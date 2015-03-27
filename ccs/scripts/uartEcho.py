#!/usr/bin/python

from testlink import Testlink
import serial
import time
import re

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

txData = [b'\n',
          b'2\n',
          b'03\n',
          b'04:\n',
          b'05:0\n',
          b'06:01\n',
          b'07:012\n',
          b'08:0123\n',
          b'09:01234\n',
          b'10:012345\n',
          b'11:0123456\n',
          b'12:01234567\n',
          b'13:012345678\n',
          b'14:0123456789\n',
          b'15:0123456789a\n',
          b'16:0123456789ab\n',
          b'17:0123456789abc\n',
          b'18:0123456789abcd\n',
          b'19:0123456789abcde\n',
          b'20:0123456789abcdef\n',
          b'21:0123456789abcdefg\n',
          b'22:0123456789abcdefgh\n',
          b'23:0123456789abcdefghi\n',
          b'24:0123456789abcdefghij\n',
          b'25:0123456789abcdefghijk\n',
          b'26:0123456789abcdefghijkl\n',
          b'27:0123456789abcdefghijklm\n',
          b'28:0123456789abcdefghijklmn\n',
          b'29:0123456789abcdefghijklmno\n',
          b'30:0123456789abcdefghijklmnop\n',
          b'31:0123456789abcdefghijklmnopq\n',
          b'32:0123456789abcdefghijklmnopqr\n',
          b'33:0123456789abcdefghijklmnopqrs\n',
          b'34:0123456789abcdefghijklmnopqrst\n',
          b'35:0123456789abcdefghijklmnopqrstu\n',
          b'36:0123456789abcdefghijklmnopqrstuv\n',
          b'37:0123456789abcdefghijklmnopqrstuvw\n',
          b'38:0123456789abcdefghijklmnopqrstuvwx\n',
          b'39:0123456789abcdefghijklmnopqrstuvwxy\n',
          b'40:0123456789abcdefghijklmnopqrstuvwxyz\n',
          b'41:0123456789abcdefghijklmnopqrstuvwxyz!\n',
          b'42:0123456789abcdefghijklmnopqrstuvwxyz!@\n',
          b'43:0123456789abcdefghijklmnopqrstuvwxyz!@#\n',
          b'44:0123456789abcdefghijklmnopqrstuvwxyz!@#$\n',
          b'45:0123456789abcdefghijklmnopqrstuvwxyz!@#$%\n',
          b'46:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^\n',
          b'47:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&\n',
          b'48:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*\n',
          b'49:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*(\n',
          b'50:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()\n',
          b'51:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()A\n',
          b'52:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()AB\n',
          b'53:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABC\n',
          b'54:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCD\n',
          b'55:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDE\n',
          b'56:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEF\n',
          b'57:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFG\n',
          b'58:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGH\n',
          b'59:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHI\n',
          b'60:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJ\n',
          b'61:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJK\n',
          b'62:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKL\n',
          b'63:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLM\n',
          b'64:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMN\n',
          b'65:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNO\n',
          b'66:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOP\n',
          b'67:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQ\n',
          b'68:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQR\n',
          b'69:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQRS\n',
          b'70:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQRST\n',
          b'71:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQRSTU\n',
          b'72:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQRSTUV\n',
          b'73:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQRSTUVW\n',
          b'74:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQRSTUVWX\n',
          b'75:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQRSTUVWXY\n',
          b'76:0123456789abcdefghijklmnopqrstuvwxyz!@#$%^&*()ABCDEFGHIJKLMNOPQRSTUVWXYZ\n']

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
    totalSent = 0
    totalRecv = 0
    currentLen = 0
    for loop in range(1, loopcount+1):
        for test in txData:
            currentLen = len(test)
            sent = serialObject.write(test)
            data = serialObject.read(len(test))
            totalSent += sent
            totalRecv += len(data)
            if sent != len(data) or test != data:
                if (verbose == True):
                    print ((bcolors.FAIL + "F: Test[%02d][T:% 6d|R:% 6d]: %s; Rev'd: %s" + bcolors.ENDC) % (loop, totalSent, totalRecv, test, data))
                else:
                    print (("F: Test[%02d][T:% 6d|R:% 6d]: %s") % (loop, totalSent, totalRecv, test))
                testPass = False
            else:
                if (verbose == True):
                    print ((bcolors.OKBLUE + "P: Test[%02d][T:% 6d|R:% 6d]: %s" + bcolors.ENDC) % (loop, totalSent, totalRecv, test))
                else:
                    print (("P: Test[%02d]: %s") % (loop, test))
    print("Total Sent: %d\nTotal Recv: %d" % (totalSent, totalRecv))
    return testPass

def main():
    print ("Starting UART Echo test script")
    testlink = Testlink(description="UART Echo test script")

    testlink.add_argument("-l", "--loop", help="UART echo loop count", type=int, default=10)
    testlink.add_argument("-t", "--type", dest='serialType', help="USB or UART", choices=['uart', 'usb'], default='uart')
    testlink.add_argument("-v", help="Verbose output", action='store_true')
    testlink.add_argument("--flowcontrol", help="Enable flow control for UART", action='store_true')

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

            if args.flowcontrol:
                serialPort = serial.Serial(port, baud, length, parity, stop, timeout = 3, rtscts = True)
            else:
                serialPort = serial.Serial(port, baud, length, parity, stop, timeout = 3)
            if args.v == True:
                print(serialPort)
            result = runTest(serialPort, args.loop, args.v)
            serialPort.close()
            if result == True:
                testlink.success()
        else:
            print ("--bench arg is missing a \'%s_port\'" % args.serialType)

    else:
        print("Regex: \"%s\" not found" % regexString)

    testlink.failure()

if __name__ == '__main__':
    main()
