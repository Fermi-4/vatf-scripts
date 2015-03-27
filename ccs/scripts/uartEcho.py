#!/usr/bin/python

from testlink import Testlink
import serial
import time
import re

txData = [b'nibb',
          b'8--bytes',
          b'8--bytes plus',
          b'16-byte testcase',
          b'16-byte testcase plus']
#          b'0123456789012345678901234567890123456789012345678901234567890'\
#          b'          1         2         3         4         5         6']
#          b'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'\
#          b'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'\
#          b'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'\
#          b'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'\
#         b'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'\
#         b'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'\
#         b'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'\
#         b'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ'];

STOP_BITS = {
    0: serial.STOPBITS_ONE,
    1: serial.STOPBITS_TWO,
}

PARITY_BITS = {
    0: serial.PARITY_NONE,
    1: serial.PARITY_EVEN,
    2: serial.PARITY_ODD,
    3: serial.PARITY_SPACE,
    4: serial.PARITY_MARK,
}

LENGTH_BITS = {
    0: serial.FIVEBITS,
    1: serial.SIXBITS,
    2: serial.SEVENBITS,
    3: serial.EIGHTBITS,
}

def runTest(serialObject, loopcount, verbose=False):
    assert(serialObject is not None)
    testPass = True
    for loop in range(1, loopcount+1):
        for test in txData:
            print ("Test[%02d]: %s" % (loop, test))
            sent = serialObject.write(test)
            data = serialObject.read(len(test))
            if sent != len(data) and test != data:
                print ('Test[%02d] failed' % loop)
                if (verbose == True):
                    print ('Sent %d and received %d' % (sent, len(data)))
                    print ('Sent:  \"%s\"\nRecv:  \"%s\"' % (test, data))
                testPass = False
                break;
    return testPass

def main():
    print ("Starting UART Echo test script")
    testlink = Testlink(description="UART Echo test script")

    testlink.add_argument("-l", "--loop", help="UART echo loop count", type=int, default=10)
    testlink.add_argument("-t", "--type", dest='serialType', help="USB or UART", choices=['uart', 'usb'], default='uart')
    testlink.add_argument("-v", help="Verbose output", action='store_true')

    args = testlink.parse_args()

    regexString = "Starting.*example"

    print ("Waiting for regex pattern '%s'..." % regexString)
    if testlink.block(regexString):
        # Needed to allow the target to call UART_read()...
        time.sleep(3)
        #port = None
        if   args.serialType == 'uart':
            port = testlink.getBenchArg('uart_port')
        elif args.serialType == 'usb':
            port = testlink.getBenchArg('usb_port')

        if port:
            # Default uart parameters
            baud   = 9600
            length = LENGTH_BITS[3]
            parity = PARITY_BITS[0]
            stop   = STOP_BITS[0]

            # If we have other parameter in CIO, then use those
            testlink.seek(0)
            uartParams = re.match("B:(\d*)_L:(\d*)_P:(\d*)_S:(\d*)", testlink.read())
            if uartParams:
                print("Using external UART parameters", uartParams.group(0))
                baud   = int(uartParams.group(1))
                length = LENGTH_BITS[int(uartParams.group(2))]
                parity = PARITY_BITS[int(uartParams.group(3))]
                stop   = STOP_BITS[int(uartParams.group(4))]

            serialPort = serial.Serial(port, baud, length, parity, stop, timeout = 10)
            if args.v == True:
                print(serialPort)
            result = runTest(serialPort, args.loop, args.v)
            serialPort.close()
            if result == True:
                testlink.success()
        else:
            print ("--bench arg is missing a \'%s_port\'" % args.serialType)

    else:
        print("Regex: \"%s\" not found" % regexString);

    testlink.failure()

if __name__ == '__main__':
    main()
