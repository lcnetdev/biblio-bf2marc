use 5.010000;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Biblio::BF2MARC',
    license             => 'unrestricted',
    dist_author         => q{Wayne Schneider <wayne@indexdata.com>},
    dist_version_from   => 'lib/Biblio/BF2MARC.pm',
    release_status      => 'unstable',
    configure_requires => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More' => '0',
        'XML::LibXSLT' => '1',
        'XML::LibXML' => '2'
    },
    requires => {
        'RDF::Trine' => '1.014',
        'RDF::Query' => '2.9',
        'XML::LibXSLT' => '1.85',
        'XML::LibXML' => '2',
        'File::ShareDir' => '0'
    },
    add_to_cleanup     => [ 'Biblio-BF2MARC-*', 'lib/Biblio/BF2MARC/bibframe2marc.xsl' ],
);
$builder->add_build_element('xsl');
$builder->create_build_script();
