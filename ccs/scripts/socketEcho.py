#!/usr/bin/python

import argparse
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
    parser = argparse.ArgumentParser(description='TCP/UDP Send receive test script')

    parser.add_argument("--cio", help="C I/O input file", type=argparse.FileType('r',0), required=True)

    # Override args
    parser.add_argument("-ip", "--ip", help="IP address of the target")
    parser.add_argument("-p",  "--port", help="Port number of the target", type=int, default=1000)
    parser.add_argument("-l",  "--bufsize", help="Buffer size", type=int, default=1024)
    parser.add_argument("-s",  "--socket", help="tcp or udp socket", choices=['tcp', 'udp'], default='tcp')
    parser.add_argument("-c",  "--cert", help="CA certificate path")

    args = parser.parse_args()

    ipv4RegEx = re.compile("(\d{1,3}\.?){4}")
    ipv6RegEx = re.compile("(Address:\s)(([\dA-Fa-f]+:*)+)")

    for i in range(120):
        print "%s attempt to start..." % i
        args.cio.seek(0)
        readString = args.cio.read()

        ipv6Address = ipv6RegEx.search(readString)
        ipAddress   = ipv4RegEx.search(readString)

        if (ipv6Address):
            args.ip = readString[ipv6Address.start(2):ipv6Address.end()]
            print "IPv6:'%s'" % readString[ipv6Address.start(2):ipv6Address.end()]
            run6(args.ip, args.port, args.bufsize, args.socket, args.cert)
            break
        if (ipAddress):
            args.ip = ipAddress.group(0)
            run4(args.ip, args.port, args.bufsize, args.socket, args.cert)
            break

        time.sleep(2)

if __name__ == '__main__':
    main()
