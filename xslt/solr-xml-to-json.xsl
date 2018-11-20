<?xml version="1.1"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:c="http://www.w3.org/ns/xproc-step"  xmlns:nma="tag:conaltuohy.com,2018:nma">
	
	<!-- search result pagination -->
	<xsl:variable name="result-count" select="number(/response/result/@numFound)"/>
	<xsl:variable name="result-count-so-far" select="number(/response/result/@start) + count(/response/result/doc)"/>
	<xsl:variable name="object-type" select="substring-before($relative-uri, '?')"/><!-- e.g. 'object', 'party' etc. -->
	<xsl:variable name="query-parameters" select="tokenize(substring-after($relative-uri, '?'), '&amp;')"/>
	<xsl:param name="host-name" select=" 'data.nma.gov.au' "/> 
	
	<!-- the latest version of the 'simple' data format; used when no particular version was requested explicitly -->
	<xsl:variable name="latest-version" select=" '2' "/>
	
	<!-- Generate a link that points to the next page, by constructing a new API query URI with the old 'offset' parameter
	removed, and a new 'offset' parameter which reflects the number of records returned in this response. -->
	<xsl:variable name="next-page-link" select="
		concat(
			$object-type,
			'?',
			string-join(
				(
					$query-parameters
						[not(starts-with(., 'offset='))]
						[substring-after(., '=')],
					concat(
						'offset=', 
						$result-count-so-far
					)
				),
				'&amp;'
			)
		)
	"/>	
	<xsl:variable name="first-page-link" select="
		concat(
			$object-type,
			'?',
			string-join(
				(
					$query-parameters
						[not(starts-with(., 'offset='))]
						[substring-after(., '=')]
				),
				'&amp;'
			)
		)
	"/>
		
	<!-- content negotiation -->
	<!-- if the "format" URL parameter is present, it identifies one of the payload fields; "simple" or "json-ld" -->
	<xsl:param name="format"/>
	<!-- if the format parameter is absent then a format is chosen based on the HTTP "Accept" header -->
	<xsl:param name="accept"/>
	<!-- (or as a last resort the "simple" JSON format is chosen) -->
	
	<!-- the current API query URI, used when generating a "next" link -->
	<xsl:param name="relative-uri"/>
	
	<!-- the dataset requested ("public" or "internal"); needed so that "internal" requests can be cached by proxies separately from "public" data -->
	<xsl:param name="dataset"/>
	
	<!-- determine whether the request is a search request, or a retrieval of a single resource -->
	<!-- by attempting to match the request URI to a pattern like "object/12345" --> 
	<xsl:variable name="is-search-request" select="not(matches($relative-uri, '[^/]*/.*'))"/>
	
	<!-- The format to return result data in -->
	<xsl:variable name="response-format">
		<xsl:choose>
			<!-- if the API user has specified a "format" parameter in their request URI, then this is the format chosen -->
			<xsl:when test="$format">
				<xsl:value-of select="$format"/>
			</xsl:when>
			<!-- otherwise, if the API sent an HTTP "Accept" header, and it rates JSON-LD above JSON, then json-ld is the format chosen -->
			<xsl:when test="number(nma:content-type-preference('application/ld+json')) &gt; number(nma:content-type-preference('application/json'))">
				<xsl:text>json-ld</xsl:text>
			</xsl:when>
			<!-- otherwise, the simple JSON output format is chosen -->
			<xsl:otherwise>
				<xsl:text>simple</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<!-- a parse tree of the HTTP "Accept" header, e.g.
		<types>
			<type name="application/xml" q="0.1"/>
			<type name="text/html"/>
			<type name="application/json" q="0.5"/>
		</types>
	-->
	<xsl:variable name="accept-header-types">
		<xsl:element name="types">
			<!-- parse the accept header into a list of types, separated by commas -->
			<xsl:analyze-string select="$accept" regex="[^,]+">
				<xsl:matching-substring>
					<xsl:element name="type">
						<!-- parse the type into a MIME content-type, optionally followd by a semi-colon and a bunch of other parameters -->
						<xsl:analyze-string select="normalize-space(.)" regex="([^\s;]+)(.*)">
							<xsl:matching-substring>
								<xsl:attribute name="name" select="regex-group(1)"/>
								<!-- parse the content type parameters (the 'q' content type is a number between 0 and 1 that gives the user's preference rating -->
								<xsl:analyze-string select="regex-group(2)" regex=";\s?([^=]+)=([^;]+)">
									<xsl:matching-substring>
										<xsl:attribute name="{regex-group(1)}" select="regex-group(2)"/>
									</xsl:matching-substring>
								</xsl:analyze-string>
							</xsl:matching-substring>
						</xsl:analyze-string>
					</xsl:element>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:element>
	</xsl:variable>

	<!-- If the user requested the 'simple' format, they can specialise that with a "profile" parameter that selects a specific version of that format -->
	<!-- The profile parameter will look something like "http://nma-dev.conaltuohy.com/profile/1" -->
	<xsl:variable name="requested-version" select="
		if ($response-format = 'simple' and $accept-header-types/types/type[@name='application/vnd.api+json']/@profile) then
			substring-after(
				$accept-header-types/types/type[@name='application/vnd.api+json']/@profile,
				'/profile/'
			)
		else
			()
	"/>
	
	<!-- This preference function returns a number from 0 to 1, representing the user's expressed preference for the given content type -->
	<xsl:function name="nma:content-type-preference">
		<xsl:param name="content-type"/>
		<xsl:variable name="specified-type" select="$accept-header-types/types/type[@name=$content-type]"/>
		<xsl:choose>
			<!-- if the content type is not in the Accept header at all, the rating is 0 -->
			<xsl:when test="not($specified-type)">0.0</xsl:when>
			<!-- otherwise the rating is whatever was given in the Accept header -->
			<xsl:otherwise><xsl:value-of select="($specified-type/@q, 1.0)[1]"/></xsl:otherwise>
			<!-- This is not a totally compliant implementation of interpreting an Accept header: -->
			<!-- it doesn't handle high-level content types (e.g. "text/*", or "image/*"), or the "anything" content type "*/*" -->
			<!-- but it's complete enough for our purposes -->
		</xsl:choose>
	</xsl:function>

	<!-- Convert the Solr http response into an API response to the API user -->
	<xsl:template match="/">
		<!-- define the HTTP response; the error code supplied, or a 404 "Not found" if nothing was found, otherwise a 200 "OK" -->
		<c:response status="{
			if (/response/lst[@name='error']) then 
				/response/lst[@name='error']/int[@name='code']
			else
				if ($result-count=0) then 
					'404' 
				else if (not($is-search-request) and /response/result/doc/str[@name='status_code']) then
					/response/result/doc/str[@name='status_code']
				else
					'200'
		}">
			<xsl:call-template name="response-headers"/>
			<!-- specify which format the result is being returned in -->
			<c:body content-type="{
				if ($response-format='json-ld') then 
					'application/ld+json' 
				else 
					if ($response-version) then
						concat('application/vnd.api+json;profile=http://', $host-name, '/profile/', $response-version)
					else
						'application/vnd.api+json'
			}">
				<xsl:choose>
					<xsl:when test="/response/lst[@name='error']">
						<xsl:call-template name="return-error"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- output the actual result data -->
						<xsl:choose>
							<xsl:when test="$is-search-request">
								<!-- URI specified a search request -->
								<xsl:call-template name="return-search-results"/>
							</xsl:when>
							<xsl:otherwise>
								<!-- URI specified a request for a single resource by identifier -->
								<xsl:call-template name="return-single-resource"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</c:body>
		</c:response>
	</xsl:template>
	
	<xsl:template name="return-error">
		<xsl:choose>
			<xsl:when test="$response-format = 'json-ld'">
				{
					"context": "/context.json",
					"type": "Request",
					"id": "<xsl:value-of select="$relative-uri"/>",
					"request_uri": "<xsl:value-of select="$relative-uri"/>",
					"response": {
						"type": "Response",
						"status_code_value": <xsl:value-of select="/response/lst[@name='error']/int[@name='code']"/>,
						"reason_phrase": "<xsl:value-of select="/response/lst[@name='error']/str[@name='msg']"/>"
					}
				}
			</xsl:when>
			<xsl:otherwise><!-- JSON-API -->
				{
					"errors": [
						{
							"status": <xsl:value-of select="/response/lst[@name='error']/int[@name='code']"/>,
							"title": "<xsl:value-of select="/response/lst[@name='error']/str[@name='msg']"/>"
						}
					]
				}
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="return-single-resource">
		<xsl:choose>
			<xsl:when test="$response-format = 'json-ld'">
				<xsl:choose>
					<xsl:when test="$result-count = 0">
						<!-- no object found with that id; return a 404 -->
						{
							"context": "/context.json",
							"type": "Request",
							"id": "<xsl:value-of select="$relative-uri"/>",
							"request_uri": "<xsl:value-of select="$relative-uri"/>",
							"response": {
								"type": "Response",
								"status_code_value": 404,
								"reason_phrase": "Not found"
							}
						}
					</xsl:when>
					<xsl:when test="/response/result/doc/str[@name='status_code']">
						<!-- an explicit status code is stored; return that -->
						{
							"context": "/context.json",
							"type": "Request",
							"id": "<xsl:value-of select="$relative-uri"/>",
							"request_uri": "<xsl:value-of select="$relative-uri"/>",
							"response": {
								"type": "Response",
								"status_code_value": <xsl:value-of select="/response/result/doc/str[@name='status_code']"/>,
								"reason_phrase": "<xsl:value-of select="/response/result/doc/str[@name='reason']"/>"
							}
						}
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="/response/result/doc"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- follow JSON-API practice of wrapping result in a "data" object -->
				<xsl:choose>
					<xsl:when test="$result-count = 0">
						<xsl:text>{"data": null, "errors": [{"status": "404", "title": "Not found"}]}</xsl:text>
					</xsl:when>
					<xsl:when test="/response/result/doc/str[@name='status_code']">
						<!-- an explicit status code is stored; return that -->
						<xsl:text>{"data": null, "errors": [{"status": "</xsl:text>
						<xsl:value-of select="/response/result/doc/str[@name='status_code']"/>
						<xsl:text>", "title": "</xsl:text>
						<xsl:value-of select="/response/result/doc/str[@name='reason']"/>
						<xsl:text>"}]}</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>{"data": [</xsl:text>
						<xsl:apply-templates select="/response/result/doc"/>
						<xsl:text>]}</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="return-search-results">
		<xsl:choose>
			<xsl:when test="$response-format = 'json-ld'">
				<xsl:text>
				{"context": "/context.json",
				"id": "</xsl:text>
				<xsl:value-of select="$first-page-link"/>
				<xsl:text>",
				"type": "Aggregation",</xsl:text>
				<xsl:if test="$result-count &gt; $result-count-so-far">
					<!-- The current page of records does not exhaust the result set -->
					<xsl:text>"next": "</xsl:text>
					<xsl:value-of select="$next-page-link"/>
					<xsl:text>",</xsl:text>
				</xsl:if>
				<xsl:text>"entities": </xsl:text>
				<xsl:value-of select="$result-count"/>
				<xsl:text>,
				"aggregates": [</xsl:text>
				<xsl:for-each select="/response/result/doc">
					<xsl:if test="position() > 1">
						<xsl:text>,&#xA;</xsl:text>
					</xsl:if>
					<xsl:apply-templates select="."/>
				</xsl:for-each>
				<xsl:text>]
				}</xsl:text>
			</xsl:when>
			<xsl:otherwise><!-- JSON-API -->
				<xsl:text>{"data": [&#xA;</xsl:text>
				<xsl:for-each select="/response/result/doc">
					<xsl:if test="position() > 1">
						<xsl:text>,&#xA;</xsl:text>
					</xsl:if>
					<xsl:apply-templates select="."/>
				</xsl:for-each>
				<xsl:text>], "meta": {"results": </xsl:text>
				<xsl:value-of select="$result-count"/>
				<xsl:text>}</xsl:text>
				<xsl:if test="$result-count &gt; $result-count-so-far">
					<!-- The current page of records does not exhaust the result set -->
					<xsl:text>, "links": {"next": "</xsl:text>
					<xsl:value-of select="$next-page-link"/>
					<xsl:text>"}</xsl:text>
				</xsl:if>
				<xsl:text>}</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="response-headers">
		<!-- hint to cache for up to 24 hours -->
		<c:header name="Cache-Control" value="max-age=43200"/><!-- cache for 12 hours -->
		<xsl:if test="$accept and not($format)">
			<!-- data format was selected using the "Accept" header -->
			<c:header name="Vary" value="Accept"/>
		</xsl:if>
		<xsl:if test="$dataset='internal'">
			<!-- data is for NMA internal use and should not be served to the public by downstream proxies -->
			<c:header name="Vary" value="apikey"/>
		</xsl:if>
		<c:header name="Dataset" value="{$dataset}"/>
		<xsl:if test="$is-search-request">
			<!-- pagination headers are only useful for search requests because they produce multiple results -->
			<c:header name="Result-Count" value="{$result-count}"/>
			<xsl:if test="$result-count &gt; $result-count-so-far">
				<!-- The current page of records does not exhaust the result set -->
				<c:header name="Link" value="&lt;{$next-page-link}&gt;; rel=next"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<!-- Originally there was only one "simple" field; later this was split into multiple versions "simple_1", "simple_2" etc. -->
	<!-- Here, as a transitional arrangement, we check whether the "simple" field still exists since this means we can't choose a specific version -->
	<xsl:variable name="legacy-simple-field-exists" select="exists(*[@name='simple'])"/>
	<xsl:variable name="response-version" select="
		if ($response-format='json-ld' or $legacy-simple-field-exists) then ()
		else ($requested-version, $latest-version)[1]
	"/>
	
	<!-- Represent an individual search result simply by selecting the appropriate format payload field from within it -->
	<xsl:template match="doc">
		<xsl:variable name="payload-field-name" select="
			if ($response-version) then
				concat($response-format, '_', $response-version)
			else
				$response-format
		"/>
		<xsl:value-of select="*[@name=$payload-field-name]"/>
		<!--
		<xsl:message>
			<xsl:value-of select="concat('legacy-simple-field-exists=', $legacy-simple-field-exists)"/>.
			<xsl:value-of select="concat('response-format=', $response-format)"/>.
			<xsl:value-of select="concat('requested-version=', $requested-version)"/>.
			<xsl:value-of select="concat('payload-field-name=', $payload-field-name)"/>.
		</xsl:message>
		-->
	</xsl:template>

</xsl:stylesheet>
