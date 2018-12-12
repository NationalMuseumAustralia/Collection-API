<p:declare-step version="1.0" name="dashboard"  type="nma:dashboard"
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 	
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns:nma="tag:conaltuohy.com,2018:nma">

	<p:input port='source' primary='true'/>
	<!-- e.g.
		<request xmlns="http://www.w3.org/ns/xproc-step"
		  method = NCName
		  href? = anyURI
		  detailed? = boolean
		  status-only? = boolean
		  username? = string
		  password? = string
		  auth-method? = string
		  send-authorization? = boolean
		  override-content-type? = string>
			 (c:header*,
			  (c:multipart |
				c:body)?)
		</request>
	-->
	<!-- expects request URIs:
	/xproc-z/dashboard/?field1=value&amp;field2=value ...
	-->
	<p:input port='parameters' kind='parameter' primary='true'/>
	<p:output port="result" primary="true" sequence="true"/>
	<p:import href="xproc-z-library.xpl"/>
	<p:www-form-urldecode name="fields">
		<p:with-option name="value" select="substring-after(/c:request/@href, '?')"/>
	</p:www-form-urldecode>
	<p:load name="facets" href="../facets.xml"/>
	<p:wrap-sequence name="facets-and-fields" wrapper="facets-and-fields">
		<p:input port="source">
			<p:pipe step="facets" port="result"/>
			<p:pipe step="fields" port="result"/>
		</p:input>
	</p:wrap-sequence>
	<p:xslt name="prepare-solr-request">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="stylesheet"><p:document href="../xslt/dashboard-request-to-solr-request.xsl"/></p:input>
	</p:xslt>
	<p:xslt name="convert-xml-to-json">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="stylesheet"><p:document href="../xslt/convert-between-xml-and-json.xsl"/></p:input>
	</p:xslt>
	<p:http-request/>
	<p:xslt name="convert-json-to-xml">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="stylesheet"><p:document href="../xslt/convert-between-xml-and-json.xsl"/></p:input>
	</p:xslt>
	<p:wrap-sequence name="request-and-response" wrapper="request-and-reponse">
		<p:input port="source">
			<p:pipe step="fields" port="result"/>
			<p:pipe step="convert-json-to-xml" port="result"/>
			<p:pipe step="facets" port="result"/>
		</p:input>
	</p:wrap-sequence>
	<p:xslt name="render-solr-response">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="stylesheet"><p:document href="../xslt/solr-response-to-dashboard-response.xsl"/></p:input>
	</p:xslt>
	<z:make-http-response content-type="application/xhtml+xml"/>
	
</p:declare-step>
