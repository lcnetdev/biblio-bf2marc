# Build base container
FROM ubuntu:18.04
MAINTAINER Wayne Schneider <wayne@indexdata.com>
ENV DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8 LC_ALL=C.UTF-8 LANGUAGE=en_US.UTF-8
RUN apt-get -q update && \
    apt-get -qy upgrade && \
    apt-get -qy dist-upgrade && \
    apt-get -qy install \
      perl \
      build-essential \
      cpanminus

# Install requirements from apt
RUN apt-get -qy install \
      librdf-trine-perl \
      librdf-query-perl \
      libxml-libxslt-perl \
      libmodule-build-perl \
      libfile-share-perl

# Install requirements from CPAN
RUN cpanm MARC::Record MARC::File::XML

# Install and build bibframe2marc
COPY . /opt/biblio-bf2marc
WORKDIR /opt/biblio-bf2marc
RUN perl Build.PL && \
    ./Build clean && \
    ./Build && \
    ./Build test && \
    ./Build install

ENTRYPOINT [ "/usr/local/bin/bibframe2marc" ]

# Clean up container
RUN [ "apt-get", "clean" ]
RUN [ "rm", "-rf", "/var/lib/apt/lists/*", "/tmp/*", "/var/tmp/*" ]
