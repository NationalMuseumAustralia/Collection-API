#!/bin/bash
# Convert schema field mappings sheet to Markdown for wiki documentation

FILE_IN=resources/schema-field-mappings.xml
FILE_OUT=resources/field-list-page.md

echo Converting to: $FILE_OUT
java -jar /usr/local/xmlcalabash/xmlcalabash.jar -Xallow-text-results -i source=$FILE_IN -o result=$FILE_OUT ../xproc/field-mappings-to-field-list-page.xpl
