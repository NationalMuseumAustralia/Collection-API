<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema">

	<xsl:param name="relative-uri"/>
	<xsl:variable name="anonymous" select="/c:request/c:header[lower-case(@name)='x-anonymous-consumer']/@value"/>
	<xsl:variable name="dataset" select="if ($anonymous='false') then 'internal' else 'public'"/>
	
	<!-- transform the incoming HTTP request to the API into an outgoing HTTP request to Solr -->
	<!-- the incoming request has been parsed into a set of parameters i.e. c:param-set, -->
	<!-- and the path components of the URI passed as $relative-uri -->
	<xsl:template match="/c:param-set">
		<c:request method="get">
			<!-- the request URI specifies either an individual resource, or a search -->
			<xsl:choose>
				<!-- 
				Request relative URI is a request for a description of a single resource,
				since it has the form "XXXXX/nnnn" e.g. "object/1234" or "party/5678" 
				-->
				<xsl:when test="matches($relative-uri, '[^/]+/[^?]+')">
					<xsl:attribute name="href" select="
						concat(
							'http://localhost:8983/solr/core_nma_',
							$dataset,
							'/select?wt=xml&amp;q=id:', 
							substring-before(
								concat($relative-uri, '?'),
								'?'
							)
						)
					"/>
				</xsl:when>
				<!--
				Request URI is a search query because it includes query parameters 
				e.g. "object?medium=bark" or "party?name=smith" 
				-->
				<xsl:when test="contains($relative-uri, '?')">
				
					<xsl:variable name="sort" select="/c:param-set/c:param[@name='sort']/@value"/>
					<xsl:variable name="start" select="/c:param-set/c:param[@name='offset']/@value"/>
					<!-- if you don't specify a limit, this is how many rows you get -->
					<xsl:variable name="default-rows" select="50"/>
					<!-- this is the maximum number of rows you can get, even if you request more -->
					<xsl:variable name="max-rows" select="100"/>
					<!-- this is the number of rows requested -->
					<xsl:variable name="requested-rows" select="/c:param-set/c:param[@name='limit']/@value"/>
					<!-- this is the number of rows which we will request from Solr -->
					<!-- and which is no less than 1 and no more than $max-rows -->
					<xsl:variable name="rows" select="
						if ($requested-rows castable as xs:integer) then
							min((
								$max-rows cast as xs:integer,
								max((1, $requested-rows cast as xs:double))
							)) cast as xs:integer
						else
							$default-rows
					"/>
					<xsl:variable name="entity-type" select="substring-before($relative-uri, '?')"/>
					<xsl:attribute name="href" select="
						concat(
							'http://localhost:8983/solr/core_nma_',
							$dataset,
							'/select?wt=xml&amp;',
							'fq=type%3A', $entity-type, '&amp;',
							'q=', encode-for-uri(
								string-join(
									for $parameter in /c:param-set/c:param
										[normalize-space(@value)]
										[not(@name=('format', 'sort', 'offset', 'limit'))] 
									return concat(
										$parameter/@name, 
										if ($parameter/@value='*') then 
											':*' 
										else concat(
											':&quot;', 
											replace(
												replace(
													$parameter/@value,
													'\\',
													'\\\\'
												),
												'&quot;',
												'\\&quot;'
											), 
											'&quot;~1000000'
										)
									), 
									' AND '
								)
							),
							if ($sort) then
								concat(
									'&amp;sort=', 
									string-join(
										encode-for-uri($sort),
										','
									)
								)
							else (),
							if ($start) then 
								concat('&amp;start=', encode-for-uri($start))
							else (),
							'&amp;rows=', encode-for-uri(string($rows))
						)
					"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="error-uri" select="$relative-uri"/>
				</xsl:otherwise>
			</xsl:choose>
		</c:request>
	</xsl:template>
		
</xsl:stylesheet>
