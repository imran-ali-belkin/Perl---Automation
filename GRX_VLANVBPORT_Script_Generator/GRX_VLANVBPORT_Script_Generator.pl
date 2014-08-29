#!/usr/bin/perl
use strict;
use warnings;

# =================================================================================================================
# GRX VLANVBPORT Script Generator

# TL script generator Name: GRX_VLANVBPORT_Script Generator.exe

# File from output used:
# tl1_logs_VLANVBPORT.txt
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Use vlanvbport.csv file pulled from CMS/iMS

# In CMS/iMS:
# 1. Highlight VB in Network Tree.
# 2. Click on VBPORT in the Work area.
# 3. Change number of records to 5000 to list all VBPORTs.
# 4. Highlight all VBPORTs (CTRL-A).
# 5. CLICK on VLAN-VB PORTS to list all VLANVBPORTS.
# 6. Right click on the header, and print report and save file as vlanvbport.csv
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Output:
# N101-1-VB7-2 (UTICA_258_2),N101-1-VB7-VLAN702 (UTICA_258_2),N,Client,None,N,Y,702,NONE
# [ID], [VLAN], [ARP], [DHCPDIR], [IGMP], [PPPOEAC], [PPPOESUB], [LSVID], [OPT82ACT]
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create 2 files:

# 1_DELETE_VLANVBPORT.txt
# 2_CREATE_VLANVBPORT.txt
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# File 1:
# 1_DELETE_VLANVBPORT.txt

# TL1 command:
# DLT-VLAN-VBPORT::N101-1-VB7-2::::VLAN=N101-1-VB7-VLAN702,INCL=Y;

# Pattern Match
# DLT-VLAN-VBPORT::[ID]::::VLAN=[VLAN],INCL=Y;

# Notes:
# For [ID], Do not include shelf name (UTICA_258_2)
# For [VLAN], Do not include shelf name (UTICA_258_2)
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# File 2:
# 2_CREATE_VLANVBPORT.txt

# TL1 command:
# ENT-VLAN-VBPORT::N101-1-VB7-2::::VLAN=N101-1-VB7-VLAN702,ARP=N,DHCPDIR=Client,IGMP=None,PPPOEAC=N,PPPOESUB=Y,OPT82ACT=NONE;

# Pattern Match
# ENT-VLAN-VBPORT::[ID]::::VLAN=[VLAN],ARP=[ARP],DHCPDIR=[DHCPDIR],IGMP=[IGMP],PPPOEAC=[PPPOEAC],PPPOESUB=[PPPOESUB],OPT82ACT=[OPT82ACT];

# Notes:
# For [ID], Do not include shelf name (UTICA_258_2)
# For [VLAN], Do not include shelf name (UTICA_258_2)
# Do not need [LSVID] <-- This value is created automatically.
# =================================================================================================================




if (!$ARGV[0])
{
  print "================================================\n";
  print "USAGE\n";
  print "================================================\n";
  
  print "Usage of this script is 'GRX_VLANVBPORT_Script_Generator vlanvbport.csv'\n";
  print "So, type the name of the generator and follow it with the name\n";
  print "of the CSV file. Thank you!";
  exit;  
}

if ($ARGV[0])
{
    print "----------------------------------------------\n";
	print "Welcome to the GRX_VLANVBPORT_Script Generator\n";
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
my $FILE_DELETE = '1_DELETE_VLANVBPORT.txt';
open $fh_DELETE, '>', $FILE_DELETE or die "Could not open $FILE_DELETE $!\n";

my $fh_CREATE;		 
my $FILE_CREATE = '2_CREATE_VLANVBPORT.txt';
open $fh_CREATE, '>', $FILE_CREATE or die "Could not open $FILE_CREATE $!\n";


# N101-1-VB7-2 (UTICA_258_2),N101-1-VB7-VLAN702 (UTICA_258_2),N,Client,None,N,Y,702,NONE
# [ID], [VLAN], [ARP], [DHCPDIR], [IGMP], [PPPOEAC], [PPPOESUB], [LSVID], [OPT82ACT]

while(<>)
{ 
   if ($_ =~ /N\d+-\d+-VB\d+-\d+/)
   {
	my ($id, $VLAN, $ARP, $DHCPDIR, $IGMP, $PPPOEAC, $PPPOESUB, $LSVID, $OPT82ACT) = split(',', $_);
	chomp($OPT82ACT);
	
	#################################################################
	#
	#
	my $cleaned_up_id;
	if 
	(
		$id =~ /(N\d+-\d+-VB\d+-\d+-\d+) .*/
		||
		$id =~ /(N\d+-\d+-VB\d+-\d+) .*/		
	)
    {
	  $cleaned_up_id = $1;
	}
	#
	#
	#################################################################

	
	#################################################################
	#
	#
	my $cleaned_up_vlan;
	if 
	(
		$VLAN =~ /(N\d+-\d+-VB\d+-VLAN\d+) /
	)
	{
		$cleaned_up_vlan = $1;
	}
	#
	#
	#################################################################
	
	# DLT-VLAN-VBPORT::N101-1-VB7-2::::VLAN=N101-1-VB7-VLAN702,INCL=Y;
	# DLT-VLAN-VBPORT::[ID]::::VLAN=[VLAN],INCL=Y;
	print {$fh_DELETE}("DLT-VLAN-VBPORT::" . $cleaned_up_id . "::::VLAN=" . $cleaned_up_vlan . ",INCL=Y;\n");

	# ENT-VLAN-VBPORT::N101-1-VB7-2::::VLAN=N101-1-VB7-VLAN702,ARP=N,DHCPDIR=Client,IGMP=None,PPPOEAC=N,PPPOESUB=Y,OPT82ACT=NONE;
	                  # ENT-VLAN-VBPORT::N101-1-VB7-2          ::::VLAN=N101-1-VB7-VLAN702      ,ARP=N,           DHCPDIR=Client,          IGMP=None,         PPPOEAC=N,               PPPOESUB=Y,                OPT82ACT=NONE;
	print {$fh_CREATE}("ENT-VLAN-VBPORT::" . $cleaned_up_id . "::::VLAN=" . $cleaned_up_vlan . ",ARP=" . $ARP . ",DHCPDIR=" . $DHCPDIR . ",IGMP=" . $IGMP . ",PPPOEAC=" . $PPPOEAC . ",PPPOESUB=" . $PPPOESUB . ",OPT82ACT=". $OPT82ACT . ";\n");
	
	print "----------------------------\n";
	print "Processed line\n";
	print "----------------------------\n";
	}
}

print "Done!\n";

close $fh_error;
close $fh_DELETE;
close $fh_CREATE;
