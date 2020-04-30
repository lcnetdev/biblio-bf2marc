package Biblio::BF2MARC;

use 5.010000;
use strict;
use warnings;
use Carp qw(carp croak);

=head1 NAME

Biblio::BF2MARC - Convert BIBFRAME RDF to MARC

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.010000';

=head1 SYNOPSIS

    use Biblio::BF2MARC;
    use RDF::Trine;
    use XML::LibXML;
    use MARC::Record;
    use MARC::File::XML;

    # load in an RDF::Trine::Model with BIBFRAME 2.0 descriptions
    my $model = RDF::Trine::Model->temporary_model();
    my $parser = RDF::Trine::Parser->new('rdfxml');
    $parser->parse_file_into_model(undef, 'bibframe.xml', $model);

    # instantiate a BF2MARC converter
    # pass in the model
    my $bf2marc = Biblio::BF2MARC->new($model);

    # point the converter at your own custom stylesheet, rather than
    # using the one included
    my $style_doc = XML::LibXML->load_xml( location => 'my-bf2marc.xsl', no_cdata => 1 );
    $bf2marc->stylesheet($style_doc);

    # return BIBFRAME descriptions as an array
    # each entry represents a BIBFRAME description (work + instance)
    my @descriptions = $bf2marc->descriptions;

    # convert descriptions to striped RDF/XML
    # (XML::LibXML::Document objects for XSLT conversion)
    my @striped_descriptions;
    foreach my $description (@descriptions) {
        push(
          @striped_descriptions,
          $bf2marc->to_striped_xml(
            $description,
            { dereference => {
                'http://id.loc.gov/ontologies/bibframe/Agent' =>
                  ['http://id.loc.gov']
              }
            }
          )
        );
    }

    # convert striped descriptions to MARCXML (XML::LibXML::Document objects)
    my @marcxml_docs;
    foreach my $striped_description (@striped_descriptions) {
        push(@marcxml_docs, $bf2marc->convert($striped_description));
    }

    # convert descriptions to MARC::Record objects
    my @marc_collection;
    foreach my $marcxml (@marcxml_docs) {
        push(@marc_collection, MARC::Record->new_from_xml($marcxml->toString, 'UTF-8'));
    }

=head1 DESCRIPTION

Biblio::BF2MARC provides a library to manage conversion of RDF
BIBFRAME 2.0 descriptions into MARC records, using an XSLT 1.0
stylesheet such as the one provided by the
L<bibframe2marc|https://github.com/lcnetdev/bibframe2marc>
project (included in this distribution as a default). The converter
object is built on an L<RDF::Trine::Model>, and so can operate on RDF
graphs in memory, from a file, or from any storage backend supported
by L<RDF::Trine::Store>. The converter returns MARCXML as XML::LibXML
objects, which can in turn be converted into MARC::Record objects to
support alternate MARC serializations.

=head1 DEPENDENCIES

=over 4

=item * L<RDF::Trine>

=item * L<RDF::Query>

=item * L<XML::LibXML>

=item * L<XML::LibXSLT>

=item * L<List::Util>

=item * L<File::ShareDir>

=back

=cut

# Avoid Redland parser due to issues with IRI encoding
# Unfortunate for performance
# For some reason these use statements need to come before RDF::Trine
use RDF::Trine::Parser::RDFXML;
use RDF::Trine::Parser::RDFa;
use RDF::Trine::Parser::NTriples;
use RDF::Trine::Parser::Turtle;
use RDF::Trine::Parser::TriG;

use RDF::Trine;
use RDF::Query;
use XML::LibXML;
use XML::LibXSLT;
use List::Util qw(none);
use File::Share qw(:all);
use Biblio::BF2MARC::Description;

# Convenience variables
my %namespaces = (
                  'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                  'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
                  'bf' => 'http://id.loc.gov/ontologies/bibframe/',
                  'bflc' => 'http://id.loc.gov/ontologies/bflc/',
                  'madsrdf' => 'http://www.loc.gov/mads/rdf/v1#'
                 );
