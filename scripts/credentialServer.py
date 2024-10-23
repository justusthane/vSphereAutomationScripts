#! /usr/bin/env python
import sys
import socket
import os
import atexit
import subprocess

username = sys.argv[1]

def on_exit():
    print('Closing server')
    os.unlink(socket_path)

atexit.register(on_exit)

socket_path = '/run/credentialServer.sock'
password = subprocess.getoutput(f'systemd-ask-password --timeout 0 "Please enter the password for {username}"')

try:
    os.unlink(socket_path)
except OSError:
    if os.path.exists(socket_path):
        raise

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

server.bind(socket_path)
os.chmod(socket_path, 0o700)

server.listen(1)
while True:
    print('Listening for connections...')
    connection, client_address = server.accept()

    try:
        print('Connection from', str(connection).split(", ")[0][-4:])

        data = connection.recv(1024)
        if not data:
            break
        if data.decode() == 'gimmegimmegimme':
            response = password
            connection.sendall(response.encode())
    finally:
        connection.close()
