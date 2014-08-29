use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

################################################################################################
#
# This script is useful on 7.0 and greater systems where you want to get old school.
#
# It retrieves the existing VB port to access cross-connect and then creates a new cross-connect
# The retrieve is done at the shelf level
#
# It does build a deletes file which simply deletes the cross-connect of the existing VB port to
# access port
# It does build a creates file which uses the original VB port 
#
# So, you will probably use this in scenarios where you are pinning the VB ports.
#
################################################################################################


# These are counters which keep track of how many cross-connects we create by access subscriber type
my $counter_DSL_classic_creates = 0;
my $counter_ONT_classic_creates = 0;
my $counter_IMA_creates = 0;
my $counter_IMA_GRP_AP_creates = 0;
my $counter_DSL_GRP_creates = 0;
my $counter_DS3_downlink_creates = 0;
my $counter_OC_downlink_creates = 0;

my $counter_cross_connects_found = 0;
my $counter_cross_connects_created = 0;
my $counter_cross_connects_deleted = 0;


################################################################################################
#
# Getting user input
#
# 1. Asks you the system IP address
# 2. Enter the card location using Node-Shelf-Slot notation
# 3. Enter the future Virtual Bridge
# 4. Enter the future VB port starting point (then will increment by 1)
#
################################################################################################

print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The C7 VB Port to Access port XCON TL1 Script Generator\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls the VB port to Access port ATM data cross-connect\n";
print "2: Creates a text file that has all of the DELETES\n";
print "   The deletes will have the syntax to delete the existing cross-connect.\n";
print "3: Creates a text file that has all of the CREATES\n";
print "   The creates will have the syntax to build a new cross-connect to a \n";
print "   from the VB port to the access port\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES or DELETES and use in your TL1\n"; 
print "scripts.\n";
print "==========================================================================\n";

print "\n\n";
print "==========================================================================\n";
print "Please enter either the IP address or hostname of the C7 you want to reach:\n";
print ">";
my $destination_c7 = <STDIN>;
chomp($destination_c7);

my $user_name = 'c7support';

print "\n\n";
print "==========================================================================\n"; 
print "Enter the Access Shelf:\n";
print "\n";
print "Make sure to get this correct or else I will not be able to retrieve properly\n";
print "For example, if the access cards are in N2-1 then enter N2-1:\n";
print "                                          NODE-SHELF\n";
print "\n";
print ">";
my $user_data_uplink = <STDIN>;
chomp($user_data_uplink);


