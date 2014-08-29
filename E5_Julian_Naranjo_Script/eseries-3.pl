#!C:\Perl\bin\perl
# use strict;
# use warnings;
use Net::Telnet;
use Term::ReadKey;

# Jason Murphy changed the Timeout from 10 to undefined - so that we'll wait as long as possible
$telnet = new Net::Telnet (Timeout =>10,Prompt => '/>$/', Input_Log => "outputlog.txt", errmode=>

							(
								sub 
								{
									print "\n";
									print "-----------------------------------\r\n";
									print "Could not connect to ".$ip_address."\n";
									print "-----------------------------------\r\n";
									# List of unreachable devices
									open FILE, ">>failed.txt" or die $!;
									print FILE $ip_address."\n";
									close FILE;
									$i++;
									next;	
								}
							)
							);						
# Read parameters from file
open(INPUT, "input.txt") || die("Could not open file!");
@commands=<INPUT>; 
$i = 0;
foreach $input_line (@commands)
	{		
	$line = $input_line;
	if ($line =~ /^ip_addr=/)
		{	
			$device = $line;
			@ip = split("=",$device);
			$ip_address = $ip[1];				
			chomp($ip_address);
			# Call the subroutine to telnet to device and send the commands
			&connect;
		}
	$i++;
	}
			
# Subroutine
sub connect	
		{ 
			# Connect to the shelf
			$telnet->open($ip_address);
			# Wait for username
			$telnet->waitfor('/User name:\s*/');
			# Send username
			$telnet->print("admin");
			# Wait for password 
			$telnet->waitfor('/Password:\s*/');
			# Send password
			ReadMode 'noecho';
			ReadMode 'normal';
			$telnet->print ("1234");
			$telnet->waitfor('/>/');
			print "\n-> Working on: ".$ip_address."\n";
			$send_ip = "# IP address -> ".$ip_address."\n";
			$telnet->cmd(string => $send_ip, prompt => '/>/');
			$ind = $i + 1;
			$next_device = "#####";
			# send commands to the device
			do
				{
				$command = @commands[$ind];
				chomp($command);
				$telnet->cmd(string => $command, prompt => '/>/');
				# Jason Murphy incremented from .3 to .5
				sleep (1);
				$ind ++;
				# jason's addition
				print "\t$command\n";
				}	
			until ($command eq $next_device);
				$telnet->cmd(string => "config save", prompt => '/>/');
				# Jason Murphy incremented from 5 to 20 seconds
				sleep (5);
				$telnet->close;
				print "Completed ".$ip_address."\n";		
		}
			
			