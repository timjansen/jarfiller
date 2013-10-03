<?xml version="1.0"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
				xmlns:page="http://tjansen.de/refPage"
				xmlns:i="http://tjansen.de/internal"
				xmlns="http://www.w3.org/1999/xhtml">
<xsl:output method = "xml" omit-xml-declaration="no"  doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>
<xsl:param name="multipageEnabled"/>
<xsl:param name="multipagePath"/>

<xsl:variable name="articleSections" select="/page:page/page:article/page:body/(page:singleColumnSection|page:exampleWithResult)"/>
<xsl:variable name="pagePath" select="string(/page:page/page:path)"/>

<!-- Returns all sub-sections of the given section. -->
<xsl:function name="i:getSubSections">
<xsl:param name="section"/>         <!-- The section -->
 	<xsl:copy-of select="$section/(page:subSection|page:collapsedSubSection)"/>	
</xsl:function>

<!-- Returns the section or subsection with the given anchor. -->
<xsl:function name="i:getNodeByAnchor">
<xsl:param name="anchor"/>         <!-- The section or sub-section anchor (string) -->
	<xsl:variable name="possibleSection" select="$articleSections[@anchor eq $anchor]"/>
	<xsl:copy-of select="if ($possibleSection) 
	                     then $possibleSection
	                     else $articleSections/*[@anchor = $anchor][1]"/>	
</xsl:function>

<!-- Returns the section with the given anchor. If the anchor is a sub-section, the parent is returned.-->
<xsl:function name="i:getSectionByAnchor">
<xsl:param name="anchor"/>         <!-- The section or sub-section anchor (string) -->
	<xsl:variable name="possibleSection" select="$articleSections[@anchor eq $anchor]"/>
	<xsl:copy-of select="if ($possibleSection) 
	                     then $possibleSection[1]
	                     else $articleSections[*/@anchor = $anchor][1]"/>	
</xsl:function>



<!-- Returns how to link to the given linkAnchor in the selected mode.
Return: <i:result>
			<i:href>link with anchor</i:href>
			<i:page>link without anchor</i:page>
			<i:isSamePage>true/false, depending on whether the link is on the same page</i:isSamePage>
			<i:isLinkAvailable>true/false, depending on whether linking is possible (in 'multi' mode, multipage-sections have no own page)</i:isLinkAvailable>
			<i:title>title of the linked section/subsection</i:title>
        </i:result>-->
<xsl:function name="i:getSectionLink">
	<xsl:param name="selectedAnchor"/>  <!-- The current selected anchor for multipage mode (string) -->
	<xsl:param name="linkAnchor"/>      <!-- The anchor to link to (string) -->
	<xsl:param name="pageMode"/>        <!-- 'auto' (takes best mode), 'single' (always single page mode) or 'multi' (always multi page mode) -->
	
	<xsl:variable name="selectedSectionAnchor" select="i:getSectionByAnchor($selectedAnchor)/@anchor"/>
	<xsl:variable name="linkSection" select="i:getSectionByAnchor($linkAnchor)"/>
	<xsl:variable name="linkNode" select="i:getNodeByAnchor($linkAnchor)"/>
	<xsl:variable name="isMultipageSection" select="string($linkSection/@multipage)"/>
	<xsl:variable name="title" select="if ($linkNode/page:summary) then string($linkNode/page:summary) else ($linkNode/page:head)"/>

	<i:result>
		<xsl:choose>
			<xsl:when test="$multipageEnabled and $pageMode eq 'single'"><i:href><xsl:copy-of select="concat($pagePath, '#', $linkNode/@anchor)"/></i:href><i:page><xsl:copy-of select="$pagePath"/></i:page><i:isSamePage>false</i:isSamePage><i:isLinkAvailable>true</i:isLinkAvailable></xsl:when>
			<xsl:when test="($multipageEnabled or $pageMode eq 'multi') and $isMultipageSection eq 'true' and $linkSection/@anchor ne $linkAnchor"><i:href><xsl:copy-of select="concat($linkNode/@anchor, '.xhtml#', $linkNode/@anchor)"/></i:href><i:page><xsl:copy-of select="string($linkNode/@anchor)"/>.xhtml</i:page><i:isSamePage>false</i:isSamePage><i:isLinkAvailable>true</i:isLinkAvailable></xsl:when>
			<xsl:when test="($multipageEnabled or $pageMode eq 'multi') and $isMultipageSection eq 'true' and $linkSection/@anchor eq $linkAnchor"><i:href/><i:page/><i:isSamePage>false</i:isSamePage><i:isLinkAvailable>false</i:isLinkAvailable></xsl:when>
			<xsl:when test="($multipageEnabled and $selectedSectionAnchor ne $linkSection/@anchor) or (not($multipageEnabled) and $pageMode eq 'multi')"><i:href><xsl:copy-of select="concat($linkSection/@anchor , '.xhtml#' , $linkNode/@anchor)"/></i:href><i:page><xsl:copy-of select="string($linkSection/@anchor)"/>.xhtml</i:page><i:isSamePage>false</i:isSamePage><i:isLinkAvailable>true</i:isLinkAvailable></xsl:when>
			<xsl:otherwise><i:href><xsl:copy-of select="concat('#', $linkNode/@anchor)"/></i:href><i:page><xsl:copy-of select="$selectedSectionAnchor"/>.xhtml</i:page><i:isSamePage>true</i:isSamePage><i:isLinkAvailable>true</i:isLinkAvailable></xsl:otherwise>
		</xsl:choose>
		<i:title><xsl:value-of select="$title"/></i:title>
	</i:result>
