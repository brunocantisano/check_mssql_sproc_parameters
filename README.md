# check_mssql_sproc_parameters plugin
Nagios plugin for executing procedures with input parameters to MS SQL Server

Executing procedures in mssql server with parameters, formatting results in HTML.
ps.: It uses only input parameters, output parameteres are not considered.

Uses the original code from:
AUTHOR: Jeremy D. Pavleck , Capella University <jeremy@pavleck.com>
DATE  : 10/25/2005

Update:
AUTHOR: Bruno Cardoso Cantisano <bruno.cantisano@gmail.com>
DATE  : 04/25/2017
PURPOSE: Updated to allow input parameters and format the results in HTML.

The original code works with procedures that only return one column, but
does not allow parameters. If the procedure returns more than one column also
doesn't work. This code update fixes this problem, but the procedure
must return the first column as an int (procedure return) called "retorno".

# Prerequisites
 * Microsoft ODBC Driver 17 for SQL Server
 - RedHat Enterprise Server 6 and 7

```bash
sudo su

#Download appropriate package for the OS version
#Choose only ONE of the following, corresponding to your OS version

#RedHat Enterprise Server 6
curl https://packages.microsoft.com/config/rhel/6/prod.repo > /etc/yum.repos.d/mssql-release.repo

#RedHat Enterprise Server 7
curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/mssql-release.repo

exit
sudo yum remove unixODBC-utf16 unixODBC-utf16-devel #to avoid conflicts
sudo ACCEPT_EULA=Y yum install msodbcsql17
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA=Y yum install mssql-tools
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
# optional: for unixODBC development headers
sudo yum install unixODBC-devel
```
 - Ubuntu 14.04, 16.04 and 17.10

 ```bash
sudo su 
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

#Download appropriate package for the OS version
#Choose only ONE of the following, corresponding to your OS version

#Ubuntu 14.04
curl https://packages.microsoft.com/config/ubuntu/14.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

#Ubuntu 16.04
curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list

#Ubuntu 17.10
curl https://packages.microsoft.com/config/ubuntu/17.10/prod.list > /etc/apt/sources.list.d/mssql-release.list

exit
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install msodbcsql17
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA=Y apt-get install mssql-tools
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
# optional: for unixODBC development headers
sudo apt-get install unixodbc-dev
``` 
 * Follow these steps to create a valid user to execute the procedure:
-Configuration
In Opsview Monitor, add your Microsoft SQL Database as a Host and apply the Host Template "Database - Microsoft SQL" to that host.
1.	Create a new "SQL Authentication user" on the server you are monitoring by logging into the "Microsoft SQL Server Management Studio", and navigating to "localhost> Security >Logins" and right clicking on Logins and selecting "New Login…".
2.	Populate the sections as below:
GENERAL: create a new login name (username), and change to "SQL Server Authentication". Enter a password (must be complex, ex. numbers and upper case characters) and then remove "Enforce password expiration and "user must change password at new login". 
SERVER ROLES: Select "public" and "sysadmin". Ex.: user `monitor` and password `MyPass`
USER MAPPING: Leave as default. 
SECURABLES: Click "Search..", select "All objects of the types...", and then "Servers" and click OK. Then scroll down the lists to find the permission titled "View server state", and check "Grant". 
STATUS: Ensure "Grant" and "Enabled" are checked respectively.
 * configure /etc/odbc.ini
```bash
[MyMSSQLServer]
Driver=ODBC Driver 17 for SQL Server
Server=192.168.0.30
Port=1433
Database=MyDb
Driver=/opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.1.so.0.1
UsageCount = 1

[Default]
Driver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so
``` 
 * configure /etc/odbcinst.ini
```bash
[ODBC Driver 17 for SQL Server]
Description=Microsoft ODBC Driver 17 for SQL Server
Driver=/opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.1.so.0.1
UsageCount=2

[ODBC]
Trace=No
TraceFile=/tmp/odbc.log
UsageCount=2

[FreeTDS]
Description=FreeTDS
Driver=/usr/lib/x86_64-linux-gnu/odbc/libtdsodbc.so
Setup=/usr/lib/x86_64-linux-gnu/odbc/libtdsS.so
UsageCount=2
``` 
 * configure `/etc/freetds/freetds.conf`
```bash
#   $Id: freetds.conf,v 1.12 2007/12/25 06:02:36 jklowden Exp $
#
# This file is installed by FreeTDS if no file by the same
# name is found in the installation directory.
#
# For information about the layout of this file and its settings,
# see the freetds.conf manpage "man freetds.conf".

# Global settings are overridden by those in a database
# server specific section
[global]
        # TDS protocol version
;       tds version = 4.2

        # Whether to write a TDSDUMP file for diagnostic purposes
        # (setting this to /tmp is insecure on a multi-user system)
;       dump file = /tmp/freetds.log
;       debug flags = 0xffff

        # Command and connection timeouts
;       timeout = 10
;       connect timeout = 10

        # If you get out-of-memory errors, it may mean that your client
        # is trying to allocate a huge buffer for a TEXT field.
        # Try setting 'text size' to a more reasonable limit
        text size = 64512

# A typical Sybase server
[egServer50]
        host = symachine.domain.com
        port = 5000
        tds version = 5.0

# A typical Microsoft server
[egServer70]
        host = ntmachine.domain.com
        port = 1433
        tds version = 7.0

# A typical Microsoft server
[MyMSSQLServer]
  database = MyDb
  host = 192.168.0.30
  port = 1433
  tds version = 7.0
  client charset = UTF-8
```
 * test settings (considering dsn: `MyMSSQLServer`, user: `monitor` and password: `MyPass`):
```bash
isql -v MyMSSQLServer monitor MyPass
```
# Usage
 * In Sql Server, create this procedure: checaTabProcessos.sql
 * Insert these lines inside <head></head> tag in main html.
```
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.0/jquery.min.js"></script>
<LINK REL='stylesheet' TYPE='text/css' HREF='stylesheets/style.css' />
``` 
 * Copy `sproc_html\assets\css\style.css` to nagios stylesheets folder.
 * Copy `sproc_html\imgs\*` to nagios images folder.
 * Running:

 ```bash
./check_mssql_sproc_parameters.pl -H 127.0.0.1 -u monitor -P MyPass -d MyDb -p checaTabProcessos -c 2 -w 1
```

commands.cfg:

![ScreenShot](commands.png?raw=true)

services.cfg:

![ScreenShot](services.png?raw=true)