################################################################################################
#
# Telnet stuff
#
################################################################################################
my $shell = C7::Cmd->new($destination_c7, 23);
$shell->connect;
my ($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
my $password = $shell->computeForgottenPassword( $date, $sid );


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
$t->send("RTRV-CRS-VC::$user_data_uplink-all::::scope=ntwk;");
print "=============================\n";
print "I am retrieving all of the ATM data cross-connects on $user_data_uplink \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the cross-connects\n";
print "======================================\n";

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
my $DESTINATION_FILE = 'CREATES_VBPort_to_Access_FOR_' . $user_data_uplink . '.txt';
my $DESTINATION_FILE_2 = 'DELETES_VBPort_to_Access_FOR_' . $user_data_uplink . '.txt';
my $ERROR_FILE = 'TL1_ERROR_VBPort_to_Access_LOG_FOR_' . $user_data_uplink . '.txt';

my $line;
my $fh2;		# CREATES
my $fh3;		# DELETES
 
my $path_info = 'BOTH';


####################################################################################
#
# CREATES LOGIC
#
####################################################################################

open my $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";

# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# This is the write file
open $fh2, ">", $DESTINATION_FILE or die "Couldn't open $DATA_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);

  	if ( ( $line =~ m!PATH=PROT! ) || ( $line =~ m!TSI! ) ) {
		next;
	}
    elsif ($line =~ /TRFPROF/ ){
	   $counter_cross_connects_found++;
	   
 		# $1 will be the access port
		# $2 will be the TRFPROF
		# $3 will be the BCKPROF
		# $4 will be the PATH
		# $5 will be the BWC
		#  "N1-1-2-2-1-VP100-VC223,N1-1-12-1-1-VP4095-VC84:2WAY:KEY=N1-1-2-2-1-VP100-VC223,TRFPROF=UBR,BCKPROF=UBR,PATH=UNPROT,CONSTAT=NORMAL,"
		
		# Functionality to add as of 12-29-2011:																			COMPLETED?		TESTED?		TESTED BWC?
		# DSL classic access:																								Yes				Yes			Yes
		# ONT classic access:																								Yes				Yes			Yes
		# Some sort of DS3 packet downlink 				N{1-255}-{1-5}-{1-20}-{1-6}-VP{0-4095}-VC{32-65535}					Yes				Yes			Yes		
		# Some type of dowlink with STS:				N{1-255}-{1-5}-{1-20}-{1-4}-{1-48}-VP{0-4095}-VC{20,32-65535}		Yes				
		# IMA Group:									N{1-255}-{1-5}-{1-20}-IMA{1-16}-VP{0-4095}-VC{32-65535}				Yes				Yes			Yes
		# IMA Group with AP Port:						N{1-255}-{1-5}-{1-20}-AP{1-16}-VP{0-4095}-VC{32-65535}				Yes
		# DSL Group 									N{1-255}-{1-5}-{1-20}-GRP{1-12}-VP{0-255}-VC{32-65535}				Yes

		# VDSL Packet									N{1-255}-{1-5}-{1-20}-{1-24}-EP{1-7960}								Hmm...
		# VDSL Group									N{1-255}-{1-5}-{1-20}-GRP{1-24}-EP{1-7960}							Hmm...


		
 				
		# Here is the Bandwidth Constraint logic:
		if ( $line =~ m!BWC=\d+,!)
		{
				# VB port to DSL access with a BWC:
				if ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! )
				{
					
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n");
					$counter_DSL_classic_creates++;					
					$counter_cross_connects_created++;					
				}
				# VB port to ONT access with a BWC:
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}


					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
					$counter_ONT_classic_creates++;
					$counter_cross_connects_created++;
				}		
  				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-IMA\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! )
				{

					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}

					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
					$counter_IMA_creates++;
					$counter_cross_connects_created++;
				}
				# IMA AP access with a BWC:
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-AP\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
					$counter_IMA_GRP_AP_creates++;
					$counter_cross_connects_created++;
				}
				# DSL GRP access with a BWC:
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ( $5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}

					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
					$counter_DSL_GRP_creates++;
					$counter_cross_connects_created++;
				}
				# Packet access (DS3 Port) with a BWC:
 				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}


					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
					$counter_DS3_downlink_creates++;
					$counter_cross_connects_created++;
				}
				# Packet access (OC Port) with a BWC:
 				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),.*BWC=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ( $5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}

					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4,BWC=$6;\n"); 
					$counter_OC_downlink_creates++;
					$counter_cross_connects_created++;
				}
				else
				{
					print {$fh_error} ("No match on create for: " . $line . "\n");
				}

 		}
		# End of Bandwidth Constraint logic
		
		else {
				# DSL access:
				if ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4;\n"); 
					$counter_DSL_classic_creates++;					
					$counter_cross_connects_created++;
				}
				
				# ONT access:
				# "N4-1-VB1-35,N4-2-17-1-5-3-1:2WAY:KEY=N4-1-VB1-35,TRFPROF=5,BCKPROF=6,PATH=PROT,PC=BR,CONSTAT=NORMAL,"
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),!)
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4;\n"); 
					$counter_ONT_classic_creates++;
					$counter_cross_connects_created++;
				}		
				# IMA access:
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-IMA\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4;\n"); 
					$counter_IMA_creates++;
					$counter_cross_connects_created++;
				}
				# IMA AP access:
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-AP\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4;\n"); 
					$counter_IMA_GRP_AP_creates++;
					$counter_cross_connects_created++;
				}
				# DSL GRP access:
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4;\n"); 
					$counter_DSL_GRP_creates++;
					$counter_cross_connects_created++;
				}
				# DS3 Packet access:
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4;\n"); 
					$counter_DS3_downlink_creates++;
					$counter_cross_connects_created++;
				}
				# OC Packet access:
				elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! )
				{
					if ( $5 eq 'WKG'){
						$path_info = 'BOTH';
					}
					elsif ($5 eq 'UNPROT' ){
						$path_info = 'UNPROT';
					}
					print {$fh2} ("ENT-CRS-VC::$1,$2::::PATH=$path_info,TRFPROF=$3,BCKPROF=$4;\n"); 
					$counter_OC_downlink_creates++;
					$counter_cross_connects_created++;
				}		
				else
				{
					print {$fh_error} ("No match on create for: " . $line . "\n");
				}
				
		}
   }
}
close $fh2;
close $fh;



