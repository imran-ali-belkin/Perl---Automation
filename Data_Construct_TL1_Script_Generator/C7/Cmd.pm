package C7::Cmd;

# This class has routines to access the C7 Command line interface


use strict;
use warnings;

use Carp;
use Net::Telnet;
use HTTP::Date;

# Constants
use constant
{
	TL1_TIMEOUT	=> 5,
	LOCAL_TIMEOUT => 5,
	REMOTE_TIMEOUT => 5,
};

#
#  This class uses Net::Telnet to connect to a C7 Amp.  An instance can 
#  send TL1 commands, or, after a call to openShell(), can issue debug
#  commands.
#
#  C7Cmd will log in by default as user c7support, using the forgotten
#  password algorithm.
#
#  method descriptions:
#
#  ctor: accepts host, port, verbosity level
#
#  connect    : opens a socket
#
#  disconnect : closes a socket, disconnecting shell and logging out if 
#               required
#
#  tl1Login	  : Logs into a TL1 session (uses the forgotten password if uid
#				is c7support and no password is specified)
#
#  tl1Logout  : Logout from a TL1 session
#
#  openShell  : opens a debug shell (c7support only)
#
#  setVersion : change the version, used for old "forgottenPw" algorithm
#
#  closeShell : closes a debug shell if open
#
#  openRemoteShell : opens a shell to a remote C7 slot (c7support only)
#
#  closeRemoteShell : Closes the remote session
#
#  tl1Cmd     : sends a TL1 command and returns 1 on COMPLD, 0 on DENY
#
#  shellCmd   : sends a shell command (shell must be open)
#
#  remoteCmd  : sends a shell command to a remote shell
#
#  computeForgottenPassword : -- Not really planned to be exported

# Global vars ....
my $operation;
my $debug = 0;

# ----------------------------------------------------------------------------
# Create a Command Line Interface object
#
# Args:
#	Telnet Host
#	Telnet Port	[default: 23]
#	Verbosity Level [default: 0 -- no output]
#					1: Echoes input command
#					2: Dumps every line of output from remote system
# ----------------------------------------------------------------------------
sub new {
	my $proto	= shift;
	my $class	= ref($proto) || $proto;
	my $this	= {};

	$this->{version}		= 4.1;
	$this->{telnetHost}		= shift || "192.168.1.1";
	$this->{telnetPort}		= shift || 23;
	$this->{userName}		= "c7support";
	$this->{isConnected}	= 0;
	$this->{isLoggedIn}	    = 0;
	$this->{isShellActive}  = 0;
	$this->{isRemoteActive}	= 0;
	$this->{localShellPrompt}	= "";
	$this->{remoteShellPrompt}	= "";
	$this->{verbosity}		= shift || 0;
	@{$this->{timeOutStack}}	= ();

	$this->{Telnet}	= Net::Telnet::->new(Timeout => TL1_TIMEOUT,
										 Binmode => 0,
										 Telnetmode => 0,
										 Errmode => \&_timeoutErr);
  

	bless ($this, $class);
	return $this;
}

# ----------------------------------------------------------------------------
# connect: Makes a telnet connection to the C7 system
#
# Args:
#	Directory to log interactions in (if specified)
# ----------------------------------------------------------------------------
sub connect {
	my ($this, $logDir) = @_;
	my $verbosity = $this->{verbosity};

	if ($this->{isConnected})
	{
		carp "Already connected";
		return 0;
	}
	my $telnetAddr = join(' ', "Host:", $this->{telnetHost},
						  "port:", $this->{telnetPort});

	print "\nConnecting to $telnetAddr ..." if ($verbosity > 1);

	$operation = "telnet connect";

	# log interactions if we were asked to
	if ($logDir)
	{
		$this->{Telnet}->dump_log(File::Spec->catfile($logDir, "tnet_dmp.log"));
		$this->{Telnet}->input_log(File::Spec->catfile($logDir, "tnet_in.log"));
		$this->{Telnet}->output_log(File::Spec->catfile($logDir, "tnet_out.log"));
	}

	$this->{Telnet}->open(Host => $this->{telnetHost},
						  Port => $this->{telnetPort},
						  ErrMode => "return")
	or do {
		print STDERR $this->{Telnet}->errmsg, "\n";
		exit (1);
	};

	$this->{isConnected} = 1;
	print "=CONNECTED=\n" if ($verbosity > 1);

	return 1;
}

