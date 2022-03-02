# Using schemas if log.gov is down

## Prerequisites

Install Docker Engine
https://docs.docker.com/get-docker/

Install Docker Compose
https://docs.docker.com/compose/install/

Go to the directory where you've put docker-compose.yml.

## HTTP Server

### Starting 
```
docker-compose up -d
```

### Stopping 
```
docker-compose stop
```

## Overwrite Host

Add the url www.log.gov and the IP of http server (default 127.0.0.1) to your host configuration file.
