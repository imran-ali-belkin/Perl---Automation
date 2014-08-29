use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

# Counters to keep track of total cross-connect create and deletes

my $total_onts_found_in_source_file = 0;
my $total_ont_creates = 0;

my $total_t0s_found_in_source_file = 0;
my $total_t0_port_edits = 0;

my $total_ethernets_found_in_source_file = 0;
my $total_ethernet_port_edits = 0;

my $total_t1s_found_in_source_file = 0;
my $total_t1_port_edits = 0;

my $total_avos_found_in_source_file = 0;
my $total_avo_port_edits = 0;

my $total_rfvids_found_in_source_file = 0;
my $total_rfvid_port_creates = 0;


print "\n\n\n\n\n\n";
print "=================================================================\n";
print "The GPON Port Script Creator\n";
print "=================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls GPON port info on a single slot\n";
print "2: Creates text files that have all of the EDITS and CREATES\n";
print "3: Creates a text file that has all of the EDITS\n";
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
 
print "\n";
print "=================================================================\n";
print "Enter the GPON node-shelf-slot you want me to retrieve on:\n"; 
print "(For example N1-1-1 or N2-1-20):\n";
print ">";
my $user_GPON_Slot = <STDIN>;
chomp($user_GPON_Slot);

print "\n";
print "=================================================================\n";
print "Enter the GPON node-shelf-slot that the new card will reside in:\n";
print "For example: N7-1-3 or N10-1-20\n";
print ">";
my $user_future_GPON_Slot = <STDIN>;
chomp($user_future_GPON_Slot);



