use strict;
use warnings;

my $ALTERNATED_FILE = 'ALTERNATED_FILE.txt';
open my $fh_ALTERNATED_FILE, ">", $ALTERNATED_FILE or die "Couldn't open $ALTERNATED_FILE: $!\n";

my @fh;

for (@ARGV) {
  open my $fh, '<', $_ or die "Unable to open '$_' for reading: $!";
  push @fh, $fh;
}

while (grep { not eof } @fh) {
  for my $fh (@fh) {
    if (defined(my $line = <$fh>)) 
	{
      chomp $line;  
	  # Write line from file A to the ALTERNATED_FILE
	  print {$fh_ALTERNATED_FILE} ("$line\n");
      print "$line\n";
    }
  }
}

close $fh_ALTERNATED_FILE;
