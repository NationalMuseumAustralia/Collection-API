<?xml version="1.1"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!-- Converts a single documentation markdown section (from field mappings sheet) -->
	<!-- Call multiple times to create a full field reference page -->
	
	<xsl:param name="dataset" select=" 'Object' " />
	<xsl:param name="displayMode" select=" 'list' " />
	
	<xsl:variable name="cidocLink" select=" 'http://www.cidoc-crm.org/search/content/' " />
	<xsl:variable name="laLink" select=" 'https://linked.art/ns/v1/linked-art.json' " />
	<xsl:variable name="aatLink" select=" 'http://vocab.getty.edu/aat/' " />
	<xsl:variable name="dcLink" select=" 'http://www.dublincore.org/specifications/dublin-core/dcmi-terms/#terms-' " />
	<xsl:variable name="foafLink" select=" 'http://xmlns.com/foaf/spec/#term_' " />
	<xsl:variable name="schemaLink" select=" 'https://schema.org/' " />

	<xsl:template match="/">
		<!-- use appropriate templates -->
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

	<!-- Display header and body for field reference list -->
	<xsl:template match="/data" mode="list">
		<xsl:param name="dataset" select=" 'Object' " />
		<xsl:call-template name="displayFieldReferenceHeader">
			<xsl:with-param name="dataset" select="$dataset" />
		</xsl:call-template>
		<xsl:for-each
			select="./*[Source=$dataset and not(DC_term = '') and not(DC_term = '-') and Exclude_from_DC_help = '']">
			<xsl:variable name="record" select="." />
			<xsl:for-each select="tokenize(DC_term,',')">
				<xsl:call-template name="displayFieldReferenceRow">
					<xsl:with-param name="dataset" select="$dataset" />
					<xsl:with-param name="fieldName" select="." />
					<xsl:with-param name="record" select="$record" />
				</xsl:call-template>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>

	<!-- Display header and body for field mappings -->
	<xsl:template match="/data" mode="map">
		<xsl:param name="dataset" select=" 'Object' " />
		<xsl:call-template name="displayFieldMapHeader">
			<xsl:with-param name="dataset" select="$dataset" />
		</xsl:call-template>
		<xsl:for-each
			select="./*[Source=$dataset and not(CRM_relation__rdf_value_ = '') and not(CRM_relation__rdf_value_ = '-')]">
			<xsl:call-template name="displayFieldMapRow">
				<xsl:with-param name="dataset" select="$dataset" />
				<xsl:with-param name="fieldName"
					select="CRM_relation__rdf_value_" />
				<xsl:with-param name="record" select="." />
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="displayFieldReferenceHeader">
		<xsl:param name="dataset" select=" 'Object' " />

		<xsl:text>&#xa;</xsl:text>
		<xsl:call-template name="displayAnchor">
			<xsl:with-param name="type" select=" 'name' " />
			<xsl:with-param name="dataset" select="$dataset" />
			<xsl:with-param name="field" select=" 'field-reference' " />
		</xsl:call-template>
		<xsl:text>&#xa;</xsl:text>

		<xsl:text>## </xsl:text>
		<xsl:value-of select="$dataset" />
		<xsl:text> field reference&#xa;</xsl:text>
		<xsl:text>| Path | Field | Label | Datatype | Description | Examples |&#xa;</xsl:text>
		<xsl:text>| ---- | ----- | ----- | -------- | ----------- | -------- |&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="displayFieldReferenceRow">
		<xsl:param name="dataset" select=" 'Object' " />
		<xsl:param name="fieldName" />
		<xsl:param name="record" />
		<!-- split path from term -->
		<xsl:variable name="pathParts" select="tokenize(normalize-space($fieldName), '/')" />
    	<xsl:variable name="path" select="$pathParts[last() - 1]"/>
    	<xsl:variable name="term" select="$pathParts[last()]"/>

		<xsl:text>|</xsl:text>
		<!-- Link anchor -->
		<xsl:call-template name="displayAnchor">
			<xsl:with-param name="type" select=" 'name' " />
			<xsl:with-param name="dataset" select="$dataset" />
			<xsl:with-param name="field" select="$fieldName" />
		</xsl:call-template>
		<!-- Path -->
		<xsl:variable name="fieldPath">
			<!-- loop so duplicates are preserved -->
			<xsl:for-each select="tokenize(normalize-space($fieldName), '/')">
				<xsl:if test="position() != last()">
					<xsl:value-of select="." />
				</xsl:if>
				<xsl:if test="position() &lt; (last() - 1)">
					<xsl:text>/</xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$fieldPath != '' ">
			<xsl:text> `</xsl:text>
			<xsl:value-of select="$fieldPath" />
			<xsl:text>`</xsl:text>
		</xsl:if>
		<xsl:text> | `</xsl:text>
		<!-- Field -->
		<xsl:value-of select="$term" />
		<xsl:text>` | </xsl:text>
		<!-- Label -->
		<xsl:value-of select="$record/Display_label" />
		<xsl:text> | </xsl:text>
		<!-- Datatype -->
		<xsl:value-of select="$record/Datatype" />
		<xsl:text> | </xsl:text>
		<!-- Desription -->
		<xsl:value-of select="$record/Description" />
		<xsl:text> | </xsl:text>
		<!-- Examples -->
		<xsl:call-template name="splitBySemicolon">
			<xsl:with-param name="value" select="$record/Examples" />
		</xsl:call-template>
		<xsl:text>|&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="displayFieldMapHeader">
		<xsl:param name="dataset" select=" 'Object' " />

		<xsl:text>&#xa;</xsl:text>
		<xsl:call-template name="displayAnchor">
			<xsl:with-param name="type" select=" 'name' " />
			<xsl:with-param name="dataset" select="$dataset" />
			<xsl:with-param name="field" select=" 'field-map' " />
		</xsl:call-template>
		<xsl:text>&#xa;</xsl:text>

		<xsl:text>## </xsl:text>
		<xsl:value-of select="$dataset" />
		<xsl:text> field map&#xa;</xsl:text>
		<xsl:text>| NMA Title | CIDOC-CRM | CRM type | Linked Art JSON-LD | AAT type | NMA Simple | Simple source | NMA EMu |&#xa;</xsl:text>
		<xsl:text>| --------- | --------- | -------- | ------------------ | -------- | ---------- | ------------- | ------- |&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="displayFieldMapRow">
		<xsl:param name="dataset" />
		<xsl:param name="fieldName" />
		<xsl:param name="record" />

		<xsl:text>| </xsl:text>

		<!-- Field name -->
		<xsl:value-of select="Display_label" />
		<xsl:text> | </xsl:text>

		<!-- CIDOC property -->
		<xsl:variable name="cidocPropertyId">
			<xsl:call-template name="extractCidocId">
				<xsl:with-param name="value" select="normalize-space($fieldName)" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$cidocPropertyId != ''">
				<xsl:call-template name="displayAnchor">
					<xsl:with-param name="link" select="concat($cidocLink,'type:property+')" />
					<xsl:with-param name="field" select="$cidocPropertyId" />
					<xsl:with-param name="text" select="normalize-space($fieldName)" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>`</xsl:text>
				<xsl:value-of select="normalize-space($fieldName)" />
				<xsl:text>`</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> | </xsl:text>

		<!-- CIDOC entity -->
		<xsl:variable name="cidocEntityId">
			<xsl:call-template name="extractCidocId">
				<xsl:with-param name="value" select="normalize-space(CRM_object_type)" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$cidocEntityId != '' ">
				<xsl:call-template name="displayAnchor">
					<xsl:with-param name="link" select="concat($cidocLink,'type:entity+')" />
					<xsl:with-param name="field" select="$cidocEntityId" />
					<xsl:with-param name="text" select="normalize-space(CRM_object_type)" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>`</xsl:text>
				<xsl:value-of select="normalize-space(CRM_object_type)" />
				<xsl:text>`</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> | </xsl:text>

		<!-- Linked Art -->
		<xsl:variable name="laPathParts" select="tokenize(normalize-space(LA_JSON), '/')" />
		<xsl:variable name="laTerm" select="$laPathParts[last()]"/>
		<xsl:call-template name="displayAnchor">
			<xsl:with-param name="link" select="$laLink" />
			<xsl:with-param name="field" select="concat('#',$laTerm)" />
			<xsl:with-param name="text" select="LA_JSON" />
		</xsl:call-template>
		<xsl:text> | </xsl:text>

		<!-- AAT type -->
		<xsl:choose>
			<xsl:when test="AAT_id != '-'">
				<xsl:call-template name="displayAnchor">
					<xsl:with-param name="link" select="$aatLink" />
					<xsl:with-param name="field" select="AAT_id" />
					<xsl:with-param name="text" select="AAT_id" />
				</xsl:call-template>
				<xsl:text> - </xsl:text>
				<xsl:value-of select="AAT_label" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="AAT_id" />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> | </xsl:text>

		<!-- Simple DC -->
		<xsl:choose>
			<xsl:when test="DC_term != '-'">
				<xsl:call-template name="displayAnchor">
					<xsl:with-param name="dataset" select="concat('#',$dataset)" />
					<xsl:with-param name="field" select="DC_term" />
					<xsl:with-param name="text" select="DC_term" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>`</xsl:text>
				<xsl:value-of select="DC_term" />
				<xsl:text>`</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> | </xsl:text>

		<!-- Simple field source -->
		<xsl:variable name="dcPathParts" select="tokenize(normalize-space(DC_term), '/')" />
		<xsl:variable name="dcTerm" select="$dcPathParts[last()]"/>
		<xsl:choose>
			<xsl:when test="DC_term_source = 'dc'">
				<xsl:call-template name="displayAnchor">
					<xsl:with-param name="link" select="$dcLink" />
					<xsl:with-param name="field" select="$dcTerm" />
					<xsl:with-param name="text" select="DC_term_source" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="DC_term_source = 'foaf'">
				<xsl:call-template name="displayAnchor">
					<xsl:with-param name="link" select="$foafLink" />
					<xsl:with-param name="field" select="$dcTerm" />
					<xsl:with-param name="text" select="DC_term_source" />
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="DC_term_source = 'schema'">
				<xsl:call-template name="displayAnchor">
					<xsl:with-param name="link" select="$schemaLink" />
					<xsl:with-param name="field" select="$dcTerm" />
					<xsl:with-param name="text" select="DC_term_source" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>`</xsl:text>
				<xsl:value-of select="DC_term_source" />
				<xsl:text>`</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> | `</xsl:text>

		<!-- EMu -->
		<xsl:value-of select="EMu_field" />
		<xsl:text>` |&#xa;</xsl:text>
	</xsl:template>

	<!-- displays anchor or href: <a type="[link][dataset][-][field]">[text]</a> -->
	<xsl:template name="displayAnchor">
		<xsl:param name="type" select=" 'href' " />
		<xsl:param name="link" select=" '' " />
		<xsl:param name="dataset" select=" '' " />
		<xsl:param name="field" select=" '' " />
		<xsl:param name="text" select=" '' " />
		
		<xsl:variable name="separator">
			<xsl:if test="$field">
				<xsl:if test="$dataset">
					<xsl:text>-</xsl:text>
				</xsl:if>
			</xsl:if>
		</xsl:variable>

		<xsl:if test="$type = 'href'">
			<a href="{$link}{$dataset}{$separator}{translate($field,'/','-')}">
				<xsl:text>`</xsl:text>
				<xsl:value-of select="$text" />
				<xsl:text>`</xsl:text>
			</a>
		</xsl:if>
		<xsl:if test="$type = 'name'">
			<a name="{$link}{$dataset}{$separator}{translate($field,'/','-')}">
				<xsl:value-of select="$text" />
			</a>
		</xsl:if>

	</xsl:template>

	<!-- Extract just the basic CRM code, e.g. P46i_forms_part_of -> P46 -->
	<!-- Can't link directly to CIDOC page so run canned search for CRM code -->
	<xsl:template name="extractCidocId">
		<xsl:param name="value" />
		<xsl:variable name="pathParts" select="tokenize(normalize-space($value), '/')" />
		<xsl:variable name="term" select="$pathParts[last()]"/>
		<xsl:if test="starts-with($term, 'P') or starts-with($term, 'E')">
			<xsl:variable name="code" select="substring-before($term, '_')"/>
			<xsl:choose>
				<xsl:when test="ends-with($code, 'i')">
					<xsl:value-of select="substring-before($code, 'i')" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$code" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<!-- Split multi-value data to separate lines, using HTML <br/> -->
	<xsl:template name="splitBySemicolon">
		<xsl:param name="value" />
		<xsl:for-each select="tokenize($value,';')">
			<xsl:if test="position() != 1">
				<br />
			</xsl:if>
			<xsl:text>`</xsl:text>
			<xsl:value-of select="normalize-space(.)" />
			<xsl:text>` </xsl:text>
		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
