use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

##########################################################################
#
# Requirements
# VIDSUB_GPON_By_Shelf_Script_Generator_Script_Generator

# Script Generator Name: VIDSUB_GPON_By_Shelf_Script_Generator_Script_Generator.exe

# Script generator questions to ask the user:
  # 1. Please enter either the IP address or hostname of the C7 you want to reach:
  # 2. Enter the node-shelf that you want to retreive on (example N1-1 or N2-1):
  # 3. Enter the working IRC location (example: N1-1-20)
  
  # TL1 Command:
  # RTRV-VID-SUB::N15-2-ALL::::RTRAID=N1-1-7;
  
  # Syntax:  
  # RTRV-VID-SUB::[Quest #2]-ALL::::RTRAID=[Ques #3];
  
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Output:

  # "N15-2-1-2-2-1::RTRAID=N1-1-7,CHANCNT=5,VIDBW=20000,VIDLOANBW=0,"
  
  # Pattern match on all lines.
 
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create 2 output files:

# 1. VIDSUB_GPON_DELETES_FOR_Nx-x.txt  <-- Where Nx-x = Ques #2.
# 2. VIDSUB_GPON_CREATES_FOR_Nx-x.txt  <-- Where Nx-x = Ques #2.


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# File 1: VIDSUB_GPON_DELETES_FOR_Nx-x.txt
  # TL1 Command:
  # DLT-VID-SUB::N15-2-1-2-2-1::::RTRAID=N1-1-7;

# pattern match:
  # DLT-VID-SUB::[Source from output]::::RTRAID=[Ques #3];

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# File 2: VIDSUB_CREATES_FOR_Nx-x.txt

# TL1 Command:
  # ENT-VID-SUB::N15-2-1-2-2-1::::RTRAID=N1-1-7,CHANCNT=5,VIDBW=20000,VIDLOANBW=0;
   
# Pattern match:
  # ENT-VID-SUB::[Source from output]::::RTRAID=[Ques #3],CHANCNT=[From output],VIDBW=[From output],VIDLOANBW=[From output];
#
#
#
#
#
###########################################################################################################



	



##############################################################################################
#
# Counters to keep track of things
#
#
my $candidate_found = 0;
my $candidate_create = 0;
my $candidate_delete = 0;
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
print "VIDSUB_GPON_By_Shelf_TL1_Script_Generator\n";
print "\tWritten 6-05-2014\n";
print "\tRequirements provided by An Do\n";
print "\tCoded by Jason Murphy\n";

print "========================================================\n";
print "\n\n";
print "This script performs the following:\n";
print "1: Logs into a C7 and pulls VIDSUB GPON info\n";
print "2: Creates two text files VIDSUB DELETES and CREATES\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual modifications to the C7 system.\n";
print "========================================================\n";
  
print "\n\n";
print "========================================================\n";
print " Please enter either the IP address or hostname of the C7:\n";
print " Example: 10.208.25.59\n";
print ">";
my $ip = <STDIN>;
chomp($ip);


print "\n\n";
print "========================================================\n";
print "Enter the node-shelf that you want to retrieve on:\n";
print "      Example: N15-2\n";
print ">";
my $C7_xDSL_shelf = <STDIN>;
chomp($C7_xDSL_shelf);

print "\n\n";
print "========================================================\n";
print "Enter the working IRC location (example: N1-1-7):\n";
print ">";
my $irc_location = <STDIN>;
chomp($irc_location);


print "\n\n";

#
#
#
#
#
##############################################################################################




##############################################################################################
#
#	Telnet to C7 to retrieve ONT data
#
#
#
#
my $user_name = 'c7support';
   
