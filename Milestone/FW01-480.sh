#!/bin/vbash
# Script use to configure Vyos Firewall/Router for SEC-480

# Need to source vyos script commands from this file below
source /opt/vyatta/etc/functions/script-template

# Prevent Script from running without the "vyattacfg" user group permission applied
if [ "$(id -g -n)" != 'vyattacfg' ] ; then
    exec sg vyattacfg -c "/bin/vbash $(readlink -f $0) $@"
fi

# Configuration commands go here VVV
configure

# Network Adapter Config
set interfaces ethernet eth0 address '10.0.17.160/24' #NET_TBD
set interfaces ethernet eth0 description 'SEC480-WAN'
set interfaces ethernet eth1 address '192.168.30.2/24'
set interfaces ethernet eth1 description 'SEC480-LAN'

# DNS Settings
set system name-server '10.0.17.2' #SET_UPSTREAM_DNS_HERE

# Default Gateway
set protocols static route 0.0.0.0/0 next-hop 10.0.17.2 #SET_UPSTREAM_DNS_HERE

# Set Hostname
set system host-name 'FW01-480'

# Apply Initial Network Config
commit

# DNS Forwarding for DMZ and LAN NET

set service dns forwarding allow-from '192.168.30.0/24'
set service dns forwarding listen-address '192.168.30.2'

set service dns forwarding system

# NAT Config
set nat source rule 10 description 'NAT FROM LAN to WAN'
set nat source rule 10 outbound-interface 'eth0'
set nat source rule 10 source address '192.168.30.0/24'
set nat source rule 10 translation address 'masquerade'

# Set SSH Listen Address to LAN only
delete service ssh listen-address '0.0.0.0'
set service ssh listen-address '192.168.30.2'

# Save Configuration
commit
save
exit
