# Driver File for running 480 Module Commands

# Load 480-Util Module
Import-Module './480-utils.psm1' -Force

$config = getConfig -configfile "/home/mike-adm/Documents/SEC-480/Milestone5/modules/480-utils/480.json"

# Display Banner
480Banner

# Connect VCenter Session
connectVCenter -server $config.vcenter_server

## Milestone 7 Deployments

# Vars
$vm = Get-VM -Name "$selected_vm"
$snapshot = Get-Snapshot -VM $vm -Name $config.snapshot
$vmhost = Get-VMHost -Name $config.esxi_host
$ds = Get-Datastore -Name $config.datastore
$vmnetwork = "blue21-LAN"


# Select VM
$selected_vm = selectVM($config.basevm_folder)

# Create linked clone VMs
$newname = Read-Host "Please enter a new base name for deployment VMs"
foreach ($i in 1..2) {
    $newvm = New-VM -LinkedClone -Name "$newname-0$i" -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -Confirm:$false
    $newvm | New-Snapshot -Name "Base"

    # Set network onto blue21-LAN
    $adapter = (Get-VM -Name "$newname-0$i" | Get-NetworkAdapter)[0]
    Set-NetworkAdapter -NetworkAdapter $adapter -NetworkName "$vmnetwork" -Confirm:$false

    # Start VMs
    Start-VM -VM "$newname-0$i" -RunAsync -Confirm:$false
    
    # Delay next deployment to avoid dhcp issues on ubuntu
    Start-Sleep -s 15
}

# Wait for system power on
Start-Sleep -s 120

# Get IP and MAC of specified VM
foreach ($i in 1..2) {
    Get-IP("$newname-0$i")
}

### New Functions Demo

# # Create New Virtual Network
# New-Network -config $config -netname "blue21"

# # Create FW-Blue21 Linked Clone
# cloneVM -config $config -selected_vm "vyos.base"

# # Set Network for fw-blue21 to be on "480-internal" + "blue21-LAN"
# Set-Network

# # Start/Stop VM Function (for fw-blue21)
# Set-VMPower

# # Get IP and MAC of specified VM
# Get-IP("fw-blue21")

# Show output for "Get-IP("fw-blue21")" --> Then run ansible demo

## Old
# =========
# Select VM
#$selected_vm = selectVM($config.basevm_folder)

# Create VM
#cloneVM -config $config -selected_vm $selected_vm