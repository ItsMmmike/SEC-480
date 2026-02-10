### Script used to install new ADDS, DNS, and DHCP services on Windows Server Host
# Run with Admin User --> 'Invoke-WebRequest -Uri "" -Outfile .\ADDS-Install02.ps1'

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

# Grab Script for Pt.2
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ItsMmmike/SEC-480/refs/heads/main/Milestone2/ADDS-Install02.ps1" -Outfile .\ADDS-Install02.ps1

# Complete ADDS Install and Promote Host to DC
Install-ADDSForest -DomainName $domain -InstallDNS -Force
