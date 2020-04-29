#!/bin/sh

#
# Kitodo Production Builder Entrypoint shell script
#

set -e

KITODO_COMMIT=$1
KITODO_SOURCE_URL=$2

if [ "x$KITODO_COMMIT" = "x" ]; then
  if [ "x$KITODO_SOURCE_URL" = "x" ]; then
    echo "Syntax: docker-compose run kitodo [<KITODO_COMMIT>] [<KITODO_SOURCE_URL>]"
	echo "Either KITODO_COMMIT or KITODO_SOURCE_URL must be given."
	echo "Use \"master\" for KITODO_COMMIT to get the latest commit."
	exit 1
  fi
  KITODO_COMMIT="master"
fi
if [ "x$KITODO_SOURCE_URL" = "x" ]; then
  if [ $KITODO_COMMIT = "master" ]; then
	KITODO_SOURCE_URL="https://github.com/kitodo/kitodo-production/archive/master.zip"
  else
    KITODO_SOURCE_URL="https://github.com/kitodo/kitodo-production/archive/$KITODO_COMMIT.zip"
  fi
elif [ `echo "$KITODO_SOURCE_URL" | rev | cut -c 1-4` != 'piz.' ]; then
  if [ `echo "$KITODO_SOURCE_URL" | rev | cut -c 1-1` != '/' ]; then
    KITODO_SOURCE_URL="${KITODO_SOURCE_URL}/"
  fi
  KITODO_SOURCE_URL="${KITODO_SOURCE_URL}archive/$KITODO_COMMIT.zip"
fi

echo "========================================================================="
echo "1. Download source files"
echo "========================================================================="

echo "using commit $KITODO_COMMIT"
echo "using $KITODO_SOURCE_URL as download location"

curl -L $KITODO_SOURCE_URL > master.zip
unzip master.zip 

DIR=`ls -1 . | grep kitodo-prod`
if [ x$DIR = "x" ]; then
  echo "No Kitodo Production directory found in zip"
  exit 1
fi
echo extracted to $DIR
if [ `echo "$DIR" | rev | cut -c 1-6` != 'retsam' ]; then
  mv $DIR kitodo-production-master
  echo renamed $DIR to kitodo-production-master
fi


echo "========================================================================="
echo "Create MySQL database and user"
echo "========================================================================="

mysql --host=$MYSQL_HOST -u root --password=$MYSQL_ROOT_PASSWORD -e "drop database kitodo; create database kitodo; grant all privileges on kitodo.* to kitodo@'%' identified by 'kitodo';flush privileges;"

echo "SQL statements done."

sed -i "s!flyway.url=jdbc:mysql://localhost/kitodo?useSSL=false!flyway.url=jdbc:mysql://$MYSQL_HOST/kitodo?useSSL=false!;" kitodo-production-master/Kitodo-DataManagement/src/main/resources/db/config/flyway.properties

echo "Adapted mysql connection for maven."


echo "========================================================================="
echo "2. Build files for deployment"
echo "========================================================================="

echo "========================================================================="
echo "Build development version and modules"
echo "========================================================================="

(cd kitodo-production-master/ && mvn clean package '-P!development')
zip -j kitodo-3-modules.zip kitodo-production-master/Kitodo/modules/*.jar
mv kitodo-production-master/Kitodo/target/kitodo-3*.war kitodo-3.war


echo "========================================================================="
echo "Create Maven fake repository"
echo "========================================================================="

# create a fake repo for kitodo api jar. we need it when generating the sql dump
API_VERSION=`ls kitodo-production-master/Kitodo-API/target/kitodo-api*.jar | xargs basename -s .jar | cut -c 12-` 
mkdir -p maven-fake-repo/org/kitodo/kitodo-api/$API_VERSION
cp kitodo-production-master/Kitodo-API/target/kitodo-api*.jar maven-fake-repo/org/kitodo/kitodo-api/$API_VERSION
# register the repo in the kitodo main pom.xml
MAVEN_URL="file://`pwd`/maven-fake-repo"
REPO_DEF="<repository><id>localfs</id><name>Local System</name><layout>default</layout><url>$MAVEN_URL</url><snapshots><enabled>true</enabled></snapshots></repository>"
sed -i "s!<repositories>!<repositories>$REPO_DEF!;" kitodo-production-master/pom.xml


echo "========================================================================="
echo "Generate SQL dump (flyway migration)"
echo "========================================================================="

echo "Build db"
cat kitodo-production-master/Kitodo/setup/schema.sql | mysql --host=$MYSQL_HOST -u kitodo -D kitodo --password=kitodo
cat kitodo-production-master/Kitodo/setup/default.sql | mysql --host=$MYSQL_HOST -u kitodo -D kitodo --password=kitodo
(cd kitodo-production-master/Kitodo-DataManagement && mvn flyway:baseline -Pflyway && mvn flyway:migrate -Pflyway)
mysqldump --host=$MYSQL_HOST -u kitodo --password=kitodo kitodo > kitodo-3.sql


echo "========================================================================="
echo "Create zip archive with directories and config file"
echo "========================================================================="

mkdir zip zip/config zip/debug zip/import zip/logs zip/messages zip/metadata zip/plugins zip/plugins/command zip/plugins/import zip/plugins/opac zip/plugins/step zip/plugins/validation zip/rulesets zip/scripts zip/swap zip/temp zip/users zip/xslt zip/diagrams
install -m 444 kitodo-production-master/Kitodo/src/main/resources/kitodo_*.xml zip/config/
install -m 444 kitodo-production-master/Kitodo/src/main/resources/modules.xml zip/config/
install -m 444 kitodo-production-master/Kitodo/src/main/resources/docket*.xsl zip/xslt/
install -m 444 kitodo-production-master/Kitodo/rulesets/*.xml zip/rulesets/
install -m 444 kitodo-production-master/Kitodo/diagrams/*.xml zip/diagrams/
install -m 554 kitodo-production-master/Kitodo/scripts/*.sh zip/scripts/
chmod -w zip/config zip/import zip/messages zip/plugins zip/plugins/command zip/plugins/import zip/plugins/opac zip/plugins/step zip/plugins/validation zip/rulesets zip/scripts zip/xslt
(cd zip && zip -r ../kitodo-3-config.zip *)


echo "========================================================================="
echo "X. Export & Exit"
echo "========================================================================="

mkdir -p /kitodo/$API_VERSION-$KITODO_COMMIT
mv kitodo-3* /kitodo/$API_VERSION-$KITODO_COMMIT
chmod -R a+rw /kitodo

echo "========================================================================="
echo "DONE!"
echo "========================================================================="
echo "Commit:       $KITODO_COMMIT"
echo "Download URL: $KITODO_SOURCE_URL"
echo "API version:  $API_VERSION"
echo "Export dir:   $API_VERSION-$KITODO_COMMIT"
echo "========================================================================="
echo "Have a nice day!"