# Kitodo Production Dockerfile for building Kitodo

FROM ubuntu AS build
RUN apt-get update && apt-get -y install bash curl  mysql-client openjdk-8-jdk unzip zip && apt-get -y install maven
WORKDIR /build

COPY build-kitodo.entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

# cf. https://stackoverflow.com/a/40312311
ENTRYPOINT ["/entrypoint.sh"]
# empty command, we pass the run command in to the entrypoint as parameters
CMD []

