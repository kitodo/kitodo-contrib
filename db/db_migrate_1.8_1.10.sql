/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;

alter table benutzer
	add column ldaplogin VARCHAR(255);

create table dockets (
	docketID INT(11) not null auto_increment,
	name VARCHAR(255),
	file VARCHAR(255),
	primary key (docketID)
);

insert into dockets
	(docketID, name, file) values (1, 'default', 'docket.xsl');

alter table projectfilegroups
	add column folder VARCHAR(255);

alter table projekte
	add column projectIsArchived BIT default false;

update projekte
	set projectIsArchived = false;

alter table prozesse
	modify wikifield TEXT,
	add column batchID INT(11),
	add column docketID INT(11),
	add index docket (docketID ASC),
	add index batch (batchID ASC);

update prozesse
	set docketID=1;

alter table schritte
	add column batchStep BIT default false,
	add column stepPlugin VARCHAR(255),
	add column validatorPlugin VARCHAR(255);


/* Move records from table schritteeigenschaften to table prozesseeigenschaften */
insert into prozesseeigenschaften
	(Titel, Wert, IstObligatorisch, DatentypenID, Auswahl, creationDate,container,prozesseID)
select
	se.Titel,
	se.Wert,
	se.IstObligatorisch,
	se.DatentypenID,
	se.Auswahl,
	se.creationDate,
	se.container,
	s.ProzesseID
from
	schritteeigenschaften se, schritte s
where se.SchritteID = s.SchritteID;

truncate schritteeigenschaften;

/*!40101 SET character_set_client = @saved_cs_client */;
