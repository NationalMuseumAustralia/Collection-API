<?xml version="1.1"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:c="http://www.w3.org/ns/xproc-step" >
	
	<xsl:template match="/response">
		<c:response status="{if (result/@numFound='0') then '404' else '200'}" content-type="application/json">
			<c:body content-type="application/json">
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
		<xsl:value-of select="arr[@name='json-ld']"/>
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
