############################################################################################################################################
#
# This is the ADSL, XDSL, DSL Group, T0 port TL1 Script Generator
# Written 2-5-2013 by Jason Murphy
# Note - go to the user interface section to get a feel for what this script does 
#
#
use strict;
use warnings;
use Net::Telnet;
use C7::Cmd;

############################################################################################################################################
#
# Counters to keep track of total edits
#
#
#
my $total_DSL_found_in_source_file = 0;
my $total_VDSL_found_in_source_file = 0;
my $total_XDSLGRPS_found_in_source_file = 0;
my $total_T0_found_in_source_file = 0;
#
#
#
############################################################################################################################################
 
 
############################################################################################################################################
#
# The user main interface that prompts the user for data
#
print "\n\n\n\n\n\n";
print "=================================================================\n";
print "The XDSL and T0 Port by Shelf Script Creator\n";
print "=================================================================\n";
print "\n\n";
print "This script does these three things:\n";
print "1: Logs into a C7 and pulls ADSL/VDSL/DSL Groups ports and\n" ;
print "    T0 port against an entire shelf\n";   
print "2: Creates text files that have all of the EDITS\n";
print "\nThis script is not service affecting and does not\n"; 
print "perform the actual edits.\n";
print "You can copy the edits and use with your favorite TL1 engine.\n"; 
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
print "Enter the shelf you want me to retrieve on:\n"; 
print "(For example N1-1 or N2-1):\n";
print ">";
my $user_ADSL_Slot = <STDIN>;
chomp($user_ADSL_Slot);
#
#
#
############################################################################################################################################

 

############################################################################################################################################
# 
# This is the C7 PW crack stuff
#
#
#
my $shell = C7::Cmd->new($ip, 23);
$shell->connect;
my ($date, $sid) = $shell->_getDateAndSid() ;
$shell->disconnect;
my $password = $shell->computeForgottenPassword( $date, $sid );
#
#
#
############################################################################################################################################


############################################################################################################################################
#
#	This section telnets in and retrieves all DSL ports on an DSL card
#
#
# 	This is the telnet session to get all DSL related info
my $t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_DSL.txt' );
 
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
$t->send("RTRV-ADSL::$user_ADSL_Slot-ALL;");
print "==========================================================\n";
print "I am retrieving all of the ADSL ports on shelf: $user_ADSL_Slot \n";  
print "==========================================================\n";
# 2-5-2013
$t->waitfor('/^;/ms');

$t->timeout(undef);
$t->send("RTRV-XDSL::$user_ADSL_Slot-ALL;");
print "==========================================================\n";
print "I am retrieving all of the VDSL ports on shelf: $user_ADSL_Slot \n";  
print "==========================================================\n";
# 2-5-2013
$t->waitfor('/^;/ms');

$t->timeout(undef);
$t->send("RTRV-GRPXDSL::$user_ADSL_Slot-ALL;");
print "==========================================================\n";
print "I am retrieving all of the VDSL ports on shelf: $user_ADSL_Slot \n";  
print "==========================================================\n";


$t->waitfor('/^;/ms');
print "OK, done retrieving the ADSL ports.\n";
print "==========================================================\n\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->timeout(30);
 #Logout
$t->send('CANC-USER;');
$t->close;
#
#
#
#
############################################################################################################################################

 
############################################################################################################################################
#
#	This section telnets in and retrieves all T0 ports on the DSL card
#
#
#
#
# This is the telnet session to get all ONT related info
$t = new Net::Telnet ( Timeout=>30, Input_Log => 'tl1_logs_T0_Ports.txt' );
 
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
$t->send("RTRV-T0::$user_ADSL_Slot-ALL;");
print "\n==========================================================\n";
print "I am retrieving all of the T0 ports on the shelf: $user_ADSL_Slot \n";  
  
$t->waitfor('/^;/ms');
print "==========================================================\n";
print "OK, done retrieving the T0 ports\n";
print "==========================================================\n\n";
# OR instead of using send/waitfor, you can use cmd if you set the prompt correctly:

$t->timeout(30);
$t->send('CANC-USER;');
$t->close;
#
#
#
#
#
############################################################################################################################################




############################################################################################################################################
#
# This section is the actual manipulation and writing out of the new files which will have the TL1 edits, etc.
#
############################################################################################################################################


