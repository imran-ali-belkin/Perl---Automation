use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# Counters to keep track of total cross-connect create and deletes

my $counter_total_creates = 0;
 
my $counter_cross_connect_found = 0;
my $not_matched_on_create = 0;

print "========================================================\n";
print "The C7 Ethernet Bandwidth Profile Creator\n";
print "========================================================\n";
print "\n\n";
print "This script does these two things:\n";
print "1: Logs into a C7 and pulls all Ethernet Bandwidth Profiles\n";
print "2: Creates a text file that has all of the CREATES\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES and use in your TL1\n"; 
print "scripts.\n";
print "========================================================\n";

print "\n\n";
print "========================================================\n";
print "Please enter the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

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

print "\n\n\n\n\n\n";
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
$t->send("RTRV-PROF-ETHBW::ALL;");
print "=============================\n";
print "I am retrieving all of the Ethernet Bandwidth Profiles\n";  
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the Ethernet Bandwidth Profiles\n";
print "======================================\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->timeout(30);

#$t->prompt('/^;/ms');
#Now it will automatically send/waitfor with cmd command
#$t->cmd('inh-msg-all;');
#$t->cmd('inh-msg-all;');

 #Logout
$t->send('CANC-USER;');
print "======================================\n";
print "Logging out of the C7 system\n";
print "======================================\n";
$t->close;

print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and create a CREATES file\n";
 print "=====================================================\n";

# Jason's additions
my $DATA_FILE = 'tl1_logs.txt';
my $DESTINATION_FILE = 'CREATES_ETHERNET_BANDWIDTH_PROFILES_FOR_' . $ip . '.txt';
# my $DESTINATION_FILE_2 = 'DELETES_FOR_' . $user_IG . '.txt';
my $line;
my $fh2;		# CREATES
my $fh3;		# DELETES

my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' . $ip . '.txt';
my $fh_error;
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# This is the write file
open $fh2, ">", $DESTINATION_FILE or die "Couldn't open $DATA_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);

	 if ( $line =~ /EIR/ && $line =~/"\d+::CIR/)
 	 {
			$counter_cross_connect_found++ ;
			
			# Logic to match on Ethernet Bandwidth Profile - 7.x system 
			# "1::CIR=0,EIR=1024,DESC=\"@1Meg\""
			if ($line =~ m!(\d+)::CIR=(\d+),EIR=(\d+),DESC=\\\"(.*)\\\""! )
			{
				print "We are matched!\n";
				print {$fh2} ("ENT-PROF-ETHBW::$1::::CIR=$2,EIR=$3,DESC=$4;\n"); 
				$counter_total_creates++;
			}
 			else 
			{
				print {$fh_error} ("Not matched on CREATE: $line \n");
				$not_matched_on_create++;
			}
	  
	  }
}
close $fh2;
close $fh;
close $fh_error;

print "=================================================================\n";
print "Results:\n";
print "Ethernet Bandwidth Profiles found in TL1:\t $counter_cross_connect_found \n"; 
print "Total Ethernet Bandwidth Profile Creates:\t $counter_total_creates \n";

print "If the following number is not 0 then contact Jason Murphy: $not_matched_on_create \n";
print "=================================================================\n";






