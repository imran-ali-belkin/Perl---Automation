===========================================
Script Name:	The Data ATM Script Creator
===========================================

Written by:	Jason Murphy
Date:		12/29/2011
Revision:	2

Purpose:	Will create the CREATES and DELETES for ATM (DS3/OCx) uplinks
		for DSL and ONT subscribers.

Specific Steps:
		The script logs into the C7 by IP address or hostname
		Then it retrieves all ATM cross-connects for a given DS3 or OCx uplink.
		Then it creates a txt file containing all of the creates
		Then is creates a txt file containing all of the deletes

What Uplinks are supported?
		DS3 ATM Uplinks
		OCx ATM Uplinks

What access ports are supported?
		DSL
		DSL Groups
		ONT Ethernet
		T1 IMA Downlinks
		T1 IMA AP Downlinks
		DS3 Downlinks
		OCx Downlinks

If you have any ideas for enhanced functionality please contact Jason Murphy
 