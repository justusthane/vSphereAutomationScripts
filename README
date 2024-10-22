This is a collection of systemd services to run automated tasks against vSphere. So far it includes:

### vsphereSnapshotReport
Emails a report of the number of snapshots per VM.

### vsphereDRSGroupMgmt
Adds any VMs that are members of the VIP, Gold, or Silver Resource Groups to the "VMs to Keep in Shuniah" DRS group.

### vsphereAutomationCredentialServer
Requests and serves the password used to connect to vSphere, used by the other services. Upon service start, it creates a systemd password request, which can be responded to using `systemd-tty-ask-password-agent`.

## Installation
Clone this repo, and then run `./install.pl <username>`, where <username> is the username used to connect to vSphere (should use an account dedicated to this project with only the necessary permissions - currently requires the Host -> Inventory -> Modify Cluster privilege, required to manage DRS groups ([as documented here](https://tekhead.it/blog/2015/06/assigning-vcenter-permissions-for-drs-affinity-rules/)).

The install script copies all the necessary files (systemd services and scripts), and enables and starts the systemd timers.
