use strict;
use warnings;
  
my $t0_xcons_created = 1;
 
print "\n\n\n\n\n\n";
print "========================================================\n";
print "The C7 T0 Script Creator\n";
print "Version: 6-5-2012";
print "\n========================================================\n";
print "\n\n";
print "This script does these 2 things:\n";
print "1: Prompts the user for GR-303 subscriber data\n";
print "2: Creates a file that has all of the T0 creates\n";
 print "\nThis script is not service affecting and does not\n"; 
print "perform the actual creates deletes.\n";
print "You can copy the CREATES and use in your TL1\n"; 
print "scripts.\n";
print "========================================================\n";

######################################################################
# Gathering User Input to Option the Program
######################################################################

print "\n\n";
print "========================================================\n";
print "Enter the IG node and IG number:\n";
print "For example type N1-1-IG1 and hit enter\n";
print ">";
my $ig_node_number = <STDIN>;
chomp($ig_node_number);

print "\n\n";
print "========================================================\n";
print "Enter the start/low number of the CRV:\n";
print "For example if the CRV starts at 120 then just type 120 and hit enter\n";
print ">";
my $ig_start_crv = <STDIN>;
chomp( $ig_start_crv );

                                                                                                                                                      
print "\n\n";
print "========================================================\n";
print "Enter the node number of the subscribers:\n";
print "For example type N7-1 and hit enter\n";
print ">";
my $node_number = <STDIN>;
chomp($node_number);

print "\n\n";
print "========================================================\n";
print "Enter the lowest number DSL card slot:\n";
print "For example if slot 1 is the starting slot then just type 1 and hit enter:\n";
print ">";
my $lowest_slot = <STDIN>;
chomp( $lowest_slot );

print "\n\n";
print "========================================================\n";
print "Enter the highest number DSL card slot:\n";
print "For example if slot 20 is the highest slot then just type 20 and hit enter:\n";
print ">";
my $highest_slot = <STDIN>;
chomp( $highest_slot );


##################################################################################################################################################
# File Handle Stuff
##################################################################################################################################################
my $DATA_FILE = 'tl1_logs.txt';
my $DESTINATION_FILE = 'T0_Creates_IG' . $ig_node_number . "_CRV_starting_at_$ig_start_crv.txt";
open my $fh_303_creates , ">", $DESTINATION_FILE or die "Couldn't open $DATA_FILE: $!\n";
 
 

##################################################################################################################################################
# T0 Creates Logic Section
##################################################################################################################################################
while ( $lowest_slot <= $highest_slot )
{
	my $port_number = 1;
	my $upper_port_number = 24;
	
	while ( $port_number <= $upper_port_number ){
	print { $fh_303_creates } ("ENT-CRS-T0::$ig_node_number-$ig_start_crv,$node_number-$lowest_slot-$port_number;\n"); 
		$ig_start_crv++;
		$port_number++;

		$t0_xcons_created++;
	}

	$lowest_slot++

}  
close $fh_303_creates;
 
 
print "=======================================================";
print "Totals\n\n";
print "Number of 303 cross-connects created:		$t0_xcons_created\n";
print "=======================================================";

				



