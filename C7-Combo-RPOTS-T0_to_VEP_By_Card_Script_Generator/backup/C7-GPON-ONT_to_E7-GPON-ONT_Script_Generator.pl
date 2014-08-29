use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

##############################################################################################
#
# Counters to keep track of things
#
#
my $ont_found = 0;
my $ont_written = 0;
my $ont_not_matched = 0;

my $gpon_ont_on_port_1_found = 0;
my $gpon_ont_on_port_2_found = 0;
my $gpon_ont_on_port_3_found = 0;
my $gpon_ont_on_port_4_found = 0;
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
print "The C7 GPON T0 E7 GPON ONT Script Creator\n";
print "\tWritten 1-15-2014\n";
print "\tRequirements provided by An Do\n";
print "\tCoded by Jason Murphy\n";

print "========================================================\n";
print "\n\n";
print "This script performs the following:\n";
print "1: Logs into a C7 and pulls GPON ONT data\n";
print "2: Creates a text file that has the E7 ONT syntax\n";
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
$t->send("RTRV-ONT::$C7_gpon_card-all;");
print "=============================\n";
print "I am retrieving all ONTs on $C7_gpon_card\n";  
print "Please be patient.\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the ONTs on \n";
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
my $DESTINATION_FILE = 'E7_SYNTAX_FOR_' . $C7_gpon_card . '.txt';

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

my $temp_card;
my $temp_ont;

