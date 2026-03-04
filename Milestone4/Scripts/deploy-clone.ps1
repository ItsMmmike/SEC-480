# Connect to vSphere Server
#$vserver = "vcenter.michael.local"
#Connect-VIServer($vserver)

# Source VM Info
$name = "test.base"
$vm = Get-VM -Name "$name"
$snapshot = Get-Snapshot -VM $vm -Name "Base"
$vmhost = Get-VMHost -Name "super21.michael.local"
$ds = Get-Datastore -Name datastore2-super21
$newid = "$name.demo"

# Create Linked Clone
New-VM -LinkedClone -Name $newid -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds -Confirm:$false
