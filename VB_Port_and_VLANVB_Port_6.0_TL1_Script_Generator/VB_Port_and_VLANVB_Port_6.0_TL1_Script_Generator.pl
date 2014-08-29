use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

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

my $vlanvbports_found = 0;
my $vlanvbports_created = 0;
my $vlanvbports_deleted = 0;
################################################################################################


 
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
print "The C7 6.0 VB Port and VLAN VB Port TL1 Script Generator\n";
print "         Version 1_A - May 1, 2012\n";
print "          Written by Jason Murphy\n";
print "==========================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls all VB and VLANVB ports on a Virtual Bridge\n";
print "2: Creates a text file that has all of the DELETES\n";
print "   The deletes will have the syntax to delete the existing cross-connect.\n";
print "3: Creates a text file that has all of the CREATES\n";
print "   The creates will have the syntax to build a new cross-connect to a \n";
print "   user-specified VB port\n";
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

#################################################################################################


#################################################################################################
#
# Telnet to retrieve all VLANVB ports
# 
#################################################################################################
$t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_vlanvb_ports.txt' );
  #C7 IP/Hostname to open, change this to the one you want.
$t->open($destination_c7);

  #Wait for prompt to appear;
$t->waitfor('/>/ms');
    
#Send default username/password (Not using cracker here)
$t->send("ACT-USER::");
$t->send($user_name);
$t->send(":::");
$t->send($password);
$t->send(";");

#The actual return prompt is a semicolon at the end of the output, so wait for this
$t->waitfor('/^;/ms');
 
# Inhibit Message All
$t->send("INH-MSG-ALL;");
$t->waitfor('/^;/ms');

$t->timeout(undef);
$t->send("RTRV-VLAN-VBPORT::$user_data_uplink-all;");
print "=============================\n";
print "I am retrieving all of the VLANVB ports on $user_data_uplink \n";  
print "Please be patient. In particular if this is a larger network\n";
print "=============================\n";

$t->waitfor('/^;/ms');
print "======================================\n";
print "OK, done retrieving the VLAN VB Ports ports\n";
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

my $DATA_FILE_VLANVB_PORTS = 'tl1_logs_vlanvb_ports.txt';
open my $fh_source_vlanvb_ports, '<', $DATA_FILE_VLANVB_PORTS or die "Could not open $DATA_FILE_VLANVB_PORTS: $!\n";
 
# Creates VB port file stuff
my $CREATES_VB_PORTS_FILE = 'CREATES_VB_PORTS_FOR_' . $user_data_uplink . '.txt';
my $fh_CREATES_VB_PORTS;		# CREATES File Handle
open $fh_CREATES_VB_PORTS, ">", $CREATES_VB_PORTS_FILE or die "Couldn't open $CREATES_VB_PORTS_FILE: $!\n";

# Deletes VB port file stuff
my $fh_DELETES_VB_PORTS;		# DELETES File Handle
my $DELETES_VB_PORTS_FILE = 'DELETES_VB_PORTS_' . $user_data_uplink . '.txt';
open $fh_DELETES_VB_PORTS, ">", $DELETES_VB_PORTS_FILE or die "Couldn't open $DELETES_VB_PORTS_FILE: $!\n";

# Creates VB port file stuff
my $CREATES_VLANVB_PORTS_FILE = 'CREATES_VLANVB_PORTS_FOR_' . $user_data_uplink . '.txt';
my $fh_CREATES_VLANVB_PORTS;		# CREATES File Handle
open $fh_CREATES_VLANVB_PORTS, ">", $CREATES_VLANVB_PORTS_FILE or die "Couldn't open $CREATES_VLANVB_PORTS_FILE: $!\n";

# Deletes VB port file stuff
my $fh_DELETES_VLANVB_PORTS;		# DELETES File Handle
my $DELETES_VLANVB_PORTS_FILE = 'DELETES_VLANVB_PORTS_' . $user_data_uplink . '.txt';
open $fh_DELETES_VLANVB_PORTS, ">", $DELETES_VLANVB_PORTS_FILE or die "Couldn't open $DELETES_VLANVB_PORTS_FILE: $!\n";

