/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;

ALTER TABLE `benutzer`
    ADD COLUMN `ldaplogin` VARCHAR(255);

CREATE TABLE `dockets` (
	`docketID` INT(11) NOT NULL auto_increment,
	`name` VARCHAR(255),
	`file` VARCHAR(255),
	PRIMARY KEY (`docketID`)
) ENGINE=MyISAM;

INSERT INTO `dockets` (`docketID`, `name`, `file`)
    VALUES (1, 'default', 'docket.xsl');

ALTER TABLE `projectfilegroups`
    ADD COLUMN `folder` VARCHAR(255);

ALTER TABLE `projekte`
    ADD COLUMN `projectIsArchived` BIT DEFAULT false;

ALTER TABLE `prozesse`
	MODIFY `wikifield` LONGTEXT,
	ADD COLUMN `batchID` INT(11),
	ADD COLUMN `docketID` INT(11);

UPDATE `prozesse` SET `docketID` = 1;

ALTER TABLE `schritte`
	ADD COLUMN `batchStep` BIT DEFAULT false,
	ADD COLUMN `stepPlugin` VARCHAR(255),
	ADD COLUMN `validationPlugin` VARCHAR(255);

ALTER TABLE `prozesseeigenschaften`
    MODIFY `Wert` LONGTEXT;

/* Move records from table `schritteeigenschaften` to table `prozesseeigenschaften` */
INSERT INTO `prozesseeigenschaften`
    (`Titel`, `Wert`, `IstObligatorisch`, `DatentypenID`, `Auswahl`, `creationDate`, `container`, `prozesseID`)
    SELECT
        se.`Titel`,
        se.`Wert`,
        se.`IstObligatorisch`,
        se.`DatentypenID`,
        se.`Auswahl`,
        se.`creationDate`,
        se.`container`,
        s.`ProzesseID`
    FROM
        `schritteeigenschaften` se, `schritte` s
    WHERE se.`SchritteID` = s.`SchritteID`;

TRUNCATE `schritteeigenschaften`;

/*!40101 SET character_set_client = @saved_cs_client */;

