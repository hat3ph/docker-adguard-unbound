#!/bin/bash

# create /etc/cron.d/iptables_ddns_update with below line...
#MAILTO=""
#*/5 * * * * root /home/ubuntu/iptables_ddns_update.sh > /dev/null 2>&1

# your ddns hostname
ddns_host="xxx.ddns.net"

# extract your latest dynamic IP from the ddns hostname
ddns_ip=`host $ddns_host | cut -d ' ' -f 4`

# create the ddns_ip.txt if missing
if [ ! -f /tmp/ddns_ip.txt ]; then
        #echo "File is missing"
        echo "1.2.3.4" > /tmp/ddns_ip.txt
fi

current_ddns_ip=`cat /tmp/ddns_ip.txt`

#echo "Hostname $ddns_host's IP is $ddns_ip"
#echo "Current DDNS IP is $current_ddns_ip"

# update/replace the iptables rules if the ddns IP have changed from the last update
# run ‘sudo iptables --line-numbers -L DOCKER’ to get the rules line
if [ $ddns_ip != $current_ddns_ip ]; then
        #echo "No same IP"
	# update iptables rules by rules number
	/sbin/iptables -R DOCKER 4 -p tcp --dport 53 -s $ddns_ip -j ACCEPT
	/sbin/iptables -R DOCKER 5 -p udp --dport 53 -s $ddns_ip -j ACCEPT
	# update/save the latest ddns ip to ddns_ip.txt
  echo $ddns_ip > /tmp/ddns_ip.txt
fi
