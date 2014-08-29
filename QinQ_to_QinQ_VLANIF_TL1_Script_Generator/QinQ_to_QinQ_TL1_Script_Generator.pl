use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;


#############################################################################################################
#
# 	Counters to keep track of things
#
#############################################################################################################
my $counter_vidsub_created = 0;
my $counter_vidsub_deleted = 0;
my $counter_vidsub_found = 0; 



 
#############################################################################################################
#
# 	The main user interface - getting user input, etc
#
#############################################################################################################
print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The C7 QinQ to QinQ TL1 Script Generator for C7 7.0\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls QinQ information for a 7.0 system\n";
print "2: Creates a text file that has all of the DELETES for the QinQ subs\n";
print "3: Creates a text file that has all of the CREATES for new QinQ subs\n";
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

print "==========================================================================\n";


print "==========================================================================\n";
print "What shelf you want to pull against\n";
print "			You only need to enter NODE-SHELF\n";
print "			An example is N3-1\n";
print "==========================================================================\n";
print ">";
my $shelf = <STDIN>;
chomp($shelf);


print "\n\n";
print "==========================================================================\n"; 
print "Enter the Uplink Virtual Bridge:\n";
print "\n";
print "Make sure to get this correct \n";
print "\n";
print "The general syntax is: \n";
print "                                       NODE-SHELF-SLOT\n";
print "										Example: N1-1-VB1\n";
print "\n";
print "==========================================================================\n"; 
print ">";
my $uplink_virtual_bridge = <STDIN>;
chomp($uplink_virtual_bridge);


print "\n\n";
print "==========================================================================\n"; 
print "Enter the Uplink VLAN:\n";
print "\n";
print "Make sure to get this correct \n";
print "\n";
print "The general syntax is: \n";
print "                           If the VLAN is 100 then type 100 and hit enter";
print "							  Example: 100\n";
print "\n";
print "==========================================================================\n"; 
print ">";
my $uplink_vlan = <STDIN>;
chomp($uplink_vlan);

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
$t->send("RTRV-VLAN-IF::$shelf-all::::BRIDGE=$uplink_virtual_bridge,VLAN=$uplink_vlan,DETAILS=Y;");
print "=============================\n";
print "I am retrieving all of the VLANIFs on $shelf\n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the video subs for $shelf\n";
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
my $FILE_SUBS_CREATES = 'VLANIF_SUB_CREATES_FOR_' . $shelf . '.txt';
my $FILE_SUBS_DELETES = 'VLANIF_SUB_DELETES_FOR_' . $shelf . '.txt';
my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_VIDEO_SUB_' . $shelf . '.txt';

my $line;

# File Handles
my $fh_video_sub_creates;		# CREATES
my $fh_video_sub_deletes;		# DELETES
my $fh_error;

# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";
open $fh_video_sub_creates, ">", $FILE_SUBS_CREATES or die "Couldn't open $FILE_SUBS_CREATES: $!\n";
open $fh_video_sub_deletes, ">", $FILE_SUBS_DELETES or die "Couldn't open $FILE_SUBS_DELETES: $!\n";

##############################################################################################################
#
#	The Creates and  Deletes Section
#
##############################################################################################################
while ($line = <$fh> )
{
  chomp($line);

		if ( $line =~ m!PATH=PROT! )
		{
			next;
		}
		# "N3-1-9-15-CH0-VP8-VC35:N1-1-VB1-6102:VLAN=608,BRIDGE=N1-1-VB1,ARP=N,DHCPDIR=CLIENT,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=N,LSVID=608,ENCAP=ETHERNETV2,
		# DOS=N,STP=OFF,STPCOST=100,STPPRIO=128,DIRN=DOWN,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CVID=UNTAGGED,SVID=608,PRIO=1,RCVID=420,
		# RXETHBWPROF=NONE,TXETHBWPROF=NONE"  	
		elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*:VLAN=(\d+),BRIDGE=(N\d+-\d+-VB\d+),.*PRIO=(\w+),RCVID=(\d+),!) 
		{
		$counter_vidsub_found++; 		
					# ("ENT-VLAN-IF::$3::::BRIDGE=$user_specified_vb,VLAN=$user_specified_vlan,ARP=N,DHCPDIR=CLIENT,PPPOESUB=Y,DOS=Y,PORTTYPE=EDGE,CVID=UNTAGGED,PRIO=0,RCVID=$2,PATH=$path_info,TRFPROF=$4,BCKPROF=$5;\n");						
 					print {$fh_video_sub_creates} ("ENT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3,PRIO=$4,RCVID=$5,ARP=N,DHCPDIR=CLIENT,PPPOESUB=Y,DOS=Y,PORTTYPE=EDGE,CVID=UNTAGGED,PATH=BOTH,TRFPROF=UBR,BCKPROF=UBR;\n");
					$counter_vidsub_created++;
					
 					print {$fh_video_sub_deletes} ("DLT-VLAN-IF::$1::::VLAN=$2,BRIDGE=$3;\n");					
					$counter_vidsub_deleted++;
		}
		else
		{
					print {$fh_error} ("No match on create for: " . $line . "\n");
		}
} 

close $fh;
close $fh_video_sub_creates;		 
close $fh_video_sub_deletes;		 
close $fh_error;

print "==========================================================\n";
print "Totals \n";
print "==========================================================\n";

print "Total VLANIFs found in TL1 retrieval file:\t " . $counter_vidsub_found . "\n";
print "Total QinQ VLANIFs written to TL1 CREATES file:\t " . $counter_vidsub_created . "\n";
print "Total QinQ VLANIFS written to TL1 DELETES file:\t " . $counter_vidsub_deleted . "\n\n";
print "\n";


 

