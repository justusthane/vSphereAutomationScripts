#! /usr/bin/env python
import sys
import socket
import os
import subprocess
import smtplib
from email.message import EmailMessage

socket_path = '/run/credentialServer.sock'

client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    client.connect(socket_path)

    message = 'gimmegimmegimme'
    client.sendall(message.encode())

    response = client.recv(1024)
    subprocess.run(['/usr/local/bin/vsphereAutomation/snapshotReport.ps1', '-user', sys.argv[1], '-password', response])

    client.close()
except ConnectionRefusedError:
    print('Could not connect to credential server')
    msg = EmailMessage()
    msg.set_content(f'Credentials needed to run VMware snapshot report. Please SSH to {socket.gethostname()} and run systemd-tty-ask-password-agent to specify password')
    msg['Subject'] = f'Password needed'
    msg['From'] = f'{socket.gethostname()}@confederationc.on.ca'
    msg['To'] = 'jbadergr@confederationcollege.ca'

    s = smtplib.SMTP('mail.confederationc.on.ca')
    s.send_message(msg)
    s.quit()
