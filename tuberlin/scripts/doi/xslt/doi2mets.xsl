<?xml version="1.0" encoding="utf-8"?>
<!--
 (c) 2018 Technische Universität Berlin

 This software is licensed under GNU General Public License version 3 or later.

 For the full copyright and license information,
 please see https://www.gnu.org/licenses/gpl-3.0.html or read
 the LICENSE.txt file that was distributed with this source code.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mets="http://www.loc.gov/METS/"
                xmlns:mods="http://www.loc.gov/mods/v3"
                xmlns:goobi="http://meta.goobi.org/v1.5.1/">

    <xsl:import href="doiTemplates.xsl"/>

    <xsl:output method="xml" omit-xml-declaration="no" standalone="no" indent="yes" encoding="utf-8"/>

    <xsl:param name="doi"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>

    <!-- Since XSLT 1.0 doesn't allow variables in template matching, we have to use a workaround with two templates -->
    <xsl:template match="mets:dmdSec[@ID='DMDLOG_0000']/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi">
        <goobi:goobi>
            <xsl:copy-of select="./*"/>
            <xsl:if test="not(goobi:metadata[@name='_doi']) and $dmdsec_id = 'DMDLOG_0000'">
                <goobi:metadata name="DOI"><xsl:value-of select="$doi"/></goobi:metadata>
            </xsl:if>
        </goobi:goobi>
    </xsl:template>

    <xsl:template match="mets:dmdSec[@ID='DMDLOG_0001']/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi">
        <goobi:goobi>
            <xsl:copy-of select="./*"/>
            <xsl:if test="not(goobi:metadata[@name='_doi']) and $dmdsec_id = 'DMDLOG_0001'">
                <goobi:metadata name="DOI"><xsl:value-of select="$doi"/></goobi:metadata>
            </xsl:if>
        </goobi:goobi>
    </xsl:template>

</xsl:stylesheet>
