<?xml version="1.1"?>
<xsl:stylesheet version="3.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:dashboard="local-functions"
	xmlns="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="c f dashboard map xs">
	
	<!-- the parameters from the request URL of the dashboard -->
	<xsl:variable name="request" select="/*/c:param-set"/>
	
	<!-- the specification of the searchable facets; previously used to convert the above request parameters into a Solr search -->
	<xsl:variable name="facet-spec" select="/*/facets"/>

	<!-- the response from Solr to the above search -->
	<xsl:variable name="response" select="/*/c:body"/>

	<!-- the facets returned by Solr -->
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
						<xsl:variable name="facet-range" select="range"/><!-- e.g. MONTH, DAY -->
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
											<!-- format the value for display -->
											<xsl:value-of select="dashboard:display-value($value, $facet-range)"/>
											<xsl:value-of select="concat(' (', $count, ')')"/>
										</option>
									</xsl:for-each>
								</select>
							</div>
						</xsl:if>
					</xsl:for-each>
					<button>Apply filter</button>
				</form>
				<!-- render each facet as a bar chart, in which each bucket within a facet is rendered as a link which constrains that facet -->
				<xsl:for-each-group select="$facet-spec/facet" group-by="group">
					<div class="chart-group">
						<h2><xsl:value-of select="current-group()[1]/group"/></h2>
						<div class="charts">
							<!--<xsl:for-each select="$facet-spec/facet">-->
							<xsl:for-each select="$solr-facets[@key=current-group()/name]">
								<xsl:sort select="count(f:array[@key='buckets']/f:map)"/>
								<xsl:variable name="solr-facet" select="."/>
								<xsl:variable name="solr-facet-key" select="@key"/>
								<xsl:variable name="facet" select="$facet-spec/facet[name=$solr-facet-key]"/>
								<xsl:if test="$solr-facet"><!-- facet returned some result; this means that Solr results match the facet -->
									<div class="chart">
										<h3>
											<xsl:value-of select="$facet/label"/>
											<xsl:for-each select="$solr-facet/f:number[@key='numBuckets']">
												<xsl:choose>
													<xsl:when test=".=1"> (1 value)</xsl:when>
													<xsl:otherwise> (<xsl:value-of select="."/> values)</xsl:otherwise>
												</xsl:choose>
											</xsl:for-each>
										</h3>
										<xsl:variable name="selected-value" select="$request/c:param[@name=$facet/name]/@value"/>
										<xsl:variable name="all-buckets" select="$solr-facet/f:array[@key='buckets']/f:map[f:string[@key='val']/text()]"/>
										<xsl:variable name="buckets" select="
											if (normalize-space($selected-value)) then
												$all-buckets[f:string[@key='val']/text() = $selected-value]
											else
												$all-buckets
										"/>
										<xsl:variable name="maximum-value" select="
											max(
												for $bucket in $buckets return xs:unsignedInt($bucket/f:number[@key='count'])
											)
										"/>
										<xsl:for-each select="$buckets">
											<xsl:variable name="value" select="f:string[@key='val']"/>
											<xsl:variable name="count" select="xs:unsignedInt(f:number[@key='count'])"/>
											<xsl:variable name="label" select="dashboard:display-value($value, $facet/range)"/>
											<div class="bucket">
												<div class="bar" style="width: {100 * $count div $maximum-value}%"> </div>
												<div class="label">
													<a 
														title="{$label}"
														href="{
															concat(
																'?',
																string-join(
																	(
																		concat($facet/name, '=', $value),
																		for $param in $request/c:param
																			[not(@name=$facet/name)]
																			[normalize-space(@value)] 
																		return 
																			concat($param/@name, '=', $param/@value)
																	),
																	'&amp;'
																)
															)
														}"
													><xsl:value-of select="$label"/></a>
													<span> (<xsl:value-of select="$count"/>)</span>
												</div>
											</div>
										</xsl:for-each>
									</div>
								</xsl:if>
							</xsl:for-each>
						</div>
					</div>
				</xsl:for-each-group>
				<div class="api-calls">
					<h2><xsl:value-of select="$response/f:map/f:map[@key='response']/f:number[@key='numFound']"/> API calls</h2>
					<ul>
						<xsl:for-each select="$response/f:map/f:map[@key='response']/f:array[@key='docs']/f:map/f:string[@key='request_uri']">
							<li>
								<a href="/{.}"><xsl:value-of select="."/></a>
							</li>
						</xsl:for-each>
					</ul>
				</div>
			</body>
		</html>
	</xsl:template>
	
	<!-- format a Solr field value for display -->
	<xsl:function name="dashboard:display-value">
		<xsl:param name="value"/>
		<xsl:param name="format"/>
		<xsl:choose>
			<xsl:when test="$format='MONTH'">
				<xsl:value-of select="format-dateTime(
					xs:dateTime($value), 
					'[MNn] [Y]', 'en', (), ()
				)"/>
			</xsl:when>
			<xsl:when test="$format='DAY'">
				<xsl:value-of select="format-dateTime(
					xs:dateTime($value), 
					'[D] [MNn] [Y]', 'en', (), ()
				)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$value"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:template name="css">
		<style type="text/css">
			body {
				font-family: Calibri, Helvetica, Arial, sans-serif;
				font-size: 10pt;
			}
			h1 {
				font-size: 13pt;
			}
			h2 {
				font-size: 11pt;
			}
			h3 {
				font-size: 10pt;
			}
			img {
				border: none;
			}
			div.facet label {
				font-weight: bold;
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
			div.chart-group {
				padding: 1em;
				margin-top: 1em;
				background-color: #E5E5E5;
			}
			div.charts {
				display: flex;
				flex-wrap: wrap;
			}
			div.chart {
				background-color: #FFFFFF;
				padding: 0.5em;
				margin: 0.5em;
			}
			div.chart div.bucket {
				position: relative; 
				height: 1.5em;
			}
			div.chart div.bucket div.bar {
				z-index: 0; 
				position: absolute; 
				background-color: lightsteelblue;
				height: 1.2em;
			}
			div.chart div.bucket div.label {
				width: 100%;
				height: 100%;
				overflow: hidden;
				white-space: nowrap;
				text-overflow: ellipsis;
				position: relative;
			}
			div.chart div.bucket div.label a {
				text-decoration: none;
			}
		</style>
	</xsl:template>

</xsl:stylesheet>