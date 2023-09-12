<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:nma="tag:conaltuohy.com,2018:nma"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	exclude-result-prefixes="xs nma">

	<xsl:variable name="base-url" select=" 'http://localhost:8983' "/>
	<!--
	<xsl:variable field="base-url" select=" 'http://nma-dev.conaltuohy.com' "/>
	-->
	
	<xsl:variable name="facet-spec" select="/*/facets"/>

	
	<!-- transform the incoming HTTP request to the dashboard into an outgoing HTTP request to Solr -->
	<!-- the incoming request has been parsed into a set of parameters i.e. c:param-set, -->
	<!-- and the path components of the URI passed as $relative-uri -->
	<xsl:template match="/">
		<c:request 
			method="post"
			href="{
				concat(
					$base-url,
					'/solr/core_nma_log/query?'
				)
			}"
			override-content-type="text/plain"
		>
			<c:body content-type="application/xml">
				<xsl:apply-templates select="/*/c:param-set"/>
			</c:body>
		</c:request>
	</xsl:template>
	
	<xsl:template match="c:param-set">
		<f:map>
			<f:string key="query">*:*</f:string>
			<f:array key="filter">
				<xsl:for-each select="c:param[normalize-space(@value)]">
					<!-- the param/@name specifies the facet's name; look up the facet by name and get the facet's field -->
					<xsl:variable name="facet-name" select="@name"/>
					<xsl:variable name="facet-value" select="@value"/>
					<xsl:variable name="facet" select="$facet-spec/facet[name=$facet-name]"/>
					<xsl:variable name="field-name" select="$facet/field"/>
					<xsl:variable name="field-range" select="$facet/range"/>
					<xsl:choose>
						<xsl:when test="$field-range">
							<f:string><xsl:value-of select="
								concat(
									'{!tag=', $facet-name, '}', 
									$field-name, 
									':[&quot;', 
									@value,
									'/', $field-range,
									'&quot; TO &quot;',
									@value,
									'/', $field-range, '+1', $field-range,
									'&quot;]'
								)
							"/></f:string>
						</xsl:when>
						<xsl:otherwise>
							<f:string><xsl:value-of select="concat('{!tag=', $facet-name, '}', $field-name, ':&quot;', @value, '&quot;')"/></f:string>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</f:array>
			<f:map key="facet">
				<xsl:for-each select="$facet-spec/facet">
					<f:map key="{name}">
						<xsl:if test="missing"><!-- include a count of records which are missing a value for this facet -->
							<f:boolean key="missing">true</f:boolean>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="range">
								<!-- facet/range specifies a range unit; either MONTH, DAY, or YEAR -->
								<f:string key="type">range</f:string>
								<!-- e.g. "NOW/DAY-1MONTH", "NOW/MONTH-1YEAR" -->
								<f:string key="start"><xsl:value-of select="concat('NOW/', range, start)"/></f:string>
								<!-- e.g. "+1DAY", "+1MONTH" -->
								<f:string key="gap"><xsl:value-of select="concat('+1', range)"/></f:string>
								<!-- e.g. "NOW/+1DAY", "NOW/+1MONTH" -->
								<f:string key="end"><xsl:value-of select="concat('NOW/', range, '+1', range)"/></f:string>
							</xsl:when>
							<xsl:otherwise>
								<f:string key="type">terms</f:string>
							</xsl:otherwise>
						</xsl:choose>
						<f:string key="field"><xsl:value-of select="field"/></f:string>
						<f:number key="limit">40</f:number>
						<f:boolean key="numBuckets">true</f:boolean>
						<f:map key="domain">
							<f:string key="excludeTags"><xsl:value-of select="name"/></f:string>
						</f:map>
					</f:map>
				</xsl:for-each>
			</f:map>
		</f:map>
	</xsl:template>
		
</xsl:stylesheet>
