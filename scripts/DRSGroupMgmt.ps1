#!/usr/bin/pwsh
param (
[string]$vsphereUsername,
[string]$vsphereAddress,
[string]$smtpServer,
[string]$emailFrom,
[string]$emailTo,
[string]$password
)

Import-Module VMware.VimAutomation.Core -WarningAction SilentlyContinue
try {
  connect-viserver $vsphereAddress -user "$vsphereUsername" -pass "$password" -Force -ErrorAction Stop
}
catch {
  Send-MailMessage -SmtpServer $smtpServer -to $emailto -from $emailFrom -subject "Error: vSphere Automation DRS group management" -body "Invalid credentials provided for vSphere. Please SSH to $([Environment]::MachineName) and run systemctl restart vsphereAutomationCredentialServer to correct credentials."
  Throw $Error
}
$priorityVMs = get-resourcepool -Name "Production (0 - VIP)","Production (1 - Gold)","Production (2 - Silver)" | VMware.VimAutomation.Core\get-vm
#Add VMs to DRS group
Set-DrsClusterGroup -DrsClusterGroup "VMs to Keep in Shuniah" -VM $priorityVMs -Add
#Remove VMs from DRS group if they aren't in the specified Resource Groups
$(Get-DrsClusterGroup -Name "VMs to Keep in Shuniah").Member.Name | %{If (-Not($priorityVMs.Name -contains $_)) {Set-DrsClusterGroup -DrsClusterGroup "VMs to Keep in Shuniah" -VM $_ -Remove}}
