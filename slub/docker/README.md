# Kitodo.Production Docker Documentation

With the docker image provided, Kitodo.Production can be started in no time at all. A MySQL/MariaDB database and ElasticSearch must be present to start the application. There is also a docker-compose file for a quick start.

## Using Docker Image

The image contains the WAR, the database file and the config modules of the corresponding release for the Docker image tag.

```
docker pull markusweigelt/kitodo-production:TAG
```

### Environment Variables

| Name | Default | Description
| --- | --- | --- |
| KITODO_DB_HOST | localhost | Host of MySQL or MariaDB database |
| KITODO_DB_PORT | 3306 | Port of MySQL or MariaDB database |
| KITODO_DB_NAME | kitodo | Name of database used by Kitodo.Productions |
| KITODO_DB_USER | kitodo | Username to access database |
| KITODO_DB_PASSWORD | kitodo | Password used by username to access database |
| KITODO_ES_HOST | localhost | Host of Elasticsearch |

### Targets

| Name | Path | Description
| --- | --- | --- |
| Config Modules | /usr/local/kitodo | If the directory is mounted or bind per volume and is empty, then it will be prefilled with the provided config modules of the release. |

### Database 

If the database is still empty, it will be initialized with the database script from the release.

## Using Docker Compose Example

### Prerequisites

Install Docker Engine
https://docs.docker.com/get-docker/

Install Docker Compose
https://docs.docker.com/compose/install/

Go to the directory where you've put docker-compose.yml.

### Starting 
```
docker-compose up -d
```

### Stopping 
```
docker-compose stop
```

### View Logs 
```
docker-compose logs -f
```
