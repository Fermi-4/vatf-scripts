/*******************************************************************************
 **+--------------------------------------------------------------------------+**
 **|                            ****                                          |**
 **|                            ****                                          |**
 **|                            ******o***                                    |**
 **|                      ********_///_****                                   |**
 **|                      ***** /_//_/ ****                                   |**
 **|                       ** ** (__/ ****                                    |**
 **|                           *********                                      |**
 **|                            ****                                          |**
 **|                            ***                                           |**
 **|                                                                          |**
 **|         Copyright (c) 2007-2008 Texas Instruments Incorporated           |**
 **|                        ALL RIGHTS RESERVED                               |**
 **|                                                                          |**
 **| Permission is hereby granted to licensees of Texas Instruments           |**
 **| Incorporated (TI) products to use this computer program for the sole     |**
 **| purpose of implementing a licensee product based on TI products.         |**
 **| No other rights to reproduce, use, or disseminate this computer          |**
 **| program, whether in part or in whole, are granted.                       |**
 **|                                                                          |**
 **| TI makes no representation or warranties with respect to the             |**
 **| performance of this computer program, and specifically disclaims         |**
 **| any responsibility for any damages, special or consequential,            |**
 **| connected with the use of this program.                                  |**
 **|                                                                          |**
 **+--------------------------------------------------------------------------+**
 *******************************************************************************/

/*  File Name :   st_v4l2_parser.c

    This file contains code to test various resolutions supported by V4L2 driver

    (C) Copyright 2008, Texas Instruments, Inc

    @author     Prathap.M.S 
    @version    0.1 - Created

 */ 

/* Generic header files */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#define __USE_GNU
#include <fcntl.h>
#include <getopt.h>
#include <pthread.h>
#include <signal.h>
#include <sched.h>
#include <string.h>
#include <time.h>
#include <errno.h>

#include <linux/unistd.h>

#include <sys/prctl.h>
#include <sys/stat.h>
#include <sys/sysinfo.h>
#include <sys/types.h>

/* Test case common header file */
#include "st_v4l2_display_common.h"

#define DEFAULT_STABILITY_COUNT 1000

/* Default output interface - LCD */
char *displayout = "lcd";

/* Default values related to test */
char *testcaseid = "DisplayTests";
char *testname = "Functionality";

/* Test case options structure */
extern struct v4l2_display_testparams testoptions;

/* The below will hold the user passed strings from command line */
static char *displaynode = NULL;
char *pixelformat = "RGB565";
char *standard = "ntsc";
char *interface = "composite";
char *filename ="yuv";

/* This is to indicate if its a special test */
int othertests=0;

/*Function to display test suite version */
void display_v4l2_display_testsuite_version();

/* Place all extern functions here */

/* Function to check pixel format */
extern int check_pixel_format();

/* Function to check output path */
extern int check_output_path();

/* Function to check interface */
extern int check_interface();

/* Function to check standard */
extern int check_std();

/* Function to display help/usage instructions */
extern void display_help();

/****************************************************************************
 * Function             - process_v4l2_display_test_options 
 * Functionality        - This function parses the command line options and vallues passed for the options
 * Input Params         -  argc,argv
 * Return Value         -  None
 * Note                 -  None
 ****************************************************************************/
