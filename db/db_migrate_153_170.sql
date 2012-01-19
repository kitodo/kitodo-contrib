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

