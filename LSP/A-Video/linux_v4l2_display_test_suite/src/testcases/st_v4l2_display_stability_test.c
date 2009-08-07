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

/*	File Name :   st_v4l2_display_stability_test.c

    This file contains code to test various resolutions supported by V4L2 driver

    (C) Copyright 2008, Texas Instruments, Inc

    @author     Prathap.M.S 
    @version    0.1 - Created             

 */

/* function prototypes for interface functions are defined here*/
#include "st_v4l2_display_interface.h"

#include "st_v4l2_display_common.h"

/* global variables */
char displaynode[25];

#define NUM_FRAMES 1000


/****************************************************************************
 * Function             - st_v4l2_display_stability_test
 * Functionality        - Function to display image of given width*height on the
 *                              all V4L2 supported windows
 * Input Params         - mode and interface. resolution of the image,  test case id.
 * Return Value         - None.
 * Note                 - None
 ****************************************************************************/
void st_v4l2_display_stability_test(struct v4l2_display_testparams *testoptions,  char* test_id,int nooftimes)
{

    int retVal = SUCCESS;
    int status = SUCCESS;
    struct st_v4l2_format st_fmt; 
    int st_img_type = 0;	
    int st_dev ;

    int i = 0;
    int loopcount=0;
    /* Retrieving test case options values */
    int st_width = testoptions->width;
    int st_height = testoptions->height;
    int noofbuffers = testoptions->noofbuffers;
    int noofframes = testoptions->noofframes; 
    int pixelfmt = testoptions->pixfmt;
    int cropfactor = testoptions->cropfactor;
    int zoomfactor = testoptions->zoomfactor;
    /* variables to track device state, mapping of buffers and state of V4L2 window */ 
    Bool openStatus = FALSE;
    Bool mmapStatus = FALSE;
    Bool winStatus = FALSE;

    /* Start test case */
    DBG_PRINT_TST_START((test_id));

    /* get device number for a device string to avoid further string operations */
    st_v4l2_set_device_number(testoptions->devnode, &st_dev);

    do
    {  
        for(loopcount = 0;loopcount < nooftimes;loopcount++)
        {
            if(testoptions->openmode == BLOCKING_OPEN_MODE)
            {
                /* open V4L2 display device */
                retVal = st_v4l2_display_open_interface(st_dev);
                if (SUCCESS != retVal)
                {
                    DBG_PRINT_ERR(("Failed to open V4L2 device /dev/video%d |", st_dev));
                    status = FAILURE;  
                    break;
                }
            }
            else
            {

                /* open V4L2 display device in non blocking mode */
                retVal = st_v4l2_display_open_nonblock_interface(st_dev);
                if (SUCCESS != retVal)
                {
                    if(MODE_NOT_SUPPORTED == retVal)
                    {
                        DBG_PRINT_ERR(("Non Blocking open mode is not supported"));
                        status = FAILURE;
                        break;
                    }
                    else
                    {
                        DBG_PRINT_ERR(("Failed to open V4L2 device /dev/video%d |", st_dev));
                        status = FAILURE;  
                        break;
                    }
                }
            }
            openStatus = TRUE; // device is opened

            DBG_PRINT_TRC0(("V4L2 device node /dev/video%d opened |", st_dev));
            /* get format */
            retVal = st_v4l2_display_getimg_interface(st_dev, &st_fmt);
            if (SUCCESS != retVal)
            {
                DBG_PRINT_ERR(("G_FMT Ioctl Failed |"));
                status = FAILURE;
                break;
            }
            DBG_PRINT_TRC0(("G_FMT Ioctl Passed |"));
            /* set format */
            st_fmt.width = st_width;
            st_fmt.height = st_height;
            st_fmt.type = BUFTYPE;
            st_fmt.pixelformat = pixelfmt;
            retVal = st_v4l2_display_setimg_interface(st_dev, &st_fmt);
            if (SUCCESS != retVal)
            {
                DBG_PRINT_ERR(("S_FMT Ioctl Failed |"));
                status = FAILURE;
                break;
            }
            DBG_PRINT_TRC0(("S_FMT Ioctl Passed |"));
            if(cropfactor != 0)
            {
                retVal = st_v4l2_display_set_crop_interface(st_dev,cropfactor);
                if (SUCCESS != retVal)
                {
                    if(OPERATION_NOT_SUPPORTED == retVal)
                    {
                        DBG_PRINT_ERR(("Set crop not supported on this platform |"));
                        status = FAILURE;
                        break;
                    }
                    else
                    {
                        DBG_PRINT_ERR(("Set crop Ioctl Failed |"));
                        status = FAILURE;
                        break;
                    }
                }
            }

            if(zoomfactor != 0)
            {
                retVal = st_v4l2_display_set_zoom_interface(st_dev,zoomfactor);
                if (SUCCESS != retVal)
                {
                    if(OPERATION_NOT_SUPPORTED == retVal)
                    {
                        DBG_PRINT_ERR(("Set crop with zoom not supported on this platform|\n"));
                        status = FAILURE;
                        break;
                    }
                    else
                    {
                        DBG_PRINT_ERR(("Set Zoom Ioctl Failed |"));
                        status = FAILURE;
                        break;
                    }
                }
            }


            /* Request buffer */
            retVal = st_v4l2_display_request_buffer_interface(st_dev,noofbuffers);
            if (SUCCESS != retVal)
            {
                DBG_PRINT_ERR(("REQBUF Ioctl Failed |"));
                status = FAILURE;
                break;
            }

            DBG_PRINT_TRC0(("REQBUF Ioctl Passed |"));

            /* Query buffer */
            retVal = st_v4l2_display_query_buffer_mmap_interface(st_dev);

            if (QUERYBUFFAIL == retVal)
            {
                DBG_PRINT_ERR(("QUERYBUF Ioctl Failed |"));
                status = FAILURE;
                break;
            }

            DBG_PRINT_TRC0(("QUERYBUF Ioctl Passed |"));
            if (FAILURE == retVal)
            {
                DBG_PRINT_ERR(("Mmap Failed |"));
                status = FAILURE;
                break;
            }

            DBG_PRINT_TRC0(("Mmap Passed |"));

            /* Setting mmmapstatus as TRUE as mmap has passed if control reaches
             * here*/
            mmapStatus = TRUE;

            /* get format */
            retVal = st_v4l2_display_getimg_interface(st_dev, &st_fmt);
            if (SUCCESS != retVal)
            {
                DBG_PRINT_ERR(("G_FMT Ioctl Failed |"));
                status = FAILURE;
                break;
            }
            DBG_PRINT_TRC0(("G_FMT Ioctl Passed |")); 

            fill_lines(st_width);
            /* Enqueue buffers */
            retVal = st_v4l2_display_enqueue_buffers(st_dev);
            if (SUCCESS != retVal)
            {
                DBG_PRINT_ERR(("Enqueue Failed |"));
                status = FAILURE;
                break;
            }

            DBG_PRINT_TRC0(("Enqueuing Buffers Passed |"));

            /* Stream on */
            retVal = st_v4l2_display_streamon_interface(st_dev);
            if (SUCCESS != retVal)
            {
                DBG_PRINT_ERR(("STREAM ON Failed |"));
                status = FAILURE;
                break;
            }

            DBG_PRINT_TRC0(("Streaming on for frames | %d",noofframes));

            /* Display frames */       
            retVal = st_v4l2_display_color_bar(st_dev,noofframes);
            if (SUCCESS != retVal)
            {
                DBG_PRINT_ERR(("Display Failed |"));
                status = FAILURE;
                break;
            }

            DBG_PRINT_TRC0(("Display Successful"));

            /* Stream off */       
            retVal = st_v4l2_display_streamoff_interface(st_dev);
            if (SUCCESS != retVal)
            {
                DBG_PRINT_ERR(("STREAM OFF Failed |"));
                status = FAILURE;
                break;
            }

            DBG_PRINT_TRC0(("Streaming off.....Stopping display |"));

            /* unmap buffers if mapped */
            if (TRUE == mmapStatus)
            {
                /* close v4l2 device */
                retVal = st_v4l2_display_unmap_interface(st_dev);
                if (SUCCESS != retVal)
                {
                    DBG_PRINT_ERR(("unmap failed |"));
                    status = FAILURE;
                    break;
                } 

                mmapStatus = FALSE; // buffers not mapped

                DBG_PRINT_TRC0(("Buffers unmapped Successfully |"));
            }

            /* close device if opened */
            if (TRUE == openStatus)
            {
                /* close v4l2 device */
                retVal = st_v4l2_display_close_interface(st_dev);
                if (SUCCESS != retVal)
                {
                    DBG_PRINT_ERR(("V4L2 Device could not be closed |"));
                    status = FAILURE;
                    break;
                } 

                openStatus = FALSE; // device is closed

                DBG_PRINT_TRC0(("V4L2 device node /dev/video%d closed |",st_dev));
            }
        }
        break;

    }while(SUCCESS != retVal);


    /* print status/result of the test case */
    if (FAILURE == status)
    {
        DBG_PRINT_TST_RESULT_FAIL((test_id));
    }
    else
    {
        DBG_PRINT_TST_RESULT_PASS((test_id));
    }
    /* end test case */
    DBG_PRINT_TST_END((test_id));	

    return;

}

/* vim: set ts=4 sw=4 tw=80 et:*/


