use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

##############################################################################################
#
# Counters to keep track of things
#
my $vlanif_found 			= 0;
my $vlanif_not_matched 		= 0;
#
#
##############################################################################################


##############################################################################################
#
#	User Interface Section
#
print "========================================================\n";
print "The ATM_Downlink_Ethernet_Uplink_Move_By_VLAN_Script_Generator\n";
print "\tWritten 5-09-2014\n";
print "\tRequirements by: 	An Do\n";
print "\tCoded by:			Jason Murphy\n";
print "\n\n";
print "This script performs the following:\n";
print "1: Logs into a C7 and pulls VLANIFs\n";
print "2: Creates text files for DELETES and CREATES\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual modifications to the C7 system.\n";
print "========================================================\n";

print "\n\n";
print "========================================================\n";
print "1. Enter the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

print "\n\n";
print "========================================================\n";
print "2. Enter the existing VLAN to retreive on (example 8):\n";
print ">";
my $existing_VLAN = <STDIN>;
chomp($existing_VLAN);

print "\n\n";
print "========================================================\n";
print "3. Enter the existing VB (example N1-1-VB1):\n";
print ">";
my $existing_VB = <STDIN>;
chomp($existing_VB);

print "\n\n";
print "========================================================\n";
print "4. Enter the new uplink VB (example N2-1-VB1):\n";
print ">";
my $new_uplink_VB = <STDIN>;
chomp($new_uplink_VB);

print "\n\n";
print "========================================================\n";
print "5. Enter the new uplink VLAN (example 100):\n";
print ">";
my $new_uplink_VLAN = <STDIN>;
chomp($new_uplink_VLAN);

print "\n\n";
print "========================================================\n";
print "6. Enter the VBPORT start value (example 500):\n";
print ">";
my $VBPORT_start_value = <STDIN>;
chomp($VBPORT_start_value);

print "\nOk - time to launch telnet session\n";
#
#
##############################################################################################




##############################################################################################
#
#	Telnet to C7 to retrieve ONT data
#
#
my $user_name = 'c7support';
   
