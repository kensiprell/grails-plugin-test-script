## grails-plugin-test-script

I use this script along with the [grails-atmosphere-meteor-sample](https://github.com/kensiprell/grails-atmosphere-meteor-sample) application for testing the [grails-atmosphere-meteor](https://github.com/kensiprell/grails-atmosphere-meteor) plugin using [geb](http://www.grails.org/plugin/geb) functional tests.

It should run on any *nix system, but I've tested it only on OSX. It uses the following standard programs: bash, perl, and sed. It also requires the [gvmtool](http://gvmtool.net/) for switching between the Grails versions.

Usage:

The example below uses the Grails version defined with gvm default:

```
    testGrailsAtmosphereMeteor.sh
``` 

The example below uses Grails version 2.1.1:

```
    testGrailsAtmosphereMeteor.sh 2.1.1
``` 

The example below uses all Grails versions defined in the script's VERSIONS array, iterating through the  versions, creating a new app, installing the plugin, running the geb tests. etc. .

```
    testGrailsAtmosphereMeteor.sh all
``` 

When finished, the script will start your browser with an appropriate page showing either the geb test results page for the first two options or showing a summary page with links to the individual geb tests if the 'all' argument is given.