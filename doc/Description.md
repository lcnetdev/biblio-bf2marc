# NAME

Biblio::BF2MARC - Convert BIBFRAME RDF to MARC

# VERSION

Version 0.1.0

# SYNOPSIS

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

# DESCRIPTION

Biblio::BF2MARC::Description is a helper class for [Biblio::BF2MARC](https://metacpan.org/pod/Biblio::BF2MARC),
specifying the structure of a BIBFRAME description. A BIBFRAME description
is defined as a pair of bf:Work and bf:Instance nodes that refer to one
another. This class does not validate that assumption (which would require
access to an underlying RDF model), it is simply a formalization of the
BIBFRAME description datatype for convenience.

# SUBROUTINES/METHODS

## new

    $description = Biblio::BF2MARC::Description->new(%description);

Constructor for BF2MARC converter. Can take a hash as
the single parameter to construct the object, or the properties can be
set by the accessor methods below.

## work

    $work = $description->work;
    $description->work($work);

Set or get the [RDF::Trine::Node](https://metacpan.org/pod/RDF::Trine::Node) for the work. Returns the node.
Will croak if work is not an [RDF::Trine::Node](https://metacpan.org/pod/RDF::Trine::Node) object.

## instance

    $instance = $description->instance;
    $description->instance($instance);

Set or get the [RDF::Trine::Node](https://metacpan.org/pod/RDF::Trine::Node) for the work. Returns the node.
Will croak if work is not an [RDF::Trine::Node](https://metacpan.org/pod/RDF::Trine::Node) object.

# AUTHOR

Wayne Schneider, `<wayne at indexdata.com>`

# BUGS AND FEATURE REQUESTS

Please use the GitHub issues tracker at
[https://github.com/lcnetdev/biblio-bf2marc/issues](https://github.com/lcnetdev/biblio-bf2marc/issues) to report issues
and make feature requests.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Biblio::BF2MARC::Description

# LICENSE

As a work of the United States government, this project is in the
public domain within the United States.

Additionally, we waive copyright and related rights in the work
worldwide through the CC0 1.0 Universal public domain dedication.

[Legal Code (read the full
text)](https://creativecommons.org/publicdomain/zero/1.0/legalcode).

You can copy, modify, distribute and perform the work, even for
commercial purposes, all without asking permission.
