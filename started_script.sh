#!/bin/sh

### Custom user script
### Called after router started and network is ready

echo 0        > /proc/sys/net/ipv6/conf/default/forwarding
echo 0        > /proc/sys/net/ipv6/conf/all/forwarding
echo 0        > /proc/sys/net/ipv6/conf/br0/forwarding



echo 1        > /proc/sys/net/ipv6/conf/default/accept_ra  
echo 1        > /proc/sys/net/ipv6/conf/eth2/accept_ra        
echo 1        > /proc/sys/net/ipv6/conf/br0/accept_ra     
echo 1        > /proc/sys/net/ipv6/conf/br0/accept_ra_pinfo
echo 1        > /proc/sys/net/ipv6/conf/br0/accept_ra_pinfo


### Example - load ipset modules
#modprobe ip_set
#modprobe ip_set_hash_ip
#modprobe ip_set_hash_net
#modprobe ip_set_bitmap_ip
#modprobe ip_set_list_set
#modprobe xt_set

ln -sf /sbin/rc /etc/storage/openvpn/client/ovpnc.script

openvpn --cd /etc/storage/openvpn/client/ --config client.conf --daemon openvpn-cli

sleep 10

. /etc/storage/ddns_script.sh

. /etc/storage/geolocation_script.sh