</xsl:function>






<xsl:template name="spaces">
	<xsl:param name="number"/>
	<xsl:for-each select="1 to $number"><xsl:text> </xsl:text></xsl:for-each>
</xsl:template>

<xsl:template name="tooltip">
	<xsl:param name="title"/>
	<xsl:param name="contentNode"/>
	<xsl:param name="haveDecoration"/>
	<xsl:param name="tooltipType"/> <!-- 'tooltip' or 'topic' -->
	
	<xsl:variable name="prefix" select="if ($tooltipType eq 'tooltip') then 'tl' else 'tpc'"/>
	<xsl:variable name="aid" select="concat('tl-', generate-id(.))"/>
	<xsl:variable name="tid" select="concat('pp-', generate-id($contentNode))"/>
	<a href="#" id="{$aid}" class="{if ($haveDecoration eq 'true') then 'dottedTooltip' else 'tooltip'}" onclick="return {$prefix}Click('{$aid}','{$tid}');" onmouseover="return {$prefix}Over('{$aid}','{$tid}');" onmouseout="return {$prefix}Out('{$aid}','{$tid}');">
		<xsl:copy-of select="$title"/> 
	</a>
</xsl:template>

<xsl:template name="tooltipDiv">
	<xsl:param name="id"/>
	<xsl:param name="content"/>
	<xsl:param name="class"/>
	<div id="{$id}" class="{$class}"><xsl:copy-of select="$content"/></div>
</xsl:template>

<xsl:template match="page:explanation/text()|page:li/text()|page:em/text()|page:cell/text()|page:more/text()|page:popup/text()">
	<xsl:value-of select="replace(string(.), '[\s\r\n]+', ' ')"/>
</xsl:template>

<xsl:template match="page:em"><em><xsl:apply-templates/></em></xsl:template>

<xsl:template match="page:idf"><span class="idf"><xsl:apply-templates/></span></xsl:template>

<xsl:template match="page:javadoc">
	<xsl:variable name="pattern-name" select="fn:string()"/>
	<xsl:variable name="javadoc-conf" select="/page:page/page:javadocConfig"/>
	<xsl:variable name="javadoc-base" select="$javadoc-conf/page:baseURL"/>
	<xsl:choose>
		<xsl:when test="@to != ''"><a href="{if (fn:starts-with(@to, 'http://')) then '' else $javadoc-base}{@to}" class="javadoc"><xsl:apply-templates/></a></xsl:when>
		<xsl:when test="count($javadoc-conf/page:shortcuts/page:shortcut[@name=$pattern-name]) > 0"><a href="{$javadoc-conf/page:shortcuts/page:shortcut[@name=$pattern-name]/@uri}" class="javadoc"><xsl:apply-templates/></a>
		</xsl:when>
		<xsl:otherwise>
			<xsl:choose>
				<xsl:when test="fn:substring($pattern-name, 1, 1) = '@'">
					<xsl:variable name="class-name" select="fn:substring($pattern-name, 2)"/>
					<a href="{$javadoc-base}{fn:replace(if (fn:string(@package) = '') then $javadoc-conf/page:defaultAnnotationPackage else @package, '\.', '/')}/{$class-name}.html" class="javadoc"><xsl:apply-templates/></a>
				</xsl:when>
				<xsl:otherwise>
					<a href="{$javadoc-base}{fn:replace(if (fn:string(@package) = '') then $javadoc-conf/page:defaultPackage else @package, '\.', '/')}/{$pattern-name}.html" class="javadoc"><xsl:apply-templates/></a>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>




<xsl:template match="page:link">
<xsl:param name="selectedAnchor" tunnel="yes"/>
<xsl:variable name="linkAnchor" select="string(@anchor)"/>
<xsl:choose>
	<xsl:when test="$linkAnchor ne ''">
		<xsl:variable name="link" select="i:getSectionLink($selectedAnchor, $linkAnchor, 'auto')"/>
		<xsl:choose>
			<xsl:when test="$link/i:isSamePage eq 'true'"><a href="{$link/i:href}" onclick="if (event.button == 0) return goTo('{$link/i:href}', true); else return true;"><xsl:apply-templates/></a></xsl:when>
			<xsl:otherwise><a href="{$link/i:href}"><xsl:apply-templates/></a></xsl:otherwise>
		</xsl:choose>
	</xsl:when>
	<xsl:otherwise><a href="{@to}"><xsl:apply-templates/></a></xsl:otherwise>
</xsl:choose>
</xsl:template>


<xsl:template match="page:cmt"><xsl:choose>
<xsl:when test="../name()='config'"><span class="cmt">&lt;!-- <xsl:apply-templates/> --></span></xsl:when>
<xsl:otherwise><!-- IGNORE HERE! --></xsl:otherwise>
</xsl:choose></xsl:template>

<xsl:template match="page:plainCmt"><xsl:choose>
<xsl:when test="../name()='config'"><span class="cmt">&lt;!-- <xsl:apply-templates/> --></span></xsl:when>
<xsl:otherwise><span class="cmt">// <xsl:apply-templates/></span></xsl:otherwise>
</xsl:choose></xsl:template>

<xsl:template match="page:abstract"><span class="abstract"><xsl:apply-templates/></span></xsl:template>

<xsl:template match="page:strike"><span class="strike"><xsl:apply-templates/></span></xsl:template>

