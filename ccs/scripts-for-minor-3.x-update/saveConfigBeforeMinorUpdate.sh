#!/bin/bash
# Expected command line parameters
# 	$1: directory for stored data, typical "~"
#     a sub-directory "savedOldVersionData" will be created below
# Saving current configuration as part of preparation for minor 3.x update ...
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# Files taken from .../tomcat8/webapps/kitodo*/WEB-INF/classes, excluding mapping.json

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
	echo "\$1 (directory for data to be saved in)"
	exit -1
fi
if [ ! -d $1 ]
then
	echo "Directory $1 given as first parameter not found"
	exit -2
fi

echo "Saving current configuration as part of preparation for minor 3.x update ..."
echo "as described here https://github.com/kitodo/kitodo-production/issues/3396 ..."
echo "Files taken from .../tomcat8/webapps/kitodo*/WEB-INF/classes, excluding mapping.json"
echo ""
possibleConfigDirs="$(find "$configDirSearchPath" -maxdepth 1 -type d -iname "$kitodoBaseWarName")"
numberPossibleConfigDirs="$(echo "$possibleConfigDirs" | wc -l)"
if [ "$numberPossibleConfigDirs" != 1 ]
then
        echo "Not clear (expecting one - no less, no more) candidate for config here: " $configDirSearchPath
        exit -3
fi

destDir=$1/savedOldVersionData
filename="$(date | awk '{print $6$2$3$4}' | sed -e 's/:/_/g')"
if [ ! -d "$destDir" ]
then
        echo "creating directory: " $destDir
        mkdir $destDir
fi

# create the tar of the config
desttarfile=$destDir/$filename-config.tar
dirToTar=$possibleConfigDirs/WEB-INF/classes
find "$dirToTar" -maxdepth 1 -type f -printf "%f\n"| grep -v mapping > .temp.tar
numberOfFilesFound="$(cat .temp.tar | wc -l)"
if [ ! $numberOfFilesFound > 0 ]
then
        echo "Could not find any config files here: $dirToTar"
        exit -4
fi
echo "Creating" $desttarfile "including these files:"
tar -C $dirToTar -czf "$desttarfile" -T .temp.tar
tar tf $desttarfile
rm .temp.tar
echo ""

echo "... work done!"
echo ""

