# Connect to vSphere Server
$vserver = "vcenter.michael.local"
Connect-VIServer($vserver)

# Source VM Info
$vm = Get-VM -Name "test"
$snapshot = Get-Snapshot -VM $vm -Name "base"
$vmhost = Get-VMHost -Name "super21.michael.local"
$ds = Get-Datastore -Name datastore2-super21
$linkedname = "{0}.linked" -f $vm.name

# Create temp VM
$linkedvm = New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -Confirm:$false

# Create Full VM from temp VM
$newvm = New-VM -Name "test.base" -VM $linkedvm -VMHost $vmhost -Datastore $ds -Confirm:$false

## Snapshot for new vm
$newvm | New-Snapshot -Name "Base"

# Cleanup temp linked clone VM
Get-VM $linkedname | Remove-VM -Confirm:$false
