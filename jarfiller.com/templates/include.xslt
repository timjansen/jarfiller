<?xml version="1.0"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
				xmlns:inc="http://tjansen.de/refPageInclude">
<xsl:output method = "xml"/>

<xsl:function name="inc:getSource">
	<xsl:param name="file"/>
	<xsl:param name="ref"/>
	<xsl:variable name="incDoc" select="doc(string($file))"/>
	<xsl:copy-of select="if ($ref) then $incDoc/descendant::*[@id eq $ref] else $incDoc/*"/>
</xsl:function>

<xsl:template match="inc:includeNode">
	<xsl:message>Including node now: <xsl:value-of select="@file"/> : <xsl:value-of select="@ref"/></xsl:message>
	<xsl:apply-templates select="inc:getSource(@file, @ref)"/>
</xsl:template>

<xsl:template match="inc:includeContent">
	<xsl:message>Including content now: <xsl:value-of select="@file"/> : <xsl:value-of select="@ref"/></xsl:message>
	<xsl:apply-templates select="inc:getSource(@file, @ref)/*"/>
</xsl:template>

<xsl:template match="@*|node()" priority="-1">
	<xsl:copy>
		<xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
</xsl:template>

</xsl:stylesheet>