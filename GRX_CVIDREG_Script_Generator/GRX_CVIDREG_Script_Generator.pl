#!/usr/bin/perl
use strict;
use warnings;


if (!$ARGV[0])
{
  print "================================================\n";
  print "USAGE\n";
  print "================================================\n";
  
  print "Usage of this script is 'GRX_CVIDREG_Script_Generator CVIDREG.csv'\n";
  print "So, type the name of the generator and follow it with the name\n";
  print "of the CSV file. Thank you!";
  exit;  
}

if ($ARGV[0])
{
    print "-------------------------------------------\n";
	print "Welcome to the GRX_CVIDREG_Script Generator\n";
    print "-------------------------------------------\n";
	print "Requirements written by: An Do\n";
	print "Programming by: Jason Murphy\n";
	print "Written July 15, 2014\n";
	
	print "Hit enter to start the script!\n";
	print ">";
	my $contine = <STDIN>;
}

my $fh_error;		 
my $ERROR_FILE = 'error.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

my $fh_DELETE_CVID_REG;		
my $FILE_CVID_DELETE = '1_DELETE_CVID_REG.txt';
open $fh_DELETE_CVID_REG, '>', $FILE_CVID_DELETE or die "Could not open $FILE_CVID_DELETE $!\n";

my $fh_CREATE_CVID_REG;		 
my $FILE_CVID_CREATE = '2_CREATE_CVID_REG.txt';
open $fh_CREATE_CVID_REG, '>', $FILE_CVID_CREATE or die "Could not open $FILE_CVID_CREATE $!\n";


while(<>)
{ 
   if ($_ =~ /N\d+-\d+-VB\d+-\d+/)
   {
	my ($id, $SVID, $Priority, $RCVID) = split(',', $_);

	
	my $cleaned_up_id;
	if ($id =~ /(N\d+-\d+-VB\d+-\d+-DFLT) .*/)
    {
	  $cleaned_up_id = $1;
	}
	
    # DLT-CVIDREG::[ID];   <- Do not include shelf name (UTICA_258_2)
	print {$fh_DELETE_CVID_REG}("DLT-CVIDREG::" . $cleaned_up_id . ";\n");

	# NOTES:
	# For [Priority], If = Copy Bits, then use COPYPBITS (notice there is a "P" in there), 
	# If Priority has a value, then use that value (e.g. Priority 0, use PRIO=0)
    my $new_priority;
	if ($Priority eq 'Copy Bits')
	{
	  $new_priority = 'COPYPBITS';
	}
	elsif ($Priority eq 'Priority 0')
	{
	  $new_priority = '0';
	}
	elsif ($Priority eq 'Priority 1')
	{
	  $new_priority = '1';
	}	
	elsif ($Priority eq 'Priority 2')
	{
	  $new_priority = '2';
	}	
	elsif ($Priority eq 'Priority 3')
	{
	  $new_priority = '3';
	}	
	elsif ($Priority eq 'Priority 4')
	{
	  $new_priority = '4';
	}	
	elsif ($Priority eq 'Priority 5')
	{
	  $new_priority = '5';
	}	
	elsif ($Priority eq 'Priority 6')
	{
	  $new_priority = '6';
	}	
	elsif ($Priority eq 'Priority 7')
	{
	  $new_priority = '7';
	}	
	# ENT-CVIDREG::[ID]::::SVID=[SVID],PRIO=[Priority],RCVID=[RCVID];
	print {$fh_CREATE_CVID_REG}("ENT-CVIDREG::" . $cleaned_up_id . "::::SVID=" . $SVID . ",PRIO=" . $new_priority . ",RCVID=" . $RCVID . ";\n");
	
	print "----------------------------\n";
	print "id is $cleaned_up_id\n";
	print "SVID is $SVID\n";
	print "Priority is $new_priority\n";
	print "RCVID is $RCVID\n";
	print "----------------------------\n";
	}
}

close $fh_error;
close $fh_DELETE_CVID_REG;
close $fh_CREATE_CVID_REG;
