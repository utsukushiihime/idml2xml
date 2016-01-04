<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
    xmlns:aid   = "http://ns.adobe.com/AdobeInDesign/4.0/"
    xmlns:aid5  = "http://ns.adobe.com/AdobeInDesign/5.0/"
    xmlns:idPkg = "http://ns.adobe.com/AdobeInDesign/idml/1.0/packaging"
    xmlns:idml2xml  = "http://transpect.io/idml2xml"
  exclude-result-prefixes="idPkg aid5 aid xs"
>

  <xsl:template match="idml2xml:genSpan[not(@*)]" mode="idml2xml:AutoCorrect">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[not(node())]"
		mode="idml2xml:AutoCorrect" priority="1.5" />

  <xsl:template match="idml2xml:genSpan[*[name() = ($idml2xml:shape-element-names, 'idml2xml:genFrame')]]
                                       [every $n in node() satisfies (name($n) = ($idml2xml:shape-element-names, 'idml2xml:genFrame'))]
                                       [not(@AppliedConditions)]"
    mode="idml2xml:AutoCorrect" priority="1.5">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="idml2xml:genSpan
                         [string-length(.) eq 0]
                         [
                           not(*[name()=$idml2xml:idml-content-element-names])
                           and 
                           not(.//EPS or .//PDF or .//Image or .//WMF)
                         ]" mode="idml2xml:AutoCorrect" priority="1.25" >
  </xsl:template>


  <xsl:template match="idml2xml:genSpan[@aid:pstyle][not(../@aid:cstyle)]" mode="idml2xml:AutoCorrect">
    <idml2xml:genPara>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </idml2xml:genPara>
  </xsl:template>

  <xsl:template match="*[@idml2xml:AppliedParagraphStyle ne @aid:pstyle]/@aid:pstyle" mode="idml2xml:AutoCorrect">
    <xsl:attribute name="aid:pstyle" select="../@idml2xml:AppliedParagraphStyle" />
  </xsl:template>

  <xsl:template match="*[@idml2xml:AppliedParagraphStyle ne @aid:pstyle]/@idml2xml:AppliedParagraphStyle" mode="idml2xml:AutoCorrect">
    <xsl:attribute name="idml2xml:pstyle-was" select="../@aid:pstyle" />
  </xsl:template>

  <xsl:template match="*[@idml2xml:AppliedCellStyle ne @aid5:cellstyle]/@idml2xml:AppliedCellStyle" mode="idml2xml:AutoCorrect">
    <xsl:attribute name="idml2xml:cellstyle-was" select="../@aid5:cellstyle" />
  </xsl:template>

  <xsl:template match="*[@idml2xml:AppliedCellStyle ne @aid5:cellstyle]/@aid5:cellstyle" mode="idml2xml:AutoCorrect">
    <xsl:attribute name="aid5:cellstyle" select="../@idml2xml:AppliedCellStyle" />
  </xsl:template>
  
  <xsl:template match="idml2xml:ParagraphStyleRange[matches(@idml2xml:reason, 'et1')]" mode="idml2xml:AutoCorrect">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template
    match="idml2xml:ParagraphStyleRange[matches(@idml2xml:reason, 'cp1')][idml2xml:genPara][every $c in * satisfies ($c/self::idml2xml:genPara)]" 
    mode="idml2xml:AutoCorrect" priority="3">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <!-- GI 2012-10-02
       I suppose this template is for dealing with tagging extraction. We had a case when an idml2xml:genTable was 
       unwrapped from the parastylerange and got an attached aid:pstyle attribute. This prolly doesn’t hurt, but
       we better leave the genTable in the genPara. -->
  <xsl:template
    match="idml2xml:ParagraphStyleRange[matches(@idml2xml:reason, 'cp1')][count(*) eq 1][not(*/@aid:cstyle)][not(idml2xml:genTable)]" 
    mode="idml2xml:AutoCorrect" priority="2">
    <xsl:element name="{name(*)}">
      <xsl:apply-templates select="*/@*" mode="#current"/>
      <xsl:attribute name="aid:pstyle" select="@AppliedParagraphStyle" />
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac2'), ' ')" />
      <xsl:apply-templates select="*/node()" mode="#current" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="idml2xml:ParagraphStyleRange[matches(@idml2xml:reason, 'cp1')]" mode="idml2xml:AutoCorrect">
    <idml2xml:genPara idml2xml:reason="cp1 ac1" aid:pstyle="{@AppliedParagraphStyle}">
      <xsl:apply-templates mode="#current" />
    </idml2xml:genPara>
  </xsl:template>

  <!-- default handler, with the slight modification that it collects its ancestor ParagraphStyleRange’s @srcpath attribute -->
  <xsl:template match="idml2xml:genPara" mode="idml2xml:AutoCorrect">
    <xsl:copy>
      <xsl:apply-templates mode="#current"
        select="parent::idml2xml:ParagraphStyleRange/@*[not(name() = ('AppliedParagraphStyle', 'idml2xml:reason'))], @*"/>
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac13'), ' ')" />
      <xsl:apply-templates mode="#current"
        select="parent::idml2xml:ParagraphStyleRange/Properties"/>
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
  </xsl:template>
  
  <xsl:template 
    match="idml2xml:genPara[count(distinct-values(for $p in *[@aid:pstyle] return name($p))) eq 1]" 
    mode="idml2xml:AutoCorrect">
    <xsl:apply-templates mode="#current" />
  </xsl:template>


  <xsl:template match="idml2xml:genPara[idml2xml:contains(@idml2xml:reason, 'gp2')]" mode="idml2xml:AutoCorrect idml2xml:AutoCorrect-group-pseudoparas" priority="4">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac12'), ' ')" />
      <xsl:call-template name="group-pseudoparas">
        <xsl:with-param name="pstyle" select="@aid:pstyle" tunnel="yes"/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[*/@aid:pstyle]" mode="idml2xml:AutoCorrect-group-pseudoparas">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac11'), ' ')" />
      <xsl:call-template name="group-pseudoparas" />
    </xsl:copy>
  </xsl:template>

  <xsl:template name="group-pseudoparas">
    <xsl:param name="pstyle" as="xs:string" tunnel="yes"/>
    <xsl:for-each-group select="node()[not(self::comment())]" group-adjacent="if (@aid:pstyle) then name() else false()">
      <xsl:choose>
        <xsl:when test="current-grouping-key()">
          <xsl:element name="{name()}">
            <xsl:copy-of select="current-group()[last()]/@*" />
            <xsl:if test="$srcpaths = 'yes'"><xsl:attribute name="srcpath" select="current-group()/@srcpath" /></xsl:if>
            <xsl:attribute name="idml2xml:reason" select="'ac6'" />
            <xsl:apply-templates select="current-group()/node()" mode="idml2xml:AutoCorrect" />
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()" mode="idml2xml:AutoCorrect-group-pseudoparas" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>


  <xsl:template match="@idml2xml:AppliedParagraphStyle[matches(../@idml2xml:reason, 'gp3')]" mode="idml2xml:AutoCorrect">
    <xsl:if test="../@aid:pstyle">
      <xsl:attribute name="idml2xml:pstyle-was" select="../@aid:pstyle" />
    </xsl:if>
    <xsl:attribute name="aid:pstyle" select="." />
  </xsl:template>



  <xsl:template match="*[@aid:cstyle]
                        [idml2xml:genSpan]
                        [count(*) eq 1]" mode="idml2xml:AutoCorrect">
    <xsl:copy>
      <xsl:copy-of select="@*" />
      <xsl:copy-of select="*/@*" /><!-- genSpan's cstyle will win -->
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, */@idml2xml:reason, 'ac10'), ' ')" />
      <xsl:apply-templates mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[@aid:cstyle]
                        [idml2xml:genSpan]
                        [count(*) eq 1]/
                       idml2xml:genSpan" mode="idml2xml:AutoCorrect">
    <xsl:apply-templates mode="#current" />
  </xsl:template>



  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode: idml2xml:AutoCorrect-clean-up -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="@idml2xml:AppliedParagraphStyle[. = ../@aid:pstyle]" mode="idml2xml:AutoCorrect-clean-up" />

  <xsl:template match="*[not(self::idml2xml:genPara)][@aid:pstyle]" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:param name="genPara" as="element(idml2xml:genPara)?" tunnel="yes" />
    <xsl:choose>
      <xsl:when test="$genPara/@aid:pstyle and idml2xml:same-scope(., $genPara)">
        <xsl:copy>
          <xsl:copy-of select="@*" />
          <xsl:attribute name="aid:pstyle" select="$genPara/@aid:pstyle" />
          <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac8'), ' ')" />
          <xsl:apply-templates mode="#current" />
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- one kind of pstyled element, together with optional anchored objects and character ranges. Everything will be wrapped in an element like the last pstyled   -->
  <xsl:template match="idml2xml:genPara
                         [*[@aid:pstyle]]
                         [count(distinct-values(for $p in *[@aid:pstyle] return name($p))) eq 1]
                         [count(      *[@aid:pstyle] 
                                | *[@aid:cstyle] 
                                | *[@idml2xml:AppliedCharacterStyle] 
                                | *[@idml2xml:story]
                                | text()
                               ) 
                          eq count(node())
                         ]" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:element name="{name(*[@aid:pstyle][last()])}">
      <xsl:copy-of select="*[@aid:pstyle][last()]/@*" />
      <xsl:attribute name="aid:pstyle" select="@aid:pstyle" />
      <xsl:attribute name="idml2xml:reason" select="string-join((@idml2xml:reason, 'ac7'), ' ')" />
      <xsl:apply-templates select="      *[@aid:pstyle]/node() 
                                   union *[@aid:cstyle] 
                                   union *[@idml2xml:AppliedCharacterStyle] 
                                   union *[@idml2xml:story]
                                   union text()" mode="#current" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="idml2xml:genSpan[matches(@aid:cstyle, 'No.character.style')]
		                                   [parent::idml2xml:genPara[count(descendant::idml2xml:genSpan) = 1]]
		                                   [not(@*[not(matches(name(), '^(srcpath|idml2xml|aid)'))])]" 
		mode="idml2xml:AutoCorrect-clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <!-- dissolve genSpans that contain only tables or rectangles because the information cannot be used later-->
  <xsl:template match="idml2xml:genSpan[idml2xml:genTable or Rectangle]
                                       [count(*) = (1, 2)]
                                       [every $text in text() satisfies (not(matches($text, '\S')))]
                                       [every $node in node()[not(self::text())] satisfies ($node/local-name() = ('Rectangle', 'genTable', 'Properties'))]
                                       [not(@AppliedConditions) and Rectangle]" 
                mode="idml2xml:AutoCorrect-clean-up" priority="3">
    <xsl:apply-templates select="*[self::idml2xml:genTable or self::Rectangle]" mode="#current"/>
  </xsl:template>

  <xsl:template match="HiddenText[empty(node())]" mode="idml2xml:AutoCorrect-clean-up" />
  
  
  <xsl:template match="idml2xml:genFrame[@idml2xml:elementName eq 'Group']
                                        [count(node()) eq 1]" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  
  <!-- make @srcpath unique: -->
  
  <xsl:key name="by-srcpath" match="*[@srcpath]" use="@srcpath"/>
  
  <xsl:template match="@srcpath" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:variable name="same-path-items" select="key('by-srcpath', .)/generate-id()" as="xs:string+"/>
    <xsl:choose>
      <xsl:when test="$srcpaths = 'no'"/>
      <xsl:when test="count($same-path-items) gt 1">
        <xsl:attribute name="srcpath" select="concat(., ';n=', index-of($same-path-items, generate-id(..)))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="srcpath" select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Solve a situation like this:
   <idml2xml:parsep/>
   <idml2xml:genPara>
      <idml2xml:genAnchor/>
   </idml2xml:genPara>
   <idml2xml:link>
      <idml2xml:ParagraphStyleRange>
         <idml2xml:genPara>
         …
   The first idml2xml:genPara is not a para in its own right. Its content belongs to the beginning 
   of the subsequent idml2xml:genPara, if there is such.
  -->

  <xsl:template match="*[idml2xml:parsep]" mode="idml2xml:AutoCorrect-clean-up">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="*" group-starting-with="idml2xml:parsep">
        <xsl:choose>
          <xsl:when test="self::idml2xml:parsep">
            <xsl:if test="(count(current-group()[self::idml2xml:genPara]) gt 1
                           ) and
                           current-group()[idml2xml:is-dissolvable-anchor-genPara(.)]">
             
              
              <xsl:message select="'AutoCorrect-clean-up: More than one para: ' , current-group()[last()]"/>
              <xsl:comment>❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧ unhandled!!!, <xsl:value-of select="count(current-group()[not(self::idml2xml:parsep)]
                                               [not(idml2xml:is-dissolvable-anchor-genPara(.))]
                                )"/>
              </xsl:comment>
              <xsl:comment>
                <xsl:for-each select="current-group()">
                  <xsl:sequence select="name(.)"/>
                </xsl:for-each>
              </xsl:comment>
              <!-- this case wasn't thought of and has to be handled! -->
            </xsl:if>
            <xsl:apply-templates select="current-group()[not(idml2xml:is-dissolvable-anchor-genPara(.))]"
              mode="#current">
              <xsl:with-param name="insert-anchor" select="current-group()[idml2xml:is-dissolvable-anchor-genPara(.)]/*" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[@aid:pstyle]" mode="idml2xml:AutoCorrect-clean-up" priority="5">
    <xsl:param name="insert-anchor" as="element(idml2xml:genAnchor)*" tunnel="yes"/>
    <xsl:choose>
      <xsl:when test="exists($insert-anchor)">
        <xsl:copy>
          <xsl:apply-templates select="@*,
                                       $insert-anchor,
                                       node()" mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="idml2xml:genPara[idml2xml:is-dissolvable-anchor-genPara(.)]"
    mode="idml2xml:AutoCorrect-clean-up"/>
  
  <xsl:function name="idml2xml:is-dissolvable-anchor-genPara" as="xs:boolean">
    <xsl:param name="para" as="element(*)?"/>
    <xsl:sequence select="exists($para/preceding-sibling::*[1]/self::idml2xml:parsep)
                          and
                          exists($para/idml2xml:genAnchor)
                          and
                          (every $child in $para/* satisfies ($child/self::idml2xml:genAnchor))"/>
  </xsl:function>
  
</xsl:stylesheet>