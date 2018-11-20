#!perl -T
use 5.010000;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Biblio::BF2MARC' ) || print "Bail out!\n";
    use_ok( 'Biblio::BF2MARC::Description' ) || print "Bail out!\n";
}

diag( "Testing Biblio::BF2MARC $Biblio::BF2MARC::VERSION, Perl $], $^X" );
