#!/bin/bash
set -euo pipefail
cp scripts/* /usr/local/bin/
cp systemd/* /etc/systemd/system/
systemctl daemon-reload
systemctl enable vSphereAutomationCredentialServer.service
systemctl start vSphereAutomationCredentialServer.service
systemctl enable vSphereSnapshotReport.timer
systemctl start vSphereSnapshotReport.timer
systemctl enable vSpherePriorityVMsDRSGroup.timer
systemctl start vSpherePriorityVMsDRSGroup.timer
