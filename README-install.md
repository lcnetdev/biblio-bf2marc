# Installation instructions for Biblio::BF2MARC

The Biblio::BF2MARC module has a significant number of dependencies, many of which can be satisfied by distribution packages for major Linux distributions. Here are installation instructions for Debian Buster, Ubuntu Bionic, RHEL/CentOS 7/8, and Amazon Linux 2.

* [Debian Buster/Ubuntu Bionic](#debian-buster-ubuntu-bionic)
* [Ubuntu Bionic](#ubuntu-bionic)
* [RHEL/CentOS 7](#rhel-centos-7)
* [RHEL/CentOS 8](#rhel-centos-8)
* [Amazon Linux 2](#amazon-linux-2)

## Debian Buster/Ubuntu Bionic

1. Install prerequisite packages

```
sudo apt-get update -q
sudo apt-get install -qy git librdf-trine-perl librdf-query-perl libxml-libxslt-perl libmodule-build-perl libfile-share-perl cpanminus perl-doc
sudo cpanm MARC::Record MARC::File::XML
```

2. Clone repository into working directory

```
git clone --recursive https://github.com/lcnetdev/biblio-bf2marc
```

3. Build module and install library and `bibframe2marc` command line

```
cd biblio-bf2marc
perl Build.PL
./Build
./Build test
sudo ./Build install
```

## RHEL/CentOS 7

1. Install prerequisite packages

```
sudo yum install gcc git libxslt-devel libxml2-devel perl-App-cpanminus perl-Test-Simple perl-XML-LibXSLT perl-Module-Build perl-Test-Deep perl-Test-Exception perl-DBI perl-DBD-SQLite perl-JSON perl-Text-CSV_XS perl-Class-Load perl-DateTime perl-Params-Validate perl-DateTime-Locale perl-DateTime-TimeZone perl-Module-Pluggable perl-Test-Warn perl-Parse-RecDescent perl-File-ShareDir
sudo cpanm XML::LibXSLT RDF::Trine RDF::Query MARC::Record MARC::File::XML File::Share
```

2. Clone repository into working directory

```
git clone --recursive https://github.com/lcnetdev/biblio-bf2marc
```

3. Build module and install library and `bibframe2marc` command line

```
cd biblio-bf2marc
perl Build.PL
./Build
./Build test
sudo ./Build install
```

## RHEL/CentOS 8

1. Install prerequisite packages

```
sudo yum install gcc git libxslt-devel libxml2-devel perl-App-cpanminus perl-XML-LibXML perl-Test-Simple perl-Module-Build perl-DBI perl-DBD-SQLite perl-JSON perl-Module-Pluggable perl-File-ShareDir
sudo cpanm XML::LibXSLT RDF::Trine RDF::Query MARC::Record MARC::File::XML File::Share
```

2. Clone repository into working directory

```
git clone --recursive https://github.com/lcnetdev/biblio-bf2marc
```

3. Build module and install library and `bibframe2marc` command line

```
cd biblio-bf2marc
perl Build.PL
./Build
./Build test
sudo ./Build install
```

## Amazon Linux 2

Same as RHEL 7!

1. Install prerequisite packages

```
sudo yum install gcc git libxslt-devel libxml2-devel perl-App-cpanminus perl-Test-Simple perl-XML-LibXSLT perl-Module-Build perl-Test-Deep perl-Test-Exception perl-DBI perl-DBD-SQLite perl-JSON perl-Text-CSV_XS perl-Class-Load perl-DateTime perl-Params-Validate perl-DateTime-Locale perl-DateTime-TimeZone perl-Module-Pluggable perl-Test-Warn perl-Parse-RecDescent perl-File-ShareDir
sudo cpanm XML::LibXSLT RDF::Trine RDF::Query MARC::Record MARC::File::XML File::Share
```

2. Clone repository into working directory

```
git clone --recursive https://github.com/lcnetdev/biblio-bf2marc
```

3. Build module and install library and `bibframe2marc` command line

```
cd biblio-bf2marc
perl Build.PL
./Build
./Build test
sudo ./Build install
```