<xsl:template match="page:warn"><strong class="warn"><xsl:apply-templates/></strong></xsl:template>

<xsl:template match="page:plainCode"><span class="plainCode"><xsl:apply-templates/></span></xsl:template>

<xsl:template match="page:br"><br/></xsl:template>

<xsl:template match="page:console"><pre class="subSecConsole"><xsl:apply-templates/></pre></xsl:template>

<xsl:template match="page:svgImage"><div class="svgContainer">
<object data="{@fileBase}.svg" type="image/svg+xml" width="{@width}" height="{@height}"><img src="{@fileBase}.png" width="{@width}" height="{@height}" alt="{@alt}" /></object>
</div></xsl:template>

<xsl:template match="page:more">(<xsl:choose>
	<xsl:when test="@ref"><xsl:variable name="ref" select="@ref"/>
		<xsl:call-template name="tooltip">
			<xsl:with-param name="title">more</xsl:with-param>
			<xsl:with-param name="contentNode" select="/descendant::node()[@id=$ref]"/>
			<xsl:with-param name="haveDecoration">true</xsl:with-param>
			<xsl:with-param name="tooltipType">tooltip</xsl:with-param>
		</xsl:call-template></xsl:when>
	<xsl:otherwise>
		<xsl:call-template name="tooltip">
			<xsl:with-param name="title">more</xsl:with-param>
			<xsl:with-param name="contentNode" select="."/>
			<xsl:with-param name="haveDecoration">true</xsl:with-param>
			<xsl:with-param name="tooltipType">tooltip</xsl:with-param>
		</xsl:call-template></xsl:otherwise>
	</xsl:choose>)</xsl:template>
	
<xsl:template name="docOrTag">
	<xsl:param name="pattern-name"/>
	<xsl:param name="text"/>
	<xsl:param name="ref"/>
	<xsl:choose>
	<xsl:when test="$ref">
		<xsl:call-template name="tooltip">
			<xsl:with-param name="title"><xsl:copy-of select="$text"/></xsl:with-param>
			<xsl:with-param name="contentNode" select="/descendant::node()[@id=$ref]"/>
			<xsl:with-param name="haveDecoration">false</xsl:with-param>
			<xsl:with-param name="tooltipType">tooltip</xsl:with-param>
		</xsl:call-template></xsl:when>
	<xsl:when test="empty(/page:page/page:docConfig/page:popup[@name=$pattern-name])">
		<xsl:message terminate="yes" select="'Failed to find pattern:',$pattern-name"></xsl:message>
	</xsl:when>
	<xsl:otherwise>
		<xsl:call-template name="tooltip">
			<xsl:with-param name="title"><xsl:copy-of select="$text"/></xsl:with-param>
			<xsl:with-param name="contentNode" select="/page:page/page:docConfig/page:popup[@name=$pattern-name]"/>
			<xsl:with-param name="haveDecoration">false</xsl:with-param>
			<xsl:with-param name="tooltipType">tooltip</xsl:with-param>
		</xsl:call-template></xsl:otherwise>
	</xsl:choose></xsl:template>

<xsl:template match="page:doc">
	<xsl:call-template name="docOrTag">
		<xsl:with-param name="pattern-name" select="fn:string()"/>
		<xsl:with-param name="text"><xsl:apply-templates/></xsl:with-param>
		<xsl:with-param name="ref" select="@ref"/>
	</xsl:call-template>
</xsl:template>

<xsl:template match="page:topic">
	<xsl:variable name="keyword" select="fn:string(.)"/>
	<xsl:variable name="ttopic" select="/page:page/page:topicConfig/page:topic[page:keyword = $keyword]"/>
	<xsl:choose>
	<xsl:when test="exists($ttopic)">
	<xsl:call-template name="tooltip">
			<xsl:with-param name="title" select="$keyword"/>
			<xsl:with-param name="contentNode" select="$ttopic"/>
			<xsl:with-param name="haveDecoration">true</xsl:with-param>
			<xsl:with-param name="tooltipType">topic</xsl:with-param>
	</xsl:call-template>
	</xsl:when>
	<xsl:otherwise><xsl:copy-of select="$keyword"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!--  takes <tag> element and extracts the tag name -->
<xsl:function name="i:extractTagName">
	<xsl:param name="tag"/>
	<xsl:variable name="firstString" select="fn:string($tag/child::node()[1])"/>
	<xsl:value-of select="fn:replace($firstString, '\s.*$', '')"/>
</xsl:function>

<xsl:template match="page:tag">
	<xsl:variable name="tagName" select="i:extractTagName(.)"/>
	<xsl:variable name="afterNameText" select="fn:substring-after(fn:string(child::node()[1]), $tagName)"/>
	<span class="tag">&lt;<xsl:call-template name="docOrTag">
		<xsl:with-param name="pattern-name" select="$tagName"/>
		<xsl:with-param name="text" select="$tagName"/>
		<xsl:with-param name="ref" select="@ref"/>
	</xsl:call-template><xsl:value-of select="$afterNameText"/><xsl:apply-templates select="child::node()[fn:position() > 1]"/><xsl:if test="name()='tag' and @stand-alone"> /</xsl:if>></span>
</xsl:template>


