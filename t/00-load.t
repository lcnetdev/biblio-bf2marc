#!perl -T
use 5.010000;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Biblio::BF2MARC' ) || print "Bail out!\n";
}

diag( "Testing Biblio::BF2MARC $Biblio::BF2MARC::VERSION, Perl $], $^X" );
