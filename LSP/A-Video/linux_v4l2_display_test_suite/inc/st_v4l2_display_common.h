/******************************************************************************
**+-------------------------------------------------------------------------+**
**|                            ****                                         |**
**|                            ****                                         |**
**|                            ******o***                                   |**
**|                      ********_///_****                                  |**
**|                      ***** /_//_/ ****                                  |**
**|                       ** ** (__/ ****                                   |**
**|                           *********                                     |**
**|                            ****                                         |**
**|                            ***                                          |**
**|                                                                         |**
**|         Copyright (c) 1998-2008 Texas Instruments Incorporated          |**
**|                        ALL RIGHTS RESERVED                              |**
**|                                                                         |**
**| Permission is hereby granted to licensees of Texas Instruments          |**
**| Incorporated (TI) products to use this computer program for the sole    |**
**| purpose of implementing a licensee product based on TI products.        |**
**| No other rights to reproduce, use, or disseminate this computer         |**
**| program, whether in part or in whole, are granted.                      |**
**|                                                                         |**
**| TI makes no representation or warranties with respect to the            |**
**| performance of this computer program, and specifically disclaims        |**
**| any responsibility for any damages, special or consequential,           |**
**| connected with the use of this program.                                 |**
**|                                                                         |**
**+-------------------------------------------------------------------------+**
******************************************************************************/

/**
 *  \file   st_v4l2_display_common.h
 *
 *  \brief  This file contains the common functions
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \history    0.1    Prathap MS   Created
 */

#ifndef _ST_COMMON_H_
#define _ST_COMMON_H_

/* Standard Linux header files */
#include <string.h>
#include <stdlib.h>
#include <stDefines.h>
#include <stLog.h>

/* Return codes */
#define FAILURE -1
#define SUCCESS 0

/* Status codes */
#define TRUE 1
#define FALSE 0

/*Structure for holding the test options */
struct v4l2_display_testparams
{
/* Device node name */
char *devnode;
/* Number of buffers to request/enqueue */
int noofbuffers;
/*Number of frames to display */
int noofframes;
/* Open mode- Blocking/non blocking */
int openmode;
/* Width of the input image to be displayed */
int width;
/* Height of the input image to be displayed */
int height;
/* Pixel format of the input image to be displayed */
int pixfmt;
/* Rotation angle - Not yet implemented */
int rotation;
/* Factor by which an image can be cropped */
int cropfactor;
/* Factor by which image can be zoomed */
int zoomfactor;
};

/* Function declarations */
/* Function to generate color bar */
void colorbar_generate(unsigned char *addr, int width, int height, int order);
/* Function to print testcase options(print member values of
 * v4l2_display_testparams structure) */
void print_v4l2_display_test_params();

#endif /* _ST_COMMON_H_ */

/* vim: set ts=4 sw=4 tw=80 et:*/

