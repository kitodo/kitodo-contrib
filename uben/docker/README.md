kitodo-docker
=============

Docker configurations for testing different versions and snapshots of Kitodo Production.

This uses docker-compose. There is a docker service for building Kitodo and one for running Kitodo.

The basic idea is that the building service produces the installation files (war, zip, sql, and 
config) for a specific commit/snapshot of Kitodo.

The run service builds a set of docker images with elastic search, mysql and tomcat using a set of
installation files. These images can then be run to function as one Kitodo installation.

The building service is based on the manual on how to set up a development version of Kitodo:
https://kitodo-production.readthedocs.io/en/latest/developer/gettingstarted/development-version/


Building Kitodo
---------------


If not already done, build the Kitodo Builder with docker-compose:
```
$ docker-compose build build-kitodo
```

For building a set of installation files, do:
```
$ docker-compose run build-kitodo <COMMIT> <SOURCE_URL>
```

You must specify either `<COMMIT>` or `<SOURCE_URL>`.
`<SOURCE_URL>` identifies from where the Kitodo source code will be downloaded.
If `<SOURCE_URL>` is omitted, the URL is constructed so that the standard kitodo repository on GitHub is taken.
You may either specify a complete URL pointing to a ZIP file or just the URL of the repository, eg.
`https://github.com/kitodo/kitodo-production`.

`<COMMIT>` is a Git commit hash. If specified, the source from the commit is taken.
If omitted, `master` is assumed.
If no URL or a base URL is given, then the download URL is constructed using `<COMMIT>`.
If a complete URL is given, however, the source from the URL is taken nonetheless.

Examples:
- For the latest commit type
  ```
  $docker-compose run build-kitodo master
  ```

- For a specific commit that is not in the standard Kitodo repo, type
  ```
  $docker-compose run build-kitodo 8aaa81584c https://github.com/mnscholz/kitodo-production/
  ```
  

The builder will create a directory named with the Kitodo API version and commit hash in
the `builds` directory. There, it places the files needed for deploying Kitodo Production:
- `kitodo-3.war`: The WAR file
- `kitodo-3-config.zip`: The subdirectories in `/usr/local/kitodo`
- `kitodo-3.sql`: The database dump
- `kitodo-3-modules.zip`: The modules
 

Running Kitodo
--------------

After building a Kitodo version one can build and run a Kitodo server with the following Docker service:

First, build it with
```
$ docker-compose build run-kitodo
```

then run it with
```
$ docker-compose build --build-arg KITODO_BUILD=<DIR_IN_BUILDS> run-kitodo
```

`<DIR_IN_BUILDS>` must be a directory in the `builds` directory in which the installaion files reside.

Example:
```
$ docker-compose build --build-arg KITODO_BUILD=3.2.0-SNAPSHOT-142f3da run-kitodo
```

After building, run the image:
```
$ docker-compose up run-kitodo
```

Kitodo should now be available on `localhost:8089`.







