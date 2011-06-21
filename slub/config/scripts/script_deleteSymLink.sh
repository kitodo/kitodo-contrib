#!/bin/bash

# Logging einschalten?
Debug=1
source `dirname $0`/errorlevel.sh

# Verwaltung der später per Cron zu erledigenden Jobdefinitionen einbinden
source `dirname $0`/script_manageJobDefinitions.sh

# erste Variable: Linkname
Linkname="$1"

# Existiert der symbolische Link?
if [ -L $Linkname ]
then
    # Goobi ID der Vorganges ermitteln
    DetectGoobiID
    # Existiert ein zur Goobi ID passendes Vorgangsverzeichnis?
    if [ -d $Goobidata/$ID ]
    then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Verzeichnis $Goobidata/$ID existiert"; fi
	# Zeitstempel der aktuellsten Datei ermitteln und ermittelten Zeitstempel mit gespeicherten vergleichen
	for i in $Jobs
	do
	    TimestampCompare $i
	done
    fi
    # Symbolischen Link löschen
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "rm $Linkname"; fi
    rm "$Linkname"
    Errorlevel=$?
    errorlevel
else
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Es existiert kein symbolischer Link $Linkname"; fi
fi
