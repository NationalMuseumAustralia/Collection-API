<p:declare-step version="1.0" name="signup"  type="nma:signup"
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 	
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:kong="tag:conaltuohy.com,2018:kong"
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
	/xproc-z/signup/internal/ (signup form for internal API key)
	/xproc-z/signup/internal/register (target of signup form for internal API key)
	/xproc-z/signup/public/ (signup form for public API key)
	/xproc-z/signup/public/register (target of signup form for public API key)
	-->
	<p:input port='parameters' kind='parameter' primary='true'/>
	<p:output port="result" primary="true" sequence="true"/>
	<p:import href="xproc-z-library.xpl"/>	
	<p:variable name="base-uri" select="substring-after(/c:request/@href, '/xproc-z/signup/')"/>
	<p:variable name="maximum-key-security" select="substring-before($base-uri, '/')"/><!-- 'public' or 'internal' -->
	<p:variable name="relative-uri" select="substring-after($base-uri, '/')"/><!-- '' or 'register' -->
	<p:choose>
		<p:when test=" not($maximum-key-security = ('public', 'internal') ) ">
			<z:not-found/>
		</p:when>
		<p:when test=" $relative-uri='' ">
			<p:sink/>
			<nma:signup-form>
				<p:with-option name="maximum-key-security" select="$maximum-key-security"/>
			</nma:signup-form>
		</p:when>
		<p:when test=" $relative-uri='register' ">	
			<p:www-form-urldecode name="fields">
				<p:with-option name="value" select="/"/>
			</p:www-form-urldecode>
			<nma:process-signup>
				<p:with-option name="maximum-key-security" select="$maximum-key-security"/>
				<!-- if $maximum-key-security = 'public' then process-signup should not mint an 'internal' key -->
				<p:input port="fields">
					<p:pipe step="fields" port="result"/>
				</p:input>
			</nma:process-signup>
		</p:when>
		<p:otherwise>
			<z:not-found/>
		</p:otherwise>
	</p:choose>
		
	<p:declare-step name="signup-form" type="nma:signup-form">
		<p:option name="maximum-key-security"/>
		<p:output port="result"/>
		<p:load href="../signup.html"/>
		<p:choose>
			<p:when test="$maximum-key-security = 'public' ">
				<!-- the form is unauthenticated and should mint only public API keys, so remove the other option -->
				<p:delete match="//html:select[@id='user-group']/html:option[@value='internal']"/>
			</p:when>
			<p:otherwise>
				<!-- the signup form is authenticated, so it can offer both 'public' and 'internal' API keys -->
				<p:identity/>
			</p:otherwise>
		</p:choose>
		<z:make-http-response content-type="application/xhtml+xml"/>
	</p:declare-step>
	
	<p:documentation>Send an email using the sendemail command-line client</p:documentation>
	<p:declare-step name="send-email" type="nma:send-email">
		<p:input port="source"/>
		<p:option name="to" required="true"/>
		<p:option name="cc" select=" () "/>
		<p:option name="bcc" select=" () "/>
		<p:option name="from" required="true"/>
		<p:option name="subject" required="true"/>
		
		<!-- construct the command-line arguments for the sendemail command -->
		<p:in-scope-names name="email-fields"/>
		<p:xslt name="sendemail-args">
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="source">
				<p:pipe step="email-fields" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet version="2.0" 
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
						xmlns:c="http://www.w3.org/ns/xproc-step">
						<xsl:template match="/">
							<args>
								<xsl:for-each select="/c:param-set/c:param">
									<xsl:choose>
										<xsl:when test=" @name='to' ">
											<arg>-t</arg>
										</xsl:when>
										<xsl:when test=" @name='cc' ">
											<arg>-cc</arg>
										</xsl:when>
										<xsl:when test=" @name='bcc' ">
											<arg>-bcc</arg>
										</xsl:when>
										<xsl:when test=" @name='from' ">
											<arg>-f</arg>
										</xsl:when>
										<xsl:when test=" @name='subject' ">
											<arg>-u</arg>
										</xsl:when>
									</xsl:choose>
									<arg><xsl:value-of select="@value"/></arg>
								</xsl:for-each>
								<arg>-o</arg>
								<arg>message-charset=UTF-8</arg>
								<arg>-o</arg>
								<arg>message-content-type=html</arg>
							</args>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<p:exec name="sendemail" command="sendemail" source-is-xml="true" result-is-xml="false" arg-separator="&#x0A;">
			<p:with-option name="args" select="string-join(/args/arg, '&#x0A;')"/>
			<p:input port="source">
				<p:pipe step="send-email" port="source"/>
			</p:input>
		</p:exec>
		<p:sink/>
		<!-- debugging -->
		<p:store href="/tmp/email-response.txt">
			<p:input port="source">
				<p:pipe step="sendemail" port="result"/>
			</p:input>
		</p:store>
		<p:store href="/tmp/email-errors.txt">
			<p:input port="source">
				<p:pipe step="sendemail" port="errors"/>
			</p:input>
		</p:store>
	</p:declare-step>
	
	<p:declare-step name="get-api-key" type="nma:get-api-key">
		<p:output port="result"/>
		<p:option name="name" required="true"/>
		<p:option name="email" required="true"/>
		<p:option name="user-group" required="true"/>
		<!-- first create a consumer (user) -->
		<!-- 
		Kong username is a unique id, which needs to be unique even if the name/email/user-group combo is not,
		because a single user may wish to mint different API keys with the same security level for different apps.
		The username needs to include some identifying characteristic to support logging and admin. TODO: check if that's true.
		For uniqueness, the name also includes a random code.
		-->
		<p:variable name="random-id" select="current-dateTime()"/>
		<p:variable name="username" select="
			concat(
				$name,
				' &lt;', 
				$email, 
				'(', 
				$user-group,
				' [',
				$random-id,
				'])&gt;'
			)
		"/>
		<p:template name="create-user-request">
			<p:with-param name="username" select="$username"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<fn:map>
						<fn:string key="username">{$username}</fn:string>
						<fn:string key="custom_id">{$username}</fn:string>
					</fn:map>
				</p:inline>
			</p:input>
		</p:template>
		<kong:write name="create-user" method="post" uri="http://localhost:8001/consumers/"/>
		<p:sink/>
		<!-- above may fail if  user already existed, but we can retrieve it now -->
		<kong:read name="get-consumer" cx:depends-on="create-user-request">
			<p:with-option name="uri" select="
				concat(
					'http://localhost:8001/consumers/?custom_id=',
					encode-for-uri($username)
				)
			"/>
		</kong:read>
		<!-- specify the appropriate user group for the new user -->
		<p:template name="specify-user-group">
			<p:with-param name="user-group" select="$user-group"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<map xmlns="http://www.w3.org/2005/xpath-functions">
						<string key="group">{$user-group}</string>
					</map>
				</p:inline>
			</p:input>
		</p:template>
		<cx:message>
			<p:with-option name="message" select="
				concat(
					'Adding ',
					$email,
					' to user group ',
					/fn:map/fn:string[@key='group']
				)
			"/>
		</cx:message>
		<kong:write name="add-new-user-to-specified-group" method="post">
			<p:with-option name="uri" select="
				concat(
					'http://localhost:8001/consumers/', 
					/c:response/c:body/fn:map/fn:array[@key='data']/fn:map[1]/fn:string[@key='id'],
					'/acls'
				)
			">
				<p:pipe step="get-consumer" port="result"/>
			</p:with-option>
		</kong:write>
		<p:sink/>
		<!-- for debugging, log the requests -->
		<!--
		<p:store href="/tmp/create-user.xml" indent="true">
			<p:input port="source">
				<p:pipe step="create-user" port="log"/>
			</p:input>
		</p:store>
		<p:store href="/tmp/get-consumer.xml" indent="true">
			<p:input port="source">
				<p:pipe step="get-consumer" port="log"/>
			</p:input>
		</p:store>
		<p:store href="/tmp/add-new-user-to-specified-group.xml" indent="true">
			<p:input port="source">
				<p:pipe step="add-new-user-to-specified-group" port="log"/>
			</p:input>
		</p:store>
		-->
		<!-- mint an API key for the user (NB kong:read is used instead of kong:write because there's no data to send) -->
		<kong:write name="add-key-to-consumer" method="post">
			<p:with-option name="uri" select="
				concat(
					'http://localhost:8001/consumers/', 
					/c:response/c:body/fn:map/fn:array[@key='data']/fn:map[1]/fn:string[@key='id'],
					'/key-auth'
				)
			">
				<p:pipe step="get-consumer" port="result"/>
			</p:with-option>
			<p:input port="source">
				<p:inline>
					<fn:map>
						<!-- an empty map is required here since HTTP POST implies a request payload -->
					</fn:map>
				</p:inline>
			</p:input>
		</kong:write>
		<!-- expect: 
		{
			 "consumer_id": "876bf719-8f18-4ce5-cc9f-5b5af6c36007",
			 "created_at": 1443371053000,
			 "id": "62a7d3b7-b995-49f9-c9c8-bac4d781fb59",
			 "key": "62eb165c070a41d5c1b58d9d3d725ca1"
		}
		-->	
	</p:declare-step>
	
	<p:declare-step name="process-signup" type="nma:process-signup">
		<p:option name="maximum-key-security" select=" 'public' "/><!-- do not mint 'internal' keys if $maximum-key-security is 'public' -->
		<p:input port="fields"/>
		<p:output port="result"/>
		<!-- get data from posted form fields -->
		<p:variable name="email" select="/c:param-set/c:param[@name='email']/@value"/>
		<p:variable name="name" select="
			string-join(
				(
					/c:param-set/c:param[@name='first-name']/@value,
					/c:param-set/c:param[@name='last-name']/@value
				),
				' '
			)
		"/>
		<p:variable name="user-group"  select="
			if ($maximum-key-security='internal') then 
				/c:param-set/c:param[@name='user-group']/@value
			else 
				'public' 
		"/>
		<p:variable name="subject" select="concat('NMA Collections API Key for ', if (normalize-space($name)) then $name else 'you')"/>
		
		<!--		<cx:message message="getting API key ..."/>-->
		<nma:get-api-key name="api-key">
			<p:with-option name="name" select="$name"/>
			<p:with-option name="email" select="$email"/>
			<p:with-option name="user-group" select="$user-group"/>
		</nma:get-api-key>
		<p:sink/>
		<!--
		<cx:message message="retrieved API key"/>
		<p:store href="/tmp/api-key.xml" indent="true"/>
		-->
		<!--
		<kong:read uri="http://localhost:8001/consumers/"/>
		<p:store href="/tmp/kong-consumers.xml" indent="true"/>
		-->
		<p:template name="email-response">
			<p:input port="parameters">
				<p:pipe step="process-signup" port="fields"/>
			</p:input>
			<p:input port="source">
				<p:pipe step="api-key" port="result"/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fn="http://www.w3.org/2005/xpath-functions">
						<head>
							<title>API Key Registration Complete</title>
							<style type="text/css">
								body {{
									font-family: Helvetica, Arial, sans-serif;
									font-size: 16pt;
								}}
								table {{
									background: #e1e1e1;
									color: #333;
									padding: 15px;
								}}
								caption {{
									color: #524e3e;
								}}
								th {{
									text-align: right;
								}}
								h1 {{
									font-size: 24pt;
								}}
							</style>
						</head>
						<body>
							<h1>Hi {$first-name},</h1>
							<p>Thank you for registering for an API key. Your code is:</p>
							<p><code>{/c:response/c:body/fn:map/fn:string[@key='key']}</code></p>
							<p>To get started, <a href="https://github.com/NationalMuseumAustralia/Collection-API/wiki/Getting-started">view the documentation on GitHub</a>.</p>
							<p>We hope you enjoy using the API. Please let us know how you are using it, or email feedback or questions to <a href="mailto:api@nma.gov.au">api@nma.gov.au</a></p>
							<p>National Museum of Australia</p>
							<p>Collection Explorer</p>
							<table>
								<caption>Registration Details</caption>
								<tr>
									<th>First name</th><td>{$first-name}</td>
								</tr>
								<tr>
									<th>Last name</th><td>{$last-name}</td>
								</tr>
								<tr>
									<th>Organisation</th><td>{$organisation}</td>
								</tr>
								<tr>
									<th>Email</th><td>{$email}</td>
								</tr>
								<tr>
									<th>User group</th><td>{$user-group}</td>
								</tr>
								<tr>
									<th>Use of the API</th><td>{$use}</td>
								</tr>
								<tr>
									<th>Website</th><td>{$website}</td>
								</tr>
							</table>
						</body>
					</html>		
				</p:inline>
			</p:input>
		</p:template>
		<nma:send-email 
			from="NMA API Registration (do not reply) &lt;no-reply@nma.gov.au&gt;">
			<p:with-option name="subject" select="$subject"/>
			<p:with-option name="to" select="concat($name, ' &lt;', $email, '&gt;') "/>
			<p:input port="source">
				<p:pipe step="email-response" port="result"/>
			</p:input>
		</nma:send-email>
		<!--
		<p:store href="/tmp/fields.xml">
			<p:input port="source">
				<p:pipe step="process-signup" port="fields"/>
			</p:input>
		</p:store>
		-->
		
		<!-- Create response web page -->
		<p:identity name="http-response">
			<p:input port="source">
				<p:inline>
					<c:response status="303">
						<c:header name="location" value="http://www.nma.gov.au/collections/api/thankyou"/>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
		<!--
		<p:template name="http-response">
			<p:input port="parameters">
				<p:pipe step="process-signup" port="fields"/>
			</p:input>
			<p:input port="source">
				<p:empty/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<c:response status="200">
						<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
						<c:header name="Server" value="XProc-Z"/>
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head>
									<title>API Key Registration Complete</title>
								</head>
								<body>
									<h1>API Key Registration Complete</h1>
									<p>Thanks {$first-name}! Check your email address <strong>{$email}</strong> for your API key (remember to check in your spam filter, if you don't see the email)</p>
								</body>
							</html>						
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:template>-->
	</p:declare-step>
	
	<p:declare-step name="read" type="kong:read">
		<p:option name="uri" required="true"/><!-- e.g. "http://localhost:8001/consumers/" -->
		<p:option name="method" select=" 'get' "/><!-- default HTTP method for reading is 'get' -->
		<p:output port="result" primary="true">
			<p:pipe step="convert-to-xml" port="result"/>
		</p:output>
		<p:output port="log">
			<p:pipe step="log" port="result"/>
		</p:output>
		<p:xslt name="create-request">
			<p:with-param name="uri" select="$uri"/>
			<p:with-param name="method" select="$method"/>
			<p:input port="source"><p:inline><dummy/></p:inline></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
						xmlns:c="http://www.w3.org/ns/xproc-step" 
						xmlns:f="http://www.w3.org/2005/xpath-functions"
						xmlns:map="http://www.w3.org/2005/xpath-functions/map">
						<xsl:param name="uri"/>
						<xsl:param name="method"/>
						<xsl:template match="/">
							<c:request
								method="{$method}"
								detailed="true"
								override-content-type="text/plain"
								href="{$uri}"/>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<!--
		<p:store href="/tmp/kong-read-request.xml"/>
		<p:identity>
			<p:input port="source">
				<p:pipe step="create-request" port="result"/>
			</p:input>
		</p:identity>
		-->
		<!-- make http request -->
		<p:http-request/>
		<!-- convert result from json to xml -->
		<kong:json-to-xml name="convert-to-xml"/>
		<p:wrap-sequence name="log" wrapper="operation">
			<p:input port="source">
				<p:pipe step="create-request" port="result"/>
				<p:pipe step="convert-to-xml" port="result"/>
			</p:input>
		</p:wrap-sequence>
	</p:declare-step>	
	
	<p:declare-step name="write" type="kong:write">
		<p:option name="uri" required="true"/><!-- e.g. "http://localhost:8001/consumers/" -->
		<p:option name="method" required="true"/>
		<p:input port="source"/>
		<p:output port="result" primary="true">
			<p:pipe step="convert-to-xml" port="result"/>
		</p:output>
		<p:output port="log">
			<p:pipe step="log" port="result"/>
		</p:output>
		<p:xslt name="create-request">
			<p:with-param name="uri" select="$uri"/>
			<p:with-param name="method" select="$method"/>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
						xmlns:c="http://www.w3.org/ns/xproc-step" 
						xmlns:f="http://www.w3.org/2005/xpath-functions"
						xmlns:map="http://www.w3.org/2005/xpath-functions/map">
						<xsl:param name="uri"/>
						<xsl:param name="method"/>
						<xsl:template match="/">
							<c:request
								method="{$method}"
								detailed="true"
								override-content-type="text/plain"
								href="{$uri}">
								<c:body content-type="application/json">
									<xsl:copy-of select="xml-to-json(*)"/>
								</c:body>
							</c:request>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<!-- make http request -->
		<p:http-request/>
		<!-- convert result from json to xml -->
		<kong:json-to-xml name="convert-to-xml"/>
		<p:wrap-sequence name="log" wrapper="operation">
			<p:input port="source">
				<p:pipe step="create-request" port="result"/>
				<p:pipe step="convert-to-xml" port="result"/>
			</p:input>
		</p:wrap-sequence>
	</p:declare-step>
	
	<p:declare-step name="json-to-xml" type="kong:json-to-xml">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:xslt name="convert-to-xml">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
						xmlns:c="http://www.w3.org/ns/xproc-step" 
						xmlns:f="http://www.w3.org/2005/xpath-functions"
						xmlns:map="http://www.w3.org/2005/xpath-functions/map">
						<xsl:template match="*">
							<xsl:copy>
								<xsl:copy-of select="@*"/>
								<xsl:apply-templates/>
							</xsl:copy>
						</xsl:template>
						<xsl:template match="c:body">
							<xsl:copy>
								<xsl:copy-of select="json-to-xml(.)"/>
							</xsl:copy>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
</p:declare-step>
