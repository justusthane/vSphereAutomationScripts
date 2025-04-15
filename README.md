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
7. Run `./install`

The install script copies all the necessary files (systemd services and scripts), and enables and starts the systemd timers.

## Updating
Simply pull the repo again (`git pull`) and re-run `./install`. Your customized CONFIG.ini file will not be overwritten.

## Usage
Mostly it should just run by itself. Because the password for the vSphere user is only stored in memory, after the server is rebooted (or the vsphereAutomationCredentialServer systemd unit is restarted) the password must be re-entered.

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

### Other helpful commands

#### Show logs for service
`journalctl -xeu <service_name>`

#### Show systemd timer statuses
`systemctl list-timers`

## Technical Details

### Overview
This project consists of several systemd services. Each service has a corresponding Python script that it runs. In most cases, the Python script in turns calls a related PowerShell script which does the actually work - the purpose of the Python "wrapper" script is simply to fetch the password from the credentialServer service and pass it to the PowerShell script.

A goal of this project was to not store the password on disk. Instead, the credential server service (scripts/credentialServer.py) creates a systemd password request, which sits and waits to be responded to.

Once a user provides the password, the credential server opens a Unix socket at /run/credentialServer.sock, which provides the password when requested by the Python wrapper scripts during each of their scheduled executions.

Configurable options are specified in the CONFIG.ini file. During installation `/install` reads this file and creates systemd override files for each service which pass the options to their corresponding systemd service as environment variables. The systemd services in turn pass the options to the scripts they call as arguments.

The meat of the installation consists of copying the systemd files and associated scripts to the proper locations on the filesystem (/etc/systemd/system and /usr/local/bin/vsphereAutomation).

The installer (`./install`) is just `install.source.pl` packaged as a binary using [pp - PAR Packager](https://metacpan.org/pod/pp). This is necessary because the script uses some third-party modules, and the easiest way to deal with this is to package it all up using pp.

Once pp is installed, packaging the installer is as simple as `pp -o install install.source.pl`. The modules used are also present in the `modules` directory, but this is just for development.

### Project structure & file descriptions
- `CONFIG.ini.default`: Contains default configuration files. This must be manually copied and renamed to "CONFIG.ini", which is then read by the installer.
- `install`: Used to install/update the project. This is a binary version of `install.source.pl`, packaged using "pp - PAR Packer" and contains any prerequisite Perl modules used by the installer.
- `install.source.pl`: Source code for the installer. Although this can be used directly (instead of `./install`), any prerequisite Perl modules must be manually installed first.
- `modules`: Contains Perl dependencies used by the installer. These are not used once the project is installed, as the dependencies are all packaged into the binary `./install` installer. This is only present for development purposes.
- `scripts`: Contains the scripts that do all the actual work. During installation, these get copied to their install destination, probably /usr/local/bin/vsphereAutomation/.
    - `DRSGroupMgmt.ps1`: PowerShell script which performs the automated DRS group management. This gets called by `DRSGroupMgmt.py`.
    - `DRSGroupMgmt.py`: Wrapper script which retrieves credentials from the *vsphereAutomationCredentialServer* service and then calls `DRSGroupMgmt.ps1`.
    - `credentialServer.py`: Runs as a systemd service. Requests a password from the user at start, and then services the password when requested via a Unix socket.
    - `snapshotReport.ps1`: PowerShell script which performs the snapshot report. This gets called by `snapshotReport.py`.
    - `snapshotReport.py`: Wrapper script which retrieves credentials from the *vsphereAutomationCredentialServer* service and then calls `snapshotReport.ps1`.
- `systemd`: Contains the systemd unit files. Everything in this directory gets copied to `/etc/systemd/system` upon installation.
    - `vsphereAutomationCredentialServer.service`: Responsible for running `credentialServer.py`. Runs continuously.
    - `vsphereDRSGroupMgmt.service`: Responsible for running `DRSGroupMgmt.py`. Only runs when started by the associated systemd timer, and stops after running.
    - `vsphereDRSGroupMgmt.timer`: Starts the associated systemd service on a schedule.
    - `vsphereSnapshotReport.service`: Responsible for running `snapshotReport.py`. Only runs when started by the associated systemd timer, and stops after running.
    - `vsphereSnapshotReport.timer`: Starts the associated systemd service on a schedule.
- `test.pl`: Used for testing perl code, not important to the project.
- `test.py`: Used for testing python code, not important to the project.

## Known Issues
- [Every time the PowerShell scripts run they print a lot of ugly messages to journalctl](https://cc-gitlab.confederationcollege.ca/techservices/vsphereautomationscripts/-/issues/9). This does not impact the operation.
