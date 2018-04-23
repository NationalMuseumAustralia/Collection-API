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
	<p:variable name="accept" select="/c:request/c:header[@name='accept']/@value"/>
	<p:www-form-urldecode name="uri-parameters">
		<p:with-option name="value" select="substring-after($relative-uri, '?')"/>
	</p:www-form-urldecode>
	<p:choose>
		<!-- welcome page for the API, includes some sample invocations of the API -->
		<p:when test=" $relative-uri = '' ">
			<nma:home-page/>
		</p:when>
		<p:otherwise>
			<!-- either searching, or retrieving individual objects -->
			<!-- the "format" parameter can be used to specify a content type (overriding Accept header) -->
			<p:variable name="format" select="/c:param-set/c:param[@name='format']/@value"/>
			<p:choose>
				<!-- retrieve record by id -->
				<p:when test=" matches($relative-uri, '[^/]+/[^?]+') ">
					<p:load>
						<p:with-option name="href" select="
							concat(
								'http://localhost:8983/solr/core_nma_public/select?wt=xml&amp;q=id:', 
								substring-before(
									concat($relative-uri, '?'),
									'?'
								)
							)
						"/>
					</p:load>
					<nma:format-result>
						<p:with-option name="accept" select="$accept"/>
						<p:with-option name="format" select="$format"/>
					</nma:format-result>
				</p:when>
				<!-- retrieve objects matching search criteria -->
				<p:when test=" contains($relative-uri, '?') ">
					<p:variable name="sort" select="/c:param-set/c:param[@name='sort']/@value"/>
					<p:variable name="start" select="/c:param-set/c:param[@name='offset']/@value"/>
					<!-- if you don't specify a limit, this is how many rows you get -->
					<p:variable name="default-rows" select="50"/>
					<!-- this is the maximum number of rows you can get, even if you request more -->
					<p:variable name="max-rows" select="100"/>
					<!-- this is the number of rows requested -->
					<p:variable name="requested-rows" select="/c:param-set/c:param[@name='limit']/@value"/>
					<!-- this is the number of rows which we will request from Solr -->
					<!-- and which is no less than 1 and no more than $max-rows -->
					<p:variable name="rows" select="
						if ($requested-rows castable as xs:integer) then
							min((
								$max-rows cast as xs:integer,
								max((1, $requested-rows cast as xs:double))
							)) cast as xs:integer
						else
							$default-rows
					"/>
					<p:variable name="entity-type" select="substring-before($relative-uri, '?')"/>
					<p:load>
						<p:with-option name="href" select="
							concat(
								'http://localhost:8983/solr/core_nma_public/select?wt=xml&amp;',
								'fq=type:', $entity-type, '&amp;',
								'q=', encode-for-uri(
									string-join(
										for $parameter in /c:param-set/c:param
											[normalize-space(@value)]
											[not(@name=('format', 'sort', 'offset', 'limit'))] 
										return concat(
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
												'&quot;~1000000'
											)
										), 
										' AND '
									)
								),
								if ($sort) then
									concat(
										'&amp;sort=', 
										string-join(
											encode-for-uri($sort),
											','
										)
									)
								else (),
								if (not($start='')) then 
									concat('&amp;start=', encode-for-uri($start))
								else (),
								if (not($rows='')) then 
									concat('&amp;rows=', encode-for-uri($rows))
								else ()
							)
						"/>
					</p:load>
					<nma:format-result>
						<p:with-option name="accept" select="$accept"/>
						<p:with-option name="format" select="$format"/>
						<p:with-option name="relative-uri" select="$relative-uri"/>
					</nma:format-result>
				</p:when>
				<p:otherwise>
					<z:not-found/>
				</p:otherwise>
			</p:choose>
		</p:otherwise>
	</p:choose>
	
	<p:declare-step name="format-result" type="nma:format-result">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="accept"/>
		<p:option name="format"/>
		<p:option name="relative-uri"/>
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
	
	<p:declare-step name="home-page" type="nma:home-page">
		<p:output port="result"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head>
									<title>NMA API v1.0β</title>
								</head>
								<body>
									<h1>NMA API v1.0β</h1>
									<p>Examples:</p>
									<ul>
										<li>Get <a href="object/45929">object 45929</a></li>
										<li>Search for <a href="object?title=bark">bark</a></li>
									</ul>
									<form action="object" method="get">
										<table>
											<tr>
												<td><label>Type</label></td>
												<td><input type="text" name="type"/></td>
											</tr>
											<tr>
												<td><label>Text (catch-all)</label></td>
												<td><input type="text" name="text"/></td>
											</tr>
											<tr>
												<td><label>Collection name</label></td>
												<td><input type="text" name="collection"/></td>
											</tr>
											<tr>
												<td><label>Title</label></td>
												<td><input type="text" name="title"/></td>
											</tr>
											<tr>
												<td><label>Description</label></td>
												<td><input type="text" name="description"/></td>
											</tr>
											<tr>
												<td><label>Creator</label></td>
												<td><input type="text" name="creator"/></td>
											</tr>
											<tr>
												<td><label>Temporal</label></td>
												<td><input type="text" name="temporal"/></td>
											</tr>
											<tr>
												<td><label>Spatial</label></td>
												<td><input type="text" name="spatial"/></td>
											</tr>
											<tr>
												<td><label>Dimension</label></td>
												<td><input type="text" name="dimension"/></td>
											</tr>
											<tr>
												<td><label>Medium</label></td>
												<td><input type="text" name="medium"/></td>
											</tr>
											<tr>
												<td><label>Rights</label></td>
												<td><input type="text" name="rights"/></td>
											</tr>
											<tr>
												<td><label>Contributor</label></td>
												<td><input type="text" name="contributor"/></td>
											</tr>
											<tr>
												<td><label>Media (identifiers)</label></td>
												<td><input type="text" name="media"/></td>
											</tr>
											<tr>
												<td><label>Name (of people)</label></td>
												<td><input type="text" name="name"/></td>
											</tr>
											<tr>
												<td><label>Gender</label></td>
												<td><input type="text" name="gender"/></td>
											</tr>
											<tr>
												<td><label>Location (lat, long)</label></td>
												<td><input type="text" name="location"/></td>
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
	</p:declare-step>

</p:declare-step>