<xsl:template match="page:ctag">
	<xsl:variable name="prevTags" select="preceding-sibling::*[name()='tag' or name()='ctag']"/>
	<xsl:variable name="openingTag" select="
	(for $anytag in $prevTags
	    return if (name($anytag)='tag' and count($prevTags[name()='tag' and ($anytag &lt;&lt; .)]) = count($prevTags[name()='ctag' and ($anytag &lt;&lt; .)])) then $anytag else ())[last()]
	"/>
	<xsl:variable name="tagName" select="i:extractTagName($openingTag)"/>

	<span class="tag">&lt;/<xsl:call-template name="docOrTag">
		<xsl:with-param name="pattern-name" select="$tagName"/>
		<xsl:with-param name="text" select="$tagName"/>
		<xsl:with-param name="ref" select="$openingTag/@ref"/>
	</xsl:call-template>></span>

</xsl:template>

<xsl:template match="page:annotated">
	<xsl:variable name="ref" select="@ref"/>
	<xsl:choose>
		<xsl:when test="@ref"><xsl:call-template name="tooltip">
	<xsl:with-param name="title"><xsl:apply-templates select="if (page:title) then page:title else /descendant::node()[@id=$ref]/page:title"/></xsl:with-param>
	<xsl:with-param name="contentNode" select="/descendant::node()[@id=$ref]/page:explanation"/>
	<xsl:with-param name="haveDecoration">true</xsl:with-param>
	<xsl:with-param name="tooltipType">tooltip</xsl:with-param>
</xsl:call-template></xsl:when>
		<xsl:otherwise><xsl:call-template name="tooltip">
	<xsl:with-param name="title"><xsl:apply-templates select="page:title"/></xsl:with-param>
	<xsl:with-param name="contentNode" select="page:explanation"/>
	<xsl:with-param name="haveDecoration">true</xsl:with-param>
	<xsl:with-param name="tooltipType">tooltip</xsl:with-param>
</xsl:call-template></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="page:list"><ul><xsl:if test="not(ancestor::page:list)"><xsl:attribute name="class" select="'subSecList'"/></xsl:if><xsl:for-each select="page:li"><li><xsl:apply-templates select="."/></li></xsl:for-each></ul></xsl:template>
<xsl:template match="page:orderedList"><ol><xsl:if test="not(ancestor::page:list)"><xsl:attribute name="class" select="'subSecList'"/></xsl:if><xsl:for-each select="page:li"><li><xsl:apply-templates select="."/></li></xsl:for-each></ol></xsl:template>

<xsl:template match="page:table"><div class="subSecTableDiv"><table>
<xsl:for-each select="page:head"><tr><xsl:for-each select="page:cell"><th><xsl:apply-templates select="."/></th></xsl:for-each></tr></xsl:for-each>
<xsl:for-each select="page:row"><tr><xsl:for-each select="page:cell"><td><xsl:apply-templates select="."/></td></xsl:for-each></tr></xsl:for-each>
</table></div>
</xsl:template>



<xsl:template name="genericSubSection">
	<xsl:param name="summary"/>
	<xsl:param name="head"/>
	<xsl:param name="anchor"/>
	<xsl:param name="selectedAnchor"/>
	<xsl:param name="isCollapsed"/>
	
	<div class="subSecRow{2-((index-of($articleSections/*/@anchor, $anchor)) mod 2)}" id="sec_{$anchor}">
		<xsl:if test="not($multipageEnabled) and $isCollapsed eq 'true'">
			<xsl:attribute name="style">display: none</xsl:attribute>
		</xsl:if>
		<div class="subSecHead" id="sechd_{$anchor}"><xsl:choose><xsl:when test="$anchor eq ''"></xsl:when><xsl:when test="$multipageEnabled or not(/page:page/page:multipage)"><a name="{$anchor}"><xsl:value-of select="$head"/></a></xsl:when><xsl:otherwise><a class="multipageHeadLink" href="{i:getSectionLink($selectedAnchor, $anchor, 'multi')/i:href}" name="{$anchor}"><xsl:value-of select="$head"/></a></xsl:otherwise></xsl:choose>
		<xsl:if test="count(page:more)>0"><br/>(<xsl:call-template name="tooltip">
		<xsl:with-param name="title">more</xsl:with-param>
		<xsl:with-param name="contentNode" select="page:more"/>
		<xsl:with-param name="haveDecoration">true</xsl:with-param>
		<xsl:with-param name="tooltipType">tooltip</xsl:with-param>
		</xsl:call-template>)
		</xsl:if></div><div class="subSecContent" id="seccnt_{$anchor}">
		<xsl:if test="$summary ne ''">
			<xsl:choose>
				<xsl:when test="$multipageEnabled and $selectedAnchor ne $anchor">
					<h2 class="subSecSummaryNoClick"><xsl:value-of select="$summary"/></h2>				
				</xsl:when>
				<xsl:when test="not($multipageEnabled) and $isCollapsed ne 'true'">
					<h3 class="subSecSummaryNoClick"><xsl:value-of select="$summary"/></h3>				
				</xsl:when>
				<xsl:when test="not($multipageEnabled)">
					<div class="subSecSummaryClick"><a href="#" onclick="return hideCollapsableSection('{$anchor}');"><xsl:value-of select="$summary"/></a></div>				
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:for-each select="*">
			<xsl:choose>
				<xsl:when test="name()='code'">
				<xsl:variable name="maxLen" select="fn:max(for $i in page:line[fn:count(page:cmt)>0] return (fn:string-length($i)-fn:string-length($i/page:cmt)))"/>
					<pre class="subSecCode"><code>
						<xsl:for-each select="*">
							<xsl:choose>
								<xsl:when test="name()='line'">
									<xsl:apply-templates select="."><xsl:with-param name="selectedAnchor" tunnel="yes" select="$selectedAnchor"/></xsl:apply-templates>
									<xsl:if test="fn:count(page:cmt)>0">
										<xsl:call-template name="spaces">
											<xsl:with-param name="number" select="($maxLen + 2 - (fn:string-length(.)-(if (fn:count(page:cmt)>0) then fn:string-length(page:cmt) else 0))) cast as xs:integer"/>
										</xsl:call-template><span class="cmt">// <xsl:apply-templates select="page:cmt/node()"><xsl:with-param name="selectedAnchor" tunnel="yes" select="$selectedAnchor"/></xsl:apply-templates></span>
									</xsl:if>
									<xsl:text>
