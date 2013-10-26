#!/bin/bash
BROWSER="/Applications/Google Chrome.app"
GEB_VER=0.9.2
SELENIUM_VER=2.35.0
JETTY_VER=8.1.13.v20130916
JETTY_PLUGIN_VER=2.0.3
APP_NAME="grails-atmosphere-meteor-test"
PACKAGE="org.grails.plugins.atmosphere_meteor_sample"
HOME_DIR=$(echo $HOME)
TEST_DIR="$(pwd)"
APP_DIR="$TEST_DIR/$APP_NAME"
PLUGIN_DIR="$HOME_DIR/Development/Plugins/grails-atmosphere-meteor"
SOURCE_DIR="$HOME_DIR/Development/Plugins/grails-atmosphere-meteor-sample"
CONTAINERS=(jetty tomcat)
#VERSIONS=( 2.0.0 2.0.1 2.0.4 2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.1.5 2.2.0 2.2.1 2.2.2 2.2.3 2.2.4 2.3.0 2.3.1 )
VERSIONS=( 2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.1.5 2.2.0 2.2.1 2.2.2 2.2.3 2.2.4 2.3.0 2.3.1 )
FORKED_VERSIONS=( 2.3.0 2.3.1 )
VERSIONS_LEGACY=( 2.0.0 2.0.1 2.0.2 2.0.3 2.0.4 2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.1.5 )
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
read -d '' JETTY_DEP1 <<EOF
	dependencies {
		provided(
			"org.eclipse.jetty:jetty-http:$JETTY_VER",
			"org.eclipse.jetty:jetty-server:$JETTY_VER",
			"org.eclipse.jetty:jetty-webapp:$JETTY_VER",
			"org.eclipse.jetty:jetty-plus:$JETTY_VER",
			"org.eclipse.jetty:jetty-security:$JETTY_VER",
			"org.eclipse.jetty:jetty-websocket:$JETTY_VER",
			"org.eclipse.jetty:jetty-continuation:$JETTY_VER",
			"org.eclipse.jetty:jetty-jndi:$JETTY_VER"
		) {
    		excludes "commons-el","ant", "sl4j-api","sl4j-simple","jcl104-over-slf4j"
    		excludes "xercesImpl","xmlParserAPIs", "servlet-api"
    		excludes "mail", "commons-lang"
    		excludes([group: "org.eclipse.jetty.orbit", name: "javax.servlet"],
            	[group: "org.eclipse.jetty.orbit", name: "javax.activation"],
            	[group: "org.eclipse.jetty.orbit", name: "javax.mail.glassfish"],
            	[group: "org.eclipse.jetty.orbit", name: "javax.transaction"])
		 }
EOF
read -d '' JETTY_PLUGIN1 <<EOF
		runtime(":jetty:$JETTY_PLUGIN_VER") {
			excludes "jetty-http", "jetty-server", "jetty-webapp", "jetty-plus", "jetty-security", "jetty-websocket", "jetty-continuation", "jetty-jndi"
		}
EOF
read -d '' JETTY_DEP2 <<EOF
	dependencies {
		provided(
			"org.eclipse.jetty.aggregate:jetty-all:$JETTY_VER"
		) {
    		excludes "commons-el","ant", "sl4j-api","sl4j-simple","jcl104-over-slf4j"
    		excludes "xercesImpl","xmlParserAPIs", "servlet-api"
    		excludes "mail", "commons-lang"
    		excludes([group: "org.eclipse.jetty.orbit", name: "javax.servlet"],
            	[group: "org.eclipse.jetty.orbit", name: "javax.activation"],
            	[group: "org.eclipse.jetty.orbit", name: "javax.mail.glassfish"],
            	[group: "org.eclipse.jetty.orbit", name: "javax.transaction"])
		 }
EOF
read -d '' JETTY_PLUGIN2 <<EOF
		runtime(":jetty:$JETTY_PLUGIN_VER") {
			excludes "jetty-all"
		}
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
			<h1>atmosphere-meteor Test Results</h1>
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
	echo "$ ./testGrailsAtmosphereMeteor.sh all all"
	echo "    will test the plugin and its application using all versions of"
	echo "    Grails from 2.1.0 through the latest release in all containers."
	echo "    The test results are grouped by container and then version."
	echo "$ ./testGrailsAtmosphereMeteor.sh jetty 2.1.0"
	echo "    will test the plugin and its application using Jetty and Grails version 2.1.0."
	echo "$TEST_DIR will contain a test summary and geb html pages."
	exit 0
}

for container in "${CONTAINERS[@]}"
	do
		if [ "$container" == "$1" ]; then
			ARG_CHECK=true
		fi
done	
for version in "${VERSIONS[@]}"
	do
		if [ "$version" == "$2" ]; then
			ARG_CHECK=true
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
	#GRAILS_DEFAULT_VER=${VERSIONS[$VERSIONS_LENGTH]}
	#gvm use grails $GRAILS_DEFAULT_VER
	gvm use grails 
	cd $PLUGIN_DIR
	PLUGIN_VER=$(grep "def version = .*$" AtmosphereMeteorGrailsPlugin.groovy | grep -o "\d.\d.\d")
	rm *.zip
	grails clean
	grails compile
	grails publish-plugin --allow-overwrite --noScm --repository=localPluginReleases
}

