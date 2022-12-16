#!/usr/bin/env bash

## Traffic going to the internet
route add default gw 172.30.30.1

## Currently  NAT
iptables -t nat -A POSTROUTING -o enp0s8 -j MASQUERADE

##
sudo echo \
"
config setup
        charondebug=\"all\"
        uniqueids=yes
conn server-to-client
        type=tunnel
        auto=start
        keyexchange=ikev2
        authby=secret
        left=172.30.30.30
        leftsubnet=10.2.0.1/24
        right=172.16.16.16
        rightsubnet=10.1.0.1/24
        ike=aes256-sha1-modp1024!
        esp=aes256-sha1!
        aggressive=no
        keyingtries=%forever
        ikelifetime=28800s
        lifetime=3600s
        dpddelay=30s
        dpdtimeout=120s
        dpdaction=restart
conn server-to-client2
        type=tunnel
        auto=start
        keyexchange=ikev2
        authby=secret
        left=172.30.30.30
        leftsubnet=10.2.0.1/24
        right=172.18.18.18
        rightsubnet=10.1.0.1/24
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
secret2="secret2"
sudo echo \
"
172.30.30.30 172.16.16.16 : PSK \"$secret\"
172.30.30.30 172.18.18.18 : PSK \"$secret2\"
" \
| sudo tee /etc/ipsec.secrets
unset secret
unset secret2

sudo ipsec restart

sudo iptables -t nat -I POSTROUTING 1 -m policy --pol ipsec --dir out -j ACCEPT

sudo iptables -A PREROUTING -t nat -s 172.16.16.16 -j DNAT --to-destination 10.2.0.2
sudo iptables -A PREROUTING -t nat -s 172.18.18.18 -j DNAT --to-destination 10.2.0.3
##

## Save the iptables rules
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
