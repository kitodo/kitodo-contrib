# MariaDB Dockerfile for running Kitodo

FROM mariadb
ARG KITODO_BUILD

ENV KITODO_BUILD $KITODO_BUILD
# get the db dump and put it in the autoload dir
COPY builds/${KITODO_BUILD}/kitodo-3.sql /docker-entrypoint-initdb.d/

# add config for InnoDB
COPY mariadb.kitodo.cnf /etc/mysql/conf.d/kitodo.cnf
