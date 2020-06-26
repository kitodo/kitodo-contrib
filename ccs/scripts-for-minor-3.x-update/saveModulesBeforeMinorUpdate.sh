#!/bin/bash
# Expected command line parameters
# 	$1: directory for stored data, typical "~"
#     a sub-directory "savedOldVersionData" will be created below
# As part of preparation for minor 3.x update ...
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# even if the saving of the module-jars is not described there, ...
# but to have something for a rollback ...
# this scripts tars the current module-jars
# and deletes(!) all modules-jars afterwards

#fixed parameter
kitodoPath=/usr/local/kitodo


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

dirToTar=$kitodoPath/modules

if [ ! -d $dirToTar ]
then
	echo "Current modules directory not found here: "$kitodoPath
	exit -3
fi

destDir=$1/savedOldVersionData


echo "As part of preparation for minor 3.x update ..."
echo "as described here https://github.com/kitodo/kitodo-production/issues/3396 ..."
echo "even if the saving of the module-jars is not described there, ..."
echo "but to have something for a rollback ..."
echo "this scripts tars the current module-jars from" $dirToTar
echo "to" $destDir
echo "and deletes(!) all modules-jars afterwards"
echo ""

filename="$(date | awk '{print $6$2$3$4}' | sed -e 's/:/_/g')"
if [ ! -d "$destDir" ]
then
        echo "creating directory: " $destDir
        mkdir $destDir
fi


desttarfile=$destDir/$filename-modules.tar
find "$dirToTar" -maxdepth 1 -type f -printf "%f\n" > .temp.tar
numberOfFilesFound="$(cat .temp.tar | wc -l)"
if [ ! $numberOfFilesFound > 0 ]
then
        echo "Could not find any module jar files here: $dirToTar"
        exit -4
fi
echo "Creating" $desttarfile "including these files:"
tar -C $dirToTar -czf "$desttarfile" -T .temp.tar
tar tf $desttarfile
rm .temp.tar
echo ""

echo "Deleting" $dirToTar
rm $dirToTar/*

echo "... work done!"
echo ""

