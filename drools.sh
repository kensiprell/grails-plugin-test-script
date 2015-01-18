#!/bin/bash
BROWSER="/Applications/Google Chrome.app"
GEB_VER=0.10.0
SELENIUM_VER=2.41.0
JETTY_PLUGIN_VER=3.0.0
APP_NAME="grails-drools-sample"
PACKAGE="grails.plugin.drools_sample"
HOME_DIR=$(echo $HOME)
TEST_DIR="$(pwd)"
APP_DIR="$TEST_DIR/$APP_NAME"
PLUGIN_DIR="$HOME_DIR/Development/Plugins/grails-drools"
SOURCE_DIR="$HOME_DIR/Development/Plugins/grails-drools-sample"
CONTAINERS=(jetty tomcat)
FORKED_VERSIONS=( 2.3.0 2.3.1 )
LEGACY_VERSIONS=( 2.1.5 )
JETTY_VERSIONS=( 2.3.9 2.4.4 )
VERSIONS=( 2.1.5 2.2.5 2.3.9 2.4.4 )
DATE=$(date +%Y-%m-%d_%T)

# Do not change any variables below this line.
START_TIME=$(date +"%Y-%m-%d %T")
START_SECONDS=$(date +"%s")
ARG_CHECK=false
read -d '' TEST_DEP <<EOF
	dependencies {
		test "org.gebish:geb-spock:$GEB_VER"
		test "org.seleniumhq.selenium:selenium-chrome-driver:$SELENIUM_VER"
		test "org.seleniumhq.selenium:selenium-firefox-driver:$SELENIUM_VER"
		test "org.seleniumhq.selenium:selenium-support:$SELENIUM_VER"
		test "org.spockframework:spock-grails-support:0.7-groovy-2.0"
EOF
read -d '' TEST_DEP_LEGACY <<EOF
	dependencies {
		test "org.gebish:geb-spock:$GEB_VER"
		test "org.seleniumhq.selenium:selenium-chrome-driver:$SELENIUM_VER"
		test "org.seleniumhq.selenium:selenium-firefox-driver:$SELENIUM_VER"
		test "org.seleniumhq.selenium:selenium-support:$SELENIUM_VER"
EOF
read -d '' JETTY_PLUGIN <<EOF
		compile ":jetty:$JETTY_PLUGIN_VER"
EOF
read -d '' HTML_START <<EOF
<html>
	<head>
		<title>Geb Tests</title>
		<link href="stylesheet.css" rel="stylesheet" type="text/css">
	<head>
	<body>
		<div id="report" class="container container_8">
			<div class="grid_6 alpha">
			<div class="grailslogo"></div>
			<h1>drools Test Results</h1>
			<div class=clear></div>
			<h2>&nbsp;</h2>
			<h2>Started: START_TIME</h2>
			<h2>&nbsp;</h2>
			<h2>Finished: END_TIME</h2>
			<h2>&nbsp;</h2>
			<h2>Elapsed Time: ELAPSED_TIME</h2>
			<h2>&nbsp;</h2>
EOF
read -d '' HTML_END <<EOF
	</body>
</html>
EOF

showUsage() {
	echo "Usage: The script requires two arguments."
	echo "$ ./drools.sh all all"
	echo "    will test the plugin and its application using the following Grails versions"
	echo "    depending on which serverlet container is used."
	echo "    Jetty: ${JETTY_VERSIONS[@]}"
	echo "    Tomcat: ${VERSIONS[@]}"
	echo "    The test results are grouped by container and then version."
	echo "$ ./drools.sh jetty 2.3.9"
	echo "    will test the plugin and its application using Jetty and Grails version 2.3.9."
	echo "$TEST_DIR will contain a test summary and geb html pages."
	exit 0
}

for container in "${CONTAINERS[@]}"; do
	if [ "$container" == "$1" ]; then
		if [ "$container"  == "jetty" ]; then 
			for version in "${JETTY_VERSIONS[@]}"; do
				if [ "$version" == "$2" ]; then
					ARG_CHECK=true
				fi
			done
		fi	
		if [ "$container"  == "tomcat" ]; then 
			for version in "${VERSIONS[@]}"; do
				if [ "$version" == "$2" ]; then
					ARG_CHECK=true
				fi
			done
		fi	
	fi
done	
if [ "$1" == "all" ]; then
	ARG_CHECK=true
fi
if [ "$2" == "all" ]; then
	ARG_CHECK=true
fi
if [ $ARG_CHECK == false ]; then
	showUsage
fi

openBrowser() {
	if [ -f "$BROWSER" -o -d "$BROWSER" ]; then
		/usr/bin/open -a "$BROWSER" "$1"
	else 
		echo "Error: browser ($BROWSER) not found."
	fi
	exit 0
}

packagePlugin() {
	ARTIFACTORY=`curl -s --head http://localhost:8081/artifactory | head -n 1 | wc -l`
	if [ $ARTIFACTORY == "0" ]; then
		echo "Starting Artifactory ...."
		artifactory.sh start
		sleep 2s
	fi

	echo "Packaging plugin ...."
	source ~/.gvm/bin/gvm-init.sh
	VERSIONS_LENGTH=`expr ${#VERSIONS[@]} - 1`
	gvm use grails 
	cd $PLUGIN_DIR
	PLUGIN_VER=$(grep "def version = .*$" DroolsGrailsPlugin.groovy | grep -o \".*\" | tr -d '"')
	rm *.zip
	grails clean
	grails compile
	if [[ $PLUGIN_VER == *SNAPSHOT* ]]; then
		grails publish-plugin --allow-overwrite --noScm --repository=localPluginSnapshots
	else 
  		grails publish-plugin --allow-overwrite --noScm --repository=localPluginReleases
	fi
}

testApp() {
	CONTAINER=$1
	GRAILS_VER=$2
	PLUGIN_VER=$3
	LEGACY=false

read -d '' TEST_DEP_PLUGIN <<EOF
	plugins {
		compile ":drools:$PLUGIN_VER"
		test ":geb:$GEB_VER"
		test ":spock:0.7"
EOF
read -d '' REPOSITORIES <<EOF
	repositories {
		mavenRepo "http://localhost:8081/artifactory/plugins-snapshot-local/"
		mavenRepo "http://localhost:8081/artifactory/plugins-release-local/"
EOF

	source ~/.gvm/bin/gvm-init.sh
	if [ $GRAILS_VER == "default" ]; then
		gvm use grails
	else
		gvm use grails $GRAILS_VER
	fi
	
	echo "Deleting cached project ...."
	rm -r $HOME_DIR/.grails/$GRAILS_VER/projects/$APPNAME
	
	echo "Deleting Ivy drools plugin cache ...."
	rm -r $HOME_DIR/.grails/ivy-cache/org.grails.plugins/drools*

	echo "Deleting test application directory ...."
	cd $TEST_DIR
	rm -r $APP_NAME

	echo "Creating test application ...."
	grails create-app $APP_NAME
	cd $APP_NAME
	
	echo "Modifying BuildConfig.groovy to resolve test and plugin dependencies ...."
	
	if [[ $FORKED_VERSIONS[$GRAILS_VER] ]]; then
		perl -i -pe "s/console: .*$/console: false/" $APP_DIR/grails-app/conf/BuildConfig.groovy
		perl -i -pe "s/run: .*$/run: false,/" $APP_DIR/grails-app/conf/BuildConfig.groovy
		perl -i -pe "s/test: .*$/test: false,/" $APP_DIR/grails-app/conf/BuildConfig.groovy
		perl -i -pe "s/war: .*$/war: false,/" $APP_DIR/grails-app/conf/BuildConfig.groovy		
	fi
	
	if [ $CONTAINER == "jetty" ]; then
		perl -i -pe "s/build.*:tomcat:.*$/$JETTY_PLUGIN/" $APP_DIR/grails-app/conf/BuildConfig.groovy
	fi
	
	if [ $GRAILS_VER == "2.1.5" ]; then
		perl -i -pe "s/legacyResolve/\/\/legacyResolve/g" $APP_DIR/grails-app/conf/BuildConfig.groovy
	else
		perl -i -pe "s/legacyResolve true/legacyResolve false/g" $APP_DIR/grails-app/conf/BuildConfig.groovy
	fi

	perl -i -pe "s!repositories {!$REPOSITORIES!g" $APP_DIR/grails-app/conf/BuildConfig.groovy

	perl -i -pe "s/plugins {/$TEST_DEP_PLUGIN/g" $APP_DIR/grails-app/conf/BuildConfig.groovy

	for version in "${LEGACY_VERSIONS[@]}"; do
		if [ "$version" == "$GRAILS_VER" ]; then
			LEGACY=true
			break
		fi
	done

	if [ $LEGACY == true ]; then
		perl -i -pe "s/dependencies {.*$/$TEST_DEP_LEGACY/g" $APP_DIR/grails-app/conf/BuildConfig.groovy
	else
		perl -i -pe "s/dependencies {.*$/$TEST_DEP/g" $APP_DIR/grails-app/conf/BuildConfig.groovy
	fi

	echo "Copying files ...."

	cp -r $SOURCE_DIR/grails-app/conf/UrlMappings.groovy $APP_DIR/grails-app/conf/

	cp -r $SOURCE_DIR/grails-app/conf/DroolsConfig.groovy $APP_DIR/grails-app/conf/

	cp -r $SOURCE_DIR/grails-app/domain/* $APP_DIR/grails-app/domain/
	rm  $APP_DIR/grails-app/domain/grails/plugin/drools_sample/DroolsRule.groovy
	
	cp -r $SOURCE_DIR/grails-app/controllers/* $APP_DIR/grails-app/controllers/
	
	cp -r $SOURCE_DIR/grails-app/views/test $APP_DIR/grails-app/views/

	cp -r $SOURCE_DIR/src/rules $APP_DIR/src/

	cp -r $SOURCE_DIR/test/functional $APP_DIR/test/

	grails compile

	echo "Creating Drools Domain ...."

	grails create-drools-domain $PACKAGE.DroolsRule

	cp -r $SOURCE_DIR/grails-app/conf/BootStrap.groovy $APP_DIR/grails-app/conf/

	grails clean
	
	grails -Dgeb.env=chrome test-app functional:
}

runTest() {
	CONTAINER=$1
	GRAILS_VER=$2
	GEB_DIR=$3
	echo ""
	echo "Testing Grails $GRAILS_VER in $CONTAINER ..."
	(
	testApp $CONTAINER $GRAILS_VER $PLUGIN_VER
	)
	mkdir $GEB_DIR/$CONTAINER
	mkdir $GEB_DIR/$CONTAINER/$GRAILS_VER
	cp $APP_DIR/target/test-reports/html/stylesheet.css $GEB_DIR/$CONTAINER
	cp -r $APP_DIR/target/test-reports/html $GEB_DIR/$CONTAINER/$GRAILS_VER
	echo "<div class="clear"></div><p><a href=\"file://$GEB_DIR/$CONTAINER/$GRAILS_VER/html/index.html\">$GRAILS_VER</a></p>" >> $HTMLFILE
	SUMMARY="$(cat $APP_DIR/target/test-reports/plain/TEST-functional-spock-IndexPageSpec.txt | sed -n 2p)"
	echo "<p>$SUMMARY</p><p></p>" >> $HTMLFILE
}

runJettyTest() {
	container="jetty"
	echo "<h1>$container</h1>" >> $HTMLFILE
	if [ $1 == "all" ]; then
		for version in "${JETTY_VERSIONS[@]}"; do
			runTest $container $version $GEB_DIR
		done
	else
		runTest $container $1 $GEB_DIR
	fi	
}

finishHTML() {
	GEB_DIR=$1
	cp $APP_DIR/target/test-reports/html/stylesheet.css $GEB_DIR
	END_TIME=$(date +"%Y-%m-%d %T")
	END_SECONDS=$(date +"%s")
	SECONDS_TOTAL=$(($END_SECONDS-$START_SECONDS))
	MINUTES=$(($SECONDS_TOTAL / 60))
	if [ $MINUTES -eq 1 ]; then
		MINUTES_TEXT="$MINUTES minute"
	else
		MINUTES_TEXT="$MINUTES minutes"
	fi
	SECONDS=$(($SECONDS_TOTAL % 60))
	if [ $SECONDS -eq 1 ]; then
		SECONDS_TEXT="$SECONDS second"
	else
		SECONDS_TEXT="$SECONDS seconds"
	fi
	ELAPSED_TIME="$MINUTES_TEXT and $SECONDS_TEXT"
	perl -i -pe "s/START_TIME/$START_TIME/" $HTMLFILE
	perl -i -pe "s/END_TIME/$END_TIME/" $HTMLFILE
	perl -i -pe "s/ELAPSED_TIME/$ELAPSED_TIME/" $HTMLFILE	
	echo "$HTML_END" >> $HTMLFILE
	echo ""
	echo "Tests finished."
 	echo "Open the file below in your browser for the test results:"
  	echo "$HTMLFILE"
  	openBrowser "$HTMLFILE"
}

packagePlugin

if [ $1 == "all" ]; then
	# testApp using all containers	
	GEB_DIR=$TEST_DIR/droolsTest-ALL-CONTAINERS-$DATE
	mkdir $GEB_DIR	
	HTMLFILE=$GEB_DIR/index.html
	touch $HTMLFILE
	echo "$HTML_START" >> $HTMLFILE
	echo "<h1>Test Results by Container</h1></div><div class=clear></div>" >> $HTMLFILE
	for container in "${CONTAINERS[@]}"; do
		if [ $container == "jetty" ]; then
			runJettyTest $2
		else 
			echo "<h1>$container</h1>" >> $HTMLFILE
			if [ $2 == all ]; then
				for version in "${VERSIONS[@]}"; do
					runTest $container $version $GEB_DIR
				done
			else
				runTest $container $2 $GEB_DIR
			fi
		fi	
	done
	finishHTML $GEB_DIR
 	exit 0
else
	# testApp using a specific container
	CONTAINER=$1
	GEB_DIR=$TEST_DIR/droolsTest-$CONTAINER-$DATE
	mkdir $GEB_DIR	
	HTMLFILE=$GEB_DIR/index.html
	touch $HTMLFILE
	echo "$HTML_START" >> $HTMLFILE
	echo "<h1>Test Results for $CONTAINER</h1></div><div class=clear></div>" >> $HTMLFILE
	if [ $CONTAINER == "jetty" ]; then
		runJettyTest $2
	else 
		if [ $2 == all ]; then
			for version in "${VERSIONS[@]}"; do
				runTest $CONTAINER $version $GEB_DIR
			done
		else
			runTest $CONTAINER $2 $GEB_DIR
		fi
	fi	
	finishHTML $GEB_DIR
  	exit 0
fi
