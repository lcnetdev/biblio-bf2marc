# NAME

Biblio::BF2MARC - Convert BIBFRAME RDF to MARC

# VERSION

Version 0.1.0

# SYNOPSIS

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

# DESCRIPTION

Biblio::BF2MARC provides a library to manage conversion of RDF
BIBFRAME 2.0 descriptions into MARC records, using an XSLT 1.0
stylesheet such as the one provided by the
[bibframe2marc](https://github.com/lcnetdev/bibframe2marc)
project (included in this distribution as a default). The converter
object is built on an [RDF::Trine::Model](https://metacpan.org/pod/RDF::Trine::Model), and so can operate on RDF
graphs in memory, from a file, or from any storage backend supported
by [RDF::Trine::Store](https://metacpan.org/pod/RDF::Trine::Store). The converter returns MARCXML as XML::LibXML
objects, which can in turn be converted into MARC::Record objects to
support alternate MARC serializations.

# DEPENDENCIES

- [RDF::Trine](https://metacpan.org/pod/RDF::Trine)
- [RDF::Query](https://metacpan.org/pod/RDF::Query)
- [XML::LibXML](https://metacpan.org/pod/XML::LibXML)
- [XML::LibXSLT](https://metacpan.org/pod/XML::LibXSLT)
- [List::Util](https://metacpan.org/pod/List::Util)
- [File::ShareDir](https://metacpan.org/pod/File::ShareDir)

# SUBROUTINES/METHODS

## new

    $bf2marc = Biblio::BF2MARC->new($model);

Constructor for BF2MARC converter. Can take an [RDF::Trine::Model](https://metacpan.org/pod/RDF::Trine::Model) as
the single parameter, or the model can be set later using the
`model` accessor. Will croak if the model parameter is not an
[RDF::Trine::Model](https://metacpan.org/pod/RDF::Trine::Model) object.

The constructor will attempt to set the converter stylesheet to the
default bibframe2marc.xsl in the module directory. If the stylesheet
can't be loaded, it log a warning, and the object will be returned
without a stylesheet property. The stylesheet can also be set manually
using the `stylesheet` method.

## model

    $model = $bf2marc->model;
    $bf2marc->model($model);

Set or get the RDF::Trine::Model for the converter. Returns the model.
Will croak if the model is not an [RDF::Trine::Model](https://metacpan.org/pod/RDF::Trine::Model) object.

## stylesheet

    $success= $bf2marc->stylesheet($style_doc);

Set the stylesheet used for the BIBFRAME to MARC conversion from an
[XML::LibXML::Document](https://metacpan.org/pod/XML::LibXML::Document) object. Will croak if unable to build the
stylesheet.

## descriptions

    @descriptions = $bf2marc->descriptions

Returns the BIBFRAME descriptions in the model as an array. A BIBFRAME
description is defined as a pair of bf:Work and bf:Instance nodes that
refer to one another. Each entry in the array is a
[Biblio::BF2MARC::Description](https://metacpan.org/pod/Biblio::BF2MARC::Description) object.

This method will return only resource nodes (not blank nodes).

## to\_striped\_xml

    $xml = $bf2marc->to_striped_xml($description, \%options);

Returns an [XML::LibXML::Document](https://metacpan.org/pod/XML::LibXML::Document) object that is a striped RDF/XML
representation of a [Biblio::BF2MARC::Description](https://metacpan.org/pod/Biblio::BF2MARC::Description), constructed from
the model in the BF2MARC converter object.

The nodes in the description must be [RDF::Trine::Node::Resource](https://metacpan.org/pod/RDF::Trine::Node::Resource)
objects.

### options (hashref)

- `dereference => \%classes`: A hashref of classes with the
class IRI as key and an arrayref of URL prefixes as the value which
should be dereferenced by URI and their retrieved properties added to
the element. The default behavior is not to dereference any URIs.
Note that dereferenced content is assumed to be UTF-8 encoded.

## convert

    my $marcxml = $bf2marc->convert($striped_xml);

Takes an [XML::LibXML::Document](https://metacpan.org/pod/XML::LibXML::Document) containing a striped RDF/XML
representation of a BIBFRAME description. Returns a
[XML::LibXML::Document](https://metacpan.org/pod/XML::LibXML::Document) object transformed by a conversion XSLT
stylesheet to a MARCXML document.

# INTERNAL METHODS

## \_build\_XML\_element

    my $element = $self->_build_XML_element($node);

Build an [XML::LibXML::Element](https://metacpan.org/pod/XML::LibXML::Element) object from an [RDF::Trine::Node](https://metacpan.org/pod/RDF::Trine::Node)
object. If the qname of the node is part of the internal %namespaces
hash, the element namespace and prefix will be set.

## \_build\_property

    my $element = $self->_build_property($statement, \%options);

Build an [XML::LibXML::Element](https://metacpan.org/pod/XML::LibXML::Element) object from the predicate and object
of an [RDF::Trine::Statement](https://metacpan.org/pod/RDF::Trine::Statement) object. Used to create stripes in an
RDF/XML document.

This method walks the graph of the model and retrieves statements
about the object if the object is not a literal, and calls itself to
continue to add on stripes to the element. A recursion check
is in place to ensure that stripes cannot go infinitely deep.

Literal objects add attributes to the property for `<xml:lang`>
and `rdf:datatype`, if appropriate.

Will croak with invalid option format, carp with unknown option.

### options (hashref)

- `dereference => \%classes`: A hashref of classes with the
class IRI as key and an arrayref of URL prefixes as the value which
should be dereferenced by URI and their retrieved properties added to
the element. The default behavior is not to dereference any URIs.

# AUTHOR

Wayne Schneider, `<wayne at indexdata.com>`

# BUGS AND FEATURE REQUESTS

Please use the GitHub issues tracker at
[https://github.com/lcnetdev/biblio-bf2marc/issues](https://github.com/lcnetdev/biblio-bf2marc/issues) to report issues
and make feature requests.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Biblio::BF2MARC

# SEE ALSO

- [bibframe2marc XSLT
conversion](https://github.com/lcnetdev/bibframe2marc)
- The [Bibliographic Framework
Initiative](http://www.loc.gov/bibframe) at the Library of Congress
- [marc2bibframe2 XSLT
conversion](https://github.com/lcnetdev/marc2bibframe2)

# LICENSE

As a work of the United States government, this project is in the
public domain within the United States.

Additionally, we waive copyright and related rights in the work
worldwide through the CC0 1.0 Universal public domain dedication.

[Legal Code (read the full
text)](https://creativecommons.org/publicdomain/zero/1.0/legalcode).

You can copy, modify, distribute and perform the work, even for
commercial purposes, all without asking permission.
