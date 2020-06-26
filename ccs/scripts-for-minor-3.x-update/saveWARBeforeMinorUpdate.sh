#!/bin/bash
# Expected command line parameters
# 	$1: directory for stored data, typical "~"
#     a sub-directory "savedOldVersionData" will be created below
# As part of preparation for minor 3.x update ...
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# even if the saving of the WAR-file is not described there, ...
# but to have something for a rollback ...
# this scripts tars the WAR-file plus the according deployed files ...
# and deletes(!) the WAR-file plus the according deployed files afterwards.
# Hint: tomcat service will be stopped(!) also

#fixed parameter
tomcatWebApps=/var/lib/tomcat8/webapps/
kitodoBaseWarName="kitodo*"
tempfile=~/.temp.tar


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

destDir=$1/savedOldVersionData


echo "As part of preparation for minor 3.x update ..."
echo "as described here https://github.com/kitodo/kitodo-production/issues/3396 ..."
echo "even if the saving of the WAR-file is not described there, ..."
echo "but to have something for a rollback ..."
echo "this scripts tars the WAR-file plus the according deployed files from" $tomcatWebApps "..."
echo "to" $destDir "..."
echo "and deletes(!) the WAR-file plus the according deployed files afterwards."
echo "Hint: tomcat service will be stopped(!) also."
echo ""

filename="$(date | awk '{print $6$2$3$4}' | sed -e 's/:/_/g')"
if [ ! -d "$destDir" ]
then
        echo "creating directory: " $destDir
        mkdir $destDir
fi

rememberpwd=`pwd`

desttarfile=$destDir/$filename-war.tar
dirToTar=$tomcatWebApps
cd $dirToTar
find . -type f | grep -v ROOT > $tempfile
numberOfFilesFound="$(cat $tempfile | wc -l)"
if [ ! $numberOfFilesFound > 0 ]
then
        echo "Could not find any WAR files files here:" $dirToTar
        exit -4
fi

echo "stopping Tomcat ..."
service tomcat8 stop
echo ""

echo "Creating" $desttarfile
tar -C $dirToTar -czf "$desttarfile" -T $tempfile
rm $tempfile
echo ""

echo "Deleting WAR-file in" $dirToTar
ls *.war | xargs rm 
echo "Delete deployed data in" $dirToTar
ls -d */ | grep -v ROOT | xargs rm -R


cd $rememberpwd

echo "... work done!"
echo ""

