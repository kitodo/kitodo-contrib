#!/opt/ActivePerl-5.16/bin/perl
# -*- coding: utf-8 -*-
#~ This program is free software: you can redistribute it and/or modify
#~ it under the terms of the GNU General Public License as published by
#~ the Free Software Foundation, either version 3 of the License, or
#~ (at your option) any later version.

#~ This program is distributed in the hope that it will be useful,
#~ but WITHOUT ANY WARRANTY; without even the implied warranty of
#~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#~ GNU General Public License for more details.

#~ You should have received a copy of the GNU General Public License
#~ along with this program.  If not, see <http://www.gnu.org/licenses/>.

#~ Dieses Programm ist Freie Software: Sie können es unter den Bedingungen
#~ der GNU General Public License, wie von der Free Software Foundation,
#~ Version 3 der Lizenz oder (nach Ihrer Wahl) jeder neueren
#~ veröffentlichten Version, weiterverbreiten und/oder modifizieren.

#~ Dieses Programm wird in der Hoffnung, dass es nützlich sein wird, aber
#~ OHNE JEDE GEWÄHRLEISTUNG, bereitgestellt; sogar ohne die implizite
#~ Gewährleistung der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK.
#~ Siehe die GNU General Public License für weitere Details.

#~ Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
#~ Programm erhalten haben. Wenn nicht, siehe <http://www.gnu.org/licenses/>.
	
#~ @Autor Armin Möller   armin.moeller@sbb.skp-berlin.de

use feature ":5.10";
use strict;
use utf8;
binmode STDOUT,":utf8";
use CGI qw/:all :standard *table *Tr *td *div *span -utf8/;
use inifile;
use HTML::Entities;
use Time::Local 'timelocal_nocheck';
use DBI;
use DBD::Oracle qw(:ora_types);
use Encode;
use strict;
use vars qw/ $dbh $ini /;
use Data::Dumper;
use IO::Handle;
STDERR->autoflush(1);
STDOUT->autoflush(1);
my ($adr, $gradr,  $p1);
my $debug = 0;
$ini = inifile->new("goobi.ini",'array');
# -*- coding: utf-8 -*-
#Programm einchecken


#### colourchecker dazu


use feature ":5.10";
use strict;
use XML::LibXML;
use HTML::Entities();
use utf8;
use File::Copy;
use Cwd;



my $parser = XML::LibXML->new();
my $count;
my @id;
my $res;
my $ldir = cwd();

chdir ini("werkbank");

my $template = <<eot;
<?xml version="1.0" encoding="UTF-8"?>
<!-- This METS file was created on Thu Aug 11 15:01:44 CEST 2011 using the UGH Metadata Library: ugh.fileformats.mets.MetsMods (version 1.9-20100505) -->
<mets:mets xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd http://www.loc.gov/METS/ http://www.loc.gov/standards/mets/version17/mets.v1-7.xsd" xmlns:mets="http://www.loc.gov/METS/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<mets:fileSec>
		<mets:fileGrp USE="LOCAL">
		</mets:fileGrp>
	</mets:fileSec>
	<mets:structMap TYPE="LOGICAL">
	</mets:structMap>
	<mets:structMap TYPE="PHYSICAL">
		<mets:div DMDID="DMDPHYS_0000" ID="PHYS_0000" TYPE="BoundBook"/>
	</mets:structMap>
	<mets:structLink>
	</mets:structLink>
</mets:mets>
eot

#~ $template =~ s/[\t\r\n]+//g;
my $tmp = $parser->parse_string($template);

my @defs = (
	{typ => 'node', name=>"mets", xpath=>"//mets:mets",},
	{typ => 'node', name=>"dmdSec", xpath=>"/mets:mets/mets:fileSec",},
	{typ => 'node', name=>"local", xpath=>"//mets:fileGrp[\@USE='LOCAL']",},
	{typ => 'node', name=>"logical", xpath=>"//mets:structMap[\@TYPE='LOGICAL']",},
	{typ => 'node', name=>"physical", xpath=>"//mets:structMap[\@TYPE='PHYSICAL']/mets:div",},
	{typ => 'node', name=>"structlink", xpath=>"//mets:structLink",},
);

