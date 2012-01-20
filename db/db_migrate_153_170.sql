/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;

-- NOTE: remove comment hyphens only if these tables are empty

--drop table metadatenkonfigurationen;
--drop table projekte;

alter table MetadatenKonfigurationen rename to metadatenkonfigurationen;
alter table Projekte rename to projekte;

alter table prozesse modify IstTemplate BIT;

alter table prozesseeigenschaften modify Wert varchar(255);
alter table prozesseeigenschaften modify IstObligatorisch BIT;
alter table prozesseeigenschaften modify Auswahl VARCHAR(255);

alter table schritteeigenschaften modify Wert VARCHAR(255);
alter table schritteeigenschaften modify IstObligatorisch BIT;
alter table schritteeigenschaften modify Auswahl varchar(255);

alter table vorlageneigenschaften modify Wert varchar(255);
alter table vorlageneigenschaften modify IstObligatorisch BIT;
alter table vorlageneigenschaften modify Auswahl varchar(255);

alter table werkstueckeeigenschaften modify Wert varchar(255);
alter table werkstueckeeigenschaften modify IstObligatorisch bit;
alter table werkstueckeeigenschaften modify Auswahl varchar(255);

CREATE TABLE `benutzereigenschaften` (
  `benutzereigenschaftenID` int(11) NOT NULL AUTO_INCREMENT,
  `Titel` varchar(255) DEFAULT NULL,
  `Wert` varchar(255) DEFAULT NULL,
  `IstObligatorisch` bit(1) DEFAULT NULL,
  `DatentypenID` int(11) DEFAULT NULL,
  `Auswahl` varchar(255) DEFAULT NULL,
  `creationDate` datetime DEFAULT NULL,
  `BenutzerID` int(11) DEFAULT NULL,
  PRIMARY KEY (`benutzereigenschaftenID`),
  KEY `FK963DAE0F8896477B` (`BenutzerID`),
  KEY `FK963DAE0FC44F7B5B` (`BenutzerID`)
);
/*!40101 SET character_set_client = @saved_cs_client */;
