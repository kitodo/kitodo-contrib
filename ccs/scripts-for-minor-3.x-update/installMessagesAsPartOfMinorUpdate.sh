#!/bin/bash
# Expected command line parameters
#	$1: path to WAR-File for the new version
#
# Installing new messages from WAR-File as part of minor 3.x update ...
# as part of the minor update process ...
# defined here https://github.com/kitodo/kitodo-production/issues/3396 ...
# even, if it is not mentioned there.
# Files will be put to /usr/local/kitodo/messages
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
	echo "\$1 (WAR-file)"
	exit -1
fi
if [ ! -f $1 ]
then
	echo "File $1 given as first parameter not found"
	exit -2
fi

destDir=$kitodoPath/messages

echo "Installing new messages from WAR-File as part of minor 3.x update ..."
echo "as part of the minor update process ..."
echo "defined here https://github.com/kitodo/kitodo-production/issues/3396 ..."
echo "even, if it is not mentioned there."
echo "Files will be put to $destDir"
echo ""

echo "stopping Tomcat ..."
service tomcat8 stop
echo ""

echo "installing messages ..."
if [ ! -d "$destDir" ]
then
        echo "creating directory: " $destDir
        mkdir $destDir
fi
unzip -j $1 WEB-INF/classes/messages/* -d $destDir
echo ""

echo "... work done!"
echo ""