sub setVersion {
	my $this = shift;

	my $ver = shift;

	$this->{version} = $ver;
}


# ----------------------------------------------------------------------------
# disconnect: Disconnects from the C7 system
#
# ----------------------------------------------------------------------------
sub disconnect {
	my $this = shift;
	my $verbosity = $this->{verbosity};

	# Logout first, if necessary
	if ($this->{isLoggedIn})
	{
		$this->tl1Logout();
	}
	if ($this->{isConnected})
	{
		$this->{Telnet}->close();
		$this->{isConnected} = 0;

		# Stop logging 
		$this->{Telnet}->dump_log("");
		$this->{Telnet}->input_log("");
		$this->{Telnet}->output_log("");

		print "=DISCONNECTED=\n" if ($verbosity > 1);
	}
}

# ----------------------------------------------------------------------------
# tl1Login: Login to the TL1 session
#
# Args:
#	User ID:
#	Password: [filled in automatically if uid is "c7support]
# ----------------------------------------------------------------------------
sub tl1Login {
	my ($this, $uid, $pw) = @_;

	my $ok = 0;
	my $cmd;
	my @outRecs;
	my $verbosity = $this->{verbosity};

	if ($this->{isLoggedIn})
	{
		carp "Already logged in";
		return 0;
	}

	# Compute and use the forgotten password if none was specified for
	# c7support user
	if ( (! defined $uid ) || ( ($uid eq "c7support") && ! defined($pw)) )
	{
		my ($date, $sid) = $this->_getDateAndSid();
		$pw = $this->computeForgottenPassword( $this->_getDateAndSid() );
	}

	$this->{Telnet}->buffer_empty();

	$cmd = "act-user\:\:$uid\:\:\:$pw";
    print "TL1: logging in as $uid\n" if ($verbosity > 1);

	$ok = $this->tl1Cmd($cmd, \@outRecs);
	if ($ok)
	{
		$this->{isLoggedIn} = 1;
		$this->{userName} = $uid;
		$ok = $this->tl1Cmd("INH-MSG-ALL", \@outRecs);
		warn "INH-MSG-ALL failed" unless $ok;

		if ($this->tl1Cmd("rtrv-netype;", \@outRecs)) 
		{
		# "CALIX,C7,OSTP,4.1.11"
			my ($ver) = $outRecs[0] =~ /.*CALIX,C7,OSTP,(\d+\.\d+)/;
			$this->setVersion($ver);
		}
	}
	else
	{
		print STDERR "LOGIN FAILED\n";
	}

	return $ok;
}

# ----------------------------------------------------------------------------
# tl1Logout: Logout from the tl1 session
#
# ----------------------------------------------------------------------------
sub tl1Logout {
	my $this = shift;
	my $verbosity = $this->{verbosity};
	my $ok = 0;
	my @recs;

	# Close the shell if it is open
	if ($this->{isShellActive})
	{
		$this->closeShell();
	}

	# Then end the tl1 session
	if ($this->{isLoggedIn})
	{
		print "TL1: logging out\n" if ($verbosity > 1);
		$ok = $this->tl1Cmd("canc-user", \@recs);
		if ($ok)
		{
			$this->{isLoggedIn} = 0;
		}
	}
	else
	{
		carp "Not logged in";
	}

	return $ok;
}

# ----------------------------------------------------------------------------
# openShell: Open a debug shell to local amp
#
# Args:	None
#
# Valid only for user "c7support
# ----------------------------------------------------------------------------
sub openShell {
	my $this = shift;
	my $verbosity = $this->{verbosity};

	if ($this->{userName} ne "c7support")
	{
		carp "Shell commands only valid for user c7support";
		return 0;
	}
	elsif ($this->{isShellActive})
	{
		carp "Shell already open";
		return 0;
	}

	print "== Opening Local shell ..." if ($verbosity > 1);
	$operation = "Open shell";

	# Set the longer timeout, storing the old value
	push @{$this->{timeOutStack}}, $this->timeOut(LOCAL_TIMEOUT);

	$this->{Telnet}->buffer_empty();
	$this->{Telnet}->print("shell");
	my ($pre, $match) = $this->{Telnet}->waitfor(Match => '/N\d+-\d-34> $/',
												 Errmode => \&_timeoutErr );
	print " OPENED ==\n" if ($verbosity > 1);

	$this->{isShellActive} = 1;
	$this->{localShellPrompt} = $match;

	return 1;
}

