<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:nma="tag:conaltuohy.com,2018:nma">

	<xsl:param name="relative-uri"/>
	<xsl:param name="id"/>
	<xsl:param name="response-status"/>
	<xsl:param name="response-content-type"/>
	
	<!-- transform the API request/response into an outgoing HTTP request to Solr -->
	<!-- to log the request/response in the "core_nma_log" Solr core -->
	<xsl:variable name="request-path" select="substring-before(concat($relative-uri, '?'), '?')"/>
	<xsl:variable name="request-path-first-segment" select="substring-before(concat($request-path, '/'), '/')"/>
	<xsl:variable name="request-resource-id" select="
		if ($request-path-first-segment = ('media', 'place', 'person', 'object', 'narrative')) then
			substring-after($request-path, concat($request-path-first-segment, '/'))
		else
			()
	"/>
	<xsl:template match="/c:request">
		<c:request method="post" href="http://localhost:8983/solr/core_nma_log/update" detailed="true">
			<c:body content-type="application/xml">
				<add commitWithin="10000">
					<doc>
						<field name="id"><xsl:value-of select="$id"/></field>
						<field name="datestamp"><xsl:value-of select="adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration('PT0H')) "/></field>
						<field name="request_uri"><xsl:value-of select="$relative-uri"/></field>
						<field name="request_first-segment"><xsl:value-of select="$request-path-first-segment"/></field>
						<field name="request_item-id"><xsl:value-of select="$request-resource-id"/></field>
						<xsl:for-each select="/c:request/c:header">
							<field name="header_{@name}"><xsl:value-of select="@value"/></field>
						</xsl:for-each>
						<xsl:for-each select="/c:request/c:param">
							<field name="parameter_{@name}"><xsl:value-of select="@value"/></field>
						</xsl:for-each>
						<field name="response_status"><xsl:value-of select="$response-status"/></field>
						<field name="response_content-type"><xsl:value-of select="$response-content-type"/></field>
					</doc>
				</add>
			</c:body>
		</c:request>
	</xsl:template>
		
</xsl:stylesheet>
