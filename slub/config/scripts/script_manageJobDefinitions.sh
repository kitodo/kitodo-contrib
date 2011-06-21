#!/bin/bash

# Datenverzeichnis von Goobi
Goobidata=/home/goobi/work/staging1
# Unterverzeichnis in dem die Images liegen
Images=images
# Unterverzeichnisstruktur, in der bestimmte Images liegen - z.B. Originalscans, beschnittene Scans usw.
Scans=scans_
# Liste der Imagevarianten
Jobs="tif orig"
# Verzeichnis, in dem die später per Cron zu bearbeitenden Goobi Jobs abgelegt werden soll
JobDir=$Goobidata/jobs

## Funktionen
# Funktion: Goobi ID der Vorganges ermitteln
DetectGoobiID () {
    # Aufruf: DetectGoobiID
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Aufruf der Funktion: DetectGoobiID"; fi
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "echo $Linkname |sed -e 's/.*\[\(.*\)\]$/\1/'"; fi
    ID=`echo "$Linkname" |sed -e 's/.*\[\(.*\)\]$/\1/'`
    Errorlevel=$?
    errorlevel
}

# Funktion: Zeitstempel der aktuellsten Datei ermitteln und ermittelten Zeitstempel mit gespeicherten vergleichen
TimestampCompare () {
    # Aufruf: TimestampCompare ArtDerImages
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Aufruf der Funktion: TimestampCompare $1"; fi
    local Job="$1"
    # cTime-Zeitstempel der aktuellsten Datei ermitteln
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "stat -c %Z $Goobidata/$ID/$Images/${Scans}$Job/`ls -tc $Goobidata/$ID/$Images/${Scans}$Job |head -1`"; fi
    local cTimestamp=`stat -c %Z $Goobidata/$ID/$Images/${Scans}$Job/\`ls -tc $Goobidata/$ID/$Images/${Scans}$Job |head -1\``
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "DEBUG\: cTimestamp = ${cTimestamp}"; fi
    Errorlevel=$?
    errorlevel
    if [ -z $cTimestamp ]; then logger -p user.info -t $0 "cTime-Zeitstempel der aktuellsten Datei konnte nicht ermittelt werden"; return; fi
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "cTime-Zeitstempel der aktuellsten Datei: $cTimestamp"; fi
    # Ermittelten cTime-Zeitstempel mit gespeicherten vergleichen
    if [ -f $Goobidata/$ID/$Job.ctimestamp ]
    then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Ein gespeicherter cTime-Zeitstempel existiert in $Goobidata/$ID/$Job.ctimestamp"; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "echo $Goobidata/$ID/$Job.ctimestamp"; fi
	local cTimestampSave=`cat $Goobidata/$ID/$Job.ctimestamp`
	if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "DEBUG\: cTimestampSave = ${cTimestampSave}"; fi
        Errorlevel=$?
	errorlevel
        if [ -z $cTimestampSave ]; then logger -p user.info -t $0 "Gespeicherter cTime-Zeitstempel konnte nicht ermittelt werden"; return; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Gespeicherter cTime-Zeitstempel: $cTimestampSave"; fi
	# Prüfung, ob der cTime-Zeitstempel neuer als der gespeicherte ist
	if [ "$cTimestamp" -gt "$cTimestampSave" ]
	then
            if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Der cTime-Zeitstempel $cTimestamp ist neuer als der gespeicherte cTime-Zeitstempel $cTimestampSave"; fi
	    # Gespeicherten cTime-Zeitstempel mit neuem ersetzen, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
	    cTimestampNew $cTimestamp $Job
	else
	    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Der cTime-Zeitstempel $cTimestamp ist nicht neuer als der gespeicherte cTime-Zeitstempel in $cTimestampSave"; fi
	fi
    # Ermittelten cTime-Zeitstempel mit vorübergehend deaktivierten vergleichen
    elif [ -f $Goobidata/$ID/$Job.ctimestamp.bak ]
    then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Ein vorübergehend deaktivierter cTime-Zeitstempel existiert in $Goobidata/$ID/$Job.ctimestamp.bak"; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mv $Goobidata/$ID/$Job.ctimestamp.bak $Goobidata/$ID/$Job.ctimestamp"; fi
        mv $Goobidata/$ID/$Job.ctimestamp.bak $Goobidata/$ID/$Job.ctimestamp
        Errorlevel=$?
        errorlevel
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "echo $Goobidata/$ID/$Job.ctimestamp"; fi
	local cTimestampSave=`cat $Goobidata/$ID/$Job.ctimestamp`
	if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "DEBUG\: cTimestampSave = ${cTimestampSave}"; fi
        Errorlevel=$?
	errorlevel
        if [ -z $cTimestampSave ]; then logger -p user.info -t $0 "Vorübergehend deaktivierter cTime-Zeitstempel konnte nicht ermittelt werden"; return; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Vorübergehend deaktivierter cTime-Zeitstempel: $cTimestampSave"; fi
	# Prüfung, ob der cTime-Zeitstempel neuer oder gleich dem vorübergehend deaktivierten ist
	if [ "$cTimestamp" -ge "$cTimestampSave" ]
	then
            if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Der cTime-Zeitstempel $cTimestamp ist neuer als oder gleich dem vorübergehend deaktivierten cTime-Zeitstempel $cTimestampSave"; fi
	    # Gespeicherten cTime-Zeitstempel mit neuem ersetzen, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
	    cTimestampNew $cTimestamp $Job
	else
	    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Der cTime-Zeitstempel $cTimestamp ist älter als der vorübergehend deaktivierte cTime-Zeitstempel in $cTimestampSave"; fi
	    # Da nur falls ein Job definiert ist, ein vorübergehend deaktivierter cTime-Zeitstempel existiert: Gespeicherten cTime-Zeitstempel trotzdem mit neuem ersetzen, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
	   cTimestampNew $cTimestamp $Job
	fi
    else
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Es existiert kein gespeicherter cTime-Zeitstempel, ein neuer wird angelegt"; fi
	# Gespeicherten cTime-Zeitstempel generieren, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
	cTimestampNew $cTimestamp $Job
    fi
    # Zeitstempel der aktuellsten Datei ermitteln
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "stat -c %Y $Goobidata/$ID/$Images/${Scans}$Job/`ls -t $Goobidata/$ID/$Images/${Scans}$Job |head -1`"; fi
    local Timestamp=`stat -c %Y $Goobidata/$ID/$Images/${Scans}$Job/\`ls -t $Goobidata/$ID/$Images/${Scans}$Job |head -1\``
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "DEBUG\: Timestamp = ${Timestamp}"; fi
    Errorlevel=$?
    errorlevel
    if [ -z $Timestamp ]; then logger -p user.info -t $0 "Zeitstempel der aktuellsten Datei konnte nicht ermittelt werden"; return; fi
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Zeitstempel der aktuellsten Datei: $Timestamp"; fi
    # Ermittelten Zeitstempel mit gespeicherten vergleichen
    if [ -f $Goobidata/$ID/$Job.timestamp ]
    then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Ein gespeicherter Zeitstempel existiert in $Goobidata/$ID/$Job.timestamp"; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "echo $Goobidata/$ID/$Job.timestamp"; fi
	local TimestampSave=`cat $Goobidata/$ID/$Job.timestamp`
	if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "DEBUG\: TimestampSave = ${TimestampSave}"; fi
        Errorlevel=$?
	errorlevel
        if [ -z $TimestampSave ]; then logger -p user.info -t $0 "Gespeicherter Zeitstempel konnte nicht ermittelt werden"; return; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Gespeicherter Zeitstempel: $TimestampSave"; fi
	# Prüfung, ob der Zeitstempel neuer als der gespeicherte ist
	if [ "$Timestamp" -gt "$TimestampSave" ]
	then
            if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Der Zeitstempel $Timestamp ist neuer als der gespeicherte Zeitstempel $TimestampSave"; fi
	    # Gespeicherten Zeitstempel mit neuem ersetzen, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
	    TimestampNew $Timestamp $Job
	else
	    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Der Zeitstempel $Timestamp ist nicht neuer als der gespeicherte Zeitstempel in $TimestampSave"; fi
	fi
    # Ermittelten Zeitstempel mit vorübergehend deaktivierten vergleichen
    elif [ -f $Goobidata/$ID/$Job.timestamp.bak ]
    then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Ein vorübergehend deaktivierter Zeitstempel existiert in $Goobidata/$ID/$Job.timestamp.bak"; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mv $Goobidata/$ID/$Job.timestamp.bak $Goobidata/$ID/$Job.timestamp"; fi
        mv $Goobidata/$ID/$Job.timestamp.bak $Goobidata/$ID/$Job.timestamp
        Errorlevel=$?
        errorlevel
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "echo $Goobidata/$ID/$Job.timestamp"; fi
	local TimestampSave=`cat $Goobidata/$ID/$Job.timestamp`
	if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "DEBUG\: TimestampSave = ${TimestampSave}"; fi
        Errorlevel=$?
	errorlevel
        if [ -z $TimestampSave ]; then logger -p user.info -t $0 "Vorübergehend deaktivierter Zeitstempel konnte nicht ermittelt werden"; return; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Vorübergehend deaktivierter Zeitstempel: $TimestampSave"; fi
	# Prüfung, ob der Zeitstempel neuer oder gleich dem vorübergehend deaktivierten ist
	if [ "$Timestamp" -ge "$TimestampSave" ]
	then
            if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Der Zeitstempel $Timestamp ist neuer als oder gleich dem vorübergehend deaktivierten Zeitstempel $TimestampSave"; fi
	    # Gespeicherten Zeitstempel mit neuem ersetzen, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
	    TimestampNew $Timestamp $Job
	else
	    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Der Zeitstempel $Timestamp ist älter als der vorübergehend deaktivierte Zeitstempel in $TimestampSave"; fi
	    # Da nur falls ein Job definiert ist, ein vorübergehend deaktivierter Zeitstempel existiert: Gespeicherten Zeitstempel trotzdem mit neuem ersetzen, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
	    TimestampNew $Timestamp $Job
	fi
    else
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Es existiert kein gespeicherter Zeitstempel, ein neuer wird angelegt"; fi
	# Gespeicherten Zeitstempel generieren, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
	TimestampNew $Timestamp $Job
    fi
}

