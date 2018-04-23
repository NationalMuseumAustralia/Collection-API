<?xml version="1.1"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:c="http://www.w3.org/ns/xproc-step"  xmlns:nma="tag:conaltuohy.com,2018:nma">
	
	<!-- content negotiation -->
	<!-- if the "format" URL parameter is present, it identifies one of the payload fields; "simple" or "json-ld" -->
	<xsl:param name="format"/>
	<!-- if the format parameter is absent then a format is chosen based on the HTTP "Accept" header -->
	<xsl:param name="accept"/>
	<!-- (or as a last resort the "simple" JSON format is chosen) -->
	
	<!-- the current API query URI, used when generating a "next" link -->
	<xsl:param name="relative-uri"/>
	
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
	<xsl:template match="/response">
		<xsl:variable name="result-count" select="number(result/@numFound)"/>
		<!-- define the HTTP response; a 404 "Not found" if nothing was found, otherwise a 200 "OK" -->
		<c:response status="{if ($result-count=0) then '404' else '200'}">
			<c:header name="Result-Count" value="{$result-count}"/>
			<xsl:variable name="result-count-so-far" select="number(result/@start) + count(result/doc)"/>
			<xsl:if test="$result-count &gt; $result-count-so-far">
				<!-- The current page of records does not exhaust the result set -->
				<!-- Generate a link that points to the next page, by constructing a new API query URI with the old 'offset' parameter
				removed, and a new 'offset' parameter which reflects the number of records returned in this response. -->
				<xsl:variable name="object-type" select="substring-before($relative-uri, '?')"/><!-- e.g. 'object', 'party' etc. -->
				<xsl:variable name="query-parameters" select="tokenize(substring-after($relative-uri, '?'), '&amp;')"/>
it				<c:header name="Link" value="&lt;{
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
				}&gt;; rel=next"/>
			</xsl:if>
			<!-- specify which format the result is being returned in -->
			<c:body content-type="{if ($response-format='json-ld') then 'application/ld+json' else 'application/json'}">
				<!-- output the actual result data -->
				<xsl:apply-templates select="result"/>
			</c:body>
		</c:response>
	</xsl:template>
	
	<xsl:template match="result[not(@numFound = '1')]">
		<!-- if the number of items found is not exactly 1, then wrap the response in a JSON array object -->
		<xsl:text>[&#xA;</xsl:text>
		<xsl:for-each select="doc">
			<xsl:if test="position() > 1">
				<xsl:text>,&#xA;</xsl:text>
			</xsl:if>
			<xsl:apply-templates select="."/>
		</xsl:for-each>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<!-- Represent an individual search result simply by selecting the appropriate format payload field from within it -->
	<xsl:template match="doc">
		<xsl:value-of select="arr[@name=$response-format]"/>
	</xsl:template>
		
</xsl:stylesheet>
