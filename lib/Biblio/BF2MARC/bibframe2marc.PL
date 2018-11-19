use strict;
use warnings;
use XML::LibXML;
use XML::LibXSLT;

# Build the bibframe2marc.xsl stylesheet
# from the rules in xsl/rules

my $rules_path = 'xsl/rules';
my $compiler_path = 'xsl/src/compile.xsl';
my $output = 'lib/Biblio/BF2MARC/bibframe2marc.xsl';

# Set up the top-level rules document
my $rules_version;
if (-r "$rules_path/VERSION") {
    open(my $version_fh, '<', "$rules_path/VERSION")
      or die "Can't open $rules_path/VERSION: $!\n";
    $rules_version = <$version_fh>;
    close($version_fh);
    chomp($rules_version);
}

my $rules_str = '<rules xmlns="http://www.loc.gov/bf2marc">';
if ($rules_version) {
    $rules_str .= "<version>$rules_version</version>";
}
opendir(my $rules_dh, $rules_path)
  or die "Can't open $rules_path: $!\n";
my @rules = grep { /\.xml$/ && -f "$rules_path/$_" } readdir($rules_dh);
closedir($rules_dh);
foreach my $file (sort { $a cmp $b } @rules) {
    $rules_str .= "<file>$rules_path/$file</file>";
}
$rules_str .= '</rules>';
my $rules_doc = XML::LibXML->load_xml( string => $rules_str );

# Process the rules to create the stylesheet
my $xslt = XML::LibXSLT->new();
my $compiler_doc = XML::LibXML->load_xml( location => $compiler_path, no_cdata => 1 );
my $compiler = $xslt->parse_stylesheet($compiler_doc);
my $output_doc = $compiler->transform($rules_doc);
open(my $output_fh, ">:encoding(UTF-8)", $output)
  or die "Can't open $output: $!\n";
print $output_fh $compiler->output_as_bytes($output_doc);
close($output_fh);

exit;
