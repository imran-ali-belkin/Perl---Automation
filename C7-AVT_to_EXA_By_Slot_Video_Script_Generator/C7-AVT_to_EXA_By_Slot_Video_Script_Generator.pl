use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;
##############################################################################################
#
# C7 Video AVT to EXA Script Generator
# Written 4/14/2014 Jason Murphy
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
print "The C7 Video AVT to EXA Script Generator\n";
print "\tWritten 4-14-2014\n";
print "\tRequirements by An Do\n";
print "\tCoded by Jason Murphy\n";

print "========================================================\n";
print "\n\n";
print "This script performs the following:\n";
print "1: Logs into a C7 and pulls Video related constructs\n";
print "2: Creates three text files that contains C7 syntax\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual modifications to the C7 system.\n";
print "========================================================\n";

print "\n\n";
print "========================================================\n";
print "Enter the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

print "\n\n";
print "========================================================\n";
print "Enter the C7 GPON card Node-Shelf-Slot you want to retrieve:\n";
print "      Example: N1-1-2 or N2-1-20\n";
print ">";
my $C7_gpon_card = <STDIN>;
chomp($C7_gpon_card);

print "\n\n";
print "========================================================\n";
print "Enter the Active IRC node-shelf-slot you want to retrieve:\n";
print "      Example: N1-1-2 or N2-1-20\n";
print ">";
my $IRC_card = <STDIN>;
chomp($IRC_card);


print "\n\n";
print "========================================================\n";
print "Enter the the EXA Video VLANIF Template ID:\n";
print ">";
my $EXA_Video_VLANIF_Template_ID = <STDIN>;
chomp($EXA_Video_VLANIF_Template_ID);

print "\n\n";
print "========================================================\n";
print "Enter the the EXA Unicast VLAN:\n";
print "\tExample: 205\n";
print ">";
my $EXA_Video_Unicast_VLAN = <STDIN>;
chomp($EXA_Video_Unicast_VLAN);


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
$t->send("RTRV-CRS-VIDVC::$C7_gpon_card-all::::IRCAID=$IRC_card,APP=IP;");
print "=============================\n";
print "I am retrieving the VIDVC IRC stuff\n";  
print "Please be patient.\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the IRC stuff for $C7_gpon_card\n";
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

# 1_DLT-VID-SUB_FOR_Nx-x-x.txt					$fh_Delete_Vid_Subs			$FILE_Delete_Vid_Subs
# 2_DLT-CRS-VIDVC_FOR_Nx-x-x.txt				$fh_Delete_CRS_VIDVC	 	$FILE_Delete_CRS_VIDVC
# 3_EXA_ENT-VLAN-IF_Creates_FOR_Nx-x-x.txt		$fh_ENT_VLAN_IF				$FILE_ENT_VLAN_IF

# 1_DLT-VID-SUB_FOR_Nx-x-x.txt					$fh_Delete_Vid_Subs			$FILE_Delete_Vid_Subs
my $fh_Delete_Vid_Subs;				
my $FILE_Delete_Vid_Subs = '1_DLT-VID-SUB_FOR_' . $C7_gpon_card . '.txt';
open $fh_Delete_Vid_Subs, ">", $FILE_Delete_Vid_Subs or die "Couldn't open $FILE_Delete_Vid_Subs: $!\n";

# 2_DLT-CRS-VIDVC_FOR_Nx-x-x.txt				$fh_Delete_CRS_VIDVC	 	$FILE_Delete_CRS_VIDVC
my $fh_Delete_CRS_VIDVC;				
my $FILE_Delete_CRS_VIDVC = '2_DLT-CRS-VIDVC_FOR_' . $C7_gpon_card . '.txt';
open $fh_Delete_CRS_VIDVC, ">", $FILE_Delete_CRS_VIDVC or die "Couldn't open $FILE_Delete_CRS_VIDVC: $!\n";

# 3_EXA_ENT-VLAN-IF_Creates_FOR_Nx-x-x.txt		$fh_ENT_VLAN_IF				$FILE_ENT_VLAN_IF
my $fh_ENT_VLAN_IF;				
my $FILE_ENT_VLAN_IF = '3_EXA_ENT-VLAN-IF_Creates_FOR_' . $C7_gpon_card . '.txt';
open $fh_ENT_VLAN_IF, ">", $FILE_ENT_VLAN_IF or die "Couldn't open $FILE_ENT_VLAN_IF: $!\n";

