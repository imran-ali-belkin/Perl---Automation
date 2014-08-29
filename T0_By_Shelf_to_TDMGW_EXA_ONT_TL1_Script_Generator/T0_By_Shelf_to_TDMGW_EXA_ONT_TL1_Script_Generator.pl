use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# Counters to keep track of total cross-connect create and deletes
my $possible_match = 0;
my $acted_on_match = 0;


###########################################################################################################
#
# Questions for script user:
#
print "\n\n\n\n\n\n";
print "=================================================================\n";
print "The C7 T0 By Shelf to TDM Gateway EXA ONT Script Creator\n";
print "	Written 1-16-2013 by Jason Murphy\n";
print "	Used for Fort Mojave - Edmund Storck, An Do\n";
print "=================================================================\n";
print "\n\n";
print "This script does the following:\n";
print "1: Prompts the user to enter existing GR-303 data\n";
print "2: Logs into a C7 and pulls T0 cross-connect data \n";
print "3: Writes out scripts for TDM Gateway migration\n";
print "		Script 1: T0 deletes\n";
print " 	Script 2: T0 creates\n";
print " 	Script 3: VEP creates\n";
print " 	Script 4: VLANIF creates\n";

print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES or DELETES and use in your TL1\n"; 
print "scripts.\n";
print "=================================================================\n";

print "\n\n";
print "=================================================================\n";
print "Please enter either the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

 
print "\n\n";
print "=================================================================\n";
print "Enter the access shelf you want to migrate (for example N1-1 or N2-1) :\n";
print ">";
my $user_shelf = <STDIN>;
chomp($user_shelf);
my $access_shelf = uc $user_shelf;

print "\n\n";
print "=================================================================\n";
print "Enter the future IG that you want the GR-303 xcons built to\n";
print "(for example N1-1-IG4):\n";
print ">";
# Convert to uppercase for matching further down in the script
my $user_IG = <STDIN>;
chomp($user_IG);
my $future_IG = uc $user_IG; 

print "\n\n";
print "=================================================================\n";
print "Enter the TDM Gateway IG that the access shelf will use\n";
print "(for example N1-1-IG4):\n";
print ">";
# Convert to uppercase for matching further down in the script
my $user_TDMGW_shelf = <STDIN>;
chomp($user_TDMGW_shelf);
my $future_TDMGW_shelf = uc $user_TDMGW_shelf; 


print "\n\n";
print "=================================================================\n";
print "For the VLANIFs enter the future VLAN ID\n";
print "(for example 100):\n";
print ">";
my $future_VLAN = <STDIN>;
chomp($future_VLAN);
#
#
###########################################################################################################



###########################################################################################################
#
# Telnet stuff
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
$t->send("RTRV-CRS-T0::$user_shelf-ALL;");
print "=============================\n";
print "I am retrieving all of the T0 cross-connects on $access_shelf\n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the cross-connects\n";
print "======================================\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

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
my $T0_deletes_file = '1_T0 DELETES_FOR_' . $access_shelf . '.txt';
my $T0_creates_file = '2_T0 CREATES_FOR_' . $access_shelf . '.txt';
my $VEPs_creates_file = '3_VEP_CREATES_FOR_' . $access_shelf . '.txt';
my $VLANIF_creates_file = '4_VLANIF_CREATES_FOR_' . $access_shelf . '.txt';

my $line;

my $fh_T0_deletes;		# File handle for T0 DELETES
my $fh_T0_creates;		# File handle for T0 CREATES
my $fh_VEPs_creates;	# File handle for VEP CREATES
my $fh_VLANIF_creates;	# File handle for VLANIF CREATES

my $ERROR_FILE = 'TL1_ERROR_FILE_FOR_' . $access_shelf . '.txt';
my $fh_error; 	# File Handle for Any lines that do not match
open $fh_error, ">", $ERROR_FILE or die "Couldn't open $ERROR_FILE: $!\n";

