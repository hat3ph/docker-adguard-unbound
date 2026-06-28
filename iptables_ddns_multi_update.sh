#!/bin/bash

# create /etc/cron.d/iptables_ddns_multi_update with below line...
#MAILTO=""
# change the location of the script path
# run at reboot after 3 min after docker create the iptables rules
#@reboot root sleep 180 && /path/iptables_ddns_multi_update.sh > /dev/null 2>&1
# run script every 5 min to check for DDNS IP change
#*/10 * * * * root /path/iptables_ddns_multi_update.sh > /dev/null 2>&1

# set program path and variables
# require iptables, ipset and iputils-ping packages
IPTABLES="/usr/sbin/iptables"
IPSET="/usr/sbin/ipset"
PING="/usr/bin/ping"
IPSET_NAME="myddnslist"

# your ddns hostname or IP
# support multiple hostname or IP
ddns_host="xxx.ddns.net"

# Create the ipset set if it does not exist
$IPSET list -n | grep -q $IPSET_NAME || $IPSET create $IPSET_NAME hash:ip
$IPSET list -n | grep -q temp || $IPSET create temp hash:ip

# extract your latest dynamic IP from the ddns hostname
# and add to the ipset temp group
if [ ! -z "$ddns_host" ]; then
        for x in $ddns_host; do
                y=`$PING -c 1 -t 1 $x | head -1 | cut -d ' ' -f 3 | tr -d '()'`
                $IPSET add temp $y
        done
fi

# swap temp to actual ipset group
ipset swap temp $IPSET_NAME
ipset destroy temp

# update iptables rules
$IPTABLES -R INPUT 4 -p tcp --dport 53 -m set --match-set $IPSET_NAME src -j ACCEPT
$IPTABLES -R INPUT 5 -p udp --dport 53 -m set --match-set $IPSET_NAME src -j ACCEPT
$IPTABLES -R INPUT 6 -p tcp -m state --state NEW --dport 80 -m set --match-set $IPSET_NAME src -j ACCEPT
