#!/usr/bin/env bash

# scrutiny.sh
# Server report collection containing processes, resource usage, networking,
# apache, and mysql to be used for point in time troubleshooting.
#
# Copyright (c) 2012, Stephen Lang
# All rights reserved.
#
# Git repository available at:
# https://github.com/stephenlang/scrutiny
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


# Enable / Disable Statistics
process_log=on
resource_log=on
network_log=on
mysql_log=on
apache_log=on
nginx_status=off


# Retention Days
retention=2


# Logs
basedir=/var/log/scrutiny


# Environment specific variables
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
date=`date +%F--%T`
lockdir=/tmp/scrutiny.lock


# Sanity Checks
if [ ! `whoami` = root ]; then
	echo "This script must be ran by the user:  root"
	exit 1
fi

if [ ! -f /usr/local/bin/lynx ]; then
	echo "This script requires lynx to be installed if"
	echo "apache_log=on.  Please install lynx or disable"
	echo "apache_log."
	exit 1
fi

if [ -d $lockdir ]; then
	echo "Lock file exists.  Please confirm that scrutiny"
	echo "is not still running.  If all is well, manually"
	echo "remove lock by running:  rm -rf $lockdir"
	exit 1
else
	/bin/mkdir $lockdir
fi

if [ ! -d $basedir ]; then
	mkdir $basedir
	chmod 700 $basedir
fi


# Clear logs

find $basedir/* -mtime +$retention -exec rm {} \;


# Process Information

if [ $process_log = on ]; then
cat << EOF >> $basedir/process.log.$date
---------------------------------------------------------------
Processes
---------------------------------------------------------------

- Description:  Display all running processes
- Command:  ps auxww
`ps auxww`

EOF
fi


# Resources 

if [ $resource_log = on ]; then
cat << EOF >> $basedir/resource.log.$date
---------------------------------------------------------------
System Resources
---------------------------------------------------------------

- Description:  Show system uptime
- Command:  uptime
`uptime`

- Description:  Top 10 processes (by CPU usage)
- Command:  ps -auxwwr | head -11
`ps -auxwwr | head -11`

- Description:  Top 10 processes (by Memory usage)
- Command:  ps auxwwm | head -11
`ps auxwwm | head -11`

- Description:  Show memory and swap usage
- Command:  top -d1 | grep -A1 '^Mem:'
`top -d1 | grep -A1 '^Mem:'`

- Description:  Show disk space usage
- Command:  Output of command:  df -hl
`df -hl`

- Description:  Show kernel stats about cpu, mem, io, trap, etc
- Command:  vmstat 1 5
`vmstat 1 5`
        
- Description:  Display kernel I/O stats
- Command:  iostat 1 2
`iostat 1 2`

EOF
fi


# Networking

if [ $network_log = on ]; then
cat << EOF >> $basedir/network.log.$date
---------------------------------------------------------------
Networking Snapshot
---------------------------------------------------------------

- Description:  Displays current network connections
- Output of command:  netstat -nat
`netstat -nat`

- Description:  Displays network traffic summary
- Command:  netstat -s
`netstat -s`

EOF
fi


# MySQL

if [ $mysql_log = on ]; then
cat << EOF >> $basedir/mysql.log.$date
---------------------------------------------------------------
MySQL Snapshot
---------------------------------------------------------------

- Description:  Prints the output of mysqladmin status
- Command:  mysqladmin status
`mysqladmin status`

- Description:  Shows currently running queries in MySQL
- Command:  mysqladmin -v processlist
`mysqladmin -v processlist` 

EOF
fi


# Apache

if [ $apache_log = on ]; then
cat << EOF >> $basedir/apache.log.$date
---------------------------------------------------------------
Apache Snapshot
---------------------------------------------------------------

- Description:  Shows what Apache was currently doing
- Command:  apachectl fullstatus
`apachectl fullstatus`

EOF
fi


# Nginx

if [ $nginx_log = on ]; then
cat << EOF >> $basedir/nginx.log.$date
---------------------------------------------------------------
Nginx Snapshot
---------------------------------------------------------------

- Description:  Shows what Nginx was currently doing
- Command:  lynx -dump http://localhost/nginx_status
`lynx -dump http://localhost/nginx_status`

EOF
fi


# Clear Lock
rm -rf $lockdir
