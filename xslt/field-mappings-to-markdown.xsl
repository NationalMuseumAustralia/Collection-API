<?xml version="1.1"?>
<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<!-- Converts a single documentation markdown section (from field mappings sheet) -->
	<!-- Call multiple times to create a full field reference page -->
	
	<xsl:param name="dataset" select=" 'Object' " />
	<xsl:param name="displayMode" select=" 'list' " />
	
	<xsl:variable name="cidocLink" select=" 'http://www.cidoc-crm.org/cidoc-crm/' " />
	<xsl:variable name="oreLink" select=" 'http://www.openarchives.org/ore/vocabulary#ore-' " />
	<xsl:variable name="rdfLink" select=" 'https://www.w3.org/TR/rdf-schema/#ch_' " />
	<xsl:variable name="rdfsLink" select=" 'https://www.w3.org/TR/rdf-schema/#ch_' " />
	<xsl:variable name="laLink" select=" 'https://linked.art/ns/v1/linked-art.json#/%40context/' " />
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
			select="./*[Source=$dataset and not(DC_term = '') and not(DC_term = '-') and Internal = '' and Exclude_from_DC_help = '']">
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
			select="./*[Source=$dataset and not(CRM_relation__rdf_value_ = '') and not(CRM_relation__rdf_value_ = '-') and Internal = '']">
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
		<xsl:text>Fields in NMA's Collection API 'simple' format&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
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
		<xsl:text>Mappings between the fields in different data formats (follow the links to definitions for each field):&#xa;</xsl:text>
		<xsl:text>* **rdf**: [CIDOC Conceptual Reference Model (CRM)](http://www.cidoc-crm.org/) property fields, and the CRM entity types of the property values&#xa;</xsl:text>
		<xsl:text>* **json-ld**: [Linked Art](https://linked.art/) JSON-LD property fields, and the [Art and Architecture Thesaurus (AAT)](https://www.getty.edu/research/tools/vocabularies/aat/) types of the property values&#xa;</xsl:text>
		<xsl:text>* **simple**: NMA's Collection API 'simple' format field and the source schema the field is from&#xa;</xsl:text>
		<xsl:text>* **source**: NMA's EMu collection management system field&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>| NMA field title | CIDOC-CRM field | CRM type | Linked Art field | AAT type | NMA Simple field | Simple source | NMA EMu field |&#xa;</xsl:text>
		<xsl:text>| --------------- | --------------- | -------- | ---------------- | -------- | ---------------- | ------------- | ------------- |&#xa;</xsl:text>
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
		<xsl:call-template name="displayPath">
			<xsl:with-param name="type" select=" 'crm' " />
			<xsl:with-param name="value" select="$fieldName" />
		</xsl:call-template>
		<xsl:text> | </xsl:text>

		<!-- CIDOC entity -->
		<xsl:call-template name="displayPath">
			<xsl:with-param name="type" select=" 'crm' " />
			<xsl:with-param name="value" select="CRM_object_type" />
		</xsl:call-template>
		<xsl:text> | </xsl:text>

		<!-- Linked Art -->
		<xsl:call-template name="displayPath">
			<xsl:with-param name="type" select=" 'la' " />
			<xsl:with-param name="value" select="LA_JSON" />
		</xsl:call-template>
		<xsl:text> | </xsl:text>

		<!-- AAT type, format: "AAT_id - AAT_label" -->
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

		<!-- Simple DC, link goes to field reference on this page -->
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

		<!-- Simple field source, link is just for the final part in the path -->
		<xsl:variable name="dcPathParts" select="tokenize(normalize-space(DC_term), '/')" />
		<xsl:variable name="dcTerm" select="$dcPathParts[last()]"/>
		<xsl:call-template name="displayPath">
			<xsl:with-param name="type" select="DC_term_source" />
			<xsl:with-param name="value" select="$dcTerm" />
			<xsl:with-param name="label" select="DC_term_source" />
		</xsl:call-template>
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

	<!-- Display a field path with each part as a separate link to its documentation -->
	<xsl:template name="displayPath">
		<xsl:param name="value" />
		<xsl:param name="type" />
		<!-- can override display with this label (instead of displaying value) -->
		<xsl:param name="label" select=" '' " />

		<xsl:for-each select="tokenize(normalize-space($value), '/')">

			<!-- path separator -->
			<xsl:if test="position() != 1">
				<xsl:text>/</xsl:text>
			</xsl:if>

			<!-- override type if part contains namespace or punctuation -->
			<xsl:variable name="partType">
				<xsl:choose>
					<xsl:when test="contains(.,':')">
						<xsl:value-of select="substring-before(., ':')" />
					</xsl:when>
					<!-- ignore if starts with bracket -->
					<xsl:when test="starts-with(.,'(')">
						<xsl:text></xsl:text>
					</xsl:when>
					<!-- ignore if starts with hyphen -->
					<xsl:when test="starts-with(.,'-')">
						<xsl:text></xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$type" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<!-- extract part name if contains namespace -->
			<xsl:variable name="partName">
				<xsl:choose>
					<xsl:when test="contains(.,':')">
						<xsl:value-of select="substring-after(., ':')" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<!-- decide on link to use -->
			<xsl:variable name="linkBase">
				<xsl:choose>
					<xsl:when test="$partType = 'crm' ">
						<xsl:value-of select="$cidocLink" />
					</xsl:when>
					<xsl:when test="$partType = 'la' ">
						<xsl:value-of select="$laLink" />
					</xsl:when>
					<xsl:when test="$partType = 'dc'">
						<xsl:value-of select="$dcLink" />
					</xsl:when>
					<xsl:when test="$partType = 'foaf'">
						<xsl:value-of select="$foafLink" />
					</xsl:when>
					<xsl:when test="$partType = 'schema'">
						<xsl:value-of select="$schemaLink" />
					</xsl:when>
					<xsl:when test="$partType = 'ore'">
						<xsl:value-of select="$oreLink" />
					</xsl:when>
					<xsl:when test="$partType = 'rdf'">
						<xsl:value-of select="$rdfLink" />
					</xsl:when>
					<xsl:when test="$partType = 'rdfs'">
						<xsl:value-of select="$rdfsLink" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:text></xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<!-- decide on label to show -->
			<xsl:variable name="displayLabel">
				<xsl:choose>
					<xsl:when test="$label != ''">
						<xsl:value-of select="$label" />
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="." />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>

			<!-- display -->
			<xsl:choose>
				<xsl:when test="$linkBase != ''">
					<xsl:call-template name="displayAnchor">
						<xsl:with-param name="link" select="$linkBase" />
						<xsl:with-param name="field" select="$partName" />
						<xsl:with-param name="text" select="$displayLabel" />
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>`</xsl:text>
					<xsl:value-of select="$displayLabel" />
					<xsl:text>`</xsl:text>
				</xsl:otherwise>
			</xsl:choose>

		</xsl:for-each>
	</xsl:template>

</xsl:stylesheet>
