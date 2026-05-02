# Script used to deploy OU groups for milestone 9
Import-Module ActiveDirectory

New-ADOrganizationalUnit -Name "Blue21" -Path "DC=blue21,DC=local"

New-ADOrganizationalUnit -Name "Accounts" -Path "DC=blue21,DC=local"
New-ADOrganizationalUnit -Name "Groups" -Path "OU=Accounts,DC=blue21,DC=local"
New-ADOrganizationalUnit -Name "Computers" -Path "DC=blue21,DC=local"
New-ADOrganizationalUnit -Name "Servers" -Path "OU=Computers,DC=blue21,DC=local"
New-ADOrganizationalUnit -Name "Workstations" -Path "OU=Computers,DC=blue21,DC=local"

