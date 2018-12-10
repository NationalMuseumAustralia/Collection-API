<?xml version="1.1"?>
<xsl:stylesheet version="3.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	exclude-result-prefixes="f">
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="c:body[not(f:*)]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:attribute name="content-type">application/xml</xsl:attribute>
			<xsl:copy-of select="json-to-xml(.)"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="c:body[f:*]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:attribute name="content-type">application/json</xsl:attribute>
			<xsl:value-of select="xml-to-json(*, map{'indent': true()})"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>