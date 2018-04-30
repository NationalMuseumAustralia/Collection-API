<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"
version="1.0" name="main" xmlns:nma="tag:conaltuohy.com,2018:nma">


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
	
	<p:input port='parameters' kind='parameter' primary='true'/>
	<p:output port="result" primary="true" sequence="true"/>
	<p:import href="xproc-z-library.xpl"/>	
	
	<p:variable name="relative-uri" select="substring-after(/c:request/@href, '/xproc-z/')"/>
	<!-- HTTP Header names are case-insensitive -->
	<p:variable name="accept" select="/c:request/c:header[lower-case(@name)='accept']/@value"/>
	<p:www-form-urldecode name="uri-parameters">
		<p:with-option name="value" select="substring-after($relative-uri, '?')"/>
	</p:www-form-urldecode>
	<p:choose>
		<!-- welcome page for the API, includes some sample invocations of the API -->
		<p:when test=" $relative-uri = '' ">
			<nma:home-page/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'apiexplorer.html')">
			<nma:api-explorer/>
		</p:when>
		<!-- retrieve record by id, OR matching search criteria -->
		<p:when test=" matches($relative-uri, '[^/]+/[^?]+') or contains($relative-uri, '?')">
			<!-- the "format" parameter can be used to specify a content type (overriding Accept header) -->
			<p:variable name="format" select="/c:param-set/c:param[@name='format']/@value"/>
			<!-- Translate the API request into a request to Solr -->
			<p:xslt>
				<p:with-param name="relative-uri" select="$relative-uri"/>
				<p:input port="stylesheet">
					<p:document href="../xslt/api-request-to-solr-request.xsl"/>
				</p:input>
			</p:xslt>
			<!-- Make the HTTP request to Solr, extract response data from Solr's response and reformat it as an API response -->
			<p:http-request/>
			<nma:format-result>
				<p:with-option name="accept" select="$accept"/>
				<p:with-option name="format" select="$format"/>
				<p:with-option name="relative-uri" select="$relative-uri"/>
			</nma:format-result>
		</p:when>
		<!-- unknown request URI -->
		<p:otherwise>
			<z:not-found/>
		</p:otherwise>
	</p:choose>
	
	<p:declare-step name="format-result" type="nma:format-result">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="accept" required="true"/>
		<p:option name="format" required="true"/>
		<p:option name="relative-uri" required="true"/>
		<p:option name="rows"/>
		<p:xslt>
			<p:with-param name="accept" select="$accept"/>
			<p:with-param name="format" select="$format"/>
			<p:with-param name="relative-uri" select="$relative-uri"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/solr-xml-to-json.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step name="api-explorer" type="nma:api-explorer">
		<p:output port="result"/>
		<p:http-request>
			<p:input port="source">
				<p:inline>
					<c:request href="../apiexplorer.html" method="get"/>
				</p:inline>
			</p:input>
		</p:http-request>
		<z:make-http-response content-type="text/html"/>
	</p:declare-step>
	
	<p:declare-step name="home-page" type="nma:home-page">
		<p:output port="result"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head>
									<title>National Museum of Australia Collections API Public Beta</title>
								</head>
								<body>
									<h1>National Museum of Australia Collections API Public Beta</h1>
									<p>Welcome to the beta testing site of the National Museum of Australia's Collections API.</p>
									<p>To get started quickly, see our <a href="https://github.com/Conal-Tuohy/NMA-API/wiki/Getting-started">Getting Started</a> guide, or jump straight into the <a href="http://nma.conaltuohy.com/apiexplorer.html" >API Explorer</a>.</p>
									<p>To report a bug, request an enhancement, or make an encouraging comment, see the <a href="https://github.com/Conal-Tuohy/NMA-API/issues">list of issues</a> at our GitHub repository, and post a new issue or comment on an existing issue (NB you will need to log in to GitHub).</p>
									<p>Sample resources:</p>
									<ul>
										<li><a href="object/64620#">Phar Lap's Heart</a></li>
										<li>Things made out of <a href="object?medium=bark">bark</a></li>
									</ul>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>

</p:declare-step>
