#!perl -T
use Test::More tests => 24;

use 5.01;
use strict;
use warnings;

use Biblio::BF2MARC;
use RDF::Trine;
use XML::LibXML;
use Net::Ping;

# Set up the model
my $model = RDF::Trine::Model->temporary_model;
my $parser = RDF::Trine::Parser->new('rdfxml');
$parser->parse_file_into_model(undef, 't/data/ole-lukoie.xml', $model);
$parser->parse_file_into_model(undef, 't/data/snoopy.xml', $model);

diag("Testing Biblio::BF2MARC object creation and methods");

my $bf2marc;

# Object creation
$bf2marc = new_ok('Biblio::BF2MARC');
isa_ok(
       $$bf2marc{stylesheet},
       'XML::LibXSLT::StylesheetWrapper',
       'test converter stylesheet'
      );

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

# Set the stylesheet manually
my $style_doc = XML::LibXML->load_xml(string => <<'END');
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"/>
END
is( eval { $bf2marc->stylesheet($style_doc) }, 1, 'set stylesheet' );

# Descriptions
$bf2marc = Biblio::BF2MARC->new($model);
my @descriptions = $bf2marc->descriptions;
is( @descriptions, 2, 'retrieve descriptions from model' );
isa_ok( $descriptions[0], 'Biblio::BF2MARC::Description', 'test description object' );

# Create a description hash so I know which one I'm dealing with
my %descriptions;
foreach my $description (@descriptions) {
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

$statement = RDF::Trine::Statement->new(
                                        RDF::Trine::iri('http://example.org/12345'),
                                        RDF::Trine::iri('http://id.loc.gov/ontologies/bibframe/creationDate'),
                                        RDF::Trine::literal('2004-05-20', undef, 'http://www.w3.org/2001/XMLSchema#date')
                                       );
$literal_prop = $bf2marc->_build_property($statement);
is(
   $literal_prop->getAttribute('rdf:datatype'),
   'http://www.w3.org/2001/XMLSchema#date',
   'literal with datatype sets rdf:datatype'
  );

$statement = RDF::Trine::Statement->new(
                                        RDF::Trine::iri('http://example.org/12345'),
                                        RDF::Trine::iri('http://www.w3.org/2000/01/rdf-schema#label'),
                                        RDF::Trine::literal('Snoopy auf Raedern', 'de')
                                       );
$literal_prop = $bf2marc->_build_property($statement);
is( $literal_prop->getAttribute('xml:lang'), 'de', 'literal with language sets xml:lang' );

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

my $ua = RDF::Trine::default_useragent;
my $test_id = $ua->get('http://id.loc.gov');

SKIP: {
    skip 'id.loc.gov service not available', 1 unless $test_id->is_success;

    my $agent_statement = RDF::Trine::Statement->new(
                                                     RDF::Trine::iri('http://id.loc.gov/authorities/names/n78095332'),
                                                     RDF::Trine::iri('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
                                                     RDF::Trine::iri('http://id.loc.gov/ontologies/bibframe/Agent')
                                                    );
    my $linked_statement = RDF::Trine::Statement->new(
                                                      RDF::Trine::blank('12345'),
                                                      RDF::Trine::iri('http://id.loc.gov/ontologies/bibframe/agent'),
                                                      RDF::Trine::iri('http://id.loc.gov/authorities/names/n78095332')
                                                     );
    my $deref_model = RDF::Trine::Model->temporary_model;
    $deref_model->add_statement($agent_statement);
    $deref_model->add_statement($linked_statement);
    my $deref_bf2marc = Biblio::BF2MARC->new($deref_model);
    my $deref_prop = $deref_bf2marc->_build_property(
                                                     $linked_statement,
                                                     { dereference => {
                                                                       'http://id.loc.gov/ontologies/bibframe/Agent' =>
                                                                       ['http://id.loc.gov']
                                                                      }
                                                     }
                                                    );
    my $xpc = XML::LibXML::XPathContext->new($deref_prop);
    $xpc->registerNs('bf', 'http://id.loc.gov/ontologies/bibframe/');
    $xpc->registerNs('madsrdf', 'http://www.loc.gov/mads/rdf/v1#');
    my $label = eval { $xpc->findvalue('bf:Agent/madsrdf:authoritativeLabel') };
    warn $@ if ($@);
    is(
       $label,
       'Shakespeare, William, 1564-1616',
       'dereference madsrdf IRI'
      );
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
is (
    $xpc->findvalue('/rdf:RDF/bf:Work/bf:adminMetadata/bf:AdminMetadata/bf:identifiedBy/bf:Local/rdf:value'),
    '13600108',
    'striped path to property'
   );

SKIP: {
    skip 'id.loc.gov service not available', 1 unless $test_id->is_success;
    my $xml = $bf2marc->to_striped_xml(
                                       $descriptions{snoopy},
                                       { dereference => {
                                                         'http://id.loc.gov/ontologies/bibframe/Agent' =>
                                                         ['http://id.loc.gov'],
                                                         'http://id.loc.gov/ontologies/bibframe/Topic' =>
                                                         ['http://id.loc.gov']
                                                        }
                                       }
                                      );
    my $xpc = XML::LibXML::XPathContext->new($xml);
    $xpc->registerNs('bf', 'http://id.loc.gov/ontologies/bibframe/');
    $xpc->registerNs('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#');
    $xpc->registerNs('madsrdf', 'http://www.loc.gov/mads/rdf/v1#');
    my $adminMetadata = eval { $xpc->findnodes('//madsrdf:adminMetadata') };
    warn $@ if ($@);
    my $size = eval { $adminMetadata->size };
    if ($@) {
        warn $@;
        $size = 0;
    }
    cmp_ok(
           $size,
           '>',
           0,
           'dereference madsrdf IRI'
          );
};

# XSLT processing - convert to MARCXML
my $marcxml = $bf2marc->convert($xml);
isa_ok( $marcxml, 'XML::LibXML::Document', 'test MARCXML object' );
my $record = $marcxml->documentElement;
is( $record->nodeName, 'marc:record', 'MARCXML record generation' );