# This is the C7 PW crack stuff
my $shell = C7::Cmd->new($ip, 23);
$shell->connect;
my ($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
my $password = $shell->computeForgottenPassword( $date, $sid );


############################################################################################################################################
#
#	This section telnets in and retrieves all ONTs on a GPON Slot
#
############################################################################################################################################

# This is the telnet session to get all ONT related info
my $t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_ONT_.txt' );

  #C7 IP/Hostname to open, change this to the one you want.
$t->open($ip);

  #Wait for prompt to appear;
$t->waitfor('/>/ms');

print "\n========================\n";
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
print "=============================\n\n";

# Inhibit Message All
$t->send("INH-MSG-ALL;");
$t->waitfor('/^;/ms');

$t->timeout(undef);
$t->send("RTRV-ONT::$user_GPON_Slot-ALL;");
print "==========================================================\n";
print "I am retrieving all of the ONTS on GPON $user_GPON_Slot \n";  
print "Please be patient. In particular if this is a larger network\n";
print "==========================================================\n";
$t->waitfor('/^;/ms'); 
$t->timeout(30);
 #Logout
$t->send('CANC-USER;');
$t->close;
############################################################################################################################################


############################################################################################################################################
#
#	This section telnets in and retrieves all T0 ports on an OLTG card
#
############################################################################################################################################

# This is the telnet session to get all ONT related info
$t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_T0_Ports_on_ONTs.txt' );

#C7 IP/Hostname to open, change this to the one you want.
$t->open($ip);

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
$t->send("RTRV-T0::$user_GPON_Slot-ALL;");
print "\n==========================================================\n";
print "I am retrieving all of the ONT T0 ports on $user_GPON_Slot \n";  
  
$t->waitfor('/^;/ms');
print "==========================================================\n";
print "OK, done retrieving the GPON ONT T0 ports\n";
print "==========================================================\n\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->timeout(30);
$t->send('CANC-USER;');
$t->close;
############################################################################################################################################



############################################################################################################################################
#
#	This section telnets in and retrieves all Ethernet ports on an OLTG card
#
############################################################################################################################################

# This is the telnet session to get all ONT related info
$t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_Ethernet_Ports_on_ONTs.txt' );

#C7 IP/Hostname to open, change this to the one you want.
$t->open($ip);

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
$t->send("RTRV-ETH::$user_GPON_Slot-ALL;");
print "==========================================================\n";
print "I am retrieving all of the Ethernet ports on GPON $user_GPON_Slot \n";  
print "==========================================================\n";

$t->waitfor('/^;/ms');
print "OK, done retrieving the GPON ONT Ethernet ports\n";
print "==========================================================\n\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->timeout(30);
 #Logout
$t->send('CANC-USER;');
$t->close;
############################################################################################################################################





############################################################################################################################################
#
#	This section telnets in and retrieves all T1 Ports on an OLTG card
#
############################################################################################################################################

# This is the telnet session to get all ONT related info
$t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_T1_Ports_on_ONTs.txt' );

  #C7 IP/Hostname to open, change this to the one you want.
$t->open($ip);

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
$t->send("RTRV-T1::$user_GPON_Slot-ALL;");
print "==========================================================\n";
print "I am retrieving all of the ONTS T1 ports on GPON $user_GPON_Slot \n";  
  
$t->waitfor('/^;/ms');
print "==========================================================\n";
print "OK, done retrieving the GPON ONT T1 ports\n";
print "==========================================================\n\n";

$t->timeout(30);

 #Logout
$t->send('CANC-USER;');
$t->close;
############################################################################################################################################





############################################################################################################################################
#
#	This section telnets in and retrieves all AVO Ports on an OLTG card
#
############################################################################################################################################

# This is the telnet session to get all ONT related info
$t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_AVO_Ports_on_ONTs.txt' );

#C7 IP/Hostname to open, change this to the one you want.
$t->open($ip);

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
$t->send("RTRV-AVO::$user_GPON_Slot-ALL;");
print "==============================================================\n";
print "I am retrieving all of the ONTS AVO ports on GPON $user_GPON_Slot \n";  
  
$t->waitfor('/^;/ms');
print "==============================================================\n";
print "OK, done retrieving the GPON ONT AVO ports\n";
print "==============================================================\n\n";
 
$t->timeout(30);

 #Logout
$t->send('CANC-USER;');
$t->close;
############################################################################################################################################




############################################################################################################################################
#
#	This section telnets in and retrieves all RFVID Ports on an OLTG card
#
############################################################################################################################################

# This is the telnet session to get all ONT related info
$t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_RFVID_Ports_on_ONTs.txt' );

  #C7 IP/Hostname to open, change this to the one you want.
$t->open($ip);

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
$t->send("RTRV-RFVID::$user_GPON_Slot-ALL;");
print "=============================================================\n";
print "I am retrieving all of the RFVID Ports on GPON $user_GPON_Slot\n";  
print "=============================================================\n";
 
$t->waitfor('/^;/ms');
print "OK, done retrieving the GPON ONT RFVID ports\n";
print "==============================================================\n\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->timeout(30);

 #Logout
$t->send('CANC-USER;');
print "Logging out of the C7 system\n";
print "===============================================================\n";
$t->close;
############################################################################################################################################



############################################################################################################################################
############################################################################################################################################
############################################################################################################################################
############################################################################################################################################
############################################################################################################################################
############################################################################################################################################
############################################################################################################################################





############################################################################################################################################
#
# This section is the actual manipulation and writing out of the new files which will have the TL1 edits, etc.
#
############################################################################################################################################


#############################################################################################################
# This section creates the existing ONT edits file to OOSMA and setting FSAN to bogus
#############################################################################################################

my $error_log = 'tl1_ERROR_LOG.txt';
my $fh_error;
open $fh_error, '>', $error_log or die "Could not open $error_log: $!\n";

my $DATA_FILE = 'tl1_logs_ONT_.txt';
my $DESTINATION_FILE_1 = $user_GPON_Slot . '_01_ONT_Edits.txt';


my $line;
my $fh1;		# Edits
 
# This is the read file
open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# This is the write file
open $fh1, ">", $DESTINATION_FILE_1 or die "Couldn't open $DESTINATION_FILE_1: $!\n";

my $ont_num_incrementer=1;

while ($line = <$fh> )
{
  chomp($line);

    # This an ONT retrieval output
	# "N2-1-18-1-1::ONTNUM=5555,ONTPROF=1,VCG=N1-1-IG3,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,DESC=\"Jimmy Joe\",ADRMODE=GRP:OOS-AUMA,SGEO&UEQ"

  if ($line =~ /ONTNUM/ ){
	  
	  $total_onts_found_in_source_file++;
	  
	  # Logic to match on ONT or DSL
	  
	 # if ONT has a VCG on it
	 if ($line =~ m!(N\d+-\d+-\d+-\d+-\d+)::ONTNUM=(\w+),ONTPROF=(\w+),VCG=(N\w+-\d+-IG\d+),!)  
	 {
		print {$fh1} ("ED-ONT::$1:::::OOS;\n"); 				# This edits the existing ONT to OOS
		print {$fh1} ("ED-ONT::$1::::ONTNUM=0,VCG=none;\n");	# This edits the existing ONT to a bogus FSAN
	 
	 }
     elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+):!) 
	 {
		print {$fh1} ("ED-ONT::$1:::::OOS;\n"); 				# This edits the existing ONT to OOS
		print {$fh1} ("ED-ONT::$1::::ONTNUM=0;\n");				# This edits the existing ONT to a bogus FSAN
		$ont_num_incrementer++;
 	 }
	 else 
	 {
		print {$fh_error} ("$line\n");
	 }
   }
}
close $fh1;
close $fh;


