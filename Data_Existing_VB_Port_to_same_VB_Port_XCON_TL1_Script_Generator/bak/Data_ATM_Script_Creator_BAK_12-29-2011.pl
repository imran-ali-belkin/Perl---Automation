use strict;
use warnings;
use Net::Telnet;

print "================================\n";
print "The C7 Data ATM  Script Creator\n";
print "================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls ATM data cross-connect data\n";
print "2: Creates a text file that has all of the CREATES\n";
print "3: Creates a text file that has all of the DELETES\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES or DELETES and use in your TL1\n"; 
print "scripts.\n";
print "=======================================\n";

print "Please enter either the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $destination_c7 = <STDIN>;
chomp($destination_c7);

print "Enter the username:\n";
print ">";
my $user_name = <STDIN>;
chomp($user_name);

print "Enter the password:\n";
print ">";
my $user_password = <STDIN>;
chomp($user_password);

print "Enter the ATM Uplink Facility:\n";
print "Make sure to get this correct or else I will not be able to retrieve on the ATM uplink\n";
print "For example, if the uplink is an OC3 ATM Uplink do N1-1-10-1-1:\n";
print "                                          NODE-SHELF-SLOT-PORT#-STS#\n";
print "\n";
print "For example, if the uplink is a DS3 ATM Uplink do N1-1-10-1:\n";
print "                                          NODE-SHELF-SLOT-PORT#\n";
print ">";
my $user_data_uplink = <STDIN>;
chomp($user_data_uplink);



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
$t->send($user_password);
$t->send(";");

#The actual return prompt is a semicolon at the end of the output, so wait for this
$t->waitfor('/^;/ms');
print "=============================\n";
print "We are logged in successfully\n";
print "=============================\n";

# Inhibit Message All
$t->send("INH-MSG-ALL;");
$t->waitfor('/^;/ms');


$t->send("RTRV-CRS-VC::$user_data_uplink-all::::scope=ntwk;");
print "=============================\n";
print "I am retrieving all of the ATM data cross-connects on $user_data_uplink \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the cross-connects\n";
print "======================================\n";
  
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
my $DESTINATION_FILE = 'CREATES_FOR_' . $user_data_uplink . '.txt';
my $DESTINATION_FILE_2 = 'DELETES_FOR_' . $user_data_uplink . '.txt';
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

  	if ( $line =~ m!PATH=PROT!) {
		next;
	}
    elsif ($line =~ /VP/ ){
		# $1 will be the uplink
		# $2 will be the access port
		# $3 will be the TRFPROF
		# $4 will be the BCKPROF
		# $5 will be the PATH
		# $6 will be the BWC
		#  "N1-1-2-2-1-VP100-VC223,N1-1-12-1-1-VP4095-VC84:2WAY:KEY=N1-1-2-2-1-VP100-VC223,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CONSTAT=NORMAL,"
		
		# Here is the Bandwidth Constraint logic:
		if ( $line =~ m!BWC=\d+,!){
				#DS3 oriented ATM uplink with DSL access with a BWC:
				if ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! ){
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=BOTH,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
				}

				#DS3 oriented ATM uplink with ONT access with a BWC:
				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! ){
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=BOTH,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
				}		

				#OC oriented ATM uplink with DLS access with a BWC:
				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! ){
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=BOTH,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
				}
				
				#OC oriented ATM uplink with ONT access with a BWC:
				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! ){
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=BOTH,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
				}		
 		}
		# End of Bandwidth Constraint logic
		
		else {
				#DS3 oriented ATM uplink with DSL access:
				if ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=BOTH,TRFPROF=$3,BCKPROF=$4;\n"); 
				}

				#DS3 oriented ATM uplink with ONT access:
				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=BOTH,TRFPROF=$3,BCKPROF=$4;\n"); 
				}		

				#OC oriented ATM uplink with DLS access:
				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=BOTH,TRFPROF=$3,BCKPROF=$4;\n"); 
				}
				
				#OC oriented ATM uplink with ONT access:
				elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=BOTH,TRFPROF=$3,BCKPROF=$4;\n"); 
				}		
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

    if ( $line =~ m!PATH=PROT!) {
		next;
	}
	elsif ($line =~ /VP/ ){			
			# $1 will be the uplink
			# $2 will be the access port
			# $3 will be the TRFPROF
			# $4 will be the BCKPROF
			# $5 will be the PATH

			my $new_path ;
			#DS3 oriented ATM uplink with DSL access:
			if ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 
			}
			#DS3 oriented ATM uplink with ONT access:
			elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$5 = 'BOTH';
				}				
			print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$5;\n"); 
			}		
			
			#OC oriented ATM uplink with DSL access:
			elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 
			}
			#OC oriented ATM uplink with ONT access:
			elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$5 = 'BOTH';
				}				
			print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$5;\n"); 
			}		
 	}	 	 
}
close $fh3;
close $fh;






