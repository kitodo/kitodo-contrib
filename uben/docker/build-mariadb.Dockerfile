# MariaDB Dockerfile

FROM mariadb

# add config for InnoDB
COPY mariadb.kitodo.cnf /etc/mysql/conf.d/kitodo.cnf
