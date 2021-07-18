#!/usr/bin/perl -w

use warnings;
no warnings 'once';
use strict;

use utf8;
use open qw(:std :utf8);
use open IO => ':encoding(utf8)';
binmode(STDOUT,':utf8');

use CGI qw(:all);
use Email::Valid;
use JSON;
use DBI;

$|++;

my $CFG_DB = 'local_settings.json';	# must be installed
my $SESSION = 'default'; # 'meslogDB'

# Переменные формы
my $query=new CGI;

my $searchstr = $query -> param('searchstr') || '';

# Передаём клиенту
print header( -type=>'text/html', -charset=>'UTF-8');
print <<EOF;
<!doctype html>
<html>
<head>
<title>meslogDB search</title>
<link rev="made" href="mailto:an.gorohovski%40gmail.com" />
<meta name="content" content="no-cache" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body bgcolor="white">
<h2>Search Result for '$searchstr'</h2>
EOF

for( $searchstr ){
	s/\s+//g;
	s/^(\S{128}).*/$1/;	# Ограничение на длину строки поиска (в 128 символов)
}

# Проверка email
my $email = &valid_email( $searchstr );
if( $email ){

	# Read DataBase configurations
	my( $dbh ) = &read_configDB( $SESSION, $CFG_DB );

	&summary( $dbh, $email );

}else{
	print <<EOF;
<center>
	<h3>Nothing found: empty email</h3>
</center>
EOF
}

	print <<EOF;
<center>
	<a href="/"
style="background-color:green;
	border:none;
	color:white;
	padding: 15px 32px;
	text-align:center;
	cursor:pointer;
	font-size:1.3em;
	text-decoration:none;
	font-family:Arial;">Repeat search</a>
</center>
<br />
</body></html>
EOF

exit;


sub summary {
	my( $dbh, $email ) = @_;

	$email = $dbh->quote( $email );

	my @ids;
	my $sth_data = $dbh->prepare(qq{ SELECT SQL_CALC_FOUND_ROWS created, int_id, flag, str FROM log 
WHERE address = $email ORDER BY int_id, created LIMIT 100 } );
	$sth_data->execute;

	my $n_rows = $dbh->selectrow_array( qq{ SELECT FOUND_ROWS() } );
	unless( $n_rows ){
		print "<center><h3>Nothing found</h3></center>";
		return;
	}

	print <<EOF;
<h3>From 'log' table</h3>
<table style="border: 1px solid black;"><tr><th>#</th><th>Timestamp</th><th>Flag</th><th>Log entry</th></tr>
EOF

	while( my( $created, $int_id, $flag, $str ) = $sth_data->fetchrow_array() ) {
		push @ids, $int_id;

		print "<tr>", (map "<td>$_</td>", (~~@ids, $created, $flag, $str)), "</tr>\n";
	}
	print "</table><br /> all entries = $n_rows<br />";

	my $i;
	for my $int_id ( @ids ){

		my $sth_data = $dbh->prepare(qq{ SELECT SQL_CALC_FOUND_ROWS
created, str FROM message WHERE int_id="$int_id" ORDER BY created LIMIT 100 } );
		$sth_data->execute;

		$n_rows = $dbh->selectrow_array( qq{ SELECT FOUND_ROWS() } );
		next unless $n_rows;

		unless( $i ){
			print <<EOF;
<br />
<h3>From 'message' table</h3>
<table style="border: 1px solid black;"><tr><th>#</th><th>Timestamp</th><th>Flag</th><th>Log entry</th></tr>
EOF
		}

		while( my( $created, $str ) = $sth_data->fetchrow_array() ) {
			print "<tr>", (map "<td>$_</td>", (++$i, $created, '<=', $str)), "</tr>\n";
		}
	}
	print "</table><br /> all entries = $i<br />" if $i;

}


sub read_configDB
{
	my( $session, $cfgs ) = @_;

	# Read DataBase configuration
	my $json_set = do {
		open( my $json_fh, $cfgs )
			or die "\x1b[31mERROR\x1b[0m: Can't open $cfgs file: $!";

		local $/;
		<$json_fh>;
	};

	my $ref = decode_json( $json_set );
	die "\x1b[31mERROR\x1b[0m: No DB settings exist: $!"
		if !exists( $ref->{'DATABASES'} ) or !exists( $ref->{'DATABASES'}{ $session } );

	my $db_name  = $ref->{'DATABASES'}{ $session }{'NAME'}   || 'meslogDB';
	my $user     = $ref->{'DATABASES'}{ $session }{'USER'};
	my $password = $ref->{'DATABASES'}{ $session }{'PASSWORD'};
	my $host     = $ref->{'DATABASES'}{ $session }{'HOST'}   || 'localhost';
	my $engine   = $ref->{'DATABASES'}{ $session }{'DBI'}    || 'DBI:mysql:database';
	my $port     = $ref->{'DATABASES'}{ $session }{'PORT'}   || 3306;

	my $dbh = DBI->connect("$engine=$db_name;host=$host;port=$port", $user, $password,
						{ RaiseError => 0, PrintError => 1, AutoCommit => 1} );

	return( $dbh );
}


# Проверка email на полное доменное имя (default), и допустимость адресов вида guest@[127.0.0.1]
sub valid_email {
	my ( $e ) = @_;

	my $email;
	eval {
		$email = Email::Valid->address(
			-address => $e,
			-allow_ip => 1,
			-localpart => 1,
			-fqdn => 1,
		);
	} or do {
#		print ERRLOG "$e is WRONG: $@\n" if $@;
	};

   $email;
}

