use Net::Telnet;
$telnet = new Net::Telnet ( Timeout=>10,
Errmode=>'die');
$telnet->open('10.208.45.1');
$telnet->waitfor('/>/');	# the literal >
print $output
$telnet->print('act-user::c7support:::c7support;');
$telnet->waitfor('/>/');
print $output
$telnet->print('rtrv-shelf::all');
$output = $telnet->waitfor('/\$ $/i');
print $output;