my @defs_a = (
	{typ => 'data', name=>"pagestart", xpath=>"//AGORA:ImageSetPageStart/text()",},
	{typ => 'data', name=>"pageend", xpath=>"//AGORA:ImageSetPageEnd/text()",},
	{typ => 'data', name=>"path", xpath=>"/RDF:RDF/AGORA:ImageSet//AGORA:PathImagefiles/text()",},
	{typ => 'node', name=>"sequencespagination", xpath=>"/RDF:RDF/AGORA:ImageSet/AGORA:SequencesPagination/RDF:Seq",},
	{typ => 'node', name=>"topstrukt", xpath=>"/RDF:RDF/AGORA:DocStrct",},
	{typ => 'node', name=>"ImageSet", xpath=>"/RDF:RDF/AGORA:ImageSet",},
);
my @defs_ss = (
	{typ => 'data', name=>"pagephysstart", xpath=>".//AGORA:PagePhysStart/text()",},
	{typ => 'data', name=>"pagephysend", xpath=>".//AGORA:PagePhysEnd/text()",},
	{typ => 'data', name=>"pageaccountedstart", xpath=>".//AGORA:PageAccountedStart/text()",},
	{typ => 'data', name=>"pageaccountedend", xpath=>".//AGORA:PageAccountedEnd/text()",},
	{typ => 'data', name=>"pagenotaccountedstart", xpath=>".//AGORA:PageNotAccountedStart/text()",},
	{typ => 'data', name=>"pagenotaccountedend", xpath=>".//AGORA:PageNotAccountedEnd/text()",},
);
my %md_trans = (
	ShelfmarkSource => "shelfmarksource",
	ShortCutDoc => "TSL_ATS",
	TitleDocSub1 => "TitleDocSub",
);
my %mutation = ( 
	OtherDocStrct => {
		Beiträger =>			{ typ =>"Other", dmd => 1, },
		Buchschmuck =>		{ typ =>"Ornament", dmd => 0, },
		Druckermarke =>		{ typ =>"PrintersMark", dmd => 0, },
		Errata =>				{ typ =>"Corrigenda", dmd => 0, },
		"Errata." =>		{ typ =>"Corrigenda", dmd => 0, },
		Exlibris =>				{ typ =>"Binding / PasteDown / Bookplate", dmd => 0, },
		"Handschriftliche Anmerkungen" => { typ =>"Annotation", dmd => 0, },
		"Handschriftliches Inhaltsverzeichnis"=> { typ =>"Contents", dmd => 1, },
		Kolophon => 			{ typ =>"Colophon", dmd => 0, },
		Kupfertitel =>			{ typ =>"EngravedTitlepage", dmd => 0, },
		Rückdeckel => 		{ typ =>"Binding / CoverBack", dmd => 0, },
		Spiegel =>				{ typ =>"Binding / PasteDown", dmd => 0, },
		Titelblatt => 			{ typ =>"TitlePage", dmd => 0, },
		Vorderdeckel => 		{ typ =>"Binding / CoverFront", dmd => 0, },
		Vorsatz =>				{ typ =>"Binding / Endsheet", dmd => 0, },
		default => 			{ typ =>"Section", dmd => 0, },
	},
	Acknowledgment => 	{ only => { typ => "Section", dmd => 1, },},
	Addendum => 			{ only => { typ => "Additional", dmd => 1, },},
	Appendix => 				{ only => { typ => "Section", dmd => 1, },},
	Cover => 					{ only => { typ => "Binding", dmd => 1, },},
	Epilogue => 				{ only => { typ => "Section", dmd => 1, },},
	Errata => 					{ only => { typ => "Corrigenda", dmd => 1, },},
	Figure => 					{ only => { typ => "Illustration", dmd => 1, },},
	IndexAuthor => 			{ only => { typ => "Index", dmd => 1, },},
	IndexOfChronology => 	{ only => { typ => "Index", dmd => 1, },},
	IndexOverall => 			{ only => { typ => "Index", dmd => 1, },},
	IndexPersons => 		{ only => { typ => "Index", dmd => 1, },},
	IndexSpecial => 			{ only => { typ => "Index", dmd => 1, },},
	IndexSubject => 		{ only => { typ => "Index", dmd => 1, },},
	Introduction => 			{ only => { typ => "Section", dmd => 1, },},
	Letter => 					{ only => { typ => "Section", dmd => 1, },},
	ListOfIllustrations => 	{ only => { typ => "Index", dmd => 1, },},
	Obituary => 				{ only => { typ => "CurriculumVitae", dmd => 1, },},
	Prepage => 				{ only => { typ => "Binding / Endsheet", dmd => 1, },},
	Remarks => 				{ only => { typ => "Section", dmd => 1, },},
	SheetMusic => 			{ only => { typ => "MusicalNotation", dmd => 1, },},
	Supplement => 			{ only => { typ => "Section", dmd => 1, },},
	Table => 					{ only => { typ => "Table", dmd => 1, },},
	TableOfAbbreviations => { only => { typ => "Table", dmd => 1, },},
	TableOfContents => 	{ only => { typ => "Contents", dmd => 1, },},
	TableOfLiteratureRefs => { only => { typ => "Table", dmd => 1, },},
	WorkAttached => 		{ only => { typ => "ContainedWork", dmd => 1, },},
);
my %id;