#############################################################################################################
#
# This section ADSL, VDSL and DSL Group Port Manipulations
#
#
#
#
my $line;			# Variable for the current line

my $error_log = 'tl1_ERROR_LOG_for_' . $user_ADSL_Slot . '.txt';
my $fh_error;
open $fh_error, '>', $error_log or die "Could not open $error_log: $!\n";

# This is the read file
my $SOURCE_FILE = 'tl1_logs_DSL.txt';
open my $fh, '<', $SOURCE_FILE or die "Could not open $SOURCE_FILE: $!\n";

# ADSL File Handle Stuff
my $FILE_ADSL = '01_ADSL_Port_Edits_' . $user_ADSL_Slot . '.txt';
my $fh_ADSL;		# File handle for ADSL write outs
# This is the write file
open $fh_ADSL, ">", $FILE_ADSL or die "Couldn't open $FILE_ADSL: $!\n";

# VDSL File Handle Stuff
my $FILE_VDSL =  '02_VDSL_Port_Edits_' . $user_ADSL_Slot . '.txt';
my $fh_VDSL;		# File handle for VDSL write outs
open $fh_VDSL, ">", $FILE_VDSL or die "Couldn't open $FILE_VDSL: $!\n";

# DSL Group Handle Stuff
my $FILE_DSLGRPS = '03_DSLGroup_Port_Edits_' . $user_ADSL_Slot . '.txt';
my $fh_GRPS;		# File handle for VDSL write outs
open $fh_GRPS, ">", $FILE_DSLGRPS or die "Couldn't open $FILE_VDSL: $!\n";
#
#
#
#
# 6.1 Format
# ED-ADSL:[TID]:<AdslAid>:[CTAG]::[<SRVTYPE>],[<CHNL0>],[<CHNL1>]:
#   [[PROF=<PROF>,][XDSR0=<XDSR0>,][MDSR0=<MDSR0>,][XUSR0=<XUSR0>,]
#   [MUSR0=<MUSR0>,][XDSR1=<XDSR1>,][MDSR1=<MDSR1>,][XUSR1=<XUSR1>,]
#   [MUSR1=<MUSR1>,][DSEXR=<DSEXR>,][USEXR=<USEXR>,][TMDS=<TMDS>,]
#   [XMDS=<XMDS>,][MMDS=<MMDS>,][TMUS=<TMUS>,][XMUS=<XMUS>,][MMUS=<MMUS>,]
#   [DSLAT=<DSLAT>,][USLAT=<USLAT>,][TC=<TC>,][RAMODEDS=<RAMODEDS>,]
#   [RAMODEUS=<RAMODEUS>,][RAUMDS=<RAUMDS>,][RADMDS=<RADMDS>,]
#   [RAUTDS=<RAUTDS>,][RADTDS=<RADTDS>,][RAUMUS=<RAUMUS>,][RADMUS=<RADMUS>,]
#   [RAUTUS=<RAUTUS>,][RADTUS=<RADTUS>,][PMMODE=<PMMODE>,][L0TIME=<L0TIME>,]
#   [L2TIME=<L2TIME>,][L2ATPR=<L2ATPR>,][L2MINR=<L2MINR>,][L2EXITR=<L2EXITR>,]
#   [L2ENTRYR=<L2ENTRYR>,][L2ENTRYT=<L2ENTRYT>,][DSST=<DSST>,][DSET=<DSET>,]
#   [USST=<USST>,][USET=<USET>,][GOS=<GOS>,][REPTRMVRST=<REPTRMVRST>,]
#   [AHC=<AHC>,][INCL=<INCL>,][DESC=<DESC>]]:[<PST>],[<SST>];

