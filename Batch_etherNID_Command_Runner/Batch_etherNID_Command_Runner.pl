use strict;
use warnings;
# use Net::SSH qw(sshopen2);
use Net::SSH::Perl;

my $user = "admin";
my $pass = "admin";
my $host = "10.247.4.33";
my $cmd = "command";

# Counters to keep track of successful etherNID configuration
my $successfully_completed_telnets = 0;

my $CLI_prompt = "#";

###########################################################################################################
#
# User Interface:
#
#
print "\n\n\n\n\n";
print "=================================================================\n";
print "etherNID Batch Mode Command Runner\n";
print "   Written 12-10-2013 by Jason Murphy\n";
print "=================================================================\n";
print "\n\n";
print "This script does the following:\n";
print "1: Reads in a list of etherNID IP addresses from a text file named list.txt\n";
print "2: Telnets to every  and runs a retrieval\n";
print "3: Writes out and appends a text file output_log.txt\n";
print "   ***Note that the etherNID IPs must be listed one per line with no other\n";
print "      characters - i.e. no commas, quotes, exclamation marks, whatever.\n";
print "=================================================================\n";
#
#
#
#######################################################

print "\n\nOff and running...\n";

# list.txt is the batch file that will list all the etherNID IP addresses

###########################################################################################################
#
# Wrap the while stuff around the telnet stuff
#

###########################################################################################################
# File handle stuff for the batch input file
# The purpose of the list.txt file is to have a list of etherNID IPs that will be read in - see the while loop below 
#
# my $BATCH_FILE = 'list.txt';
# This is the read file - the source of all our info, etc:
# open my $fh_BATCH, '<', $BATCH_FILE or die "Could not open $BATCH_FILE: $!\n";

# This variable will hold the current etherNID that is being worked with
# my $current_etherNID;


###########################################################################################################
# File handle stuff for the output file
#
#
my $TL1_Output_File = 'TL1_Output.txt';                             # This is the file handle stuff for writing out.
my $fh_TL1_Output_File;                                           	# File handle for Output
open $fh_TL1_Output_File, ">>", $TL1_Output_File or die "Couldn't open $TL1_Output_File: $!\n";

#
#
#
###########################################################################################################


###########################################################################################################
#
# The while loop that does all of the magic - it goes throught the $fh_BATCH one line at a time using the <> 
# operator and $current_etherNID is set to the IP address of it.
#
#
#while ($current_etherNID = <$fh_BATCH> )
#{
#  chomp($current_etherNID);
		###########################################################################################################
		#
		# Telnet stuff
		#
		#
		my $user_name = 'admin';
		my $password = 'admin';
		my $current_etherNID = "10.247.4.35";
		
		print {$fh_TL1_Output_File}("===========================================================\n");
		print {$fh_TL1_Output_File}("Output for $current_etherNID");

		my $ssh = Net::SSH::Perl->new($current_etherNID);
		$ssh->login($user, $pass);

		# A very key mapping occurs here where we map the telnet to the file handle $fh_TL1_Output_File
		# my $t = new Net::Telnet ( Timeout=>30, Input_Log => $fh_TL1_Output_File);

		#etherNID IP/Hostname to open, change this to the one you want.
		$ssh->open($current_etherNID);

		#Wait for prompt to appear;
		$ssh->waitfor('/:/ms');


		print "======================================\n";
		print "Logging into:\t$current_etherNID\n";
		  #Send default username/password (Not using cracker here)
	   $ssh->send($user_name);
	   $ssh->waitfor('/:/ms');

	   $ssh->send($password);
	   $ssh->waitfor('/:/ms');

		print "Logged into:\t$current_etherNID\n";
		
		$ssh->timeout(undef);
		print "Provisioning the etherNID:\n";  

		
	   # print "Sending command: echoagent edit controller_1 192.168.1.1\n";
	   # $ssh->send("echoagent edit controller_1 192.168.1.1");
	   # $ssh->waitfor('/:/ms');
		
		#	   print "Sending command: echoagent edit communication-protocol https\n";
	   # $ssh->send("echoagent edit communication-protocol https");
	   # $ssh->waitfor('/:/ms');
		
	   print "Sending command: echoagent edit port 500\n";
	   $ssh->send("echoagent edit port 500");
	   $ssh->waitfor('/:/ms');

	   # print "Sending command: echoagent edit password cr3an0rd\n";
	   # $ssh->send("echoagent edit password cr3an0rd");
	   # $ssh->waitfor('/:/ms');
		
	   # print "Sending command: echoagent edit log-level 4\n";
	   # $ssh->send("echoagent edit log-level 4");
	   # $ssh->waitfor('/:/ms');
		
	   # print "Sending command: echoagent edit debug-level 0\n";
	   # $ssh->send("echoagent edit debug-level 0");
	   # $ssh->waitfor('/:/ms');
		
	   # print "Sending command: echoagent edit report-interval 60\n";
	   # $ssh->send("echoagent edit report-interval 60");
	   # $ssh->waitfor('/:/ms');
		
	   # print "Sending command: echoagent enable\n";
	   # $ssh->send("echoagent enable");
	   # $ssh->waitfor('/:/ms');

	   # print "Sending command: echoagent show\n";
	   # $ssh->send("echoagent show");
	   # $ssh->waitfor('/:/ms');
														
	   $ssh->timeout(30);

		#Logout
		$ssh->send('exit');
		print "Logging out of:\t$current_etherNID\n";
		print "\n======================================\n\n";
		$ssh->close;

		# close(READER);
		# close(WRITER);

		print {$fh_TL1_Output_File}("===========================================================\n");
		
		$successfully_completed_telnets++;
		#
		#
		###############################################################################################

#}
#close $fh_BATCH;
#
#
#
#
###########################################################################################################
  
                                                
###############################################################################################
#
# User Interface Stuff
#
#
print "===========================================================\n";
print "Results:\n";
print "   # of etherNIDs telnetted to:\t $successfully_completed_telnets\n";
print "===========================================================\n\n";
#
#
#
###############################################################################################
