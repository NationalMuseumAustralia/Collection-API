<p:declare-step version="1.0" name="signup"  type="nma:signup"
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 	
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:kong="tag:conaltuohy.com,2018:kong"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
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
	
	<p:input port='parameters' kind='parameter' primary='true'/>
	<p:output port="result" primary="true" sequence="true"/>
	<p:import href="xproc-z-library.xpl"/>	
	<p:variable name="relative-uri" select="substring-after(/c:request/@href, '/xproc-z/')"/>
	<p:choose>
		<p:when test=" $relative-uri='signup' ">
			<p:sink/>
			<nma:signup-form/>
		</p:when>
		<p:when test=" $relative-uri='register' ">	
			<p:www-form-urldecode name="fields">
				<p:with-option name="value" select="/"/>
			</p:www-form-urldecode>
			<nma:process-signup>
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
		<p:output port="result"/>
		<p:http-request>
			<p:input port="source">
				<p:inline>
					<c:request href="../signup.html" method="get"/>
				</p:inline>
			</p:input>
		</p:http-request>
		<z:make-http-response content-type="text/html"/>
	</p:declare-step>
	
	<p:documentation>Send an email using the sendemail command-line client</p:documentation>
	<p:declare-step name="send-email" type="nma:send-email">
		<p:input port="source"/>
		<p:option name="to-email" required="true"/>
		<p:option name="to-name" required="true"/>
		<p:option name="from-email" required="true"/>
		<p:option name="from-name" required="true"/>
		<p:option name="subject" required="true"/>
		<p:template name="sendemail-args">
			<p:with-param name="to-email" select="$to-email"/>
			<p:with-param name="to-name" select="$to-name"/>
			<p:with-param name="from-email" select="$from-email"/>
			<p:with-param name="from-name" select="$from-name"/>
			<p:with-param name="subject" select="$subject"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline><args>
					<arg>-t</arg>
					<arg>{$to-name} &lt;{$to-email}&gt;</arg>
					<arg>-u</arg>
					<arg>{$subject}</arg>
					<arg>-f</arg>
					<arg>{$from-name} &lt;{$from-email}&gt;"</arg>
					<arg>-o</arg>
					<arg>message-charset=UTF-8</arg>
					<arg>-o</arg>
					<arg>message-content-type=html</arg>
				</args></p:inline>
			</p:input>
		</p:template>
		<p:exec name="sendemail" command="sendemail" source-is-xml="true" result-is-xml="false" arg-separator="&#x0A;">
			<p:with-option name="args" select="string-join(/args/arg, '&#x0A;')"/>
			<p:input port="source">
				<p:pipe step="send-email" port="source"/>
			</p:input>
		</p:exec>
		<p:store href="/tmp/email-response.txt"/>
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
		<!-- first create a consumer (user) -->
		<p:template name="create-user-request">
			<p:with-param name="name" select="$name"/>
			<p:with-param name="email" select="$email"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<fn:map>
						<fn:string key="username">{$name}</fn:string>
						<fn:string key="custom_id">{$email}</fn:string>
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
					encode-for-uri($email)
				)
			"/>
		</kong:read>
		<!-- specify the appropriate user group for the new user -->
		<p:template name="specify-user-group">
			<p:with-param name="group" select="
				if (
					$email = ('conal.tuohy@gmail.com', 'staplegunn@gmail.com') or 
					matches($email, '.*@nma\.gov\.au', 'i')
				) then 
					'internal' 
				else 
					'public'
			"/>
			<p:input port="source"><p:empty/></p:input>
			<p:input port="template">
				<p:inline>
					<map xmlns="http://www.w3.org/2005/xpath-functions">
						<string key="group">{$group}</string>
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
		<p:variable name="subject" select="concat('NMA Collections API Key for ', if (normalize-space($name)) then $name else 'you')"/>
		
		<cx:message message="getting API key ..."/>
		<nma:get-api-key name="api-key">
			<p:with-option name="name" select="$name"/>
			<p:with-option name="email" select="$email"/>
		</nma:get-api-key>
		<cx:message message="retrieved API key"/>
		<p:store href="/tmp/api-key.xml" indent="true"/>
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
						</head>
						<body>
							<p>Hi {$first-name},</p>
							<p>Thank you for registering for an API key. Your code is:</p>
							<p><code>{/c:response/c:body/fn:map/fn:string[@key='key']}</code></p>
							<p>To get started, <a href="https://github.com/Conal-Tuohy/NMA-API/wiki/Getting-started">view the documentation on GitHub</a>.</p>
							<p>We hope you enjoy using the API. Please let us know how you are using it, or email feedback or questions to <a href="mailto:api@nma.gov.au">api@nma.gov.au</a></p>
							<p>National Museum of Australia</p>
							<p>Collection Explorer</p>
						</body>
					</html>		
				</p:inline>
			</p:input>
		</p:template>
		<nma:send-email 
			from-name="NMA API Registration (do not reply)" 
			from-email="no-reply@nma.gov.au">
			<p:with-option name="subject" select="$subject"/>
			<p:with-option name="to-email" select="$email"/>
			<p:with-option name="to-name" select="$name"/>
			<p:input port="source">
				<p:pipe step="email-response" port="result"/>
			</p:input>
		</nma:send-email>
		
		<p:parameters name="form-parameters"/>
		
		<!-- email the API key -->
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
		</p:template>
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
