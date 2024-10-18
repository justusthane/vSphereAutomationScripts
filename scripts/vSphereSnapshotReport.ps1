#!/usr/bin/pwsh
param (
[string]$user,
[string]$password
)
Import-Module VMware.VimAutomation.Core -WarningAction SilentlyContinue
connect-viserver cc-vmcentre.confederationc.on.ca -user "$user" -pass "$password" -Force
$output = get-vm | select Name,@{l="SnapshotCount";e={$($_ | get-snapshot).Count}} | Where {$_.SnapshotCount -gt 0} | sort-object SnapshotCount -desc | convertto-html
Send-MailMessage -SmtpServer mail.confederationc.on.ca -to "jbadergr@confederationcollege.ca" -from "techutils-shu@confederationc.on.ca" -body "$output" -BodyAsHtml -Subject "VMware Snapshot Report"
