use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

##########################################################################
#
# Requirements
#
#
# VIDSUBCHAN_xDSL_By_Shelf_Script_Generator

# Script Generator Name: VIDSUBCHAN_xDSL_By_Shelf_Script_Generator_Script_Generator.exe

# Script generator questions to ask the user:
  # 1. Please enter either the IP address or hostname of the C7 you want to reach:		$ip
  # 2. Enter the node-shelf that you want to retrieve on (example N1-1 or N2-1):		$C7_xDSL_shelf
  # 3. Enter the working IRC location (example: N1-1-20)								$irc_location
  
# TL1 Command:
  # RTRV-CRS-VIDVC::N15-1-ALL::::IRCAID=N1-1-7,APP=VIDSUBCHNL;  
  #
  # Syntax:
  # RTRV-CRS-VIDVC::[Ques #2]-ALL::::IRCAID=[Ques #3],APP=VIDSUBCHNL;
  
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Output:
 # "N15-1-1-PP2-VP0-VC1011,N15-1-1-1-CH0-VP0-VC36::TRFPROF=76,PATH=UNPROT,APP=VIDSUBCHNL,CONSTAT=COMMFAIL" 
 # Only pattern match on all CRS (they should all be UNPROT).
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


# Create 2 output files:
# 1. VIDSUBCHAN_DELETES_FOR_Nx-x.txt  <-- Where Nx-x = Ques #2.
# 2. VIDSUBCHAN_CREATES_FOR_Nx-x.txt  <-- Where Nx-x = Ques #2.

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# File 1: VIDSUBCHAN_DELETES_FOR_Nx-x.txt

# TL1 Command:
 
  # DLT-CRS-VIDVC::N15-1-1-PP2-VP0-VC1011,N15-1-1-1-CH0-VP0-VC36::::IRCAID=N1-1-7;

# pattern match:
  # DLT-CRS-VIDVC::[Source from output],[DEST from output]::::IRCAID=[Ques #3];

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# File 2: VIDSUBCHAN_CREATES_FOR_Nx-x.txt

# TL1 Command:
  # ENT-CRS-VIDVC::N15-1-1-PP2-VP0-VC1011,N15-1-1-1-CH0-VP0-VC36::::IRCAID=N1-1-7,TRFPROF=76,PATH=UNPROT;
  
# Pattern match:
  # ENT-CRS-VIDVC::[Source from output],[DEST from output]::::IRCAID=[Ques #3],TRFPROF=[from output],PATH=UNPROT;  	
#
#
#
#######################################################################################################################


	



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
print "VIDSUBCHAN_xDSL_By_Shelf_Script_Generator\n";
print "\tWritten 6-05-2014\n";
print "\tRequirements provided by An Do\n";
print "\tCoded by Jason Murphy\n";

print "========================================================\n";
print "\n\n";
print "This script performs the following:\n";
print "1: Logs into a C7 and pulls VIDSUB xDSL info\n";
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
print "      Example: N15-1\n";
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

# RTRV-CRS-VIDVC::N15-1-ALL::::IRCAID=N1-1-7,APP=VIDSUBCHNL;  
$t->timeout(undef);
$t->send("RTRV-CRS-VIDVC::" .$C7_xDSL_shelf. "-ALL::::IRCAID=" .$irc_location. ",APP=VIDSUBCHNL;");


  
print "=============================\n";
print "I am retrieving all xcons with APP=VIDSUBCHNL on " .$C7_xDSL_shelf. "\n";  
print "Please be patient.\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the IPVCs on " .$irc_location. "\n";
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
my $CREATES_FILE = 'VIDSUBCHAN_CREATES_FOR_' .$C7_xDSL_shelf. '.txt';
open $fh_C7_CREATES, ">", $CREATES_FILE or die "Couldn't open $CREATES_FILE: $!\n";

my $fh_C7_DELETES;		# File handle for DELETES
my $DELETES_FILE = 'VIDSUBCHAN_DELETES_FOR_' .$C7_xDSL_shelf. '.txt';
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

  
   # "N15-1-1-PP2-VP0-VC1011,N15-1-1-1-CH0-VP0-VC36::TRFPROF=76,PATH=UNPROT,APP=VIDSUBCHNL,CONSTAT=COMMFAIL"
  if 
  (
	$line =~ m!(N\d+-\d+-\d+-PP2-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+)::TRFPROF=(\w+),PATH=(UNPROT),APP=VIDSUBCHNL,!  
   )
   {
     my $source = 	$1;
	 my $dest = 	$2;
	 my $trfprof =  $3;
	 my $path = 	$5;
	 
	 $candidate_found++; 

	##################################################################
	#
	# DELETES
	#
	# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	# File 1: VIDSUBCHAN_DELETES_FOR_Nx-x.txt

	# TL1 Command:
 
	# DLT-CRS-VIDVC::N15-1-1-PP2-VP0-VC1011,N15-1-1-1-CH0-VP0-VC36::::IRCAID=N1-1-7;

	# pattern match:
	# DLT-CRS-VIDVC::[Source from output],[DEST from output]::::IRCAID=[Ques #3];

	# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	# DLT-CRS-VIDVC::N15-1-1-PP2-VP0-VC1011,N15-1-1-1-CH0-VP0-VC36::::IRCAID=N1-1-7;	
	print {$fh_C7_DELETES} ("DLT-CRS-VIDVC::" .$source. "," .$dest. "::::IRCAID=" . $irc_location . ";\n");
	$candidate_delete++;
	
	##################################################################
	#
	# CREATES
    # File 2: VIDSUBCHAN_CREATES_FOR_Nx-x.txt

	# TL1 Command:
	# ENT-CRS-VIDVC::N15-1-1-PP2-VP0-VC1011,N15-1-1-1-CH0-VP0-VC36::::IRCAID=N1-1-7,TRFPROF=76,PATH=UNPROT;
  
	# 	Pattern match:
	# ENT-CRS-VIDVC::[Source from output],[DEST from output]::::IRCAID=[Ques #3],TRFPROF=[from output],PATH=UNPROT;  	
  	print {$fh_C7_CREATES} ("ENT-CRS-VIDVC::" .$source. "," .$dest. "::::IRCAID=" .$irc_location. ",TRFPROF=" .$trfprof. ",PATH=UNPROT;\n");
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
print "Results of VIDSUBCHAN_xDSL By Shelf TL1 Script Generator:\n";

print "Candidate xcon found:\t $candidate_found\n";	
print "VIDSUBCHAN xcon written to CREATES:\t $candidate_create\n";
print "VIDSUBCHAN xcon written to DELETES:\t $candidate_delete\n";

print "=================================================================\n";
#
#
##############################################################################################




