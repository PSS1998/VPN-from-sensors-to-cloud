#!/usr/bin/env bash

## NAT traffic going to the internet
route add default gw 172.16.16.1
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

##
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
sudo sysctl -w net.ipv4.conf.all.send_redirects=0
sudo sysctl -p

sudo echo \
"
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 10.2.0.0/24 -d 10.1.0.0/24 -j MASQUERADE
COMMIT
" \
| sudo cat - /etc/ufw/before.rules | sudo tee temp && sudo mv temp /etc/ufw/before.rules

sudo ufw disable 
sudo ufw enable

sudo echo \
"
config setup
        charondebug=\"all\"
        uniqueids=yes
conn client-to-server
        type=tunnel
        auto=start
        keyexchange=ikev2
        authby=secret
        left=172.16.16.16
        leftsubnet=10.1.0.1/24
        right=172.30.30.30
        rightsubnet=10.2.0.1/24
        ike=aes256-sha1-modp1024!
        esp=aes256-sha1!
        aggressive=no
        keyingtries=%forever
        ikelifetime=28800s
        lifetime=3600s
        dpddelay=30s
        dpdtimeout=120s
        dpdaction=restart
" \
| sudo tee /etc/ipsec.conf

secret="secret"
sudo echo \
"
172.16.16.16 172.30.30.30 : PSK \"$secret\"
" \
| sudo tee /etc/ipsec.secrets
unset secret

sudo ipsec restart

sudo iptables -t nat -I POSTROUTING 1 -m policy --pol ipsec --dir out -j ACCEPT
##

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
