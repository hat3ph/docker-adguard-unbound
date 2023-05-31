## Safe Internet with Adguard and Unbound - Solution
This solution is a combination of AdGuard and Unbound in a docker-compose project with the intent of enabling users to quickly and easily create and deploy a personally managed ad blocking capabilities , family safe search, parental controls (via AdGuard), and DNS caching with additional privacy options and DNSSEC validation (via Unbound). 

Docker Compose file contains:
- adguard-unbound - https://github.com/hat3ph/adguard-unbound

Contains initial unbound.conf as well.

## Prerequisites:
- Install docker: https://docs.docker.com/engine/install/
- Install docker-compose: https://docs.docker.com/compose/install/
- Run docker as non-root: https://docs.docker.com/engine/install/linux-postinstall/
- Run `disable_dnsstublistener.sh` first to disable systemd-resolved DNS stub listener.
- Install dns-root-data (ubuntu) package for the Unbound's DNSSEC key and root hints.
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

## Quickstart
To get started all you need to do is git clone the repository and spin up the containers.
```bash
git clone https://github.com/hat3ph/docker-adguard-unbound.git
cd docker-adguard-unbound
docker compose up -d
```
To disable DNSSEC validation with Unbound, comment out below volume in `docker-compose.yml` to use the default `unbound.conf`.
```yml
#- "./unbound:/opt/unbound"
#- "/usr/share/dns:/usr/share/dns"
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