# ----------------------------------------------------------------------------
# closeShell: Disconnect from local shell
#
# ----------------------------------------------------------------------------
sub closeShell {
	my $this = shift;
	my $verbosity = $this->{verbosity};
	my $ok = 0;

	# Close the remote shell first if it is open
	if ($this->{isRemoteActive})
	{
		$this->closeRemoteShell();
	}

	# Then try to close local shell
	if ( $this->{isShellActive} )
	{
		print "== Closing Local shell " if ($verbosity > 1);
		$operation = "close shell";
		my @recs = ();

		# Run the command.  Give some room for the system to be able to respond
		sleep 2;	# pace the command
		$ok = $this->shellCmd("/s/dsc");
		print " CLOSED ==\n" if ($verbosity > 1);
		sleep 3;	# pace the command
		$this->{Telnet}->buffer_empty();

		$this->{isShellActive} = 0;
		$this->{localShellPrompt} = "";

		# Get the old time out back
		$this->timeOut(pop @{$this->{timeOutStack}} );

		# the first character after shell disconenct is always lost...
		$this->tl1Cmd("rtrv-hdr"); sleep 1;
		$this->tl1Cmd("rtrv-hdr");
	}
	else
	{
		carp "No shell open";
	}
	return $ok;
}

# ----------------------------------------------------------------------------
# openRemoteShell: Open a debug shell to any card in the network
#
# Args:
#	IN: Backplane ID of shelf card is in
#	IN: Slot number of the card [defaults to amp]
#	IN: The Cpu on the card we want to talk to
#
# Valid only for user "c7support"
#
# Note: If there is a request to open a remote shell on the local shelf, we
#       simulate it by just presenting the same shell with the housekeeping
#       parameters updated
# ----------------------------------------------------------------------------
sub openRemoteShell ($;$$) {
	my ($this, $bpId, $slot, $cpu) = @_;
	my $verbosity = $this->{verbosity};

	# fill in defaults for slot and cpu
	$slot = 34 unless (defined $slot);
	unless (defined $cpu)
	{
		$cpu = ($slot >= 1 && $slot <= 22) ? 'l' : 'p';
	}

	unless ($this->{isShellActive})
	{
		carp "Local shell not open for remote shell";
		return 0;
	}

	my $cmd = "/sys/rmt -b $bpId -s $slot -c $cpu";
	print "=== Opening remote shell ===\n" if ($verbosity > 1);

	# Set the longer timeout, storing the old value
	push @{$this->{timeOutStack}}, $this->timeOut(REMOTE_TIMEOUT);

	my @recs = ();
	my $ok = $this->shellCmd($cmd,\@recs);

	my $remotePrompt = "";

	while (my $line = shift @recs)
	{
		# Look for the remote prompt
		if ( $line =~ /((N\d+-\d-$slot)(-L)?> )/  )
		{
			$remotePrompt = $1;
		}
		# remote shell to local amp -- simulate
		elsif ($line =~ /Must request/)
		{
			$remotePrompt = $this->{localShellPrompt};
		}
		last if $remotePrompt;
	}

	unless ($remotePrompt)
	{
		warn "No remote prompt found\n";
		return 0;
	}

	print "--- Remote shell OPENED ---\n" if ($verbosity > 1);

	$this->{isRemoteActive} = 1;
	$this->{remoteShellPrompt} = $remotePrompt;

	return 1;
}

# ----------------------------------------------------------------------------
# closeRemoteShell: Disconnect from remote shell
#
#  Note: This skips the disconnect command if we are just simulating the
#         remote-shell-like behaviour on local shell
# ----------------------------------------------------------------------------
sub closeRemoteShell {
	my $this = shift;
	my $ok = 0;
	my $verbosity = $this->{verbosity};

	# Close the remote shell only if it is active
	if ($this->{isRemoteActive})
	{
		my $isSim = ($this->{localShellPrompt} eq $this->{remoteShellPrompt});
		print "=== Closing remote shell ===\n" if ($verbosity > 1);
		$operation = "close remote shell";

		#Clear out data specific to this
		$this->{isRemoteActive} = 0;
		$this->{remoteShellPrompt} = "";

		# Disconnect only if it is not a simulated remote session
		unless ($isSim)
		{
			sleep 2;			# pace the command
			$ok = $this->shellCmd("/s/dsc");
			sleep 4;			# pace the disconnect
			$this->{Telnet}->buffer_empty();
		}
		else
		{
			$ok = 1;
		}
		print "--- Remote Shell CLOSED ---\n" if ($verbosity > 1);

		# Get the old time out back
		$this->timeOut(pop @{$this->{timeOutStack}} );

	}
	else
	{
		carp "No remote shell open";
	}

	return $ok;
} # closeRemoteShell

