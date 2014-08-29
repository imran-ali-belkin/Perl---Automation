use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# These are counters which keep track of how many cross-connects we create by access subscriber type
my $counter_DSL_classic_creates = 0;
my $counter_ONT_classic_creates = 0;
my $counter_IMA_creates = 0;
my $counter_IMA_GRP_AP_creates = 0;
my $counter_DSL_GRP_creates = 0;
my $counter_DS3_downlink_creates = 0;
my $counter_OC_downlink_creates = 0;

my $counter_cross_connects_found = 0;
my $counter_cross_connects_created = 0;
my $counter_cross_connects_deleted = 0;

my $counter_vlanif_creates = 0;
my $counter_ipvc_deletes = 0;

#############################################################################################################
#
# The main user interface - getting user input, etc
#
#############################################################################################################
print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The C7 IPVC to VLANIF Script Creator\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls IPVC data cross-connect data from the IRC Card\n";
print "2: Creates a text file that has all of the DELETES for the existing IPVCs\n";
print "3: Creates a text file that has all of the CREATES for new VLANIFs\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES or DELETES and use in your TL1\n"; 
print "scripts.\n";
print "==========================================================================\n";

print "\n\n";
print "==========================================================================\n";
print "Please enter either the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $destination_c7 = <STDIN>;
chomp($destination_c7);

my $user_name = 'c7support';

print "\n\n";
print "==========================================================================\n"; 
print "Enter the Location of the Working IRC Card:\n";
print "\n";
print "Make sure to get this correct or else I will not be able to retrieve the IPVCs\n";
print "For example if your IRC pair is in Slots 19 and Slots 20:\n";
print "                                     Then input N1-1-20\n";
print "\n";
print "The general syntax is: \n";
print "                                       NODE-SHELF-SLOT\n";
print "\n";
print ">";
my $user_irc_uplink = <STDIN>;
chomp($user_irc_uplink);

print "\n\n";
print "==========================================================================\n";
print "What is the future Virtual Bridge\n";
print "			You only need to enter NODE-SHELF-VB\n";
print "			An example is N10-1-VB1\n";
print ">";
my $virtual_bridge = <STDIN>;
chomp($virtual_bridge);



print "\n\n";
print "==========================================================================\n";
print "What is the future VLAN\n";
print "			You only need to enter the VLAN integer\n";
print "			An example would be 700 then hit the enter key.\n";
print ">";
my $vlan = <STDIN>;
chomp($vlan);

print "\n\n";
print "==========================================================================\n";
print "What is the future MCAST Profile\n";
print "			You only need to enter the integer\n";
print "			An example would be 1 then hit the enter key.\n";
print ">";
my $mcast_prof = <STDIN>;
chomp($mcast_prof);

print "\n\n";
print "==========================================================================\n";
print "What is the future TXETHBWPROF Profile\n";
print "			You only need to enter the integer\n";
print "			An example would be 1 then hit the enter key.\n";
print ">";
my $txethbwprof = <STDIN>;
chomp($txethbwprof);


print "\n\n";
print "==========================================================================\n";
print "What is the future RXETHBWPROF Profile\n";
print "			You only need to enter the integer\n";
print "			An example would be 1 then hit the enter key.\n";
print ">";
my $rxethbwprof = <STDIN>;
chomp($rxethbwprof);


 


