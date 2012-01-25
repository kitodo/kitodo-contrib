/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;

/* NOTE CAUTION! This script might remove tables and columns that contain data. */
/* NOTE: Remove commenting only if these tables are empty! */
drop table metadatenkonfigurationen;
drop table projekte;

alter table MetadatenKonfigurationen
	rename to metadatenkonfigurationen;

alter table Projekte
	rename to projekte,
	add column startDate datetime default null,
	add column endDate datetime default null,
	add column numberOfPages int(11) default null,
	add column numberOfVolumes int(11) default null;

alter table benutzer
	modify BenutzerID int(11) not null auto_increment,
	modify IstAktiv bit(1) default null,
	change Login login varchar(255) default null,
	change Passwort passwort varchar(255) default null,
	modify confVorgangsdatumAnzeigen bit(1) default null,
	modify mitMassendownload bit(1) default null,
	drop column zugriffSamba,
	drop zugriffWebdav;

alter table benutzergruppen
	change BenutzerGruppenID BenutzergruppenID int(11) not null auto_increment,
	change Berechtigung berechtigung int(11) default null,
	change Titel titel varchar(255) default null;

alter table benutzergruppenmitgliedschaft
	drop BenutzerGruppenMitgliedschaftID,
	modify BenutzerID int(11) not null,
	modify BenutzerGruppenID int(11);

delete from benutzergruppenmitgliedschaft
	where BenutzerID in
		(select BenutzerID from (select BenutzerID from benutzergruppenmitgliedschaft group by BenutzerID having count(BenutzerGruppenID) > 1) subsubquery);

alter table benutzergruppenmitgliedschaft
	add primary key (BenutzerID,BenutzerGruppenID);

drop table datentypen;

alter table ldapgruppen
	drop column usesShell,
	drop column homeDir,
	drop column guid;

alter table prozesse
	drop column EigenschaftenID,
	modify IstTemplate bit(1) default null,
	modify inAuswahllisteAnzeigen bit(1) default null,
	add column wikifield varchar(255);

alter table prozesseeigenschaften
	modify prozesseeigenschaftenID int(11) not null auto_increment,
	modify prozesseID int(11) default null,
	modify Wert varchar(255) default null,
	modify IstObligatorisch bit(1) default null,
	modify DatentypenID int(11) default null,
	modify Auswahl VARCHAR(255) default null,
	add column creationDate datetime default null,
	add column container int(11) default null,
	drop key DatentypenID;

alter table schritte
	modify Bearbeitungsstatus int(11) default null,
	modify Prioritaet int(11) default null,
	modify ProzesseID int(11) default null,
	modify Reihenfolge int(11) default null,
	modify SchritteID int(11) not null auto_increment,
	modify typAutomatisch bit(1) default null,
	modify typBeimAnnehmenAbschliessen bit(1) default null,
	modify typBeimAnnehmenModulUndAbschliessen bit(1) default null,
	modify typBeimAnnehmenModul bit(1) default null,
	modify typExportDMS bit(1) default null,
	modify typExportRus bit(1) default null,
	modify typImagesSchreiben bit(1) default null,
	modify typImportFileUpload bit(1) default null,
	modify typMetadaten bit(1) default null,
	drop column beimAnnehmenAbschliessen,
	drop column beimAnnehmenModulUndAbschliessen,
	drop column beimAnnehmenModul,
	drop column Typ,
	drop column EigenschaftenID;

alter table schritteberechtigtebenutzer
	modify schritteID int(11) not null,
	modify BenutzerID int(11) not null,
	drop column schritteberechtigtebenutzerID,
	add primary key (schritteID, BenutzerID);

alter table schritteberechtigtegruppen
	modify schritteID int(11) not null,
	modify BenutzerGruppenID int(11) not null,
	drop column schritteberechtigtegruppenID,
	add primary key (schritteID, BenutzerGruppenID);

alter table schritteeigenschaften
	modify Auswahl varchar(255) default null,
	modify DatentypenID int(11) default null,
	modify IstObligatorisch bit(1) default null,
	modify Wert VARCHAR(255),
	modify schritteID int(11) default null,
	modify schritteeigenschaftenID int(11) not null auto_increment,
	add column container int(11) default null;

alter table vorlagen
	modify ProzesseID int(11) default null,
	modify VorlagenID int(11) not null auto_increment,
	drop column EigenschaftenID;

alter table vorlageneigenschaften
	modify Auswahl varchar(255) default null,
	modify DatentypenID int(11) default null,
	modify IstObligatorisch bit(1) default null,
	modify Wert varchar(255),
	modify vorlagenID int(11) default null,
	modify vorlageneigenschaftenID int(11) not null auto_increment,
	add column container int(11) default null,
	add column creationDate datetime default null;

alter table werkstuecke
	modify ProzesseID int(11) default null,
	modify WerkstueckeID int(11) not null auto_increment,
	drop column EigenschaftenID;

alter table werkstueckeeigenschaften
	modify Auswahl varchar(255) default null,
	modify DatentypenID int(11) default null,
	modify IstObligatorisch bit(1) default null,
	modify Wert varchar(255),
	modify werkstueckeID int(11) default null,
	modify werkstueckeeigenschaftenID int(11) not null auto_increment,
	add column container int(11) default null,
	add column creationDate datetime default null;

create table benutzereigenschaften (
  benutzereigenschaftenID int(11) not null auto_increment,
  Titel varchar(255) default null,
  Wert varchar(255) default null,
  IstObligatorisch bit(1) default null,
  DatentypenID int(11) default null,
  Auswahl varchar(255) default null,
  creationDate datetime default null,
  BenutzerID int(11) default null,
  primary key (benutzereigenschaftenID),
  key (BenutzerID)
);
/*!40101 SET character_set_client = @saved_cs_client */;
