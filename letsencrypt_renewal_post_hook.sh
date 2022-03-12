#!/bin/bash

# delete DDNS hostname info and flush DOCKER iptables chain
# only enable this if you enable iptables_ddns_update.sh
#rm /tmp/ddns_ip.txt && /sbin/iptables --flush DOCKER

# start adguard-unbound container
# change the correct for the docker-compose.yml
docker-compose -f /path/docker-adguard-unbound/docker-compose.yml up -d