#############################################################################################################
# Create the new ONT on the new slot
#############################################################################################################
$DATA_FILE = 'tl1_logs_ONT_.txt';
my $DESTINATION_FILE_2 = $user_GPON_Slot . '_02_ONT_Creates.txt';
my $fh2;

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh2, ">", $DESTINATION_FILE_2 or die "Couldn't open $DESTINATION_FILE_2: $!\n";
 
 while ($line = <$fh> )
{
  chomp($line);

    # This an ONT retrieval output

  if ($line =~ /ONTNUM/ ){
   
	  # Logic if the ONT has a VCG and a Description
	  # "N2-1-18-1-1::ONTNUM=5555,ONTPROF=1,VCG=N1-1-IG3,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,DESC=\"Jimmy Joe\",ADRMODE=GRP:OOS-AUMA,SGEO&UEQ"
     if ( 
			$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),VCG=(\N\d+-\d+-\w+),VENDOR=(\w+),BATPROV=(\w+),SDBER=(\w+),GOS=(\w+),DESC=\\\"(.*)\\\",ADRMODE=(\w+)[:|,]!  	 	 
	 ) 
	 {
		# This creates the new ONT on the new slot	
        print {$fh2} ("ENT-ONT::$user_future_GPON_Slot-$2-$3::::ONTNUM=$4,ONTPROF=$5,VCG=$6,BATPROV=$8,SDBER=$9,GOS=$10,DESC=$11,ADRMODE=$12;\n");	
		$total_ont_creates++;
		
 	 }

	 # Logic if the ONT only has a description on it
 	 # "N2-1-18-1-1::ONTNUM=5555,ONTPROF=1,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,DESC=\"Jimmy Joe\",ADRMODE=GRP:OOS-AUMA,SGEO&UEQ"
     elsif ( 
			$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),VENDOR=(\w+),BATPROV=(\w+),SDBER=(\w+),GOS=(\w+),DESC=\\\"(.*)\\\",ADRMODE=(\w+)[:|,]!  	 	 
	 ) 
	 {
		# This creates the new ONT on the new slot	
        print {$fh2} ("ENT-ONT::$user_future_GPON_Slot-$2-$3::::ONTNUM=$4,ONTPROF=$5,BATPROV=$7,SDBER=$8,GOS=$9,DESC=$10,ADRMODE=$11;\n");	
		$total_ont_creates++;
		
 	 }
	 
	 
	 # Logic if the ONT has a VCG 
	 # "N2-1-3-1-1::ONTNUM=11111,ONTPROF=5,VCG=N1-1-IG2,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,ADRMODE=GRP:OOS-AUMA,SGEO&UEQ&CRS"
     elsif ( 
			$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),VCG=(\N\d+-\d+-\w+),VENDOR=(\w+),BATPROV=(\w+),SDBER=(\w+),GOS=(\w+),ADRMODE=(\w+)[:|,]!  	 	 
	 ) 
	 {
		# This creates the new ONT on the new slot	
        print {$fh2} ("ENT-ONT::$user_future_GPON_Slot-$2-$3::::ONTNUM=$4,ONTPROF=$5,VCG=$6,BATPROV=$8,SDBER=$9,GOS=$10,ADRMODE=$11;\n");	
		$total_ont_creates++;
 	 }
	 	 
	 # Logic if the ONT has no VCG, no Description 
	 # "N2-1-19-1-1::ONTNUM=0,ONTPROF=1,VENDOR=CXNK,BATPROV=Y,SDBER=5,GOS=OFF,ADRMODE=GRP:OOS-AU,SGEO&UEQ"
     elsif ( 
			$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+))::ONTNUM=(\w+),ONTPROF=(\w+),VENDOR=(\w+),BATPROV=(\w+),SDBER=(\w+),GOS=(\w+),ADRMODE=(\w+)[:|,]!  	 	 
	 ) 
	 {
		# This creates the new ONT on the new slot
        print {$fh2} ("ENT-ONT::$user_future_GPON_Slot-$2-$3::::ONTNUM=$4,ONTPROF=$5,BATPROV=$7,SDBER=$8,GOS=$9,ADRMODE=$10;\n");		
		$total_ont_creates++;
 	 }
	 else 
	 {
		print {$fh_error} ("$line\n");
	 }
	 
   }
}
close $fh;
close $fh2;


