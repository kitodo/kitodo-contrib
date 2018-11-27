<?xml version="1.0" encoding="utf-8"?>
<!--
 (c) 2018 Technische Universität Berlin

 This software is licensed under GNU General Public License version 3 or later.

 For the full copyright and license information,
 please see https://www.gnu.org/licenses/gpl-3.0.html or read
 the LICENSE.txt file that was distributed with this source code.
-->
<!--
    This stylesheet maps a METS/MODS file using the internal Kitodo metadata format goobi:metadata
    to a datacite metadata schema 4.1.
    See https://schema.datacite.org/meta/kernel-4.1/
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mets="http://www.loc.gov/METS/"
                xmlns:mods="http://www.loc.gov/mods/v3"
                xmlns:goobi="http://meta.goobi.org/v1.5.1/">

    <xsl:import href="doiTemplates.xsl"/>

    <xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="utf-8"/>

    <xsl:param name="doi"/>
    <xsl:param name="year"/>

    <xsl:template match="/">
        <resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xmlns="http://datacite.org/schema/kernel-4"
                  xsi:schemaLocation="http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4.1/metadata.xsd">

            <!-- Mandatory fields -->

            <identifier identifierType="DOI"><xsl:value-of select="$doi"/></identifier>

            <creators>
                <xsl:choose>
                    <!--
                        Default, if there are no known creators: machine readable value (:unav)
                        ("value unavailable, possibly unknown")
                    -->
                    <xsl:when test="not(//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Author'])
                                    and not(//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Creator'])
                                    and not(//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='WriterCorporate'])">
                        <creator>
                            <creatorName>(:unav)</creatorName>
                        </creator>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Author' or @name='Creator']">
                            <creator>
                                <creatorName nameType="Personal"><xsl:value-of select="goobi:displayName"/></creatorName>
                                <xsl:if test="goobi:firstName">
                                    <givenName><xsl:value-of select="goobi:firstName"/></givenName>
                                </xsl:if>
                                <xsl:if test="goobi:lastName">
                                    <familyName><xsl:value-of select="goobi:lastName"/></familyName>
                                </xsl:if>
                            </creator>
                        </xsl:for-each>
                        <xsl:for-each select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='WriterCorporate']">
                            <creator>
                                <creatorName nameType="Organizational"><xsl:value-of select="."/></creatorName>
                            </creator>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </creators>

            <!--
                According to DataCite recommendations, "The Title field may be used to convey the approximate or
                known date of the original object."
                Thus, if there is a PublicationYear, we add it to the title.
                The PublicationYear may for this purpose also be approximate, i.e. contain brackets etc.

                If there is no title, we use the machine readable property (:unas) "value unassigned (e.g., Untitled)"
            -->
            <xsl:variable name="pubyear">
                <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='PublicationYear']"/>
            </xsl:variable>
            <titles>
                <title>
                    <xsl:choose>
                        <xsl:when test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='TitleDocMain']">
                            <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='TitleDocMain']"/>
                            <xsl:if test="$pubyear != ''">
                                <xsl:text>; </xsl:text>
                                <xsl:value-of select="$pubyear"/>
                            </xsl:if>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>(:unas)</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </title>
            </titles>

            <!--
                The publisher should be the institute responsible for the digital publication,
                not the publisher of the original work.

                If the value is not set, (:unav) "value unavailable, possibly unknown" will be used.
            -->
            <publisher>
                <xsl:choose>
                    <xsl:when test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='_electronicPublisher']">
                        <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='_electronicPublisher']"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>(:unav)</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </publisher>

            <!--
                DataCite: "If the DOI is being used to identify a digitised version of an original item, the
                recommended approach is to supply the PublicationYear for the digital version and not the original
                object."
                If _dateDigitazition ist set, use it. Otherwise insert the current year.
                Since xsl 1.0 cannot create current date, we have to set the current year as a parameter.
            -->
            <xsl:variable name="digit_date">
                <xsl:call-template name="getYear">
                    <xsl:with-param name="date">
                        <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='_dateDigitization']"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:variable>

            <publicationYear>
                <xsl:choose>
                    <xsl:when test="$digit_date != ''">
                        <xsl:value-of select="$digit_date"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$year"/>
                    </xsl:otherwise>
                </xsl:choose>
            </publicationYear>

            <!--
                resourceTypeGeneral ist one of following values (https://schema.datacite.org/meta/kernel-4.1/include/datacite-resourceType-v4.1.xsd):
                    Audiovisual
                    Collection
                    DataPaper
                    Dataset
                    Event
                    Image
                    InteractiveResource
                    Model
                    PhysicalObject
                    Service
                    Software
                    Sound
                    Text
                    Workflow
                    Other
                Unfortunately, there seem to exist no standard for mapping digitized objects to these types.
                Here the (special) resourceType is taken directly from the type attribute in the METS logical structMap.
                The resourceTypeGeneral may be set using the mapping table below.
            -->
            <xsl:variable name="resourceType">
                <xsl:value-of select="//mets:structMap[@TYPE='LOGICAL']/mets:div[@ID='LOG_0000']/@TYPE"/>
            </xsl:variable>
            <xsl:variable name="resourceTypeGeneral">
                <xsl:choose>
                    <xsl:when test="contains('Monograph;Article;PeriodicalPart;Paper;Leaflet', $resourceType)">Text</xsl:when>
                    <xsl:when test="contains('Plan;Design;Map', $resourceType)">Image</xsl:when>
                    <xsl:otherwise>Other</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <resourceType>
                <xsl:attribute name="resourceTypeGeneral"><xsl:value-of select="$resourceTypeGeneral"/></xsl:attribute>
                <xsl:value-of select="$resourceType"/>
            </resourceType>


            <!-- Recommended fields -->

            <!--
                Contributor: "The institution or person responsible for collecting, managing, distributing, or
                otherwise contributing to the development of the resource."
            -->
            <xsl:if test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='_electronicPublisher']">
                <contributors>
                    <contributor contributorType="HostingInstitution">
                        <contributorName>
                            <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='_electronicPublisher']"/>
                        </contributorName>
                    </contributor>
                </contributors>
            </xsl:if>

            <!-- Original publication year: date issued -->
            <xsl:variable name="dateIssued">
                <xsl:call-template name="getYear">
                    <xsl:with-param name="date">
                        <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='PublicationYear']"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:variable>

            <xsl:if test="$dateIssued != ''" >
                <dates>
                    <date dateType="Issued">
                        <xsl:value-of select="$dateIssued"/>
                    </date>
                </dates>
            </xsl:if>

            <!-- Abstract -->
            <xsl:if test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Abstract']">
                <descriptions>
                    <description descriptionType="Abstract">
                        <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Abstract']"/>
                    </description>
                </descriptions>
            </xsl:if>

            <!-- Subjects (Keywords) -->
            <xsl:if test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Keyword']">
                <subjects>
                    <xsl:for-each select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Keyword']">
                        <subject>
                            <xsl:value-of select="."/>
                        </subject>
                    </xsl:for-each>
                </subjects>
            </xsl:if>


            <!-- Optional fields -->

            <!-- Language of the publication -->
            <xsl:if test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='DocLanguage']">
                <language>
                    <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='DocLanguage']"/>
                </language>
            </xsl:if>

            <!-- Size -->
            <xsl:if test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Format']">
                <sizes>
                    <size>
                        <xsl:value-of select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='Format']"/>
                    </size>
                </sizes>
            </xsl:if>

            <!-- Rights / licenses -->
            <xsl:if test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='UseAndReproductionLicense']">
                <rightsList>
                    <xsl:for-each select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='UseAndReproductionLicense']">
                        <rights>
                            <!--
                                if the license starts with http, we put it in the rightsURL attribute,
                                otherwise it should be a text element.
                            -->
                            <xsl:choose>
                                <xsl:when test="starts-with(., 'http')">
                                    <xsl:attribute name="rightsURI">
                                        <xsl:value-of select="."/>
                                    </xsl:attribute>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </rights>
                    </xsl:for-each>
                </rightsList>
            </xsl:if>

            <!-- funding -->
            <xsl:if test="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='FundingReference']">
                <fundingReferences>
                    <xsl:for-each select="//mets:dmdSec[@ID=$dmdsec_id]/mets:mdWrap/mets:xmlData/mods:mods/mods:extension/goobi:goobi/goobi:metadata[@name='FundingReference']">
                        <fundingReference>
                            <funderName><xsl:value-of select="."/></funderName>
                        </fundingReference>
                    </xsl:for-each>
                </fundingReferences>
            </xsl:if>

        </resource>

    </xsl:template>

    <xsl:template name="getYear">
        <xsl:param name="date"/>
        <xsl:choose>
            <xsl:when test="starts-with($date, '[') and string-length($date) >= 5 and number(substring($date, 2, 4)) = substring($date, 2, 4)">
                <xsl:value-of select="substring($date, 2, 4)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="string-length($date) >= 4 and number(substring($date, 1, 4)) = substring($date, 1, 4)" >
                    <xsl:value-of select="substring($date, 1, 4)"/>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
