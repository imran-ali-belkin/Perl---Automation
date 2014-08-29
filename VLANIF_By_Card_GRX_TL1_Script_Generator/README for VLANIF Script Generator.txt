=====================================
Script Name:	VLANIF Script Creator 
=====================================

Written by:	Jason Murphy
Date:		1/3/2012
Revision:	1B

Purpose:	Will create the VLANIF CREATES and DELETES for use in TL1 Scripts 
		for DSL and PON subscribers. This is for a GRX environment, not EXA!

C7 Software Supported: 6.1.x and greater. 6.1.x was the first version that supported
		The VLANIF commands. If the system is below 6.1.x do not use this script.
 
Specific Steps:	
		Logs into the C7 by IP address or hostname
		Retrieves the Software Version running to determine the TL1 syntax to use
		Retrieves the GRX VLAN-IFS based on user specified VB and VLAN
 		Then it creates a TXT file of the VLANIF creates
		Then it creates a TXT file of the VLANIF deletes
 
Access Supported: 	6.1 Supports DSL, PON and DS3 Downlink subscribers only. 
			7.0 and greater supports DSL, PON T1 IMA, T1 IMA APs, DS3 Downlinks, OC Downlinks.




