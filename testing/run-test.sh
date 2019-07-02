#!/bin/bash
# remove existing test output files
rm -r -f report/ log results-tree
# execute the jmeter test, generating an html report in "report" folder
jmeter.sh -e -l log -o report -n -t NMA-API-load-test.jmx