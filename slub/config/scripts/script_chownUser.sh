#!/bin/bash

# Logging einschalten?
Debug=1
source `dirname $0`/errorlevel.sh

# erste Variable: Benutzer
# zweite Variable: Verzeichnis
Benutzer="$1"
Verzeichnis="$2"

#echo $Benutzer
#echo $Verzeichnis
if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "sudo /bin/chown $Benutzer $Verzeichnis"; fi
sudo /bin/chown "$Benutzer" "$Verzeichnis"
Errorlevel=$?
errorlevel
