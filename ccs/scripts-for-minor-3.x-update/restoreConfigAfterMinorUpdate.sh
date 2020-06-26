#!/bin/bash
# Expected command line parameters
# 	$1: tarfile with saved configuration data
# Restoring current configuration as part of post actions after minor 3.x update ...
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# Files will be put to .../tomcat8/webapps/kitodo*/WEB-INF/classes

#fixed parameter
configDirSearchPath=/var/lib/tomcat8/webapps/
kitodoBaseWarName="kitodo*"


if [ "$EUID" -ne 0 ]
  then echo "Please run as root(sudo)"
  exit -1
fi

if [ $# -ne 1 ]
then
	echo "Parameter number not correct, expecting:"
	echo "\$1 (tarfile with saved configuration data)"
	exit -1
fi
if [ ! -f $1 ]
then
	echo "File $1 given as first parameter not found"
	exit -2
fi

echo "Restoring current configuration as part of post actions after minor 3.x update ..."
echo "as described here https://github.com/kitodo/kitodo-production/issues/3396 ..."
echo "Files will be put to .../tomcat8/webapps/kitodo*/WEB-INF/classes"
echo ""
possibleConfigDirs="$(find "$configDirSearchPath" -maxdepth 1 -type d -iname "$kitodoBaseWarName")"
numberPossibleConfigDirs="$(echo "$possibleConfigDirs" | wc -l)"
if [ "$numberPossibleConfigDirs" != 1 ]
then
        echo "Not clear (expecting one - no less, no more) candidate for config here: " $configDirSearchPath
        exit -3
fi

dirToTar=$possibleConfigDirs/WEB-INF/classes
echo "Extracting" $1 ":"
tar -C $dirToTar -xvf "$1"
echo ""

echo "... work done!"
echo ""