my %rev_namespaces = reverse(%namespaces);

=head1 SUBROUTINES/METHODS

=head2 new

    $bf2marc = Biblio::BF2MARC->new($model);

Constructor for BF2MARC converter. Can take an L<RDF::Trine::Model> as
the single parameter, or the model can be set later using the
C<model> accessor. Will croak if the model parameter is not an
L<RDF::Trine::Model> object.

The constructor will attempt to set the converter stylesheet to the
default bibframe2marc.xsl in the module directory. If the stylesheet
can't be loaded, it log a warning, and the object will be returned
without a stylesheet property. The stylesheet can also be set manually
using the C<stylesheet> method.

=cut

sub new {
    my $inv = shift;
    my $class = ref($inv) || $inv;
    my $self = {
                xslt => XML::LibXSLT->new(),
                dereferenced => [ ]
               };
    bless($self, $class);
    my $model = shift;
    if ($model) {
        $self->model($model);
    }
    my $stylesheet_file = dist_file('Biblio-BF2MARC','bibframe2marc.xsl');
    if (-r $stylesheet_file) {
        my $style_doc = eval { XML::LibXML->load_xml( location => $stylesheet_file, no_cdata => 1 ) };
        warn "Unable to load default stylesheet $stylesheet_file: $@" if $@;
        $self->stylesheet($style_doc) if $style_doc;
    } else {
        warn "Unable to load default stylesheet $stylesheet_file, file not readable";
    }
    return $self;
}

=head2 model

    $model = $bf2marc->model;
    $bf2marc->model($model);

Set or get the RDF::Trine::Model for the converter. Returns the model.
Will croak if the model is not an L<RDF::Trine::Model> object.

=cut

sub model {
    my ($self, $model) = @_;
    if ($model) {
        $model->isa('RDF::Trine::Model') || croak 'Unrecognized model type ' . ref($model);
        $$self{dereferenced} = [ ];
        $$self{model} = $model;
    }
    return $$self{model};
}

=head2 stylesheet

    $success= $bf2marc->stylesheet($style_doc);

Set the stylesheet used for the BIBFRAME to MARC conversion from an
L<XML::LibXML::Document> object. Will croak if unable to build the
stylesheet.

=cut

sub stylesheet {
    my ($self, $style_doc) = @_;
    eval { $$self{stylesheet} = $$self{xslt}->parse_stylesheet($style_doc) };
    if ($@) { croak $@ }
    return 1;
}

=head2 descriptions

    @descriptions = $bf2marc->descriptions

Returns the BIBFRAME descriptions in the model as an array. A BIBFRAME
description is defined as a pair of bf:Work and bf:Instance nodes that
refer to one another. Each entry in the array is a
L<Biblio::BF2MARC::Description> object.

This method will return only resource nodes (not blank nodes).

=cut

sub descriptions {
    my $self = shift;

    my $sparql = <<'END';
PREFIX bf: <http://id.loc.gov/ontologies/bibframe/>

SELECT DISTINCT ?work ?instance
WHERE
{
  { ?work bf:hasInstance ?instance } UNION { ?instance bf:instanceOf ?work }
}
END
    my $query = RDF::Query->new($sparql);
    my $query_iterator = $query->execute($self->model);
    my @descriptions;
    while (my $result = $query_iterator->next) {
        if ($$result{work}->is_resource && $$result{instance}->is_resource) {
            my $description = Biblio::BF2MARC::Description->new(
                work => $$result{work},
                instance => $$result{instance}
            );
            push(@descriptions, $description);
        }
    }
    return @descriptions;
}

=head2 to_striped_xml

   $xml = $bf2marc->to_striped_xml($description, \%options);

