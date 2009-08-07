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
/*	File Name :   st_v4l2_display_interface.h

    This file abstracts v4l2 driver structures, macros and enums

    (C) Copyright 2008, Texas Instruments, Inc

    @author     Prathap M.S
    @version    0.1 - Created             
 */

#ifndef _ST_V4L2_DISPLAY_INTERFACE_H_
#define _ST_V4L2_DISPLAY_INTERFACE_H_

/* Generic header files */
#include <stdio.h>
#include <string.h>
#include <getopt.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <asm/types.h>		
#include <time.h>

/* V4L2 specific header file */
#include <linux/videodev.h>
#include <linux/videodev2.h>


/*Testcode related Header files*/
#include <stDefines.h>
#include <st_v4l2_display_common.h>


#define MAX_DEV		  5 // This value can be changed when more V4L2_DISPLAY devices are introduced
#define  MAX_BUFFER      3

/* image types */
#define ST_YUYV         V4L2_PIX_FMT_YUYV
#define ST_UYVY         V4L2_PIX_FMT_UYVY
#define ST_RGB_565      V4L2_PIX_FMT_RGB565
#define ST_RGB_888      V4L2_PIX_FMT_RGB24


/* output interfaces */
#define ST_COMPOSITE    1
#define ST_COMPONENT    2
#define ST_SVIDEO       3
#define ST_DVI          4

/* Standard macros */
/* SD standrads */
#define NTSC_MODE_NAME "NTSC"
#define PAL_MODE_NAME "PAL"

/* HD standards */
#define HD_720P_50_MODE_NAME "720P-50"
#define HD_720P_60_MODE_NAME "720P-60"
#define HD_1080I_30_MODE_NAME "1080I-30"
#define HD_1080I_25_MODE_NAME "1080I-25"

/*ED standards */
#define ED_480P_60_MODE_NAME "480P-60"
#define ED_576P_50_MODE_NAME "576P-50"

#define SVIDEO_OUTPUT_NAME "SVIDEO"
#define COMPOSITE_OUTPUT_NAME "COMPOSITE"
#define COMPONENT_OUTPUT_NAME "COMPONENT"
/* Buffer type */
#define BUFTYPE V4L2_BUF_TYPE_VIDEO_OUTPUT

/* Open() call modes */
#define BLOCKING_OPEN_MODE 0
#define NON_BLOCKING_OPEN_MODE 1

#define DEFAULT_OPEN_MODE BLOCKING_OPEN_MODE

/* max, min and default number of buffers */
#define MAX_BUFFERS     8 
#define MIN_BUFFERS		3
#define ST_VIDEO_NUM_BUFS   3

/* Enable color bar display */
#define COLOR_BAR_DISPLAY

/* Return values */
#define SUCCESS         0
#define FAILURE	        -1

/* max command length */
#define TEST_ID_LENGTH      100

/* ERROR CODES - Helpful to differentiate between failures from non supported features*/
#define DEV_NOT_AVAILABLE   			-10
#define ROTATION_NOT_SUPPORTED		-11
#define MODE_NOT_SUPPORTED 	-12
#define OPERATION_NOT_SUPPORTED -14
#define QUERYBUFFAIL    -2

/* Wrapper structure for v4l2_fmt */
struct st_v4l2_format
{
    int width;
    int height;
    int  pixelformat;
    int type;
};

/* function prototype */
/* Wrapper for open() sysyem call */
int st_v4l2_display_open_interface(int dev);
/* Wrapper for close() sysyem call */
int st_v4l2_display_close_interface(int dev);
/* Wrapper for display APIs */
int st_v4l2_display_display_interface(int dev, int width, int height, int st_img_type);
/* Wrapper for QBUF API */
int st_v4l2_display_enqueue_buffers(int dev);

/* Functions to set sysfs paths for different standards/interfaces */
void set_sysfs_path_for_ntsc();
void set_sysfs_path_for_pal();
void set_sysfs_path_for_composite();
void set_sysfs_path_for_component();
void set_sysfs_path_for_svideo();

/* Functions to check on user passed command line values */
int check_pixel_format();
int check_output_path();
int check_interface();
int check_std();

#endif /* _ST_V4L2_DISPLAY_INTERFACE_H_ */

/* vim: set ts=4 et sw=4: */
