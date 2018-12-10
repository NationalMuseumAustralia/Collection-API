<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="c f">
	
	<xsl:variable name="request" select="/*/c:param-set"/>
	
	<xsl:variable name="response" select="/*/c:body"/>
	
	<xsl:variable name="facet-spec" select="/*/facets"/>
	
		<!-- construct sequences of the constraints which are currently in force, and those available as options, e.g. -->
		<!-- ('header_x-consumer-groups:"public"', ;header_x-consumer-groups:"internal"', response_status:"410", ... ) -->
		<!--
		<xsl:variable name="current-constraints" select="
			lst[@name='responseHeader']/lst[@name='params']/(str[@name='fq'] | arr[@name='q']/str)
		"/>
		-->
		
		<!--
		NB TODO: reconcile the difference between available-constraints and current-constraints:
		Necessarily current-constraints are expressed as field-name/value-expression pairs, whereas available-constraints are facet-name, bucket-value pairs.
		In the case of date-range facets, the bucket values are the dates of the start of each range, whereas the filters need to be range expressions.
		
		-->
		<!--
		<xsl:variable name="available-constraints" select="
			for $bucket in $facets/f:array[@key='buckets']/f:map return
				concat(
					$bucket/../../@key, 
					':&quot;', 
					$bucket/f:string[@key='val'], 
					'&quot;'
				)
		"/>
		-->
		
	<!-- 
	Generate a sequence of the constraints currently in force, e.g. 
	('header_x-consumer-groups:"public"', 'header_x-consumer-groups:"internal"', 'response_status:"410"', ... )
	-->
	
	<xsl:variable name="current-constraints" select="
		for $filter in 
			json-to-xml($response/f:map/f:map[@key='responseHeader']/f:map[@key='params']/f:string[@key='json'])
				/f:map/f:array[@key='filter']/f:string
		return
			substring-after($filter, '}')
	"/>

	<xsl:variable name="solr-facets" select="
		$response
			/f:map
				/f:map[@key='facets']
					/f:map[
						f:array[@key='buckets']
							/f:map
								/f:number[@key='count'] != '0'
					]
	"/>	
	
	<xsl:variable name="available-constraints" select="
		for $bucket in $solr-facets/f:array[@key='buckets']/f:map return
			concat(
				$bucket/../../@key,  
				':',
				$bucket/f:string[@key='val']
			)
	"/>
			
	<xsl:template match="/">
		<html>
			<head>
				<title>NMA API dashboard</title>
				<link rel="shortcut icon" href="http://www.nma.gov.au/__data/assets/file/0010/591499/favicon2.ico?v=0.1.1" type="image/x-icon" />
				<xsl:call-template name="css"/>
			</head>
			<body>
				<h1>NMA API dashboard</h1>
				
				<form method="GET" action="">
					<!-- render each facet as a <select> -->
					<xsl:for-each select="$facet-spec/facet">
						<xsl:variable name="facet-name" select="name"/>
						<xsl:variable name="facet-label" select="label"/>
						<xsl:variable name="field-name" select="field"/>
						<!-- retrieve the matching Solr facet -->
						<xsl:comment>facet: <xsl:value-of select="$facet-name"/></xsl:comment>
						<xsl:variable name="solr-facet" select="$solr-facets[@key=$facet-name]"/>
						<xsl:if test="$solr-facet"><!-- facet returned some result; this means that Solr results match the facet -->
							<div class="facet">
								<label for="{$facet-name}"><xsl:value-of select="$facet-label"/></label>
								<select id="{$facet-name}" name="{$facet-name}">
									<option value="">				
										<xsl:text>(any)</xsl:text>
									</option>
									<xsl:for-each select="$solr-facet/f:array[@key='buckets']/f:map[f:string[@key='val']/text()]">
										<xsl:variable name="value" select="f:string[@key='val']"/>
										<xsl:variable name="count" select="f:number[@key='count']"/>
										<!-- list all the non-blank values of this facet as options -->
										<xsl:variable name="selected" select="$request/c:param[@name = $facet-name]/@value = $value"/>
										<option value="{$value}">
											<xsl:if test="$selected"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
											<xsl:value-of select="concat($value, ' (', $count, ')')"/>
										</option>
									</xsl:for-each>
								</select>
							</div>
						</xsl:if>
					</xsl:for-each>
					<button>Apply filter</button>
				</form>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template name="css">
		<style type="text/css">
			body {
				font-family: Calibri, Helvetica, Arial, sans-serif;
				font-size: 11pt;
			}
			h1 {
				font-size: 12pt;
			}
			img {
				border: none;
			}
			.label {
				font-weight: bold;
			}
			div.facet label {
				display: inline-block;
				text-align: right;
				width: 15em;
			}
			div.facet select {
				width: 30em;
			}
			div.facet {
				margin-bottom: 0.5em;
			}
		</style>
	</xsl:template>

</xsl:stylesheet>