static void process_v4l2_display_test_options(int argc, char *argv[])
{
    int error=FALSE;
    int version=FALSE;
    int help = FALSE;
    int othertests = FALSE;
    int displayfromfile = FALSE;
    int stabilitycount = DEFAULT_STABILITY_COUNT;
    for (;;) {
        int option_index = 0;
        /** Options for getopt - New test case options added need to be
         * populated here*/
        static struct option long_options[] = {
            {"displaynode", optional_argument, NULL, 'd'},
            {"displayout", optional_argument, NULL, 'o'},
            {"openmode", optional_argument, NULL, 'b'},
            {"width", optional_argument, NULL, 'w'},
            {"height", optional_argument, NULL, 'h'},
            {"countofbuffers", optional_argument, NULL, 'c'},
            {"noofframes", optional_argument, NULL, 'n'},
            {"stabilitycount", optional_argument, NULL, 'C'},
            {"ratiocrop", optional_argument, NULL, 'r'},
            {"zoomfactor", optional_argument, NULL, 'z'},
            {"testcaseid", optional_argument, NULL, 't'},
            {"testname", optional_argument, NULL, 'T'},
            {"filename", optional_argument, NULL, 'f'},
            {"pixelformat", optional_argument, NULL, 'p'},
            {"standard", optional_argument, NULL, 's'},
            {"interface", optional_argument, NULL, 'i'},
            {"version", no_argument, NULL, 'v'},
            {"help", no_argument, NULL, '?'},
            {NULL, 0, NULL, 0}
        };
        int c = getopt_long (argc, argv, "d:o:b:w:h:c:n:C:r:z:t:T:f:p:s:i::v?",
                long_options, &option_index);
        if (c == -1)
        {
            break;
        }
        switch (c) {
            case 'd':  
                if(optarg != NULL)
                {
                    testoptions.devnode = optarg;
                }
                else if(optind<argc && argv[optind])
                {
                    testoptions.devnode = argv[optind];
                }
                break;
            case 'o' : 
                if(optarg!= NULL) 
                {
                    displayout = optarg;
                }
                else if(optind<argc && argv[optind])
                {
                    displayout = argv[optind];
                }
                break;
            case 'b':  
                if(optarg != NULL)
                {
                    testoptions.openmode = atoi(optarg);
                }
                else if(optind<argc && argv[optind])
                {
                    testoptions.openmode = atoi(argv[optind]);
                }
                break;
            case 'w' : 
                if(optarg!= NULL)
                {
                    testoptions.width= atoi(optarg);
                }
                else if(optind<argc && argv[optind])
                {
                    testoptions.width  = atoi(argv[optind]);
                }
                break;
            case 'h' : 
                if(optarg != NULL)
                { 
                    testoptions.height = atoi(optarg);
                }
                else if(optind<argc && argv[optind])
                {
                    testoptions.height  = atoi(argv[optind]);
                }
                break; 
            case 'c' : 
                if(optarg != NULL)
                { 
                    testoptions.noofbuffers = atoi(optarg);
                }
                else if(optind<argc && argv[optind])
                {
                    testoptions.noofbuffers  = atoi(argv[optind]);
                }
                break;
            case 'n' : 
                if(optarg != NULL)
                {
                    testoptions.noofframes = atoi(optarg);
                }
                else if(optind<argc && argv[optind])
                {
                    testoptions.noofframes  = atoi(argv[optind]);
                }
                break;
            case 'C' : 
                if(optarg != NULL)
                {
                    stabilitycount = atoi(optarg);
                }
                else if(optind<argc && argv[optind])
                {
                    stabilitycount  = atoi(argv[optind]);
                }
                break;
            case 'r' : 
                if(optarg != NULL)
                {
                    testoptions.cropfactor = atoi(optarg);
                }
                else if(optind<argc && argv[optind])
                {
                    testoptions.cropfactor  = atoi(argv[optind]);
                }
                break;
            case 'z' : 
                if(optarg != NULL)
                {
                    testoptions.zoomfactor = atoi(optarg);
                }
                else if(optind<argc && argv[optind])
                {
                    testoptions.zoomfactor  = atoi(argv[optind]);
                }
                break;
            case 't' : 
                if(optarg != NULL)
                { 
                    testcaseid=optarg;
                }
                else if(optind<argc && argv[optind])
                {
                    testcaseid = argv[optind];
                }
                break;
            case 'T' : 
                if(optarg != NULL)
                { 
                    testname=optarg;
                }
                else if(optind<argc && argv[optind])
                {
                    testname = argv[optind];
                }
                othertests = TRUE;
                break;
            case 'f' : 
                if(optarg != NULL)
                { 
                    filename=optarg;
                }
                else if(optind<argc && argv[optind])
                {
                    filename = argv[optind];
                }
                displayfromfile = TRUE;
                break;
            case 'p' : 
                if(optarg != NULL)
                {
                    pixelformat=optarg;
                }
                else if(optind<argc && argv[optind])
                {
                    pixelformat = argv[optind];
                }
                break;
            case 's' :
                if(optarg != NULL)
                {
                    standard=optarg;
                }
                else if(optind<argc && argv[optind])
                {
                    standard = argv[optind];
                }
                break;
            case 'i' :
                if(optarg != NULL)
                {
                    interface=optarg;
                }
                else if(optind<argc && argv[optind])
                {
                    interface = argv[optind];
                }
                break;
            case 'v' : 
                display_v4l2_display_testsuite_version();
                version= TRUE;
                break;
            case '?': 
                help = TRUE; break;

        }
    }
    /* If any error in usage, values provided for options, display help to user*/ 
    if(help !=TRUE && version !=TRUE)
    {
        if(FAILURE == check_pixel_format() || FAILURE == check_interface() || FAILURE == check_std() || FAILURE == check_output_path())
        {
            error = TRUE;
        }	
    } 
    if (error == TRUE || help ==TRUE)
    {
        display_v4l2_display_test_suite_help();
    }

    if((version != TRUE && help !=TRUE) && (error != TRUE))
    {       
        print_v4l2_display_test_params(&testoptions);
        if(othertests != TRUE)
        {
            if(displayfromfile != TRUE)
            {
                st_v4l2_display_test(&testoptions,testcaseid);
            }
            else
            {
                st_v4l2_display_from_file_test(&testoptions,testcaseid,filename);
            }
        }
        else if(strcmp(testname,"stability") == SUCCESS)
        {
            st_v4l2_display_stability_test(&testoptions,testcaseid,stabilitycount);
        }
        else if(strcmp(testname,"api") == SUCCESS)
        {
            st_v4l2_display_api_test(&testoptions,testcaseid);
        }
        else
        {
            printf("Test not supported\n");
        } 
    }
}


/****************************************************************************
 * Function             - display_version
 * Functionality        - This function displays the test suite version
 * Input Params         - None 
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void display_v4l2_display_testsuite_version()
{
    printf("v4l2DisplayTestSuite V %1.2f\n", VERSION_STRING);
}

/****************************************************************************
 * Function             - Main function
 * Functionality        - This is where the execution begins
 * Input Params         - argc,argv
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
int main(int argc, char **argv)
{
    /* Initialize options with default vales */	
    init_v4l2_display_test_params();
    /* Invoke the parser function to process the command line options */
    process_v4l2_display_test_options(argc, argv);
    return 0;
}
/* vi: set ts=4 sw=4 tw=80 et:*/