# ----------------------------------------------------------------------------
# tl1Cmd: Execute a TL1 command
#
# Args:
#	IN: The command string
#	IN: <optional> Reference to an array to return the records found
#	IN: <optional> alternate time-out for command
#	OT: Records in the array whose reference was passed in
#
# Return:
#	1 if the command executed successfully
#	0 if the command was denied or we are not in a tl1 session
#
# ----------------------------------------------------------------------------
sub tl1Cmd {
	my ($this, $Cmd, $recs, $altTimeOut) = @_;
	my $verbosity = $this->{verbosity};
	my $ok = 0;

	if ($this->{isShellActive})
	{
		carp "No TL1 inside shell";
		return 0;
	}

	my @cmd = split(';', $Cmd);
	if ( @cmd  == 0 )
	{
		carp "blank command";
		return 0;
	}

	print "SEND TL1: $cmd[0]\n" if ($verbosity);
	$operation = $cmd[0];

	$this->{Telnet}->buffer_empty();
	$this->{Telnet}->print($cmd[0]);

	my %waitArgs = (Match => '/;/', Errmode => \&_timeoutErr);
	$waitArgs{'Timeout'} = $altTimeOut if defined $altTimeOut;

	my ($prematch, $match) = $this->{Telnet}->waitfor(%waitArgs);
	$ok = defined $match;

	# return failure if command is denied
	return 0 if ($prematch =~ /DENY/);

	# we are done if user does not care about output
	return $ok unless defined $recs;
	@$recs = ();		# Clear out the output array first

	# Skip processing output recs if there are none
	return 1 if ($prematch =~ /No records processed/);

	# Fill the output param as a list of lines
	my @PrematchRecs = split(/[\r\n]+/, $prematch);

	foreach (@PrematchRecs)
	{
		if ($_ =~ /\"/) {
			print "rcvd |$_|\n" if ($verbosity > 1);
			push (@{$recs},$_);
		}
	}

	return $ok;
}

# ----------------------------------------------------------------------------
# shellCmd: Execute a command on the local amp shell
#
# Args:
#	IN: The command string
#	IN: Reference to an array to return the records found
#	IN: <optional> alternate time-out for command
#	OUT: Lines of output generated by the command in the array whose ref was
#		 passed in
#
# Return:
#	1 if the command executed successfully
#	0 if the command was denied or we are not in a tl1 session
#
# ----------------------------------------------------------------------------
sub shellCmd {
	my ($this, $cmd, $recs, $altTimeOut) = @_;
	my $verbosity = $this->{verbosity};
	my $ok = 0;
	my ($prematch, $match) = (undef, undef);

	unless ($this->{isShellActive})	{
		carp "No shell session for cmd";
		return 0;
	}

	print $this->{localShellPrompt}, "$cmd\n" if ($verbosity);
	$operation = $cmd;

	$this->{Telnet}->buffer_empty();
	$this->{Telnet}->print($cmd);

	my %waitArgs = (Match => "/$this->{localShellPrompt}/",
					Errmode => \&_timeoutErr);
	$waitArgs{Timeout} = $altTimeOut if ($altTimeOut);

	# Sometimes the C7 can spit out a spurious prompt.  We need to make sure
	# the command itself is echoed first.
	$ok = $this->{Telnet}->waitfor(String => $cmd, ErrMode => \&_timeoutErr);
	
	# Wait for response now.
	($prematch, $match) = $this->{Telnet}->waitfor(%waitArgs);
	$ok &&= defined ($match);

	# done if user doesn't want output
	return $ok unless defined $recs;

	# Separate into individual lines
	my @PrematchRecs = split(/[\r\n]+/, $prematch);
	@$recs = ();		# Start with a null output

	# Include only non-blank response lines in the OUT param
	foreach (@PrematchRecs)	{
		if ($_ =~ /\S/) {
			print "rcvd \|\| $_|\n" if ($verbosity > 1);
			push (@{$recs},$_) ;
		}
	}

	return $ok;
}

