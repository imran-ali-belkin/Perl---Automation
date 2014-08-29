use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# Counters to keep track of total cross-connect create and deletes

my $counter_total_creates = 0;
 
my $counter_cross_connect_found = 0;
my $not_matched_on_create = 0;

print "========================================================\n";
print "The C7 ATM Traffic Profile Creator\n";
print "========================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls all ATM Traffic Profiles\n";
print "2: Creates a text file that has all of the DELETES\n";
print "3: Creates a text file that has all of the CREATES\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES or DELETES and use in your TL1\n"; 
print "scripts.\n";
print "========================================================\n";

print "\n\n";
print "========================================================\n";
print "Please enter the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

my $user_name = 'c7support';
  
# print "\n\n";
# print "========================================================\n";
# print "Enter the IG group you want me to retrieve on (for example N1-1-IG1) :\n";
# print ">";
# my $user_IG = <STDIN>;
# chomp($user_IG);


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
$t->send("RTRV-PROF-TRF::ALL;");
print "=============================\n";
print "I am retrieving all of the ATM Traffic Profiles\n";  
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the ATM Traffic Profiles\n";
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
print "and create two separate files - a CREATES file and a DELETES file\n";
 print "=====================================================\n";

# Jason's additions
my $DATA_FILE = 'tl1_logs.txt';
my $DESTINATION_FILE = 'CREATES_ATM_TRAFFIC_PROFILES_FOR_' . $ip . '.txt';
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

	 if ( $line =~ /ACTIVE/ && $line =~/"\d+::COS/)
 	 {
			$counter_cross_connect_found++ ;
			
			# Logic to match on ATM Traffic Profile 
			# "307::COS=UBR,CDVT=0,PCR01=622,SCR0=0,SCR01=0,MCR=0,APP=IP,MBS=0,MFS=0,CELLTAG=N,POLICE=Y,ACTIVE=Y,DESC=\"@Newbie_IP\""
			if ($line =~ m!(\d+)::COS=(.*),CDVT=(\d+),PCR01=(\d+),SCR0=(\d+),SCR01=(\d+),MCR=(\d+),APP=(\w+),MBS=(\d+),MFS=(\d+),CELLTAG=(\w+),POLICE=(\w+),ACTIVE=([\w+]),DESC=\\\"(.*)\\\""! )
			{
				print "We are matched!\n";
				print {$fh2} ("ENT-PROF-TRF::$1::::COS=$2,CDVT=$3,PCR01=$4,SCR0=$5,SCR01=$6,MCR=$7,APP=$8,MBS=$9,MFS=$10,CELLTAG=$11,POLICE=$12,ACTIVE=$13,DESC=$14;\n"); 
				$counter_total_creates++;
			}
 			# "309::COS=UBR,CDVT=0,PCR01=14150,SCR0=0,SCR01=0,MCR=0,MBS=0,MFS=0,CELLTAG=N,POLICE=Y,ACTIVE=Y,DESC=\"@oscar_6meg\""			
			elsif ($line =~ m!(\d+)::COS=(.*),CDVT=(\d+),PCR01=(\d+),SCR0=(\d+),SCR01=(\d+),MCR=(\d+),MBS=(\d+),MFS=(\d+),CELLTAG=(\w+),POLICE=(\w+),ACTIVE=([\w+]),DESC=\\\"(.*)\\\""! )
			{
				print "We are matched!\n";
				print {$fh2} ("ENT-PROF-TRF::$1::::COS=$2,CDVT=$3,PCR01=$4,SCR0=$5,SCR01=$6,MCR=$7,MBS=$8,MFS=$9,CELLTAG=$10,POLICE=$11,ACTIVE=$12,DESC=$13;\n"); 
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
# close $fh;


# open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
# open $fh3, ">", $DESTINATION_FILE_2 or die "Couldn't open $DATA_FILE: $!\n";
# while ($line = <$fh> )
# {
#   chomp($line);

#  if ($line =~ /NSG=/ ){
	  # Logic to match on ONT or DSL 
#      if ($line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+)! || $line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+)!){
#		print {$fh3} ("DLT-CRS-T0::$1,$2;\n"); 
#		$counter_total_deletes++;
#	  }
#	  else 
#	 {
#		print {$fh_error} ("Not matched on DELETE: $line \n");
#	 } 	
#   }
#}
# close $fh3;
close $fh;
close $fh_error;

print "=================================================================\n";
print "Results:\n";
print "ATM Traffic Profiles found in TL1:\t $counter_cross_connect_found \n"; 
print "Total ATM Traffic Profile Creates:\t $counter_total_creates \n";

print "If the following number is not 0 then contact Jason Murphy: $not_matched_on_create \n";
print "=================================================================\n";






