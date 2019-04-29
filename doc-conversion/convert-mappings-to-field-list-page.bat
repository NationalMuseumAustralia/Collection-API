@ECHO OFF
:: Convert schema field mappings sheet to Markdown for wiki documentation

set CALABASH_HOME=%USERPROFILE%\lib\xmlcalabash-1.1.21-98
set DATA_DIR_IN=%USERPROFILE%\Git\NMA\Collection-API\doc-conversion\resources
set DATA_DIR_OUT=%USERPROFILE%\Git\NMA\Collection-API\doc-conversion\resources
set XPROC_FILE=%USERPROFILE%\Git\NMA\Collection-API\xproc\field-mappings-to-field-list-page.xpl

:: NB: ':\=/' converts Windows filepaths from backslash to forward-slash 
set FILE_IN=%DATA_DIR_IN:\=/%/schema-field-mappings.xml
set FILE_OUT=%DATA_DIR_OUT:\=/%/field-list-page.md

echo Converting to: %FILE_OUT%
java -cp %CALABASH_HOME%\xmlcalabash-1.1.21-98.jar com.xmlcalabash.drivers.Main -i source=%FILE_IN% -o result=%FILE_OUT% %XPROC_FILE% 
EXIT /B 0
