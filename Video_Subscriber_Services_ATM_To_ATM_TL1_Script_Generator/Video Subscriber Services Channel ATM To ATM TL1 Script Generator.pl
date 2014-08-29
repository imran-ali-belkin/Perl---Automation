use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# These are counters which keep track of how many cross-connects we create by access subscriber type
my $counter_vss_creates = 0;
my $counter_vss_deletes = 0;
my $counter_cross_connects_found = 0;

#############################################################################################################
#
# The main user interface - getting user input, etc
#
#############################################################################################################
print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The C7 Video Subscriber ATM to ATM Services Script Creator\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls VSS data cross-connect data from the IRC Card\n";
print "2: Creates a text file that has all of the DELETES for the existing VSS\n";
print "3: Creates a text file that has all of the CREATES for new VSS\n";
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
print "Please enter either node-shelf of the C7 you want to get VSS for:\n";
print "Example if it is N6-1 then just type N6-1 and hit the enter key:\n";
print ">";
my $node_shelf = <STDIN>;
chomp($node_shelf);

print "\n\n";
print "==========================================================================\n";
print "Please enter the ATM Traffic profile that the VSS are using:\n";
 print ">";
my $traffic_profile = <STDIN>;
chomp($traffic_profile);

print "\n\n";
print "==========================================================================\n";
print "What is the new ATM uplink (OC ingress) slot for the VSS:\n";
print "\tExample: N5-1-9\n";
print ">";
my $atm_ingress_slot = <STDIN>;
chomp($atm_ingress_slot);

# Syntax to retrieve
# rtrv-crs-viDVC::n6-1-all::::iRCAID=N6-1-16,tRFPROF=39;

# Output to match on:
# "N6-1-10-PP1-VP0-VC4120,N6-1-4-12-CH0-VP0-VC40::TRFPROF=39,PATH=UNPROT,APP=VIDSUBSVC,CONSTAT=NORMAL"
# "N6-1-10-PP1-VP0-VC4130,N6-1-4-13-CH0-VP0-VC40::TRFPROF=39,PATH=UNPROT,APP=VIDSUBSVC,CONSTAT=NORMAL"


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

# For VSS do this:
# rtrv-crs-viDVC::n6-1-all::::iRCAID=N6-1-16,tRFPROF=39;

$t->timeout(undef);
$t->send("RTRV-CRS-VIDVC::$node_shelf-all::::IRCAID=$user_irc_uplink,TRFPROF=$traffic_profile;");
print "=============================\n";
print "I am retrieving all of the VSS data cross-connects on  \n";
print "using shelf:					$node_shelf\n";
print "using IRC: 					$user_irc_uplink\n";
print "using ATM Traffic profile: 	$traffic_profile\n";  
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
my $CREATES_FILE = 'CREATES_FOR_' . $user_irc_uplink . '.txt';
my $DELETES_FILE = 'DELETES_FOR_' . $user_irc_uplink . '.txt';
my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_irc_uplink . '.txt';


# This is the raw read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open my $fh_DELETES, ">", $DELETES_FILE or die "Couldn't open $DELETES_FILE: $!\n";
open my $fh_CREATES, ">", $CREATES_FILE or die "Couldn't open $CREATES_FILE: $!\n";
open my $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";

##############################################################################################################
#
#	The Creates and Deletes Section
#
##############################################################################################################
my $VB_PORT = 3000;
my $line;

while ($line = <$fh> )
{
  chomp($line);

  	if ( $line =~ m!PATH=PROT!) {
		next;
	}
    elsif ($line =~ m!PP1! ){
	   $counter_cross_connects_found++;
	    				 								
		# "N6-1-10-PP1-VP0-VC4120,N6-1-4-12-CH0-VP0-VC40::TRFPROF=39,PATH=UNPROT,APP=VIDSUBSVC,CONSTAT=NORMAL"
		if ( $line =~ m!(N\d+-\d+-\d+-PP1-(VP\d+-VC\d+)),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+)::TRFPROF=(\d+),! ){

			# increment the VB port
			$VB_PORT++;					
			
			# dlt-crs-vidvc::N6-1-10-PP1-VP0-VC1010,N6-1-1-1-CH0-VP0-VC40::::irCAID=n6-1-16;
			print{$fh_DELETES} ("DLT-CRS-VIDVC::$1,$3::::IRCAID=$user_irc_uplink;\n");

			# New syntax for creates
			# ENT-CRS-VIDVC::N59-2-9-PP1-VP0-VC1424,N59-2-14-24-CH0-VP0-VC41::::IRCAID=n52-1-20,TRFPROF=19,PATH=UNPROT;
			print{$fh_CREATES} ("ENT-CRS-VIDVC::$atm_ingress_slot-PP1-$2,$3::::IRCAID=$user_irc_uplink,TRFPROF=$traffic_profile,PATH=UNPROT;\n");
			
			$counter_vss_creates++;
			$counter_vss_deletes++;
		}
		else
		{
			print {$fh_error} ("No match on create for: " . $line . "\n");
		}
 	} # end elsif

				
}	# end while

close $fh;
close $fh_CREATES;
close $fh_DELETES;
close $fh_error;

print "==========================================================\n";
print "Totals \n";
print "==========================================================\n";

print "Total cross-connects found in TL1 retrieval file:\t " . $counter_cross_connects_found . "\n";
print "Total cross-connects written to TL1 CREATES file:\t " . $counter_vss_creates  . "\n";
print "Total cross-connects written to TL1 DELETES file:\t " . $counter_vss_deletes  . "\n\n";
print "\n";
 



