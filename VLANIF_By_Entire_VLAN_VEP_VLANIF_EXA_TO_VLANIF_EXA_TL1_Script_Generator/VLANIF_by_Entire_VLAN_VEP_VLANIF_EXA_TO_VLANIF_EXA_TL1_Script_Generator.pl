use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

my $ont_vlanif_found = 0;
my $ont_creates = 0;
my $ont_deletes = 0;

my $grx_virtual_bridge;

print "\n\n\n\n\n\n";
print "========================================================\n";
print "The C7 VLANIF EXA to VLANIF EXA Script Creator for VEPS\n";
print "\tVersion 5, Date 9-24-2012\n";
print "========================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls VEP VLANIFs for a shelf\n";
print "2: Creates a text file that has all of the VEP DELETES\n";
print "3: Creates a text file that has all of the VEP CREATES\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES or DELETES and use in your TL1\n"; 
print "scripts.\n";
print "========================================================\n";

######################################################################
# Gathering User Input to Option the Program
######################################################################

print "\n\n";
print "========================================================\n";
print "Please enter the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

my $user_name = 'c7support';
                                                                                                                                                      
print "\n\n";
print "========================================================\n";
print "Enter the SHELF the cross-connects are on:\n";
print "For example type N1-1 and hit enter\n";
print ">";
my $user_data_uplink = <STDIN>;
chomp($user_data_uplink);

print "\n\n";
print "========================================================\n";
print "Enter the existing VLAN you want to retrieve on:\n";
print "For example if DHCP subs or PPPoE subs are in VLAN 10 then just type 10 and hit enter:\n";
print ">";
my $user_data_vlan = <STDIN>;
chomp($user_data_vlan);

print "\n\n";
print "========================================================\n";
print "Enter the future VLAN you want to retrieve on:\n";
print "For example if DHCP subs or PPPoE subs are in VLAN 20 then just type 20 and hit enter:\n";
print ">";
my $user_future_data_vlan = <STDIN>;
chomp($user_future_data_vlan);

 
######################################################################
# Telnetting into the System
######################################################################

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

print "\n\n";
print "========================\n";
print "Logging in to the system\n";
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

$t->send("INH-MSG-ALL;");
$t->waitfor('/^;/ms');

$t->send("RTRV-NETYPE;");
$t->waitfor('/^;/ms');

print "=============================\n";
print "I am retrieving all of the VEP VLANIFs on $user_data_uplink \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";


$t->timeout(undef);

 # $t->send("RTRV-VLAN-IF::ALL::::VLAN=$user_data_uplink-VLAN$user_data_vlan,DETAILS=Y;");
# This is the EXA retrieval
$t->send("RTRV-VLAN-IF::$user_data_uplink-all::::vlan=$user_data_vlan,bridge=local,details=y;");
$t->waitfor('/^;/ms');


$t->timeout(30);
print "======================================\n";
print "OK, done retrieving the VLANIFs\n";
print "======================================\n";
  
#Logout
$t->send('CANC-USER;');
print "======================================\n";
print "Logging out of the C7 system\n";
print "======================================\n";
$t->close;

print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and create two separate files - a CREATES file and a DELETES file\n";
 print "=====================================================\n";

# Jason's additions
my $line;


# This is the write file for the TL1 raw file that was created after all of the telnet activity
my $DATA_FILE = 'tl1_logs.txt';

# Declare the fh file handle which will be used to read in the TL1_LOGS.txt file
my $fh;
# This is the read file
open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";


# FILE HANDLE for CREATES
my $fh_creates;		
# The FILE which will be used for CREATES
my $DESTINATION_FILE_CREATES = 'VLANIF_VEP_CREATES_FOR_' . $user_data_uplink . "_VLAN_$user_future_data_vlan.txt";
# Open the file handle for writing and 
open $fh_creates, ">", $DESTINATION_FILE_CREATES or die "Couldn't open $DESTINATION_FILE_CREATES: $!\n";


my $fh_deletes;		# DELETES FILE HANDLE
my $DESTINATION_FILE_DELETES = 'VLANIF_VEP_DELETES_FOR_' . $user_data_uplink . "_VLAN_" . $user_data_vlan . ".txt";	
open $fh_deletes, ">", $DESTINATION_FILE_DELETES or die "Couldn't open " . $DESTINATION_FILE_DELETES . ": " . $! . "\n";


open my $fh_to_get_software_version, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_data_uplink . "_VLAN_$user_data_vlan.txt";
open my $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";