my %vars;
my %structlink;
my $obj;
#~ opendir my $META ,"." or die "cant open dir .";
#~ while(my $dir = readdir($META)){
#~ for my $dir ( qw/736/){
for my $dir ( qw/667/){
#~ for my $dir ( qw/5067/){
	%id = (
		dmdlog => 0,
		log => 0,
		phys => 0,
		
	);
	%structlink = undef;
	my $change;
	my %para;
	my $ret = $tmp->cloneNode(1);
	next if $dir =~ /^\./;
	next if !-d $dir or !-f "$dir/meta.xml";
	$obj = $parser->parse_file("$dir/meta.xml");
	next if ! $obj->findnodes('//*[name()="RDF:RDF"]');
	for my $def ( @defs ) {
		if( $def->{typ} eq 'node' ) {
			$vars{$def->{name}} = shift @{$ret->findnodes($def->{xpath})};
		} elsif ( $def->{typ} eq 'data' ) {
			my $t = shift @{$ret->findnodes($def->{xpath})};
			$vars{$def->{name}} = $t->data;
		} else {
			die "falscher Typ ".$def->{typ};
		}
	}
	for my $def ( @defs_a ) {
		if( $def->{typ} eq 'node' ) {
			$para{$def->{name}} = shift @{$obj->findnodes($def->{xpath})};
		} elsif ( $def->{typ} eq 'data' ) {
			my $t = shift @{$obj->findnodes($def->{xpath})};
			$para{$def->{name}} = $t->data;
		} else {
			die "falscher Typ ".$def->{typ};
		}
	}
	struk(docstrukt => $para{topstrukt},logical=>$vars{logical}, metadata => {SeriesTitleDigital=>["Preußen 17 digital - Digitalisierung des im VD 17 nachgewiesenen Bestandes preußischer Drucke der Staatsbibliothek zu Berlin"]});
	file(local=>$vars{local},von=>$para{pagestart},bis=>$para{pageend},path=>$para{path});
	mkstructlink(hash => \%structlink, structlink => $vars{structlink});
	physical(sequencespagination => $para{sequencespagination}, physical => $vars{physical},von=>$para{pagestart},bis=>$para{pageend},);
	$vars{mets}->insertBefore(dmdsec(id => "DMDPHYS_0000", data => {copyrightimageset=>"Staatsbibliothek zu Berlin - Preußischer Kulturbesitz",PhysicalLocation=>"SBB Berlin",pathimagefiles=>$para{path}}),$vars{dmdSec});
	last if $count++ > 20;
	$ret->toFile("$ldir/bla.xml");
	#~ say("$ldir/bla.xml");
}

