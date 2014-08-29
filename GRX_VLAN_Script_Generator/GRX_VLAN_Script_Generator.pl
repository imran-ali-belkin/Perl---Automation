#!/usr/bin/perl
use strict;
use warnings;

##############################################################################################
#
# GRX VLAN Script Generator
#
# TL script generator Name: GRX_VLAN_Script Generator.exe

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Use vlan.csv file pulled from CMS/iMS

# In CMS/iMS:
# 1. Highlight VB in Network Tree.
# 2. Click on VLANS in the Work area.
# 3. Change number of records to 5000 to list all VLANS.
# 4. Right click on the header, and print report and save file as vlan.csv

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Output:
# N101-1-VB7 (UTICA_258_2),701,Test ONT,VLAN Per Service,NONE,NONE,1,None,N
# [Bridge], [VLAN], [DESCRIPTION], [APPMODE}, [L2RLYMODE], [OPTION82], [NUMPRIO], [IGMPMODE], [STBRLYARP]
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create 2 files:
# 1_DELETE_VLAN.txt
# 2_CREATE_VLAN.txt

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# File 1:
# 1_DELETE_VLAN.txt

# TL1 command:
# DLT-VLAN::N101-1-VB7-VLAN701;

# Pattern Match
# DLT-VLAN::[Bridge]-VLAN[VLAN];

# Notes:
# For [Bridge], Do not include shelf name (UTICA_258_2)

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# File 2:

# 2_CREATE_VLAN.txt

# TL1 command:
# ENT-VLAN::N101-1-VB7-VLAN701::::DESC="Test ONT",APPMODE=TLS,L2RLYMODE=NONE,OPTION82=NONE,NUMPRIO=1,IGMPMODE=NONE,STBRLYARP=N;

# Pattern Match
# ENT-VLAN::[Bridge]-VLAN[VLAN]::::DESC=[DESCRIPTION],APPMODE=TLS,L2RLYMODE=[L2RLYMODE],OPTION82=[OPTION82],NUMPRIO=[NUMPRIO],IGMPMODE=[IGMPMODE],STBRLYARP=[STBRLYARP];

# Notes:
# For [Bridge], Do not include shelf name (UTICA_258_2)
# For DESC, if there is no DESC, then don't include this option.
# For APPMODE, use TLS for all VLANS, we are changing all VLANs to TLS.
#
#
#########################################################################################################



if (!$ARGV[0])
{
  print "================================================\n";
  print "USAGE\n";
  print "================================================\n";
  
  print "Usage of this script is 'GRX_VLAN_Script_Generator vlans.csv'\n";
  print "So, type the name of the generator and follow it with the name\n";
  print "of the CSV file. Thank you!";
  exit;  
}

if ($ARGV[0])
{
    print "----------------------------------------------\n";
	print "Welcome to the GRX_VLAN_Script Generator\n";
    print "----------------------------------------------\n";
	print "Requirements written by: An Do\n";
	print "Programming by: Jason Murphy\n";
	print "Written July 15, 2014\n";
	
	print "Hit enter to start the script!\n";
	print ">";
	my $contine = <STDIN>;
}

my $fh_error;		 
my $ERROR_FILE = 'error.txt';
open $fh_error, '>', $ERROR_FILE or die "Could not open $ERROR_FILE $!\n";

my $fh_DELETE;		
my $FILE_DELETE = '1_DELETE_VLAN.txt';
open $fh_DELETE, '>', $FILE_DELETE or die "Could not open $FILE_DELETE $!\n";

my $fh_CREATE;		 
my $FILE_CREATE = '2_CREATE_VLAN.txt';
open $fh_CREATE, '>', $FILE_CREATE or die "Could not open $FILE_CREATE $!\n";



while(<>)
{ 
   if ($_ =~ /N\d+-\d+-VB\d+/)
   {
    # N101-1-VB7 (UTICA_258_2),701,Test ONT,VLAN Per Service,NONE,NONE,1,None,N
	# [Bridge], [VLAN], [DESCRIPTION], [APPMODE}, [L2RLYMODE], [OPTION82], [NUMPRIO], [IGMPMODE], [STBRLYARP]

	my ($bridge, $VLAN, $DESCRIPTION, $APPMODE, $L2RLYMODE, $OPTION82, $NUMPRIO, $IGMPMODE, $STBRLYARP) = split(',', $_);
	chomp($STBRLYARP);
		
	#################################################################
	#
	#
	my $cleaned_up_bridge;
	if ($bridge =~ /(N\d+-\d+-VB\d+) .*/)
    {
	  $cleaned_up_bridge = $1;
	}
	#
	#
	#################################################################


	######################################################################################
	#
	#
	# N101-1-VB7 (UTICA_258_2),701,Test ONT,VLAN Per Service,NONE,NONE,1,None,N
	# [Bridge], [VLAN], [DESCRIPTION], [APPMODE}, [L2RLYMODE], [OPTION82], [NUMPRIO], [IGMPMODE], [STBRLYARP]

	# DLT-VLAN::N101-1-VB7-VLAN701;
	# DLT-VLAN::[Bridge]-VLAN[VLAN];
	
	# Notes:
	# For [Bridge], Do not include shelf name (UTICA_258_2)

	# DLT-VLAN::N101-1-VB7-VLAN701;

	print {$fh_DELETE}("DLT-VLAN::" . $cleaned_up_bridge . "-VLAN" . $VLAN . ";\n");
	#
	#
	######################################################################################

	
	
	######################################################################################
    #
	#	
	# ENT-VLAN::N101-1-VB7-VLAN701::::DESC="Test ONT",APPMODE=TLS,L2RLYMODE=NONE,OPTION82=NONE,NUMPRIO=1,IGMPMODE=NONE,STBRLYARP=N;
	# ENT-VLAN::[Bridge]-VLAN[VLAN]::::DESC=[DESCRIPTION],APPMODE=TLS,L2RLYMODE=[L2RLYMODE],OPTION82=[OPTION82],NUMPRIO=[NUMPRIO],IGMPMODE=[IGMPMODE],STBRLYARP=[STBRLYARP];

	#                   ENT-VLAN::                                            ::::DESC="Test ONT",          APPMODE=TLS,             L2RLYMODE=NONE,              OPTION82=NONE,             NUMPRIO=1,              IGMPMODE=NONE,             STBRLYARP=N;
	if ($DESCRIPTION eq '')
	{
		print {$fh_CREATE}("ENT-VLAN::${cleaned_up_bridge}-VLAN${VLAN}::::APPMODE=TLS,L2RLYMODE=${L2RLYMODE},OPTION82=${OPTION82},NUMPRIO=${NUMPRIO},IGMPMODE=${IGMPMODE},STBRLYARP=${STBRLYARP};\n");
	}
	else
	{
		print {$fh_CREATE}("ENT-VLAN::${cleaned_up_bridge}-VLAN${VLAN}::::DESC=\"${DESCRIPTION}\",APPMODE=TLS,L2RLYMODE=${L2RLYMODE},OPTION82=${OPTION82},NUMPRIO=${NUMPRIO},IGMPMODE=${IGMPMODE}STBRLYARP=${STBRLYARP};\n");	
	}
	#
	#
    ######################################################################################

	print "----------------------------\n";
	print "Processed line\n";
	print "----------------------------\n";

	}
}

print "Done!\n";

close $fh_error;
close $fh_DELETE;
close $fh_CREATE;
