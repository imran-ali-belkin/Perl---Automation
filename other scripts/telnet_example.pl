use strict;
use warnings;
use Net::Telnet;

my $t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs.txt' );

  #C7 IP/Hostname to open, change this to the one you want.
$t->open('tactrn01');

  #Wait for prompt to appear;
$t->waitfor('/>/ms');

  #Send default username/password (Not using cracker here)
$t->send('ACT-USER::c7support:::c7support;');

  #The actual return prompt is a semicolon at the end of the output, so wait for this
$t->waitfor('/^;/ms');

$t->send('RTRV-CRS-T0::N1-1-IG1-ALL;');

$t->waitfor('/^;/ms');

# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->prompt('/^;/ms');

  #Now it will automatically send/waitfor with cmd command
$t->cmd('inh-msg-all;');
$t->cmd('inh-msg-all;');

  #Logout
$t->send('CANC-USER;');

$t->close;


# Jason's additions
my $DATA_FILE = 'tl1_logs.txt';
my $DESTINATION_FILE = 'the_creates.txt';
my $DESTINATION_FILE_2 = 'the_deletes.txt';
my $line;
my $fh2;		# CREATES
my $fh3;		# DELETES

# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# This is the write file
open $fh2, ">", $DESTINATION_FILE or die "Couldn't open $DATA_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /IG/ ){
     # This is the logic for Combo ports:
     if ($line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+)! || $line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+)! ){
		print {$fh2} ("ENT-CRS-T0::$1,$2;\n"); 
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

  if ($line =~ /IG/ ){
     # This is the logic for Combo ports:
     if ($line =~ m!(N\d+-\d+-IG\d+-\d+),(N\d+-\d+-\d+-\d+)!){
		print {$fh3} ("DLT-CRS-T0::$1,$2;\n"); 
	 }
         
 	
   }
  
}
close $fh3;
close $fh;