########################################################
# Parse out what Software Version the system is running:
########################################################
# "CALIX,C7,OSTP,7.0.567"

my $network_software_version; 

while ($line = <$fh_to_get_software_version> )
{
  chomp($line);
   
  if ($line =~ m!CALIX,C7,.*(6\.1|7\.0|7\.2|8\.0)\.!)
	{
		$network_software_version = $1;
 		last;
	}
}
close $fh_to_get_software_version ;
###########################################################



##################################################################################################################################################
# Creates Logic Section
##################################################################################################################################################

while ($line = <$fh> )
{
  chomp($line);
  my $new_path ;

	#######################################
	# If S/W Version is 6.1
	# 10.208.5.14 - test system
	#########################################

    # > rtrv-vlan-if::ALL::::VLAN=N1-1-VB1-VLAN4094,DETAILS=Y;                                                                                                                                                  
	# "N1-1-10-1-CH0-VP0-VC35:N1-1-VB1-1:VLAN=N1-1-VB1-VLAN4094,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=4094,ENCAP=ETHERNETV2,DOS=Y,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=BOTH,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=4094,PRIO=0,RCVID=NONE"
	
	# 6.1 ENT-VLAN-IF syntax  
    # ent-vlan-if::n1-1-10-2-ch0-vp0-vc35::::VLAN=N1-1-VB1-VLAN4094,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,PRIO=0,RCVID=NONE,ARP=N,DHCPDIR=CLIENT,PPPOESUB=Y,PORTTYPE=EDGE,DIRN=DOWN;
	
	# 6.1 DLT-VLAN-IF syntax:
	# DLT-VLAN-IF::N1-1-10-2-ch0-vp0-vc35::::VLAN=N1-1-VB1-VLAN4094;

	# End TL1 Examples
	########################################################################################
	
	#######################################
	# If S/W Version is 7.0 or 7.2
	#########################################
	if ($network_software_version eq '7.0' || $network_software_version eq '7.2' || $network_software_version eq '8.0') 
	{
 		if ($line =~ /VLAN/ )
		{					
						$ont_vlanif_found++;
						
						# "N221-2-1-1-1-VEP1::VLAN=30,BRIDGE=LOCAL,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=N,LSVID=30,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=19,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,CVID=UNTAGGED,SVID=30,PRIO=5,RCVID=NONE,RXETHBWPROF=ONTVEPLINE3,TXETHBWPROF=ONTVEPLINE3,MCASTPROF=NONE"
						if ( $line =~ m!((N\d+-\d+)-\d+-\d+-\d+-VEP\d+)::VLAN=(\w+),BRIDGE=LOCAL,ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{	
								# $1 AID	$3 VLAN		$4 ARP		$5 DHCPDIR		$6 OPT82ACT		$7 IGMP		$8 PPPOEAC		$9 PPPOESUB		$10 LSVID
								# $11 ENCAP	   $12 DOS		$13 STP		$14 STPCOST		$15 STPPRIO		$16 DIRN	$17 STAGTYPE   $18 PORTTYPE  $19 CVID
								# $20 SVID     $21 PRIO		$22 RCVID	$23 RXETHBWPROF	$24 TXETHBWPROF
															

							print {$fh_creates} ("ENT-VLAN-IF::$1::::VLAN=$user_future_data_vlan,BRIDGE=LOCAL,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DIRN=$16,PORTTYPE=$18,RXETHBWPROF=$23,TXETHBWPROF=$24,CVID=$19,PRIO=$21,RCVID=$22;\n"); 
							$ont_creates++;
							
  						    print {$fh_deletes} ("DLT-VLAN-IF::$1::::VLAN=$3,BRIDGE=LOCAL;\n"); 
							$ont_deletes++;

						}
						else
						{
							print {$fh_error} ("NOT MATCHED FOR CREATE or DELETE ON: $line \n");
						}
							
						
	    } # end the VLAN match
		} # end the 7.0 check
} # end the main while
  ##################################################################################################################################################
##################################################################################################################################################
##################################################################################################################################################
    
close $fh;
close $fh_error;
close $fh_creates;		
close $fh_deletes;		 
  

print "=======================================================";
print "Totals\n\n";
print "Number of VLANIFs found:				$ont_vlanif_found\n";
print "Number of VLANIFs creates:			$ont_creates\n";
print "Number of VLANIFs deletes:			$ont_deletes\n\n";
print "=======================================================";

				