Returns an L<XML::LibXML::Document> object that is a striped RDF/XML
representation of a L<Biblio::BF2MARC::Description>, constructed from
the model in the BF2MARC converter object.

The nodes in the description must be L<RDF::Trine::Node::Resource>
objects.

=head3 options (hashref)

=over 4

=item * C<< dereference => \%classes >>: A hashref of classes with the
class IRI as key and an arrayref of URL prefixes as the value which
should be dereferenced by URI and their retrieved properties added to
the element. The default behavior is not to dereference any URIs.
Note that dereferenced content is assumed to be UTF-8 encoded.

=back

=cut

sub to_striped_xml {
    my $self = shift;
    my $description = shift;
    $description || croak 'No description passed to method';
    $description->isa('Biblio::BF2MARC::Description') || croak 'Invalid parameter type for description: ' . ref($description);
    unless ($description->work->is_resource) {
        carp "Work node in description is not a resource";
        return undef;
    }
    unless ($description->instance->is_resource) {
        carp "Instance node in description is not a resource";
        return undef;
    }
    my $options = shift;
    if ($options) {
        if (ref($options) eq 'HASH') {
            while (my ($option, $value) = each(%{$options})) {
                if ($option eq 'dereference') {
                    unless (ref($value) eq 'HASH') {
                        croak 'Invalid format for dereference option (must be hashref)';
                    }
                } else {
                    croak "Unknown option $option";
                }
            }
        } else {
            croak 'Invalid format for options (must be hashref)';
        }
    }
    my $xml = XML::LibXML::Document->new();
    my $rdf = $xml->createElement('RDF');
    while (my ($prefix, $uri) = each(%namespaces)) {
        if ($prefix eq 'rdf') {
            $rdf->setNamespace($namespaces{rdf}, 'rdf');
        } else {
            $rdf->setNamespace($uri, $prefix, 0);
        }
    }
    $xml->setDocumentElement($rdf);

    my $work = XML::LibXML::Element->new('Work');
    $work->setNamespace($namespaces{bf}, 'bf');
    $work->setNamespace($namespaces{rdf}, 'rdf', 0);
    $work->setAttributeNS($namespaces{rdf}, 'rdf:about', $description->work->uri);
    my $work_properties = $self->model->get_statements($description->work);
    $work_properties->unique;
    while (my $st = $work_properties->next) {
        if ($st->predicate->equal(RDF::Trine::iri($namespaces{rdf} . 'type')) &&
            $st->object->equal(RDF::Trine::iri($namespaces{bf} . 'Work'))) {
            next;
        } elsif ($st->predicate->equal(RDF::Trine::iri($namespaces{bf} . 'hasInstance')) &&
                 $st->object->equal($description->instance)) {
            my $has_instance = XML::LibXML::Element->new('hasInstance');
            $has_instance->setNamespace($namespaces{bf}, 'bf');
            $has_instance->setNamespace($namespaces{rdf}, 'rdf', 0);
            $has_instance->setAttributeNS($namespaces{rdf}, 'rdf:resource', $description->instance->uri);
            $work->appendChild($has_instance);
        } else {
            $work->appendChild($self->_build_property($st,$options));
        }
    }
    $rdf->appendChild($work);

    my $instance = XML::LibXML::Element->new('Instance');
    $instance->setNamespace($namespaces{bf}, 'bf');
    $instance->setNamespace($namespaces{rdf}, 'rdf', 0);
    $instance->setAttributeNS($namespaces{rdf}, 'rdf:about', $description->instance->uri);
    my $instance_properties = $self->model->get_statements($description->instance);
    $instance_properties->unique;
    while (my $st = $instance_properties->next) {
        if ($st->predicate->equal(RDF::Trine::iri($namespaces{rdf} . 'type')) &&
            $st->object->equal(RDF::Trine::iri($namespaces{bf} . 'Instance'))) {
            next;
        } elsif ($st->predicate->equal(RDF::Trine::iri($namespaces{bf} . 'instanceOf')) &&
                 $st->object->equal($description->work)) {
            my $instance_of = XML::LibXML::Element->new('instance_of');
            $instance_of->setNamespace($namespaces{bf}, 'bf');
            $instance_of->setNamespace($namespaces{rdf}, 'rdf', 0);
            $instance_of->setAttributeNS($namespaces{rdf}, 'rdf:resource', $description->work->uri);
            $instance->appendChild($instance_of);
        } else {
            $instance->appendChild($self->_build_property($st,$options));
        }
    }
    $rdf->appendChild($instance);

    return $xml;
}

