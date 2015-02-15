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

    $ cd ../api-doc/raml
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

To download a copy of the version-specific RAML files, provide another volume
to the docker container to be mounted at `/out`.  For instance, to generate
the files in the directory `/tmp/raml.out`:

    $ OUTDIR=/tmp/raml.out
    $ mkdir "$OUTDIR"
    $ docker run -it --rm -v "$PWD":/raml -v "$OUTDIR":/out -p 9000:9000 venkytv/covisint-api-console

## Building the docker image

You should be able to just pull the docker image from Docker Hub, but in case
you want to build the image locally, do the following:

    $ cd docker
    $ docker build .  # Don't miss the "." at the end

