use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# 10-3-2012 for VB port pinner script
# "N1-1-VB1-7959::ENCAP=ETHERNETV2,DOS=N,STP=OFF,DIRN=DOWN,STPCOST=100,STPPRIO=128,STAGTYPE=CTAG_8100,PORTTYPE=EDGE,PINNED=N,"


# This is a VB port retrieval
# "N4-1-VB1-6000::ENCAP=ETHERNETV2,DOS=Y,STP=N,DIRN=BOTH,STPCOST=100,STPPRIO=128,PVID=NONE,PINNED=Y"

# This is a VLANVB port retrieval
# N4-1-VB1-6000::VLAN=N4-1-VB1-VLAN1026,ARP=N,DHCP=N,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,PRIO=0,TAGGING=DFLT"

# Delete a VB port:
# dlt-vbport::N4-1-vb1-6500;


################################################################################################
#
# This script is useful on 6.0 and prior systems where the VLANIF construct does not exist.
#
# It retrieves all existing VB ports and VLANVB ports for a user specified Virtual Bridge
#
################################################################################################


################################################################################################
# 
# Counters Section
# These are counters which keep track of how many cross-connects we create by access subscriber type
my $errors = 0;

my $vbports_found = 0;
my $vbports_created = 0;
my $vbports_deleted = 0;

################################################################################################


 
################################################################################################
#
# Getting user input
#
# 1. Asks you the system IP address
# 2. Enter the existing Virtual Bridge
#
################################################################################################

print "\n\n\n\n\n\n";
print "==========================================================================\n";
print "The C7 VB Port Pinner TL1 Script Generator\n";
print "         Version 1 - October 3, 2012\n";
print "          Written by Jason Murphy\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls all VB a Virtual Bridge\n";
print "2: Creates one text file that has all VB ports set the VB ports \n";
print "\tto pinned PINNED=Y\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
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
print "For example if the Virtual Bridge is N4-1-VB1 then enter N4-1-VB1 and hit enter:\n";
print "                                          NODE-SHELF-VB#\n";
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
#################################################################################################




#################################################################################################
#
# File Handle Stuff
# 
#################################################################################################
# Jason's additions
my $line;						# Used for current line

my $DATA_FILE_VB_PORTS = 'tl1_logs_vb_ports.txt';
open my $fh_source_vb_ports, '<', $DATA_FILE_VB_PORTS or die "Could not open $DATA_FILE_VB_PORTS: $!\n";
 
# Edits VB port file stuff
my $EDITS_VB_PORTS_FILE = 'EDITS_VB_PORTS_FOR_' . $user_data_uplink . '.txt';
my $fh_EDITS_VB_PORTS;			# EDITS File Handle
open $fh_EDITS_VB_PORTS, ">", $EDITS_VB_PORTS_FILE or die "Couldn't open $EDITS_VB_PORTS_FILE: $!\n";

# Error file stuff
my $fh_error;
my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_data_uplink . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";
##############################################################################################################################


####################################################################################
#
# VB Port pinner LOGIC FOR VB PORTS - the EDITS file
#
####################################################################################
# This is the write file
while ($line = <$fh_source_vb_ports> )
{
  chomp($line); 				
		if ( $line =~ m!DOS=!)
		{
				$vbports_found++;
		
 				# This is a VB port retrieval
				# "N4-1-VB1-6000::ENCAP=ETHERNETV2,DOS=Y,STP=N,DIRN=BOTH,STPCOST=100,STPPRIO=128,PVID=NONE,PINNED=Y"

 				if ( $line =~ m!(N\d+-\d+-VB\d+-\d+)::!)
				{					
					print {$fh_EDITS_VB_PORTS} ("ED-VBPORT::$1::::PINNED=Y;\n");
  					$vbports_created++;
 				}
				else
				{
					print {$fh_error} ("No match on VB port for: " . $line . "\n");
					$errors++;
				}
 		}
}
close $fh_source_vb_ports;
close $fh_EDITS_VB_PORTS;
close $fh_error;
####################################################################################





####################################################################################
#
# Totals Section
#
####################################################################################
print "==========================================================\n";
print "Totals \n";
print "==========================================================\n";

print "Total VB ports found in TL1 retrieval file:\t " . $vbports_found . "\n";
print "Total VB creates writted to TL1 VB Port EDITS file:\t " . $vbports_created . "\n";

print "If this is a non-zero value then look at the error log.txt file and contact Jason Murphy: " . $errors . "\n";
print "\n";
####################################################################################
 

 
