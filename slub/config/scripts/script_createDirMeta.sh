#!/bin/bash

# Logging einschalten?
Debug=1
source `dirname $0`/errorlevel.sh

# erste Variable: Verzeichnis
Verzeichnis="$1"

#echo $Verzeichnis
if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "/bin/mkdir -m 0775 $Verzeichnis"; fi
/bin/mkdir -m 0775 "$Verzeichnis"
Errorlevel=$?
errorlevel
