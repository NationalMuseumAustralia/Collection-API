<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z"
version="1.0" name="main">


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

	<p:choose>
		<!-- welcome page for the API, includes some sample invocations of the API -->
		<p:when test=" $relative-uri = '' ">
			<p:identity>
				<p:input port="source">
					<p:inline>
						<c:response status="200">
							<c:body content-type="application/xhtml+xml">
								<html xmlns="http://www.w3.org/1999/xhtml">
									<head>
										<title>NMA API v0.0</title>
									</head>
									<body>
										<h1>NMA API v0.0</h1>
										<p>Examples:</p>
										<ul>
											<li>Get <a href="object/45929">object 45929</a></li>
											<li>Search for <a href="object?title=bark">bark</a></li>
										</ul>
										<form action="object" method="get">
											<table>
												<tr>
													<td><label>Title</label></td>
													<td><input type="text" name="title"/></td>
												</tr>
												<tr>
													<td><label>Place</label></td>
													<td><input type="text" name="place"/></td>
												</tr>
												<tr>
													<td><label>Person</label></td>
													<td><input type="text" name="place"/></td>
												</tr>
											</table>
											<button type="submit">Search</button>
										</form>
									</body>
								</html>
							</c:body>
						</c:response>
					</p:inline>
				</p:input>
			</p:identity>
		</p:when>
		<!-- retrieve object by id -->
		<p:when test=" starts-with($relative-uri, 'object/') ">
			<p:load>
				<p:with-option name="href" select="concat('http://localhost:8983/solr/core_nma_public/select?wt=xml&amp;q=id:', substring-after($relative-uri, 'object/'))"/>
			</p:load>
			<z:transform xslt="../xslt/solr-xml-to-json.xsl"/>
		</p:when>
		<!-- retrieve objects matching search criteria -->
		<p:when test=" starts-with($relative-uri, 'object') ">
			<p:www-form-urldecode>
				<p:with-option name="value" select="substring-after($relative-uri, 'object?')"/>
			</p:www-form-urldecode>
			<p:load>
				<p:with-option name="href" select="
					concat(
						'http://localhost:8983/solr/core_nma_public/select?wt=xml&amp;q=', 
						encode-for-uri(
							string-join(
								for $parameter in /c:param-set/c:param[normalize-space(@value)] return concat(
									$parameter/@name, 
									if ($parameter/@value='*') then 
										':*' 
									else concat(
										':&quot;', 
										replace(
											replace(
												$parameter/@value,
												'\\',
												'\\\\'
											),
											'&quot;',
											'\\&quot;'
										), 
										'&quot;'
									)
								), 
								' AND '
							)
						)
					)
				"/>
			</p:load>
			<z:transform xslt="../xslt/solr-xml-to-json.xsl"/>
		</p:when>
		<p:otherwise>
			<z:not-found/>
		</p:otherwise>
	</p:choose>

</p:declare-step>