# T0 Port manipulations
my $fh3;

$DATA_FILE = 'tl1_logs_T0_Ports_on_ONTs.txt';
my $DESTINATION_FILE_3 = $user_GPON_Slot . '_03_T0_Port_Edits.txt';

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh3, ">", $DESTINATION_FILE_3 or die "Couldn't open $DESTINATION_FILE_3: $!\n";
 
 while ($line = <$fh> )
{
  chomp($line);

    # This an ONT retrieval output

  if ($line =~ /GSFN/ ){
		$total_t0s_found_in_source_file++;

		 # Logic if the TO port has a Description
		 # "N2-1-18-1-1-6::GSFN=2LS,RTLP=0.0,TTLP=0.0,DESC=\"YoPort6\":OOS-AU,AINS&SGEO"
 		 if ( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::GSFN=(\w+),RTLP=(\d+\.\d+),TTLP=(\d+\.\d+),DESC=\\\"(.*)\\\"[:|,]!  	 	 
		 )
		 { 
		    print {$fh3} ("ED-T0::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh3} ("ED-T0::$user_future_GPON_Slot-$2-$3-$4::::GSFN=$5,RTLP=$6,TTLP=$7,DESC=$8;\n");		
		    print {$fh3} ("ED-T0::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_t0_port_edits++;
		 }

		 
		 # Logic if the TO port does not have a Description
		 # "N2-1-18-1-1-7::GSFN=2LS,RTLP=0.0,TTLP=0.0,:OOS-AU,AINS&ADA&SGEO"
 		 elsif ( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::GSFN=(\w+),RTLP=(\d+\.\d+),TTLP=(\d+\.\d+)[:|,]!  	 	 
		 )
		 { 
		    print {$fh3} ("ED-T0::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh3} ("ED-T0::$user_future_GPON_Slot-$2-$3-$4::::GSFN=$5,RTLP=$6,TTLP=$7;\n");		
		    print {$fh3} ("ED-T0::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_t0_port_edits++;
		 }		 
		else 
		{
			print {$fh_error} ("$line\n");
		}

	}
}
close $fh;
close $fh3;



# Ethernet port manipulations
my $fh4;

$DATA_FILE = 'tl1_logs_Ethernet_Ports_on_ONTs.txt';
my $DESTINATION_FILE_4 = $user_GPON_Slot . '_04_Ethernet_Port_Edits.txt';

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh4, ">", $DESTINATION_FILE_4 or die "Couldn't open $DESTINATION_FILE_4: $!\n";
 
 while ($line = <$fh> )
{
  chomp($line);

    # This an ONT retrieval output

  if ($line =~ /MAXSPD/ ){
  		$total_ethernets_found_in_source_file++;

		 # Logic if the Ethernet port has HPNA and a Description:
 		 # "N2-1-18-1-2-2::MAXSPD=100,SPD=AUTO,DPLX=AUTO,MTU=1626,VIDTXMODE=MCAST,ENONBAT=USEDEF,HPNA=Y,DESC=\"hansolo\":OOS-AU,AINS&SGEO"
		if ( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::MAXSPD=(\w+),SPD=(\w+),DPLX=(\w+),MTU=(\w+),VIDTXMODE=(\w+),ENONBAT=(\w+),HPNA=(\w+),DESC=\\\"(.*)\\\"[:|,]!  	 	 
		 )
		 { 
		    print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4::::SPD=$6,DPLX=$7,MTU=$8,VIDTXMODE=$9,ENONBAT=$10,DESC=$12;\n");		
		    print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_ethernet_port_edits++;
		 }

		 # Logic if the Ethernet port has HPNA:
		 # "N2-1-18-1-2-2::MAXSPD=100,SPD=AUTO,DPLX=AUTO,MTU=1626,VIDTXMODE=MCAST,ENONBAT=USEDEF,HPNA=Y,:OOS-AU,AINS&ADA&SGEO"
		 elsif ( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::MAXSPD=(\w+),SPD=(\w+),DPLX=(\w+),MTU=(\w+),VIDTXMODE=(\w+),ENONBAT=(\w+),HPNA=(\w)[:|,]!  	 	 
		 )
		 { 
		    print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4::::SPD=$6,DPLX=$7,MTU=$8,VIDTXMODE=$9,ENONBAT=$10;\n");		
		    print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_ethernet_port_edits++;
		 }

  
  
		 # Logic if the Ethernet port has a Description
		 # "N2-1-18-1-3-1::MAXSPD=1000,SPD=1000,DPLX=FULL,MTU=1626,VIDTXMODE=MCAST,ENONBAT=USEDEF,DESC=\"woohoo\":OOS-AUMA,AINS&SGEO"
		elsif ( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::MAXSPD=(\w+),SPD=(\w+),DPLX=(\w+),MTU=(\w+),VIDTXMODE=(\w+),ENONBAT=(\w+),DESC=\\\"(.*)\\\"[:|,]!  	 	 
		 )
		 { 
		    print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4::::SPD=$6,DPLX=$7,MTU=$8,VIDTXMODE=$9,ENONBAT=$10,DESC=$11;\n");		
		    print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_ethernet_port_edits++;
		 }

		 
		 # Logic if the Ethernet port does not have a Description
		 # N2-1-18-1-2-1::MAXSPD=1000,SPD=AUTO,DPLX=AUTO,MTU=1626,VIDTXMODE=MCAST,ENONBAT=USEDEF,:OOS-AU,AINS&ADA&SGEO"
 		 elsif ( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::MAXSPD=(\w+),SPD=(\w+),DPLX=(\w+),MTU=(\w+),VIDTXMODE=(\w+),ENONBAT=(\w+)[:|,]!  	 	  
		 )
		 { 
		    print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
 			print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4::::SPD=$6,DPLX=$7,MTU=$8,VIDTXMODE=$9,ENONBAT=$10;\n");		
		    print {$fh4} ("ED-ETH::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_ethernet_port_edits++;
		 }		 
		else 
		{
			print {$fh_error} ("$line\n");
		}
	}
}
close $fh;
close $fh4;





# T1 port manipulations
my $fh5;

$DATA_FILE = 'tl1_logs_T1_Ports_on_ONTs.txt';
my $DESTINATION_FILE_5 = $user_GPON_Slot . '_05_T1_Port_Edits.txt';

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh5, ">", $DESTINATION_FILE_5 or die "Couldn't open $DESTINATION_FILE_5: $!\n";
 
 while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /LINECDE/ )
  {
  		$total_t1s_found_in_source_file++;
		# T1 port with a description
		# "N2-1-18-1-32-1::TYPE=DS1,T1MAP=NA,EQLZ=300,FMT=UF,LINECDE=B8ZS,GOS=OFF,TMGMODE=LOOP,IBLBEN=N,DESC=\"STARGATE1\":OOS-AU,AINS&SGEO"
		if ( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::TYPE=(\w+),T1MAP=(\w+),EQLZ=(\w+),FMT=(\w+),LINECDE=(\w+),GOS=(\w+),TMGMODE=(\w+),IBLBEN=(\w+),DESC=\\\"(.*)\\\"[:|,]!  	 	 
		 )
		 { 
		    print {$fh5} ("ED-T1::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh5} ("ED-T1::$user_future_GPON_Slot-$2-$3-$4::::TYPE=$5,T1MAP=$6,EQLZ=$7,FMT=$8,LINECDE=$9,GOS=$10,TMGMODE=$11,IBLBEN=$12,DESC=$13;\n");		
		    print {$fh5} ("ED-T1::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_t1_port_edits++;
		 }

		 # T1 port without a description:
		 # "N2-1-18-1-32-1::TYPE=DS1,T1MAP=NA,EQLZ=300,FMT=UF,LINECDE=B8ZS,GOS=OFF,TMGMODE=LOOP,IBLBEN=N,:OOS-AU,AINS&ADA&SGEO"
		 elsif ( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::TYPE=(\w+),T1MAP=(\w+),EQLZ=(\w+),FMT=(\w+),LINECDE=(\w+),GOS=(\w+),TMGMODE=(\w+),IBLBEN=(\w+)[:|,]!  	 	 
		 )
		 { 
		    print {$fh5} ("ED-T1::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh5} ("ED-T1::$user_future_GPON_Slot-$2-$3-$4::::TYPE=$5,T1MAP=$6,EQLZ=$7,FMT=$8,LINECDE=$9,GOS=$10,TMGMODE=$11,IBLBEN=$12;\n");		
		    print {$fh5} ("ED-T1::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_t1_port_edits++;
		 }
		else 
		{
			print {$fh_error} ("$line\n");
		}
 
	}
}
close $fh;
close $fh5;


# AVO Port Manipulations
my $fh6;

$DATA_FILE = 'tl1_logs_AVO_Ports_on_ONTs.txt';
my $DESTINATION_FILE_6 = $user_GPON_Slot . '_06_AVO_Port_Edits.txt';

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh6, ">", $DESTINATION_FILE_6 or die "Couldn't open $DESTINATION_FILE_6: $!\n";
 
 while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /OMI/ )
  {
  		$total_avos_found_in_source_file++;
		# AVO port with a description
		# "N2-1-18-1-4-1::OMI=3.8,RFRTRN=LOCKED,DESC=\"HALWowWow\":OOS-AU,SGEO"		
		if 
		( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::OMI=(\d+\.\d+),RFRTRN=(\w+),DESC=\\\"(.*)\\\"[:|,]!  	 	 	
 		)
		 { 
		    print {$fh6} ("ED-AVO::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh6} ("ED-AVO::$user_future_GPON_Slot-$2-$3-$4::::OMI=$5,RFRTRN=$6,DESC=$7;\n");		
		    print {$fh6} ("ED-AVO::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_avo_port_edits++;
		 }

		 # AVO port without a description:
		 # "N2-1-18-1-30-1::OMI=3.8,RFRTRN=LOCKED,:OOS-AU,ADA&SGEO"
		elsif 
		( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::OMI=(\d+\.\d+),RFRTRN=(\w+)[:|,]!  	 	 
		 )
		 { 
		    print {$fh6} ("ED-AVO::$user_future_GPON_Slot-$2-$3-$4:::::OOS;\n");
			print {$fh6} ("ED-AVO::$user_future_GPON_Slot-$2-$3-$4::::OMI=$5,RFRTRN=$6;\n");		
		    print {$fh6} ("ED-AVO::$user_future_GPON_Slot-$2-$3-$4:::::IS;\n");
			$total_avo_port_edits++;
		 }
 		else 
		{
			print {$fh_error} ("$line\n");
		}

	}
}
close $fh;
close $fh6;



# RFVID Port Manipulations
my $fh7;

$DATA_FILE = 'tl1_logs_RFVID_Ports_on_ONTs.txt';
my $DESTINATION_FILE_7 = $user_GPON_Slot . '_07_RFVID_Port_Edits.txt';

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh7, ">", $DESTINATION_FILE_7 or die "Couldn't open $DESTINATION_FILE_7: $!\n";
 
 while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /ENONBAT/ )
  {
  		$total_rfvids_found_in_source_file++;
		
		# AVO port with a description		
		# N2-1-18-1-4-1::ENONBAT=USEDEF,DESC=\"alien\":OOS-AU,AINS&SGEO	
		if 
		( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::ENONBAT=(\w+),DESC=\\\"(.*)\\\"[:|,]!  	 	 	
 		)
		 { 
 			print {$fh7} ("ENT-RFVID::$user_future_GPON_Slot-$2-$3-$4::::ENONBAT=$5,DESC=$6;\n");		
			$total_rfvid_port_creates++;
 		 }

		 # AVO port without a description:
		 # N2-1-18-1-30-1::ENONBAT=USEDEF,:OOS-AU,AINS&SGEO
		elsif 
		( 
				$line =~ m!(N\d+-\d+-\d+-(\d+)-(\d+)-(\d+))::ENONBAT=(\w+)[:|,]!  	 	 
		 )
		 { 
 			print {$fh7} ("ENT-RFVID::$user_future_GPON_Slot-$2-$3-$4::::ENONBAT=$5;\n");		
			$total_rfvid_port_creates++;
 		 }
		else 
		{
			print {$fh_error} ("$line\n");
		}
 
	}
}
close $fh;
close $fh7;



#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################
#############################################################################################



#############################################################################################
#############################################################################################
# Clean-Up Section
# This is the delete logic for the existing OLTG card - this will help with clean-up

###################################################################
# Delete the RFVID port logic
my $fh8;

$DATA_FILE = 'tl1_logs_RFVID_Ports_on_ONTs.txt';
my $DESTINATION_FILE_8 = $user_GPON_Slot . '_08_Clean_Up.txt';

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh8, ">", $DESTINATION_FILE_8 or die "Couldn't open $DESTINATION_FILE_8: $!\n";
 
 while ($line = <$fh> )
{
  chomp($line);

		  if ($line =~ /ENONBAT/ )
		  {
				# RFVID Dport with a description
				# N2-1-18-1-4-1::ENONBAT=USEDEF,DESC=\"alien\":OOS-AU,AINS&SGEO
			
				if 
				( 
						$line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+):!  	 	 	
				)
				{ 
					print {$fh8} ("ED-RFVID::$1:::::OOS;\n");
					print {$fh8} ("DLT-RFVID::$1;\n");		
				}
		  }
}
close $fh;
###################################################################

###################################################################
# Delete the AVO port
$DATA_FILE = 'tl1_logs_AVO_Ports_on_ONTs.txt';
open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

 while ($line = <$fh> )
{
  chomp($line);
		  if ($line =~ /OMI/ )
		  {
				if 
				( 
						$line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+):!  	 	 	
				)
				 { 
					print {$fh8} ("ED-AVO::$1:::::OOS;\n");
					print {$fh8} ("DLT-AVO::$1;\n");
				 }

		}
}
close $fh;
###################################################################


###################################################################
# Delete the T1 port
$DATA_FILE = 'tl1_logs_T1_Ports_on_ONTs.txt';
open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

 while ($line = <$fh> )
{
  chomp($line);

		  if ($line =~ /LINECDE/ )
		  {
				if 
				( 
						$line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+):!  	 	 	
				)
				 { 
					print {$fh8} ("ED-T1::$1:::::OOS;\n");
					print {$fh8} ("DLT-T1::$1;\n");
				 }
		}
}
close $fh;
###################################################################


###################################################################
# Delete the Ethernet Ports
$DATA_FILE = 'tl1_logs_Ethernet_Ports_on_ONTs.txt';
open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

while ($line = <$fh> )
{
	chomp($line);

	  if ($line =~ /DPLX/ )
	  {
			if 
			( 
					$line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+):!  	 	 	
			)
			 { 
				print {$fh8} ("ED-ETH::$1:::::OOS;\n");
				print {$fh8} ("DLT-ETH::$1;\n");
			 }
	  }  
}
close $fh;
###################################################################


###################################################################
# Delete the T0 Ports
$DATA_FILE = 'tl1_logs_T0_Ports_on_ONTs.txt';
open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

 while ($line = <$fh> )
{
  chomp($line);
  
		  if ($line =~ /GSFN/ )
		  {
				if 
				( 
						$line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+):!  	 	 	
				)
				 { 
					print {$fh8} ("ED-T0::$1:::::OOS;\n");
					print {$fh8} ("DLT-T0::$1::::INCL=Y;\n");
				 }
		}
}
close $fh;
###################################################################

