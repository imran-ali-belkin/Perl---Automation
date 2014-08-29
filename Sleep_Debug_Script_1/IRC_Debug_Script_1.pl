# use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# These are counters which keep track of how many cross-connects we create by access subscriber type
my $counter_number_of_times_run = 0;


#############################################################################################################
#
# The main user interface - getting user input, etc
#
#############################################################################################################
print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The IRC Debug Script Collector Every 10 mins\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into the active IRC card\n";
print "2: Dumps debug into an output file\n";
print "3: Executes infinitely once every 10 mins - you will have to manually break this script\n";
print "==========================================================================\n";

print "\n\n";
print "==========================================================================\n";
print "Please enter either the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $destination_c7 = <STDIN>;
chomp($destination_c7);

my $user_name = 'c7support';

print "\n\n";
print "Logging into the C7 and retrieving info for N1-1-18\n\n";

# print "==========================================================================\n"; 
# print "Enter the Location of the Working IRC Card:\n";
# print "\n";
# print "Make sure to get this correct\n";
# print "For example if your IRC pair is in Slots 19 and Slots 20:\n";
# print "                                     Then input N1-1-20\n";
# print "\n";
# print "The general syntax is: \n";
# print "                                       NODE-SHELF-SLOT\n";
# print "\n";
# print ">";
# my $user_irc_uplink = <STDIN>;
# chomp($user_irc_uplink);

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
	print ("I am now in the TL1 interface and turned off messages\n");

	# Send the shell
	$t->send("shell;");
	$t->waitfor('/>/');
	print ("I am now shelled in\n");
	
	
	# Send the remote
	# $t->send("/s/rmt -s32 -cp\n");
	$t->send("/s/rmt -s18 -cp\n");
	$t->waitfor('/>/');
	print ("I am now remoted in to the IRC Card\n");
	
# This is the infinite loop:	
while (true){
	# /t/i/dhcp/dump host 0 [total dhcp lease count]
	# /t/i/vsc/dump sub
	# /t/i/lpd/diag/iphost/dump 

	print "=============================\n";
	print "Dumping data into the text file for $user_irc_uplink \n";  
	print "=============================\n";
	
	# Debug RAP dump:
	#/s/log/fllog -a		# Flash logs
	# $t->send("/s/log/fllog -a\n");
	# $t->waitfor('/>/');
	
	$t->send("/t/i/dhcp/dump host 0");
	$t->send("\n");
	$t->waitfor('/>/');

	# /t/i/dhcp/dump host 0 [total dhcp lease count]
	$t->send("/t/i/dhcp/dump host 0");
	$t->send("\n");
	$t->send("\n");
	$t->waitfor('/>/');

	# /t/i/vsc/dump sub
	$t->send("/t/i/vsc/dump sub");
	$t->send("\n");
	$t->send("\n");
	$t->waitfor('/>/');

	# /t/i/dhcp/dump host 0 [total dhcp lease count]
	$t->send("/t/i/lpd/diag/iphost/dump");
	$t->send("\n");
	$t->send("\n");
	$t->waitfor('/>/');

	$counter_number_of_times_run++;

	print "======================================\n";
	print "OK, just completed an iteration $counter_number_of_times_run\n";
	print "======================================\n";

	print "OK - sleeping for 10 mins\n";
	sleep(600);
	print "OK - done sleeping for 10  seconds\n";

	print "Just a quick carriage return!\n";
	$t->send("\n");
	$t->waitfor('/>/');

	print "And another to make sure we are awake!\n";
	$t->send("\n");
	$t->waitfor('/>/');

} 
# End while true
  
#Logout
$t->send('CANC-USER;');
print "======================================\n";
print "Logging out of the C7 system\n";
print "======================================\n";
$t->close;




 