</xsl:text>
								</xsl:when>
								<xsl:otherwise><xsl:text>
</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</code></pre>
				</xsl:when>
				<xsl:when test="name()='explanation'"><p class="subSecExplanation"><xsl:apply-templates><xsl:with-param name="selectedAnchor" tunnel="yes" select="$selectedAnchor"/></xsl:apply-templates></p></xsl:when>
				<xsl:when test="name()='config'"><pre class="subSecConfig"><xsl:apply-templates><xsl:with-param name="selectedAnchor" tunnel="yes" select="$selectedAnchor"/></xsl:apply-templates></pre></xsl:when>
				<xsl:when test="name()='miniHeadline'"><h4 class="subSecMiniHeadline"><xsl:apply-templates><xsl:with-param name="selectedAnchor" tunnel="yes" select="$selectedAnchor"/></xsl:apply-templates></h4></xsl:when>
				<xsl:when test="name()='list' or name()='orderedList' or name()='table' or name()='console' or name()='svgImage'"><xsl:apply-templates select="."><xsl:with-param name="selectedAnchor" tunnel="yes" select="$selectedAnchor"/></xsl:apply-templates></xsl:when>
				<xsl:otherwise></xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</div></div>
</xsl:template>

<xsl:template name="printYahBar">
	<xsl:param name="selectedAnchor"/>
	<xsl:param name="fullBar"/>

	<xsl:variable name="selected" select="i:getNodeByAnchor($selectedAnchor)"/>
	<xsl:variable name="anchorList" select="for $a in $articleSections return (if ($a/@multipage eq 'true') then i:getSubSections($a)/@anchor else $a/@anchor)"/>
	<xsl:variable name="currentIndex" select="index-of($anchorList, $selectedAnchor)"/>
	<xsl:variable name="prevLink" select="if ($currentIndex eq 1) then '' else i:getSectionLink($selectedAnchor, string($anchorList[$currentIndex - 1]), 'auto')"/>
	<xsl:variable name="nextLink" select="if ($currentIndex eq count($anchorList)) then '' else i:getSectionLink($selectedAnchor, string($anchorList[$currentIndex + 1]), 'auto')"/>
	<xsl:variable name="startLink" select="i:getSectionLink($selectedAnchor, string($anchorList[1]), 'auto')"/>
	<div class="yahbar">
		<xsl:if test="$prevLink ne ''">
		<div class="yahprev"><a href="{$prevLink/i:page}">Prev<xsl:if test="$fullBar eq 'true'"><br/><span><xsl:value-of select="$prevLink/i:title"/></span></xsl:if></a></div>
		</xsl:if>
		<xsl:choose>
		<xsl:when test="$fullBar eq 'true'">
		<div class="yahhere"><a href="#" onclick="return navToggle();"><xsl:value-of select="/page:page/page:title"/> / <xsl:value-of select="i:getSectionByAnchor($selectedAnchor)/page:head"/></a><br/><a href="{/page:page/page:path}"><span>Single Page Mode</span></a>, <a href="#" onclick="return navToggle();"><span>Show Table of Content</span></a></div>
		</xsl:when>
		<xsl:otherwise><h3 class="yahhere"><a href="#" onclick="return navToggle();"><xsl:value-of select="/page:page/page:title"/> / <xsl:value-of select="i:getSectionByAnchor($selectedAnchor)/page:head"/></a></h3></xsl:otherwise>
		</xsl:choose>
		<xsl:if test="$nextLink ne ''">
		<div class="yahnext"><a href="{$nextLink/i:page}">Next<xsl:if test="$fullBar eq 'true'"><br/><span><xsl:value-of select="$nextLink/i:title"/></span></xsl:if></a></div>
		</xsl:if>
	</div>
</xsl:template>

