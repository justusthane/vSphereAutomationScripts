## About
This is a collection of systemd services to run automated tasks against vSphere. So far it includes:

### vsphereSnapshotReport
Emails a report of the number of snapshots per VM.

### vsphereDRSGroupMgmt
Adds any VMs that are members of the VIP, Gold, or Silver Resource Groups to the "VMs to Keep in Shuniah" DRS group.

### vsphereAutomationCredentialServer
Requests and serves the password used to connect to vSphere, used by the other services. Upon service start, it creates a systemd password request, which can be responded to using `systemd-tty-ask-password-agent`.

## Installation
1. Log in as root user
2. [Install PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-rhel?view=powershell-7.4)
3. Run `pwsh -C "install-module -scope CurrentUser VMware.PowerCLI"`
4. Clone this repo (`git clone https://cc-gitlab.confederationcollege.ca/techservices/vsphereautomationscripts`) and `cd` into it
5. `cp CONFIG.ini.default CONFIG.ini`
6. Edit "CONFIG.ini" to specify options
  - "vsphere_user" must be a user in vSphere with the necessary privileges to perform the necessary tasks - currently requires the Host -> Inventory -> Modify Cluster privilege, required to manage DRS groups ([as documented here](https://tekhead.it/blog/2015/06/assigning-vcenter-permissions-for-drs-affinity-rules/)).
7. Run `./install.pl`

The install script copies all the necessary files (systemd services and scripts), and enables and starts the systemd timers.

## Updating
Simply pull the repo again (`git pull`) and re-run `./install.pl`. Your customized CONFIG.ini file will not be overwritten.

## Usage
Because the password for the vSphere user is only stored in memory, after the server is rebooted (or the vsphereAutomationCredentialServer systemd server is restarted) the password must be re-entered.

To do this, SSH to the server and run `systemd-tty-ask-password-agent` to respond to the pending password request.

If there are no password requests pending, `systemctl restart vsphereAutomationCredentialServer` to prompt a new password request.

### Running scripts outside of their schedule
If you wish to run one of the scripts immediately, rather than waiting for its next scheduled occurance, simply start the corresponding systemd service:

- `systemctl start vsphereSnapshotReport`
- `systemctl start vsphereDRSGroupMgmt`

### Temporarily disabling the scheduled tasks
To temporarily disable one of the tasks, stop the associated systemd timer:

- `systemctl stop vsphereSnapshotReport.timer`
- `systemctl stop vsphereDRSGroupMgmt.timer`

The scheduled tasks will resume next time the server is rebooted (or when the timers are restarted manually). To prevent them from resuming after a reboot, disable them:

- `systemctl disable vsphereSnapshotReport.timer`
- `systemctl disable vsphereDRSGroupMgmt.timer`

## Technical Details

### Overview
This project consists of several systemd services. Each service has a corresponding Python script that it runs. In most cases, the Python script in turns calls a related PowerShell script which does the actually work - the purpose of the Python "wrapper" script is simply to fetch the password from the credentialServer service and pass it to the PowerShell script.

A goal of this project was to not store the password on disk. Instead, the credential server service (scripts/credentialServer.py) creates a systemd password request, which sits and waits to be responded to.

Once a user provides the password, the credential server opens a Unix socket at /run/credentialServer.sock, which provides the password when requested by the Python wrapper scripts during each of their scheduled executions.

Configurable options are specified in the CONFIG.ini file. During installation, install.pl reads this file and creates systemd override files for each service which pass the options to their corresponding systemd service as environment variables. The systemd services in turn pass the options to the scripts they call as arguments.
