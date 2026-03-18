# Driver File for running 480 Module Commands

# Load 480-Util Module
Import-Module './480-utils.psm1' -Force

$config = getConfig -configfile "/home/mike-adm/Documents/SEC-480/Milestone5/modules/480-utils/480.json"

# Display Banner
480Banner

# Connect VCenter Session
#connectVCenter -server $config.vcenter_server

# Select VM
$selected_vm = selectVM($config.basevm_folder)

# Create VM
cloneVM -config $config -selected_vm $selected_vm