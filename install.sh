#!/bin/bash
set -euo pipefail
cp scripts/* /usr/local/bin/
cp systemd/* /etc/systemd/system/
if [ ! -d /etc/systemd/system/vSphereSnapshotReport.service.d ]; then
	mkdir -p /etc/systemd/system/vSphereSnapshotReport.service.d;
fi
cat << EOF > /etc/systemd/system/vSphereSnapshotReport.service.d/override.conf
[Service]
Environment="USERNAME=$1"
EOF
systemctl daemon-reload
systemctl enable vSphereAutomationCredentialServer.service
systemctl start vSphereAutomationCredentialServer.service
systemctl enable vSphereSnapshotReport.timer
systemctl start vSphereSnapshotReport.timer
systemctl enable vSpherePriorityVMsDRSGroup.timer
systemctl start vSpherePriorityVMsDRSGroup.timer
