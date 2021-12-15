# Docker

## Prerequisites

### Install Docker Engine
https://docs.docker.com/get-docker/

### Install Docker Compose
https://docs.docker.com/compose/install/

## Latest version

Start the container for the current project via the CLI in this folder.

```
docker-compose up -d
```

Data of the container volumes are stored under ./data/{PROJEKTNAME}/services/.


## Legacy versions

For example, older project versions contain an older version of Elastic Search.

```
docker-compose --env-file=.env.kitodo-3.3 up -d
```