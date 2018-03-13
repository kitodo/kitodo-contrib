<?xml version="1.0" encoding="utf-8"?>
<!--
 (c) 2018 Technische Universität Berlin

 This software is licensed under GNU General Public License version 3 or later.

 For the full copyright and license information,
 please see https://www.gnu.org/licenses/gpl-3.0.html or read
 the LICENSE.txt file that was distributed with this source code.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mets="http://www.loc.gov/METS/">

    <!-- Find out the dmdSec ID for the general metadata, default: DMDLOG_0000 -->
    <xsl:variable name="dmdsec_id">
        <xsl:choose>
            <xsl:when test="/mets:mets/mets:structMap[@TYPE='LOGICAL']/mets:div/@DMDID">
                <xsl:value-of select="/mets:mets/mets:structMap[@TYPE='LOGICAL']/mets:div/@DMDID"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="/mets:mets/mets:structMap[@TYPE='LOGICAL']/mets:div/mets:div/@DMDID">
                        <xsl:value-of select="/mets:mets/mets:structMap[@TYPE='LOGICAL']/mets:div/mets:div/@DMDID"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>DMDLOG_0000</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

</xsl:stylesheet>
