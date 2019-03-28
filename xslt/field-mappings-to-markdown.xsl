<?xml version="1.1"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="text" indent="no" encoding="UTF-8"
		omit-xml-declaration="yes" />

	<xsl:param name="dataset" select=" 'Object' " />
	<xsl:param name="displayMode" select=" 'list' " />

	<xsl:template match="/">
		<xsl:choose>
			<xsl:when test="$displayMode = 'map'">
				<xsl:apply-templates select="data" mode="map" />
			</xsl:when>
			<xsl:when test="$displayMode = 'searchHints'">
				<xsl:apply-templates select="data"
					mode="searchHints" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="data" mode="list" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="/data" mode="list">
		<xsl:call-template
			name="displayFieldReferenceHeader" />
		<xsl:for-each
			select="./*[Source=$dataset and not(DC_term = '') and not(DC_term = '-') and Exclude_from_DC_help = '']">
			<xsl:variable name="record" select="." />
			<xsl:for-each select="tokenize(DC_term,',')">
				<xsl:call-template name="displayFieldReferenceRow">
					<xsl:with-param name="fieldName" select="." />
					<xsl:with-param name="record" select="$record" />
				</xsl:call-template>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="/data" mode="map">
		<xsl:call-template name="displayFieldMapHeader" />
		<xsl:for-each
			select="./*[Source=$dataset and not(CRM_relation__rdf_value_ = '') and not(CRM_relation__rdf_value_ = '-')]">
			<xsl:call-template name="displayFieldMapRow">
				<xsl:with-param name="fieldName"
					select="CRM_relation__rdf_value_" />
				<xsl:with-param name="record" select="." />
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="displayFieldReferenceHeader">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>| Path | Field | Label | Datatype | Description | Examples | Linked Art |&#xa;</xsl:text>
		<xsl:text>| ---- | ----- | ----- | -------- | ----------- | -------- | ---------- |&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="displayFieldReferenceRow">
		<xsl:param name="fieldName" />
		<xsl:param name="record" />
		<!-- split path from term -->
		<xsl:variable name="pathParts" select="tokenize(normalize-space($fieldName), '/')" />
    	<xsl:variable name="path" select="$pathParts[last() - 1]"/>
    	<xsl:variable name="term" select="$pathParts[last()]"/>
		<xsl:text>| `</xsl:text>
		<!-- loop so duplicates are preserved -->
		<xsl:for-each select="tokenize(normalize-space($fieldName), '/')">
			<xsl:if test="position() != last()">
				<xsl:value-of select="." />
			</xsl:if>
			<xsl:if test="position() &lt; (last() - 1)">
				<xsl:text>/</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>` | `</xsl:text>
		<xsl:value-of select="$term" />
		<xsl:text>` | </xsl:text>
		<xsl:value-of select="$record/Display_label" />
		<xsl:text> | </xsl:text>
		<xsl:value-of select="$record/Datatype" />
		<xsl:text> | </xsl:text>
		<xsl:value-of select="$record/Description" />
		<xsl:text> | </xsl:text>
		<!-- split examples by semi-colons -->
		<xsl:for-each select="tokenize($record/Examples,';')">
			<xsl:if test="position() != 1">
				<xsl:text>&lt;br /&gt;</xsl:text>
			</xsl:if>
			<xsl:text>`</xsl:text>
			<xsl:value-of select="normalize-space(.)" />
			<xsl:text>` </xsl:text>
		</xsl:for-each>
		<xsl:text>| `</xsl:text>
		<xsl:value-of select="$record/LA_JSON" />
		<xsl:text>`</xsl:text>
		<!-- indicate which classified_by to use to get this unique field -->
		<xsl:if test="$record/NMA_term_id/text() and not($record/NMA_term_id/text() = '-')">
			<xsl:text>&lt;br /&gt;(`classified_as nma:</xsl:text>
			<xsl:value-of select="$record/NMA_term_id/text()" />
			<xsl:text>`)</xsl:text>
		</xsl:if>
		<xsl:if test="$record/AAT_id/text() and not($record/AAT_id/text() = '-')">
			<xsl:text>&lt;br /&gt;(`classified_as aat:</xsl:text>
			<xsl:value-of select="$record/AAT_id/text()" />
			<xsl:text>`)</xsl:text>
		</xsl:if>
		<xsl:text>|&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="displayFieldMapHeader">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>| Title | CIDOC-CRM | CRM type | Linked Art JSON-LD | AAT type | DC | DC source | EMu |&#xa;</xsl:text>
		<xsl:text>| ----- | --------- | -------- | ------------------ | -------- | -- | --------- | --- |&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="displayFieldMapRow">
		<xsl:param name="fieldName" />
		<xsl:param name="record" />
		<xsl:text>| `</xsl:text>
		<xsl:value-of select="Display_label" />
		<xsl:text>` | `</xsl:text>
		<xsl:value-of select="normalize-space($fieldName)" />
		<xsl:text>` | `</xsl:text>
		<xsl:value-of select="CRM_object_type" />
		<xsl:text>` | `</xsl:text>
		<xsl:value-of select="LA_JSON" />
		<xsl:text>` | `</xsl:text>
		<xsl:value-of select="AAT_id" />
		<xsl:text>` (</xsl:text>
		<xsl:value-of select="AAT_label" />
		<xsl:text>) | `</xsl:text>
		<xsl:value-of select="DC_term" />
		<xsl:text>` | `</xsl:text>
		<xsl:value-of select="DC_term_source" />
		<xsl:text>` | `</xsl:text>
		<xsl:value-of select="EMu_field" />
		<xsl:text>` |&#xa;</xsl:text>
	</xsl:template>

</xsl:stylesheet>
