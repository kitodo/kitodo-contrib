#!/bin/bash
# Expected command line parameters
#	None
#
# Installing new WAR-file as part of minor 3.x update ... (Part 2)
# as described here https://github.com/kitodo/kitodo-production/issues/3396 ...
# Files will be put to /var/lib/tomcat8/webapps
# Hint: tomcat service will be started(!) 

#fixed parameter
tomcatLogFile=/var/log/tomcat8/catalina.out

if [ "$EUID" -ne 0 ]
  then echo "Please run as root(sudo)"
  exit -1
fi

if [ $# -ne 0 ]
then
	echo "Parameter number not correct, expecting NONE!"
	exit -1
fi

echo "starting tomcat ..."
service tomcat8 start
echo ""

echo "waiting for deployment done ..."
deploymentDone=0
while [ $deploymentDone != 1 ]
do
	searchForDeployment="$(tail $tomcatLogFile | grep Deployment | wc -l)"
	if [ "$searchForDeployment" != 0 ]
	then
		echo "done"
		deploymentDone=1
	else
		echo "wait"
		sleep 2
	fi
done
echo ""

echo "... work done!"
echo ""

