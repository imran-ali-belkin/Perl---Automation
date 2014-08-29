use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;
##############################################################################################
#
# CSV to E7 GPON T0 Subscriber_ID Script Generator
# Written 3/13/2014 Jason Murphy
#
##############################################################################################

##############################################################################################
#
# Counters to keep track of things
#
#
my $xcon_found = 0;
my $xcon_written = 0;
my $xcon_not_matched = 0;

my $xcon_written_port_1 = 0;
my $xcon_written_port_2 = 0;
my $xcon_written_port_3 = 0;
my $xcon_written_port_4 = 0;

#
#
#
##############################################################################################


##############################################################################################
#
#	User Interface Section
#
#
#
#
print "========================================================\n";
print "CSV to E7 GPON T0 Subscriber_ID Script Generator\n";
print "\tWritten 3-14-2014\n";
print "\tRequirements by An Do\n";
print "\tCoded by Jason Murphy\n";

print "========================================================\n";
print "\n\n";
print "This script performs the following:\n";
print "1: Extracts the L2IFAID and Subscriber_ID from a CSV file\n";
print "2: Creates one text file that contains the E7 syntax\n";
print "========================================================\n";

print "\n\n";
print "========================================================\n";
print "Enter the name of the CSV file:\n";
print ">";
my $DATA_FILE = <STDIN>;
chomp($DATA_FILE);

print "\n\n";
print "========================================================\n";
print "Enter the C7 GPON card Node-Shelf-Slot you want to retrieve:\n";
print "      Example: N1-1-2 or N2-1-20\n";
print ">";
my $C7_gpon_card = <STDIN>;
chomp($C7_gpon_card);

print "\n\n";
print "========================================================\n";
print "Enter the E7 start ONT pre-fix for GPON PORT 1:\n";
print ">";
my $gpon_port_1_prefix = <STDIN>;
chomp($gpon_port_1_prefix);

print "\n\n";
print "========================================================\n";
print "Enter the E7 start ONT pre-fix for GPON PORT 2:\n";
print ">";
my $gpon_port_2_prefix = <STDIN>;
chomp($gpon_port_2_prefix);

print "\n\n";
print "========================================================\n";
print "Enter the E7 start ONT pre-fix for GPON PORT 3:\n";
print ">";
my $gpon_port_3_prefix = <STDIN>;
chomp($gpon_port_3_prefix);

print "\n\n";
print "========================================================\n";
print "Enter the E7 start ONT pre-fix for GPON PORT 4:\n";
print ">";
my $gpon_port_4_prefix = <STDIN>;
chomp($gpon_port_4_prefix);

print "====================================\n";
print "\nOk - time to process\n";
print "====================================\n";
#
#
#
#
#
##############################################################################################



print "=====================================================\n";
print "Now I am going to read in the CSV (comma separated) file\n";
print "and create the E7 edit file.\n";
print "=====================================================\n";
#
#
#
#
##############################################################################################
 
 
 
 
##############################################################################################
#
# File Handles 
# 
my $line;


# File Output Name: 
# E7_ONT_T0_Voice_Port_Settings_Nx-x-x
# (where Nx-x-x is the card in question #2).

my $fh_E7_CREATES;		# File handle for E7 syntax
my $DESTINATION_FILE_1 = 'E7_ONT_Voice_Port_Settings_' . $C7_gpon_card . '.txt';
open $fh_E7_CREATES, ">", $DESTINATION_FILE_1 or die "Couldn't open $DESTINATION_FILE_1: $!\n";


# File handle stuff for the error file
my $fh_error;		# File handle for errors
my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' . $C7_gpon_card  . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

# Open the data file for reading in the tl1_logs.txt
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# Open the destination file for writing out the E7 syntax
# 
# 
# 
# 
##############################################################################################


##############################################################################################
#
# Variables used
#
my $temp_ont;


##############################################################################################
#
# Open the TL1 Logs, Pattern Match and Write out to the CREATES and DELETES Files
#
#
#
while ($line = <$fh> )
{
  chomp($line);
  
  my ($L2IFAID, $SUBSCRIBER_ID) = split(',' , $line);
  chomp($L2IFAID);
  chomp($SUBSCRIBER_ID);
  
  # Just at a high level verify that we are operating on the correct GPON card
  if ( $L2IFAID =~ $C7_gpon_card)		
  {
		my ($node,$shelf,$slot,$GPON_Port,$ONT,$T0_Port) = split ('-',$L2IFAID);
	 
			
			# Logic to put a zero in front of any ONTs numbered 1-9
			if ($ONT eq '1')
			{
				$temp_ont = '01';
			}
			elsif ($ONT eq '2')
			{
				$temp_ont = '02';
			}
			elsif ($ONT eq '3')
			{
				$temp_ont = '03';
			}
			elsif ($ONT eq '4')
			{
				$temp_ont = '04';
			}
			elsif ($ONT eq '5')
			{
				$temp_ont = '05';
			}
			elsif ($ONT eq '6')
			{
				$temp_ont = '06';
			}
			elsif ($ONT eq '7')
			{
				$temp_ont = '07';
			}
			elsif ($ONT eq '8')
			{
				$temp_ont = '08';
			}
			elsif ($ONT eq '9')
			{
				$temp_ont = '09';
			}
			else
			{
				$temp_ont = $ONT;
			}
			
			
			# If PON port 1
			if ( $GPON_Port eq '1')
			{ 
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_1_prefix$temp_ont/p$T0_Port subscriber-id \"$SUBSCRIBER_ID\" admin-state enabled\n");
					$xcon_written_port_1++;
					$xcon_written++;
			}
			# If PON port 2
			elsif ( $GPON_Port eq '2')
			{ 
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_2_prefix$temp_ont/p$T0_Port subscriber-id \"$SUBSCRIBER_ID\" admin-state enabled\n");
					$xcon_written_port_2++;
					$xcon_written++;	
			}
			# If PON port 3
			elsif ( $GPON_Port eq '3')
			{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_3_prefix$temp_ont/p$T0_Port subscriber-id \"$SUBSCRIBER_ID\" admin-state enabled\n");
					$xcon_written_port_3++;
					$xcon_written++;
			}			
			# If PON port 4
			elsif ( $GPON_Port eq '4')
			{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_4_prefix$temp_ont/p$T0_Port subscriber-id \"$SUBSCRIBER_ID\" admin-state enabled\n");
					$xcon_written_port_4++;
					$xcon_written++;
			}			
		}
	 # No match at all - write it to the error log and increment the $ont_not_matched counter
	 else 
	 {
		print {$fh_error} ("No match for: $line \n");
		$xcon_not_matched++;
	 }
			 
}

#	End of all the pattern matching and manipulation
#
#
#
##############################################################################################



##############################################################################################
#
# File Handles - Close them
#
#
close $fh_E7_CREATES;
close $fh;
close $fh_error;
#
#
#
#
##############################################################################################



##############################################################################################
#
# Let the user know the results
#
#
#
print "=================================================================\n";
print "Results:\n";

print "E7 statement written for GPON port 1:\t $xcon_written_port_1\n";
print "E7 statement written for GPON port 2:\t $xcon_written_port_2\n";
print "E7 statement written for GPON port 3:\t $xcon_written_port_3\n";
print "E7 statement written for GPON port 4:\t $xcon_written_port_4\n";

print" Total Voice entries written out to E7 file: $xcon_written\n";

print" Total xcons not matched: $xcon_not_matched\n";

print "=================================================================\n";
#
#
##############################################################################################




