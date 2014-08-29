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
print "The C7 VLANIF GRX to VLANIF EXA Script Creator\n";
print " 		  Written: May 2, 2012\n";
print " 	      Updated April 15, 2014\n";
print " 	      Written by Jason Murphy\n\n";
print "	Latest fixes:\n";
print "	  ifIndex fix - reported by An Do\n"; 
print "========================================================\n";
print "\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls VLANIF cross-connect data for a shelf\n";
print "2: Creates a text file that has all of the CREATES\n";
print "3: Creates a text file that has all of the DELETES\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES or DELETES and use in your TL1\n"; 
print "scripts.\n\n";
print "Note I am carrying across the ATM Traffic profile IDs and\n";
print "putting those values into the Ethernet Bandwidth settings\n";
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
print "Enter the NODE-SHELF-SLOT the cross-connects are on:\n";
print "For example type N1-1-1 and hit enter\n";
print ">";
my $user_data_uplink = <STDIN>;
chomp($user_data_uplink);

print "\n\n";
print "========================================================\n";
print "Enter the Virtual Bridge users are on:\n";
print "For example type N1-1-VB1 and hit enter\n";
print ">";
my $user_data_vb = <STDIN>;
chomp($user_data_vb);

print "\n\n";
print "========================================================\n";
print "Enter the existing VLAN you want to retrieve on:\n";
print "For example if DHCP subs or PPPoE subs are in VLAN 10 then just type 10 and hit enter:\n";
print ">";
my $user_data_vlan = <STDIN>;
chomp($user_data_vlan);

print "\n\n";
print "========================================================\n";
print "Enter the future VLAN you want to build the subs to:\n";
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
print "I am retrieving all of the VLANIFS data on $user_data_uplink \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";


$t->timeout(undef);

# This is the GRX retrieval
# $t->send("RTRV-VLAN-IF::ALL::::VLAN=$user_data_uplink-VLAN$user_data_vlan,DETAILS=Y;");
# This is the EXA retrieval
$t->send("RTRV-VLAN-IF::$user_data_uplink-all::::vlan=$user_data_vlan,bridge=$user_data_vb,details=y;");
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

 
 
my $line;

# This is the write file for the TL1 raw file that was created after all of the telnet activity
my $DATA_FILE = 'tl1_logs.txt';

my $fh;
# This is the read file
open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";


#########################################################################################
#
# FILE HANDLE for CREATES
# 
my $fh_creates;		
# The FILE which will be used for CREATES
my $DESTINATION_FILE_CREATES = 'DATA_CREATES_FOR_' . $user_data_uplink . "_VLAN_$user_data_vlan.txt";
# Open the file handle for writing and 
open $fh_creates, ">", $DESTINATION_FILE_CREATES or die "Couldn't open $DESTINATION_FILE_CREATES: $!\n";


my $fh_deletes;		# DELETES FILE HANDLE
my $DESTINATION_FILE_DELETES = 'DATA_DELETES_FOR_' . $user_data_uplink . "_VLAN_$user_data_vlan.txt";	
open $fh_deletes, ">", $DESTINATION_FILE_DELETES or die "Couldn't open $DESTINATION_FILE_DELETES: $!\n";


