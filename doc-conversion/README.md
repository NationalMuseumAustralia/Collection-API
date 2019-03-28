# API field documentation conversion

Converts the schema field mapping spreadsheet into Markdown to place into the github wiki help pages.

1) Install add-on to Google Sheet

[Export Sheet Data](https://chrome.google.com/webstore/detail/export-sheet-data/bfdcopkbamihhchdnjghdknibmcnfplk?hl=en) by Chris Ingerson [Background info](https://www.techjunkie.com/convert-google-sheets-xml/)

2) Export Google Sheet to XML

Google Sheet usage: Add-ons > Export Sheet Data > Open Sidebar

Options
- Format: Select Format = XML
- Format: Select Sheet = Current sheet only
- XML: Export columns as child elements = true
- XML: Include first column in export = true (so raw XML is easier to read, rather than one row per line with lots of attributes)

NB: value in first column becomes the name of row wrapper XML element 

3) Download the XML file

The exported XML file is displayed in Google Drive - download from there and/or add it to your 'My Drive'

4) Move and rename

Move the file to your local git clone: `/Collection-API/doc-conversion/resources/schema-field-mappings.xml`

5) Run the conversion

The Windows batch file expects the git repository to be cloned into `%USERPROFILE%\Git\NMA\Collection-API`  Edit the batch file to use a different location.

```
> cd {git-location}/Collection-API/doc-conversion/resources
> convert-mappings-to-markdown.bat
```

The converted markdown is placed in:
`/Collection-API/doc-conversion/resources/field-list.md`

Optionally commit this new version of the XML and MD files

6) Update the wiki page

Ignore the XML wrapper `<c:result>`. Edit the wiki page, copy&paste the table data.
