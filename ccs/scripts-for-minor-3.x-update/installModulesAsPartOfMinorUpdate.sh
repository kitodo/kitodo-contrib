#!/bin/bash
# Expected command line parameters
#	$1: path to file with update modules.zip for the new version
#
# Installing new modules-jars as part of minor 3.x update ...
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# Files will be put to /usr/local/kitodo/modules
# Hint: tomcat service will be stopped(!) also

#fixed parameter
kitodoPath=/usr/local/kitodo


if [ "$EUID" -ne 0 ]
  then echo "Please run as root(sudo)"
  exit -1
fi

if [ $# -ne 1 ]
then
	echo "Parameter number not correct, expecting:"
	echo "\$1 (zipfile with new module-jars)"
	exit -1
fi
if [ ! -f $1 ]
then
	echo "File $1 given as first parameter not found"
	exit -2
fi

destDir=$kitodoPath/modules

echo "Installing new modules-jars as part of minor 3.x update ..."
echo "as described here https://github.com/kitodo/kitodo-production/issues/3396 ..."
echo "Files will be put to $kitodoPath/modules"
echo ""

echo "stopping Tomcat ..."
service tomcat8 stop
echo ""

echo "installing module-jars ..."
if [ ! -d "$destDir" ]
then
        echo "creating directory: " $destDir
        mkdir $destDir
fi
unzip  $1  -d $destDir
echo ""

echo "... work done!"
echo ""