# ----------------------------------------------------------------------------
# remoteCmd: Execute shell command on remote card
#
# Args:
#	IN: The command string
#	IN: Reference to an array to return the records found
#	IN: <optional> alternate time-out for command
#	IN: <optional> alternate prompt
#	OUT: Lines of output generated by the command in the array whose ref was
#		 passed in
#
# Return:
#	1 if the command executed successfully
#	0 if the command was denied or we are not in a tl1 session
#
# NOTE:
#  - Some godless shell commands do not return a prompt.
#    So, we allow the caller to specify an alternate string to look for to
#    determine end of command.  No regexps allowed.
# ----------------------------------------------------------------------------
sub remoteCmd
{
	my ($this, $cmd, $recs, $altTimeOut, $altPrompt) = @_;
	my ($prematch, $match);
	my $verbosity = $this->{verbosity};
	my $ok = 0;

	unless ($this->{isRemoteActive}) {
		carp "No remote session for cmd";
		return 0;
	}
	unless ($cmd) {
		carp "No cmd specified?";
		return 0;
	}

	# Just for debugging
	print $this->{remoteShellPrompt}, "$cmd\n" if ($verbosity);
	$operation = $cmd;

	# Set the termination criteria appropriately
	my $matchop = "/$this->{remoteShellPrompt}\$/";

	$this->{Telnet}->buffer_empty();
	$this->{Telnet}->print($cmd);

	# Set the wait-for args
	my %waitArgs = (ErrMode => \&_timeoutErr);
	if ($altPrompt)	{
		$waitArgs{String} = $altPrompt;
	} else	{
		$waitArgs{Match} = $matchop;
	}

	$waitArgs{Timeout} = $altTimeOut if ($altTimeOut);

	# Sometimes the C7 can spit out a spurious prompt.  We need to make sure
	# the command itself is echoed first.
	$ok = $this->{Telnet}->waitfor(String => $cmd, ErrMode => \&_timeoutErr);
	
	# Wait for response now.
	($prematch, $match) = $this->{Telnet}->waitfor(%waitArgs);
	$ok &&= defined ($match);

	# done if user doesn't want output
	return $ok unless defined $recs;

	# Separate into individual lines
	my @PrematchRecs = split(/[\r\n]+/, $prematch);
	@$recs = ();		# Start with a null output

	# Include only non-blank response lines after the cmd in the OUT param
	foreach (@PrematchRecs)	{
		if ($_ =~ /\S/)	{
			print "rcvd \|\|\|$_|\n" if ($verbosity > 1);
			s/$this->{localShellPrompt}//g;	# Remove spurious local shell prompts
			push (@{$recs},$_);
		}
	}

	return $ok;
} # remoteCmd()

# ----------------------------------------------------------------------------
# timeOut: retrieve/set the timeout duration for this session
#
#  This function is a facade.  It calls the timeout function of the underlying
# telnet object
#
# Args:
#	Argument, if specified, is the number of seconds the new time out should be
#
# Return:
#	The previous value of timeout if args are specified
#	The current value of timeout if no args specified
#
# ----------------------------------------------------------------------------
sub timeOut
{
	my $this = shift;
	$this->{Telnet}->timeout(@_);
} # timeOut






sub _timeoutErr {
	warn "failed - timed out waiting for response to '$operation'\n";
}

sub _ignore {
	print "timed out waiting for response to '$operation'\n";
}

sub time {
	my ($Sec, $Min, $Hour, $MDay, $Mon, $Year, $WDay, $YDay, $isdst);

	($Sec, $Min, $Hour, $MDay, $Mon, $Year, $WDay, $YDay, $isdst) = localtime;
	$Year += 1900;
	return "$Mon-$Year-$MDay-$Hour-$Min-$Sec";
}

