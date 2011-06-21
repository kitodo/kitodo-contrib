#!/bin/bash

# Logging einschalten?
Debug=1
source `dirname $0`/errorlevel.sh

# erste Variable: Verzeichnis
Verzeichnis="$1"

if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "sudo /bin/chown tomcat55 $Verzeichnis"; fi
sudo /bin/chown tomcat55 "$Verzeichnis"
Errorlevel=$?
errorlevel
