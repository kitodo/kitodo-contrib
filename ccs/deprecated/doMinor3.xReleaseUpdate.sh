#!/bin/bash
# Expected commandline parameters
# 	$1: directory for (temporary) stored data, typical "~"
#	$2: path to directory with new version, expecting data there:
#		db-diff.sql
#		kitodo-*.war
#		modules.zip

#fixed parameter
tomcatWebApps=/var/lib/tomcat8/webapps/
tomcatLogFile=/var/log/tomcat8/catalina.out
kitodoPath=/usr/local/kitodo
mysqluser="root"
mysqlpwd=""
mysqldb="kitodo"
configDirSearchPath=/var/lib/tomcat8/webapps/
kitodoBaseWarName="kitodo*"


if [ "$EUID" -ne 0 ]
  then echo "Please run as root(sudo)"
  exit -1
fi

if [ $# -ne 2 ]
then
	echo "Parameter number not correct, expecting:"
	echo "\$1 (directory for (temporary) data)"
	echo "\$2 (path to directory with new version files"
	exit -1
fi
if [ ! -d $1 ]
then
	echo "Directory $1 given as first parameter not found"
	exit -2
fi
if [ ! -d $2 ]
then
	echo "Directory $2 given as second parameter not found"
	exit -3
fi

newVersionFiles="$(find "$2" -maxdepth 1 -type f )"
foundModulesZip=0
foundDbDiffSQL=0
foundKitodoWar=0
for file in $newVersionFiles
do
	if [ $(basename "$file") == "modules.zip" ]
	then
		foundModulesZip=1
		modulesZipFile=$file
	fi
	if [ $(basename "$file") == "db-diff.sql" ]
	then
		foundDbDiffSQL=1
		DbDiffSQLFile=$file
	fi
done
if [ $foundModulesZip -eq 0 ]
then
	echo "No modules.zip found in new version directory $2"
	exit -4
fi
if [ $foundDbDiffSQL -eq 0 ]
then
	echo "No db-diff.sql found in new version directory $2"
	exit -5
fi
foundKitodoWars="$(find "$2" -maxdepth 1 -type f |grep kitodo.*\.war)"
#echo $foundKitodoWars
numberOfFoundKitodoWars="$(echo "$foundKitodoWars" | wc -l)"
if [ "$numberOfFoundKitodoWars" != 1 ]
then
        echo "Too less or too many kitodo*.war files found in new version directory $2"
        exit -6
fi
kitodoWarFile=$foundKitodoWars

echo "performing minor Kitodo 3.x update according to https://github.com/kitodo/kitodo-production/issues/3396  ..."
echo ""

echo "saving current config ..."
possibleConfigDirs="$(find "$configDirSearchPath" -maxdepth 1 -type d -iname "$kitodoBaseWarName")"
numberPossibleConfigDirs="$(echo "$possibleConfigDirs" | wc -l)"
if [ "$numberPossibleConfigDirs" != 1 ]
then
        echo "Not clear candidate for config here: " $configDirSearchPath
        exit -6
fi

destDir=$1/savedOldVersionData/
filename="$(date | awk '{print $6$2$3$4}' | sed -e 's/:/_/g')"
if [ ! -d "$destDir" ]
then
        echo "creating directory: " $destDir
        mkdir $destDir
fi

# create the tar of the config
desttarfile=$destDir$filename.zip
echo $desttarfile
dirToTar=$possibleConfigDirs/WEB-INF/classes
echo $dirToTar
find "$dirToTar" -maxdepth 1 -type f | grep -v mapping > .temp.tar
numberOfFilesFound="$(cat .temp.tar | wc -l)"
if [ ! $numberOfFilesFound > 0 ]
then
        echo "Could not find any config files here: $dirToTar"
        exit -6
fi
echo "Writing " $desttarfile
tar cf "$desttarfile" -T .temp.tar
rm .temp.tar
echo ""

echo "(re-)moving old kitodo*.war ..."
foundOldKitodoWars="$(find "$tomcatWebApps" -maxdepth 1 -type f |grep kitodo.*\.war)"
#echo $foundOldKitodoWars
numberOfFoundOldKitodoWars="$(echo "$foundOldKitodoWars" | wc -l)"
foundAtLeastOneOldKitodoWar=0
for file in $foundOldKitodoWars
do
	echo "File: "$file
	echo "move $file to $1/savedOldVersionData"
	mv $file "$1/savedOldVersionData/"
	echo "mv $(dirname $file)/$(basename $file) $1/savedOldVersionData/"
	mv $(dirname $file)/$(basename $file) "$1/savedOldVersionData/"
	foundAtLeastOneOldKitodoWar=1
done
if [ $foundAtLeastOneOldKitodoWar -eq 0 ]
then
        echo "No old kitodo*.war found"
        exit -7
fi
echo ""

echo "stopping Tomcat ..."
service tomcat8 stop
echo ""

echo "(re-)moving modules.jar ..."
filenameWithDate="modules$(date | awk '{print $6$2$3$4}' | sed -e 's/:/_/g')"
#echo $filenameWithDate
if [ ! -d $kitodoPath/modules ]
then
	echo "Current modules directory not found here: "$kitodoPath
	exit -8
fi
echo "moving modules directory to $filenameWithDate"
mv "$kitodoPath"/modules "$kitodoPath"/"$filenameWithDate"
echo ""

echo "performing database update ..."
mysql -u $mysqluser --password=$mysqlpwd  $mysqldb < $DbDiffSQLFile
if [ $? -ne 0 ]
then
	echo "Error executing SQL-Script: $DbDiffSQLFile"
	exit -9
fi
echo ""

echo "REMARK: Deletion of index as described in https://github.com/kitodo/kitodo-production/issues/3396 is NOT done!"
echo "--> take care by yourself, if needed"
echo ""

echo "installing module-jars ..."
mkdir $kitodoPath/modules
#echo $kitodoPath/modules
unzip  $modulesZipFile  -d $kitodoPath/modules/
echo ""

echo "installing $kitodoWarFile to $tomcatWebApps ..."
cp $kitodoWarFile $tomcatWebApps
echo "starting tomcat ..."
service tomcat8 start
echo "waiting for deployment done ..."
deploymentDone=0
tomcatLogFile=/var/log/tomcat8/catalina.out
while [ $deploymentDone != 1 ]
do
	searchForDeployment="$(tail $tomcatLogFile | grep Deployment | wc -l)"
	#echo $searchForDeployment
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

echo "stopping Tomcat again ..."
service tomcat8 stop
echo ""


echo "restoring config files ..."
tar -xf $desttarfile  -C $dirToTar
echo ""

echo "starting tomcat again ..."
service tomcat8 start
echo ""

echo "... Update Procedure finalized!"
echo ""
echo "Your turn now: Login to Kitodo and re-created Index if needed"
echo "Be aware of possible different URL based on WAR-file-name: $kitodoWarFile"

