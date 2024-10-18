#!/usr/bin/pwsh
param (
[string]$password
)
Import-Module VMware.VimAutomation.Core -WarningAction SilentlyContinue
connect-viserver cc-vmcentre.confederationc.on.ca -user techutils@vsphere.local -pass "$password" -Force
$priorityVMs = get-resourcepool -Name "Production (0 - VIP)","Production (1 - Gold)","Production (2 - Silver)" | VMware.VimAutomation.Core\get-vm
#Add VMs to DRS group
Set-DrsClusterGroup -DrsClusterGroup "VMs to Keep in Shuniah" -VM $priorityVMs -Add
#Remove VMs from DRS group if they aren't in the specified Resource Groups
$(Get-DrsClusterGroup -Name "VMs to Keep in Shuniah").Member.Name | %{If (-Not($priorityVMs.Name -contains $_)) {Set-DrsClusterGroup -DrsClusterGroup "VMs to Keep in Shuniah" -VM $_ -Remove}}
