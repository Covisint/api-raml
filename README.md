# api-raml
An API documentation build and browse tool which uses Docker and Mulesoft's api-console.
This uses a custom RAML reader (it is too basic to be called a parser) and a
Dockerfile to build and run a custom api-console which can be used to explore
the generated documentation.

## Prerequisites

1. [Docker](https://www.docker.com/) (Or Boot2Docker for [Mac](https://docs.docker.com/installation/mac/) or [Windows](https://docs.docker.com/installation/windows/))

## Usage

(Note: For a simpler alternative, have a look at the "Simplified usage" section below.)

To generate version-specific documentation and to run api-console to browse
them, run the following from the directory containing the RAML files you want to
use (e.g. cd into ..../git/api-doc/raml).
```
    $ docker pull venkytv/covisint-api-console
    $ docker run -it --rm -v "$PWD":/raml -p 9000:9000 venkytv/covisint-api-console
```

_The first time you run the `docker run` command, it will download a bunch of
container layers.  This might take some time.  These layers get cached locally,
so subsequent runs should be much faster._

Now, browse the generated documentation on your local machine.

* On Linux, browse to [http://localhost:9000/raml](http://localhost:9000/raml)
* On Mac and Windows, use http://192.168.99.100:9000/raml

_In case you are are unable to access the api-console on Mac or Windows, make
sure that the VM IP has not changed using the `boot2docker` command_
```
    $ boot2docker ip
    192.168.59.103
```

_boot2Docker has been deprecated.  You are probably using docker-machine now so use:_
```
   $ docker-machine ls
   NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER    ERRORS
   default   -        virtualbox   Running   tcp://192.168.99.100:2376           v1.10.3
```
and grab the IP from the URL column.

### Generating version-specific RAML files

To just generate version-specific RAML files without launching api-console, pass
the "genraml" argument to the docker command line.  This will create a
`dist/raml/versions` directory within your current directory and store the RAML files
within versioned directories there.

    $ docker run --rm -v "$PWD":/raml venkytv/covisint-api-console genraml

If the current directory contains a `release-manifest.yml` file
([example](https://github.com/Covisint/api-doc/blob/master/raml/release-manifest.yml)),
the command will also create a `dist/raml/releases` directory and copy the RAML
files into release-specific subdirectories.

### Generating CSV descriptions of RAML files

To just generate CSV descriptions of RAML files without launching api-console,
pass the "gencsv" argument to the docker command line.  This will create a
"dist/csv" directory within your current directory and store the CSV files
within.

    $ docker run --rm -v "$PWD":/raml venkytv/covisint-api-console gencsv

### Generating the api-console war file

To generate a war file for deployment into the developer portal, pass the
"genwar" argument to the docker command line.  This will create an
"api-console.war" file under the "dist" directory within your current directory.

    $ docker run --rm -v "$PWD":/raml venkytv/covisint-api-console genwar

### Advanced

To override the hostname part of the baseUri in the generated RAML files, set
the `baseuri` variable.

    $ docker run --rm -v "$PWD":/raml \
      -e "baseuri=example.com" venkytv/covisint-api-console genraml

By default, the tool collapses empty nodes in the filtered RAML files.  To
disable this behaviour, set the `collapse_empty` variable to false for the
docker run.

    $ docker run -it --rm -v "$PWD":/raml -p 9000:9000 \
      -e "collapse_empty=false" venkytv/covisint-api-console

### Debugging

To drop into a shell within the docker container after generating the custom
RAML files, pass the "bash" argument to the command line:

    $ docker run -it --rm -v "$PWD":/raml -p 9000:9000 venkytv/covisint-api-console bash

If there is a problem generating the custom RAMLs itself, the previous command
might fail.  In that case, do the following:

    $ docker run -it --rm -v "$PWD":/raml -p 9000:9000 \
      --entrypoint=bash venkytv/covisint-api-console --

This will drop you into a shell inside the container.  Now, you can run the
parser script manually by hand to debug the issue:

    # /api-console/ramlparser.rb /raml /tmp /raml/release-manifest.yml

The parser and all the supporting scripts are inside the `/api-console`
directory.  The container does not include an editor; so, if you want to edit
any of the files, you need to install an editor:

    # apt-get install vim

**REMEMBER**: Any changes you make within the container are lost the moment you
exit the shell.  The container is re-created afresh every time you do a "docker
run" and removed as soon as the command exits.  If you make any changes to the
scripts under `/api-console`, make sure the changes are also made in the
corresponding scripts in the `api-raml` git repo under the `docker/` directory.

## Simplified usage

The [util/api-console](util/api-console) script provides a simpler way to invoke
all the above commands.  It requires `ruby` and the `colorize` gem (`gem install
colorize`).

Examples:

Bring up the api-console using the RAML in the api-doc submodule:

    $ util/api-console

Use RAML files located in a different directory:

    $ util/api-console ~/my-raml-files

Point the api-console to a specific Apigee instance/environment:

    $ util/api-console -l     # List available Apigee environments
    $ util/api-console prod   # Point the api-console to the production instance

Bring up the api-console on a specific port (default: 9000):

    $ util/api-console 9000

Do a `docker pull` before execution:

    $ util/api-console -p

Generate the api-console war file:

    $ util/api-console genwar

Drop into a shell inside the docker container:

    $ util/api-console bash

Multiple options:

    $ util/api-console prod genwar  # Generate war file for production instance
    $ util/api-console -p ~/my-raml-files rnd 9002  # Pull docker image, use custom RAML files, map to port 9002

Usage help:

    $ util/api-console -h

## Building the docker image

You should be able to just pull the docker image from Docker Hub, but in case
you want to build the image locally, do the following:

    $ cd docker
    $ docker build .  # Don't miss the "." at the end

