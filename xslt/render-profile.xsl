<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:param name="profile"/>
	<!-- classify this profile URI as either supported (200=OK), no longer supported (410=GONE), or never supported (404=NOT FOUND) -->
	<xsl:variable name="status" select="
		if ($profile = ('1', '2')) then
			'200'
		else if ($profile = ('0')) then
			'410'
		else 
			'404'
	"/>
	<xsl:template match="/">
		<c:response status="{$status}" xmlns:c="http://www.w3.org/ns/xproc-step">
			<c:body content-type="application/xhtml+xml">
				<html xmlns="http://www.w3.org/1999/xhtml">
					<head>
						<title>National Museum of Australia Collections — API format '<xsl:value-of select="$profile"/>'</title>
					</head>
					<body>
						<h1>National Museum of Australia Collections — API format '<xsl:value-of select="$profile"/>'</h1>
						<xsl:choose>
							<xsl:when test="$status = '200'">
								<p>The identifier <code><xsl:value-of select="$profile"/></code> identifies a profile of the NMA Collections API data format.</p>
							</xsl:when>
							<xsl:when test="$status='410'">
								<p>The identifier <code><xsl:value-of select="$profile"/></code> identifies a profile of the NMA Collections API data format which is no longer supported</p>
							</xsl:when>
							<xsl:otherwise>
								<p>The identifier <code><xsl:value-of select="$profile"/></code> does not identify a profile of the NMA Collections API data format</p>
							</xsl:otherwise>
						</xsl:choose>
					</body>
				</html>
			</c:body>
		</c:response>
	</xsl:template>
</xsl:stylesheet>