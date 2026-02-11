# Pt.2 Script used to setup and deploy DNS and DHCP on Windows Server Host (Post AD Install)

## Grab Domain Name Info
$domain = (Get-CimInstance Win32_ComputerSystem).Domain

## Start Post-Install Setup for DNS
Add-DnsServerPrimaryZone -Name "$domain" -ReplicationScope "Forest" -PassThru
Add-DnsServerPrimaryZone -NetworkID "10.0.17.0/24" -ReplicationScope "Forest"

# Configure additional DNS Entries for Server
Add-DnsServerResourceRecordA -Name "fw01-480" -ZoneName "$domain" -IPv4Address "10.0.17.2" -CreatePtr # FW
Add-DnsServerResourceRecordA -Name "vcenter" -ZoneName "$domain" -IPv4Address "10.0.17.3" -CreatePtr # vCenter
Add-DnsServerResourceRecordA -Name "mgmt01-copper" -ZoneName "$domain" -IPv4Address "10.0.17.100" -CreatePtr # Mgmt
Add-DnsServerResourceRecordPtr -Name "4" -ZoneName "17.0.10.in-addr.arpa" -PtrDomainName "ad01-steel.$domain" # AD

## Start Post-Install Setup for DHCP
Add-DhcpServerv4Scope -Name "Infra DHCP" -StartRange 10.0.17.101 -EndRange 10.0.17.150 -SubnetMask 255.255.255.0 -State Active
Set-DhcpServerv4OptionValue -ScopeId 10.0.17.0 -Router 10.0.17.2 -DnsServer 10.0.17.4

# Need to add user to authorize DHCP Server
Add-DhcpServerSecurityGroup

# Authorize DHCP Server
Add-DhcpServerInDC