sub physical {
	my %para = (
		sequencespagination => undef,
		physical => undef,
		von => undef,
		bis => undef,
		@_
	);
	my %phys;
	for my $node ( $para{sequencespagination}->childNodes() ) {
		my %sec;
		for my $def ( @defs_ss ) {
			if( $def->{typ} eq 'node' ) {
				$sec{$def->{name}} = shift @{$node->findnodes($def->{xpath})};
			} elsif ( $def->{typ} eq 'data' ) {
				my $t = shift @{$node->findnodes($def->{xpath})};
				$sec{$def->{name}} = $t->data;
			} else {
				die "falscher Typ ".$def->{typ};
			}
		}
		if( $sec{pageaccountedstart} > 0 ) {
			my $count = $sec{pageaccountedstart};
			for my $i (  $sec{pagephysstart} ..  $sec{pagephysend} ) {
				$phys{$i} = $count++;
			}
		} elsif( $sec{pagenotaccountedstart} > 0 ) {
			my $count = $sec{pageaccountedstart};
			for my $i (  $sec{pagephysstart} ..  $sec{pagephysend} ) {
				$phys{$i} = "uncounted";
			}
		}
	}
	for my $page ( $para{von} .. $para{bis} ) {
		my $div = $obj->createElement("mets:div");
		$div->setAttribute(ID=>sprintf("PHYS_%04d",$page));
		$div->setAttribute(ORDER=>$page);
		$div->setAttribute(ORDERLABEL=>$phys{$page} // "uncounted" );
		$div->setAttribute(TYPE=>"page");
		my $fptr = $obj->createElement("mets:fptr");
		$fptr->setAttribute(FILEID=>sprintf("FILE_%04d",$page-1));
		$div->appendChild($fptr);
		$para{physical}->appendChild($div);
	}
}

sub struk {
	my %para = (
		docstrukt => undef,
		logical => undef,
		metadata => undef,
		@_
	);
	my $data;
	my $person;
	my $dmd;
	my @path;
#logid generieren
	my $log = sprintf("LOG_%04d",$id{log}++);
#type holen
	my $type = $para{docstrukt}->getAttribute("AGORA:Type");
	$type =~ s/^AGORA://;
	my $dmd_data = 1;
# Extraliste zum mutieren der Typen
	if( exists $mutation{$type} ) {
		if ( exists $mutation{$type}->{only} ) {
			$type = $mutation{$type}->{only}->{typ};
			$dmd_data = $mutation{$type}->{only}->{dmd};
		} else {
			my $title = shift @{$para{docstrukt}->findnodes(".//AGORA:TitleDocMain/text()")};
			$title = $title->data;
			$title =~ s/^\s+|\s+$//;
			if( exists $mutation{$type}->{$title} ) {
				$type = $mutation{$type}->{$title}->{typ};
				$dmd_data = $mutation{$type}->{$title}->{dmd};
			} else {
				$type = $mutation{$type}->{default}->{typ};
				$dmd_data = $mutation{$type}->{default}->{dmd};
			}
		}			
	}
# Alles Kinder untersuchen
	for my $node ( $para{docstrukt}->childNodes() ) {
		given( $node->nodeName ) {
			when (/ListOfCreators/) {
				for my $author ( $node->findnodes(".//AGORA:Author") ) {
					my $fname = shift @{$author->findnodes(".//AGORA:CreatorFirstName/text()")};
					my $lname = shift @{$author->findnodes(".//AGORA:CreatorLastName/text()")};
					push @{$person->{Author}} , { fname => $fname->data, lname => $lname->data, id => $author->getAttribute("id")} if $fname and $fname->data and $lname and $lname->data;
				}
				for my $editor ( $node->findnodes(".//AGORA:Editor") ) {
					my $fname = shift @{$editor->findnodes(".//AGORA:CreatorFirstName/text()")};
					my $lname = shift @{$editor->findnodes(".//AGORA:CreatorLastName/text()")};
					push @{$person->{Editor}} , { fname => $fname->data, lname => $lname->data } if $fname and $fname->data and $lname and $lname->data;
				}
			}
			when (/DigitalLibraryCollections/) { push @{$data->{singleDigCollection}}, $_->data for $node->findnodes(".//AGORA:DigitalLibraryCollection/text()"); }
			when (/RefImageSetRange/) {	$para{"pagestart"} = shift @{$para{docstrukt}->findnodes(".//AGORA:ImageSetPageStart/text()")}; $para{"pageend"} = shift @{$para{docstrukt}->findnodes(".//AGORA:ImageSetPageEnd/text()")}; }
			when (/DocStrct/) {}
			default {my $name = $node->nodeName; $name =~ s/^AGORA://; $name = $md_trans{$name} if exists $md_trans{$name}; push @{$data->{$name}}, $node->textContent; }
		}
	}
# Wenn Metadaten dann in die DMD-Section
	if($data and $dmd_data) {
		$dmd = sprintf("DMDLOG_%04d",$id{dmdlog}++);
		if( $para{metadata} ) {
			for my $key ( keys %{$para{metadata}} ) {
				for my $val ( @{$para{metadata}->{$key}} ) {
					push @{$data->{$key}}, $val;
				}
			}
		}
		$vars{mets}->insertBefore(dmdsec(id => $dmd, data => $data, person => $person ),$vars{dmdSec});
	}
# Wenn Herachie dann erstmal eine bauen
	if( $type =~ m#/# ) {
		@path = split /\s+\/\s+/ , $type;
		$type = pop @path;
	}
	my $insert_node = $para{logical};
	if( @path ) {
		for my $typ ( @path ) {
			if( $insert_node->lastChild and $insert_node->lastChild->getAttribute("TYPE") eq $typ ) {
				$insert_node = $insert_node->lastChild;
				structlink(von => $para{"pagestart"}->data, bis =>  $para{"pageend"}->data, log => $insert_node->getAttribute("ID") );
			} else {
				structlink(von => $para{"pagestart"}->data, bis =>  $para{"pageend"}->data, log => $log );
				my $div = $obj->createElement("mets:div");
				$div->setAttribute(ID=> $log);
				$log = sprintf("LOG_%04d",$id{log}++);
				$div->setAttribute(TYPE=>$typ);
				$insert_node->appendChild($div);
				$insert_node = $div;
			}
		}
	}
# structlink
	if( exists $para{"pagestart"} and exists $para{"pageend"} ) {
		structlink(von => $para{"pagestart"}->data, bis =>  $para{"pageend"}->data, log => $log );
	}
# Jetzt endlich die logical einhängen
	my $div = $obj->createElement("mets:div");
	$div->setAttribute(DMDID=>$dmd) if $dmd;
	$div->setAttribute(ID=>$log);
	$div->setAttribute(TYPE=>$type);
	$insert_node->appendChild($div);
# und ab in die Tiefe
	for my $child ( $para{docstrukt}->findnodes("./AGORA:DocStrct") ) {
		struk(docstrukt => $child, logical => $div );
	}
}

sub structlink{
	my %para = (
		von => undef,
		bis => undef,
		log => undef,
		@_
	);
	if( $para{von} and $para{bis} ) {
		for my $i ( $para{von} .. $para{bis} ) {
			$structlink{$para{log}}->{$i}++;
		}
	}
}

sub mkstructlink{
	my %para = (
		hash => undef,
		structlink => undef,
		@_
	);
	for my $log ( sort keys %{$para{hash}} ) {
		for my $i ( sort {$a <=> $b} keys %{$para{hash}->{$log}} ) {
			my $smlink = $obj->createElement("mets:smLink");
			$smlink->setAttribute("xmlns:xlink"=>"http://www.w3.org/1999/xlink");
			$smlink->setAttribute("xlink:to"=>sprintf("PHYS_%04d",$i));
			$smlink->setAttribute("xlink:from"=>$log);
			$para{structlink}->appendChild($smlink);
		}
	}
}

sub file{
	my %para = (
		local => undef,
		von => undef,
		bis => undef,
		path => undef,
		@_
	);
	my $ret;
	my $id = 0;
	for my $i ( $para{von} .. $para{bis} ) {
		my $file = $obj->createElement("mets:file");
		$file->setAttribute(ID=>sprintf("FILE_%04d",$id++));
		$file->setAttribute(MIMETYPE=>"image/tiff");
		my $floct = $obj->createElement("mets:FLocat");
		$floct->setAttribute(LOCTYPE=>"URL");
		$floct->setAttribute("xmlns:xlink"=>"http://www.w3.org/1999/xlink");
		$floct->setAttribute("xlink:href"=>$para{path}."/".sprintf("%08d",$i).".tif");
		$file->appendChild($floct);
		$para{local}->addChild($file);
	}
}

sub dmdsec {
	my %para = (
		id => undef,
		data => {},
		person => {},
		@_
	);
	my ($ret,$lnode);
	my $def = [
		{ 	name => "mets:dmdSec",
			attr => {ID=>$para{id},},
		},
		{ 	name => "mets:mdWrap",
			attr => {MDTYPE=>"MODS",},
		},
		{ 	name => "mets:xmlData",
		},
		{ 	name => "mods:mods",
			attr => {"xmlns:mods"=>"http://www.loc.gov/mods/v3",},
		},
		{ 	name => "mods:extension",
		},
		{ 	name => "goobi:goobi",
			attr => {"xmlns:goobi"=>"http://meta.goobi.org/v1.5.1/",},
		},
	];
	for my $def ( @$def ) {
		my $node = $obj->createElement($def->{name});
		if( exists $def->{attr} ) {
			while ( my ($key, $value) = each(%{$def->{attr}}) ) {
				$node->setAttribute($key => $value);
			}
		 }
		 if ( ! $ret ) {
			 $ret = $node;
		 } else {
			$lnode->appendChild($node);
		}
		$lnode = $node;
	}
	if( $para{data} ) {
		while ( my ($key, $value) = each(%{$para{data}}) ) {
			for my $val ( ref($value) ? @$value : ($value) ) {
				my $node = $obj->createElement("goobi:metadata");
				$node->setAttribute(name => $key);
				$node->appendText($val);
				$lnode->appendChild($node);
			}
		}
	}
	if( $para{person} ) {
		while ( my ($key, $value) = each(%{$para{person}}) ) {
			for my $person ( @$value ) {
				my $node = $obj->createElement("goobi:metadata");
				$node->setAttribute(name => $key);
				$node->setAttribute(type => "person");
				my $lname = $obj->createElement("goobi:lastName");
				$lname->appendText($person->{lname});
				$node->appendChild($lname);
				my $fname = $obj->createElement("goobi:firstName");
				$fname->appendText($person->{fname});
				$node->appendChild($fname);
				if( $person->{id} ) {
					my $id = $obj->createElement("goobi:identifier");
					$id->appendText($person->{id});
					$node->appendChild($id);
				}
				$lnode->appendChild($node);
			}
		}
	}
	return $ret;
}sub ini{
	my $tag = shift;
	my $rgabe = $ini->get( $tag );
	if (!$rgabe) {
		if (uc $tag eq "CHARSET") {
			$rgabe = '<meta http-equiv="content-type" content="text/html">';
		}
	}
	return $rgabe;
}


