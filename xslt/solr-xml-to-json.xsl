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
		<xsl:text>{&#xA;</xsl:text>
		<xsl:apply-templates/>
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
					<xsl:apply-templates/>
					<xsl:text>,&#xA;</xsl:text>
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

	<!-- old RDF crap -->
	
	<xsl:template match="/rdf:RDF">
		<json>
		[
			<xsl:apply-templates mode="subject-or-object"/>
		]
		</json>
	</xsl:template>
	
	<xsl:template match="*" mode="subject-or-object">
		<xsl:if test="position() &gt; 1">,</xsl:if>
		{
		<xsl:apply-templates select="." mode="id-and-type"/>
		<xsl:apply-templates select="*" mode="predicate"/>
		}
	</xsl:template>
	
	<xsl:template match="text()[normalize-space()]" mode="subject-or-object">
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
	
	<xsl:template match="*" mode="predicate">,
		<xsl:text>"</xsl:text>
		<xsl:value-of select="concat(namespace-uri(.), local-name(.))"/>
		<xsl:text>": </xsl:text> 
		<xsl:apply-templates select="* | text()[normalize-space()] | @rdf:about | @rdf:ID | @rdf:resource" mode="subject-or-object"/>
	</xsl:template>
	
	<xsl:template match="@rdf:about | @rdf:resource" mode="subject-or-object">
		{
			"@id": "<xsl:value-of select="resolve-uri(., (ancestor-or-self::*/@xml:base)[1])"/>"
		}
	</xsl:template>
	
	<xsl:template match="@rdf:ID" mode="subject-or-object">
		{
			"@id": "<xsl:value-of select="resolve-uri(concat('#', .), (ancestor-or-self::*/@xml:base)[1])"/>"
		}
	</xsl:template>
	
	<xsl:template match="*" mode="id-and-type">
		<xsl:text>"@id": "</xsl:text>
			<xsl:choose>
				<xsl:when test="@rdf:about">
					<xsl:value-of select="resolve-uri(@rdf:about, (ancestor-or-self::*/@xml:base)[1])"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="resolve-uri(concat('#', @rdf:ID), (ancestor-or-self::*/@xml:base)[1])"/>
				</xsl:otherwise>
			</xsl:choose>
		<xsl:text>",
		"@type": "</xsl:text>
		<xsl:value-of select="concat(namespace-uri(.), local-name(.))"/>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
</xsl:stylesheet>
