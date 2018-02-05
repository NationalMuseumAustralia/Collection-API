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
											<li>Get <a href="object/119609">item 119609</a></li>
											<li>Search for <a href="object?filters[]=obj_phydescription%3Avauxhall%20car&amp;filters[]=obj_type%3Aphotographs">photographs of Vauxhall cars</a></li>
										</ul>
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
				<p:with-option name="href" select="concat('http://localhost:8080/solr/select/?q=id:', substring-after($relative-uri, 'object/'))"/>
			</p:load>
			<z:make-http-response status="200" content-type="application/xml"/>
		</p:when>
		<!-- retrieve objects matching search criteria -->
		<p:when test=" starts-with($relative-uri, 'object') ">
			<z:parse-parameters/>
			<p:load>
				<p:with-option name="href" select="
					concat(
						'http://localhost:8080/solr/select/?q=', 
						string-join(
							for $query-term in /c:multipart/c:body[@id='filters[]'] return 
							concat(
								substring-before($query-term, ':'), 
								'%3A%22',
								substring-after($query-term, ':'),
								'%22'
							), 
							'%20AND%20'
						)
					)
				"/>
			</p:load>
			<z:make-http-response status="200" content-type="application/xml"/>
		</p:when>
		<p:otherwise>
			<z:not-found/>
		</p:otherwise>
	</p:choose>

</p:declare-step>
