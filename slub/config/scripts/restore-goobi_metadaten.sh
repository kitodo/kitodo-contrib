#!/bin/bash

######################
# Stellt eine Datensicherung aller Goobi Metadaten Dateien wieder her
# Aufruf: backup-goobi_metadaten.sh
######################

# Logging einschalten?
Debug=1
source `dirname $0`/errorlevel-echo.sh

# Zeitstempel ermitteln
START=`date "+%Y%m%d%H%M%S"`
TAG=`date "+%Y-%m-%d"`

# Verzeichnis zur Ablage der Logdateien
LOGDIR="/var/log"

# Dateiname extrahieren, Dateiendung entfernen
LOGDATEI=`basename $0 | sed -e 's/\..*$//'`

# Datenverzeichnis von Goobi
MetadatenDir="/home/goobi/work/staging1"

# Verzeichnis für die Backupdateien
BackupDir="/home/goobi/archiv/backups/goobi"

# =============================================================================

echo "Prozess: $0" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
echo "Prozess-ID: $$" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
echo "Start: $START" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
echo "Verzeichnis für wiederherzustellende Goobi Metadaten Dateien: $MetadatenDir" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
echo "===============================================================================" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1

# In Verzeichnis für wiederherzustellende Goobi Metadaten Dateien wechseln
if [ $Debug -eq 1 ]; then echo "In Verzeichnis für wiederherzustellende Goobi Metadaten Dateien wechseln" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1; fi
if [ $Debug -eq 1 ]; then echo "cd ${MetadatenDir}" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1; fi
cd $MetadatenDir >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
Errorlevel=$?
errorlevel >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
		 
# Alle Goobi Metadaten Dateien entpacken
if [ $Debug -eq 1 ]; then echo "Alle Goobi Metadaten Dateien entpacken" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1; fi
if [ $Debug -eq 1 ]; then echo "tar -xzf ${BackupDir}/${TAG}-goobi_metadaten.tar.gz" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1; fi
tar -xzf ${BackupDir}/${TAG}-goobi_metadaten.tar.gz >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
Errorlevel=$?
errorlevel >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1

# In ursprüngliches Verzeichnis zurückgehen
if [ $Debug -eq 1 ]; then echo "In ursprüngliches Verzeichnis zurückgehen" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1; fi
if [ $Debug -eq 1 ]; then echo "cd - >/dev/null" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1; fi
cd - >/dev/null 2>>${LOGDIR}/${LOGDATEI}_${START}.log
Errorlevel=$?
errorlevel >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1

ENDE=`date "+%Y%m%d%H%M%S"` >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1

echo "" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
echo "Ende: ${ENDE}" >>${LOGDIR}/${LOGDATEI}_${START}.log 2>&1
