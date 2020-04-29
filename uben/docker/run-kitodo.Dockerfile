# Kitodo Production Dockerfile

FROM alpine AS build
RUN apk update && apk add --no-cache unzip xmlstarlet
WORKDIR /build
ARG KITODO_BUILD
ARG MYSQL_HOST
ARG MYSQL_DATABASE
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG BLA

COPY builds/${KITODO_BUILD}/kitodo-3.war ./
COPY builds/${KITODO_BUILD}/kitodo-3-modules.zip ./
COPY builds/${KITODO_BUILD}/kitodo-3-config.zip ./

RUN mkdir -p /kitodo/modules
RUN unzip kitodo-3-config.zip -d /kitodo
RUN unzip kitodo-3-modules.zip -d /kitodo/modules
RUN mkdir /war-contents
RUN unzip kitodo-3.war -d /war-contents

# adjust elasticsearch config
RUN sed -i "s/^elasticsearch\.host=.*/elasticsearch.host=elasticsearch/g" /war-contents/WEB-INF/classes/kitodo_config.properties
RUN sed -i "s/^elasticsearch\.port=.*/elasticsearch.port=9200/g" /war-contents/WEB-INF/classes/kitodo_config.properties

# adjust database connection settings
RUN hibernate_cfg=/war-contents/WEB-INF/classes/hibernate.cfg.xml \
 && cp $hibernate_cfg ./i.xml && \
	xmlstarlet ed \
      -u "/hibernate-configuration/session-factory/property[@name='hibernate.connection.url']" \
      -v "jdbc:mysql://${MYSQL_HOST}/${MYSQL_DATABASE}?useSSL=false" \
      i.xml > o.xml \
 && mv o.xml i.xml \
 && xmlstarlet ed \
      -u "/hibernate-configuration/session-factory/property[@name='hibernate.connection.username']" \
      -v "${MYSQL_USER}" \
      i.xml > o.xml \
 && mv o.xml i.xml \
 && xmlstarlet ed \
      -u "/hibernate-configuration/session-factory/property[@name='hibernate.connection.password']" \
      -v "${MYSQL_PASSWORD}" \
      i.xml > o.xml \
 && rm i.xml \
 && mv o.xml $hibernate_cfg

# set up and start the tomcat
FROM tomcat:9-jdk8


COPY --from=build  /kitodo/ /usr/local/kitodo/
COPY --from=build  /war-contents/ /usr/local/tomcat/webapps/kitodo/

CMD ["catalina.sh", "run"]