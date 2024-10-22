#! /usr/bin/env python
import socket
socket_path = '/run/credentialServer.sock'

client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
try:
    client.connect(socket_path)

    message = 'gimmegimmegimme'
    client.sendall(message.encode())

    response = client.recv(1024)

    print(response)
    client.close()
except ConnectionRefusedError:
    print('Could not connect to credential server')
