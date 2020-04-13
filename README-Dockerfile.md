# Running bibframe2marc as a container

A [Dockerfile](Dockerfile) is included in this distribution to allow the `bibframe2marc` utility to be built into a Docker image and run as a container for easier portability.

## Building the image

From the root of the distribution, build the image with `docker build -t bibframe2marc .`.

## Running the container

You can run the container, piping RDF input to STDIN and attaching to the containers STDOUT and STDERR like this:

    docker run -i --rm bibframe2marc < test.rdf.xml

## Mounting a configuration file

The `bibframe2marc` utility can use a configuration file in JSON format to configure dereferencing the URIs of RDF subjects and objects, adding additional triples to the model, and using that data in BIBFRAME to MARC conversion. You can mount a configuration file on the container and instruct `bibframe2marc` to use it with the `--config` option:

    docker run -i --rm -v "$(pwd)"/config.json:/tmp/config.json bibframe2marc --config /tmp/config.json < test.rdf.xml

You can also use this strategy to mount a local directory for reading and writing input and output files using the `--input` and `--output` options. See the Docker documentation on [bind mounts](https://docs.docker.com/storage/bind-mounts/) for more details.

## `bibframe2marc` documentation

If you've built the Docker image, the easiest way to see the command line documentation is to run `bibframe2marc` with the `--help` command line switch:

    docker run --rm bibframe2marc --help
