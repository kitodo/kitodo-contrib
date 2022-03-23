FROM tomcat:9.0.56-jre11-openjdk-slim

LABEL maintainer "Markus Weigelt <Markus.Weigelt@slub-dresden.de>"

ARG KITODO_VERSION=3.4.1
ARG KITODO_WAR_NAME=kitodo-3.4.1
ARG KITODO_SQL_NAME=kitodo_3-4-1
ARG KITODO_CONFIG_MODULES_NAME=kitodo_3-4-1_config_modules

ENV JAVA_OPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xmx4G -XX:MaxPermSize=256m"
ENV KITODO_DB_HOST=localhost
ENV KITODO_DB_PORT=3306
ENV KITODO_DB_NAME=kitodo
ENV KITODO_DB_USER=kitodo
ENV KITODO_DB_PASSWORD=kitodo
ENV KITODO_ES_HOST=localhost
ENV KITODO_MQ_HOST=localhost
ENV KITODO_MQ_PORT=61616

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

RUN apt-get update && \
    apt-get install -y \
	apt-utils \
	net-tools \
	nano \
	unzip \
	dos2unix \
	mariadb-client \
	openssh-client \
	imagemagick \
	rsyslog \
	--no-install-recommends

ADD https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-${KITODO_VERSION}/${KITODO_WAR_NAME}.war /tmp/kitodo/

ADD https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-${KITODO_VERSION}/${KITODO_CONFIG_MODULES_NAME}.zip /tmp/kitodo/

ADD https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-${KITODO_VERSION}/${KITODO_SQL_NAME}.sql /tmp/kitodo/

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /tmp/wait-for-it.sh

RUN	unzip /tmp/kitodo/${KITODO_CONFIG_MODULES_NAME}.zip -x ${KITODO_CONFIG_MODULES_NAME}/scripts/*.bat -d /tmp/kitodo/ && \
	mv /tmp/kitodo/${KITODO_CONFIG_MODULES_NAME} /tmp/kitodo/kitodo-config-modules/ && \
	unzip /tmp/kitodo/${KITODO_WAR_NAME}.war -d /tmp/kitodo/kitodo-war && \
	mv /tmp/kitodo/kitodo-war  ${CATALINA_HOME}/webapps/kitodo/ && \
	mv /tmp/kitodo/${KITODO_SQL_NAME}.sql /tmp/kitodo/kitodo.sql && \
	rm -f /tmp/kitodo/${KITODO_WAR_NAME}.war && \
	rm -f /tmp/kitodo/kitodo-config-modules.zip && \
	chmod +x /tmp/wait-for-it.sh && \
	chmod +x /docker-entrypoint.sh && \
	dos2unix /tmp/kitodo/kitodo-config-modules/scripts/*.sh && \
	chmod 544 /tmp/kitodo/kitodo-config-modules/scripts/*.sh && \
	mkdir /.ssh
	
EXPOSE 8080

# make apt run interactive during logins
ENV DEBIAN_FRONTEND teletype
