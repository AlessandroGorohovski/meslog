#!/usr/bin/perl -w

use strict;
use warnings;

use File::Spec;
use Getopt::Long;
use Email::Valid;
use JSON;
use DBI;

my $VERSION = '0.01';

###
# Default Options
my $ERRLOG = 'filling_meslogDB.errors';
my $CFG_DB = 'local_settings.json';
my $SESSION = 'default'; # 'meslogDB'
my $VERBOSE;
my $HELP;

###
my $START_TIME = time;

###
# Parse input data
GetOptions(
	'errlog=s'   => \$ERRLOG,
	'cfg_db=s'   => \$CFG_DB,
	'session=s'  => \$SESSION,
	'verbose'    => \$VERBOSE,
	'help'       => \$HELP,
) or &usage();

&usage() if $HELP;

my $infile = $ARGV[0] || &usage('LOG file not specified for processing!');

print "\nInput log-records will be read from file: \x1b[1m $infile \x1b[0m\n";

# Read DataBase configurations
my( $dbh ) = &read_configDB( $SESSION, $CFG_DB );

my $save_db = &SaveDB;

open ERRLOG, ">$ERRLOG" or &usage("Can't open $ERRLOG: $!");

my $i;
open INFILE, $infile or &usage("Can't found $infile: $!");
while(<INFILE>){
	s/^\s+|\s+$//g;
	next if /^$/ || /^\D/;
=comment
# dt       tm       int_id           flag address   @oth
# 1------- 2------- 3--------------- 3-   4------   5---
2012-02-13 14:39:22 1RwtJa-000AFB-07 => :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router
2012-02-13 14:39:22 1RwtJa-000AFB-07 Completed

2012-02-13 14:39:22 1RookS-000Pg8-VO == udbbwscdnbegrmloghuf@london.com R=dnslookup T=remote_smtp defer (-44): SMTP error from remote mail server after RCPT TO:<udbbwscdnbegrmloghuf@london.com>: host mx0.gmx.com [74.208.5.90]: 450 4.3.2 Too many mails (mail bomb), try again in 1 hour(s) 25 minute(s) and see ( http://portal.gmx.net/serverrules ) {mx-us011}
2012-02-13 14:39:22 1RookS-000Pg8-VO ** fwxvparobkymnbyemevz@london.com: retry timeout exceeded

2012-02-13 14:39:22 1RwtJa-0009RI-2d <= tpxmuwr@somehost.ru H=mail.somehost.com [84.154.134.45] P=esmtp S=1289 id=120213143629.COM_FM_END.205359@whois.somehost.ru
2012-02-13 14:39:22 1RwtJa-000AFJ-3B <= <> R=1RookS-000Pg8-VO U=mailnull P=local S=3958

2012-02-13 14:39:57 1RwtJY-0009RI-E4 -> ldtyzggfqejxo@mail.ru R=dnslookup T=remote_smtp H=mxs.mail.ru [94.100.176.20] C="250 OK id=1RwtK9-0004SS-Fm"
2012-02-13 14:39:57 1RwtJY-0009RI-E4 => eqkhojhkgag@rambler.ru R=dnslookup T=remote_smtp H=imx1.rambler.ru [81.19.66.235] C="250 2.0.0 Ok: queued as 8512E1767A67"

2012-02-13 14:39:50 SMTP connection from [109.70.26.4] (TCP/IP connection count = 1)

=cut
	my $s = $_;
	my( $dt, $tm, $int_id, $flag, $address, @oth ) = split /\s+/;

	if( $tm =~/^\D/ or
		 $int_id !~/^\d\w{5}\-\d\w{5}\-\w\w$/ or
		 $flag =~/^Completed$/i )
	{
		print ERRLOG "DROPPED	$s\n";
		next;
	}

	my $log_str = $dbh->quote( join ' ', $address, @oth );

	my @qqu = ( qq{created="$dt $tm"}, qq{int_id="$int_id"}, qq{str = $log_str} );

	my $table;
	if( $flag eq '<='){

		my $f;
		for( $address, @oth ){
			next unless /^id=(\S+)/;

			push @qqu, qq{id="$1"};
			++$f;
			last;
		}

		unless( $f ){
			print ERRLOG "EMPTY_ID	$s\n";
			next;
		}

		$table = 'message';

	}else{
		push @qqu, $flag=~/(=>|\->|\*\*|==)/ ? qq{flag="$1"} : qq{flag='NA'};

		# Проверка email
		my $email = &valid_email( $address );
		push @qqu, qq{address="$email"} if $email;

		$table = 'log';
	}

	print $i++, "	$dt $tm $int_id\n" if $VERBOSE;

	next unless $save_db;

	my $qu = join ', ', @qqu;
	$dbh->do( qq{ INSERT INTO $table SET $qu} ) or warn $dbh->errstr;

}
close INFILE;

$dbh->disconnect;

print "\n# Elapsed time: ".(time - $START_TIME)." sec\n" if $VERBOSE;

exit;


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
		print ERRLOG "$e is WRONG: $@\n" if $@;
	};

    $email;
}


sub SaveDB {
	my $save_db = 1;	# 1=save into DB

	while( 1 ){
		last unless $save_db;

		print"Do You want save/update info DB (\x1b[31;1m y\x1b[0m or \x1b[32;1m n\x1b[0m )? ";
		$_ = <STDIN>;
		last if /^y(?:es)?/i;
		$save_db = 0 if /^no?/i;
	}

	$save_db;
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


sub usage
{
	my( $msg ) = @_;

	$msg = $msg ? "\x1b[31mERROR\x1b[0m: $msg\n" : '';
	my $script = "\x1b[32m" . File::Spec->splitpath($0) . "\x1b[0m";

	my $text = "$msg
$script version $VERSION

DESCRIPTION:
    Fills 'message', and 'log' tables of 'meslogDB' database (default)
    from <file.log> file


USAGE:
    $script <file.log> [OPTIONS]

EXAMPLE:
    $script mailog.out -v

HERE:
    <file.log>   -- input LOG file only

OPTIONS:
    --errlog     --  Save ERROR log file. By default, 'filling_meslogDB.errors'
    --cfg_db     --  DB configuration file. By default, 'local_settings.json'
    --session    --  session name/key in the DB configuration file. By default, 'meslogDB'
    --verbose    --  output echo messages
    --help

NOTES:
  A configuration DB file 'local_settings.json' (or specified by --cfg_db) is required.
";

	die $text;
}

