#!/usr/bin/perl
# ======================================================================
#
# Perl Source File -- Created with SAPIEN Technologies PrimalScript 3.1
#
# NAME: check_mssql_sproc.pl
#
# AUTHOR: Jeremy D. Pavleck , Capella University <jeremy@pavleck.com>
# DATE  : 10/25/2005
#
# PURPOSE: Runs a stored proc on a remote MS SQL server and returns the
#          result. Then logic is applied to determine if there is an error
#          condition or not.
# AUTHOR: Bruno Cardoso Cantisano <bruno.cantisano@gmail.com>
# DATE  : 04/25/2017
# DATE  : 12/14/2017: Adding custom html page
# DATE  : 05/04/2018: Fixing html. It's not using anymore a file to 
# assemble the html
# DATE  : 14/06/2018: Changing ODBC version
#
# PURPOSE: Updated to allow input parameters and format the results in HTML.
# ======================================================================
use DBI;
use Getopt::Long;
use HTML::Entities;
use Encode;

my ($hardcoded, $sql_user, $sql_pass);
# If you have a universal 'support' login for MS SQL server, set $hardcoded to 1
# and then set the SQL username and password.
$hardcoded = 0;
$sql_user = "";
$sql_pass = "";

my ($opt_h, $opt_proc, $opt_host, $opt_user, $opt_pw, $opt_c, $opt_w, $opt_ver);
Getopt::Long::Configure('bundling');
GetOptions(
           "h"   => \$opt_h, "help"  => \$opt_h,
           "p=s"   => \$opt_proc,  "procedure=s"  => \$opt_proc,
           "H=s"   => \$opt_host,  "hostname=s"  => \$opt_host,
           "d=s"   => \$opt_db,    "database=s"  => \$opt_db,
           "u=s"   => \$opt_user,  "user=s"  => \$opt_user,
           "P=s"   => \$opt_pw,    "password=s"  => \$opt_pw,
           "c=s"   => \$opt_c,     "critical=s"  => \$opt_c,
           "w=s"   => \$opt_w,     "warning=s"  => \$opt_w,
           "v"     => \$opt_ver,    "version"  => \$opt_ver,
);

if ($opt_h) {
    print_help();
    exit;
}

if ($opt_ver) {
        print_version();
        exit;
}

if ($hardcoded) {
        $opt_user = $sql_user;
        $opt_pw = $sql_pass;
        }

if ($opt_host eq "" or $opt_proc eq "" or $opt_db eq "" or $opt_user eq "" or $opt_pw eq "" or $opt_c eq "" or $opt_w eq "") {
print "ERROR: Mandatory arguments -H, -u, -P, -d, -p, -c and -w are required.\n";
print "Please see '$0 --help' for addtional informaton\n";
exit;
}

my $conn;

$conn{"username"} = $opt_user;
$conn{"server"} = $opt_host;
$conn{"password"} = $opt_pw;
$conn{"dsn"} = "dbi:ODBC:Driver={ODBC Driver 17 for SQL Server};SERVER=" . $conn{"server"};
$conn{"dbh"} = DBI-> connect( $conn{"dsn"}, $conn{"username"}, $conn{"password"})
        or die "Error: Unable to connect to MS-SQL database!\n", $DBI::errstr,"\n";

$paramsProc = join("", split(/[aA-zZ]|[0-9]|"/, $opt_proc, -1));
$paramsProc = substr $paramsProc, 2, length($paramsProc)-2;
$paramsProc =~ s/ /?/g;

my $sql = qq{ use $opt_db exec $opt_proc };
my $sth = $conn{"dbh"}->prepare( $sql );

$sth->{"LongReadLen"} = 0;
$sth->{"LongTruncOk"} = 1;

$sth->execute();

my $ref;
my $results = "";
my $info = "";

#Get columns name from query
$i = 1;
my $colNames = $sth->{NAME};
foreach my $colName ( @{$colNames}) {
   if($i > 1) {
     $info .= encode('utf-8', $colName) . '↔';
   }
   $i = $i + 1;
}
$info .= '∟';

#Get fields from query
while($ref = $sth->fetchrow_arrayref) {
    $i = 1;
    foreach my $field ( @{ $ref } ) {
        if($i > 1){
            $info .= ($field ? $field : "-") . '↔';
        }
        else {
            #codigo de retorno
            $results = $field;
        }
        $i = $i + 1;
    } 
    $info .= '∟';
}

#descriptions: ←-alt+27 (header), ∟-alt+28 (line) and ↔-alt+29 (row)
$table = 'header←' . $opt_proc . '←label_#LABEL#←#TYPE#←' . $results . '←'. $info;

process_results($results);

$sth->finish();
$conn{"dbh"}->disconnect();

sub process_results {
    #removing breaklines, tabs and two or more spaces
    $table =~ s/\n|\r|\t|\s{2,}//g;
    if($results >= $opt_c) {
        print_critical($results);
    }
    elsif($results >= $opt_w) {
        print_warning($results);
    }
    else {
        print_ok($results); 
    }
}

sub print_ok($results) {
    $table =~ s/#LABEL#/ok/g;
    $table =~ s/#TYPE#/OK/g;

    print $table;
    exit 0;
}

sub print_warning($results) {
    $table =~ s/#LABEL#/aviso/g;
    $table =~ s/#TYPE#/WARNING/g;

    print $table;
    exit 1;
}

sub print_critical($results) {
    $table =~ s/#LABEL#/erro/g;
    $table =~ s/#TYPE#/CRITICAL/g;

    print $table;
    exit 2;
}


sub print_help {
    print "Usage: $0 -H HOSTNAME -p PROCEDURE -d database -u user -P password -w <warn> -c <crit>\n";
    print "

    $0 1.01
    Copyright (c) 2005 Jeremy D. Pavleck <jeremy\@pavleck.com>
    This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

-p, --procedure
        Stored procedure to execute
-H, --hostname
        Hostname of database server
-d  --database
        Database to run Stored Procedure against
-u, --user
    SQL Username
-P, --password
    SQL Password
-c, --critical
        Value at which when met or exceeded will send a critical alert
-w, --warning
        Value at which when met or exceeded (but is lower then critical value) will send a warning alert.
-h, --help
        Display detailed help
-v, --version
    Show version information

    This program will connect to a remote MS SQL server, execute a stored procedure, and then process the results
    to determine if there is an error state or not.
    Currently it only works if the stored procedure returns a single result in one column. It has not been tested
    to work with any other result sets; There is currently a sister script which DOES handle these things, as well as
    boolean and word results. It should be available shortly.
    Additional Notes & Tips: If you don't wish to have your SQL passwords exposed to the world you can do one of two
    things - 1. Set \$USERx\$ in resource.cfg to the password - this will be passed to the program by Nagios, but will
    not be visible from the web console or 2. If you have a universal SQL login for all of your Nagios queries, then
    you may hardcode the username & password into the beginning of this script.


    Send email to jeremy\@pavleck.com or nagios-users\@lists.sourceforge.net if you have questions regarding the use of this
    software. To submit patches or suggest improvements, please email jeremy\@pavleck.com or visit www.Pavleck.com";
}

sub print_version {
    print "
    $0  version 1.01 - October 28th, 2005
    Copyright (c) 2005 Jeremy D. Pavleck <jeremy\@pavleck.com>
    This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.";
}
