## PowerCLI Functions and Modules used for vCenter VM Provisioning and Management
# By Mike N | SEC-480

# Banner Function
function 480Banner()
{
    $banner = @"
   _____ ______ _____ _  _   ___   ___    _    _ _   _ _       ____                              
  / ____|  ____/ ____| || | / _ \ / _ \  | |  | | | (_) |     |  _ \                             
 | (___ | |__ | |    | || || (_) | | | | | |  | | |_ _| |___  | |_) | __ _ _ __  _ __   ___ _ __ 
  \___ \|  __|| |    |__   _> _ <| | | | | |  | | __| | / __| |  _ < / _` | '_ \| '_ \ / _ \ '__|
  ____) | |___| |____   | || (_) | |_| | | |__| | |_| | \__ \ | |_) | (_| | | | | | | |  __/ |   
 |_____/|______\_____|  |_| \___/ \___/   \____/ \__|_|_|___/ |____/ \__,_|_| |_|_| |_|\___|_|   
                                                                                                                                                                       
"@
    Write-Host $banner
}

# Function used to connect to vCenter Server
function connectVCenter([string] $server)
{
    $conn = $global:DefaultVIServer

    # Check Connection State
    if ($conn) {
        # Use existing connection if available
        $msg = "vCenter Connected to {0}" -f $conn
        Write-Host -foregroundColor Green $msg
    } else {
        # Prompt user to reconnect if needed
        $conn = Connect-VIServer($server)
    }
}

# Function used to grab deployment information from config file
function getConfig([string] $configfile)
{
    $config = $null
    if (Test-Path $configfile) {
        Write-Host -ForegroundColor Green "Config file found, importing config"
        $config = Get-Content -Raw -Path $configfile | ConvertFrom-Json
    } else {
        Write-Host -ForegroundColor Red "No config file found"
    }
    return $config

}

# Function used to select VM for deployment
function selectVM([string] $folder) {
    $vmselection = $null
    try {
        # List all VMs in selected folder | Stop commands if err
        $basevms = get-vm -Location $folder -ErrorAction Stop
        
        $index = 0
        foreach ($i in $basevms) {
            $index += 1
            Write-Host "[$($index)] $($i.Name)"
        }

        # User Selection of VMs
        $selection = Read-Host "Please select a VM index to deploy"
        if ($selection -gt 0 -and $selection -le $basevms.Count) {
            $vmselection = $basevms[$selection -1]
            Write-Host "'$vmselection' was selected!" -ForegroundColor "Green"
            return $vmselection
        } else {
            Write-Host "Invalid Selection, Please try again" -ForegroundColor "Yellow"
        }
    
    # Err out if input folder was not found
    } catch {
        Write-Host "Folder $folder not found!" -ForegroundColor Red
    }
}

# Function used to create a VM Clone (Linked/Full)
function cloneVM($config, $selected_vm)
{
    # Prompt User for VM Name
    $newname = Read-Host "Please enter name for new VM"
    try {
        # Check to see if VM already exists --> Continue below if no duplicate vm name was found
        Get-VM -Name $newname -ErrorAction Stop | Out-Null

        Write-Host "======================================"
        Write-Host "VM '$newname' already exists - Stopping Task!" -ForegroundColor Yellow
        Write-Host "Please select a different VM Name"
        Write-Host "======================================"
        Write-Host ""
        
    # Continue with rest of deployment below if there are no existing vms with the same name
    } catch {
        # Source VM Info
        Write-Host $selected_vm
        $vm = Get-VM -Name "$selected_vm"
        $snapshot = Get-Snapshot -VM $vm -Name $config.snapshot
        $vmhost = Get-VMHost -Name $config.esxi_host
        $ds = Get-Datastore -Name $config.datastore
        $vmnetwork = $config.default_net
        
        Write-Host ""
        Write-Host "The following config will be used:"
        Write-Host "=================================="
        Write-Host "Base VM: $vm"
        Write-Host "Base Snapshot: $snapshot"
        Write-Host "ESXi Host: $vmhost"
        Write-Host "Datastore: $ds"
        Write-Host "New VM Name: $newname"
        Write-Host "Network: $vmnetwork"
        
        # Ask user if they would like a linked or full clone deployment
        Write-Host ""
        Write-Host "======================================================================"
        $checking = Read-Host "Please Select Deployment Type: [F]ull Clone, [L]inked Clone, or [Q]uit"
        
        # Run Deployment - Full Clone
        if ($checking.Substring(0,1).ToUpper() -eq "F") {
            # Check to see if user confirms deployment
            Write-Host ""
            Write-Host "============================"
            $checking2 = Read-Host "Confirm VM Deployment? (Y/N)"
            Write-Host ""
            if ($checking2.Substring(0,1).ToUpper() -eq "Y") {
                $newvm = New-VM -Name "$newname" -VM $vm -VMHost $vmhost -Datastore $ds -Confirm:$false
                # Snapshot for new vm
                $newvm | New-Snapshot -Name "Base"
            } else {
                Write-Host "Aborting Task" -ForegroundColor Yellow
            }

        # Run Deployment - Linked Clone
        } elseif ($checking.Substring(0,1).ToUpper() -eq "L") {
            # Check to see if user confirms deployment
            Write-Host ""
            Write-Host "============================"
            $checking2 = Read-Host "Confirm VM Deployment? (Y/N)"
            Write-Host ""
            if ($checking2.Substring(0,1).ToUpper() -eq "Y") {
                $newvm = New-VM -LinkedClone -Name "$newname" -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -Confirm:$false
                # Snapshot for new vm
                $newvm | New-Snapshot -Name "Base"
            } else {
                Write-Host "Aborting Task" -ForegroundColor Yellow
            }
        # Catch condition
        } else {
            Write-Host ""
            Write-Host "Aborting Task" -ForegroundColor Yellow
        }
    }
}

# Function used to create Base VMs from existing VM (and base VM snapshot if available)
function createBaseVM($config, $vm_target)
{
    # Source VM Info
    $vm = Get-VM -Name "$vm_target"
    $snapshot = Get-Snapshot -VM $vm -Name $config.snapshot
    $vmhost = Get-VMHost -Name $config.esxi_host
    $ds = Get-Datastore -Name $config.datastore
    $linkedname = "{0}.linked" -f $vm.name

    # Create temp VM
    $linkedvm = New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -Confirm:$false

    # Create Full VM from temp VM
    $newvm = New-VM -Name "$vm_target.base" -VM $linkedvm -VMHost $vmhost -Datastore $ds -Confirm:$false

    ## Snapshot for new vm
    $newvm | New-Snapshot -Name "Base"

    # Cleanup temp linked clone VM
    Get-VM $linkedname | Remove-VM -Confirm:$false

}

### =====================
### Milestone 6 Functions:

## New-Network Function | Used to create a new virtual switch and portgroup
# Input: config + Net Name
function New-Network([PSCustomObject]$config, [String]$netname){
    # Import var
    $vmhost = $config.esxi_host
    
    # Create port group
    try {
        New-VirtualSwitch -VMHost "$vmhost" -Name "$netname-vswitch" -ErrorAction Stop | Out-Null
        # ^^We need to run a check to see if vswitch exists

        # Grab info from new created vswitch
        $vswitch = Get-VirtualSwitch -VMHost $vmhost -Name "$netname-vswitch"
        
        # User confirm task complete
        Write-Host "'$netname-vswitch' deployed successfully!" -ForegroundColor Yellow
    } catch {
        Write-Host "'$netname-vwitch' already exists... continuing task" -ForegroundColor Yellow
    }

    # Create new portgroup on new vswitch
    try {
        New-VirtualPortGroup -VirtualSwitch $vswitch -Name "$netname-LAN" -ErrorAction Stop | Out-Null
        # ^^We need to run a check to see if vswitch exists

        # User confirm task complete
        Write-Host "'$netname-LAN' deployed successfully!" -ForegroundColor Yellow
        Write-Host "Nothing left to do, Task complete!" -ForegroundColor Green

    } catch {
        Write-Host "'$netname-LAN' already exists..." -ForegroundColor Yellow
        Write-Host "Nothing left to do, Task complete!" -ForegroundColor Green
    }
}

## Get-IP Function | Grabs IP and MAC address from the first interface of a named VM
function Get-IP([String]$vm) {
    # Grab IP + MAC adapter 1 info from VM
    $mac = (Get-VM -Name "$vm" | Get-NetworkAdapter)[0].MacAddress
    $getvmnet = Get-VM -Name "$vm"

    Write-Host "Grabbing IP and MAC Info for VM - '$vm'" -ForegroundColor Yellow
    Write-Host "======================================" 
    
    # IP Address for net adapter 1
    Write-Host "IP:" $getvmnet.Guest.IPAddress[0]

    # MAC Address for net adapter 1
    Write-Host "MAC:" $mac
    Write-Host ""
}

## Set-VMPower Function | User Selects VM and gets prompted to turn on/off
function Set-VMPower() {
    
    # Select VM from list
    Write-Host "================================================="
    Write-Host "Please select a VM from the list to power manage:"
    $index = 1
    $vms = Get-VM 

    foreach($i in $vms) {
        Write-Host "[$($index)] $($i.Name)"
        $index += 1
    }

    $selection = Read-Host "Enter Index Number Here"

    if ($selection -in 1..$vms.count) {
        $selectedVM = $vms[$selection -1].Name
        Write-Host "VM '$selectedVM' was selected" -ForegroundColor Yellow
    } else {
        Write-Host "Index out of range, please try again" -ForegroundColor Yellow
        return
    }
    
    # Set Power options for selected VMs + Prompt user if they would like to turn VM [On] or [Off]
    $vmstate = (Get-VM -Name "$selectedVM").PowerState
    Write-Host "Current power state of VM '$selectedVM': $vmstate"
    $setStatus = Read-Host "Would you like to turn the VM On or Off (on/off)"

    if ($setStatus -ilike "on") {
        # Check if VM is already on --> update user if this is the case
        if ($vmstate -eq "PoweredOn") {
            Write-Host "VM '$selectedVM' is already Powered On" -ForegroundColor Yellow
        } else {
            Write-Host "Attempting to Power On VM..." -ForegroundColor Yellow
            Start-VM -VM "$selectedVM" -RunAsync -Confirm:$true
            Write-Host "Task Complete!" -ForegroundColor Green
        }
    } elseif ($setStatus -ilike "off") {
        # Check if VM is already off --> update user if this is the case
        if ($vmstate -eq "PoweredOff") {
            Write-Host "VM '$selectedVM' is already Powered Off" -ForegroundColor Yellow
        } else {
            Write-Host "Attempting to Power Off VM..." -ForegroundColor Yellow
            Stop-VM -VM "$selectedVM" -RunAsync -Confirm:$true
            Write-Host "Task Complete!" -ForegroundColor Green
        }
    } else {
        Write-Host "Invalid option, please try again" -ForegroundColor Yellow
    }
}

# Set-Network Function
function Set-Network () {
    # Select VM from list
    Write-Host "================================================="
    Write-Host "Please select a VM from the list to configure networking:"
    $index = 1
    $vms = Get-VM 

    foreach($i in $vms) {
        Write-Host "[$($index)] $($i.Name)"
        $index += 1
    }

    $selection = Read-Host "Enter Index Number Here"

    if ($selection -in 1..$vms.count) {
        $selectedVM = $vms[$selection -1].Name
        Write-Host "VM '$selectedVM' was selected" -ForegroundColor Yellow
    } else {
        Write-Host "Index out of range, please try again" -ForegroundColor Yellow
        return
    }

    # Get Index of network adapters for specified VM
    Write-Host ""
    Write-Host "================================================================"
    Write-Host "Please select a network adapter on VM '$selectedVM' to configure"
    $index2 = 1
    $netAdapt = Get-VM -Name "$selectedVM" | Get-NetworkAdapter

    foreach($iface in $netAdapt) {
        Write-Host "[$($index2)] $($iface.Name)"
        $index2 += 1
    }

    $selection2 = Read-Host "Enter Index Number Here"

    if ($selection2 -in 1..$netadapt.count) {
        $configAdapt = $netAdapt[$selection2 -1]
        Write-Host "Interface '$($configAdapt.Name)' was selected" -ForegroundColor Yellow
    } else {
        Write-Host "Index out of range, please try again" -ForegroundColor Yellow
        return
    }

    # User selects network from list for VM Net Adapter
    Write-Host "Please select a network to assign to adapter"

    $index3 = 1
    $networks = Get-VirtualNetwork

    foreach ($net in $networks) {
        Write-Host "[$($index3)] $($net.Name)"
        $index3 += 1
    }

    $selection3 = Read-Host "Enter Index Number Here"

    if ($selection3 -in 1..$networks.count) {
        $netSelection = $networks[$selection3 -1].Name
        Write-Host "Network '$netSelection' was selected" -ForegroundColor Yellow
        Write-Host "Configuring Network Adapter..."
        # Set Network Adapter Settings using Selected Config
        Set-NetworkAdapter -NetworkAdapter $configAdapt -NetworkName "$netSelection" -Confirm:$true
    } else {
        Write-Host "Index out of range, please try again" -ForegroundColor Yellow
        return
    }
}