###################################################################
# Delete the existing ONTs
$DATA_FILE = 'tl1_logs_ONT_.txt';
open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

 while ($line = <$fh> )
{
  chomp($line);

		  if ($line =~ /ONTNUM/ )
		  {
				if 
				( 
						$line =~ m!(N\d+-\d+-\d+-\d+-\d+):!  	 	 	
				)
				 { 
					print {$fh8} ("ED-ONT::$1:::::OOS;\n");
					print {$fh8} ("DLT-ONT::$1;\n");
				 }
		  }
}
close $fh;
###################################################################
# Finally close this when you are done with all of the deletes
close $fh8;
close $fh_error;

print "\nTotals:\n";
print "\tTotal number of ONTs found in the source file:\t$total_onts_found_in_source_file\n";
print "\tTotal number of ONTs created:\t\t\t$total_ont_creates\n\n";

print "\tTotal number of T0 ports found in source file:\t$total_t0s_found_in_source_file\n"; 
print "\tTotal number of T0 ports edited:\t\t$total_t0_port_edits\n\n";

print "\tTotal number of Ethernet ports found in source file: $total_ethernets_found_in_source_file\n"; 
print "\tTotal number of Ethernet ports edited: \t\t$total_ethernet_port_edits\n\n";

print "\tTotal number of T1 ports found in source file:\t$total_t1s_found_in_source_file\n"; 
print "\tTotal number of T1 ports edited:\t\t$total_t1_port_edits\n\n";

printf "\tTotal number of AVO ports found in source file: $total_avos_found_in_source_file \n"; 
printf "\tTotal number of AVO ports edited: \t\t$total_avo_port_edits \n\n";

print "\tTotal number of RFVID ports found in source file: $total_rfvids_found_in_source_file\n"; 
print "\tTotal number of RFVID ports created:\t\t$total_rfvid_port_creates\n\n";
 


