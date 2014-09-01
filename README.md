## grails-plugin-test-script

I use these scripts to test my Grails plugins.

* [grails-atmosphere-meteor](https://github.com/kensiprell/grails-atmosphere-meteor)

* [grails-atmosphere-meteor-sample](https://github.com/kensiprell/grails-atmosphere-meteor-sample) 

* [grails-angularjs](https://github.com/kensiprell/grails-angularjs)

* [grails-angularjs-test](https://github.com/kensiprell/grails-angularjs-test)


They should run on any *nix system, but I've tested them only on OSX. They use the following standard programs: bash, perl, and sed. They also require the [gvmtool](http://gvmtool.net/) for switching between Grails versions.

When finished, the script will start your browser with an appropriate page showing either the geb test results page for a single test or showing a summary page with links to the individual geb tests if the 'all' argument is given.