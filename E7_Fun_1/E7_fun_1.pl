use strict;
use warnings;
use Net::Telnet;

##############################################################################################
#
#	User Interface Section
#
#
#
#
print "========================================================\n";
print "E7 Command Runner\n";
print "\tWritten 7-14-2014\n";
print "\tCoded by Jason Murphy\n";

# print "\n\n";
# print "========================================================\n";
# print " Please enter either the IP address or hostname of the E7:\n";
# print " Example: 10.208.5.27\n";
# print ">";
my $ip = "10.208.5.27";
chomp($ip);

# print "\n\n";
# print "========================================================\n";
# print "Enter the command you would like run:\n";
# print ">";
# my $command_to_run = <STDIN>;
# chomp($command_to_run);
#
#
#
##############################################################################################




##############################################################################################
#
#	Telnet to C7 to retrieve ONT data
#
#
#
#
my $telnet = new Net::Telnet 
			( 
				Timeout=>30, 
				Input_Log => 'input_log.txt', 
				Output_Log=>'output_log.txt', 
				Errmode=>'die',
				Prompt=>'/CalixE7>/'
			);

#C7 IP/Hostname to open, change this to the one you want.
$telnet->open($ip);

print "\n\n";
print "========================\n";
print "Logging in to E7 at $ip\n";
print "========================\n";

$telnet->waitfor('/Username:/ms');
$telnet->print("e7");
$telnet->waitfor('/Password:/ms');
$telnet->print("admin");
$telnet->waitfor('/CalixE7>/ms');


#The actual return prompt is a semicolon at the end of the output, so wait for this
print "=============================\n";
print "We are logged in successfully\n";
print "=============================\n";

print "=============================\n";
print "Retrieving the uptime\n";  
print "=============================\n";
$telnet->timeout(undef);
my @vlans = $telnet->cmd("show vlan");
print "VLANS is:\n @vlans \n";

my $line;
my $current_vlan;
my @vlan_list;

