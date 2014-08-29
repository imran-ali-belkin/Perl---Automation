use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

################################################################################################
#
# This script is useful the CLINK Project where maintaining the same VB port is used to identify
# customers
#
# It retrieves all existing VB ports, VLANVB and CVIDREG ports for a user specified Virtual Bridge
# 
# Note this script assumes a 7.0 or greater system
################################################################################################


################################################################################################
# 
# Counters Section
# These are counters which keep track of how many cross-connects we create by access subscriber type
#
my $errors = 0;

my $vbports_found = 0;
my $vbports_created = 0;

my $vlanvbports_found = 0;
my $vlanvbports_created = 0;

my $cvidreg_found = 0;
my $cvidreg_created = 0;
#
#
################################################################################################


 
################################################################################################
#
# Getting user input
#
# 1. Asks you the system IP address
# 2. Enter the existing Virtual Bridge
# 3. Ask the VLAN
#
#
#
print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The C7 Data Construct TL1 Script Generator\n";
print "         Version 1 - July 18, 2013\n";
print "          Written by Jason Murphy\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls all VB, VLANVB and CVIDREG info against a VB\n";
print "2: Creates a text file that has all the VB port Creates\n";
print "3: Creates a text file that has all the VLANVB port Creates\n";
print "4: Creates a text file that has all the CVIDREG Creates\n";
print "\n\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "Note that this script assumes a 7.0 or greater system\n";
print "You can copy the text file TL1 commands and use in your TL1\n"; 
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
print "Enter the Virtual Bridge you want me to pull against:\n";
print "\n";
print "Make sure to get this correct or else I will not be able to retrieve properly\n";
print "For example if the Virtual Bridge is N100-4-VB1 then enter N100-4-VB1 and hit enter:\n";
print "                                          NODE-SHELF-VB#\n";
print "\n";
print ">";
my $user_data_uplink = <STDIN>;
chomp($user_data_uplink);


print "\n\n";
print "==========================================================================\n"; 
print "Enter the VLAN you want me to pull against:\n";
print "\n";
print "Make sure to get this correct or else I will not be able to retrieve properly\n";
print "For example if the VLAN is 1048 then simply enter 1048 and hit enter:\n";
print "\n";
print ">";
my $user_data_uplink_VLAN = <STDIN>;
chomp($user_data_uplink_VLAN);
#
#
################################################################################################


