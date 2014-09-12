#!/usr/bin/python

import sys
import time

def main(arg):
    print ("Hello World, I read in %s") % arg
    print ("TEST PASSED")

    #blahs
    time.sleep(5);
    return

if __name__ == "__main__":
    main(sys.argv[1:])
