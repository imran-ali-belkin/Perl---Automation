use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;
##############################################################################################
#
# C7 to E7 GPON T0 Attribute Script Generator
# Written 3/13/2014 Jason Murphy
#
##############################################################################################

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
print "The C7 GPON ONT to E7 GPON T0 Port Attribute Script Generator\n";
print "\tWritten 3-14-2014\n";
print "\tRequirements by An Do\n";
print "\tCoded by Jason Murphy\n";

print "========================================================\n";
print "\n\n";
print "This script performs the following:\n";
print "1: Logs into a C7 and pulls all T0 port info from a GPON card\n";
print "2: Creates one text files that contains the E7 syntax\n";
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
$t->send("RTRV-T0::$C7_gpon_card-all;");
print "=============================\n";
print "I am retrieving all T0 ports on $C7_gpon_card\n";  
print "Please be patient.\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the T0 ports on $C7_gpon_card\n";
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
print "and create 3 separate files.\n";
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
my $line;


# File Output Name: 
# E7_ONT_T0_Voice_Port_Settings_Nx-x-x
# (where Nx-x-x is the card in question #2).


my $fh_E7_CREATES;		# File handle for E7 syntax
my $DESTINATION_FILE_1 = 'E7_ONT_T0_Voice_Port_Settings_' . $C7_gpon_card . '.txt';
open $fh_E7_CREATES, ">", $DESTINATION_FILE_1 or die "Couldn't open $DESTINATION_FILE_1: $!\n";


# File handle stuff for the error file
my $fh_error;		# File handle for errors
my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' . $C7_gpon_card  . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

# Open the data file for reading in the tl1_logs.txt
my $DATA_FILE = 'tl1_logs.txt';			
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# Open the destination file for writing out the E7 syntax
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
	 # JM 3/14/2014
	 # INPUT     "N130-1-1-1-3-1::GSFN=2LS,RTLP=GR909,TTLP=GR909,DESC=\"7015672598\":OOS-AU,SDEE&SGEO"
	 # OUTPUT     set ont-port 51203/p1 system-rx-loss gr-909 system-tx-loss gr-909 description "7015672598" admin-state enabled
	#            "N1-1-16-1-1-1::CRV=N1-1-IG1-1,GSFN=2LS,RTLP=GR909,TTLP=GR909,DESC=\"Rolfe Paul\":OOS-AU,SGEO&CRS"
	          
     # "N1-1-17-3-11-1::CRV=N1-1-IG1-203,GSFN=2LS,RTLP=GR909,TTLP=GR909,:OOS-AU,SGEO&CRS" 			  
	 if (
	 $line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::CRV=N\d+-\d+-IG\d+-\d+,GSFN=(\w+),RTLP=(\w+),TTLP=(\w+),DESC=\\"(.*)\\":!
	 ||
	 $line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::CRV=N\d+-\d+-IG\d+-\d+,GSFN=(\w+),RTLP=(\w+),TTLP=(\w+)[,:]!	 
	 )
	 {			
				
				  # $1 = ONT L2IFAID 
				  # $2 = PON Port
				  # $3 = ONT # 
				  # $4 = ONT T0 port				  
				  # $5 = GSFN
				  # $6 = RTLP
				  # $7 = TTLP
				  # $8 = DESC
				  			
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
			
			my $RTLP = $6;
			if ($RTLP eq 'GR909'){
				$RTLP = 'gr-909';
			}
			if ($RTLP eq 'ANSI'){
				$RTLP = 'ansi';
			}
			
			my $TTLP = $7;
			if ($TTLP eq 'GR909'){
				$TTLP = 'gr-909';
			}
			if ($TTLP eq 'ANSI'){
				$TTLP = 'ansi';
			}
			
			
			
		  # $1 = ONT L2IFAID 		
		  # $2 = PON Port
		  # $3 = ONT # 
		  # $4 = ONT T0 port				  
		  # $5 = GSFN
		  # $6 = RTLP			$RTLP
		  # $7 = TTLP			$TTLP
		  # $8 = DESC

			# INPUT     "N130-1-1-1-3-1::GSFN=2LS,RTLP=GR909,TTLP=GR909,DESC=\"7015672598\":OOS-AU,SDEE&SGEO"
			# OUTPUT     set ont-port 51203/p1 system-rx-loss gr-909 system-tx-loss gr-909 description "7015672598" admin-state enabled
			# Rule#2 - For RLTP/TTLP=GR909 on the C7, use gr-909 (lower case with a dash) on the E7
			# For RLTP/TTLP=ANSI on the C7, use ansi (lower case) on the E7 
	
			# If PON port 1
			if ( $2 eq '1')
			{ 
			    if ($8)
				{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_1_prefix$temp_ont/p$4 system-rx-loss $RTLP system-tx-loss $TTLP description \"$8\" admin-state enabled\n");
					$xcon_written_port_1++;
					$xcon_written++;
				}
				else
				{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_1_prefix$temp_ont/p$4 system-rx-loss $RTLP system-tx-loss $TTLP description \"\" admin-state enabled\n");
					$xcon_written_port_1++;
					$xcon_written++;
				}				
			}
			# If PON port 2
			elsif ( $2 eq '2')
			{ 
				if ($8)
				{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_2_prefix$temp_ont/p$4 system-rx-loss $RTLP system-tx-loss $TTLP description \"$8\" admin-state enabled\n");
					$xcon_written_port_2++;
					$xcon_written++;	
				}
				else 
				{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_2_prefix$temp_ont/p$4 system-rx-loss $RTLP system-tx-loss $TTLP description \"\" admin-state enabled\n");
					$xcon_written_port_2++;
					$xcon_written++;
				}
			}
			# If PON port 3
			elsif ( $2 eq '3')
			{
				if ($8)
				{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_3_prefix$temp_ont/p$4 system-rx-loss $RTLP system-tx-loss $TTLP description \"$8\" admin-state enabled\n");
					$xcon_written_port_3++;
					$xcon_written++;
				}
				else
				{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_3_prefix$temp_ont/p$4 system-rx-loss $RTLP system-tx-loss $TTLP description \"\" admin-state enabled\n");				
					$xcon_written_port_3++;
					$xcon_written++;
				}
			}			
			# If PON port 4
			elsif ( $2 eq '4')
			{
				if ($8)
				{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_4_prefix$temp_ont/p$4 system-rx-loss $RTLP system-tx-loss $TTLP description \"$8\" admin-state enabled\n");
					$xcon_written_port_4++;
					$xcon_written++;
				}
				else
				{
					print {$fh_E7_CREATES} ("set ont-port $gpon_port_4_prefix$temp_ont/p$4 system-rx-loss $RTLP system-tx-loss $TTLP description \"\" admin-state enabled\n");
					$xcon_written_port_4++;
					$xcon_written++;
				}

			}			
		}
		 # No match at all - write it to the error log and increment the $ont_not_matched counter
		 else 
		 {
			print {$fh_error} ("No match for: $line \n");
			$xcon_not_matched++;
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

print "Voice CRV found on GPON port 1:\t $xcon_written_port_1\n";
print "Voice CRV found on GPON port 2:\t $xcon_written_port_2\n";
print "Voice CRV found on GPON port 3:\t $xcon_written_port_3\n";
print "Voice CRV found on GPON port 4:\t $xcon_written_port_4\n";

print" Total Voice entries written out to E7 file: $xcon_written\n";

print" Total xcons not matched: $xcon_not_matched\n";

print "=================================================================\n";
#
#
##############################################################################################




