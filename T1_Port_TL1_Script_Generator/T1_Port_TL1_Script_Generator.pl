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
print "The C7 T1 Port TL1 Script Generator\n";
print "	Written 2-15-2013 by Jason Murphy\n";
print "=================================================================\n";
print "\n\n";
print "This script does the following:\n";
print "1: Prompts the user to enter the shelf of the T1 ports\n";
print "2: Logs into a C7 and pulls T1 port data (i.e. framing/encoding)\n";
print "3: Writes out a script for T1 port edits\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the edits into your TL1 pump of choice.\n"; 
print "=================================================================\n";

print "\n\n";
print "=================================================================\n";
print "Please enter either the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

 
print "\n\n";
print "=================================================================\n";
print "Enter the shelf that has the T1 ports (i.e. N5-1 and hit enter) :\n";
print ">";
my $user_shelf = <STDIN>;
chomp($user_shelf);
my $access_shelf = uc $user_shelf;
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
$t->send("RTRV-T1::$user_shelf-ALL;");
print "=============================\n";
print "I am retrieving all of the T1 physical port data on $access_shelf\n";  
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
my $T1_edits_file = 'T1_PORT_EDITS_FOR_' . $access_shelf . '.txt';

my $line;				# For the current line in the txt file being read
my $fh_T1_edits;		# File handle for T0 DELETES

my $ERROR_FILE = 'TL1_ERROR_FILE_FOR_' . $access_shelf . '.txt';
my $fh_error; 	# File Handle for Any lines that do not match
open $fh_error, ">", $ERROR_FILE or die "Couldn't open $ERROR_FILE: $!\n";

# This is the read file - the source of all our info, etc:
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# These are the files to write to:
open $fh_T1_edits, ">", $T1_edits_file or die "Couldn't open $T1_edits_file: $!\n";

