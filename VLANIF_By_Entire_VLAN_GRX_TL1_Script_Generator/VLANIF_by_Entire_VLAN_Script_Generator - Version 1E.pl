use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;


print "\n\n\n\n\n\n";
print "========================================================\n";
print "The C7 VLANIF Script Creator\n";
print "\n";
print "\n";
print "\tVersion: 1E\n";
print "\tCompiled: 8-22-2013\n";
print "========================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls VLANIF cross-connect data\n";
print "2: Creates a text file that has all of the CREATES\n";
print "3: Creates a text file that has all of the DELETES\n";
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
print "Enter the VB the cross-connects are on:\n";
print "For example type N1-1-VB1 and hit enter\n";
print ">";
my $user_data_uplink = <STDIN>;
chomp($user_data_uplink);

print "\n\n";
print "========================================================\n";
print "Enter the VLAN you want to retrieve on:\n";
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
# 8-22-2013 Set a 50 MB buffer 
$t->max_buffer_length(50 * 1024 * 1024);

#if ($network_software_version eq '6.1' )
#{ 
	# Retrieving all VLANIFs in 6.1 mode
	# rtrv-vlan-if::ALL::::VLAN=N1-1-VB1-VLAN4094,DETAILS=Y;
	$t->send("RTRV-VLAN-IF::ALL::::VLAN=$user_data_uplink-VLAN$user_data_vlan,DETAILS=Y;");
	$t->waitfor('/^;/ms');
#}


#if ($network_software_version eq '7.0' || $network_software_version eq '7.2' || $network_software_version eq '8.0') 
#{
	# Retrieving all VLANIFs in 7.0/7.2 mode
	# rtrv-vlan-if::ALL::::VLAN=12,BRIDGE=N1-1-VB1,DETAILS=Y;
	$t->send("RTRV-VLAN-IF::ALL::::VLAN=$user_data_vlan,BRIDGE=$user_data_uplink,DETAILS=Y;");
	$t->waitfor('/^;/ms');
#}
	
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
my $DESTINATION_FILE = 'CREATES_FOR_' . $user_data_uplink . "_VLAN $user_data_vlan.txt";
my $DESTINATION_FILE_2 = 'DELETES_FOR_' . $user_data_uplink . "_VLAN $user_data_vlan.txt";
my $line;
my $fh2;		# CREATES
my $fh3;		# DELETES





