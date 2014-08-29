use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;
##############################################################################################
#
# C7 Combo RPOTS T0 to VEP By Card Script Generator
# Written 4/2/2014 Jason Murphy
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
print "C7 Combo RPOTS T0 to VEP By Card Script Generator\n";
print "\tWritten 4-2-2014\n";
print "\tRequirements by An Do\n";
print "\tCoded by Jason Murphy\n";

print "========================================================\n";
print "\n\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual modifications to the E7 system.\n";
print "========================================================\n";

print "\n\n";
print "========================================================\n";
print "Enter the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

print "\n\n";
print "========================================================\n";
print "Enter the COMBO or RPOTS node-shelf-slot you want to retrieve:\n";
print "      Example: N1-1-1 or N2-1-20\n";
print ">";
my $C7_COMBO_card = <STDIN>;
chomp($C7_COMBO_card);


print "\n\n";
print "========================================================\n";
print "Enter the C7 TDMGW IG (example N3-1-IG4):\n";
print ">";
my $C7_TDMGW_IG = <STDIN>;
chomp($C7_TDMGW_IG);


print "\n\n";
print "========================================================\n";
print "Enter the C7 SIPVCG IG (example N1-1-IG5):\n";
print ">";
my $C7_SIPVCG_IG = <STDIN>;
chomp($C7_SIPVCG_IG);



print "====================================\n";
print "\nOk - time to launch telnet session\n";
print "====================================\n";
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
$t->send("RTRV-CRS-T0::$C7_COMBO_card-all;");
print "=============================\n";
print "I am retrieving all T0 ports on $C7_COMBO_card\n";  
print "Please be patient.\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the T0 ports on $C7_COMBO_card\n";
print "======================================\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->timeout(30);

#$t->prompt('/^;/ms');
#Now it will automatically send/waitfor with cmd command
#$t->cmd('inh-msg-all;');
#$t->cmd('inh-msg-all;');

 #Logout
$t->send('CANC-USER;');
print "======================================\n";
print "Logging out of the C7 at $ip\n";
print "======================================\n";
$t->close;

print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and create 3 separate files.\n";
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


my $fh_C7_DELETES;		
my $DELETES_FILE = 'Delete_T0_CRS_' . $C7_COMBO_card . '.txt';
open $fh_C7_DELETES, ">", $DELETES_FILE or die "Couldn't open $DELETES_FILE: $!\n";

my $fh_C7_SIPVCG_CREATES;		
my $SIPVCG_CREATES_FILE = 'Create_SIPVCG_CRS_' . $C7_COMBO_card . '.txt';
open $fh_C7_SIPVCG_CREATES, ">", $SIPVCG_CREATES_FILE or die "Couldn't open $SIPVCG_CREATES_FILE: $!\n";

my $fh_C7_VEP_CREATES;		
my $VEP_CREATES_FILE = 'Create_VEP_' . $C7_COMBO_card . '.txt';
open $fh_C7_VEP_CREATES, ">", $VEP_CREATES_FILE or die "Couldn't open $VEP_CREATES_FILE: $!\n";

my $fh_C7_VEP_CRS_CREATES;		
my $VEP_CRS_CREATES_FILE = 'Create_VEP_CRS_To_TDMGW_' . $C7_COMBO_card . '.txt';
open $fh_C7_VEP_CRS_CREATES, ">", $VEP_CRS_CREATES_FILE or die "Couldn't open $VEP_CRS_CREATES_FILE: $!\n";


# File handle stuff for the error file
my $fh_error;		# File handle for errors
my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' . $C7_COMBO_card  . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

# Open the data file for reading in the tl1_logs.txt
my $DATA_FILE = 'tl1_logs.txt';			
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
my $temp_RTLP;


##############################################################################################
#
# Open the TL1 Logs, Pattern Match and Write out to the CREATES and DELETES Files
#
#
#
while ($line = <$fh> )
{
  chomp($line);
  
	# 4-2-2014 Line to match:
	# "N1-1-IG2-401,N3-1-17-1:2WAY:NSG=4,NDS0=1,NAILUP=N,BWC=,IG=,TVC=,"


	if ($line =~ m!(N\d+-\d+-IG\d+-\d+),((N\d+-\d+-\d+)-(\d+)):!)
	{	
		# $1 is the IG line
		# $2 is the entire L2IFAID for the access port
		# $3 is the access port node-shelf-slot
		# $4 is the access port port #
		print {$fh_C7_DELETES} ("DLT-CRS-T0::$1,$2;\n");

		print {$fh_C7_SIPVCG_CREATES} ("ENT-CRS-T0::$1,$C7_SIPVCG_IG-NEXT;\n");

		
		# ENT-VEP::N3-1-17-VEP1::::IGAID=N3-1-IG4,AOR=N1-1-IG2-401;
		# ENT-VEP::[Dest from Output where the last digit (port number) is the VEP#]::::IGAID=Question 3,AOR=[CRV from Output];
		# ::::IGAID=Question 3,AOR=[CRV from Output];
		print {$fh_C7_VEP_CREATES}("ENT-VEP::$3-VEP$4::::IGAID=$C7_TDMGW_IG,AOR=$1;\n");
		
		
		
		# File name:
		# Create_VEP_CRS_To_TDMGW_Nx-x-x <-- Where Nx-x-x = Question2.

		# TL1 Output:
		# ENT-CRS-T0::N3-1-IG4-NEXT,N3-1-17-VEP1;

		# Pattern Match:
		# ENT-CRS-T0::[Ques #3 add -NEXT],[Dest from Output where the last digit (port number) is the VEP#];

		
		# ENT-CRS-T0::N3-1-17-VEP1,N3-1-IG4-NEXT
		# ENT-CRS-T0::[Dest from Output where the last digit (port number) is the VEP#],[Ques #3 add -NEXT];

		# An Do: The Source and Destination need to be switched on the output
		print {$fh_C7_VEP_CRS_CREATES}("ENT-CRS-T0::$C7_TDMGW_IG-NEXT,$3-VEP$4;\n");
		
		
		$xcon_written++;
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
close $fh_C7_DELETES;
close $fh_C7_SIPVCG_CREATES;
close $fh_C7_VEP_CREATES;
close $fh_C7_VEP_CRS_CREATES;
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

print" Total Voice entries written out: $xcon_written\n";

print" Total xcons not matched: $xcon_not_matched\n";

print "=================================================================\n";
#
#
##############################################################################################