# Funktion: Gespeicherten Zeitstempel erzeugen oder überschreiben, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
cTimestampNew () {
    # Aufruf: cTimestampNew Zeitstempel ArtderImages
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Aufruf der Funktion: cTimestampNew $1 $2"; fi
    local cTimestamp="$1"
    local Job="$2"
    # Gespeicherten cTime-Zeitstempel erzeugen oder überschreiben
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "echo $cTimestamp >$Goobidata/$ID/$Job.ctimestamp"; fi
    echo "$cTimestamp" >$Goobidata/$ID/$Job.ctimestamp
    Errorlevel=$?
    errorlevel
    # Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
    if [ ! -d $JobDir/$Job ]
    then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Verzeichnis $JobDir/$Job zur Aufnahme der zu bearbeitenden Jobs existiert noch nicht"; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mkdir -p $JobDir/$Job"; fi
	mkdir -p $JobDir/$Job
        Errorlevel=$?
	errorlevel
    fi
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "touch $JobDir/$Job/$ID"; fi
    touch $JobDir/$Job/$ID
    Errorlevel=$?
    errorlevel
}

# Funktion: Gespeicherten Zeitstempel erzeugen oder überschreiben, Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
TimestampNew () {
    # Aufruf: TimestampNew Zeitstempel ArtderImages
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Aufruf der Funktion: TimestampNew $1 $2"; fi
    local Timestamp="$1"
    local Job="$2"
    # Gespeicherten Zeitstempel erzeugen oder überschreiben
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "echo $Timestamp >$Goobidata/$ID/$Job.timestamp"; fi
    echo "$Timestamp" >$Goobidata/$ID/$Job.timestamp
    Errorlevel=$?
    errorlevel
    # Goobi ID des Vorganges für spätere Jobabarbeitung hinterlegen
    if [ ! -d $JobDir/$Job ]
    then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Verzeichnis $JobDir/$Job zur Aufnahme der zu bearbeitenden Jobs existiert noch nicht"; fi
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mkdir -p $JobDir/$Job"; fi
	mkdir -p $JobDir/$Job
        Errorlevel=$?
	errorlevel
    fi
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "touch $JobDir/$Job/$ID"; fi
    touch $JobDir/$Job/$ID
    Errorlevel=$?
    errorlevel
}

