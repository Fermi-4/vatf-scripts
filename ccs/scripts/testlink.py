#!/usr/bin/python

import argparse
import sys
import re
import time
import signal

class Testlink(argparse.ArgumentParser):
    """
    Testlink module to be used by testlink test scripts. It simplifies the
    testing proceedure by providing a standard interface to the Testlink
    system. By using this module, test scripts are kept compliant with
    the TI-RTOS Testlink scripts.
    """
    def __init__(self, *args, **kwargs):
        """
        Constructor initializes similar as the ArgumentParser in the argparse module with the
        addition that it automatically adds '--cio' and '--bench' options.
        """
        argparse.ArgumentParser.__init__(self, *args, **kwargs)
        self.add_argument("--cio", help="C I/O input file", type=argparse.FileType('r',0), required=True)
        self.add_argument("--bench", help="Optional set of arguments supplied by the bench file")
        self.bench = dict()

    def parse_args(self):
        """
        This function perform similarly as the argparser.parse_args() API call
        and should be called after any additional arguments have been added
        to the Testlink module
        User arguments are added by calling "testlink.add_arguments()". See
        the argparse module for this documentation.
        """
        self.args = argparse.ArgumentParser.parse_args(self)
        if self.args.bench:
            for item in self.args.bench.split('~'):
                pair = item.split('=')
                self.bench[pair[0]] = pair[1]
        return self.args

    def getBenchArg(self, key):
        """
        This function will return the value of a argument passed in by the
        testlink script.
        testlink.getBenchArg("uart") ==> "/dev/ttyUSB0"
        :param key: A sub argument that was passed in via the '--bench'
                    argument
        :return: Returns the value of the key if it was detected in the
                 '--bench', otherwise it returns None
        """
        return self.bench.get(key)

    def getAvailBenchArgs(self):
        """
        This function returns a list
        :return: Dictionary of available bench arguments
        """
        return self.bench.keys()

    def read(self, *args, **kwargs):
        """
        Function reads the C I/O input file supplied by testlink
        """
        return self.args.cio.read(*args, **kwargs)

    def readline(self, *args, **kwargs):
        """
        Function readline's the C I/O input file supplied by testlink
        """
        return self.args.cio.readline(*args, **kwargs)

    def seek(self, *args, **kwargs):
        """
        Function seeks the C I/O input file supplied by testlink
        """
        return self.args.cio.seek(*args, **kwargs)

    def tell(self, *args, **kwargs):
        """
        Function tell's the C I/O input file supplied by testlink
        """
        return self.args.cio.tell(*args, **kwargs)

    def success(self):
        """
        Test script that determines that a test has passed should call
        "testlink.success()"
        :return: This function does not return
        """
        print("Test passed")
        sys.exit(0)

    def failure(self):
        """
        Test script that determines that a test has failed should call
        "testlink.failure()"
        :return: This function does not return
        """
        print("Test failed")
        sys.exit(1)

    def block(self, text, Timeout=120):
        """
        :param text: a regular expression pattern (or a string pattern)
        :param Timeout: read attempts in seconds
        :return: True if regex was found, else False
        """
        assert isinstance(text, str)
        for i in range(Timeout):
            self.seek(0)
            match = re.search(text, self.read())
            if match:
                return True
            time.sleep(1)
        return False

if __name__ == '__main__':
    help(Testlink)