########################################################
# Parse out what Software Version the system is running:
########################################################
# "CALIX,C7,OSTP,7.0.567"
open my $fh_to_get_software_version, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

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
	# If S/W Version is 6.1
	#########################################
	if ($network_software_version eq '6.1' ) 
	{
		if ( $line =~ m!PATH=PROT!) 
		{
			next;
		}
		elsif ($line =~ /VLAN/ )
		{		
		
				######################################################################################################
				# 6.1 VLAN-IF Fields:
				# $1 DSL AID			$2 VLAN				$3 ARP				$4 DHCPDIR		$5 OPT82ACT
				# $6 IGMP				$7 PPPOEAC			$8 PPPOESUB			$9 LSVID			$10 ENCAP		$11	DOS
				# $12 STP				$13	STPCOST $14 STPPRIO	    			$15 DIRN    		$16 STAGTYPE	$17 PORTTYPE
				# $18 TRFPROF			$19 BCKPROF				$20 PATH 			$21 CVID	
				# $22 SVID				$23 PRIO				$24 RCVID 			$25 RXETHBWPROF		$26 TXETHBWPROF
				######################################################################################################

				#=======================================
				#6.1 Supported Formats of VLANIF command
				#=======================================							COMPLETED?		TESTED?		TESTED BWC?
				# DSL																Y				Y			Y
				# ONT Eth IFindex													Y				Y			Y
				#
				# DSL Group VC AID													Y				Y			Y
				# N{1-255}-{1-5}-{1-20}-GRP{1-12}-VP{0-255}-VC{32-65535}
				#
				# OC Downlink
				# N{1-255}-{1-5}-{1-20}-{1-4}-{1-48}-VP{0-4095}-VC{20,32-65535}


							
				#####################################
				# 6.1 Ethernet uplink with DSL access - COMPLETE
				#####################################
				# > rtrv-vlan-if::ALL::::VLAN=N1-1-VB1-VLAN4094,DETAILS=Y;
				# N1-1-10-1-CH0-VP0-VC35:N1-1-VB1-1:VLAN=N1-1-VB1-VLAN4094,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=4094,ENCAP=ETHERNETV2,DOS=Y,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=BOTH,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=4094,PRIO=0,RCVID=NONE"
 				
 				if ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
 				{							
						if ( $20 eq 'WKG') 
						{
							$new_path = 'BOTH';
						}
						else 
						{
							$new_path = $20;
						}						
						print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,CVID=$21,PRIO=$23,RCVID=$24;\n"); 
				} # end 6.1 Ethernet Uplink with DSL access section
				#####################################
				# 6.1 Ethernet uplink with DSL Group access - COMPLETE
				#####################################
				# DSL Group VC AID
				# N{1-255}-{1-5}-{1-20}-GRP{1-12}-VP{0-255}-VC{32-65535}

				# > rtrv-vlan-if::ALL::::VLAN=N1-1-VB1-VLAN4094,DETAILS=Y;
				# N1-1-10-1-CH0-VP0-VC35:N1-1-VB1-1:VLAN=N1-1-VB1-VLAN4094,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=4094,ENCAP=ETHERNETV2,DOS=Y,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=BOTH,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=4094,PRIO=0,RCVID=NONE"
 				
 				elsif ( $line =~ m!(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
 				{							
						if ( $20 eq 'WKG') 
						{
							$new_path = 'BOTH';
						}
						else 
						{
							$new_path = $20;
						}						
						print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,CVID=$21,PRIO=$23,RCVID=$24;\n"); 
				} # end 6.1 Ethernet Uplink with DSL GRP access section
				#####################################
				# 6.1 Ethernet uplink with OC Downlink - COMPLETE
				#####################################
				# OC Downlink
				# N{1-255}-{1-5}-{1-20}-{1-4}-{1-48}-VP{0-4095}-VC{20,32-65535}

				# > rtrv-vlan-if::ALL::::VLAN=N1-1-VB1-VLAN4094,DETAILS=Y;
				# N1-1-10-1-CH0-VP0-VC35:N1-1-VB1-1:VLAN=N1-1-VB1-VLAN4094,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=4094,ENCAP=ETHERNETV2,DOS=Y,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=BOTH,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=4094,PRIO=0,RCVID=NONE"
 				
 				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
 				{							
						if ( $20 eq 'WKG') 
						{
							$new_path = 'BOTH';
						}
						else 
						{
							$new_path = $20;
						}						
						print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,CVID=$21,PRIO=$23,RCVID=$24;\n"); 
				} # end 6.1 Ethernet Uplink with OC Downlink access section

		
				###########################
				# 6.1 Ethernet Uplink and ONT - COMPLETE
				###########################
 				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
						{
								if ( $20 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $20;
								}						
						print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,CVID=$21,PRIO=$23,RCVID=$24;\n"); 

				}

				
				######################################################################################################
				# 6.1 VLAN-IF Fields w/ BW Constraints :
				# $1 DSL AID			$2 VLAN				$3 ARP				$4 DHCPDIR		$5 OPT82ACT
				# $6 IGMP				$7 PPPOEAC			$8 PPPOESUB			$9 LSVID			$10 ENCAP		$11	DOS
				# $12 STP				$13	STPCOST $14 STPPRIO	    			$15 DIRN    		$16 STAGTYPE	$17 PORTTYPE
				# $18 TRFPROF			$19 BCKPROF				$20 PATH 			$21 BWC 		$22 CVID	
				# $23 SVID				$24 PRIO				$25 RCVID 			$26 RXETHBWPROF		$27 TXETHBWPROF
				######################################################################################################
				
				######################################################################################################
				#6.1 Ethernet uplink with DSL access and BWC: - COMPLETE
				######################################################################################################
				# "N2-1-20-1-CH0-VP0-VC35:N1-1-VB1-24:VLAN=12,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=6,BCKPROF=6,PATH=WKG,BWC=10,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
 				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
				{					
						if ( $20 eq 'WKG') {
							$new_path = 'BOTH';
						}
						else {
							$new_path = $20;
						}
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,,BWC=$21,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
				}
				######################################################################################################
				#6.1 Ethernet uplink with DSL Group and BWC: - COMPLETE
				######################################################################################################
				# "N2-1-20-1-CH0-VP0-VC35:N1-1-VB1-24:VLAN=12,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=6,BCKPROF=6,PATH=WKG,BWC=10,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
 				elsif ( $line =~ m!(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
				{					
						if ( $20 eq 'WKG') {
							$new_path = 'BOTH';
						}
						else {
							$new_path = $20;
						}
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,,BWC=$21,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
				}
				###########################
				# 6.1 - ONT VLANIF with BWC 
				###########################
				# "N2-1-1-1-1-1-1:N1-1-VB1-24:VLAN=12,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=6,BCKPROF=6,PATH=WKG,BWC=10,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+-\w+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
				{			
						if ( $20 eq 'WKG') {
							$new_path = 'BOTH';
						}
						else {
							$new_path = $20;
						}
						
					print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,,BWC=$21,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
				} 
				######################################################################################################
				#6.1 Ethernet uplink with OC Downlink and BWC: - COMPLETE
				######################################################################################################
				# "N2-1-20-1-CH0-VP0-VC35:N1-1-VB1-24:VLAN=12,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=6,BCKPROF=6,PATH=WKG,BWC=10,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
 				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
				{					
						if ( $20 eq 'WKG') {
							$new_path = 'BOTH';
						}
						else {
							$new_path = $20;
						}								
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,,BWC=$21,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
				}
				
		}	# end VLAN section	
	}  # end network software check for 6.1

	
	
	
	#######################################
	# If S/W Version is 7.0 or 7.2
	#########################################

	#=======================================
	#7.0 Supported Formats of VLANIF command
	#=======================================
	#																	COMPLETED		TESTED?			TESTED BWC?
	# DslGrpVciAid 
	# N{1-255}-{1-5}-{1-20}-GRP{1-12}-VP{0-255}-VC{32-65535}			Y
	#
	# IMA AP															Y
	# N{1-255}-{1-5}-{1-20}-AP{1-16}-VP{0-4095}-VC{32-65535}
	# 
	# IMA																Y	
	# N{1-255}-{1-5}-{1-20}-IMA{1-16}-VP{0-4095}-VC{32-65535}
	#
	# Vc12PortAid i.e. DS3 Downlink										Y
	# N{1-255}-{1-5}-{1-20}-{1-12}-VP{0-4095}-VC{32-65535}
	#  
	# VcLuStsAid i.e. OC downlink										Y
	# N{1-255}-{1-5}-{1-20}-{1-4}-{1-48}-VP{0-4095}-VC{20,32-65535}
	#===============================================================
	
	# Sample 7.0 output from a retrieve:
	# N1-1-5-1-CH0-VP0-VC35:N1-1-VB1-11:VLAN=12,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
	  
	# Sample 7.2 output from a retrieve:
	# N1-1-4-1-CH0-VP0-VC35:N1-1-VB1-2:VLAN=52,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=52,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=52,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,MCASTPROF=NONE"

	if ($network_software_version eq '7.0' || $network_software_version eq '7.2' || $network_software_version eq '8.0') 
	{

		if ( $line =~ m!PATH=PROT!) 
		{
			next;
		}
		elsif ($line =~ /VLAN/ )
		{						
				# This is 7.0 syntax - retrieving all VLANIFs
				# rtrv-vlan-if::ALL::::VLAN=12,BRIDGE=N1-1-VB1,DETAILS=YES;
						#########################################################################################################
					    # 7.0 Fields 
						# $1 DSL AID	$2 VLAN		$3 BRIDGE		$4 ARP				$5 DHCPDIR		$6 OPT82ACT
						# $7 IGMP		$8 PPPOEAC	$9 PPPOESUB		$10 LSVID			$11 ENCAP		$12	DOS
						# $13 STP		$14	STPCOST $15 STPPRIO	    $16 DIRN    		$17 STAGTYPE	$18 PORTTYPE
						# $19 TRFPROF		$20 BCKPROF				$21 PATH 			$22 CVID	
						# $23 SVID			$24 PRIO				$25 RCVID 			$26 RXETHBWPROF		$27 TXETHBWPROF
						#########################################################################################################
												
						# Sample 7.0 output from a retrieve:
						# N1-1-5-1-CH0-VP0-VC35:N1-1-VB1-11:VLAN=12,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
						  
						# Sample 7.2 output from a retrieve:
						# N1-1-4-1-CH0-VP0-VC35:N1-1-VB1-2:VLAN=52,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=52,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=52,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,MCASTPROF=NONE"

						# 7.0 Example of syntax:
						# ENT-VLAN-IF::N2-1-1-1-CH0-VP8-VC35::::VLAN=1027,BRIDGE=N12-1-VB20,TMPLT=2,TRFPROF=UBR,BCKPROF=UBR,PATH=BOTH,CVID=UNTAGGED,PRIO=0,RCVID=NONE;

						
						###########################
						#7.0 Ethernet uplink with DSL access:
						###########################
						if ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}
								
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
						}						
						###########################
						#7.0 Ethernet uplink with VDSL access:
						###########################
						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}
								
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
						}
						###########################
						#7.0 Ethernet uplink with DSL GRP access:
						###########################
						elsif ( $line =~ m!(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}
								
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
						}
						###########################
						# 7.0 Ethernet Uplink and ONT
						###########################
						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+-\w+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}						
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
						}
						###########################
						# 7.0 Ethernet Uplink and OC Access
						###########################
 						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}
								
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
						}
						###########################
						# 7.0 Ethernet Uplink and DS3 Access
						###########################
 						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}
								
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
						}
						###########################
						# 7.0 Ethernet Uplink and IMA AP
						###########################
						# IMA AP		
						# N{1-255}-{1-5}-{1-20}-AP{1-16}-VP{0-4095}-VC{32-65535}
 						elsif ( $line =~ m!(N\d+-\d+-\d+-AP\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}
								
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
						}
						###########################
						# 7.0 Ethernet Uplink and IMA AP
						###########################
						# IMA			
						# N{1-255}-{1-5}-{1-20}-IMA{1-16}-VP{0-4095}-VC{32-65535}
 						elsif ( $line =~ m!(N\d+-\d+-\d+-IMA\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}
								
							print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,CVID=$22,PRIO=$24,RCVID=$25;\n"); 
						}


						

						######################################################################################################
						# 7.0 Ethernet uplink with DSL/PON access and BWC:
						# $1 DSL AID	$2 VLAN		$3 BRIDGE		$4 ARP				$5 DHCPDIR		$6 OPT82ACT
						# $7 IGMP		$8 PPPOEAC	$9 PPPOESUB		$10 LSVID			$11 ENCAP		$12	DOS
						# $13 STP		$14	STPCOST $15 STPPRIO	    $16 DIRN    		$17 STAGTYPE	$18 PORTTYPE
						# $19 TRFPROF		$20 BCKPROF				$21 PATH 			$22 BWC			$23 CVID	
						# $24 SVID			$25 PRIO				$26 RCVID 			$27 RXETHBWPROF		$28 TXETHBWPROF
						######################################################################################################

						# 7.0 Example of syntax:
						# ENT-VLAN-IF::N2-1-1-1-CH0-VP8-VC35::::VLAN=1027,BRIDGE=N12-1-VB20,TMPLT=2,TRFPROF=UBR,BCKPROF=UBR,PATH=BOTH,BWC=10,CVID=UNTAGGED,PRIO=0,RCVID=NONE;

						###########################
						# 7.0 - DSL VLANIF with BWC 
						###########################
						# "N2-1-20-1-CH0-VP0-VC35:N1-1-VB1-24:VLAN=12,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=6,BCKPROF=6,PATH=WKG,BWC=10,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}								
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,,BWC=$22,CVID=$23,PRIO=$25,RCVID=$26;\n"); 
						}
						###########################
						# 7.0 - VDSL VLANIF with BWC 
						###########################
						# "N2-1-20-1-CH0-VP0-VC35:N1-1-VB1-24:VLAN=12,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=6,BCKPROF=6,PATH=WKG,BWC=10,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}								
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,,BWC=$22,CVID=$23,PRIO=$25,RCVID=$26;\n"); 
						}						
						###########################
						# 7.0 - DSL GRP VLANIF with BWC 
						###########################
 						elsif ( $line =~ m!(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}								
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,,BWC=$22,CVID=$23,PRIO=$25,RCVID=$26;\n"); 
						}						
						###########################
						# 7.0 - ONT VLANIF with BWC 
						###########################
						# "N2-1-1-1-1-1-1:N1-1-VB1-24:VLAN=12,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=12,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=6,BCKPROF=6,PATH=WKG,BWC=10,CVID=UNTAGGED,SVID=12,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,"
						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+-\w+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{			
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}								
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,,BWC=$22,CVID=$23,PRIO=$25,RCVID=$26;\n"); 
						} 
						###########################
						# 7.0 - IMA AP VLANIF with BWC 
						###########################
 						elsif ( $line =~ m!(N\d+-\d+-\d+-IMA\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}								
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,,BWC=$22,CVID=$23,PRIO=$25,RCVID=$26;\n"); 
						}
						###########################
						# 7.0 - IMA AP VLANIF with BWC 
						###########################
 						elsif ( $line =~ m!(N\d+-\d+-\d+-AP\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}								
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,,BWC=$22,CVID=$23,PRIO=$25,RCVID=$26;\n"); 
						}
						#################################
						# 7.0 - DS3 Downlink Access w/ BWC 
						#################################
 						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}								
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,,BWC=$22,CVID=$23,PRIO=$25,RCVID=$26;\n"); 
						}					
						#################################
						# 7.0 - OC Downlink Access w/ BWC 
						#################################
 						elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
						{
								if ( $21 eq 'WKG') {
									$new_path = 'BOTH';
								}
								else {
									$new_path = $21;
								}								
								print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,ARP=$4,DHCPDIR=$5,PPPOESUB=$9,DOS=$12,DIRN=$16,PORTTYPE=$18,TRFPROF=$19,BCKPROF=$20,PATH=$new_path,,BWC=$22,CVID=$23,PRIO=$25,RCVID=$26;\n"); 
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
	# If S/W Version is 6.1
	#########################################
	if ($network_software_version eq '6.1') 
	{
			if ( $line =~ m!PATH=PROT!) 
			{
				next;
			}
			elsif ($line =~ /VLAN/ )
			{			
					my $new_path ;
		
					# Syntax to delete a 6.1 VLANIF
					# dlt-vlan-if::n1-1-5-14-ch0-vp0-vc35::::vlan=n1-1-vb1-vlan500; 
					
					#####################################
					# 6.1 Ethernet Uplink with DSL access:
					#####################################
					if ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2;\n"); 
					}
					##########################################
					# 6.1 Ethernet Uplink with DSL GRP access:
					##########################################
 					elsif ( $line =~ m!(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2;\n"); 
					}
					######################################
					# 6.1 Ethernet Uplink with ONT access:
					######################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2;\n"); 
					}
					###############################################
					# 6.1 Ethernet Uplink with DS3 Downlink access:
					###############################################
 					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2;\n"); 
					}


					################################################
					# 6.1 Ethernet Uplink with DSL access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2;\n"); 
					}
					################################################
					# 6.1 Ethernet Uplink with DSL GRP access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2;\n"); 
					}
					################################################
					# 6.1 Ethernet Uplink with ONT access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+-\w+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2;\n"); 
					}
					################################################
					# 6.1 Ethernet Uplink with DS3 access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+-\w+-\w+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2;\n"); 
					}
			} # end the VLAN match	 	 
	} # end the 6.1 check
  
  
  
	#########################################
	# If S/W Version is 7.0
	#########################################
	if ($network_software_version eq '7.0' || $network_software_version eq '7.2' || $network_software_version eq '8.0') 
	{  
			if ( $line =~ m!PATH=PROT!) 
			{
				next;
			}
			elsif ($line =~ /VLAN/ )
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
					# 7.0 Ethernet Uplink with DSL access:
					#####################################
					if ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}
					#####################################
					# 7.0 Ethernet Uplink with VDSL access:
					#####################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}
					#####################################
					# 7.0 Ethernet Uplink with ONT access:
					#####################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+-\w+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}					
					#####################################
					# 7.0 Ethernet Uplink with GRP DSL access:
					#####################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}
					#####################################
					# 7.0 Ethernet Uplink with IMA access:
					#####################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-IMA\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}
					#####################################
					# 7.0 Ethernet Uplink with IMA AP access:
					#####################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-AP\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}

					#####################################
					# 7.0 Ethernet Uplink with DS3 access:
					#####################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}
					#####################################
					# 7.0 Ethernet Uplink with OC access:
					#####################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}

					

					################################################
					# 7.0 Ethernet Uplink with DSL access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}
					################################################
					# 7.0 Ethernet Uplink with VDSL access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}					################################################
					# 7.0 Ethernet Uplink with DSL access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}					
					################################################
					# 7.0 Ethernet Uplink with ONT access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+-\w+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}					
					################################################
					# 7.0 Ethernet Uplink with IMA access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-IMA\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}					
					################################################
					# 7.0 Ethernet Uplink with IMA AP access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-AP\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}					
					################################################
					# 7.0 Ethernet Uplink with DS3 access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}
					################################################
					# 7.0 Ethernet Uplink with OC access and a BWC:
					################################################
					elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*:VLAN=(\w+),BRIDGE=(\w+-\d+-\w+),ARP=(\w+),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),BWC=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+)(,|")!)
					{
						print {$fh3} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n"); 
					}

			} # end the VLAN match	 	 
	} # end the 7.0 check
	
} # end the main while
close $fh3;
close $fh;