# Funktion: Gespeicherten Zeitstempel vorübergehend deaktivieren und die später per Cron zu erledigenden Jobdefinitionen löschen
TimestampBackup () {
    # Aufruf: TimestampBackup ArtderImages
    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Aufruf der Funktion: TimestampBackup $1"; fi
    local Job="$1"
    # Die später per Cron zu erledigenden Jobdefinitionen löschen
    if [ -f $JobDir/$Job/$ID ]
    then
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "rm $JobDir/$Job/$ID"; fi
	rm $JobDir/$Job/$ID
        Errorlevel=$?
	errorlevel
	# Gespeicherten cTime-Zeitstempel vorübergehend deaktivieren
	if [ -f $Goobidata/$ID/$Job.ctimestamp ]
	then
	    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mv $Goobidata/$ID/$Job.ctimestamp $Goobidata/$ID/$Job.ctimestamp.bak"; fi
	    mv $Goobidata/$ID/$Job.ctimestamp $Goobidata/$ID/$Job.ctimestamp.bak
	    Errorlevel=$?
	    errorlevel
	else
	    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Gespeicherter cTime-Zeitstempel $Goobidata/$ID/$Job.ctimestamp existiert nicht"; fi
	fi
        # Gespeicherten Zeitstempel vorübergehend deaktivieren
        if [ -f $Goobidata/$ID/$Job.timestamp ]
	then
    	    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "mv $Goobidata/$ID/$Job.timestamp $Goobidata/$ID/$Job.timestamp.bak"; fi
    	    mv $Goobidata/$ID/$Job.timestamp $Goobidata/$ID/$Job.timestamp.bak
    	    Errorlevel=$?
    	    errorlevel
	else
    	    if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Gespeicherter Zeitstempel $Goobidata/$ID/$Job.timestamp existiert nicht"; fi
	fi
    else
        if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "Jobdefinition $JobDir/$Job/$ID existiert nicht"; fi
    fi
}