# This is the read file - the source of all our info, etc:
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# These are the files to write to:
open $fh_T0_deletes, ">", $T0_deletes_file or die "Couldn't open $T0_deletes_file: $!\n";
open $fh_T0_creates, ">", $T0_creates_file or die "Couldn't open $T0_creates_file: $!\n";
open $fh_VEPs_creates, ">", $VEPs_creates_file or die "Couldn't open $VEPs_creates_file: $!\n";
open $fh_VLANIF_creates, ">", $VLANIF_creates_file or die "Couldn't open $VEPs_creates_file: $!\n";

while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /NSG=/ ){
	
	# Increment that we have a possible match
	$possible_match++;
		
	# Logic to match on ONT 
		# match 1 var is the GR-303 CRV
		# match 2 var is the ONT minus the T0 port 		
		# match 3 var is the access shelf				
		# match 4 var is the ONT T0 port
	   
	 # Match on the ONT
     if ($line =~ m!(N\d+-\d+-IG\d+-\d+),((N\d+-\d+)-\d+-\d+-\d+-)(\d+)!)
	 {
	    # Debug code
		# print {$fh_error}("Match 1 is $1\n");
		# print {$fh_error}("Match 2 is $2\n");
		# print {$fh_error}("Match 3 is $3\n");
		# print {$fh_error}("Match 4 is $4\n");
		
		# Filter out anything that is not the access shelf
		if ($3 eq $access_shelf)
		{
			# Print out the T0 deletes:
			# DLT-CRS-T0::N1-1-IG3-2,N2-1-17-4-8-1;
			print {$fh_T0_deletes}("DLT-CRS-T0::$1,$2$4;\n");
			
			# Print out the T0 creates:
			# ENT-CRS-T0::N1-1-IG3-1,N1-1-IG1-NEXT;
			print {$fh_T0_creates}("ENT-CRS-T0::$1,$future_IG-NEXT;\n");

			# Print out the VEPs			
			# ENT-VEP::N2-1-20-1-1-VEP1::::IGAID=N2-1-IG3,AOR=N1-1-IG3-1,HOSTPROTO=DHCP; This is the GR-303 CRV
			print {$fh_VEPs_creates}("ENT-VEP::$2VEP$4::::IGAID=$user_TDMGW_shelf,AOR=$1,HOSTPROTO=DHCP;\n");

			# Print out the VLANIF creates
			# ENT-VLAN-IF::N2-1-20-1-1-VEP1::::VLAN=20,BRIDGE=LOCAL,PORTTYPE=EDGE,ARP=N,DHCPDIR=CLIENT,IGMP=NONE,PPPOEAC=N,PPPOESUB=N,ENCAP=ETHERNETV2,DOS=N,DIRN=DOWN,RXETHBWPROF=ONTVEPLINE3,TXETHBWPROF=ONTVEPLINE3,CVID=UNTAGGED,PRIO=5,RCVID=NONE;
			print {$fh_VLANIF_creates}("ENT-VLAN-IF::$2VEP$4::::VLAN=$future_VLAN,BRIDGE=LOCAL,PORTTYPE=EDGE,ARP=N,DHCPDIR=CLIENT,IGMP=NONE,PPPOEAC=N,PPPOESUB=N,ENCAP=ETHERNETV2,DOS=N,DIRN=DOWN,RXETHBWPROF=ONTVEPLINE3,TXETHBWPROF=ONTVEPLINE3,CVID=UNTAGGED,PRIO=5,RCVID=NONE;\n");				
			$acted_on_match++;
		}
	 }
 	 else
	 {
			print {$fh_error} ("Did not match on create: $line \n");
 	 } 	 
   }
}
close $fh_T0_deletes;
close $fh_T0_creates;
close $fh_VEPs_creates;
close $fh_VLANIF_creates;
close $fh_error;

print "===========================================================\n";
print "Results:\n";
print "Possible matches found in source file for create:\t$possible_match\n";
print "Total ONT T0 port matches and data written out:\t $acted_on_match \n";
print "===========================================================\n";






