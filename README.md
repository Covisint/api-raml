# api-raml
An API documentation build and browse tool which uses Docker and Mulesoft's api-console.
This uses a custom RAML reader (it is too basic to be called a parser) and a
Dockerfile to build and run a custom api-console which can be used to explore
the generated documentation.

## Prerequisites

1. [Docker](https://www.docker.com/) (Or Boot2Docker for [Mac](https://docs.docker.com/installation/mac/) or [Windows](https://docs.docker.com/installation/windows/))

## Usage

To generate version-specific documentation and to run api-console to browse
them, run the following from the directory containing the RAML files you want to
use.

    $ docker pull venkytv/covisint-api-console
    $ docker run -it --rm -v "$PWD":/raml -p 9000:9000 venkytv/covisint-api-console

_The first time you run the `docker run` command, it will download a bunch of
container layers.  This might take some time.  These layers get cached locally,
so subsequent runs should be much faster._

Now, browse the generated documentation on your local machine.

* On Linux, browse to [http://localhost:9000/raml](http://localhost:9000/raml)
* On Mac and Windows, use http://192.168.59.103:9000/raml

_In case you are are unable to access the api-console on Mac or Windows, make
sure that the VM IP has not changed using the `boot2docker` command._
```
    $ boot2docker ip
    192.168.59.103
```

### Generating version-specific RAML files

To just generate version-specific RAML files without launching api-console, pass
the "genraml" argument to the docker command line.  This will create a
`dist/raml/versions` directory within your current directory and store the RAML files
within versioned directories there.  It will also create a `dist/raml/releases`
directory and copy the RAML files into release-specific subdirectories.

    $ docker run --rm -v "$PWD":/raml venkytv/covisint-api-console genraml

__IMPORTANT__: Release information is picked up from the
[docker/release-manifest.yml](docker/release-manifest.yml) file.  If this
information is changed, the docker image needs to be rebuilt and pushed into
Docker Hub.  See below for instructions on building the Docker image.

### Generating CSV descriptions of RAML files

To just generate CSV descriptions of RAML files without launching api-console,
pass the "gencsv" argument to the docker command line.  This will create a
"dist/csv" directory within your current directory and store the CSV files
within.

    $ docker run --rm -v "$PWD":/raml venkytv/covisint-api-console gencsv

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

To get a shell within the docker container, pass the "bash" argument to the
command line:

    $ docker run -it --rm -v "$PWD":/raml -p 9000:9000 venkytv/covisint-api-console bash

## Building the docker image

You should be able to just pull the docker image from Docker Hub, but in case
you want to build the image locally, do the following:

    $ cd docker
    $ docker build .  # Don't miss the "." at the end