foreach $line (@vlans)
{
	if ($line =~ /(\d+) \"/)
	{
	  print "Current VLAN is: $1\n";
	  push(@vlan_list, $1);
	}
}

print "VLAN list is @vlan_list\n";



print "======================================\n";
print "OK, done.\n";
print "======================================\n";

$telnet->timeout(30);

$telnet->print("logout");
print "======================================\n";
print "Logging out of the E7 at $ip\n";
print "======================================\n";
$telnet->close;

print "=====================================================\n";
print "Now I am going to read in the TL1 text file\n";
print "and create the E7 files\n";
print "=====================================================\n";
#
#
#
#
##############################################################################################

 
 
 
##############################################################################################
#
# File Handles 
# 
# my $DATA_FILE = 'tl1_logs.txt';			
# my $line;

# my $fh_C7_CREATES;		# File handle for CREATES
# my $CREATES_FILE = 'IPVC_CREATES_FOR_' .$C7_xDSL_shelf. '.txt';
# open $fh_C7_CREATES, ">", $CREATES_FILE or die "Couldn't open $CREATES_FILE: $!\n";

# my $fh_C7_DELETES;		# File handle for DELETES
# my $DELETES_FILE = 'IPVC_DELETES_FOR_' .$C7_xDSL_shelf. '.txt';
# open $fh_C7_DELETES, ">", $DELETES_FILE or die "Couldn't open $DELETES_FILE: $!\n";

# File handle stuff for the error file
# my $fh_error;		# File handle for errors
# my $ERROR_FILE = 'TL1_ERROR_LOGS_FOR_' .$C7_xDSL_shelf. '.txt';
# open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

# Open the data file for reading in the tl1_logs.txt
# open my $fh, '<', $DATA_FILE or die "Could not open $DATA_FILE: $!\n";

# 
# 
# 
# 
##############################################################################################


##############################################################################################
#
# Open the TL1 Logs, Pattern Match and Write out to the CREATES and DELETES Files
#
#
#
# while ($line = <$fh> )
# {
  # chomp($line);

 # "N1-1-7-PP1-VP0-VC164,N15-1-1-1-CH0-VP0-VC39::TRFPROF=59,BCKPROF=59,PATH=UNPROT,BWC=1,ARP=N,PARP=Y,APP=IP,CONSTAT=NORMAL" 
 # Only pattern match on CRS where PATH=UNPROT or PATH=WORK
  
  # if 
  # (
	# $line =~ m!(N\d+-\d+-\d+-PP1-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+)::TRFPROF=(\w+),BCKPROF=(\w+),PATH=(UNPROT),BWC=(\d+),ARP=([YN]),PARP=([YN]),APP=(IP),!  
	# ||
	# $line =~ m!(N\d+-\d+-\d+-PP1-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+)::TRFPROF=(\w+),BCKPROF=(\w+),PATH=(WKG),BWC=(\d+),ARP=([YN]),PARP=([YN]),APP=(IP),!  
   # )
   # {
     # my $source = 	$1;
	 # my $dest = 	$2;
	 # my $trfprof =  $3;
	 # my $bckprof =  $4;
	 # my $path = 	$5;
	 # my $bwc =		$6;
	 # my $arp = 		$7;
	 # my $parp = 	$8;
	 # my $app = 		$9;
	 
	 # $candidate_found++; 

	 # if ($path eq 'WKG')
	# {
	  # $path = 'BOTH';
	# }

	##################################################################
	#
	# DELETES
	#
	# File 1: IPVC_DELETES_FOR_Nx-x.txt
	# TL1 Command:
	# DLT-CRS-VIDVC::N1-1-7-PP1-VP0-VC164,N15-1-1-1-CH0-VP0-VC39::::IRCAID=N1-1-7;
    #
	# pattern match:
	# DLT-CRS-VIDVC::[Source from output],[DEST from output]::::IRCAID=[Ques #3];
	# print {$fh_C7_DELETES} ("DLT-CRS-VIDVC::" .$source. "," .$dest. "::::IRCAID=" . $irc_location . ";\n");
	# $candidate_delete++;
	
	##################################################################
	#
	# CREATES
	# File 2: IPVC_CREATES_FOR_Nx-x.txt
    #
	# TL1 Command:
	# ENT-CRS-VIDVC::N1-1-7-PP1-VP0-VC164,N15-1-1-1-CH0-VP0-VC39::::IRCAID=N1-1-7,TRFPROF=59,BCKPROF=59,ARP=N,PARP=Y,PATH=UNPROT;
	# ENT-CRS-VIDVC::[Source from output],[DEST from output::::IRCAID=[Ques #3],TRFPROF=[Copy from output],BCKPROF=[Copy from output],ARP=[Copy from output],PARP=[Copy from output],PATH=[If UNPROT, use UNPROT -- IF WORK, use BOTH]	
    #
	# Pattern match:
	# ENT-CRS-VIDVC::N1-1-7-PP1-VP0-VC164,N15-1-1-1-CH0-VP0-VC39::::IRCAID=N1-1-7,BWC=1,TRFPROF=59,BCKPROF=59,ARP=N,PARP=Y,PATH=UNPROT;
  	# print {$fh_C7_CREATES} ("ENT-CRS-VIDVC::" .$source. "," .$dest. "::::IRCAID=" .$irc_location. ",BWC=".$bwc. ",TRFPROF=" .$trfprof. ",BCKPROF=" .$bckprof. ",ARP=" .$arp. ",PARP=" .$parp. ",PATH=" .$path. ";\n");
	# $candidate_create++;
   # }
   
   # Use Case: No BWCs
   # elsif 
  # (
	# $line =~ m!(N\d+-\d+-\d+-PP1-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+)::TRFPROF=(\w+),BCKPROF=(\w+),PATH=(UNPROT),ARP=([YN]),PARP=([YN]),APP=(IP),!  
	# ||
	# $line =~ m!(N\d+-\d+-\d+-PP1-VP\d+-VC\d+),(N\d+-\d+-\d+-\d+-CH0-VP\d+-VC\d+)::TRFPROF=(\w+),BCKPROF=(\w+),PATH=(WKG),ARP=([YN]),PARP=([YN]),APP=(IP),!  
   # )
   # {
     # my $source = 	$1;
	 # my $dest = 	$2;
	 # my $trfprof =  $3;
	 # my $bckprof =  $4;
	 # my $path = 	$5;
	 # my $arp = 		$6;
	 # my $parp = 	$7;
	 # my $app = 		$8;
	 
	 # $candidate_found++; 

	 # if ($path eq 'WKG')
	# {
	  # $path = 'BOTH';
	# }

	##################################################################
	#
	# DELETES
	#
	# File 1: IPVC_DELETES_FOR_Nx-x.txt
	# TL1 Command:
	# DLT-CRS-VIDVC::N1-1-7-PP1-VP0-VC164,N15-1-1-1-CH0-VP0-VC39::::IRCAID=N1-1-7;
    #
	# pattern match:
	# DLT-CRS-VIDVC::[Source from output],[DEST from output]::::IRCAID=[Ques #3];
	# print {$fh_C7_DELETES} ("DLT-CRS-VIDVC::" .$source. "," .$dest. "::::IRCAID=" . $irc_location . ";\n");
	# $candidate_delete++;
	
	##################################################################
	#
	# CREATES
	# File 2: IPVC_CREATES_FOR_Nx-x.txt
    #
	# TL1 Command:
	# ENT-CRS-VIDVC::N1-1-7-PP1-VP0-VC164,N15-1-1-1-CH0-VP0-VC39::::IRCAID=N1-1-7,TRFPROF=59,BCKPROF=59,ARP=N,PARP=Y,PATH=UNPROT;
	# ENT-CRS-VIDVC::[Source from output],[DEST from output::::IRCAID=[Ques #3],TRFPROF=[Copy from output],BCKPROF=[Copy from output],ARP=[Copy from output],PARP=[Copy from output],PATH=[If UNPROT, use UNPROT -- IF WORK, use BOTH]	
    #
	# Pattern match:
	# ENT-CRS-VIDVC::N1-1-7-PP1-VP0-VC164,N15-1-1-1-CH0-VP0-VC39::::IRCAID=N1-1-7,BWC=1,TRFPROF=59,BCKPROF=59,ARP=N,PARP=Y,PATH=UNPROT;
  	# print {$fh_C7_CREATES} ("ENT-CRS-VIDVC::" .$source. "," .$dest. "::::IRCAID=" .$irc_location. ",TRFPROF=" .$trfprof. ",BCKPROF=" .$bckprof. ",ARP=" .$arp. ",PARP=" .$parp. ",PATH=" .$path. ";\n");
	# $candidate_create++;
   # }
   # No match at all - write it to the error log and increment the $ont_not_matched counter
   # else 
   # {
		# print {$fh_error} ("No match for: $line \n");
   # }
# }
#	End of all the pattern matching and manipulation
#
#
#
##############################################################################################


##############################################################################################
#
# File Handles - Close them
#
#
# close $fh_C7_CREATES;
# close $fh_C7_DELETES;
# close $fh;
# close $fh_error;
#
#
#
#
##############################################################################################




