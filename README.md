## Safe Internet with Adguard and Unbound - Solution
This solution is a combination of AdGuard and Unbound in a docker-compose project with the intent of enabling users to quickly and easily create and deploy a personally managed ad blocking capabilities , family safe search, parental controls (via AdGuard), and DNS caching with additional privacy options and DNSSEC validation (via Unbound). 

Docker Compose file contains:
- adguard-unbound - https://github.com/hat3ph/adguard-unbound

Contains initial unbound.conf as well.

## Prerequisites:
- Run `disable_dnsstublistener.sh` first to disable systemd-resolved DNS stub listener.
- ☁ If using a cloud provider, you need to allow ingress for below port:

| Port      | Service                       |
|-----------|-------------------------------|
| 53/tcp    | AdGuard Home DNS connection   |
| 53/udp    | AdGuard Home DNS connection   |
| 3000/tcp  | AdGuard Home install web panel|
| 80/tcp    | AdGuard Home web panel HTTP   |
| 443/tcp   | AdGuard Home web panel HTTPS  |
| 784/udp   | AdGuard Home DNS-over-QUIC    |
| 853/tcp   | AdGuard Home DNS-over-TLS     |
| 67-68/tcp | AdGuard Home DHCP service     |
| 5053/tcp  | Unbound DNS connection        |
| 5053/udp  | Unbound DNS connection        |

### For using Docker:
- Install docker: https://docs.docker.com/engine/install/
- Install docker-compose: https://docs.docker.com/compose/install/
- Run docker as non-root: https://docs.docker.com/engine/install/linux-postinstall/

### For using Podman
- Install podman and podman-compose
  - Ubuntu 24.04: `sudo apt-get install podman podman-compose`
  - CentOS 9: `sudo yum install epel-release && sudo yum install podman podman-compose`

## Quickstart
To get started all you need to do is git clone the repository and spin up the containers.
```bash
git clone https://github.com/hat3ph/docker-adguard-unbound.git
cd docker-adguard-unbound

# using docker
docker compose up -d

# using podman as root
sudo podman compose up -d

# using rootless podman
podman compose up -d
```

