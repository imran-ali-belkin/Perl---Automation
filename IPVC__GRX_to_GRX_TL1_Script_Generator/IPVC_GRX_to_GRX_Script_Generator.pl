use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

############################################################################################
#
#
# An Do requirements:

# Taken from:
# IPVC_GRX_to_GRX_Script_Generator.exe

# Retrieval:
# RTRV-CRS-VIDVC::N1-1-18-PP1-all::::IRCAID=N1-1-18;

# Output:
# N1-1-18-PP1-VP0-VC32,N1-1-7-24-CH0-VP0-VC39::TRFPROF=39,BCKPROF=39,PATH=UNPROT,ARP=N,PARP=Y,APP=IP,CONSTAT=NORMAL

# Delete Script:
# DLT-CRS-VIDVC::N1-1-18-PP1-VP0-VC32,N1-1-7-24-CH0-VP0-VC39::::IRCAID=N1-1-18;

# Create Script:
# ENT-CRS-VIDVC::N1-1-18-PP1-VP0-VC32,N1-1-7-24-CH0-VP0-VC39::::IRCAID=N1-1-18,TRFPROF=39,BCKPROF=39,ARP=N,PARP=N,PATH=BOTH;

# For path, need unprot and pro

# These are counters which keep track of how many cross-connects we create by access subscriber type
#
#
############################################################################################



############################################################################################
#
#
# Counters
#
#
my $counter_cross_connects_found = 0;
my $counter_ipvc_creates = 0;
my $counter_ipvc_deletes = 0;
my $counter_errors = 0;
#
#
#
############################################################################################




#############################################################################################################
#
# The main user interface - getting user input, etc
#
#
#
print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The C7 IPVC GRX to GRX TL1 Script Creator\n";
print "\tWritten 9-23-2031 by Jason Murphy\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls IPVC data cross-connect data from the IRC Card\n";
print "2: Creates a text file that has all of the DELETES for the existing IPVCs\n";
print "3: Creates a text file that has all of the CREATES for the exisitng IPVCs\n";
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
#
#
#
#############################################################################################################
 

#############################################################################################################
#
# Password cracker stuff
#
#
my $shell = C7::Cmd->new($destination_c7, 23);
$shell->connect;
my ($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
my $password = $shell->computeForgottenPassword( $date, $sid );
#
#
#
#############################################################################################################



#############################################################################################################
#
# Telnet to the C7 and grab all of the data
#
#
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
my $CREATES_FILE = 'CREATES_FOR_' . $user_irc_uplink . '.txt';
my $DELETES_FILE = 'DELETES_FOR_' . $user_irc_uplink . '.txt';
my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_irc_uplink . '.txt';

my $line;			# The current line we are working on as we read in the file
my $fh_creates;		# The file handle for the CREATES file
my $fh_deletes;		# The file handle for the DELETES file
my $fh_error;		# The file handle for the error log file

my $path_info = 'BOTH';

open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";

# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# Open the file handles
open $fh_creates, ">", $CREATES_FILE or die "Couldn't open $CREATES_FILE: $!\n";
open $fh_deletes, ">", $DELETES_FILE or die "Couldn't open $DELETES_FILE: $!\n";
#
#
#
#
#############################################################################################################



##############################################################################################################
#
#	The Creates and Deletes Section
#
#
#
#
#
while ($line = <$fh> )
{
  chomp($line);

  	if ( $line =~ m!PATH=PROT!) 
	{
		next;
	}
    elsif ($line =~ /VP/ )
	{
	   $counter_cross_connects_found++;
	   		
				if ( $line =~ m!(N\d+-\d+-\d+-PP1-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+)::TRFPROF=(\w+),BCKPROF=(\w+),PATH=(\w+),ARP=(\w+),PARP=(\w+),APP=(\w+),!)
				{
				# 9-23-2013 JM:
				# Line to match against:
				# N1-1-18-PP1-VP0-VC32,N1-1-7-24-CH0-VP0-VC39::TRFPROF=39,BCKPROF=39,PATH=UNPROT,ARP=N,PARP=Y,APP=IP,CONSTAT=NORMAL


				# $1 is the uplink VC
				# $2 is the access
				# $3 TRFPROF
				# $4 BCKPROF
				# $5 PATH
				# $6 ARP
				# $7 PARP
				# $8 APP		
					if ( $5 eq 'WKG')
					{
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' )
					{
						$path_info = 'UNPROT';
					}

					# Delete Script:
					# DLT-CRS-VIDVC::N1-1-18-PP1-VP0-VC32,N1-1-7-24-CH0-VP0-VC39::::IRCAID=N1-1-18;
					print {$ $fh_deletes} ("DLT-CRS-VIDVC::$1,$2::::IRCAID=$user_irc_uplink;\n"); 
					$counter_ipvc_creates++;					

					# Create Script:
					# ENT-CRS-VIDVC::N1-1-18-PP1-VP0-VC32,N1-1-7-24-CH0-VP0-VC39::::IRCAID=N1-1-18,TRFPROF=39,BCKPROF=39,ARP=N,PARP=N,PATH=BOTH;
					print {$ $fh_creates} ("ENT-CRS-VIDVC::$1,$2::::IRCAID=$user_irc_uplink,TRFPROF=$3,BCKPROF=$4,ARP=$6,PARP=$7,PATH=$5;\n"); 					
					$counter_ipvc_deletes++;
				}
				else
				{
					print {$fh_error} ("No match on create for: " . $line . "\n");
					$counter_errors++;
				}		
		}
}
close $fh_creates;
close $fh_deletes;
close $fh_error;

print "==========================================================\n";
print "Totals \n";
print "==========================================================\n";

print "Total cross-connects found in TL1 retrieval file:\t " . $counter_cross_connects_found . "\n";
print "Total cross-connects written to TL1 CREATES file:\t " . $counter_ipvc_creates . "\n";
print "Total cross-connects written to TL1 DELETES file:\t " . $counter_ipvc_deletes . "\n";
print "Total # of possible errors is:\t" . $counter_errors . "\n\n";
print "\n";
 