####################################################################################
#
# DELETES LOGIC
#  				This logic for 3-27-2012 is completed
# 
####################################################################################

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh3, ">", $DESTINATION_FILE_2 or die "Couldn't open $DATA_FILE: $!\n";
while ($line = <$fh> )
{
  chomp($line);

  	if ( ( $line =~ m!PATH=PROT! ) || ( $line =~ m!TSI! ) ) {
		next;
	}
	elsif ($line =~ /TRFPROF/ ){			
			# $1 will be the uplink
			# $2 will be the access port
			# $3 will be the TRFPROF
			# $4 will be the BCKPROF
			# $5 will be the PATH

			my $new_path ;
			# VB port with DSL access:
			if ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 
				$counter_cross_connects_deleted++;
 			}
			# VB port with ONT access:
			elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-\d+-\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}				
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 				
				$counter_cross_connects_deleted++;
			}		
			# VB port with IMA access:
			elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-IMA\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 
				$counter_cross_connects_deleted++;
			}
			# VB port with IMA AP access:
			elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-AP\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 
				$counter_cross_connects_deleted++;
			}
			# VB port with DSL GRP access:
			elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-GRP\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 
				$counter_cross_connects_deleted++;
			}
			# VB port with Packet DS3 access:
			elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 
				$counter_cross_connects_deleted++;
			}
			# VB port with Packet OC access:
			elsif ( $line =~ m!(N\d+-\d+-VB\d+-\d+),(N\d+-\d+-\d+-\d+-\d+-VP\d+-VC\d+):.*TRFPROF=(\w+),.*BCKPROF=(\w+),.*PATH=(\w+),! ){
				if ( $5 eq 'WKG') {
					$new_path = 'BOTH';
				}
				else {
					$new_path = $5;
				}
				print {$fh3} ("DLT-CRS-VC::$1,$2::::PATH=$new_path;\n"); 
				$counter_cross_connects_deleted++;
			}
			else
			{
					print {$fh_error} ("No match on delete for: " . $line . "\n");
			}
 	}	 	 
}
close $fh3;
close $fh;
close $fh_error;

print "==========================================================\n";
print "Totals \n";
print "==========================================================\n";

print "Total cross-connects found in TL1 retrieval file:\t " . $counter_cross_connects_found . "\n";
print "Total cross-connects written to TL1 CREATES file:\t " . $counter_cross_connects_created . "\n";
print "Total cross-connects written to TL1 DELETES file:\t " . $counter_cross_connects_deleted . "\n\n";

print "Specifics by cross-connect type:\n";
print "DSL cross-connects created in text file:\t\t" . $counter_DSL_classic_creates . "\n";
print "ONT cross-connects created in text file:\t\t" . $counter_ONT_classic_creates . "\n";
print "IMA cross-connects created in text file:\t\t" . $counter_IMA_creates . "\n";
print "IMA AP cross-connects created in text file:\t\t" . $counter_IMA_GRP_AP_creates . "\n";
print "DSL Group cross-connects created in text file:\t\t" . $counter_DSL_GRP_creates . "\n";
print "DS3 Downlink cross-connects created in text file:\t" . $counter_DS3_downlink_creates . "\n";
print "OC Downlink cross-connects created in text file:\t" . $counter_OC_downlink_creates . "\n";

print "\n";
 