=head2 convert

   my $marcxml = $bf2marc->convert($striped_xml);

Takes an L<XML::LibXML::Document> containing a striped RDF/XML
representation of a BIBFRAME description. Returns a
L<XML::LibXML::Document> object transformed by a conversion XSLT
stylesheet to a MARCXML document.

=cut

sub convert {
    my ($self, $description) = @_;
    my $output = eval { $$self{stylesheet}->transform($description) };
    if ($@) {
        carp "Conversion failed: $@";
    } else {
        return $output;
    }
}

=head1 INTERNAL METHODS

=head2 _build_XML_element

    my $element = $self->_build_XML_element($node);

Build an L<XML::LibXML::Element> object from an L<RDF::Trine::Node>
object. If the qname of the node is part of the internal %namespaces
hash, the element namespace and prefix will be set.

=cut

sub _build_XML_element {
    my ($self, $node) = @_;
    $node || croak 'No node passed to method';
    $node->isa('RDF::Trine::Node') || croak "Invalid parameter type for node: " . ref($node);
    my ($element, $namespace, $name);
    eval { ($namespace, $name) = $node->qname };
    if ($@) {
        croak "Can't create RDF/XML for node " .
          $node->as_string() .
          ", resource namespace can't be determined: $@";
    }
    $element = XML::LibXML::Element->new($name);
    if ($rev_namespaces{$namespace}) {
        $element->setNamespace($namespace,$rev_namespaces{$namespace});
    } else {
        $element->setNamespace($namespace);
    }

    return $element;
}

=head2 _build_property

    my $element = $self->_build_property($statement, \%options);

Build an L<XML::LibXML::Element> object from the predicate and object
of an L<RDF::Trine::Statement> object. Used to create stripes in an
RDF/XML document.

This method walks the graph of the model and retrieves statements
about the object if the object is not a literal, and calls itself to
continue to add on stripes to the element. A recursion check
is in place to ensure that stripes cannot go infinitely deep.

Literal objects add attributes to the property for C<<xml:lang>>
and C<rdf:datatype>, if appropriate.

Will croak with invalid option format, carp with unknown option.

=head3 options (hashref)

=over 4

=item * C<< dereference => \%classes >>: A hashref of classes with the
class IRI as key and an arrayref of URL prefixes as the value which
should be dereferenced by URI and their retrieved properties added to
the element. The default behavior is not to dereference any URIs.

=back

=cut