sub computeForgottenPassword {
	my $this = shift;
	my $date = shift;
	my $sid = shift;

	my ($da,$db,$dc) = $date =~ /(\d+)-(\d\d)-(\d\d)/;
	if( (length $da) == 2 )
	{
		if($debug) {
			print "changing date format from \"$date\" to ";
		}
		$date = "20$da-$db-$dc";
		if($debug) {
			print "\"$date\"\n";
		}
	}

	if (!$date || !$sid) {
		if($debug) {
			print STDERR "computeForgottenPassword: invalid arguments";
		}
		return "c7support";
	}


	#
	# the sid may have embedded spaces (which aren't valid
	# password characters), or other characters to mask,
	# so we replace them with '#'
	#
	$sid =~ tr/ /#/; 

	#
	# We use HTTP::Date because it offers a str2time() method
	#
	# HTTP::Date is nice because it gives 1-based output and
	# doesn't give years since 1900.  However, it doesn't provide
	# day of week, so I resort to localtime() for that.
	#
	# localtime returns the following array:
	#
	#     0    1    2     3     4    5     6     7     8
	#  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) 
	#

	my ($year, $month, $day) = HTTP::Date::parse_date( $date );
	my $time = HTTP::Date::str2time( $date );
	my @tmp = localtime($time);
	my $wday = $tmp[6] + 1;  # we use Sunday = 1, localtime returns Sunday = 0
	my $yday = $tmp[7] + 1;  # also 0-based from localtime

	my ($a,$b,$c,$d,$e);

	if ($this->{version} <= 4.0) {
		my $sum_year = $this->_addDigits($year);
		$a = $this->_multiplyAndExtractLastTwoChars($sum_year, $day);
		$b = $this->_multiplyAndExtractLastTwoChars($sum_year, $month);
		$c = $this->_multiplyAndExtractLastTwoChars($day, $month);
		$d = $this->_getCharModulo($wday, $sid);
		$e = $this->_getCharModulo($month, $sid);
	} elsif ($this->{version} >= 4.1) {
		my $x = $this->_addDigits($year * $yday * (length $sid) + $wday);

		$a = $this->_multiplyAndExtractLastTwoChars($x, $day);
		$b = $this->_getCharModulo($yday, $sid);
		$c = $this->_multiplyAndExtractLastTwoChars($x, $month);
		$d = $this->_getCharModulo($wday, $sid);
		$e = $this->_multiplyAndExtractLastTwoChars($x, $yday);
#		print "x=$x, yday = $yday, day=$day, wday=$wday, month=$month, sidlen=";
#		print length $sid;
#		print "\n";
	}

	return $a . $b . $c . $d . $e ;
}

#
# return the (mod)th character in the passed string
#
sub _getCharModulo {
	my ($this, $mod, $sid) = @_;

	my $len = length $sid;

	while ( $mod > $len ) {
		$mod -= $len;
	}
	$mod--;  	# zero based

	my @sid = split('', $sid);
	return $sid[$mod];
}
	
sub _multiplyAndExtractLastTwoChars  {
	my ($this, $a, $b) = @_;

	my $n = $a * $b;
 
	return 
		 length $n == 1 ? $n.$n : substr($n, -2, 2);
}

sub _addDigits  {
	my ($this, $n) = @_;

	my $x = 0;
	my @n = split('', $n);
	foreach (@n) {
		$x += $_;
	}

	return $x;
}

sub _getDateAndSid {
    my $this  = shift;

	#
	# get a prompt 
	#
	$operation = "tl1 prompt";
	$this->{Telnet}->buffer_empty();
	$this->{Telnet}->print("");
	$this->{Telnet}->waitfor(Match => '/>/', Errmode => \&_timeoutErr);

	#
	# rtrv-hdr (don't need to be logged in)
	#
	my $cmd = "rtrv-hdr";
	$operation = $cmd;
	$this->{Telnet}->buffer_empty();
	$this->{Telnet}->print($cmd);
	my ($prematch, $match) = $this->{Telnet}->waitfor(Match => '/;/', 
												   Errmode => \&_timeoutErr);

	#
	# Ugly hack to get at the date and sid.
	# The sid may have spaces
	#
	print "GOT:\n|$prematch|\n" if ($debug);
	# my @s = split (/[\n\r]+/, $prematch);
	# chomp @s;
	# my $line = "";

	# for (@s) {
		# if ( /.*\d+:\d+:\d+/ ) {
			# $line = $_;
			# last;
		# }
	# }

	# die "trouble parsing rtrv-hdr" if ( $line eq "" ) ;

	# $line =~ s/^\s+//;
	# my @fields = split(/\s+/, $line);
	# my $date = $fields[-2];
	# my $sid = $fields[0];
	# my $max = @fields - 3;
	# foreach (1 .. $max) {
	  # $sid = $sid . " " . $fields[$_];
	# }
	my ($sid, $date) = $prematch =~ /^\s+(\S.+)\s+([0-9][0-9]?\-[0-9][0-9]?\-[0-9][0-9]?)\s+[0-9][0-9]?:[0-9][0-9]?:[0-9][0-9]?\s*$/m;
	
	return ($date, $sid);
}

1;
