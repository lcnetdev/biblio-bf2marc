#!perl -T
use Test::More tests => 5;

use 5.01;
use strict;
use warnings;

use Biblio::BF2MARC::Description;
use RDF::Trine;

# Set up a description
my $work = RDF::Trine::iri('http://example.org/13600108#Work');
my $instance = RDF::Trine::iri('http://example.org/13600108#Instance');

diag("Testing Biblio::BF2MARC::Description object creation and methods");

my $description;

# Object creation
$description = new_ok('Biblio::BF2MARC::Description');

# Work accessor
$description->work($work);
is_deeply($description->work, $work, 'set work property');

# Instance accessor
$description->instance($instance);
is_deeply($description->instance, $instance, 'set instance property');

# Object creation with properties
$description = new Biblio::BF2MARC::Description (
    work => $work,
    instance => $instance
);
is_deeply($description->work, $work, 'create work with constructor');
is_deeply($description->instance, $instance, 'create instance with constructor');
