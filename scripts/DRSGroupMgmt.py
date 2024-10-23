#! /usr/bin/env python
import sys
import socket
import os
import subprocess
import smtplib
from email.message import EmailMessage

socket_path = '/run/credentialServer.sock'
vsphere_username = sys.argv[1]
vsphere_address = sys.argv[2]
smtp_server = sys.argv[3]
email_from = sys.argv[4]
email_to = sys.argv[5]

client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    client.connect(socket_path)

    message = 'gimmegimmegimme'
    client.sendall(message.encode())

    response = client.recv(1024)
    subprocess.run(['/usr/local/bin/vsphereAutomation/DRSGroupMgmt.ps1', 
        '-vsphereUsername', vsphere_username, 
        '-vsphereAddress', vsphere_address, 
        '-smtpServer', smtp_server, 
        '-emailFrom', email_from, 
        '-emailTo', email_to, 
        '-password', response])

    client.close()
except ConnectionRefusedError:
    print('Could not connect to credential server')
    msg = EmailMessage()
    msg.set_content(f'Credentials needed to run vSphere Priority VMs DRS group script. Please SSH to {socket.gethostname()} and run systemd-tty-ask-password-agent to specify password')
    msg['Subject'] = f'Password needed'
    msg['From'] = email_from
    msg['To'] = email_to

    s = smtplib.SMTP(smtp_server)
    s.send_message(msg)
    s.quit()
