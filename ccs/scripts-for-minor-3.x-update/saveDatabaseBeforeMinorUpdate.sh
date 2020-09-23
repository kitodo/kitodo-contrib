#!/bin/bash
# Expected command line parameters
# 	$1: directory for stored data, typical "~"
#     a sub-directory "savedOldVersionData" will be created below
# As part of preparation for minor 3.x update ...
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# even if the saving of the database is not described there, ...
# but to have something for a rollback ...
# this script exports the kitodo database and gzips the export
# Hint: tomcat service will be stopped(!) also

#fixed parameter
mysqluser="root"
mysqlpwd=""
mysqldb="kitodo"
tempexportfile=~/.temp.sqlexport


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
echo "even if the saving of the database is not described there, ..."
echo "but to have something for a rollback ..."
echo "this script exports the kitodo database and gzips the export"
echo "to" $destDir "..."
echo "Hint: tomcat service will be stopped(!) also."
echo ""

filename="$(date | awk '{print $6$2$3$4}' | sed -e 's/:/_/g')"
if [ ! -d "$destDir" ]
then
        echo "creating directory: " $destDir
        mkdir $destDir
fi

desttarfile=$destDir/$filename-database.tar

echo "stopping Tomcat ..."
service tomcat8 stop
echo ""

echo "Exporting database $mysqldb ..."
mysqldump --add-drop-table -u $mysqluser  $mysqldb > $tempexportfile
gzip $tempexportfile
mv $tempexportfile.gz $destDir/$filename-database.gz
echo "Export file created: $destDir/$filename-database.gz"

echo "... work done!"
echo ""

