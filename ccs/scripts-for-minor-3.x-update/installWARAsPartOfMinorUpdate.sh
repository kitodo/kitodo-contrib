#!/bin/bash
# Expected command line parameters
#	$1: path to WAR-file for the new version
#
# Installing new WAR-file as part of minor 3.x update ...
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# Files will be put to /var/lib/tomcat8/webapps
# Hint: tomcat service will be stopped(!) also

#fixed parameter
tomcatWebApps=/var/lib/tomcat8/webapps/
tomcatLogFile=/var/log/tomcat8/catalina.out

if [ "$EUID" -ne 0 ]
  then echo "Please run as root(sudo)"
  exit -1
fi

if [ $# -ne 1 ]
then
	echo "Parameter number not correct, expecting:"
	echo "\$1 (WAR-file for new version)"
	exit -1
fi
if [ ! -f $1 ]
then
	echo "File $1 given as first parameter not found"
	exit -2
fi
if [ ! -d $tomcatWebApps ]
then
  echo "Could not find $tomcatWebApps"
  exit -3
fi

#destDir=$kitodoPath/modules

echo "Installing new WAR-jars as part of minor 3.x update ..."
echo "as described here https://github.com/kitodo/kitodo-production/issues/3396 ..."
echo "Files will be put to $tomcatWebApps"
echo ""

echo "stopping Tomcat ..."
service tomcat8 stop
echo ""

kitodoWarFile=$1
echo "copying $kitodoWarFile to $tomcatWebApps ..."
cp $kitodoWarFile $tomcatWebApps
echo ""

echo "starting tomcat ..."
service tomcat8 start
echo ""

echo "waiting 30s for a basic deployment ..."
sleep 30
echo ""

echo "stopping Tomcat ..."
service tomcat8 stop
echo ""

echo "... work done! (Part 1)"
echo ""

