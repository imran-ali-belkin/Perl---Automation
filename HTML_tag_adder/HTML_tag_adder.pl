use strict;
use warnings;

my $ALTERNATED_FILE = 'HTML_file.txt';
open my $fh_ALTERNATED_FILE, ">", $ALTERNATED_FILE or die "Couldn't open $ALTERNATED_FILE: $!\n";

while(<>)
{
	chomp;
	print {$fh_ALTERNATED_FILE}("<H4>");
	print {$fh_ALTERNATED_FILE}($_);
	print {$fh_ALTERNATED_FILE}("</H4>\n");
}
close $fh_ALTERNATED_FILE;
