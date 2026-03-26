# Driver File for running 480 Module Commands

# Load 480-Util Module
Import-Module './480-utils.psm1' -Force

$config = getConfig -configfile "/home/mike-adm/Documents/SEC-480/Milestone5/modules/480-utils/480.json"

# Display Banner
480Banner

# Connect VCenter Session
connectVCenter -server $config.vcenter_server

## New Functions Demo

# Create New Virtual Network
New-Network -config $config -netname "blue21"

# Get IP and MAC of specified VM
Get-IP("fw-blue21")

# Create FW-Blue21 Linked Clone
cloneVM -config $config -selected_vm "vyos.base"

# Set Network for fw-blue21 to be on "VM Network" + "blue21-LAN"
Set-Network

# Start/Stop VM Function (for fw-blue21)
Set-VMPower

# Show output for "Get-IP("fw-blue21")" --> Then run ansible demo

## Old
# =========
# Select VM
#$selected_vm = selectVM($config.basevm_folder)

# Create VM
#cloneVM -config $config -selected_vm $selected_vm