while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /T1MAP=/ ){
	
	# Increment that we have a possible match
	$possible_match++;
			
		
	 # Match on Description but no ATTENUATION.
	 #						$1					$2		$3			$4			$5			$6			$7		$8				$9			$10			$11		$12					$13				$14	
	 # "N5-1-5-2::						   TYPE=DS1,  T1MAP=NA,   EQLZ=300,  FMT=ESF,  LINECDE=B8ZS, GOS=OFF,  PYLDSCRM=N,    ATMMON=N,    EXT=Y,    PDOM=0,    NDS0RESVD=0,    TMGMODE=SOURCE,DESC=\"riverspan2\":IS-NR,"
     if ($line =~ m!(N\d+-\d+-\d+-\d+)::TYPE=(\w+),T1MAP=(\w+),EQLZ=(\d+),FMT=(\w+),LINECDE=(\w+),GOS=(\w+),PYLDSCRM=(\w+),ATMMON=(\w+),EXT=(\w+),PDOM=(\d+),NDS0RESVD=(\d+),TMGMODE=(\w+),DESC=\\"(.*)\\":!)
	 {		
			print {$fh_T1_edits}("ED-T1::$1:::::OOS;\n");
			print {$fh_T1_edits}("ED-T1::$1::::TYPE=$2,T1MAP=$3,EQLZ=$4,FMT=$5,LINECDE=$6,GOS=$7,PYLDSCRM=$8,ATMMON=$9,EXT=$10,PDOM=$11,NDS0RESVD=$12,TMGMODE=$13,DESC=$14;\n");
			print {$fh_T1_edits}("ED-T1::$1:::::IS;\n");
			$acted_on_match++;
	 }	 

	 # Match with AP= and DESC=
	 #						 $1				 $2			$3			$4		 $5			$6			$7			$8				$9			$10
	 #                    "N5-1-9-1::      TYPE=DS1,  T1MAP=SEQ,  EQLZ=300, FMT=ESF,  LINECDE=B8ZS, GOS=OFF,  TMGMODE=SOURCE,AP=N5-1-9-AP1,DESC=\"BOND SPAN1\":OOS-AUMA,SGEO" 
     elsif ($line =~ m!(N\d+-\d+-\d+-\d+)::TYPE=(\w+),T1MAP=(\w+),EQLZ=(\d),FMT=(\w+),LINECDE=(\w+),GOS=(\w+),TMGMODE=(\w+),AP=(.*),DESC=\\"(.*)\\":!)
	 {		
			print {$fh_T1_edits}("ED-T1::$1:::::OOS;\n");
			print {$fh_T1_edits}("ED-T1::$1::::TYPE=$2,T1MAP=$3,EQLZ=$4,FMT=$5,LINECDE=$6,GOS=$7,TMGMODE=$8,AP=$9,DESC=$10;\n");
			print {$fh_T1_edits}("ED-T1::$1:::::IS;\n");
			$acted_on_match++;
	 }
	 
	 
	 # Match on a T1 port w/o a description
	# 					  $1				$2		  $3			$4		$5			$6			$7			$8			$9			$10		$11				 $12
	# "N5-1-7-6::                       TYPE=DS1,  T1MAP=NA,   EQLZ=300,  FMT=ESF,  LINECDE=B8ZS, GOS=OFF,  PYLDSCRM=Y,    EXT=Y,    PDOM=0,    NDS0RESVD=0,    TMGMODE=SOURCE,:OOS-AUMA,FAF"
     elsif ($line =~ m!(N\d+-\d+-\d+-\d+)::TYPE=(\w+),T1MAP=(\w+),EQLZ=(\d+),FMT=(\w+),LINECDE=(\w+),GOS=(\w+),PYLDSCRM=(\w+),EXT=(\w+),PDOM=(\d+),NDS0RESVD=(\d+),TMGMODE=(\w+),!)
	 {		
			print {$fh_T1_edits}("ED-T1::$1:::::OOS;\n");
			print {$fh_T1_edits}("ED-T1::$1::::TYPE=$2,T1MAP=$3,EQLZ=$4,FMT=$5,LINECDE=$6,GOS=$7,PYLDSCRM=$8,EXT=$9,PDOM=$10,NDS0RESVD=$11,TMGMODE=$12;\n");
			print {$fh_T1_edits}("ED-T1::$1:::::IS;\n");
			$acted_on_match++;
	 }
	 # Match with Description Entered
	 # 						$1				  $2		 $3			  $4		$5		$6			$7			$8			$9			  $10			$11		$12			$13				$14				$15
	 # N5-1-5-1::                           TYPE=T1,   T1MAP=NA,   ATTEN=0.0,PWR=SINK, FMT=ESF,  LINECDE=B8ZS, GOS=OFF,  PYLDSCRM=N,    ATMMON=N,    EXT=Y,    PDOM=0,    NDS0RESVD=0,    TMGMODE=SOURCE,DESC=\"riverspan1\":OOS-MA,"

     elsif ($line =~ m!(N\d+-\d+-\d+-\d+)::TYPE=(\w+),T1MAP=(\w+),ATTEN=0.0,PWR=(\w+),FMT=(\w+),LINECDE=(\w+),GOS=(\w+),PYLDSCRM=(\w+),ATMMON=(\w+),EXT=(\w+),PDOM=(\d+),NDS0RESVD=(\d+),TMGMODE=(\w+),DESC=\\"(.*)\\":!)
	 {		
			print {$fh_T1_edits}("ED-T1::$1:::::OOS;\n");
			print {$fh_T1_edits}("ED-T1::$1::::TYPE=$2,T1MAP=$3,ATTEN=$4,PWR=$5,FMT=$6,LINECDE=$7,GOS=$8,PYLDSCRM=$9,ATMMON=$10,EXT=$11,PDOM=$12,NDS0RESVD=$13,TMGMODE=$14,DESC=$15;\n");
			print {$fh_T1_edits}("ED-T1::$1:::::IS;\n");
			$acted_on_match++;
	 }



 	 else
	 {
			print {$fh_error} ("Did not match on create: $line \n");
 	 } 	 
   }
}
close $fh_T1_edits;
close $fh_error;

print "===========================================================\n";
print "Results:\n";
print "Possible matches found in source file for T1 port edit:\t$possible_match\n";
print "Total T1 ports written to the edit file :\t$acted_on_match\n";
print "===========================================================\n";






