#!/bin/bash
# Expected command line parameters
#	$1: path to file with update sql script for the new version
#
# As part of preparation for minor 3.x update ...
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# this script updates the kitodo database 
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
	echo "\$1 (path to file with update sql script for the new version)"
	exit -1
fi
if [ ! -f $1 ]
then
	echo "File $1 given as first parameter not found"
	exit -2
fi

echo "As part of preparation for minor 3.x update ..."
echo "as described here https://github.com/kitodo/kitodo-production/issues/3396 ..."
echo "this script updates the kitodo database"
echo "Hint: tomcat service will be stopped(!) also."
echo ""


echo "stopping Tomcat ..."
service tomcat8 stop
echo ""

echo "performing database update ..."
mysql -u $mysqluser --password=$mysqlpwd  $mysqldb < $1
if [ $? -ne 0 ]
then
	echo "Error executing SQL-Script: $1"
	exit -3
fi
echo ""

echo "... work done!"
echo ""