#############################################################################################################
#
# Password cracker stuff
#
#############################################################################################################
my $shell = C7::Cmd->new($destination_c7, 23);
$shell->connect;
my ($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
my $password = $shell->computeForgottenPassword( $date, $sid );



#############################################################################################################
#
# Telnet to the C7 and grab all of the data
#
#############################################################################################################
my $t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs.txt' );

  #C7 IP/Hostname to open, change this to the one you want.
$t->open($destination_c7);

  #Wait for prompt to appear;
$t->waitfor('/>/ms');

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

# Inhibit Message All
$t->send("INH-MSG-ALL;");
$t->waitfor('/^;/ms');

$t->timeout(undef);
$t->send("RTRV-CRS-VIDVC::$user_irc_uplink-PP1-all::::IRCAID=$user_irc_uplink;");
print "=============================\n";
print "I am retrieving all of the ATM data cross-connects on $user_irc_uplink \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the cross-connects\n";
print "======================================\n";

$t->timeout(30);
  
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
my $DESTINATION_FILE = 'CREATES_FOR_' . $user_irc_uplink . '.txt';
my $DESTINATION_FILE_2 = 'DELETES_FOR_' . $user_irc_uplink . '.txt';
my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_irc_uplink . '.txt';

my $line;
my $fh2;		# CREATES
my $fh3;		# DELETES
my $fh_error;

my $path_info = 'BOTH';

open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";

# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# This is the write file
open $fh2, ">", $DESTINATION_FILE or die "Couldn't open $DATA_FILE: $!\n";




##############################################################################################################
#
#	The Creates Section
#
##############################################################################################################

while ($line = <$fh> )
{
  chomp($line);

  	if ( $line =~ m!PATH=PROT!) {
		next;
	}
    elsif ($line =~ /VP/ ){
	   $counter_cross_connects_found++;
	   
		# $1 will be the access port
		# $2 will be the PATH
		# $3 will be the Bandwidth Constraint / BWC
 				 				
		# Here is the Bandwidth Constraint logic:
		if ( $line =~ m!BWC=\d+,!){
				# IPVCs that have Bandwidth Constraints
 				if ( $line =~ m!N\d+-\d+-\d+-PP1-VP\d+-VC\d+,(N.*):.*PATH=(\w+),.*BWC=(\w+),! ){
					
					if ( $2 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($2 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					# Example of a VLANIF
					# "ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,CVID=$21,PRIO=$23,RCVID=$24,;\n");
					
					print {$fh2} ("ENT-VLAN-IF::$1::::PATH=$path_info,BWC=$3,IGMP=Source,BRIDGE=$virtual_bridge,VLAN=$vlan;\n");
					$counter_vlanif_creates++;					
					$counter_cross_connects_created++;
				}

				else
				{
					print {$fh_error} ("No match on create for: " . $line . "\n");
				}

 		}
		# End of Bandwidth Constraint logic
		
		else {
 				if ( $line =~ m!N\d+-\d+-\d+-PP1-VP\d+-VC\d+,(N\d+-\d+-\d+-\d+-\d+-\d+)-\d+:.*PATH=(\w+),! )
				{
					if ( $2 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($2 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					# Example of a VLANIF				
					# N1-1-10-1-CH0-VP0-VC35:N1-1-VB1-1:VLAN=N1-1-VB1-VLAN4094,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=4094,ENCAP=ETHERNETV2,DOS=Y,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=BOTH,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=4094,PRIO=0,RCVID=NONE"
					# "ENT-VLAN-IF::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,PPPOESUB=$8,DOS=$11,DIRN=$15,PORTTYPE=$17,TRFPROF=$18,BCKPROF=$19,PATH=$new_path,CVID=$21,PRIO=$23,RCVID=$24;\n");
					# 
					# From An's Technical Guideline:
					# ENT-VLAN-IF::N3-1-2-1-1-1::::VLAN=8,BRIDGE=LOCAL,PORTTYPE=EDGE,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=N,ENCAP=ETHERNETV2,DOS=N,STP=OFF,DIRN=DOWN,MCASTPROF=1,CVID=8,PRIO=3,RCVID=NONE;
					#
					print {$fh2} ("ENT-VLAN-IF::$1::::VLAN=$vlan,ARP=N,BRIDGE=LOCAL,DHCPDIR=CLIENT,DOS=N,OPT82ACT=NONE,DIRN=DOWN,PPPOEAC=N,PPPOESUB=N,IGMP=NONE,PORTTYPE=EDGE,STP=OFF,CVID=UNTAGGED,PRIO=3,RCVID=NONE,MCASTPROF=$mcast_prof,TXETHBWPROF=$txethbwprof,RXETHBWPROF=$rxethbwprof;\n"); 
					$counter_vlanif_creates++;					
					$counter_cross_connects_created++;
				}
				else
				{
					print {$fh_error} ("No match on create for: " . $line . "\n");
				}
				
		}
   }
}
close $fh2;
close $fh;



##############################################################################################################
#
#	The Deletes Section
#
##############################################################################################################



open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh3, ">", $DESTINATION_FILE_2 or die "Couldn't open $DATA_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);

    if ( $line =~ m!PATH=PROT!) {
		next;
	}
	elsif ($line =~ /PP1/ ){			
			# $1 will be the IRC uplink
			# $2 will be the access port
 			# $3 will be the PATH

			my $new_path ;
			# "N1-1-20-PP1-VP0-VC32,N1-1-1-1-1-1-3:2WAY:KEY=N1-1-20-PP1-VP0-VC32,TRFPROF=1,BCKPROF=1,PATH=UNPROT,CONSTAT=NORMAL,"
			if 
			( 
			# ONT Match
			$line =~ m!(N\d+-\d+-\d+-PP1-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*PATH=(\w+),.*[,|"]! 
			||
			# DSL port Match
			$line =~ m!(N\d+-\d+-\d+-PP1-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*PATH=(\w+),.*[,|"]! 
						
			)
			{
				if ( $3 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $3;
				}
				print {$fh3} ("DLT-CRS-VIDVC::$1,$2::::IRCAID=$user_irc_uplink;\n"); 
 				$counter_ipvc_deletes++;
 			}
			else
			{
					print {$fh_error} ("No match on delete for: " . $line . "\n");					
			}
 	}	 	 
}
close $fh3;
close $fh;
close $fh_error;

print "==========================================================\n";
print "Totals \n";
print "==========================================================\n";

print "Total cross-connects found in TL1 retrieval file:\t " . $counter_cross_connects_found . "\n";
print "Total cross-connects written to TL1 CREATES file:\t " . $counter_vlanif_creates . "\n";
print "Total cross-connects written to TL1 DELETES file:\t " . $counter_ipvc_deletes . "\n\n";
print "\n";
 



