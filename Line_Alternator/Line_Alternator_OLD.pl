use strict;
use warnings;

# These are counters which 
my $total_lines_found_fileA = 0;
my $total_lines_found_fileB = 0;
my $total_lines_written = 0;

#############################################################################################################
#
# The main user interface - getting user input, etc
#
#############################################################################################################
print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The Line Alternator\n";
print " 				Written 12-18-2013 by Jason Murphy\n";
print "==========================================================================\n";
print "\n\n";
print "This script this:\n";
print "1: Finds a.txt (the file you want first)\n";
print "2: Finds b.txt (the file you want second)\n";
print "3: Creates a text file that has lines a b a b a b ... alternated\n";

print "==========================================================================\n";

print "==========================================================================\n";
print "Hit enter when ready to execute this script:\n";
print ">";
print "==========================================================================\n";
my $do_nothing_with_this = <STDIN>;
chomp($do_nothing_with_this);


# Jason's additions
my $DATA_FILE_A = 'a.txt';
my $DATA_FILE_B = 'b.txt';
my $ALTERNATED_FILE = 'ALTERNATED_FILE.txt';
my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_irc_uplink . '.txt';


# This is the raw read file
open my $fh_A, '<', $DATA_FILE_A or die "Could not open $DATA_FILE_A: $!\n";
open my $fh_B, '<', $DATA_FILE_B or die "Could not open $DATA_FILE_B: $!\n";
open my $fh_ALTERNATED_FILE, ">", $ALTERNATED_FILE or die "Couldn't open $ALTERNATED_FILE: $!\n";
open my $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";

##############################################################################################################
#
#	The Alternates Section
#
##############################################################################################################
my $line_A;

while ($line_A = <$fh_A> )
{
	# Chomp it
	chomp($line_A);

	# Increment the found counter
	$total_lines_found_fileA++;
	
	# Write line from file A to the ALTERNATED_FILE
	print {$fh_ALTERNATED_FILE} ("$line_A");
}


				
##############################################################################################################
#
#	Close the File Handles
#
##############################################################################################################
close $fh_A;
close $fh_B;
close $fh_ALTERNATED_FILE;
close $fh_error;


##############################################################################################################
#
#	Print out all totals
#
##############################################################################################################
print "==========================================================\n";
print "Totals \n";
print "==========================================================\n";

print "Total lines found in file a.txt:\t " . $total_lines_found_fileA . "\n";
print "Total lines found in file b.txt:\t " . $total_lines_found_fileB . "\n";
print "Total lines writted to the output.txt:\t " . $total_lines_written . "\n";
print "\n";
 