##############################################################################################
#
# Open the TL1 Logs, Pattern Match and Write out to the CREATES and DELETES Files
#
#
#
while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /ONTNUM=/ ){
	 $ont_found++; 

	 
	 ##############################################################################################################################3
	 ##############################################################################################################################3
	 #
	 # Port 1 related
	 #
	 # Match on GPON port 1 - COMPLETED
	 # Match on GPON port 1 with REGID Missing in match - COMPLETED
	 # Match on GPON port 1 REGID not present in TL1 output - COMPLETED
	 # Match on GPON port 1 ONTNUM, REGID and ONTPROF present but no description
	 # Match on GPON port 1 ONTNUM, ONTPROF present but no description
	 #
	 ##############################################################################################################################3
	 ##############################################################################################################################3
	 

	 
	 # If matches on GPON Port 1
	 #"N130-1-1-1-1::ONTNUM=5D0D7,REGID=7015674000,ONTPROF=30,VCG=N105-1-IG3,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,DESC=\"HETTINGER CO 407 3RD AVE N\",ADRMODE=GRP:OOS-AU,SDEE&SGEO&UEQ"
     if ($line =~ m!(N\d+-\d+-(\d+)-1-(\d+))::ONTNUM=(\w+),REGID=(\w+),ONTPROF=(\w+),.*DESC=(.*),ADRMODE!)
	 {
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
		
		
		# create ont 11301 profile 714GX serial-number 5D0D7 reg-id 7015674000 description ""HETTINGER CO 407 3RD AVE N"" admin-state enabled"
		print {$fh_E7_CREATES} ("create ont $gpon_port_1_prefix$temp_ont profile $6 serial-number $4 reg-id $5 description $7\" admin-state enabled\n");
		$gpon_ont_on_port_1_found++;
		$ont_written++;
	 }
	 

	 # If matches on GPON Port 1 - with REGID blank
	 #"N130-1-1-1-1::ONTNUM=5D0D7,REGID=7015674000,ONTPROF=30,VCG=N105-1-IG3,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,DESC=\"HETTINGER CO 407 3RD AVE N\",ADRMODE=GRP:OOS-AU,SDEE&SGEO&UEQ"
     elsif ($line =~ m!(N\d+-\d+-(\d+)-1-(\d+))::ONTNUM=(\w+),REGID=,ONTPROF=(\w+),.*DESC=(.*),ADRMODE! || 
			$line =~ m!(N\d+-\d+-(\d+)-1-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),.*DESC=(.*),ADRMODE!)
	 {
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
		
		
		# create ont 11301 profile 714GX serial-number 5D0D7 reg-id 7015674000 description ""HETTINGER CO 407 3RD AVE N"" admin-state enabled"
		print {$fh_E7_CREATES} ("create ont $gpon_port_1_prefix$temp_ont profile $5 serial-number $4 description $6\" admin-state enabled\n");
		$gpon_ont_on_port_1_found++;
		$ont_written++;
	 }



	 # If matches on GPON Port 1 - ONTNUM, REGID, ONTPROF but no DESCRIPTION
	# No match for:    "N130-1-1-1-18::ONTNUM=0,REGID=7015672681,ONTPROF=32,VCG=N105-1-IG3,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,ADRMODE=PORT:OOS-AU,SGEO&UEQ" 
     elsif ($line =~ m!(N\d+-\d+-(\d+)-1-(\d+))::ONTNUM=(\w+),REGID=(\w+),ONTPROF=(\w+),!)
	 {
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
		
		# create ont 11301 profile 714GX serial-number 5D0D7 reg-id 7015674000 description ""HETTINGER CO 407 3RD AVE N"" admin-state enabled"
		print {$fh_E7_CREATES} ("create ont $gpon_port_1_prefix$temp_ont profile $6 serial-number $4 reg-id $5 description \"\" admin-state enabled\n");
		$gpon_ont_on_port_1_found++;
		$ont_written++;
	 }

	 #############CURRENT CODE

	 # If matches on GPON Port 1 - ONTNUM, ONTPROF but no DESCRIPTION
	 # No match for:    "N130-1-1-3-23::ONTNUM=1234,ONTPROF=ONT710,VCG=N105-1-IG2,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,ADRMODE=PORT:OOS-AU,SGEO&UEQ" 
     elsif ($line =~ m!(N\d+-\d+-(\d+)-1-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),!)
	 {
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
		
		# create ont 11301 profile 714GX serial-number 5D0D7 reg-id 7015674000 description ""HETTINGER CO 407 3RD AVE N"" admin-state enabled"
		print {$fh_E7_CREATES} ("create ont $gpon_port_1_prefix$temp_ont profile $5 serial-number $4 description \"\" admin-state enabled\n");
		$gpon_ont_on_port_1_found++;
		$ont_written++;
	 }
	 
	 



	 ############CURRENT 10:15 AM, Pacific

	 ##############################################################################################################################3
	 ##############################################################################################################################3
	 #
	 # Port 2 related
	 #
	 # Match on GPON port 2 - COMPLETED
	 # Match on GPON port 2 with REGID Missing in match - COMPLETED
	 # Match on GPON port 2 with Description missing - COMPLETED
	 # Match on GPON port 2 with Descrpition and REGID missing
	 ##############################################################################################################################3
	 ##############################################################################################################################3

	 # Match on GPON port 2
     elsif ($line =~ m!(N\d+-\d+-(\d+)-2-(\d+))::ONTNUM=(\w+),REGID=(\w+),ONTPROF=(\w+),.*DESC=(.*),ADRMODE!)
	 {
			# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic

		print {$fh_E7_CREATES} ("create ont $gpon_port_2_prefix$temp_ont profile $6 serial-number $4 reg-id $5 description $7\" admin-state enabled\n");
		$gpon_ont_on_port_2_found++;
		$ont_written++;
	 }
	 
	 
	 	 # Match on GPON port 2 - with REGID missing
		elsif ($line =~ m!(N\d+-\d+-(\d+)-2-(\d+))::ONTNUM=(\w+),REGID=,ONTPROF=(\w+),.*DESC=(.*),ADRMODE!
				||
				$line =~ m!(N\d+-\d+-(\d+)-2-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),.*DESC=(.*),ADRMODE!)
		{
			# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
	
		print {$fh_E7_CREATES} ("create ont $gpon_port_2_prefix$temp_ont profile $5 serial-number $4 description $6\" admin-state enabled\n");
		$gpon_ont_on_port_2_found++;
		$ont_written++;
	 }
	 
	 	 # Match on GPON port 2 - with description missing
	 	 #No match for:    "N130-1-1-1-18::ONTNUM=0,REGID=7015672681,ONTPROF=32,VCG=N105-1-IG3,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,ADRMODE=PORT:OOS-AU,SGEO&UEQ" 
     elsif ($line =~ m!(N\d+-\d+-(\d+)-2-(\d+))::ONTNUM=(\w+),REGID=(\w+),ONTPROF=(\w+),!)
	 {
			# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
		print {$fh_E7_CREATES} ("create ont $gpon_port_2_prefix$temp_ont profile $6 serial-number $4 reg-id $5 description \"\" admin-state enabled\n");
		$gpon_ont_on_port_2_found++;
		$ont_written++;
	 }
	 
	 	 # No match for:    "N130-1-1-3-23::ONTNUM=1234,ONTPROF=ONT710,VCG=N105-1-IG2,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,ADRMODE=PORT:OOS-AU,SGEO&UEQ" 
     elsif ($line =~ m!(N\d+-\d+-(\d+)-2-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),!)
	 {
			# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
		print {$fh_E7_CREATES} ("create ont $gpon_port_2_prefix$temp_ont profile $5 serial-number $4 description \"\" admin-state enabled\n");
		$gpon_ont_on_port_2_found++;
		$ont_written++;
	 }
	 
	 
	 
	 ##############################################################################################################################3
	 ##############################################################################################################################3
	 #
	 # Port 3 related
	 #
	 # Match on GPON port 3 - COMPLETED
	 # Match on GPON port 3 with REGID Missing in match - COMPLETED
	 #
	 #
	 ##############################################################################################################################3
	 ##############################################################################################################################3

	 # Match on GPON port 3
     elsif ($line =~ m!(N\d+-\d+-(\d+)-3-(\d+))::ONTNUM=(\w+),REGID=(\w+),ONTPROF=(\w+),.*DESC=(.*),ADRMODE!)
	 {						
					# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic

		print {$fh_E7_CREATES} ("create ont $gpon_port_3_prefix$temp_ont profile $6 serial-number $4 reg-id $5 description $7\" admin-state enabled\n");
		$gpon_ont_on_port_3_found++;
		$ont_written++;
	 }
	 
	 
	 
	 
	 	 # Match on GPON port 3 with REGID blank
     elsif ($line =~ m!(N\d+-\d+-(\d+)-3-(\d+))::ONTNUM=(\w+),REGID=,ONTPROF=(\w+),.*DESC=(.*),ADRMODE!
			||
			$line =~ m!(N\d+-\d+-(\d+)-3-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),.*DESC=(.*),ADRMODE!)
	 {						
					# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic

	print {$fh_E7_CREATES} ("create ont $gpon_port_3_prefix$temp_ont profile $5 serial-number $4 description $6\" admin-state enabled\n");
		$gpon_ont_on_port_3_found++;
		$ont_written++;
	 }
	 
	 
	 	 # Match on GPON port 3 with Desc missing
     elsif ($line =~ m!(N\d+-\d+-(\d+)-3-(\d+))::ONTNUM=(\w+),REGID=(\w+),ONTPROF=(\w+),!)
	 {						
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic

		print {$fh_E7_CREATES} ("create ont $gpon_port_3_prefix$temp_ont profile $6 serial-number $4 reg-id $5 description \"\" admin-state enabled\n");
		$gpon_ont_on_port_3_found++;
		$ont_written++;
	 }
	 
	 
	 # Match on GPON port 3 with Desc and REGID missing
     elsif ($line =~ m!(N\d+-\d+-(\d+)-3-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),!)
	 {						
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic

		print {$fh_E7_CREATES} ("create ont $gpon_port_3_prefix$temp_ont profile $5 serial-number $4 description \"\" admin-state enabled\n");
		$gpon_ont_on_port_3_found++;
		$ont_written++;
	 }
	 
	 
	 ##############################################################################################################################3
	 ##############################################################################################################################3
	 #
	 # Port 4 related
	 #
	 # Match on GPON port 4 - COMPLETED
	 # Match on GPON port 4 with REGID Missing in match - COMPLETED
	 #
	 #
	 ##############################################################################################################################3
	 ##############################################################################################################################3
	 
	 # Match on GPON port 4
     elsif ($line =~ m!(N\d+-\d+-(\d+)-4-(\d+))::ONTNUM=(\w+),REGID=(\w+),ONTPROF=(\w+),.*DESC=(.*),ADRMODE!)
	 {
	
	
			# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
	 
		print {$fh_E7_CREATES} ("create ont $gpon_port_4_prefix$temp_ont profile $6 serial-number $4 reg-id $5 description $7\" admin-state enabled\n");
		$gpon_ont_on_port_4_found++;
		$ont_written++;
	 }
	 
	 
	 
	 	 # Match on GPON port 4 w/ REGID blank
     elsif ($line =~ m!(N\d+-\d+-(\d+)-4-(\d+))::ONTNUM=(\w+),REGID=,ONTPROF=(\w+),.*DESC=(.*),ADRMODE!
			||
			$line =~ m!(N\d+-\d+-(\d+)-4-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),.*DESC=(.*),ADRMODE!)
	 {
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
	 
		print {$fh_E7_CREATES} ("create ont $gpon_port_4_prefix$temp_ont profile $5 serial-number $4 description $6\" admin-state enabled\n");
		$gpon_ont_on_port_4_found++;
		$ont_written++;
	 }
	 
	 # Match on GPON port 4 with DESC missing
     elsif ($line =~ m!(N\d+-\d+-(\d+)-4-(\d+))::ONTNUM=(\w+),REGID=(\w+),ONTPROF=(\w+),!)
	 {
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
	 
		print {$fh_E7_CREATES} ("create ont $gpon_port_4_prefix$temp_ont profile $6 serial-number $4 reg-id $5 description \"\" admin-state enabled\n");
		$gpon_ont_on_port_4_found++;
		$ont_written++;
	 }
	 
	 	 # Match on GPON port 4 with DESC missing and REGID missing
     elsif ($line =~ m!(N\d+-\d+-(\d+)-4-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),!)
	 {
		# Logic to put a zero in front of any cards numbered 1-9
		if ($2 eq '1')
		{
			$temp_card = '01';
		}
		elsif ($2 eq '2')
		{
			$temp_card = '02';
		}
		elsif ($2 eq '3')
		{
			$temp_card = '03';
		}
		elsif ($2 eq '4')
		{
			$temp_card = '04';
		}
		elsif ($2 eq '5')
		{
			$temp_card = '05';
		}
		elsif ($2 eq '6')
		{
			$temp_card = '06';
		}
		elsif ($2 eq '7')
		{
			$temp_card = '07';
		}
		elsif ($2 eq '8')
		{
			$temp_card = '08';
		}
		elsif ($2 eq '9')
		{
			$temp_card = '09';
		}
		# End the number conversion logic

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
		# End the number conversion logic
	 
		print {$fh_E7_CREATES} ("create ont $gpon_port_4_prefix$temp_ont profile $5 serial-number $4 description \"\" admin-state enabled\n");
		$gpon_ont_on_port_4_found++;
		$ont_written++;
	 }
	 
	 
	 
	 
	 
	 
	 # No match at all - write it to the error log and increment the $ont_not_matched counter
	 else 
	 {
		print {$fh_error} ("No match for: $line \n");
		$ont_not_matched++;
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
print "ONTs found in the C7 source TL1 file:\t $ont_found++\n"; 

print "ONTs found on port 1:\t $gpon_ont_on_port_1_found\n";
print "ONTs found on port 2:\t $gpon_ont_on_port_2_found\n";
print "ONTs found on port 3:\t $gpon_ont_on_port_3_found\n";
print "ONTs found on port 4:\t $gpon_ont_on_port_4_found\n";

print" Total ONTs not matched: $ont_not_matched\n";

print" Total ONTs written out to E7 file: $ont_written\n";

print "=================================================================\n";
#
#
##############################################################################################