<xsl:template match="page:singleColumnSection">
	<xsl:param name="selectedAnchor" tunnel="yes"/>

	<xsl:if test="$multipageEnabled">
		<xsl:call-template name="printYahBar">
			<xsl:with-param name="selectedAnchor" select="$selectedAnchor"/>
			<xsl:with-param name="fullBar">false</xsl:with-param>
		</xsl:call-template>
	</xsl:if>

	
	<xsl:choose>
		<xsl:when test="$selectedAnchor=@anchor">
			<h1 id="sec_{@anchor}" class="multipageTitle"><a name="{@anchor}"><xsl:value-of select="page:head"/></a></h1>
		</xsl:when>
		<xsl:when test="$multipageEnabled">
			<h1 id="sec_{@anchor}" class="multipageTitle"><xsl:value-of select="if (*[@anchor eq $selectedAnchor]/page:summary) then (*[@anchor eq $selectedAnchor]/page:summary) else (*[@anchor eq $selectedAnchor]/page:head) "/></h1>
		</xsl:when>
		<xsl:otherwise>
			<h2 id="sec_{@anchor}" class="sectionHead"><a name="{@anchor}"><xsl:value-of select="page:head"/></a></h2>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:for-each select="page:intro"><div class="sectionIntro"><xsl:apply-templates/></div></xsl:for-each>
	
	<xsl:if test="count(page:collapsedSubSection) > 1 and not($multipageEnabled)">
		<div class="sectionExpandAll">
			(<a href="#">
				<xsl:attribute name="onclick">
return showAll([<xsl:for-each select="page:collapsedSubSection">['colla_<xsl:value-of select="@anchor"/>','sec_<xsl:value-of select="@anchor"/>'],</xsl:for-each> null]); 
</xsl:attribute>expand everything</a>)
		</div>
	</xsl:if>

	<xsl:for-each select="(page:subSection|page:collapsedSubSection)[$selectedAnchor eq '' or $selectedAnchor eq @anchor or ../@anchor=$selectedAnchor]">
		<xsl:variable name="anchor" select="string(@anchor)"/>
		<xsl:choose>
			<xsl:when test="name()='collapsedSubSection'">
				<xsl:variable name="collaSecId" select="concat('colla_', $anchor)"/>
				<xsl:if test="not($multipageEnabled)">
				<div id="{$collaSecId}" class="subSecRow{2-(index-of($articleSections/*/@anchor, $anchor) mod 2)}">
				<div class="subSecHead"><xsl:choose><xsl:when test="$multipageEnabled or not(/page:page/page:multipage)"><a name="{@anchor}"><xsl:value-of select="page:head"/></a></xsl:when><xsl:otherwise><a class="multipageHeadLink" href="{i:getSectionLink($selectedAnchor, @anchor, 'multi')/i:href}" name="{@anchor}"><xsl:value-of select="page:head"/></a></xsl:otherwise></xsl:choose></div>
				<div class="collapsedSubSecSummary">
					<div>
						<a href="#" onclick="return showCollapsableSection('{$anchor}');"><xsl:value-of select="page:summary"/></a>
					</div>
				</div></div>
				</xsl:if>
				<xsl:for-each select="page:content">
					<xsl:call-template name="genericSubSection">
						<xsl:with-param name="summary" select="../page:summary"/>
						<xsl:with-param name="head" select="../page:head"/>
						<xsl:with-param name="anchor" select="../@anchor"/>
						<xsl:with-param name="selectedAnchor" select="$selectedAnchor"/>
						<xsl:with-param name="isCollapsed" select="'true'"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise> 
				<xsl:call-template name="genericSubSection">
					<xsl:with-param name="summary" select="()"/>
					<xsl:with-param name="head" select="page:head"/>
					<xsl:with-param name="anchor" select="@anchor"/>
					<xsl:with-param name="selectedAnchor" select="$selectedAnchor"/>
					<xsl:with-param name="isCollapsed" select="'false'"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:for-each>
	
	<xsl:if test="$multipageEnabled">
		<xsl:call-template name="printYahBar">
			<xsl:with-param name="selectedAnchor" select="$selectedAnchor"/>
			<xsl:with-param name="fullBar">true</xsl:with-param>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<xsl:template match="page:box">
	<div>
		<h3><xsl:value-of select="page:title"/></h3>
		<div class="sidecolumnSubTitleLine"><xsl:value-of select="page:subTitleLine"/></div>
		<xsl:apply-templates select="page:content"/>
	</div>
</xsl:template>

<xsl:template match="page:htmlBox">
	<div>
		<h3><xsl:value-of select="page:title"/></h3>
		<xsl:copy-of select="page:html"/>
	</div>
</xsl:template>

<xsl:template match="page:sidebar">
	<xsl:apply-templates/>
</xsl:template>



<xsl:template name="page">
<xsl:param name="selectedAnchor"/>

<xsl:variable name="root" select="/"/>
<xsl:variable name="isSelectedAnchorSection" select="page:article/page:body/*[@anchor eq $selectedAnchor]"/>
<xsl:variable name="selectedSectionTitle" select="i:getSectionByAnchor($selectedAnchor)/page:head"/>
<xsl:variable name="selectedNode" select="i:getNodeByAnchor($selectedAnchor)"/>
<xsl:variable name="selectedTitle" select="string(if($selectedNode/page:summary) then $selectedNode/page:summary else $selectedNode/page:head)"/>

