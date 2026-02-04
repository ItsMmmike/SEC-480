### Script used to install new ADDS, DNS, and DHCP services on Windows Server Host

## Install ADDS, DNS, and DHCP Features for Windows Server Host
Install-WindowsFeature -Name AD-Domain-Services,DNS,DHCP -IncludeManagementTools

## Start Post-Install Setup for AD Domain and promote to Domain Controller
Import-Module ADDSDeployment

# Ask User for Domain Name
Write-Host "==="
while($true) {
  $domain = Read-Host -Prompt "Please provide a new Domain Name - (ex. domain.local)"
  $prompt = Read-Host -Prompt "Confirm new domain for '$domain'? [Y/n]"
  Write-Host ""
  if ($prompt -eq "Y") {
    break
  } elseif ($prompt -eq "y") {
    break
  } else {
    continue
  }
}

Install-ADDSForest -DomainName $domain -InstallDNS -Force

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
Set-DhcpServerv4OptionValue -ScopeId 10.10.17.0 -Router 10.0.17.2 -DnsServer 10.0.17.4