# File handle stuff for the error file
my $fh_error;		# File handle for errors
my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' . $C7_gpon_card  . '.txt';
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
my $irc_pseudo_port;
my $subscriber_no_index = 'test';
my $subscriber_including_index = 'test';


##############################################################################################
#
# Open the TL1 Logs, Pattern Match and Write out to the CREATES and DELETES Files
#
#
#
while ($line = <$fh> )
{
  chomp($line);
	
	 # Just a high level filter
	 if ($line =~ /N\d+-\d+-\d+-PP\d+-VP\d+-VC\d+/)
	 {	 
		 # 4/14 JEM
		 # "N1-1-20-PP1-VP0-VC60,N1-1-7-1-1-1-3::TRFPROF=1,BCKPROF=1,PATH=UNPROT,ARP=N,PARP=Y,APP=IP,CONSTAT=NORMAL"	          
		 if ( $line =~ m!(N\d+-\d+-\d+-PP\d+-VP\d+-VC\d+),((N\d+-\d+-\d+-\d+-\d+-\d+)-\d+)::TRFPROF=\w+,BCKPROF=\w+,PATH=\w+,ARP=\w+,PARP=\w+,APP=\w+,!)
		 {		
			$irc_pseudo_port = $1;
			$subscriber_no_index = $3;
			$subscriber_including_index = $2;
			
			# $C7_gpon_card
			# $IRC_card
			# $EXA_Video_VLANIF_Template_ID
			# $EXA_Video_Unicast_VLAN
			
			# DLT-VID-SUB::N1-1-7-1-1-1::::RTRAID=N1-1-20;
			# DLT-VID-SUB::[Dest_From_Output--Node#-Shelf-Slot-GPON-ONT-Port(Do not need index number!!)]::::RTRAID=[Quest #3];
			print {$fh_Delete_Vid_Subs} ("DLT-VID-SUB::" . $subscriber_no_index . "::::RTRAID=" . $IRC_card . ";\n");

			# DLT-CRS-VIDVC::N1-1-20-PP1-VP0-VC60,N1-1-7-1-1-1-3::::IRCAID=N1-1-20,INCL=Y;
			# DLT-CRS-VIDVC::[Source_From_Output],[Dest_From_Output]::::IRCAID=[Ques #3],INCL=Y;
			print {$fh_Delete_CRS_VIDVC} ("DLT-CRS-VIDVC::" . $irc_pseudo_port . "," . $subscriber_including_index . "::::" . "IRCAID=" . $IRC_card . ",INCL=Y;\n");

			# ENT-VLAN-IF::N1-1-7-1-1-1::::VLAN=101,BRIDGE=LOCAL,TMPLT=10,CVID=UNTAGGED,RCVID=NONE,PRIO=0;
			# ENT-VLAN-IF::[Dest_From_Output--Node#-Shelf-Slot-GPON-ONT-Port(Do not need index number!!)]:::VLAN=[Ques #5],BRIDGE=LOCAL,TMPLT=[Ques #4],CVID=UNTAGGED,RCVID=NONE,PRIO=0;
			print {$fh_ENT_VLAN_IF} ("ENT-VLAN-IF::" . $subscriber_no_index . "::::VLAN=" . $EXA_Video_Unicast_VLAN . ",BRIDGE=LOCAL,TMPLT=" . $EXA_Video_VLANIF_Template_ID . ",CVID=UNTAGGED,RCVID=NONE,PRIO=0;\n");
			$xcon_written++;
		 }				
		# No match at all - write it to the error log and increment the $ont_not_matched counter
		 else 
		 {
			print {$fh_error} ("No match for: $line \n");
			$xcon_not_matched++;
		 }	
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
close $fh_Delete_Vid_Subs;
close $fh_Delete_CRS_VIDVC;
close $fh_ENT_VLAN_IF;
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

print "Writes to each file:\t$xcon_written\n";

print" Total not matched:\t$xcon_not_matched\n";

print "=================================================================\n";
#
#
##############################################################################################




