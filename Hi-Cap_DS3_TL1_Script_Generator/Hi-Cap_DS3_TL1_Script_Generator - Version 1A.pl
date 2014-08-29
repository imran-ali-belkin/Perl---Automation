use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# Counters to keep track of total cross-connect create and deletes

my $counter_total_creates = 0;
my $counter_total_creates_bwc = 0;
my $counter_total_deletes = 0;

print "\n\n\n\n\n\n";
print "========================================================\n";
print "The C7 DS3 Hi-Cap Script Creator\n";
print "========================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls DS3 Hi-Cap cross-connect data\n";
print "2: Creates a text file that has all of the CREATES\n";
print "3: Creates a text file that has all of the DELETES\n";
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
  
print "\n\n";
print "========================================================\n";
print "Enter the Node and Shelf of the DS3 hi-caps\n";
print "you want me to pull (for example N1-1) :\n";
print ">";
my $user_shelf = <STDIN>;
chomp($user_shelf);


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

# DS3 STS1 Hi-Cap Script Creator Specific Logic
print "=============================\n";
print "I am retrieving all of the DS3 Hi-Cap cross-connects on $user_shelf \n";  
print "Please be patient.\n";
print "=============================\n";
$t->timeout(undef);
$t->send("RTRV-CRS-STS1::$user_shelf-all::::scope=ntwk;");
$t->waitfor('/^;/ms');


$t->timeout(30);

print "======================================\n";
print "OK, done retrieving the cross-connects\n";
print "======================================\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

 
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
my $DESTINATION_FILE = 'DS3_CREATES_FOR_' . $user_shelf . '.txt';
my $DESTINATION_FILE_2 = 'DS3_DELETES_FOR_' . $user_shelf . '.txt';
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

		  # We want to discard the redundant if there is a WKG and PROT path cross-connect
		  if ($line =~ /PATH=PROT/ ) {
				next;
		  }

		  # BWCs used with DS3 STS1 Hi-Cap hi-caps
		  if ($line =~ (/BWC=/) ){
			  # Logic to match on DS3 STS1 Hi-Cap to DS3 STS1 Hi-Cap. or on DS3 STS1 Hi-Cap to ONT, or ONT to ONT, or ONT to DS3 STS1 Hi-Cap
			 if (
					$line =~ m!((N\d+-\d+)-\d+-\d+-\d+-\d+),((N\d+-\d+)-\d+-\d+-\d+-\d+).*BWC=(\d+).*! ||
					$line =~ m!((N\d+-\d+)-\d+-\d+-\d+-\d+),((N\d+-\d+)-\d+-\d+).*BWC=(\d+).*! ||
					$line =~ m!((N\d+-\d+)-\d+-\d+),((N\d+-\d+)-\d+-\d+-\d+-\d+).*BWC=(\d+).*! || 
					$line =~ m!((N\d+-\d+)-\d+-\d+),((N\d+-\d+)-\d+-\d+).*BWC=(\d+).*! 

					# $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+).*BWC=(\d+).*! ||
					# $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+).*BWC=(\d+).*! ||
					# $line =~ m!(N\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+).*BWC=(\d+).*! || 
					# $line =~ m!(N\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+).*BWC=(\d+).*! 
				)
				{
 
					if ( $2 eq $4 )
					{
						print {$fh2} ("ENT-CRS-STS1::$1,$3::::PATH=UNPROT,BWC=$5;\n");
					}
					else 
					{
						print {$fh2} ("ENT-CRS-STS1::$1,$3::::PATH=BOTH,BWC=$5;\n"); 
					}
					$counter_total_creates_bwc++ ;
				}
		  }

		  # Pure DS3 STS1 Hi-Cap - no BWCs
		  elsif ($line =~ /PATH=WKG/ || $line =~ /PATH=UNPROT/ ){
			  # Logic to match on DS3 STS1 Hi-Cap to DS3 STS1 Hi-Cap. or on DS3 STS1 Hi-Cap to ONT, or ONT to ONT, or ONT to DS3 STS1 Hi-Cap
				 if (
					$line =~ m!((N\d+-\d+)-\d+-\d+-\d+-\d+),((N\d+-\d+)-\d+-\d+-\d+-\d+)! ||
					$line =~ m!((N\d+-\d+)-\d+-\d+-\d+-\d+),((N\d+-\d+)-\d+-\d+)! ||
					$line =~ m!((N\d+-\d+)-\d+-\d+),((N\d+-\d+)-\d+-\d+-\d+-\d+)! || 
					$line =~ m!((N\d+-\d+)-\d+-\d+),((N\d+-\d+)-\d+-\d+)! 

					# $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+)! ||
					# $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+)! ||
					# $line =~ m!(N\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+)! || 
					# $line =~ m!(N\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+)! 
				    )			
					{

						if ( $2 eq $4 )
						{
							print {$fh2} ("ENT-CRS-STS1::$1,$3::::PATH=UNPROT;\n");
						}
						else 
						{
							print {$fh2} ("ENT-CRS-STS1::$1,$3::::PATH=BOTH;\n");
						}
						$counter_total_creates++;
					}
		   }

		   
} # end of the big while loop
close $fh2;
close $fh;


open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh3, ">", $DESTINATION_FILE_2 or die "Couldn't open $DATA_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /PATH=PROT/) {
	next;
  }
	
  if ($line =~ /PATH=WKG/ || $line =~ /PATH=UNPROT/ ){

	  # Logic to match on DS3 STS1 Hi-Cap to DS3 STS1 Hi-Cap. or on DS3 STS1 Hi-Cap to ONT
     if (
			$line =~ m!(N\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+)! || 
			$line =~ m!(N\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+)! || 
			$line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+)! ||
			$line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+),(N\d+-\d+-\d+-\d+)! )
     {
			print {$fh3} ("DLT-CRS-STS1::$1,$2;\n"); 
		$counter_total_deletes++;
	 }	
   }
}
close $fh3;
close $fh;


print "===================================================\n";
print "Results:\n";
print "Total delete cross-connects: $counter_total_deletes \n";
print "\n";
print "Total create cross-connects: $counter_total_creates \n";
print "Total create cross-connects w/ BWCs: $counter_total_creates_bwc \n";
print "===================================================\n\n";






