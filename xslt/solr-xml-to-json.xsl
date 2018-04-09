<?xml version="1.1"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:c="http://www.w3.org/ns/xproc-step"  xmlns:nma="tag:conaltuohy.com,2018:nma">
	
	<!-- content negotiation -->
	<!-- if the format parameter is present, it identifies one of the payload fields; "simple" or "json-ld" -->
	<!-- if the format parameter is absent then a format is chosen based on the HTTP accept header -->
	<!-- or as a last resort a buillt in default is chosen -->
	<xsl:param name="accept" select=" 'application/json' "/>
	<xsl:param name="format"/>
	
	<xsl:variable name="accept-header-types">
		<xsl:element name="types">
			<xsl:analyze-string select="$accept" regex="[^,]+">
				<xsl:matching-substring>
					<xsl:element name="type">
						<xsl:analyze-string select="normalize-space(.)" regex="([^\s;]+)(.*)">
							<xsl:matching-substring>
								<xsl:attribute name="name" select="regex-group(1)"/>
								
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
	
	<xsl:function name="nma:content-type-preference">
		<xsl:param name="content-type"/>
		<xsl:variable name="specified-type" select="$accept-header-types/types/type[@name=$content-type]"/>
		<xsl:choose>
			<xsl:when test="not($specified-type)">0.0</xsl:when>
			<xsl:otherwise><xsl:value-of select="($specified-type/@q, 1.0)[1]"/></xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:variable name="response-format">
		<xsl:choose>
			<xsl:when test="$format">
				<xsl:value-of select="$format"/>
			</xsl:when>
			<xsl:when test="number(nma:content-type-preference('application/ld+json')) &gt;= number(nma:content-type-preference('application/json'))">
				<xsl:text>json-ld</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>simple</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:template match="/response">
		<c:response status="{if (result/@numFound='0') then '404' else '200'}">
			<c:body content-type="{if ($response-format='json-ld') then 'application/ld+json' else 'application/json'}">
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
	
	<!-- a JSON object -->
	<xsl:template match="doc">
		<xsl:value-of select="arr[@name=$response-format]"/>
	</xsl:template>
	
	<xsl:template match="doc" priority="-999"><!-- obsolete -->
		<xsl:text>{&#xA;</xsl:text>
		<!-- Solr generates an alias of each property name (an artefact of the "schemaless" mode is creating an explicit "string" version of each property -->
		<!-- which we can ignore -->
		<!-- and the _version_ field can go too -->
		<xsl:apply-templates select="*[not(@name='_version_')][not(ends-with(@name, '_str'))]"/>
		<xsl:text>&#xA;}</xsl:text>
	</xsl:template>
	


	<!-- a JSON object property/value pair -->
	<xsl:template match="doc/*">
		<xsl:value-of select="
			concat(
				'&quot;',
				@name,
				'&quot;: '
			)
		"/>
		<xsl:variable name="string-values" select="descendant-or-self::str"/>
		<xsl:choose>
			<xsl:when test="count($string-values) = 1">
				<xsl:apply-templates select="$string-values[1]/text()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>[</xsl:text>
				<xsl:for-each select="$string-values">
					<xsl:if test="position() &gt; 1">
						<xsl:text>,&#xA;</xsl:text>
					</xsl:if>
					<xsl:apply-templates/>
				</xsl:for-each>
				<xsl:text>]</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="not(position() = last())">,&#xA;</xsl:if>
	</xsl:template>
	
	<xsl:template match="text()[normalize-space()]">
		<xsl:text>"</xsl:text>
		<xsl:variable name="regex">[&quot;\\&#x1;-&#x1F;]</xsl:variable>
		<xsl:analyze-string select="." regex="{$regex}">
			<xsl:matching-substring>
				<xsl:text>\u</xsl:text>
				<xsl:value-of select="format-number(string-to-codepoints(.), '0000')"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring><xsl:value-of select="."/></xsl:non-matching-substring>
		</xsl:analyze-string>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
</xsl:stylesheet>