## Podman FAQ
### Run rootful VS rootless podman container
You can run rootful container with root full access or rootless container for enhanced security using podman.
```bash
# enable rootfull system wide podman service
sudo systemctl enable --now podman.socket
sudo podman compose -f docker-compose.yml up -d

# enable rootless podman service
systemctl --user enable --now podman.socket
podman compose -f docker-compose.yml up -d
```
### Not able to bind port 53
```bash
Error: cannot listen on the UDP port: listen udp4 :53: bind: address already in use
exit code: 126
podman start adguard-unbound
Error: unable to start container "2ef2c01bc0ba476095b851a8b71dc24ebff94d4fe681ce66e4b2db78b8589922": cannot listen on the UDP port: listen udp4 :53: bind: address already in use
exit code: 125
```
Not able to bind port 53 due to already used by Podman's [aardvark-dns](https://github.com/containers/podman/discussions/14242). Edit `/etc/containers/containers.conf` to use another port.
```bash
[network]
dns_bind_port=5000 # or well whatever you like
```
### Rootless podman with privileged port 53
```bash
Error: rootlessport cannot expose privileged port 53, you can add 'net.ipv4.ip_unprivileged_port_start=53' to /etc/sysctl.conf (currently 1024), or choose a larger port number (>= 1024): listen tcp 0.0.0.0:53: bind: permission denied
exit code: 126
podman start adguard-unbound
Error: unable to start container "73d392a9d0df2d4f92492c4f8702aba40d7b6909e97492c4da69ab7853afae13": rootlessport cannot expose privileged port 53, you can add 'net.ipv4.ip_unprivileged_port_start=53' to /etc/sysctl.conf (currently 1024), or choose a larger port number (>= 1024): listen tcp 0.0.0.0:53: bind: permission denied
exit code: 125
```
Update sysctl for port 53. Reboot the server with the new changes.
```bash
echo "net.ipv4.ip_unprivileged_port_start=53" | sudo tee /etc/sysctl.d/20-dns-privileged-port.conf
```
### Podman container restart policy
To enable container auto-start during host reboot, enable the podman-restart service.
```bash
# enable system-wide podman service
sudo systemctl enable --now podman-restart.service
# enable rootless podman service
systemctl --user enable --now podman-restart.service
```
Edit `docker-compose.yml` and change restart policy to [always](https://github.com/containers/podman/issues/20418).
```yml
restart: always
```
### Podman mounted volume permission denied with SELinux 
```bash
# /var/log/message
Jun 28 19:17:40 centos9 setroubleshoot[1818]: SELinux is preventing /usr/sbin/unbound from read access on the file unbound.conf. For complete SELinux messages run: sealert -l 6951e854-eb81-4d61-b11f-87dc2fb3db7f
Jun 28 19:17:40 centos9 setroubleshoot[1818]: SELinux is preventing /usr/sbin/unbound from read access on the file unbound.conf.#012#012*****  Plugin catchall (100. confidence) suggests   **************************#012#012If you believe that unbound should be allowed read access on the unbound.conf file by default.#012Then you should report this as a bug.#012You can generate a local policy module to allow this access.#012Do#012allow this access for now by executing:#012# ausearch -c 'unbound' --raw | audit2allow -M my-unbound#012# semodule -X 300 -i my-unbound.pp#012

# podman logs adguard-unbound
[1751109574] unbound[3:0] error: Could not open /opt/unbound/unbound.conf: Permission denied
[1751109574] unbound[3:0] fatal error: Could not read config file: /opt/unbound/unbound.conf. Maybe try unbound -dd, it stays on the commandline to see more errors, or unbound-checkconf
Failed to start unbound: 1
```
Either [disable SELinux](https://linuxconfig.org/how-to-disable-selinux-on-linux) or edit `docker-compose.yml` with [label](https://blog.christophersmart.com/2021/01/31/podman-volumes-and-selinux/)
```yml
    volumes:
      - "./adguard/opt-adguard-work:/opt/adguardhome/work:Z" # adguard container work directory
      - "./adguard/opt-adguard-conf:/opt/adguardhome/conf:Z" # adguard container conf directory
      - "./unbound:/opt/unbound:Z" # map custom unbound config
```

## Local Unbound DNS Server with DNSSEC validation
To use Unbound as local DNS server with DNSSEC validation, use below entry as your DNS upstream server under Settings -> DNS Settings.
```bash
127.0.0.1:5053
```

## Modifying the upstream DNS provider for Unbound
If you choose to use Cloudflare for any reason you are able to modify the upstream DNS provider in `unbound.conf`.

Search for `forward-zone` and modify the IP addresses for your chosen DNS [provider](https://docs.pi-hole.net/guides/dns/upstream-dns-providers/).

>**NOTE:** The anything after `#` is a comment on the line. 
What this means is it is just there to tell you which DNS provider you put there. It is for you to be able to reference later. I recommend updating this if you change your DNS provider from the default values.
```yaml
forward-zone:
        name: "."
        forward-addr: 1.1.1.1@853#cloudflare-dns.com
        forward-addr: 1.0.0.1@853#cloudflare-dns.com
        forward-addr: 2606:4700:4700::1111@853#cloudflare-dns.com
        forward-addr: 2606:4700:4700::1001@853#cloudflare-dns.com
        forward-tls-upstream: yes
```

## Access Adguard Interface (IMPORTANT)
First connect to http://xxx.xxx.xxx.xxx:3000 first to setup AdGuard Home before DNS query and adblocking to work.
The IP could be your local docker host IP or public IP of your cloud VPS.

Once finish the installation wizard, comment out `docker-compose.yml` to disable the wizard page.
```yml
#- 3000:3000/tcp # AdGuard Home web panel
```

## DNS-over-HTTPS/TLS/QUIC
To use DoH/DoT/DoQ encryption, first register and apply a valid FQDN and SSL certificate first for AdGuard Home.

If you are using Let's Encrypt free SSL certicate, check out [link](https://ikarus.sg/lets-encrypt-dot-android/) regarding DoT connection denied with some Android device due to expired X3 root certificate.

To manual or auto renewal Lets's Encrypt certificates, run below command with pre and post hook or copy the 2 script to `/etc/letsencrypt/renewal-hooks/pre` and `/etc/letsencrypt/renewal-hooks/post` respectively and let certbot auto renewal by itself.
```bash
sudo certbot renew --pre-hook /path/letsencrypt_renewal_pre_hook.sh --post-hook /path/letsencrypt_renewal_post_hook.sh --dry-run
```

## Disable open resolve to prevent DNS Amplication Attack
If you run this in cloud as your provide DNS, advise to restrict DNS access to prevent [DNS Amplication Attack](https://openresolver.com/).
Setup cron job to run `iptables_ddns_update.sh` to update the iptables rule.
Docker will re-create the docker iptables rule if you restart the container hence will mess up with the iptables rule. 
Advice just restart the VPS to let the script setup the iptables rule again from fresh.
