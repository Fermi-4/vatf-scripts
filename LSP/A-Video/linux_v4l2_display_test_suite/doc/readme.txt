A Brief  overview
===========================
V4L2 display test suite- This is a test suite to test V4L2 display on TI platforms.
Its look and feel is like any other linux utility.
Can be easily plugged into any host automation system or can be used independently for target side validation/automation.

Version
========
0.10

Platforms supported
====================
DM644x(Davinci),DM646x(Davinci-HD) and OMAP35x

Testing status(testing of this test suite on various platforms)
=================================================================
DM646x(Davinci-HD) -Regression tested
OMAP35x- Fully tested
DM644x(Davinci)- Not tested.

Package content
===============
src-Contains the source code. Has 3 directories interface,parser and testcases

src/interface- Contains the interface file. This has wrappers for driver APIs and data structures.This file is the only file that is platform specific and is different for different platforms.

src/parser- Contains the parser file. This has the parser logic to parse command line options.

src/testcases- Contains the test case files.

Makefiles- There are makefiles for each platform.  The makefiles have toolchain path in use,path to linux kernel and rule to build/place executables in required path.

inc- contains all header files

bin- contains all executables having appropriate platform names in them for easy identification.

doc- contains the README and architecture guide.

scripts-contains sample scripts for all platforms. This is just to show the usage. Many more configurations/scripts are possible/can be written based on refering to the sample scripts provided.

Steps to build
================
1)Make sure the kernel path,toolchain paths and the include directory are correctly configured in the Makefiles.
2)Issue the command - make -f Makefile_dm646x to build the V4L2 display test suite executable for DM646x(Davinci-HD) platform.
3)Issue the command - make -f Makefile_dm644x to build the V4L2 display test suite executable for DM644x(Davinci) platform.
4)Issue the command - make -f Makefile_omap35x to build the V4L2 display test suite executable for OMAP35x platform.

The above steps will build the V4L2 display executable for all platforms and place the executables in the bin directory.

Step to clean
=============
make -f Makefile_dm646x clean - Command to clean for the DM646x(Davinci-HD) platform.
make -f Makefile_dm644x clean - Command to clean for the DM644x(Davinci) platform.
make -f Makefile_omap35x clean - Command to clean for the omap35x platform.

Steps to run
================
1)Boot the DUT  using the uImage built from appropriate PSP release.
2)Refer to the sample scripts for usage on the executable or run the executable with --help option to know the usage.
For eg on Davinci-HD platform, you can run command like- ./dm646xV4l2DisplayTests --help.


Expected output(display)
==========================
When run without any argument, the test runs a default color bar display on composite interface for Davinci platforms and a VGA display on LCD for OMAP35x platform.
Refer to sample scripts for more options.

Supported features
=====================
Many configurable parameters like- width,height,number of buffers, number of frames, device node etc etc---All of which can be passed at run time eliminating need for any compilation. 
Parameters(command line options) for both short options like -d and long
options like --devicenode
Supports Multiple platforms. Currently tested on DM646x(Regression) and OMAP35x(Full).
Test all V4L2 supported ioctls(based on platform suport)
Test all suported API tests
Stability tests
Stress tests(with varying the number of frames)
Tests that support multiple interface- SVideo, composite etc
Tests that support multiple standrads- SD(NTSC,PAL), ED(480P,576P) and HD(720P,1080i).
Tests that support display from an image yuv file passed at command line.
In summary test for V4L2 framework supported display operations.

Pending features(from a V4l2 display framework perspective)
===========================================================
User pointer needs to be implemented. Currently all testcases are mmap based.
Multitasking test needs to be implemented.

Point of contact
================
Please send in your queries/comments to msprathap@ti.com