testApp() {
	CONTAINER=$1
	GRAILS_VER=$2
	PLUGIN_VER=$3
	LEGACY=false

read -d '' TEST_DEP_PLUGIN <<EOF
	plugins {
		compile ":atmosphere-meteor:$PLUGIN_VER"
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
	
	#echo "Deleting cached plugin ...."
	#rm $HOME_DIR/.grails/$GRAILS_VER/cached-installed-plugins/atmosphere-meteor-*.zip

	echo "Deleting cached project ...."
	rm -r $HOME_DIR/.grails/$GRAILS_VER/projects/$APPNAME
	
	echo "Deleting Ivy atmosphere-meteor plugin cache ...."
	rm -r $HOME_DIR/.grails/ivy-cache/org.grails.plugins/atmosphere*

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
		echo "Modifying BuildConfig.groovy to include Jetty dependencies ...."
		perl -i -pe "s/dependencies {.*$/dependencies {$JETTY_DEP2/g" $APP_DIR/grails-app/conf/BuildConfig.groovy
		perl -i -pe "s/build.*:tomcat:.*$/$JETTY_PLUGIN2/" $APP_DIR/grails-app/conf/BuildConfig.groovy
	fi
	
	perl -i -pe "s!repositories {!$REPOSITORIES!g" $APP_DIR/grails-app/conf/BuildConfig.groovy

	perl -i -pe "s/plugins {/$TEST_DEP_PLUGIN/g" $APP_DIR/grails-app/conf/BuildConfig.groovy

	for version in "${VERSIONS_LEGACY[@]}"; do
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

	grails refresh-dependencies

	echo "Creating Meteor artefacts ...."

	grails create-meteor-handler $PACKAGE.Default

	grails create-meteor-servlet $PACKAGE.Default

	echo "Copying files ...."

	cp $SOURCE_DIR/grails-app/conf/AtmosphereMeteorConfig.groovy $APP_DIR/grails-app/conf/

	cp $SOURCE_DIR/grails-app/conf/UrlMappings.groovy $APP_DIR/grails-app/conf/
	
	cp $SOURCE_DIR/grails-app/views/layouts/main.gsp $APP_DIR/grails-app/views/layouts/
	
	cp $SOURCE_DIR/grails-app/atmosphere/org/grails/plugins/atmosphere_meteor_sample/* $APP_DIR/grails-app/atmosphere/org/grails/plugins/atmosphere_meteor_sample/

	cp -r $SOURCE_DIR/grails-app/views/atmosphereTest $APP_DIR/grails-app/views/

	cp -r $SOURCE_DIR/grails-app/controllers/* $APP_DIR/grails-app/controllers/

	cp -r $SOURCE_DIR/grails-app/services/* $APP_DIR/grails-app/services/

	cp -r $SOURCE_DIR/test/functional $APP_DIR/test/

	cd $TEST_DIR/$APP_NAME

	# http://blog.jeffbeck.info/?p=185
	grails package
	# test using Firefox
	#grails test-app functional:
	# test using Chrome
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

if [ $# -eq 0 ]; then
	# testApp using using all containers and most recent Grails version"
	LENGTH=${#VERSIONS[@]}
	LAST_POSITION=$((LENGTH - 1))
	GRAILS_VER=${VERSIONS[${LAST_POSITION}]}
	GEB_DIR=$TEST_DIR/atmosphereTest-DEFAULT-$DATE
	mkdir $GEB_DIR	
	HTMLFILE=$GEB_DIR/index.html
	touch $HTMLFILE
	echo "$HTML_START" >> $HTMLFILE
	echo "<h1>Test Results by Container</h1></div><div class=clear></div>" >> $HTMLFILE
	for container in "${CONTAINERS[@]}"; do
		echo "<h1>$container</h1>" >> $HTMLFILE
			runTest $container $GRAILS_VER $GEB_DIR
	done
	finishHTML $GEB_DIR
  	exit 0
elif [ $1 == all ]; then
	# testApp using all containers	
	GEB_DIR=$TEST_DIR/atmosphereTest-ALL-CONTAINERS-$DATE
	mkdir $GEB_DIR	
	HTMLFILE=$GEB_DIR/index.html
	touch $HTMLFILE
	echo "$HTML_START" >> $HTMLFILE
	echo "<h1>Test Results by Container</h1></div><div class=clear></div>" >> $HTMLFILE
	for container in "${CONTAINERS[@]}"; do
		echo "<h1>$container</h1>" >> $HTMLFILE
		if [ $2 == all ]; then
			for version in "${VERSIONS[@]}"; do
				runTest $container $version $GEB_DIR
			done
		else
			runTest $container $2 $GEB_DIR
		fi	
	done
	finishHTML $GEB_DIR
 	exit 0
else
	# testApp using a specific container
	CONTAINER=$1
	GEB_DIR=$TEST_DIR/atmosphereTest-$CONTAINER-$DATE
	mkdir $GEB_DIR	
	HTMLFILE=$GEB_DIR/index.html
	touch $HTMLFILE
	echo "$HTML_START" >> $HTMLFILE
	echo "<h1>Test Results for $CONTAINER</h1></div><div class=clear></div>" >> $HTMLFILE
		if [ $2 == all ]; then
		for version in "${VERSIONS[@]}"; do
			runTest $CONTAINER $version $GEB_DIR
		done
	else
		runTest $CONTAINER $2 $GEB_DIR
	fi	
	finishHTML $GEB_DIR
  	exit 0
fi

# artifactory.sh stop
