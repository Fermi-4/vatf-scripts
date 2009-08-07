###############################################################################
##+-------------------------------------------------------------------------+##
##|                            ####                                         |##
##|                            ####                                         |##
##|                            ######o###                                   |##
##|                      ########_///_####                                  |##
##|                      ##### /_//_/ ####                                  |##
##|                       ## ## (__/ ####                                   |##
##|                           #########                                     |##
##|                            ####                                         |##
##|                            ###                                          |##
##|                                                                         |##
##|         Copyright (c) 2007-2008 Texas Instruments Incorporated          |##
##|                        ALL RIGHTS RESERVED                              |##
##|                                                                         |##
##| Permission is hereby granted to licensees of Texas Instruments          |##
##| Incorporated (TI) products to use this computer program for the sole    |##
##| purpose of implementing a licensee product based on TI products.        |##
##| No other rights to reproduce, use, or disseminate this computer         |##
##| program, whether in part or in whole, are granted.                      |##
##|                                                                         |##
##| TI makes no representation or warranties with respect to the            |##
##| performance of this computer program, and specifically disclaims        |##
##| any responsibility for any damages, special or consequential,           |##
##| connected with the use of this program.                                 |##
##|                                                                         |##
##+-------------------------------------------------------------------------+##
###############################################################################


#   ============================================================================
#   @file   omap35x_v4l2_display_tests_sample_script
#
#   @desc   This script contains some sample usage of v4l2 display test suite on omap35x platform
#           Make sure the executable and script is in the same directory as sample script is trying to execute from current directory(pwd)
#   @ver    0.10
#   ============================================================================


#Prints the usage/help
./dm644xV4l2DisplayTests --help

#Prints the version
./dm644xV4l2DisplayTests -v

#Runs the default color bar display-No options provided- Runs by default on TV out over composite interface
./dm644xV4l2DisplayTests 

#Run the display test- Displays default color bar with width (-w) 720, height (-h) 480, number of buffers queued is (-c) 3 and number of iterations (-n) 1000
./dm644xV4l2DisplayTests -w 720 -h 480 -c 3 -n 1000

#Run the display test- Displays default color bar with width (-w) 720, height (-h) 480(long options support)
./dm644xV4l2DisplayTests --width 720 --height 480

#Run the API test- Runs all APIs supported. -T stands for special tests like api,stability. Currently only api,stability can be passed for -T. Wheraes the smsmall letter -t stands for test name(will be logged) and helpful for testers reference. User can pass any string to small -t option but string shouldn't have any spaces.
./dm644xV4l2DisplayTests -T api -t apitests

#Run the stability Test
./dm644xV4l2DisplayTests -T stability

#Displays the file stefan_qvga_422.yuv
#Showing the usage- Commented because cannit ship the yuv files as part of package and yuv file names can be different.Just showing the usage here.Also on Davinci-HD only YUV422UVP (a different format) is supprted. So use file of that format only
#./dm644xV4l2DisplayTests -f stefan_qvga_422.yuv -w 320 -h 240

#runs the default color bar test with PAL standard on composite interface
./dm644xV4l2DisplayTests -s pal

#runs the default color bar test with NTSC standard over svideo interface
./dm644xV4l2DisplayTests -s ntsc -i svideo

#Stress Test- Run the display test overnight- Displays default color bar with number of buffers queued is 4 overnight
./dm644xV4l2DisplayTests -c 4 -n 864000 -t stress

#Displays default color bar with some reference log useful for testers reference. The option passed will be printed as part of logging
./dm644xV4l2DisplayTests -t sep30_lsprelease_080_test

#Run the stability test for 10 times on VID2 window.By changing -C to high value, it can run over night and detect for any memory leak/crash.
# -d stands for device node and can be passed as command line
./dm644xV4l2DisplayTests -d /dev/video2 -T stability -C 10