# 6.1 Example:
# ED-ADSL::N1-1-3-1:::ADSL2+,FAST,DISABLE:PROF=3,XDSR0=48,MDSR0=32,
#   XUSR0=32,MUSR0=32,XDSR1=32,MDSR1=32,XUSR1=32,MUSR1=32,DSEXR=50,USEXR=50,
#   TMDS=6,XMDS=31,MMDS=0,TMUS=6,XMUS=31,MMUS=0,DSLAT=24,USLAT=24,TC=ENABLED,
#   RAMODEDS=DYNAMIC,RAMODEUS=DYNAMIC,RAUMDS=31,RADMDS=0,RAUTDS=30,RADTDS=30,
#   RAUMUS=31,RADMUS=0,RAUTUS=30,RADTUS=30,PMMODE=L2,L0TIME=5,L2TIME=5,
#   L2ATPR=2,L2MINR=1024,L2EXITR=512,L2ENTRYR=1,L2ENTRYT=1800,DSST=32,DSET=511,
#   USST=6,USET=30,GOS=OFF,REPTRMVRST=N,AHC=N,INCL=N,DESC="DESCRIPTION":OOS,
#   SB;

# Proven in the lab on a 6.1. system
# ED-ADSL::N1-1-12-1:::MM,FAST,DISABLE;
# ED-ADSL::N1-1-12-1:::::OOS;
# ED-ADSL::N1-1-12-1:::MM,FAST,DISABLE:XDSR0=896,MDSR0=128,XUSR0=160,MUSR0=128,XDSR1=0,MDSR1=0,XUSR1=0,MUSR1=0,DSEXR=100,USEXR=100,TMDS=6,XMDS=31;
# ED-ADSL::N1-1-12-1:::::IS;
# ED-ADSL::N1-1-12-1::::DESC=WOOHOO;
 
while ($line = <$fh> )
{
  chomp($line);

###########################################################################
# 
# ADSL Ports
#
#
# if the line has a DSL param XDSR0 on it then let's use it: 
	if ($line =~ /XDSR0=/ ){
	  	  
	 # Logic to match on ADSL port
	 
  	 # Output from a retrieval:
 	 # "N1-1-1-1:MM,FAST,DISABLE:XDSR0=1792,MDSR0=128,XUSR0=320,MUSR0=128,XDSR1=0,MDSR1=0,XUSR1=0,MUSR1=0,DSEXR=100,USEXR=100,TMDS=6,XMDS=31,MMDS=1,TMUS=6,XMUS=31,MMUS=1,DSLAT=AUTO,USLAT=AUTO,TC=ENABLED,GOS=OFF,REPTRMVRST=N,:OOS-AU,SGEO&CRS"
     #
	 # Example of a successful edit:
     # ED-ADSL::N1-1-12-1:::MM,FAST,DISABLE:XDSR0=896,MDSR0=128,XUSR0=160,MUSR0=128,XDSR1=0,MDSR1=0,XUSR1=0,MUSR1=0,DSEXR=100,USEXR=100,TMDS=6,XMDS=31;
	 #
 	 if ($line =~ m!(N\d+-\d+-\d+-\d+):(.*),(.*),(.*):(.*)[:]!)  
	 {
			print {$fh_ADSL} ("ED-ADSL::$1:::::OOS;\n"); 				 
			print {$fh_ADSL} ("ED-ADSL::$1:::$2,$3,$4:$5;\n");	
			print {$fh_ADSL} ("ED-ADSL::$1:::::IS;\n");

			# Increment for our stats that we have created an edit 
			$total_DSL_found_in_source_file++; 
	 }	 
		 else 
		 {  
				# If we don't match on anything then let's print it to the TL1 Error log:
				print {$fh_error} ("No match for: $line\n");
		 }
 }	 # End ADSL port match
#
#
#
#
#
#	 	 
###########################################################################
	 
	 
	 
###########################################################################
#
# 
# VDSL Ports
#
#
#
 	if ($line =~ /PKTMODE/ ) 
	{
	# RTRV-XDSL::ALL:::
	# "N5-1-1-1:VDSL2MM:PKTMODE=Y,CHNLLAT=INTLV,FALLBACKVPI=0,FALLBACKVCI=35,XDSLLINEPROF=8D,XRDS=512000,MRDS=64,XRUS=512000,MRUS=64,GOS=OFF,REPTRMVRST=N,MININPDS=0.5,MININPUS=0.5,TMDS=6,XMDS=16,MMDS=0,TMUS=6,XMUS=16,MMUS=0,INTLVLATDS=AUTO,INTLVLATUS=AUTO,:OOS-AU,AINS&ADA&FAF"
		 if ($line =~ m!(N\d+-\d+-\d+-\d+):(.*):(.*)[:]!)  
		 {
				print {$fh_VDSL} ("ED-XDSL::$1:::::OOS;\n"); 				 
				print {$fh_VDSL} ("ED-XDSL::$1:::$2:$3;\n");	
				print {$fh_VDSL} ("ED-XDSL::$1:::::IS;\n");

				# Increment for our stats that we have created an edit 
				$total_VDSL_found_in_source_file++; 		 
		}	 
		 else 
		 {  
				# If we don't match on anything then let's print it to the TL1 Error log:
				print {$fh_error} ("No match for: $line\n");
		 }
	}
#
#
#	
###########################################################################


	
 ##################################################
 # 
 #
 # Logic to match on GRP Ports
 #
 #
 #
 #
 #   REGEX explanation:
 # 		match on the literal GRP
 # 		match one or more integers
 #		match on the literal ::
 
	if ($line =~ /GRP\d+::/ )  
	{
	# Sample retrieve:
	# RTRV-GRPXDSL::ALL:::
    # "N2-1-14-GRP2::TYPE=ADSL,MEM=N2-1-14-3&N2-1-14-4,MRDS=768,XRDS=65472,MRUS=256,XRUS=3008,DIFDS=16,DIFUS=16,GOS=OFF,REPTRMVRST=N,DESC=\"574-935-0035\":IS-NR,CRS"
	# "N1-3-3-GRP1::TYPE=VDSL,MEM=N1-3-3-1&N1-3-3-2,PKTMODE=Y,FALLBACKVPI=0,FALLBACKVCI=35,MRDS=768,XRDS=65472,MRUS=256,XRUS=1600,DIFDS=16,DIFUS=16,GOS=OFF,REPTRMVRST=N,:OOS
		 if ($line =~ m!(N\d+-\d+-\d+-GRP\d+)::TYPE=\w+,(.*)[:]!)  
		 {
				print {$fh_GRPS} ("ENT-GRPXDSL::$1::::$2;\n");	
				print {$fh_GRPS} ("ED-GRPXDSL::$1:::::IS;\n");

				# Increment for our stats that we have created an edit 
				$total_XDSLGRPS_found_in_source_file++; 
		 }	 	
		 else 
		 {  
				# If we don't match on anything then let's print it to the TL1 Error log:
				print {$fh_error} ("No match for: $line\n");
		 }
	}
}
close $fh;
close $fh_ADSL;
close $fh_VDSL;
close $fh_GRPS;
#
#
#
#
#####################################################################################





