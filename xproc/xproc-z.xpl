<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
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
	<p:import href="signup.xpl"/>
	<p:import href="admin.xpl"/>
	
	<p:variable name="relative-uri" select="substring-after(/c:request/@href, '/xproc-z/')"/>
	<!-- HTTP Header names are case-insensitive -->
	<p:variable name="accept" select="/c:request/c:header[lower-case(@name)='accept']/@value"/>
	<!-- the Kong 'x-consumer-groups' header will contain the dataset name 'internal' or 'public' -->
	<p:variable name="dataset" select="/c:request/c:header[lower-case(@name)='x-consumer-groups']/@value"/>

	<p:choose>
		<p:when test="$relative-uri='debug'">
			<z:make-http-response>
				<p:input port="source">
					<p:pipe step="main" port="source"/>
				</p:input>
			</z:make-http-response>
		</p:when>
		<p:when test="starts-with($relative-uri, 'signup/') ">
			<nma:signup>
				<p:input port="source">
					<p:pipe step="main" port="source"/>
				</p:input>
			</nma:signup>
		</p:when>
		<p:when test="starts-with($relative-uri, 'admin/') ">
			<nma:admin>
				<p:input port="source">
					<p:pipe step="main" port="source"/>
				</p:input>
			</nma:admin>
		</p:when>
		<!-- welcome page for the API, includes some sample invocations of the API -->
		<p:when test=" $relative-uri = '' ">
			<nma:home-page/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'apiexplorer.html')">
			<nma:api-explorer/>
		</p:when>
		<p:when test="$relative-uri = 'context.json'">
			<nma:json-context/>
		</p:when>
		<!-- retrieve record by id, OR matching search criteria -->
		<p:when test=" matches($relative-uri, '[^/]+/[^?]+') or contains($relative-uri, '?')">
			<p:try name="decode-and-process-query-parameters">
				<p:group>
					<p:www-form-urldecode name="uri-parameters">
						<p:with-option name="value" select="substring-after($relative-uri, '?')"/>
					</p:www-form-urldecode>
					<p:group>
						<!-- the "format" parameter, if it exists, specifies a content type (overriding Accept header) -->
						<p:variable name="format" select="/c:param-set/c:param[@name='format']/@value"/>
						<!-- Translate the API request into a request to Solr -->
						<p:try>
							<p:group>
								<p:xslt>
									<p:with-param name="relative-uri" select="$relative-uri"/>
									<p:with-param name="dataset" select="$dataset"/>
									<p:input port="stylesheet">
										<p:document href="../xslt/api-request-to-solr-request.xsl"/>
									</p:input>
								</p:xslt>
								<!-- Make the HTTP request to Solr, extract response data from Solr's response and reformat it as an API response -->
								<p:http-request/>
							</p:group>
							<p:catch name="solr-request-error">
								<p:template>
									<p:input port="parameters"><p:empty/></p:input>
									<p:input port="source">
										<p:pipe step="solr-request-error" port="error"/>
									</p:input>
									<p:input port="template">
										<p:inline>
											<response>
												<lst name="error">
													<int name="code">500</int>
													<str name="msg">{string(.)}</str>
												</lst>
											</response>
										</p:inline>
									</p:input>
								</p:template>
							</p:catch>
						</p:try>
						<nma:format-result>
							<p:with-option name="format" select="$format"/>
							<p:with-option name="accept" select="$accept"/>
							<p:with-option name="relative-uri" select="$relative-uri"/>
						</nma:format-result>
					</p:group>
				</p:group>
				<p:catch name="malformed-uri-parameters">
					<!-- generate an error response in Solr's own error format -->
					<p:identity name="solr-style-malformed-uri-parameters-error-response">
						<p:input port="source">
							<p:inline>
								<response>
									<lst name="error">
										<int name="code">400</int>
										<str name="msg">Malformed URI parameters</str>
									</lst>
								</response>
							</p:inline>
						</p:input>
					</p:identity>
					<nma:format-result>
						<p:with-option name="accept" select="$accept"/>
						<p:with-option name="relative-uri" select="$relative-uri"/>
					</nma:format-result>
				</p:catch>
			</p:try>
		</p:when>
		<!-- unknown request URI -->
		<p:otherwise>
			<z:not-found/>
		</p:otherwise>
	</p:choose>
	<!-- enable CORS -->
	<z:add-response-header header-name="Access-Control-Allow-Origin" header-value="*"/>
	
	<p:declare-step name="format-result" type="nma:format-result">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="accept" required="true"/>
		<p:option name="format" select=" '' "/><!-- the 'format' URI parameter may not be present -->
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
	
	<p:declare-step name="json-context" type="nma:json-context">
		<p:output port="result"/>
		<p:http-request>
			<p:input port="source">
				<p:inline>
					<c:request href="../context.json" method="get" override-content-type="text/json"/>
				</p:inline>
			</p:input>
		</p:http-request>
		<z:make-http-response content-type="application/json"/>
	</p:declare-step>
	
	<p:declare-step name="home-page" type="nma:home-page">
		<p:output port="result"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="303">
						<c:header name="location" value="http://www.nma.gov.au/collections/api/landing"/>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>

</p:declare-step>