my $shell = C7::Cmd->new($ip, 23);
$shell->connect;
my ($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
my $password = $shell->computeForgottenPassword( $date, $sid );

my $t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs.txt' );

# C7 IP/Hostname to open, change this to the one you want.
$t->open($ip);

# Wait for prompt to appear;
$t->waitfor('/>/ms');

print "\n\n\n\n\n\n";
print "========================\n";
print "Logging in to C7 at $ip\n";
print "========================\n";

# Send default username/password (Not using cracker here)
$t->send("ACT-USER::");
$t->send($user_name);
$t->send(":::");
$t->send($password);
$t->send(";");

# The actual return prompt is a semicolon at the end of the output, so wait for this
$t->waitfor('/^;/ms');
print "=============================\n";
print "We are logged in successfully\n";
print "=============================\n";

# Inhibit Message All
$t->send("INH-MSG-ALL;");
$t->waitfor('/^;/ms');

$t->timeout(undef);

###################################################
#
#	TL1 Command sent to the C7: 
#   VLANIF Retrieval
#	RTRV-VLAN-IF::ALL::::VLAN=8,BRIDGE=N1-1-VB1;
#   
$t->send("RTRV-VLAN-IF::ALL::::VLAN=$existing_VLAN,BRIDGE=$existing_VB;");
print "=============================\n";
print "I am retrieving all VLAN-IFs for:\n";  
print "\tVLAN $existing_VLAN\n";  
print "\tBRIDGE $existing_VB\n";  
print "Please be patient.\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the VLANIFs\n";
print "======================================\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->timeout(30);


 #Logout
$t->send('CANC-USER;');
print "======================================\n";
print "Logging out of the C7 at $ip\n";
print "======================================\n";
$t->close;


print "\n\n";
print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and output C7 syntax commands\n\n";
print "The following files will be created:\n";
print '1_DELETES_FOR_VLAN' . $existing_VLAN . '.txt';
print "\n";
print '2_CREATES_FOR_VLAN' . $new_uplink_VLAN . '.txt';
print "\n";
print "=====================================================\n\n";
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

# File handle for DELETES
my $fh_C7_DELETES;				
my $DELETES_FILE = '1_DELETES_FOR_VLAN' . $existing_VLAN . '.txt';
open $fh_C7_DELETES, ">", $DELETES_FILE or die "Couldn't open $DELETES_FILE: $!\n";


# File handle for CREATES
my $fh_C7_CREATES;				
my $CREATES_FILE = '2_CREATES_FOR_VLAN' . $new_uplink_VLAN . '.txt';
open $fh_C7_CREATES, ">", $CREATES_FILE or die "Couldn't open $CREATES_FILE: $!\n";

	
# File handle stuff for the error file
my $fh_error;		# File handle for errors
my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' . $ip  . '.txt';
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
  
  # Concert ticket
  if ($line =~ m!\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+!)
  {
		# VIP Lounge
		if 
		 (
		 # REGEX for 5-9-2014
		 # "N4-1-9-1-1-VP117-VC107::VLAN=8,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,
		 # IGMP=NONE,PPPOEAC=N,PPPOESUB=N,LSVID=8,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,
		 # STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,CVID=UNTAGGED,SVID=8,PRIO=0,
		 # RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,MCASTPROF=NONE"
		 $line =~ 
		 (
		 m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+)::VLAN=(\d+),BRIDGE=(N\d+-\d+-VB\d+),ARP=(\w+),DHCPDIR=CLIENT,OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=N,PPPOESUB=(\w+),LSVID=(\d+),ENCAP=(\w+),DOS=(\w+),STP=OFF,STPCOST=(\d+),STPPRIO=(\d+),DIRN=(\w+),STAGTYPE=(.*),PORTTYPE=(\w+),CVID=(\w+),SVID=(\d+),PRIO=(\d+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+),MCASTPROF=(\w+)!)
		 )
		 {					
				my $L2IFAID_cap 	= $1;
				my $VLAN_cap 		= $2;
				my $BRIDGE_cap 		= $3;
				my $ARP_cap			= $4;
				my $DHCPDIR_cap		= $5;
				my $OPT82ACT_cap	= $6;
												
				# File 1 (1_DELETES_FOR_VLANx.txt)
				#
				# C7 command:
				# DLT-VLAN-IF::N4-1-9-1-1-VP117-VC107::::VLAN=8,BRIDGE=N1-1-VB1;
				# DLT-VLAN-IF::[Source from output]::::VLAN=[VLAN from output],BRIDGE=[Bridge from output];
				print {$fh_C7_DELETES} ("DLT-VLAN-IF::" . $L2IFAID_cap . "::::VLAN=" . $VLAN_cap . ",BRIDGE=" . $BRIDGE_cap . ";\n");

				
				# ENT-VBPORT::N2-1-VB1-500::::DOS=N,DIRN=DOWN,PORTTYPE=EDGE,PINNED=Y;
				# ENT-VBPORT::[Ques #4]-[QUES #6]::::DOS=N,DIRN=DOWN,PORTTYPE=EDGE,PINNED=Y;
				print {$fh_C7_CREATES} ("ENT-VBPORT::" . $new_uplink_VB . "-" . $VBPORT_start_value . "::::DOS=N,DIRN=DOWN,PORTTYPE=EDGE,PINNED=Y;\n");
				
				# ENT-VLAN-VBPORT::N2-1-VB1-500::::VLAN=N2-1-VB1-VLAN100,ARP=N,DHCPDIR=CLIENT,
				# IGMP=NONE,PPPOEAC=N,PPPOESUB=N;

				# ENT-VLAN-VBPORT::[Keep same VB Port]::::VLAN=[Ques #4]-VLAN[Ques #5],ARP=N,DHCPDIR=CLIENT,IGMP=NONE,PPPOEAC=N,PPPOESUB=N;
				print {$fh_C7_CREATES} ("ENT-VLAN-VBPORT::" . $new_uplink_VB . "-" . $VBPORT_start_value . "::::VLAN=" . $new_uplink_VB . "-VLAN" . $new_uplink_VLAN . ",ARP=N,DHCPDIR=CLIENT,IGMP=NONE,PPPOEAC=N,PPPOESUB=N;\n");
				
				# ENT-CVIDREG::N2-1-VB1-500-UNTAGGED::::SVID=100,PRIO=0,RCVID=NONE;
				# ENT-CVIDREG::[Keep same VB Port]-UNTAGGED::::SVID=[Ques #4],PRIO=0,RCVID=NONE;
				print {$fh_C7_CREATES} ("ENT-CVIDREG::" . $new_uplink_VB . "-" . $VBPORT_start_value . "-UNTAGGED::::SVID=" . $new_uplink_VLAN . ",PRIO=0,RCVID=NONE;\n");

				# ENT-CRS-VC::N2-1-VB1-500,N4-1-9-1-1-VP117-VC107::::TRFPROF=UBR,BCKPROF=UBR,PATH=BOTH;
				# ENT-CRS-VC::[Keep same VB Port],[Source from output]::::TRFPROF=UBR,BCKPROF=UBR,PATH=BOTH;
				print {$fh_C7_CREATES} ("ENT-CRS-VC::" . $new_uplink_VB . "-" . $VBPORT_start_value . "," . $L2IFAID_cap , "::::TRFPROF=UBR,BCKPROF=UBR,PATH=BOTH;\n");

				$vlanif_found++;
				
				# Increment the VB port:
				$VBPORT_start_value++;
				
		}
		 # No match at all - write it to the error log and increment the $ont_not_matched counter
			 else 
			 {
				print {$fh_error} ("No match for: $line \n");
				$vlanif_not_matched++;
			 }
   
	}
}

#	End of all the pattern matching and manipulation
#
#
##############################################################################################



##############################################################################################
#
# File Handles - Close them
#
close $fh_C7_DELETES;
close $fh_C7_CREATES;
close $fh;
close $fh_error;
#
#
##############################################################################################



##############################################################################################
#
# Let the user know the results
#
print "=================================================================\n";
print "Results:\n";

print "Number of VLANIFs found:\t $vlanif_found\n";

print "=================================================================\n";
#
#
##############################################################################################




