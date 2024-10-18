#!/bin/bash
set -euo pipefail
if [ ! -d /usr/local/bin/vsphereAutomation ]; then
	mkdir -p /usr/local/bin/vsphereAutomation;
fi
cp scripts/* /usr/local/bin/vsphereAutomation/
cp systemd/* /etc/systemd/system/
if [ ! -d /etc/systemd/system/vsphereSnapshotReport.service.d ]; then
	mkdir -p /etc/systemd/system/vsphereSnapshotReport.service.d;
fi
cat << EOF > /etc/systemd/system/vsphereSnapshotReport.service.d/override.conf
[Service]
Environment="USERNAME=$1"
EOF
systemctl daemon-reload
systemctl enable vsphereAutomationCredentialServer.service
systemctl start vsphereAutomationCredentialServer.service
systemctl enable vsphereSnapshotReport.timer
systemctl start vsphereSnapshotReport.timer
systemctl enable vsphereDRSGroupMgmt.timer
systemctl start vsphereDRSGroupMgmt.timer
