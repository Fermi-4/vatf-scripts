#!/usr/bin/python

from testlink import Testlink
import socket
import sys
import time
import re
import os
import subprocess
import ssl

message = \
   b'01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789' \
    '01234567890123456789012345678901234567890123456789'

def compIndex(a, b, length):
    for index in range(length):
        if (a[index] != b[index]):
            print("Difference at %d" % index)
            return index
    return length

def runSocket(sock, buf):
    global message
    try:
        for msgSize in range(1, buf + 1):
            sock.send(message[:msgSize])
            ret = sock.recv(msgSize)

            recvSize = len(ret)
            if ((recvSize != msgSize) or (ret != message[:msgSize])):
                print("Error receiving %u bytes of data" % msgSize)
                print("Socket received %d bytes" % recvSize)
                compIndex(ret, message, recvSize)
                break;
            else:
                print("MSG %d OK" % msgSize)
        print "PASS"

    except socket.error:
        print "FAIL"
        print("Socket error")
        print(sys.exc_info())

def run6(ip, port, bufsize, socketType="tcp", cert=None):
    tls = 1 if (cert != None and socketType == 'tcp') else 0
    socketType = socket.SOCK_STREAM if (socketType == 'tcp') else socket.SOCK_DGRAM

    #ip = 'fe80::aa63:f2ff:fe00:9af%eth0'
    for i in range(0, 5):
        FNULL = open(os.devnull, 'w')
        statusCode =  subprocess.call(['ping6', '-c', '1', '-q', ip + '%eth' + str(i) ], stdout=FNULL, stderr=subprocess.STDOUT)
        FNULL.close()
        if statusCode == 0:
            res = socket.getaddrinfo(ip + "%eth" + str(i), port, socket.AF_UNSPEC, socketType)
            for r in res:
                af, sock, proto, cname, sa = r
                try:
                    test = socket.socket(af, sock, proto)
                    if tls == 1:
                        test = ssl.wrap_socket(test,
                                               ca_certs=cert,
                                               cert_reqs=ssl.CERT_REQUIRED)
                    test.settimeout(20)
                    test.connect(sa)

                    print r

                    runSocket(test, bufsize)

                    test.close()
                    print("Socket closed")
                except socket.error, e:
                    print e
                    continue

def run4(ip, port, bufsize, socketType="tcp", cert=None):
    tls = 1 if (cert != None and socketType == 'tcp') else 0
    socketType = socket.SOCK_STREAM if (socketType == 'tcp') else socket.SOCK_DGRAM

    try:
        test = socket.socket(socket.AF_INET, socketType)
        if tls == 1:
            test = ssl.wrap_socket(test,
                                   ca_certs=cert,
                                   cert_reqs=ssl.CERT_REQUIRED)
        test.settimeout(20)
        test.connect((ip, port))

        runSocket(test, bufsize)

        test.close()
        print("Socket closed")

    except socket.error, e:
        print e


def main():
    testlink = Testlink(description='TCP/UDP Send receive test script')

    # Override args
    testlink.add_argument("-ip", "--ip", help="IP address of the target")
    testlink.add_argument("-p",  "--port", help="Port number of the target", type=int, default=1000)
    testlink.add_argument("-l",  "--bufsize", help="Buffer size", type=int, default=1024)
    testlink.add_argument("-s",  "--socket", help="tcp or udp socket", choices=['tcp', 'udp'], default='tcp')
    testlink.add_argument("-c",  "--cert", help="CA certificate path")

    args = testlink.parse_args()

    ipv4RegEx = "(\d{1,3}\.){3}\d{1,3}"
    ipv6RegEx = "(Address:\s)(([\dA-Fa-f]+:*)+)"

    for i in range(120):
        if testlink.block(ipv4RegEx, 2):
            args.ip = ipAddress.group(0)
            run4(args.ip, args.port, args.bufsize, args.socket, args.cert)
            break
        if testlink.block(ipv6RegEx, 2):
            args.ip = readString[ipv6Address.start(2):ipv6Address.end()]
            print "IPv6:'%s'" % readString[ipv6Address.start(2):ipv6Address.end()]
            run6(args.ip, args.port, args.bufsize, args.socket, args.cert)
            break

if __name__ == '__main__':
    main()