################################################################################################
#
# Telnet Cracker stuff
#
################################################################################################
my $shell = C7::Cmd->new($destination_c7, 23);
$shell->connect;
my ($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
my $password = $shell->computeForgottenPassword( $date, $sid );

#################################################################################################
#
# Telnet to retrieve all VB ports
# 
#################################################################################################
my $t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_vb_ports.txt' );

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
$t->send("RTRV-VBPORT::$user_data_uplink-all;");
print "=============================\n";
print "I am retrieving all of the VB ports on $user_data_uplink \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the VB ports\n";
print "======================================\n";

$t->timeout(30);
  
#Logout
$t->send('CANC-USER;');
$t->close;

print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and create two separate files - a CREATES file and a DELETES file\n";
print "=====================================================\n";
#
#
#################################################################################################




################################################################################################
#
# Telnet Cracker stuff
#
################################################################################################
$shell = C7::Cmd->new($destination_c7, 23);
$shell->connect;
($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
$password = $shell->computeForgottenPassword( $date, $sid );

#################################################################################################
#
# Telnet to retrieve all VLANVB ports
# 
#################################################################################################
$t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_vlanvb_ports.txt' );

# C7 IP/Hostname to open, change this to the one you want.
$t->open($destination_c7);

# Wait for prompt to appear;
$t->waitfor('/>/ms');

print "========================\n";
print "Logging in to the system\n";
print "========================\n";
    
# Send default username/password (Not using cracker here)
$t->send("ACT-USER::");
$t->send($user_name);
$t->send(":::");
$t->send($password);
$t->send(";");

# The actual return prompt is a semicolon at the end of the output, so wait for this
$t->waitfor('/^;/ms');
print "=============================\n";
print "We are logged in successfully\n";
print "=============================\n";

# Inhibit Message All
$t->send("INH-MSG-ALL;");
$t->waitfor('/^;/ms');

$t->timeout(undef);
$t->send("RTRV-VLAN-VBPORT::" . $user_data_uplink . "-ALL::::VLAN=" . $user_data_uplink . "-VLAN" . $user_data_uplink_VLAN . ";");
print "=============================\n";
print "I am retrieving all of the VLAN VB ports on VB: $user_data_uplink VLAN: $user_data_uplink_VLAN\n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the VLANVB ports\n";
print "======================================\n";

$t->timeout(30);
  
# Logout
$t->send('CANC-USER;');
$t->close;

print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and create two separate files - a CREATES file and a DELETES file\n";
print "=====================================================\n";
#
#
#################################################################################################


#################################################################################################
#
# File Handle Stuff to pull the VB ports out of the tl1_logs_vb_ports.txt and then use 
# for retrieving the CVIDREG
# 
#
my $PRELIM_DATA_FILE_VB_PORTS = 'tl1_logs_vb_ports.txt';
open my $fh_source_vb_ports, '<', $PRELIM_DATA_FILE_VB_PORTS or die "Could not open $PRELIM_DATA_FILE_VB_PORTS: $!\n";

# Edits VB port file stuff
my $SOURCE_VB_PORTS_FILE = 'VBPORTS_SOURCE.txt';
my $fh_EDITS_VB_PORTS_DESTINATION;			# EDITS File Handle
open $fh_EDITS_VB_PORTS_DESTINATION, ">", $SOURCE_VB_PORTS_FILE or die "Couldn't open $SOURCE_VB_PORTS_FILE: $!\n";

# Error file stuff
my $fh_error_VBPORTS;
my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_data_uplink . '.txt';
open $fh_error_VBPORTS, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";

my $line;

while ($line = <$fh_source_vb_ports> )
{
  chomp($line); 				
			# This is a VB port retrieval
			# "N4-4-VB1-3399::VLAN=N100-4-VB1-VLAN1048,ARP=N,DHCPDIR=NONE,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=1048,"
			if ( $line =~ m!(N\d+-\d+-VB\d+-\d+)::!)
			{					
				print {$fh_EDITS_VB_PORTS_DESTINATION} ("$1\n");
			}
			else
			{
				print {$fh_error_VBPORTS} ("No match on VB port for: " . $line . "\n");
			}
}
close $fh_EDITS_VB_PORTS_DESTINATION;
close $fh_source_vb_ports;
close $fh_error_VBPORTS;
#
# 
#
#
#################################################################################################




################################################################################################
#
# Telnet Cracker stuff
#
################################################################################################
my $new_shell = C7::Cmd->new($destination_c7, 23);
$new_shell->connect;
my ($new_date, $new_sid) = $new_shell->_getDateAndSid() ;
$new_shell->disconnect;
my $new_password = $new_shell->computeForgottenPassword( $new_date, $new_sid );

#################################################################################################
#
# Telnet to C7 and retrieve all CVIDREG ports - open the VB ports file and do a while loop to
# loop through them
# 

# Note that SOURCE2 is for testing purposes
# my $SOURCE_CVID_REG = 'VBPORTS_SOURCE2.txt';

my $SOURCE_CVID_REG = 'VBPORTS_SOURCE.txt';
open my $fh_CVID, '<', $SOURCE_CVID_REG or die "Could not open $SOURCE_CVID_REG: $!\n";

my $PER_VB_PORT;

my $j = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_CVIDREG_ports.txt' );

#C7 IP/Hostname to open, change this to the one you want.
$j->open($destination_c7);

#Wait for prompt to appear;
$j->waitfor('/>/ms');

print "========================\n";
print "Logging in to the system\n";
print "========================\n";
    
#Send default username/password (Not using cracker here)
$j->send("ACT-USER::");
$j->send($user_name);
$j->send(":::");
$j->send($new_password);
$j->send(";");

#The actual return prompt is a semicolon at the end of the output, so wait for this
$j->waitfor('/^;/ms');

# Inhibit Message All
$j->send("INH-MSG-ALL;");
$j->waitfor('/^;/ms');

$j->timeout(undef);

print "=============================\n";
print "I am retrieving all of the CVIDREG ports on each VB PORT: $user_data_uplink VLAN: $user_data_uplink_VLAN\n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";


# Loop through the lines here and retrieve against all VB ports
while ($line = <$fh_CVID> )
{
		chomp($line); 			

		if ($line eq ""){
			last;
		}
		else{
			$j->send("RTRV-CVIDREG::" . $line . "-ALL;");
			$j->waitfor('/^;/ms');
		}
}

# $j->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the CVIDREG ports\n";
print "======================================\n";

$j->timeout(30);
  
#Logout
$j->send('CANC-USER;');
$j->close;

print "=====================================================\n";
print "Done\n";
print "=====================================================\n";

close $fh_CVID;
#
#
#################################################################################################

















#################################################################################################
#
# Part A.1 File Handle Stuff for - tl1_logs_vb_ports.txt			
#
# 
my $DATA_FILE_VB_PORTS = 'tl1_logs_vb_ports.txt';
open $fh_source_vb_ports, '<', $DATA_FILE_VB_PORTS or die "Could not open $DATA_FILE_VB_PORTS: $!\n";
 
# Edits VB port file stuff
my $EDITS_VB_PORTS_FILE = 'CREATES_VB_PORTS_FOR_' . $user_data_uplink . '.txt';
my $fh_EDITS_VB_PORTS;			# EDITS File Handle
open $fh_EDITS_VB_PORTS, ">", $EDITS_VB_PORTS_FILE or die "Couldn't open $EDITS_VB_PORTS_FILE: $!\n";

# Error file stuff
my $fh_error;
$ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_data_uplink . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";
#
#
#################################################################################################
 

####################################################################################
#
# Part A.2 LOGIC For VB PORTS - the CREATES file
#
#
while ($line = <$fh_source_vb_ports> )
{
  chomp($line); 				
  		if ( $line =~ m!ENCAP=!)
		{
				$vbports_found++;
		
 				# This is a VB port retrieval
				# "N100-4-VB1-3400::ENCAP=ETHERNETV2,DOS=Y,STP=OFF,DIRN=BOTH,STPCOST=100,STPPRO=128,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,PINNED=Y"				
				
 				if ( $line =~ m!(N\d+-\d+-VB\d+-\d+)::ENCAP=ETHERNETV2,DOS=([Y|N]),STP=OFF,DIRN=(\w+),STPCOST=100,STPPRIO=\d+,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,PINNED=([Y|N])! )
				{									
					# ENT-VBPORT:[TID]:<VbPortAid>:[CTAG]:::[[ENCAP=<ENCAP>,][DOS=<DOS>,][STP=<STP>,][STPCOST=<STPCOST>,][STPPRIO=<STPPRIO>,][PVID=<PVID>,][DIRN=<DIRN>,][STAGTYPE=<STAGTYPE>,][PORTTYPE=<PORTTYPE>,][PINNED=<PINNED>]];
					print {$fh_EDITS_VB_PORTS} ("ENT-VBPORT::$1::::DOS=$2,DIRN=$3,PORTTYPE=EDGE,PINNED=$4;\n");
  					$vbports_created++;
 				}
				else
				{
					print {$fh_error} ("No match on VB port for: " . $line . "in tl1_logs_vb_ports.txt\n");
					$errors++;
				}
 		}
}
close $fh_source_vb_ports;
close $fh_EDITS_VB_PORTS;
close $fh_error;
#
#
####################################################################################





#################################################################################################
#
# Part B.1 File Handle Stuff for - tl1_logs_vlanvb_ports.txt			
# 
#
my $DATA_FILE_VLANVB_PORTS = 'tl1_logs_vlanvb_ports.txt';
open my $fh_source_vlanvb_ports, '<', $DATA_FILE_VLANVB_PORTS or die "Could not open $DATA_FILE_VLANVB_PORTS: $!\n";
 
# Edits VB port file stuff
my $EDITS_VLANVB_PORTS_FILE = 'CREATES_VLANVB_PORTS_FOR_' . $user_data_uplink . '.txt';
my $fh_EDITS_VLANVB_PORTS;			# EDITS File Handle
open $fh_EDITS_VLANVB_PORTS, ">", $EDITS_VLANVB_PORTS_FILE or die "Couldn't open $EDITS_VB_PORTS_FILE: $!\n";

# Error file stuff
$ERROR_FILE = 'TL1_ERROR_LOG_FOR_VLANVB_PORTS' . $user_data_uplink . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";
#
#
#
#################################################################################################
 

####################################################################################
#
# Part B.2 LOGIC For VB PORTS - the CREATES file
#
#
#
while ($line = <$fh_source_vlanvb_ports> )
{
  chomp($line); 				
  		if ( $line =~ m!ARP=!)
		{
				$vlanvbports_found++;
		
 				# This is a VLANVB port retrieval
				# "N100-4-VB1-3399::VLAN=N100-4-VB1-VLAN1048,ARP=N,DHCPDIR=NONE,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,LSVID=1048,"
				
 				if ( $line =~ m!(N\d+-\d+-VB\d+-\d+)::VLAN=(N\d+-\d+-VB\d+-VLAN\d+),ARP=([Y|N]),DHCPDIR=(\w+),OPT82ACT=(\w+),IGMP=NONE,PPPOEAC=N,PPPOESUB=([Y|N]),LSVID=(\d+)!)
				{					
					# ENT-VLAN-VBPORT:[TID]:<VbPortAid>:[CTAG]:::VLAN=<VLAN>,[[ARP=<ARP>,]
					# [DHCP=<DHCP>,][DHCPDIR=<DHCPDIR>,][OPT82ACT=<OPT82ACT>,][IGMP=<IGMP>,]
					# [PPPOEAC=<PPPOEAC>,][PPPOESUB=<PPPOESUB>,][LSVID=<LSVID>,][PRIO=<PRIO>,]
					# [TAGGING=<TAGGING>]];
					print {$fh_EDITS_VLANVB_PORTS} ("ENT-VLAN-VBPORT::$1::::VLAN=$2,ARP=$3,DHCPDIR=$4,OPT82ACT=$5,PPPOESUB=$6;\n");
  					$vlanvbports_created++;
 				}
				else
				{
					print {$fh_error} ("No match on VLANVB port for: " . $line . "in tl1_logs_vlanvb_ports.txt\n");
					$errors++;
				}
 		}
}
close $fh_source_vlanvb_ports;
close $fh_EDITS_VLANVB_PORTS;
close $fh_error;
#
#
#
####################################################################################





#################################################################################################
#
# Part C.1 File Handle Stuff for - tl1_logs_CVIDREG_ports.txt			
# 
#
#
my $DATA_FILE_CVIDREG_PORTS = 'tl1_logs_CVIDREG_ports.txt';
open my $fh_source_CVIDREG_ports, '<', $DATA_FILE_CVIDREG_PORTS or die "Could not open $DATA_FILE_CVIDREG_PORTS: $!\n";
 
# Edits CVIDREG file stuff
my $EDITS_CVIDREG_PORTS_FILE = 'CREATES_CVIDREG_PORTS_FOR_' . $user_data_uplink . '.txt';
my $fh_EDITS_CVIDREG_PORTS;			# EDITS File Handle
open $fh_EDITS_CVIDREG_PORTS, ">", $EDITS_CVIDREG_PORTS_FILE or die "Couldn't open $EDITS_CVIDREG_PORTS_FILE: $!\n";

# Error file stuff
$ERROR_FILE = 'TL1_ERROR_LOG_FOR_CVIDREG_PORTS' . $user_data_uplink . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";
#
#
#
#################################################################################################
 

####################################################################################
#
# Part C.2 LOGIC For CVIDREG PORTS - the CREATES file
#
#
#
while ($line = <$fh_source_CVIDREG_ports> )
{
  chomp($line); 				
  		if ( $line =~ m!PRIO=!)
		{
				$cvidreg_found++;
				
 				# This is a CVIDREG port retrieval
				# "N100-4-VB1-3400-UNTAGGED::SVID=1048,PRIO=0,RCVID=NONE"
				
 				if ( $line =~ m!(N\d+-\d+-VB\d+-\d+-\w+)::SVID=(\d+),PRIO=(\d+),RCVID=(\w+)!)
				{					
					# Syntax from 7.0 doc:
					# ENT-CVIDREG:[TID]:<CVidRegAid>::::SVID=<SVID>,[PRIO=<PRIO>],RCVID=<RCVID>;					
					print {$fh_EDITS_CVIDREG_PORTS} ("ENT-CVIDREG::$1::::SVID=$2,PRIO=$3,RCVID=$4;\n");
  					$cvidreg_created++;
 				}
				else
				{
					print {$fh_error} ("No match on CVIDREG for: " . $line . "in tl1_logs_CVIDREG_ports.txt\n");
					$errors++;
				}
 		}
}
close $fh_source_CVIDREG_ports;
close $fh_EDITS_CVIDREG_PORTS;
close $fh_error;
#
#
####################################################################################





####################################################################################
#
# Totals Section
#
#
print "==========================================================\n";
print "Totals \n";
print "==========================================================\n";

print "Total VB ports found in TL1 retrieval file:\t " . $vbports_found . "\n";
print "Total VB creates writted to TL1 VB Port CREATES file:\t " . $vbports_created . "\n\n";

print "Total VLANVB ports found in TL1 retrieval file:\t " . $vlanvbports_found . "\n";
print "Total VLANVB creates writted to TL1 VB Port CREATES file:\t " . $vlanvbports_created . "\n\n";

print "Total CVIDREG ports found in TL1 retrieval file:\t " . $cvidreg_found . "\n";
print "Total CVIDREG creates writted to TL1 VB Port CREATES file:\t " . $cvidreg_created . "\n\n";


print "If this is a non-zero value then look at the error log.txt files and contact Jason Murphy: " . $errors . "\n";
#
#
#
####################################################################################
 

 
