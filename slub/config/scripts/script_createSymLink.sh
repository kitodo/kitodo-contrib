#!/bin/bash

# Logging einschalten?
Debug=1
source `dirname $0`/errorlevel.sh

# Verwaltung der später per Cron zu erledigenden Jobdefinitionen einbinden
source `dirname $0`/script_manageJobDefinitions.sh

# erste Variable: Ausgangsverzeichnis
# zweite Variable: Linkname
Ausgangsverzeichnis="$1"
Linkname="$2"
Benutzer="$3"

# Verzeichnisname, in dem die Originalscans abgelegt werden sollen
Originalscans="scans_orig"
# Verzeichnisname, in dem die Präsentationsscans abgelegt werden sollen
Praesentationsscans="scans_tif"
# Verzeichnisname, in dem die Abbildungsscans abgelegt werden sollen
Abbildungsscans="scans_abb"

#echo $Ausgangsverzeichnis
#echo $Linkname

if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "ln -s $Ausgangsverzeichnis $Linkname"; fi
ln -s "$Ausgangsverzeichnis" "$Linkname"
Errorlevel=$?
errorlevel

if [ ! -d "$Ausgangsverzeichnis"/"$Originalscans" ]
then
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mkdir -m 2755 -p $Ausgangsverzeichnis/$Originalscans"; fi
    mkdir -m 2775 -p "$Ausgangsverzeichnis"/"$Originalscans"
    Errorlevel=$?
    errorlevel
else
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Anzulegendes Verzeichnis $Ausgangsverzeichnis/$Originalscans existiert bereits"; fi
fi

if [ ! -d "$Ausgangsverzeichnis"/"$Praesentationsscans" ]
then
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mkdir -m 2775 -p $Ausgangsverzeichnis/$Praesentationsscans"; fi
    mkdir -m 2775 -p "$Ausgangsverzeichnis"/"$Praesentationsscans"
    Errorlevel=$?
    errorlevel
else
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Anzulegendes Verzeichnis $Ausgangsverzeichnis/$Praesentationsscans existiert bereits"; fi
fi

if [ ! -d "$Ausgangsverzeichnis"/"$Abbildungsscans" ]
then
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mkdir -m 2775 -p $Ausgangsverzeichnis/$Abbildungsscans"; fi
    mkdir -m 2775 -p "$Ausgangsverzeichnis"/"$Abbildungsscans"
    Errorlevel=$?
    errorlevel
else
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Anzulegendes Verzeichnis $Ausgangsverzeichnis/$Abbildungsscans existiert bereits"; fi
fi

if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "sudo /bin/chown -R $Benutzer $Ausgangsverzeichnis"; fi
sudo /bin/chown -R "$Benutzer" "$Ausgangsverzeichnis"
Errorlevel=$?
errorlevel

# Verwaltung der später per Cron zu erledigenden Jobdefinitionen, außer wenn $Benutzer tomcat55 ist - dann hat der Goobi Benutzer keine Schreibrechte und es gibt keinen Anpassungsbedarf
if [ $Benutzer != "tomcat55" ]
then
    # Goobi ID der Vorganges ermitteln
    DetectGoobiID
    # Existiert ein zur Goobi ID passendes Vorgangsverzeichnis?
    if [ -d $Goobidata/$ID ]
	then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Verzeichnis $Goobidata/$ID existiert"; fi
        # Gespeicherten Zeitstempel vorübergehend deaktivieren und die später per Cron zu erledigenden Jobdefinitionen löschen
        for i in $Jobs
        do
	    TimestampBackup $i
        done
    fi
fi
					     