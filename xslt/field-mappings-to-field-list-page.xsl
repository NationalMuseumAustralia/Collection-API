<?xml version="1.1"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="text" indent="no" encoding="UTF-8"
		omit-xml-declaration="yes" />

	<xsl:import href="field-mappings-to-markdown.xsl" />

	<xsl:template match="/">

		<!-- ToC -->
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>On this page:&#xa;</xsl:text>
		<xsl:call-template name="displayToC">
			<xsl:with-param name="value" select=" 'Object' " />
		</xsl:call-template>
		<xsl:call-template name="displayToC">
			<xsl:with-param name="value" select=" 'Narrative' " />
		</xsl:call-template>
		<xsl:call-template name="displayToC">
			<xsl:with-param name="value" select=" 'Party' " />
		</xsl:call-template>
		<xsl:call-template name="displayToC">
			<xsl:with-param name="value" select=" 'Place' " />
		</xsl:call-template>
		<xsl:text>&#xa;</xsl:text>

		<!-- Body -->
		<xsl:call-template name="displaySection">
			<xsl:with-param name="value" select=" 'Object' " />
		</xsl:call-template>
		<xsl:call-template name="displaySection">
			<xsl:with-param name="value" select=" 'Narrative' " />
		</xsl:call-template>
		<xsl:call-template name="displaySection">
			<xsl:with-param name="value" select=" 'Party' " />
		</xsl:call-template>
		<xsl:call-template name="displaySection">
			<xsl:with-param name="value" select=" 'Place' " />
		</xsl:call-template>
		<xsl:text>&#xa;</xsl:text>

	</xsl:template>

	<xsl:template name="displayToC">
		<xsl:param name="value" />

		<xsl:text>* [</xsl:text>
		<xsl:value-of select="$value" />
		<xsl:text> field reference](#</xsl:text>
		<xsl:value-of select="$value" />
		<xsl:text>-field-reference)&#xa;</xsl:text>

		<xsl:text>* [</xsl:text>
		<xsl:value-of select="$value" />
		<xsl:text> field map](#</xsl:text>
		<xsl:value-of select="$value" />
		<xsl:text>-field-map)&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="displaySection">
		<xsl:param name="value" />

		<!-- headings -->
		<xsl:text>&lt;a name="</xsl:text>
		<xsl:value-of select="$value" />
		<xsl:text>-field"&gt;&lt;/a&gt;&#xa;</xsl:text>
		<xsl:text># </xsl:text>
		<xsl:value-of select="$value" />
		<xsl:text> fields&#xa;</xsl:text>

		<xsl:apply-templates select="data" mode="list">
			<xsl:with-param name="dataset" select="$value" />
		</xsl:apply-templates>
		<xsl:apply-templates select="data" mode="map">
			<xsl:with-param name="dataset" select="$value" />
		</xsl:apply-templates>
	</xsl:template>

</xsl:stylesheet>
