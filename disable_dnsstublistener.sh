#/usr/bash

SERVICE=systemd-resolved.service
PORT=53

if (systemctl -q is-active $SERVICE)
    then
    echo "Application $SERVICE is running."
        if (ss -tunlp | grep $PORT > /dev/null)
                then
                echo "Network port $PORT is running."
                mkdir -p /etc/systemd/resolved.conf.d/
                printf "[Resolve]\nDNS=127.0.0.1\nDNSStubListener=no" > /etc/systemd/resolved.conf.d/disable_dnsstublistener.conf
                mv /etc/resolv.conf /etc/resolv.conf.backup
                ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
		echo "Restarting $SERVICE"
                systemctl restart $SERVICE
                exit 1
        fi
    exit 1
fi