# Error file stuff
my $fh_error;
my $ERROR_FILE = 'TL1_ERROR_LOG_FOR_' . $user_data_uplink . '.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE: $!\n";
##############################################################################################################################


####################################################################################
#
# CREATES AND DELETE LOGIC FOR VB PORTS
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

 				if ( $line =~ m!(N\d+-\d+-VB\d+-\d+)::ENCAP=\w+,DOS=([Y|N]),STP=[Y|N],DIRN=(\w+),STPCOST=\d+,STPPRIO=\d+,PVID=\w+,PINNED=([Y|N])["|,]! )
				{					
					print {$fh_CREATES_VB_PORTS} ("ENT-VBPORT::$1::::DOS=$2,DIRN=$3,PINNED=$4;\n");
					print {$fh_DELETES_VB_PORTS} ("DLT-VBPORT::$1:;\n");
 					$vbports_created++;
					$vbports_deleted++;
				}
				else
				{
					print {$fh_error} ("No match on VB port for: " . $line . "\n");
					$errors++;
				}
 		}
}
close $fh_source_vb_ports;
close $fh_CREATES_VB_PORTS;
close $fh_DELETES_VB_PORTS;
####################################################################################



####################################################################################
#
# CREATES AND DELETE LOGIC FOR VLANVB PORTS
#
####################################################################################
# This is the write file
while ($line = <$fh_source_vlanvb_ports> )
{
  chomp($line); 				
		if ( $line =~ m!IGMP=!)
		{
			$vlanvbports_found++;
			
				# This is a VLANVB port retrieval
				# N4-1-VB1-6000::VLAN=N4-1-VB1-VLAN1026,ARP=N,DHCP=N,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,PRIO=0,TAGGING=DFLT"
				# N4-1-VB1-4::VLAN=N4-1-VB1-VLAN1026,ARP=N,DHCP=N,OPT82ACT=NONE,IGMP=NONE,PPPOEAC=N,PPPOESUB=Y,PRIO=0,TAGGING=DFLT"

 				if ( $line =~ m!(N\d+-\d+-VB\d+-\d+)::VLAN=(N\d+-\d+-VB\d+-VLAN\d+),ARP=([Y|N]),DHCP=([Y|N]),OPT82ACT=\w+,IGMP=\w+,PPPOEAC=[Y|N],PPPOESUB=([Y|N]),PRIO=\d+,TAGGING=\w+["|,]! )
				{					
					# ent-vlan-vbport::N4-1-vb1-6500::::VLAN=N4-1-vb1-vlan1026;
					print {$fh_CREATES_VLANVB_PORTS} ("ENT-VLAN-VBPORT::$1::::VLAN=$2,ARP=$3,DHCP=$4,PPPOESUB=$5;\n");
					print {$fh_DELETES_VLANVB_PORTS} ("DLT-VLAN-VBPORT::$1::::VLAN=$2;\n");
					$vlanvbports_created++;
					$vlanvbports_deleted++;
 				}
				else
				{
					print {$fh_error} ("No match on VLANVB port for: " . $line . "\n");
					$errors++;
				}
 		}
}
close $fh_source_vlanvb_ports;
close $fh_CREATES_VLANVB_PORTS;
close $fh_DELETES_VLANVB_PORTS;
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
print "Total VB creates writted to TL1 VB Port CREATES file:\t " . $vbports_created . "\n";
print "Total VB deletes written to TL1 VB Port DELETES file:\t " . $vbports_deleted . "\n\n";

print "Total VLANVB ports found in TL1 retrieval file:\t " . $vlanvbports_found . "\n";
print "Total VLANVB ports written to TL1 VLANVB Port CREATES file:\t " . $vlanvbports_created . "\n";
print "Total VLANVB ports written to TL1 VLANVB Port DELETES file:\t " . $vlanvbports_deleted . "\n\n";

print "If this is a non-zero value then look at the error log.txt file and contact Jason Murphy: " . $errors . "\n";

print "\n";
####################################################################################
 

 
