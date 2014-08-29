#!/usr/local/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $prior_line = 'test';
my $current_line = 'test';

my $assess_flag = 'false';


my $fh;		
my $SOURCE_FILE = shift;
print "Destination file log is: $SOURCE_FILE\n";
open $fh, "<", $SOURCE_FILE or die "Couldn't open $SOURCE_FILE: $!\n";
my @file_array = <$fh>;

print "File array is: @file_array\n";

my $fh_log;		
my $DESTINATION_FILE_LOG = 'Eliminated_duplicates_'  . time . '.txt';
open $fh_log, ">", $DESTINATION_FILE_LOG or die "Couldn't open $DESTINATION_FILE_LOG: $!\n";


my $fh_creates;		
my $DESTINATION_FILE_CREATES = 'Improved_File_'  . time . '.txt';
open $fh_creates, ">", $DESTINATION_FILE_CREATES or die "Couldn't open $DESTINATION_FILE_CREATES: $!\n";

my $duplicates_detected = 0;

foreach $current_line (@file_array)
{	
	chomp $current_line;
	
	if ($assess_flag eq 'false')
	{
		print "in the first if block\n";
		$prior_line = $current_line;
		$assess_flag = 'true';
	}
	elsif ($assess_flag eq 'true')
	{
		
		print "Assessing: $prior_line\n";
		print "versus\n";
		print "Assessing: $current_line\n";
		
		if ($prior_line eq $current_line)
		{
			# replace everything in the line with just a semi-colon
			print {$fh_log}("Duplicate detected: $current_line\n");
			print "Duplicate detected! $prior_line\n";
			$duplicates_detected++;
		}
		else
		{
			print {$fh_creates}("$current_line\n");
		}
		
		$assess_flag = 'false';
	}
	
}
close $fh_log;
close $fh_creates;







