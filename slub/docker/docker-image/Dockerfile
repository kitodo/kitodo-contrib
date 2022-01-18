FROM tomcat:9.0.56-jre11-openjdk-slim

LABEL maintainer "Markus Weigelt <Markus.Weigelt@slub-dresden.de>"

ENV JAVA_OPTS="-Djava.awt.headless=true -XX:+UseConcMarkSweepGC -Xmx4G -XX:MaxPermSize=256m"
ENV KITODO_DB_HOST=localhost
ENV KITODO_DB_PORT=3306
ENV KITODO_DB_NAME=kitodo
ENV KITODO_DB_USER=kitodo
ENV KITODO_DB_PASSWORD=kitodo
ENV KITODO_ES_HOST=localhost

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

RUN apt-get update && apt-get install -y \
	wget \
	net-tools \
	nano \
	unzip \
	mariadb-client \
	--no-install-recommends

ADD https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-3.4.1/kitodo-3.4.1.war /tmp/kitodo/

ADD https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-3.4.1/kitodo_3-4-1_config_modules.zip /tmp/kitodo/

ADD https://github.com/kitodo/kitodo-production/releases/download/kitodo-production-3.4.1/kitodo_3-4-1.sql /tmp/kitodo/kitodo_3-4-1.sql

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /tmp/wait-for-it.sh

RUN	unzip /tmp/kitodo/kitodo_3-4-1_config_modules.zip -x kitodo_3-4-1_config_modules/scripts/*.bat -d /tmp/kitodo/ && \
	unzip /tmp/kitodo/kitodo-3.4.1.war -d /tmp/kitodo/kitodo-3.4.1-war && \
	mv /tmp/kitodo/kitodo-3.4.1-war ${CATALINA_HOME}/webapps/kitodo && \
	rm -f /tmp/kitodo/kitodo-3.4.1.war && \
	rm -f /tmp/kitodo/kitodo_3-4-1_config_modules.zip && \
	chmod +x /tmp/wait-for-it.sh && \
	chmod +x /docker-entrypoint.sh
	
EXPOSE 8080

CMD ["catalina.sh", "run"]