sub _build_property {
    my ($self, $st, $options, @subjects) = @_;
    $st || croak 'No statement passed to method';
    $st->isa('RDF::Trine::Statement') || croak 'Invalid parameter type for property: ' . ref($st);
    my $dereference;
    if ($options) {
        if (ref($options) eq 'HASH') {
            while (my ($option, $value) = each(%{$options})) {
                if ($option eq 'dereference') {
                    if (ref($value) eq 'HASH') {
                        $dereference = $value;
                    } else {
                        carp 'Invalid format for dereference option (must be hashref)';
                    }
                } else {
                    carp "Unknown option $option";
                }
            }
        } else {
            croak 'Invalid format for options (must be hashref)';
        }
    }
    push(@subjects, $st->subject);
    my $property = $self->_build_XML_element($st->predicate);
    if ($st->object->is_literal) {
        if ($st->object->has_language) {
            $property->setAttribute('xml:lang',$st->object->literal_value_language);
        }
        if ($st->object->has_datatype) {
            $property->setNamespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'rdf', 0);
            $property->setAttributeNS(
                                      'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                                      'datatype',
                                      $st->object->literal_datatype
                                     );
        }
        $property->appendTextNode($st->object->literal_value);
    } elsif ($st->object->is_resource ||
             $st->object->is_blank) {

        # Build the node list to process
        # If the object is an rdf:List, there may be multiples
        # Otherwise the list is just the object
        my @node_list;
        my @collection = $self->model->objects($st->object, RDF::Trine::iri($namespaces{rdf} . 'first'));
        my @rest = $self->model->objects($st->object, RDF::Trine::iri($namespaces{rdf} . 'rest'));
        if (@collection) {
            # For collections, set the rdf:parseType attribute on the property
            $property->setAttributeNS($namespaces{rdf}, 'rdf:parseType', 'Collection');
            foreach my $node (@collection) {
                unless (
                        $node->is_nil ||
                        ($node->is_resource && $node->uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')
                       ) {
                    push(@node_list, $node);
                }
            }
            # Process the rest of the rdf:List, if it's there
            while (my $node = shift(@rest)) {
                unless (
                        $node->is_nil ||
                        ($node->is_resource && $node->uri eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')
                       ) {
                    push(@node_list, $self->model->objects($node, RDF::Trine::iri($namespaces{rdf} . 'first')));
                    push(@rest, $self->model->objects($node, RDF::Trine::iri($namespaces{rdf} . 'rest')));
                }
            }
        } else {
            @node_list = ($st->object);
        }

        # Process the node list
        # Create a stripe for each node
        foreach my $node (@node_list) {
            my $stripe;

            # Get object classes in model
            my @types = $self->model->objects($node, RDF::Trine::iri($namespaces{rdf} . 'type'));

            # dereference resources, add to model
            if ($dereference && $node->is_resource) {
                # We are only going to deal with UTF-8 when dereferencing. Servers that
                # send other encodings for RDF will likely result in weird output
                local $RDF::Trine::Parser::encodings{ 'RDF::Trine::Parser::RDFXML' } = 'utf8';
                local $RDF::Trine::Parser::encodings{ 'RDF::Trine::Parser::RDFa' } = 'utf8';
                local $RDF::Trine::Parser::encodings{ 'RDF::Trine::Parser::NTriples' } = 'utf8';
                local $RDF::Trine::Parser::encodings{ 'RDF::Trine::Parser::TriG' } = 'utf8';
                local $RDF::Trine::Parser::encodings{ 'RDF::Trine::Parser::RDFJSON' } = 'utf8';
                local $RDF::Trine::Parser::encodings{ 'RDF::Trine::Parser::NQuads' } = 'utf8';
                local $RDF::Trine::Parser::encodings{ 'RDF::Trine::Parser::Redland' } = 'utf8';
                while (my ($class, $prefixes) = each(%{$dereference})) {
                    foreach my $type (@types) {
                        if (
                            $type->is_resource &&
                            ($type->uri eq $class) &&
                            (none { $_ eq $node->uri } @{$$self{dereferenced}})
                           ) {
                            foreach my $prefix (@{$prefixes}) {
                                if ($node->uri =~ /^$prefix/) {
                                    eval { RDF::Trine::Parser->parse_url_into_model( $node->uri, $self->model ); };
                                    if ($@) {
                                        carp 'Unable to dereference IRI ' .
                                          $node->uri .
                                          ' in statement ' .
                                          $st->as_string() .
                                          ': ' .
                                          $@;
                                    }
                                    push(@{$$self{dereferenced}}, $node->uri);
                                    last;
                                }
                            }
                        }
                    }
                }
                # Update types array with new data if available
                my @types_upd = $self->model->objects($node, RDF::Trine::iri($namespaces{rdf} . 'type'));
                foreach my $type (@types_upd) {
                    my $match = 0;
                    foreach my $type_o (@types) {
                        if ($type->equal($type_o)) {
                            $match = 1;
                            last;
                        }
                    }
                    push(@types,$type) unless $match;
                }
            }

            # Build the XML element for the stripe
            if (@types) {
                for (my $i = 0; $i < @types; $i++) {
                    if ($i == 0) {
                        $stripe = $self->_build_XML_element($types[$i]);
                        if ($node->is_resource) {
                            $stripe->setNamespace($namespaces{rdf}, 'rdf', 0);
                            $stripe->setAttributeNS($namespaces{rdf}, 'rdf:about', $node->uri);
                        }
                    } else {
                        my $type = $self->_build_XML_element(RDF::Trine::iri($namespaces{rdf} . 'type'));
                        $type->setAttributeNS($namespaces{rdf}, 'rdf:resource', $types[$i]->uri);
                        $stripe->addChild($type);
                    }
                }
            } else {
                $stripe = $self->_build_XML_element(RDF::Trine::iri($namespaces{rdf} . 'Description'));
            }

            # Attach properties to the stripe
            my $props = $self->model->get_statements($node);
            $props = $props->unique;
            my $props_mater = $props->materialize;
            if ($props_mater->length > 0) {
                while (my $prop_st = $props_mater->next) {
                    my $self_referencing;
                    foreach my $i (@subjects) {
                        if ($prop_st->object->equal($i)) {
                            $self_referencing = 1;
                            last;
                        }
                    }
                    if ($prop_st->predicate->equal(RDF::Trine::iri($namespaces{rdf} . 'type'))) {
                        next;
                    } elsif ($self_referencing) {
                        my $self_ref = $self->_build_XML_element($prop_st->predicate);
                        $self_ref->setNamespace($namespaces{rdf}, 'rdf', 0);
                        $self_ref->setAttributeNS($namespaces{rdf}, 'rdf:resource', $prop_st->object->uri);
                        $stripe->addChild($self_ref);
                    } else {
                        eval { $stripe->addChild($self->_build_property($prop_st, $options, @subjects)) };
                        carp $@ if ($@);
                    }
                }
                $property->addChild($stripe);
            } else {
                if ($node->is_resource) {
                    $property->setNamespace($namespaces{rdf}, 'rdf', 0);
                    $property->setAttributeNS($namespaces{rdf}, 'rdf:resource',$node->uri)
                }
            }
        }
    } else {
        carp "Can't create RDF/XML for statement " .
          $st->as_string() .
          ": unknown node type for object.";
        return undef;
    }

    return $property;
}

=head1 AUTHOR

Wayne Schneider, C<< <wayne at indexdata.com> >>

=head1 BUGS AND FEATURE REQUESTS

Please use the GitHub issues tracker at
L<https://github.com/lcnetdev/biblio-bf2marc/issues> to report issues
and make feature requests.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Biblio::BF2MARC

=head1 SEE ALSO

=over 4

=item * L<bibframe2marc XSLT
conversion|https://github.com/lcnetdev/bibframe2marc>

=item * The L<Bibliographic Framework
Initiative|http://www.loc.gov/bibframe> at the Library of Congress

=item * L<marc2bibframe2 XSLT
conversion|https://github.com/lcnetdev/marc2bibframe2>

=back

=head1 LICENSE

As a work of the United States government, this project is in the
public domain within the United States.

Additionally, we waive copyright and related rights in the work
worldwide through the CC0 1.0 Universal public domain dedication.

L<Legal Code (read the full
text)|https://creativecommons.org/publicdomain/zero/1.0/legalcode>.

You can copy, modify, distribute and perform the work, even for
commercial purposes, all without asking permission.

=cut

1; # End of Biblio::BF2MARC
