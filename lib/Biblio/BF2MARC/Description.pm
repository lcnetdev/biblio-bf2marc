package Biblio::BF2MARC::Description;

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

    use Biblio::BF2MARC::Description;
    use RDF::Trine;

    # Resources should be bf:Work and bf:Instance resources that
    # refer to each other (via the bf:hasInstance or bf:instanceOf
    # predicates). The class does not validate this assumption.

    my $work = RDF::Trine::iri('http://example.org/13600108#Work');
    my $instance = RDF::Trine::iri('http://example.org/13600108#Instance');

    # Constructor

    my $description = Biblio::BF2MARC::Description->new(
        work => $work,
        instance => $instance
    );

=head1 DESCRIPTION

Biblio::BF2MARC::Description is a helper class for L<Biblio::BF2MARC>,
specifying the structure of a BIBFRAME description. A BIBFRAME description
is defined as a pair of bf:Work and bf:Instance nodes that refer to one
another. This class does not validate that assumption (which would require
access to an underlying RDF model), it is simply a formalization of the
BIBFRAME description datatype for convenience.

=cut

use RDF::Trine;

=head1 SUBROUTINES/METHODS

=head2 new

    $description = Biblio::BF2MARC::Description->new(%description);

Constructor for BF2MARC converter. Can take a hash as
the single parameter to construct the object, or the properties can be
set by the accessor methods below.

=cut

sub new {
    my $inv = shift;
    my $class = ref($inv) || $inv;
    my $self = { };
    bless($self, $class);
    if (@_) {
        my %description = @_;
        while (my ($key, $value) = each(%description)) {
            ($key eq 'work' || $key eq 'instance') || croak "Invalid property $key";
            $self->work($value) if ($key eq 'work');
            $self->instance($value) if ($key eq 'instance');
        }
    }
    return $self;
}

=head2 work

    $work = $description->work;
    $description->work($work);

Set or get the L<RDF::Trine::Node> for the work. Returns the node.
Will croak if work is not an L<RDF::Trine::Node> object.

=cut

sub work {
    my ($self, $work) = @_;
    if ($work) {
        $work->isa('RDF::Trine::Node') || croak 'Unrecognized object type for work ' . ref($work);
        $$self{work} = $work;
    }
    return $$self{work};
}

=head2 instance

    $instance = $description->instance;
    $description->instance($instance);

Set or get the L<RDF::Trine::Node> for the work. Returns the node.
Will croak if work is not an L<RDF::Trine::Node> object.

=cut

sub instance {
    my ($self, $instance) = @_;
    if ($instance) {
        $instance->isa('RDF::Trine::Node') || croak 'Unrecognized object type for instance ' . ref($instance);
        $$self{instance} = $instance;
    }
    return $$self{instance};
}

=head1 AUTHOR

Wayne Schneider, C<< <wayne at indexdata.com> >>

=head1 BUGS AND FEATURE REQUESTS

Please use the GitHub issues tracker at
L<https://github.com/lcnetdev/biblio-bf2marc/issues> to report issues
and make feature requests.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Biblio::BF2MARC::Description

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

1; # End of Biblio::BF2MARC::Description
