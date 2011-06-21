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

#sudo /bin/mkdir -m 0775 "$Verzeichnis"
if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "sudo /bin/mkdir $Verzeichnis"; fi
sudo /bin/mkdir "$Verzeichnis"
Errorlevel=$?
errorlevel

if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "sudo /bin/chmod g+w $Verzeichnis"; fi
sudo /bin/chmod g+w "$Verzeichnis"
Errorlevel=$?
errorlevel

if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "sudo /bin/chown $Benutzer $Verzeichnis"; fi
sudo /bin/chown $Benutzer "$Verzeichnis"
Errorlevel=$?
errorlevel

if [ $Debug -eq 1 ]; then logger -p user.info -t $0 "sudo /bin/chgrp nogroup $Verzeichnis"; fi
sudo /bin/chgrp nogroup "$Verzeichnis"
Errorlevel=$?
errorlevel

#sudo -u $Benutzer /bin/mkdir -m 0775 "$Verzeichnis"
#sudo /bin/chgrp tomcat "$Verzeichnis"