my $shell = C7::Cmd->new($ip, 23);
$shell->connect;
my ($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
my $password = $shell->computeForgottenPassword( $date, $sid );


my $t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs.txt' );

  #C7 IP/Hostname to open, change this to the one you want.
$t->open($ip);

  #Wait for prompt to appear;
$t->waitfor('/>/ms');

print "\n\n\n\n\n\n";
print "========================\n";
print "Logging in to C7 at $ip\n";
print "========================\n";
  #Send default username/password (Not using cracker here)
$t->send("ACT-USER::");
$t->send($user_name);
$t->send(":::");
$t->send($password);
$t->send(";");

  #The actual return prompt is a semicolon at the end of the output, so wait for this
$t->waitfor('/^;/ms');
print "=============================\n";
print "We are logged in successfully\n";
print "=============================\n";

# Inhibit Message All
$t->send("INH-MSG-ALL;");
$t->waitfor('/^;/ms');

$t->timeout(undef);
$t->send("RTRV-VID-SUB::" .$C7_xDSL_shelf. "-ALL::::RTRAID=" .$irc_location. ";");

  
print "=============================\n";
print "I am retrieving all VIDSUBS on " .$C7_xDSL_shelf. "\n";  
print "Please be patient.\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the VIDSUBs on " .$irc_location. "\n";
print "======================================\n";

# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:
$t->timeout(30);

 #Logout
$t->send('CANC-USER;');
print "======================================\n";
print "Logging out of the C7 at $ip\n";
print "======================================\n";
$t->close;

print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and create the C7 DELETE and CREATEs files\n";
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
my $DATA_FILE = 'tl1_logs.txt';			
my $line;

my $fh_C7_CREATES;		# File handle for CREATES
my $CREATES_FILE = 'VIDSUB_GPON_CREATES_FOR_' .$C7_xDSL_shelf. '.txt';
open $fh_C7_CREATES, ">", $CREATES_FILE or die "Couldn't open $CREATES_FILE: $!\n";

my $fh_C7_DELETES;		# File handle for DELETES
my $DELETES_FILE = 'VIDSUB_GPON_DELETES_FOR_' .$C7_xDSL_shelf. '.txt';
open $fh_C7_DELETES, ">", $DELETES_FILE or die "Couldn't open $DELETES_FILE: $!\n";

# File handle stuff for the error file
my $fh_error;		# File handle for errors
my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' .$C7_xDSL_shelf. '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

# Open the data file for reading in the tl1_logs.txt
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# 
# 
# 
# 
##############################################################################################



##############################################################################################
#
# Open the TL1 Logs, Pattern Match and Write out to the CREATES and DELETES Files
#
#
#
while ($line = <$fh> )
{
  chomp($line);

  
 
  # "N15-2-1-2-2-1::RTRAID=N1-1-7,CHANCNT=5,VIDBW=20000,VIDLOANBW=0,"
  # "N15-1-1-1-CH0::RTRAID=N1-1-7,CHANCNT=3,VIDBW=14600,VIDLOANBW=10000,STBIP=10.20.75.111"
  if 
  (
	$line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+)::RTRAID=N\d+-\d+-\d+,CHANCNT=(\w+),VIDBW=(\w+),VIDLOANBW=(\w+)[,"]!  
   )
   {
	 my $dest = 		$1;
	 my $chancnt =  	$2;
	 my $vidbw = 		$3;
	 my $vidloanbw = 	$4;
	 $candidate_found++; 


	##################################################################
	#
	# DELETES
	# File 1: VIDSUB_GPON_DELETES_FOR_Nx-x.txt
	#
	# TL1 Command: 
	# DLT-VID-SUB::N15-2-1-2-2-1::::RTRAID=N1-1-7;
	#
	# pattern match:
	# DLT-VID-SUB::[Source from output]::::RTRAID=[Ques #3];

	print {$fh_C7_DELETES} ("DLT-VID-SUB::" .$dest. "::::RTRAID=" . $irc_location . ";\n");
	$candidate_delete++;
	
	##################################################################
	#
	# CREATES
	# File 2: VIDSUB_GPON_CREATES_FOR_Nx-x.txt

	# TL1 Command:
	# ENT-VID-SUB::N15-2-1-2-2-1::::RTRAID=N1-1-7,CHANCNT=5,VIDBW=20000,VIDLOANBW=0;
  
	# Pattern match:
    # ENT-VID-SUB::[Source from output]::::RTRAID=[Ques #3],CHANCNT=[From output],VIDBW=[From output],VIDLOANBW=[From output];

	

	
  	print {$fh_C7_CREATES} ("ENT-VID-SUB::" .$dest. "::::RTRAID=" .$irc_location. ",CHANCNT=" .$chancnt. ",VIDBW=" .$vidbw. ",VIDLOANBW=" .$vidloanbw. ";\n");
	$candidate_create++;
   }
   # No match at all - write it to the error log and increment the $ont_not_matched counter
   else 
   {
		print {$fh_error} ("No match for: $line \n");
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
close $fh_C7_CREATES;
close $fh_C7_DELETES;
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
print "Results of VIDUSB_xDSL By Shelf TL1 Script Generator:\n";

print "Candidate xcon found:\t $candidate_found\n";	
print "VIDSUB xcon written to CREATES:\t $candidate_create\n";
print "VIDSUB xcon written to DELETES:\t $candidate_delete\n";

print "=================================================================\n";
#
#
##############################################################################################




