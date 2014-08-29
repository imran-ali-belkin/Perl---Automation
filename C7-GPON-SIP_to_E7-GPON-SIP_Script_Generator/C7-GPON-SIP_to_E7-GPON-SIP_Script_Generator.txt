use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

##############################################################################################
#
# Counters to keep track of things
#
#
my $xcon_found = 0;
my $xcon_written = 0;
my $xcon_not_matched = 0;

my $xcon_written_port_1 = 0;
my $xcon_written_port_2 = 0;
my $xcon_written_port_3 = 0;
my $xcon_written_port_4 = 0;

#
#
#
##############################################################################################


##############################################################################################
#
#	User Interface Section
#
#
#
#
print "========================================================\n";
print "The C7 GPON SIP to E7 GPON SIP Script Creator\n";
print "\tWritten 1-15-2014\n";
print "\tRequirements provided by An Do\n";
print "\tCoded by Jason Murphy\n";

print "========================================================\n";
print "\n\n";
print "This script performs the following:\n";
print "1: Logs into a C7 and pulls voice VEPs from a GPON card\n";
print "2: Creates a text file that has the E7 VEPs syntax\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual modifications to the E7 system.\n";
print "========================================================\n";

print "\n\n";
print "========================================================\n";
print "Enter the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

print "\n\n";
print "========================================================\n";
print "Enter the C7 GPON card Node-Shelf-Slot you want to retrieve:\n";
print "      Example: N1-1-2 or N2-1-20\n";
print ">";
my $C7_gpon_card = <STDIN>;
chomp($C7_gpon_card);

print "\n\n";
print "========================================================\n";
print "Enter the E7 sip-rmt-cfg-profile(example: \@E7_GPON_SIP):\n";
print ">";
my $E7_sip_rmt_cfg_profile = <STDIN>;
chomp($E7_sip_rmt_cfg_profile);

print "\n\n";
print "========================================================\n";
print "Enter the E7 start ONT pre-fix for GPON PORT 1:\n";
print ">";
my $gpon_port_1_prefix = <STDIN>;
chomp($gpon_port_1_prefix);

print "\n\n";
print "========================================================\n";
print "Enter the E7 start ONT pre-fix for GPON PORT 2:\n";
print ">";
my $gpon_port_2_prefix = <STDIN>;
chomp($gpon_port_2_prefix);

print "\n\n";
print "========================================================\n";
print "Enter the E7 start ONT pre-fix for GPON PORT 3:\n";
print ">";
my $gpon_port_3_prefix = <STDIN>;
chomp($gpon_port_3_prefix);

print "\n\n";
print "========================================================\n";
print "Enter the E7 start ONT pre-fix for GPON PORT 4:\n";
print ">";
my $gpon_port_4_prefix = <STDIN>;
chomp($gpon_port_4_prefix);

# This is the part where we push user-entered traffic profiles onto the @atm_traf_profiles_to_ignore array
# my @atm_traf_profiles_to_ignore_array;

# print "\n\n";
# print "========================================================\n";
# print " Enter the C7 ATM Profile(s) for APPID=IP\n";
# print " Cross-connects that match this profile will be ignored\n\n";
# print " Enter 1 ATM Profile integer per line and hit enter\n";
# print " When you are done just leave the line blank and hit enter\n";
# print ">";

# while ( ($_ = <>) =~ /\S/ ) 
# {
#   chomp;
#   push @atm_traf_profiles_to_ignore_array, $_;
#   print ">";
#}

print "====================================\n";
print "\nOk - time to launch telnet session\n";
print "====================================\n";
#
#
#
#
#
##############################################################################################




##############################################################################################
#
#	Telnet to C7 to retrieve ONT data
#
#
#
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

print "\n\n\n\n\n\n";
print "========================\n";
print "Logging in to C7 at $ip\n";
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
$t->send("RTRV-VEP::$C7_gpon_card-all;");
print "=============================\n";
print "I am retrieving all VEPs on $C7_gpon_card\n";  
print "Please be patient.\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the VEPs on $C7_gpon_card\n";
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
print "Logging out of the C7 at $ip\n";
print "======================================\n";
$t->close;

print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and create an E7 CREATES file for t\n";
print "=====================================================\n";
#
#
#
#
##############################################################################################
 
 
 
 
##############################################################################################
#
# File Handles 
# 
my $DATA_FILE = 'tl1_logs.txt';			
my $line;

my $fh_E7_CREATES;		# File handle for CREATES
my $DESTINATION_FILE = 'E7_SYNTAX_FOR_VEPs_' . $C7_gpon_card . '.txt';

# File handle stuff for the error file
my $fh_error;		# File handle for errors
my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' . $C7_gpon_card  . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

# Open the data file for reading in the tl1_logs.txt
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# Open the destination file for writing out the E7 syntax
open $fh_E7_CREATES, ">", $DESTINATION_FILE or die "Couldn't open $DATA_FILE: $!\n";
# 
# 
# 
# 
##############################################################################################


##############################################################################################
#
# Variables used
#
my $temp_ont;
my $temp_RTLP;


