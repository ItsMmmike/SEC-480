# Pt.2 Script used to setup and deploy DNS and DHCP on Windows Server Host as well as RDP and provision a new Domain Admin User (Post AD Install)

## Grab Domain Name Info
$domain = (Get-CimInstance Win32_ComputerSystem).Domain

## Start Post-Install Setup for DNS
Add-DnsServerPrimaryZone -NetworkID "10.0.17.0/24" -ComputerName "10.0.17.4" -ReplicationScope "Forest" # Reverse Lookup for DNS

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

## Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 # Enable RDP
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" # Allow RDP through FW

## Create New user

# Prompt User Creation
Write-Host "==="
while($true) {
  $usr = Read-Host -Prompt "Please provide a username for New Domain Admin"
  $check = Read-Host -Prompt "Confirm new user '$usr'? [Y/n]"
  Write-Host ""
  if ($check -eq "Y") {
    break
  } elseif ($check -eq "y") {
    break
  } else {
    continue
  }
}

# Prompt User Password
while($true) {
  $pw1 = Read-Host "Enter Password" -AsSecureString
  $pw2 = Read-Host "Re-Enter Password" -AsSecureString
  $pw1_check = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw1))
  $pw2_check = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw2))
  if ($pw1_check -ceq $pw2_check) {
      Write-Host "Password Set!" -ForegroundColor Green
      break
  } else {
      Write-Host "Passwords do not match - Please try again." -ForegroundColor Yellow
      continue
  }
}

# Create User and set as Domain Admin
New-ADUser -Name $usr -AccountPassword $pw1 -enabled:$true
Add-ADGroupMember -Identity "Domain Admins" -Members $usr
