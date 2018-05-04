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

# Usage
 * In Sql Server, create this procedure: checaTabProcessos.sql
 * Insert these lines inside <head></head> tag in main html.
```
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.0/jquery.min.js"></script>
<LINK REL='stylesheet' TYPE='text/css' HREF='stylesheets/style.css' />
``` 
 * Copy sproc_html\assets\css\style.css to nagios stylesheets folder.
 * Copy sproc_html\imgs\* to nagios images folder.
 * Running:

```bash
./check_mssql_sproc_parameters.pl -H 127.0.0.1 -u sa -P MyPass -d MyDb -p checaTabProcessos -c 2 -w 1
```

commands.cfg:

![ScreenShot](commands.png?raw=true)

services.cfg:

![ScreenShot](services.png?raw=true)
