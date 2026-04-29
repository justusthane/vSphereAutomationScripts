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
  Send-MailMessage -SmtpServer $smtpServer -to $emailto -from $emailFrom -subject "Error: VMware Snapshot Report" -body "Invalid credentials provided for vSphere. Please SSH to $([Environment]::MachineName) and run systemctl restart vsphereAutomationCredentialServer to correct credentials."
  Throw $Error
}
$output = get-vm | ForEach {
	$snapshots = get-snapshot $_;
	[PScustomObject]@{
		Name = $_.Name;
		SnapshotCount = $snapshots.Count;
		OldestSnapshot = ($snapshots | sort-object Created | select -First 1).Created;
	}
	} | Where {$_.SnapshotCount -gt 0} | sort-object SnapshotCount -desc 

If $output.Count -gt 0 {
	$output = $output | convertto-html;
	Send-MailMessage -SmtpServer $smtpServer -to $emailTo -from $emailFrom -body "$output" -BodyAsHtml -Subject "VMware Snapshot Report";
}
