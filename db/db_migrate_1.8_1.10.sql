/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;

alter table benutzer
	add column ldaplogin VARCHAR(255) null default null;

create table dockets (
	docketID INT(11) not null auto_increment,
	name VARCHAR(255) default null,
	file VARCHAR(255) default null,
	primary key (docketID)
);

insert into dockets
	(docketID, name, file) values (1, 'default', 'docket.xsl');

alter table projectfilegroups
	add column folder VARCHAR(255) null default null;

alter table projekte
	add column projectIsArchived BIT null default false;

update projekte
	set projectIsArchived = false;

alter alter table prozesse
	modify wikifield TEXT null default null,
	add column batchID INT(11) null,
	add column docketID INT(11) null,
	add index docket (docketID ASC),
	add index batch (batchID ASC);

update prozesse
	set docketID=1;

alter table schritte
	add column batchStep BIT null default false,
	add column stepPlugin VARCHAR(255) null default null,
	add column validatorPlugin VARCHAR(255) null default null;


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
where se.SchritteID = s.SchritteID

truncate schritteeigenschaften;

/*!40101 SET character_set_client = @saved_cs_client */;
