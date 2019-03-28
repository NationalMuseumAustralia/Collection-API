<?xml version="1.0"?>
<!--
   Copyright 2019 Conal Tuohy

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-->
<p:declare-step version="1.0"
	xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:c="http://www.w3.org/ns/xproc-step">

	<!-- NB: Requires -Xallow-text-results in Calabash command line call -->

	<!-- Might be able to get rid of XML wrapper element see https://stackoverflow.com/questions/13307936/transformation-outputs-non-xml-documents -->

	<p:input port="source" primary="true" />
	<p:input port="parameters" kind="parameter" />
	<p:output port="result" primary="true" />

	<p:xslt name="convert">
		<p:input port="stylesheet">
			<p:document href="../xslt/field-mappings-to-markdown.xsl" />
		</p:input>
	</p:xslt>

</p:declare-step>
