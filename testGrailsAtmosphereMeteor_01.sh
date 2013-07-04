#!/bin/bash
BROWSER="/Applications/Google Chrome.app"
GEB_VER=0.9.0
SELENIUM_VER=2.33.0
APP_NAME="grails-atmosphere-meteor-test"
PACKAGE="org.grails.plugins.atmosphere_meteor_sample"
HOME_DIR=$(echo $HOME)
TEST_DIR="$(pwd)"
APP_DIR="$TEST_DIR/$APP_NAME"
PLUGIN_DIR="$HOME_DIR/Development/Plugins/grails-atmosphere-meteor"
SOURCE_DIR="$HOME_DIR/Development/Plugins/grails-atmosphere-meteor-sample"
#VERSIONS=( 2.0.0 2.0.1 2.0.2 2.0.3 2.0.4 2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.1.5 2.2.0 2.2.1 2.2.2 )
# 2.0.2 and 2.0.3: java.lang.NullPointerException at 
# org.apache.ivy.plugins.resolver.AbstractResolver.initRepositoryCacheManagerFromSettings(AbstractResolver.java:396)
VERSIONS=( 2.0.0 2.0.1 2.0.4 2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.1.5 2.2.0 2.2.1 2.2.2 2.2.3 )
VERSIONS_LEGACY=( 2.0.0 2.0.1 2.0.2 2.0.3 2.0.4 2.1.0 2.1.1 2.1.2 2.1.3 2.1.4 2.1.5 )
DATE=$(date +%Y-%m-%d_%T)
# Do not change any variables below this line.
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
read -d '' TEST_DEP_PLUGIN <<EOF
	plugins {
		test ":geb:$GEB_VER"
		test ":spock:0.7"
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
EOF
read -d '' HTML_END <<EOF
		</div>
	</body>
</html>
EOF

showUsage() {
	echo "Usage: The script accepts zero or one argument."
	echo "    Running the script without an argument will test the plugin and its associated" 
	echo "    sample application with the Grails version defined in GRAILS_HOME."
	echo "$ ./testGrailsAtmosphereMeteor.sh all"
	echo "    will test the plugin and its application using all versions of"
	echo "    Grails from 2.0.0 through the latest release."
	echo "$ ./testGrailsAtmosphereMeteor.sh 2.1.0"
	echo "    will test the plugin and its application using only version 2.1.0."
	echo "$TEST_DIR will contain a test summary and geb html pages."
	exit 0
}

for version in "${VERSIONS[@]}"
	do
		if [ "$version" == "$1" ]; then
			ARG_CHECK=true
		fi
done	
if [ $# -eq 0 ]; then
	ARG_CHECK=true
fi
if [ "$1" == "all" ]; then
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
	echo "Packaging plugin ...."
	source ~/.gvm/bin/gvm-init.sh
	gvm default grails
	cd $PLUGIN_DIR
	PLUGIN_VER=$(grep "def version = .*$" AtmosphereMeteorGrailsPlugin.groovy | grep -o "\d.\d.\d")
	rm *.zip
	grails clean
	grails compile
	grails maven-install
}

testApp() {
	GRAILS_VER=$1
	PLUGIN_VER=$2
	LEGACY=false

	source ~/.gvm/bin/gvm-init.sh
	gvm use grails $GRAILS_VER
	
	echo "Deleting cached plugin ...."
	rm $HOME_DIR/.grails/$GRAILS_VER/cached-installed-plugins/atmosphere-meteor-*.zip

	echo "Deleting cached project ...."
	rm -r $HOME_DIR/.grails/$GRAILS_VER/projects/$APPNAME

	echo "Deleting test application directory ...."
	cd $TEST_DIR
	rm -r $APP_NAME

	echo "Creating test application ...."
	grails create-app $APP_NAME
	cd $APP_NAME

	echo "Installing plugin in test application ...."
	grails install-plugin $PLUGIN_DIR/grails-atmosphere-meteor-$PLUGIN_VER.zip

	#echo "Adding inplace plugin to BuildConfig.groovy"
	#echo 'grails.plugin.location.atmosphere_meteor = "/Users/Ken/Development/Plugins/grails-atmosphere-meteor"' > BuildConfig.groovy
	#cat grails-app/conf/BuildConfig.groovy >> BuildConfig.groovy
	#mv BuildConfig.groovy grails-app/conf/BuildConfig.groovy

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

	echo "Modifying BuildConfig.groovy to resolve test dependencies ...."

	for version in "${VERSIONS_LEGACY[@]}"; do
		if [ "$version" == "$GRAILS_VER" ]; then
			LEGACY=true
			break
		fi
	done

	if [ $LEGACY == true ]; then
		perl -i -pe "s/dependencies {/$TEST_DEP_LEGACY/g" $APP_DIR/grails-app/conf/BuildConfig.groovy
	else
		perl -i -pe "s/dependencies {/$TEST_DEP/g" $APP_DIR/grails-app/conf/BuildConfig.groovy
	fi

	perl -i -pe "s/plugins {/$TEST_DEP_PLUGIN/g" $APP_DIR/grails-app/conf/BuildConfig.groovy

	# test using Firefox
	#grails test-app functional:
	# test using Chrome
	grails -Dgeb.env=chrome test-app functional:
}

runSingleTest() {
	GRAILS_VER=$1
	(
	testApp $GRAILS_VER $PLUGIN_VER
	)
  	cp -r $APP_DIR/target/test-reports/html $TEST_DIR/atmosphereTest-$GRAILS_VER-$DATE
  	echo ""
  	echo $(head -n 2 $APP_DIR/target/test-reports/plain/TEST-functional-spock-IndexPageSpec.txt)
  	echo "Open the file below in your browser for the test details:"
  	echo "$TEST_DIR/atmosphereTest-$GRAILS_VER-$DATE/index.html"
  	openBrowser "$TEST_DIR/atmosphereTest-$GRAILS_VER-$DATE/index.html"	
}

if [ $# -eq 0 ]; then
	# testApp using $GRAILS_HOME version"
	packagePlugin
	runSingleTest $(gvm default grails | grep -o "\d.\d.\d")
  	exit 0
elif [ $1 == all ]; then
	# testApp using all Grails versions ($VERSIONS)
	packagePlugin
	GEB_DIR=$TEST_DIR/atmosphereTest-ALL-$DATE
	mkdir $GEB_DIR	
	HTMLFILE=$GEB_DIR/index.html
	touch $HTMLFILE
	echo "$HTML_START" >> $HTMLFILE
	echo "<h1>Test Results by Grails Version</h1><h2>atmosphereTest-ALL-$DATE</h2></div>" >> $HTMLFILE
	for version in "${VERSIONS[@]}"; do
		GRAILS_VER=$version
		(
		testApp $GRAILS_VER $PLUGIN_VER
		)
		mkdir $GEB_DIR/$GRAILS_VER
		cp $APP_DIR/target/test-reports/html/stylesheet.css $GEB_DIR
		cp -r $APP_DIR/target/test-reports/html $GEB_DIR/$GRAILS_VER
		echo "<div class="clear"></div><p><a href=\"file://$GEB_DIR/$GRAILS_VER/html/index.html\">$GRAILS_VER</a></p>" >> $HTMLFILE
		SUMMARY="$(cat $APP_DIR/target/test-reports/plain/TEST-functional-spock-IndexPageSpec.txt | sed -n 2p)"
		echo "<p>$SUMMARY</p><p></p>" >> $HTMLFILE
	done
	echo "$HTML_END" >> $HTMLFILE
	echo ""
	echo "Tests finished."
 	echo "Open the file below in your browser for the test results:"
  	echo "$HTMLFILE"
  	openBrowser "$HTMLFILE"
 	exit 0
else
	# testApp using a specific Grails version
	packagePlugin
	runSingleTest $1
  	exit 0
fi