#####################################################################################
#
# T0 Port manipulations
#
#
#
my $DATA_FILE = 'tl1_logs_T0_Ports.txt';
my $FILE_T0 = '04_T0_Port_Edits_for_' . $user_ADSL_Slot . '.txt';

my $fh_T0;

open $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";
open $fh_T0, ">", $FILE_T0 or die "Couldn't open $FILE_T0: $!\n";
 
 while ($line = <$fh> )
{
  chomp($line);

  if ($line =~ /GSFN/ ){
		$total_T0_found_in_source_file++;

  		 # 6.1 system - matches on EFTT and no Description
 		 # N1-1-16-1::GSFN=2LS,RTLP=-2.0,TTLP=-2.0,Z=900,EFTT=N,:OOS-AU,AINS&ADA&SGEO"
  		 if 
		 ( $line =~ m!(N\d+-\d+-\d+-\d+)::.*GSFN=(\w+),RTLP=(.*),TTLP=(.*),Z=(\d+),EFTT=(\w+)[:|,]! )
		 { 
		    print {$fh_T0} ("ED-T0::$1:::::OOS;\n");
			print {$fh_T0} ("ED-T0::$1::::GSFN=$2,RTLP=$3,TTLP=$4,Z=$5,EFTT=$6;\n");		
		    print {$fh_T0} ("ED-T0::$1:::::IS;\n");
			$total_T0_found_in_source_file++;
		 }
		 # 6.1. system - matches on EFTT and a Description
		 #  N1-1-16-1::GSFN=2LS,RTLP=-2.0,TTLP=-2.0,Z=900,EFTT=N,DESC=\"SUPERMAN\":OOS-AU,AINS&SGEO"
 		 elsif ( $line =~ m!(N\d+-\d+-\d+-\d+)::.*GSFN=(\w+),RTLP=(.*),TTLP=(.*),Z=(\d+),EFTT=(\w+),DESC=\\\"(.*)\\\"[:|,]! )
		 { 
		    print {$fh_T0} ("ED-T0::$1:::::OOS;\n");
			print {$fh_T0} ("ED-T0::$1::::GSFN=$2,RTLP=$3,TTLP=$4,Z=$5,EFTT=$6,DESC=$7;\n");		
		    print {$fh_T0} ("ED-T0::$1:::::IS;\n");
			$total_T0_found_in_source_file++;
		 }
		# GPON variation
		# "N1-3-19-1-9-2::GSFN=2LS,RTLP=GR909,TTLP=GR909,DESC=\"MIKE KNUEVE\":OOS-AU,SGEO"
		elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+)::GSFN=(\w+),RTLP=(.*),TTLP=(.*),DESC=(.*)"[:|,]! )
		{ 
		    print {$fh_T0} ("ED-T0::$1:::::OOS;\n");
			print {$fh_T0} ("ED-T0::$1::::GSFN=$2,RTLP=$3,TTLP=$4,DESC=$5;\n");		
		    print {$fh_T0} ("ED-T0::$1:::::IS;\n");		
		}
	    # GPON something or another
		#  N1-3-19-1-1-1::CRV=N1-4-IG1-515,GSFN=2LS,RTLP=GR909,TTLP=GR909,DESC=\"BRETT UNVERFERTH\":OOS-AU,SGEO&CRS"
		elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+)::CRV=N\d+-\d+-IG\d+-\d+,GSFN=(\w+),RTLP=(.*),TTLP=(.*),DESC=(.*)"[:|,]! )
		{ 
		    print {$fh_T0} ("ED-T0::$1:::::OOS;\n");
			print {$fh_T0} ("ED-T0::$1::::GSFN=$2,RTLP=$3,TTLP=$4,DESC=$5;\n");		
		    print {$fh_T0} ("ED-T0::$1:::::IS;\n");		
		}
		# GPON variation 
		# "N1-3-19-1-32-1::CRV=N1-4-IG1-501,GSFN=2LS,RTLP=GR909,TTLP=GR909,:OOS-AU,ADA&SGEO&CRS"
		elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+)::CRV=N\d+-\d+-IG\d+-\d+,GSFN=(\w+),RTLP=(.*),TTLP=(.*),[:|,]! )
		{ 
		    print {$fh_T0} ("ED-T0::$1:::::OOS;\n");
			print {$fh_T0} ("ED-T0::$1::::GSFN=$2,RTLP=$3,TTLP=$4;\n");		
		    print {$fh_T0} ("ED-T0::$1:::::IS;\n");		
		}

		# GPON variation 
		#  "N1-3-19-1-1-2::GSFN=2LS,RTLP=GR909,TTLP=GR909,:OOS-AU,ADA&SGEO"
		elsif ( $line =~ m!(N\d+-\d+-\d+-\d+-\d+-\d+)::GSFN=(\w+),RTLP=(.*),TTLP=(.*),[:|,]! )
		{ 
		    print {$fh_T0} ("ED-T0::$1:::::OOS;\n");
			print {$fh_T0} ("ED-T0::$1::::GSFN=$2,RTLP=$3,TTLP=$4;\n");		
		    print {$fh_T0} ("ED-T0::$1:::::IS;\n");		
		}
		else 
		{
			print {$fh_error} ("$line\n");
		}
	}
}
close $fh;
close $fh_T0; 
close $fh_error;
#
#
# 
#####################################################################################
 
 
 
 
#####################################################################################
#
# User Interface - print out totals for the user
#
#
# 
print "\nTotals:\n";
print "\tTotal number of ADSL ports found in source file:\t$total_DSL_found_in_source_file\n"; 
print "\tTotal number of VDSL ports found in source file:\t$total_VDSL_found_in_source_file\n"; 
print "\tTotal number of XDSL Groups found in source file:\t$total_XDSLGRPS_found_in_source_file\n"; 
print "\tTotal number of T0 ports found in source file:\t$total_T0_found_in_source_file\n"; 
#
#
# 
#####################################################################################

 

  