##############################################################################################
#
# Open the TL1 Logs, Pattern Match and Write out to the CREATES and DELETES Files
#
#
#
while ($line = <$fh> )
{
  chomp($line);
     # N130-1-1-1-1-VEP1::IGAID=N130-1-IG6,USER=7015674000,PID=11M00c97,AOR=7015674000,HOSTPROTO=DHCP,:OOS-AU,SGEO&SDEE;
	 #                N130-1-  1-   1-     1-VEP1      ::IGAID=N130-1-IG6,    USER=7015674000,PID=11M00c97,AOR=7015674000,HOSTPROTO=DHCP,:OOS-AU,SGEO&SDEE;
	 if ($line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-VEP(\d+))::IGAID=N\d+-\d+-IG\d+,USER=(\w+),PID=(\w+),AOR=(\w+),!)
	 {
			print "Made it inside the regex\n";
			# $1 is the entire AID
			# $2 is the OLTG port
			# $3 is the ONT
			# $4 is the VEP
			# $5 is the USER
			# $6 is the PID
			# $7 is the AOR
			
			# add sip-svc to-ont-port 51203/p1 sip-rmt-cfg-profile @E7_GPON_SIP user 7015674000 password 11M00c97 uri 7015674000 sip-rmt-cfg-override enabled admin-state enabled

			# Rule#1 - 5123/p1  (ONT#/Port#)
			# This is pulled from destination port N130-1-1-1-3-1-1 (Node-Shelf-Slot-GPON#-ONT#-VEP#)
			# Use the same ONT pre-fix from the ONT script Generator to create the ONT number.  Use the ONT pre-fix, then add ONT# = 51203 (ONT Pre-Fix=512, ONT#3)
			# For the ONT voice port (p1), use the VEP# after the ONT#, in this case it is VEP1. If it is VEP2, use p2, etc. 

			
			# Logic to put a zero in front of any ONTs numbered 1-9
			if ($3 eq '1')
			{
				$temp_ont = '01';
			}
			elsif ($3 eq '2')
			{
				$temp_ont = '02';
			}
			elsif ($3 eq '3')
			{
				$temp_ont = '03';
			}
			elsif ($3 eq '4')
			{
				$temp_ont = '04';
			}
			elsif ($3 eq '5')
			{
				$temp_ont = '05';
			}
			elsif ($3 eq '6')
			{
				$temp_ont = '06';
			}
			elsif ($3 eq '7')
			{
				$temp_ont = '07';
			}
			elsif ($3 eq '8')
			{
				$temp_ont = '08';
			}
			elsif ($3 eq '9')
			{
				$temp_ont = '09';
			}
			else
			{
				$temp_ont = $3;
			}
			# $1 is the entire AID
			# $2 is the OLTG port
			# $3 is the ONT
			# $4 is the VEP
			# $5 is the USER
			# $6 is the PID
			# $7 is the AOR
			
									
			# add sip-svc to-ont-port 51203/p1 sip-rmt-cfg-profile @E7_GPON_SIP user 7015674000 password 11M00c97 uri 7015674000 sip-rmt-cfg-override enabled admin-state enabled
					
			# If PON port 1
			if ( $2 eq '1')
			{ 
				print {$fh_E7_CREATES} ("add sip-svc to-ont-port $gpon_port_1_prefix$temp_ont/p$4 sip-rmt-cfg-profile $E7_sip_rmt_cfg_profile user $5 password $6 uri $7 sip-rmt-cfg-override enabled admin-state enabled\n");
				$xcon_written_port_1++;
				$xcon_written++;
			}
			# If PON port 2
			elsif ( $2 eq '2')
			{ 
				print {$fh_E7_CREATES} ("add sip-svc to-ont-port $gpon_port_2_prefix$temp_ont/p$4 sip-rmt-cfg-profile $E7_sip_rmt_cfg_profile user $5 password $6 uri $7 sip-rmt-cfg-override enabled admin-state enabled\n");
				$xcon_written_port_2++;
				$xcon_written++;
			}
			# If PON port 3
			elsif ( $2 eq '3')
			{ 
				print {$fh_E7_CREATES} ("add sip-svc to-ont-port $gpon_port_3_prefix$temp_ont/p$4 sip-rmt-cfg-profile $E7_sip_rmt_cfg_profile user $5 password $6 uri $7 sip-rmt-cfg-override enabled admin-state enabled\n");
				$xcon_written_port_3++;
				$xcon_written++;
			}			
			# If PON port 4
			elsif ( $2 eq '4')
			{ 
				print {$fh_E7_CREATES} ("add sip-svc to-ont-port $gpon_port_4_prefix$temp_ont/p$4 sip-rmt-cfg-profile $E7_sip_rmt_cfg_profile user $5 password $6 uri $7 sip-rmt-cfg-override enabled admin-state enabled\n");
				$xcon_written_port_4++;
				$xcon_written++;
			}			
		 # No match at all - write it to the error log and increment the $ont_not_matched counter
			 else 
			 {
				print {$fh_error} ("No match for: $line \n");
				$xcon_not_matched++;
			 }

		}
}

#	End of all the pattern matching and manipulation
#
#
#
##############################################################################################



##############################################################################################
#
# File Handles - Close them
#
#
close $fh_E7_CREATES;
close $fh;
close $fh_error;
#
#
#
#
##############################################################################################



##############################################################################################
#
# Let the user know the results
#
#
#
print "=================================================================\n";
print "Results:\n";

print "Voice VEPs found on port 1:\t $xcon_written_port_1\n";
print "Voice VEPs found on port 2:\t $xcon_written_port_2\n";
print "Voice VEPs found on port 3:\t $xcon_written_port_3\n";
print "Voice VEPs  found on port 4:\t $xcon_written_port_4\n";

print" Total Voice VEP entries written out to E7 file: $xcon_written\n";

print" Total Voice VEP not matched: $xcon_not_matched\n";

print "=================================================================\n";
#
#
##############################################################################################




