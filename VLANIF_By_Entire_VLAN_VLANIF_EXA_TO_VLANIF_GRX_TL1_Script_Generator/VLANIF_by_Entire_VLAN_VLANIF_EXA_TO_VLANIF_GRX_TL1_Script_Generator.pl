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
print "The C7 VLANIF EXA to GRX TL1 Script Creator\n";
print "Version: 6-5-2012";
print "========================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls VLANIF cross-connect data\n";
print "2: Creates a text file that has all of the EXA DELETES\n";
print "3: Creates a text file that has all of the GRX CREATES\n";
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
print "Enter the Local VLAN you want to retrieve on:\n";
print "For example if DHCP subs or PPPoE subs are in VLAN 10 then just type 10 and hit enter:\n";
print ">";
my $user_data_vlan = <STDIN>;
chomp($user_data_vlan);


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
print "I am retrieving all of the ATM data cross-connects on $user_data_uplink \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";


$t->timeout(undef);

# This is the GRX retrieval
# $t->send("RTRV-VLAN-IF::ALL::::VLAN=$user_data_uplink-VLAN$user_data_vlan,DETAILS=Y;");
# This is the EXA retrieval
$t->send("RTRV-VLAN-IF::$user_data_uplink-all::::vlan=$user_data_vlan,bridge=local,details=y;");
$t->waitfor('/^;/ms');


$t->timeout(30);
print "======================================\n";
print "OK, done retrieving the cross-connects\n";
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
my $DATA_FILE = 'tl1_logs.txt';
my $DESTINATION_FILE = 'VLANIF_GRX_CREATES_FOR_' . $user_data_uplink . "_VLAN_$user_data_vlan.txt";
my $DESTINATION_FILE_2 = 'VLANIF_EXA_DELETES_FOR_' . $user_data_uplink . "_VLAN_$user_data_vlan.txt";
my $line;
my $fh2;		# CREATES
my $fh3;		# DELETES

my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_data_uplink . "_VLAN_$user_data_vlan.txt";



########################################################
# Parse out what Software Version the system is running:
########################################################
# "CALIX,C7,OSTP,7.0.567"
open my $fh_to_get_software_version, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open my $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";

my $network_software_version; 

while ($line = <$fh_to_get_software_version> )
{
  chomp($line);
   
  if ($line =~ m!CALIX,C7,.*(6\.1|7\.0|7\.2)\.!)
	{
		$network_software_version = $1;
 		last;
	}
}
close $fh_to_get_software_version ;
###########################################################

# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# This is the write file
open $fh2, ">", $DESTINATION_FILE or die "Couldn't open $DATA_FILE: $!\n";


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
	if ($network_software_version eq '7.0' || $network_software_version eq '7.2') 
	{
 		if ($line =~ /VLAN/ )
		{					
						$ont_vlanif_found++;
						
						###########################
						#
						#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 		This is for Don Feeney's Project
						#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
						#7.0 EXA Ethernet uplink with ONT  access:
						###########################
						#  N1-2-2-1-4-1::VLAN=51,BRIDGE=LOCAL,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=51,ENCAP=ETHERNETV2,DOS=Y,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,CVID=UNTAGGED,SVID=51,PRIO=0,RCVID=NONE,RXETHBWPROF=1,TXETHBWPROF=1,MCASTPROF=NONE"

						if ( $line =~ m!((N\d+-\d+)-\d+-\d+-\d+-\d+)::VLAN=(\w+),BRIDGE=LOCAL,ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{	
								# $1 AID	$3 VLAN		$4 ARP		$5 DHCPDIR		$6 OPT82ACT		$7 IGMP		$8 PPPOEAC		$9 PPPOESUB		$10 LSVID
								# $11 ENCAP	   $12 DOS		$13 STP		$14 STPCOST		$15 STPPRIO		$16 DIRN	$17 STAGTYPE   $18 PORTTYPE  $19 CVID
								# $20 SVID     $21 PRIO		$22 RCVID	$23 RXETHBWPROF	$24 TXETHBWPROF
															
							$grx_virtual_bridge = "$2" . "-" . "VB1";
							
							my $traffic_profile = "$24";
							my $back_traffic_profile = "$23" ;

							print {$fh2} ("ENT-VLAN-IF::$1-9::::VLAN=$3,BRIDGE=$grx_virtual_bridge,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DIRN=$16,PORTTYPE=$18,TRFPROF=$traffic_profile,BCKPROF=$back_traffic_profile,CVID=$19,PRIO=$21,RCVID=$22,PATH=UNPROT;\n"); 
							$ont_creates++;
						}
						else
						{
							print {$fh_error} ("NOT MATCHED ON: $line \n");
						}
							
						
	    } # end the VLAN match
		} # end the 7.0 check
} # end the main while
close $fh2;
close $fh;
##################################################################################################################################################
##################################################################################################################################################
##################################################################################################################################################









##################################################################################################################################################
# Deletes Logic Section
##################################################################################################################################################


###########################
# This is the DELETES logic
###########################

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh3, ">", $DESTINATION_FILE_2 or die "Couldn't open $DATA_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);
  
    
	#########################################
	# If S/W Version is 7.0
	#########################################
	if ($network_software_version eq '7.0' || $network_software_version eq '7.2') 
	{  
			if ($line =~ /VLAN/ )
			{			
					my $new_path ;
					######################################################################################################
					#7.0 Ethernet uplink with DSL access:
					# $1 DSL AID	$2 VLAN		$3 BRIDGE		$4 ARP				$5 DHCPDIR		$6 OPT82ACT
					# $7 IGMP		$8 PPPOEAC	$9 PPPOESUB		$10 LSVID			$11 ENCAP		$12	DOS
					# $13 STP		$14	STPCOST $15 STPPRIO	    $16 DIRN    		$17 STAGTYPE	$18 PORTTYPE
					# $19 TRFPROF		$20 BCKPROF				$21 PATH 			$22 CVID	
					# $23 SVID			$24 PRIO				$25 RCVID 			$26 RXETHBWPROF		$27 TXETHBWPROF
					######################################################################################################
		
					# Syntax to delete a 7.0 VLANIF
					# dlt-vlan-if::n1-1-5-14-ch0-vp0-vc35::::vlan=12,bridge=n1-1-vb1; 
					
					#####################################
					# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!		Don Feeney's One Off Script
					# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!		Don Feeney's One Off Script
					# 7.0 EXA Ethernet Uplink with ONT access:
					#####################################
					

				    if ( $line =~ m!((N\d+-\d+)-\d+-\d+-\d+-\d+)::VLAN=(\w+),BRIDGE=LOCAL,ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
 					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$3,BRIDGE=LOCAL;\n"); 
						$ont_deletes++;

					}
					else
					{
						print {$fh_error} ("NOT MATCHED ON: $line \n");
					}					

			} # end the VLAN match	 	 
	} # end the 7.0 check
} # end the main while
close $fh3;
close $fh;
close $fh_error;

 

print "=======================================================";
print "Totals\n\n";
print "Number of VLANIF found:				$ont_vlanif_found\n";
print "Number of VLANIF GRX creates created:			$ont_creates\n";
print "Number of VLANIF EXA deletes created:			$ont_deletes\n\n";
print "=======================================================";

				



