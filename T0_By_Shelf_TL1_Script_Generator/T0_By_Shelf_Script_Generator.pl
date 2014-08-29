use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# Counters to keep track of total cross-connect create and deletes

my $counter_total_creates = 0;
my $counter_total_deletes = 0;

my $possible_match_for_a_create = 0;
my $possible_match_for_a_delete = 0;
 
print "\n\n\n\n\n\n";
print "=================================================================\n";
print "The C7 T0 By Shelf Script Creator\n";
print "=================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls T0 cross-connect data \n";
print "2: Creates a text file that has all of the CREATES\n";
print "3: Creates a text file that has all of the DELETES\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES or DELETES and use in your TL1\n"; 
print "scripts.\n";
print "=================================================================\n";

print "\n\n";
print "=================================================================\n";
print "Please enter either the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $ip = <STDIN>;
chomp($ip);

my $user_name = 'c7support';
 
print "\n\n";
print "=================================================================\n";
print "Enter the shelf you want me to retrieve on (for example N1-1 or N2-1) :\n";
print ">";
my $user_IG = <STDIN>;
chomp($user_IG);


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
$t->send("RTRV-CRS-T0::$user_IG-ALL;");
print "=============================\n";
print "I am retrieving all of the T0 cross-connects on $user_IG \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the cross-connects\n";
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
my $DESTINATION_FILE = 'CREATES_FOR_' . $user_IG . '.txt';
my $DESTINATION_FILE_2 = 'DELETES_FOR_' . $user_IG . '.txt';
my $line;
my $fh2;		# File handle for CREATES
my $fh3;		# File handle for DELETES

my $ERROR_FILE = 'TL1_ERROR_FILE_FOR_' . $user_IG . '.txt';
my $fh_error; 	# File Handle for Any lines that do not match
open my $fh_error, ">", $ERROR_FILE or die "Couldn't open $ERROR_FILE: $!\n";

# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# This is the write file
open $fh2, ">", $DESTINATION_FILE or die "Couldn't open $DESTINATION_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /NSG=/ ){
		$possible_match_for_a_create++;
		
	  # Logic to match on ONT or DSL 
     if ($line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+)! || $line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+)!){
			print {$fh2} ("ENT-CRS-T0::$1,$2;\n"); 
			$counter_total_creates++;
	 }
 	 else
	 {
			print {$fh_error} ("Did not match on create: $line \n");
 	 } 
	 
   }
}
close $fh2;
close $fh;


open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh3, ">", $DESTINATION_FILE_2 or die "Couldn't open $DATA_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /NSG=/ ){
	  $possible_match_for_a_delete++;

	  # Logic to match on ONT or DSL 
      if ($line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+)! || $line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+)!){
			print {$fh3} ("DLT-CRS-T0::$1,$2;\n"); 
			$counter_total_deletes++;
	 }	
 	 else
	 {
			print {$fh_error} ("Did not match on delete: $line \n");
	 }

   }
}
close $fh3;
close $fh;
close $fh_error;

print "===========================================================\n";
print "Results:\n";
print "XCONS found in source file for create:\t$possible_match_for_a_create\n";
print "XCONS found in source file for deletes:\t$possible_match_for_a_delete\n";
print "Total delete cross-connects:\t $counter_total_deletes \n";
print "Total create cross-connects:\t $counter_total_creates \n";
print "===========================================================\n";






