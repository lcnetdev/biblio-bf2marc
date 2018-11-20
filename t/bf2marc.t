#!perl -T
use Test::More tests => 19;

use 5.01;
use strict;
use warnings;

use Biblio::BF2MARC;
use RDF::Trine;

# Set up the model
my $model = RDF::Trine::Model->temporary_model;
my $parser = RDF::Trine::Parser->new('rdfxml');
$parser->parse_file_into_model(undef, 't/data/ole-lukoie.xml', $model);
$parser->parse_file_into_model(undef, 't/data/snoopy.xml', $model);

diag("Testing Biblio::BF2MARC object creation and methods");

my $bf2marc;

# Object creation
$bf2marc = new_ok('Biblio::BF2MARC');

# Object create with non-model should croak
eval { $bf2marc = new Biblio::BF2MARC ('oops') };
if ($@) {
    ok(1, 'constructor croak with invalid parameter');
} else {
    ok(0, 'constructor croak with invalid parameter');
}

# Set the model
$bf2marc = new Biblio::BF2MARC;
$bf2marc->model($model);
is_deeply( $model, $bf2marc->model, 'set model' );

# Object create with model argument
$bf2marc = Biblio::BF2MARC->new($model);
is_deeply( $model, $bf2marc->model, 'create object with model' );

# Descriptions
my $descriptions = $bf2marc->descriptions;
is( @{$descriptions}, 2, 'retrieve descriptions from model' );
isa_ok( $$descriptions[0], 'Biblio::BF2MARC::Description', 'test description object' );

# Create a description hash so I know which one I'm dealing with
my %descriptions;
foreach my $description (@{$descriptions}) {
    if ($description->work->uri eq 'http://bibframe.example.org/5226#Work') {
        $descriptions{snoopy} = $description;
    } elsif ($description->work->uri eq 'http://example.org/13600108#Work') {
        $descriptions{ole_lukoie} = $description;
    } else {
        diag "Unknown description for " . $description->work->uri;
    }
}

# Helper methods for building RDF/XML
# _build_XML_element
my $node = RDF::Trine::iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
my $element = $bf2marc->_build_XML_element($node);
isa_ok( $element, 'XML::LibXML::Element', 'test XML element' );
is( $element->nodeName, 'rdf:type', '_build_XML_element nodename' );

# _build_property
my $statement = RDF::Trine::Statement->new(
                                           RDF::Trine::iri('http://example.org/12345'),
                                           RDF::Trine::iri('http://www.w3.org/2000/01/rdf-schema#label'),
                                           RDF::Trine::literal('Snoopy on wheels /')
                                          );
my $literal_prop = $bf2marc->_build_property($statement);
isa_ok( $literal_prop, 'XML::LibXML::Element', 'test property element object' );
is( $literal_prop->textContent, 'Snoopy on wheels /', 'literal property value' );

TODO: {
    local $TODO = 'Set up tests for literal datatype and language';

    ok(0, 'set datatype on literal');
    ok(0, 'set language on literal');
};

$statement = RDF::Trine::Statement->new(
                                        RDF::Trine::iri('http://example.org/12345'),
                                        RDF::Trine::iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
                                        RDF::Trine::iri('http://id.loc.gov/ontologies/bibframe/Text')
                                       );

my $resource_prop = $bf2marc->_build_property($statement);
my $resource_attr = $resource_prop->getAttribute('rdf:resource');
is( $resource_attr, 'http://id.loc.gov/ontologies/bibframe/Text', 'set rdf:resource for property' );

$statement = RDF::Trine::Statement->new(
                                        RDF::Trine::iri('http://example.org/13600108#Work'),
                                        RDF::Trine::iri('http://id.loc.gov/ontologies/bibframe/genreForm'),
                                        RDF::Trine::iri('http://id.loc.gov/vocabulary/marcgt/fic')
                                       );
my $striped_prop = $bf2marc->_build_property($statement);
is( $striped_prop->firstChild->firstChild->textContent, 'fiction', 'build striped property element' );

$statement = RDF::Trine::Statement->new(
                                        RDF::Trine::iri('http://example.org/13600108#Instance'),
                                        RDF::Trine::iri('http://id.loc.gov/ontologies/bibframe/hasItem'),
                                        RDF::Trine::iri('http://example.org/13600108#Item050-11')
                                       );
my $recursive_prop = $bf2marc->_build_property($statement);

TODO: {
    local $TODO = 'Set up tests to dereferences madsrdf IRIs';

    ok(0, 'dereference madsrdf IRI');
};

# Striped RDF/XML
my $xml = $bf2marc->to_striped_xml($descriptions{ole_lukoie});

isa_ok( $xml, 'XML::LibXML::Document', 'test striped RDF/XML object' );

my $xpc = XML::LibXML::XPathContext->new($xml);
$xpc->registerNs('bf', 'http://id.loc.gov/ontologies/bibframe/');
$xpc->registerNs('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#');
my $work_list = $xpc->findnodes('/rdf:RDF/bf:Work');
my $instance_list = $xpc->findnodes('/rdf:RDF/bf:Instance');
is ($work_list->size(), 1, 'single top-level bf:Work');
is ($instance_list->size(), 1, 'single top-level bf:Instance');

# XSLT processing
TODO: {
    local $TODO = 'Set up tests for XSLT processing of striped RDF/XML';

    ok(0, 'test MARCXML object');
};
