=====================================
Script Name:	The T0 Script Creator
=====================================

Written by:	Jason Murphy
Date:		1/6/2012
Revision:	1A

Purpose:	Will create the CREATES and DELETES files for T1 hi-caps 
		

Specific Steps:	
		Logs into the C7 by IP address or hostname
		Retrieves all of the T1 hi-cap cross-connects for a user-specified shelf
		Then it creates a TXT file of the T1 hi-cap creates
		Then it creates a TXT file of the T1 hi-cap deletes

Supported Interfaces:	T1/HDSL ports and ONT T1 ports.
		
Limitations:	The script does not currently support T1 port to VC/VP cross-connects.

