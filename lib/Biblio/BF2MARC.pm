package Biblio::BF2MARC;

use 5.010000;
use strict;
use warnings;
use Carp qw(carp croak);

=head1 NAME

Biblio::BF2MARC - Convert BIBFRAME RDF to MARC

=head1 VERSION

Version 0.01_01

=cut

our $VERSION = '0.01_01';

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
    my $bf2marc = Biblio::BF2MARC->new($model);

    # return BIBFRAME descriptions as an arrayref
    # each entry represents a BIBFRAME description (work + instance)
    my $descriptions = $bf2marc->descriptions;

    # convert descriptions to striped RDF/XML
    # (XML::LibXML::Document objects for XSLT conversion)
    my @striped_descriptions;
    foreach my $description (@{$descriptions}) {
        push(@striped_descriptions, $bf2marc->to_striped_xml($description));
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
L<bibframe2marc-xsl|https://github.com/lcnetdev/bibframe2marc-xsl>
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

=item * L<File::ShareDir>

=back

=cut

use RDF::Trine;
use RDF::Query;
use XML::LibXML;
use XML::LibXSLT;
use File::ShareDir;

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
}

=head2 descriptions

=cut

sub descriptions {
}

=head2 to_striped_xml

=cut

sub to_striped_xml {
}

=head2 convert

=cut

sub convert {
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

=item * L<bibframe2marc-xsl XSLT
conversion|https://github.com/lcnetdev/bibframe2marc-xsl>

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
