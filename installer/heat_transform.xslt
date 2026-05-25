<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:wix="http://wixtoolset.org/schemas/v4/wxs">

  <!-- Identity transform -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Remove the main executable from harvested files (we handle it separately) -->
  <xsl:template match="wix:Component[wix:File/@Id='gyawun.exe']" />
  <xsl:template match="wix:ComponentRef[@Id='gyawun.exe']" />

</xsl:stylesheet>
