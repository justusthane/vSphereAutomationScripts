#!/bin/bash
set -euo pipefail
cp scripts/* /usr/local/bin/
cp systemd/* /etc/systemd/system/
systemctl daemon-reload
systemctl enable credentialServer.service
systemctl start credentialServer.service
systemctl enable vSphereSnapshotReport.timer
systemctl start vSphereSnapshotReport.timer