open my $fh_to_get_software_version, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_data_uplink . "_VLAN_$user_data_vlan.txt";
open my $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";
#
#
#
#########################################################################################

  
#########################################################################################
#
# Creates Logic Section
#
while ($line = <$fh> )
{
 	
  chomp($line);
  my $new_path ;	
 	
  		if ($line =~ /PATH=PROT/ )
		{
			next;
		}
		elsif ($line =~ /BRIDGE=/) 
		{					
						print "I am on the elsif BRIDGE\n";
						$ont_vlanif_found++;			
						# ONT with a Bandwidth Constraint
 						# "N201-1-20-1-22-1-1:N200-1-VB1-2129:            VLAN=10,	 BRIDGE=N200-1-VB1,ARP=N, DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=N,LSVID=10,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=116,BCKPROF=105,PATH=PROT,BWC=4,CVID=UNTAGGED,SVID=10,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,MCASTPROF=NONE"
						 #                          $2               $1       $3         $4               $5        $6             $7          $8          $9            $10            $11             $12         $13   $14       $15           $16            $17        $18            $19             $20           $21          $22      $23        $24      $25    $26    $27        $28             $29              $30
						 if ( $line =~ m!((N\d+-\d+-\d+-\d+-\d+-\d+)-\d+):N\d+-\d+-VB\d+-\d+:VLAN=(\w+),BRIDGE=(N\d+-\d+-VB\d+),ARP=([Y|N]),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\d+),BCKPROF=(\d+),PATH=(\w+),BWC=(\d+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+),MCASTPROF=(\w+)(,|")!)
						 {	
							my $full_ifIndex = $1;
							my $shortened_ifIndex = $2;
							
						    if ( $22 eq 'WKG')
							{
								$new_path = 'BOTH';
							}
							elsif ( $22 eq 'UNPROT')
							{
								$new_path = 'UNPROT';
							}
 							
							# Sample from An's SONET to ERPS Technical Guideline
							# ENT-VLAN-IF::N3-1-5-1-3-1::::VLAN=3,BRIDGE=LOCAL,PORTTYPE=EDGE,ARP=N,DHCPDIR=CLIENT,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,ENCAP=ETHERNETV2,DOS=Y,DIRN=DOWN,TRFPROF=10,BCKPROF=11,CVID=UNTAGGED,PRIO=0,RCVID=NONE;
							print {$fh_creates} ("ENT-VLAN-IF::" . $shortened_ifIndex . "::::VLAN=$user_future_data_vlan,BRIDGE=LOCAL,ARP=$5,DHCPDIR=$6,PPPOESUB=$10,DIRN=$17,PORTTYPE=$19,RXETHBWPROF=$21,TXETHBWPROF=$20,CVID=$24,PRIO=$26,RCVID=$28;\n"); 
							$ont_creates++;
							
  						    print {$fh_deletes} ("DLT-VLAN-IF::" . $full_ifIndex . "::::VLAN=$3,BRIDGE=$4;\n"); 
							$ont_deletes++;
						}
						
						# ONT - no Bandwidth Constraint
						#   "N200-1-1-1-1-1-1:N200-1-VB1-484:VLAN=10,BRIDGE=N200-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=N,LSVID=10,ENCAP=ETHERNETV2,DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=107,BCKPROF=102,                                                                   PATH=UNPROT,        CVID=UNTAGGED,SVID=10,PRIO=0,RCVID=NONE,RXETHBWPROF=NONE,TXETHBWPROF=NONE,MCASTPROF=NONE"
						 elsif ( $line =~ m!((N\d+-\d+-\d+-\d+-\d+-\d+)-\d+):N\d+-\d+-VB\d+-\d+:VLAN=(\w+),BRIDGE=(N\d+-\d+-VB\d+),ARP=([Y|N]),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=(\w+),PPPOEAC=(\w+),PPPOESUB=(\w+),LSVID=(\w+),ENCAP=(\w+),DOS=(\w+),STP=(\w+),STPCOST=(\w+),STPPRIO=(\w+),DIRN=(\w+),STAGTYPE=(\w+),PORTTYPE=(\w+),TRFPROF=(\d+),BCKPROF=(\d+),PATH=(\w+),CVID=(\w+),SVID=(\w+),PRIO=(\w+),RCVID=(\w+),RXETHBWPROF=(\w+),TXETHBWPROF=(\w+),MCASTPROF=(\w+)(,|")!)
						 {	
							my $full_ifIndex = $1;
							my $shortened_ifIndex = $2;
							
						   if ( $22 eq 'WKG')
							{
								$new_path = 'BOTH';
							}
							elsif ( $22 eq 'UNPROT')
							{
								$new_path = 'UNPROT';
							}
 							
							# Sample from An's SONET to ERPS Technical Guideline
							# ENT-VLAN-IF::N3-1-5-1-3-1::::VLAN=3,BRIDGE=LOCAL,PORTTYPE=EDGE,ARP=N,DHCPDIR=CLIENT,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,ENCAP=ETHERNETV2,DOS=Y,DIRN=DOWN,TRFPROF=10,BCKPROF=11,CVID=UNTAGGED,PRIO=0,RCVID=NONE;
							print {$fh_creates} ("ENT-VLAN-IF::" . $shortened_ifIndex . "::::VLAN=$user_future_data_vlan,BRIDGE=LOCAL,ARP=$5,DHCPDIR=$6,PPPOESUB=$10,DIRN=$17,PORTTYPE=$19,RXETHBWPROF=$21,TXETHBWPROF=$20,CVID=$23,PRIO=$25,RCVID=$27;\n"); 
							$ont_creates++;
							
  						    print {$fh_deletes} ("DLT-VLAN-IF::" . $full_ifIndex . "::::VLAN=$3,BRIDGE=$4;\n"); 
							$ont_deletes++;
						}
						else
						{
							print {$fh_error} ("NOT MATCHED FOR CREATE or DELETE ON: $line \n");
						}

	  }			
}
#  
#
#########################################################################################

#########################################################################################
#
# Close out File Handles
#    
close $fh;
close $fh_error;
close $fh_creates;		
close $fh_deletes;		 
#    
#    
#########################################################################################
  

#########################################################################################
#
# User-Interface Totals Print Outs
#    
print "=======================================================";
print "Totals\n\n";
print "Number of VLANIFs found:				$ont_vlanif_found\n";
print "Number of VLANIFs creates:			$ont_creates\n";
print "Number of VLANIFs deletes:			$ont_deletes\n\n";
print "=======================================================";
#    
#    
#########################################################################################

				