<xsl:for-each select="/page:page">
<xsl:variable name="rootPath" select="if (count(page:root) > 0) then string(page:root) else '../../'"/>
<html>
<head>
	<title><xsl:if test="$selectedAnchor ne ''"><xsl:value-of select="$selectedTitle"/> - </xsl:if><xsl:value-of select="page:title"/></title>
	<meta http-equiv="X-UA-Compatible" content="chrome=1"/>
	<xsl:if test="count(page:metaKeywords)>0"><meta http-equiv="keywords" content="{page:metaKeywords}"/></xsl:if>
	<meta http-equiv="content-language" content="en"/>
	<link rel="shortcut icon" href="{$rootPath}images/favicon.png" type="image/png" />
	<link rel="stylesheet" type="text/css" href="{$rootPath}style/style.css"/>
	<xsl:for-each select="page:styleSheet"><link rel="StyleSheet" href="{$rootPath}{string()}" type="text/css"/></xsl:for-each>
	<xsl:if test="page:embeddedStyle">
		<style type="text/css">
			<xsl:value-of select="page:embeddedStyle"/>
		</style>
	</xsl:if>
	<script type="text/javascript">
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-6791190-2']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);
})();
</script>
<script type="text/javascript" src="{$rootPath}js/all.js" />
</head>
<body id="body">
	<div id="visibleContent">
		<div id="top"><a href="/"><img src="{$rootPath}images/titlebar.png" alt="Jarfiller.com"/></a></div>
		
		<xsl:if test="exists(page:title) and not(exists(page:html)) and not($multipageEnabled)">
				<div id="titleArea">
				<h1><xsl:value-of select="page:title"/></h1>
				<xsl:if test="count(page:titleIntro) > 0">
				<p id="titleIntro"><xsl:apply-templates select="page:titleIntro"/></p>
				</xsl:if> 
				</div>
		</xsl:if>
	
		<xsl:if test="page:article">
			<div id="main">
				<div id="bodycolumn">
					<xsl:choose>
					<xsl:when test="not($multipageEnabled)">
					<div id="options">Options: <a href="#" onclick="return navToggle();">Table of Content</a>, <a href="{i:getSectionLink($selectedAnchor, $articleSections[1]/@anchor, 'multi')/i:page}">Multi-Page Version</a> 
					</div>
					</xsl:when>
					<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
					<xsl:apply-templates select="page:article/page:body/page:singleColumnSection[$selectedAnchor eq '' or @anchor eq $selectedAnchor or (@multipage eq 'true' and */@anchor = $selectedAnchor)]">
						<xsl:with-param name="selectedAnchor" select="$selectedAnchor"  tunnel="yes"/>
					</xsl:apply-templates>
				</div>
				<div id="sidecolumn"><xsl:apply-templates select="page:article/page:sidebar"/></div>
			</div>
		</xsl:if>
		
		<xsl:if test="page:html">
			<xsl:copy-of select="page:html/node()"/>
		</xsl:if>
		
	</div>

	<div id="footer">
		<div id="footer-content">
			<div id="footer-left">
				<div class="footerLine"><a href="/">Home</a> - <a href="/about">About Jarfiller</a> - <a href="/imprint.xhtml">Imprint</a></div>
				<div class="footerLine">Please send feedback and corrections to <a href="mailto:tim@tjansen.de">tim@<span style="display: none">got you</span>tjansen.de</a>.</div>
				<div class="footerLine"><a href="http://www.twitter.com/timjansen">Follow</a> me on Twitter.</div>

				<div class="copyrightLine">© 2010 Tim Jansen<xsl:if test="page:license eq 'cc-by-free-src'">; content licensed under <a href="http://creativecommons.org/licenses/by/3.0/us/">cc-by</a>; example source code is public domain
				</xsl:if></div>
			</div>
			<div id="footer-right">
				<xsl:if test="page:license eq 'cc-by-free-src'">
					<a rel="license" href="http://creativecommons.org/licenses/by/3.0/us/"><img alt="Creative Commons License" style="border-width:0" src="{$rootPath}images/ext/cc-by-88x31.png" /></a>
				</xsl:if>
			
			</div>
		</div>
	</div>
	
	<!-- Navigation -->
	<xsl:if test="page:article">
	<div id="navbar" onclick="return navToggle();" onmouseover="document.getElementById('navbar').className='mouseover';"  onmouseout="document.getElementById('navbar').className='';">
	</div>
	<div id="navcontainer">
		<div id="navlinks">
			<div id="navclosebar"><a href="#" onclick="return navClose();"><img src="{$rootPath}images/close.png" height="16" width="16" alt="close" /></a></div>
			<div id="navpositionbar" class="navpositionbar"/>
			<h2 id="navtitle"><xsl:value-of select="page:title"/></h2>
			<xsl:for-each select="$articleSections">
				<xsl:variable name="section" select="."/>
				<xsl:variable name="linkInfo" select="i:getSectionLink($selectedAnchor, $section/@anchor, 'auto')"/>
					<xsl:choose>
						<xsl:when test="$linkInfo/i:isLinkAvailable ne 'true'"><span class="navseclink"><xsl:value-of select="$linkInfo/i:title"/></span></xsl:when>
						<xsl:when test="$linkInfo/i:isSamePage eq 'true'"><a id="nav_{$section/@anchor}" class="navseclink" href="{$linkInfo/i:href}" onclick="if (event.button == 0) return goTo('{$linkInfo/i:href}', true); else return true;"><xsl:value-of select="$linkInfo/i:title"/></a></xsl:when>
						<xsl:otherwise><a id="nav_{$section/@anchor}" class="navseclink" href="{$linkInfo/i:href}"><xsl:value-of select="$linkInfo/i:title"/></a></xsl:otherwise>
					</xsl:choose>

				<xsl:for-each select="i:getSubSections($section)">
					<xsl:variable name="linkInfo" select="i:getSectionLink($selectedAnchor, @anchor, 'auto')"/>
					<xsl:choose>
						<xsl:when test="$linkInfo/i:isSamePage eq 'true'"><a id="nav_{@anchor}" class="navsublink" href="{$linkInfo/i:href}" onclick="if (event.button == 0) return goTo('{$linkInfo/i:href}', true); else return true;"><xsl:value-of select="$linkInfo/i:title"/></a></xsl:when>
						<xsl:otherwise><a id="nav_{@anchor}" class="navsublink" href="{$linkInfo/i:href}"><xsl:value-of select="$linkInfo/i:title"/></a></xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:for-each>
		</div>
	</div>
	</xsl:if>
	
	<div id="popups">
		<!-- Popups for more, annotations, docs and tags: -->
		<xsl:variable name="displayedContent" select="if ($selectedAnchor eq '') then $articleSections
		                                              else $articleSections[@anchor eq $selectedAnchor], $articleSections/*[@anchor eq $selectedAnchor]"/>
		<xsl:variable name="usedIds" select="fn:unordered(fn:distinct-values(($displayedContent/descendant::page:tag/@ref, $displayedContent/descendant::page:doc/@ref, $displayedContent/descendant::page:annotated/@ref)))"/>
		<xsl:variable name="usedNames" select="fn:unordered(fn:distinct-values((for $n in $displayedContent/descendant::page:doc return string($n),
		                                                                        for $n in $displayedContent/descendant::page:tag return i:extractTagName($n))))"/>
		<xsl:for-each select="$displayedContent/descendant::page:more[not(@ref)], 
		                      $displayedContent/descendant::page:annotated[not(@ref)]/page:explanation,
		                      page:docConfig/page:popup[@id=$usedIds or @name=$usedNames]"> 
			<xsl:call-template name="tooltipDiv">
				<xsl:with-param name="id" select="concat('pp-', generate-id(.))"/>
				<xsl:with-param name="content"><xsl:apply-templates select="./node()"/></xsl:with-param>
				<xsl:with-param name="class" select="'tooltip'"/>
			</xsl:call-template>
		</xsl:for-each>
	
		<!-- Popups for topics: -->
		<xsl:for-each select="page:topicConfig/page:topic[page:keyword = $displayedContent/descendant::page:topic]"> 
			<xsl:call-template name="tooltipDiv">
				<xsl:with-param name="id" select="concat('pp-', generate-id(.))"/>
				<xsl:with-param name="content"><div class="topicPara"><span class="topicHead"><xsl:value-of select="page:headline"/></span>
				<xsl:if test="page:abbreviation"><span class="topicAbbreviation"> - <xsl:value-of select="page:abbreviation"/></span></xsl:if></div>
				
				<div class="topicPara"><xsl:apply-templates select="page:description"/></div>
				
				<xsl:if test="page:relatedGuides or page:relatedReferences">
					<div class="topicPara">
						<xsl:if test="page:relatedGuides"><span class="topicLinkHead">Jarfiller Guide: </span> <xsl:apply-templates select="page:relatedGuides"/><xsl:if test="page:relatedReferences"><br/></xsl:if></xsl:if>
						<xsl:if test="page:relatedReferences"><span class="topicLinkHead">Jarfiller Reference: </span> <xsl:apply-templates select="page:relatedReferences"/></xsl:if>
					</div>
				</xsl:if>
				
				<xsl:if test="page:homepage or page:wikipedia">
					<div class="topicPara">
						<xsl:if test="page:homepage"><span class="topicLinkHead">Homepage: </span> <xsl:apply-templates select="page:homepage"/><xsl:if test="page:wikipedia"><br/></xsl:if></xsl:if>
						<xsl:if test="page:wikipedia"><span class="topicLinkHead">Wikipedia: </span> <xsl:apply-templates select="page:wikipedia"/></xsl:if>
					</div>
				</xsl:if>
				
				<xsl:if test="page:specification or page:api or page:jsr">
					<div class="topicPara">
						<xsl:if test="page:specification"><span class="topicLinkHead">Specification: </span> <xsl:apply-templates select="page:specification"/><xsl:if test="page:api or page:jsr"><br/></xsl:if></xsl:if>
						<xsl:if test="page:api"><span class="topicLinkHead">API: </span> <xsl:apply-templates select="page:api"/><xsl:if test="page:jsr"><br/></xsl:if></xsl:if>
						<xsl:if test="page:jsr"><span class="topicLinkHead">JSR: </span> <xsl:apply-templates select="page:jsr"/></xsl:if>
					</div>
				</xsl:if>
				</xsl:with-param>
				<xsl:with-param name="class" select="'topic'"/>
			</xsl:call-template>
		</xsl:for-each>
		
		<!-- Popup helpers -->
		<div id="ttCloseBar" class="closeBar"><a href="#" onclick="return tlClose();"><img src="{$rootPath}images/close.png" height="16" width="16" alt="close" /></a></div>
		<div id="topicCloseBar" class="closeBar"><a href="#" onclick="return tpcClose();"><img src="{$rootPath}images/close.png" height="16" width="16" alt="close" /></a></div>
	</div>
</body>
</html>
</xsl:for-each>
</xsl:template>

<xsl:template match="/page:page">
	<xsl:call-template name="page"><xsl:with-param name="selectedAnchor" select="''"/></xsl:call-template>
	
	<xsl:if test="/page:page/page:multipage and $multipageEnabled"> <!--   -->
		<xsl:for-each select="$articleSections[not(@multipage) or @multipage eq 'false'], 
				$articleSections[@multipage eq 'true']/(page:collapsedSubSection|page:subSection)">
			<xsl:variable name="anchor" select="@anchor"/>
			<xsl:message>{<xsl:value-of select="concat($anchor, ' -- ', $multipagePath, $pagePath, $anchor, '.xhtml')"/>}</xsl:message>
			<xsl:for-each select="/page:page">
				<xsl:result-document href="{$multipagePath}{$pagePath}{$anchor}.xhtml"><xsl:call-template name="page"><xsl:with-param name="selectedAnchor" select="$anchor"/></xsl:call-template></xsl:result-document>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:if>
</xsl:template>
</xsl:stylesheet>