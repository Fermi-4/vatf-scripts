/******************************************************************************
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
 **|         Copyright (c) 1998-2007 Texas Instruments Incorporated           |**
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
/**
 *  \file   vdceResize.c
 *
 *  \brief  This file measures the time taken for resize operartion
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     Prathap MS     Created
 *              0.2     Prathap MS     Updated as per driver code changes 
 *              0.3     Saumya Agarwal     Updated for user input
 */

/* Standard header file */
#include <stdio.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>
#include <asm/arch/davinci_vdce.h>

/* Package header file */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

/* Device node for VDCE */
static char devicename[25];

static int in_width, in_height, in_pitch, out_width, out_height, out_pitch;


static char inputfile[80];

#define LOOPCOUNT 2000
#define OUTPUTFILE	    "resize_output.yuv"

void usageResize()
{  
    PERFLOG("./perfTest FRResize {Device name} {input width} {input height} {inputFilename} {output width} {output height}\n");
}

/*******************************************************************************
  Function Declarations
 ******************************************************************************/
/* Functions to read/write frame from/to YUV file */
extern void read_frame_from_file(unsigned char *,char *,int);
extern void write_frame_to_file(unsigned char *, char *,int);

/* Function to configure vdce parameters */
int  configure_vdce_engine(int, int, int, int, int);

/* Function to resize*/
int  resize(int);


/******************************************************************************
  Main function 	
 *******************************************************************************/
int vdce_resize(int argc,  const char **argv)
{
    int ret            = 0;
    int vdcefd         = 0;
    vdce_reqbufs_t	reqbuf;
    vdce_buffer_t buffer;
    void *inaddress,*outaddress;

    if(argc == 0 || argc < 6)
    {   usageResize();
        return -1;
    }

    /* get the device name*/
    getNextTokenString(&argc, argv, devicename);

    /* get input width */
    getNextTokenInt(&argc, argv, &in_width);

    /* get input height */
    getNextTokenInt(&argc, argv, &in_height);

    /* get input filename */
    getNextTokenString(&argc, argv, inputfile );

    /* get output width */
    getNextTokenInt(&argc, argv, &out_width);

    /* get output height */
    getNextTokenInt(&argc, argv, &out_height);


    in_pitch = in_width;
    out_pitch = out_width;

    vdcefd = open((const char *)devicename,O_RDWR);
    if( vdcefd < 0){
        perror("Unable to open VDCE Driver.\n");
        return -1;
    }

    /* Request input buffer */
    reqbuf.buf_type = VDCE_BUF_IN;
    reqbuf.num_lines = in_height;
    reqbuf.bytes_per_line = in_pitch;
    reqbuf.image_type = VDCE_IMAGE_FMT_422;
    reqbuf.count = 1;

    if (ioctl(vdcefd, VDCE_REQBUF, &reqbuf) < 0) {
        perror("buffer allocation error for input.\n");
        return -1;
    }

    /* Request output buffer */
    reqbuf.buf_type = VDCE_BUF_OUT;
    reqbuf.num_lines = out_height;
    reqbuf.bytes_per_line = out_pitch;
    reqbuf.image_type = VDCE_IMAGE_FMT_422;
    reqbuf.count =1;

    if (ioctl(vdcefd, VDCE_REQBUF, &reqbuf) < 0) {
        perror("buffer allocation error for output.\n");
        return -1;
    }

    /* Query input buffer */
    buffer.buf_type = VDCE_BUF_IN;
    buffer.index = 0;
    if (ioctl(vdcefd, VDCE_QUERYBUF, &buffer) < 0) {
        perror("buffer query  error.\n");
        return -1;
    }

    /* mmap input buffer */ 
    inaddress =
        mmap(NULL, buffer.size,
                PROT_READ | PROT_WRITE, MAP_SHARED,
                vdcefd, buffer.offset);
    if (inaddress == MAP_FAILED) {
        perror("\nerror in mmaping output buffer");
        return -1;
    }

    /* Query output buffer */
    buffer.buf_type = VDCE_BUF_OUT;
    buffer.index = 0;
    if (ioctl(vdcefd, VDCE_QUERYBUF, &buffer) < 0) {
        perror("buffer query  error.\n");
        return -1;
    }

    /* mmap output buffer */ 
    outaddress =
        mmap(NULL, buffer.size,
                PROT_READ | PROT_WRITE, MAP_SHARED,
                vdcefd, buffer.offset);
    if (outaddress == MAP_FAILED) {
        perror("\nerror in mmaping output buffer");
        return -1;
    }

    /* read input from yuv file */
    read_frame_from_file(inaddress, inputfile, in_height*in_pitch*2);


    /* configure vdce params */
    ret = configure_vdce_engine(vdcefd, in_width, in_height, out_width, out_height);
    if(ret < 0) {
        perror("Cannot initialize Vdce Driver\n");
        return -1;
    }

    /* Resize operation */
    ret = resize(vdcefd);
    if(ret < 0) 
        perror("Resize operation failed\n");


    /* Write output to YUV file */ 
    write_frame_to_file(outaddress, OUTPUTFILE, out_height*out_pitch*2);


    PERFLOG("Resize complete. \n\n");

    if(-1 == munmap(inaddress,in_height*in_pitch*2))
        perror("Unmap for input address failed\n");
    if(-1 == munmap(outaddress,out_height*out_pitch*2))
        perror("Unmap for output address failed\n");

    if (0 < vdcefd) {
        if(-1 == close(vdcefd))
            perror("Close of vdce handle failed\n");
    }

    return ret;
}


/*
 *=====================config_vdce_engine===========================*/
int configure_vdce_engine(int vdcefd , int in_width, int in_height, int out_width, int out_height)
{
    vdce_params_t vdce_params;

    /* Setting VDCE mode to resizing */
    vdce_params.vdce_mode = VDCE_OPERATION_RESIZING;

    /* ioctl call to get default params */
    if (ioctl(vdcefd, VDCE_GET_DEFAULT, &vdce_params) < 0) {
        PERFLOG("Get default params failed error.\n");
        return -1;
    }

    /* set input width and height */ 
    vdce_params.common_params.src_hsz_luminance = in_width; 
    vdce_params.common_params.src_vsz_luminance = in_height;

    /* set output width and height  */
    vdce_params.common_params.dst_hsz_luminance = out_width; 
    vdce_params.common_params.dst_vsz_luminance= out_height; 

    /* Setting the vdce processing mode */
    vdce_params.common_params.src_processing_mode = VDCE_INTERLACED;
    vdce_params.common_params.src_mode = VDCE_FRAME_MODE;
    vdce_params.common_params.res_mode = VDCE_FRAME_MODE;

    vdce_params.common_params.prcs_unit_value =256;
    /* call ioctl to set parameters */
    if (ioctl(vdcefd, VDCE_SET_PARAMS, &vdce_params) < 0) {
        PERFLOG("set params failed \n");
        return -1;
    }
    return 0;
}
/*
 *=====================resize===========================*/
/*This function triggers the resize operation */
int resize(int vdcefd)
{
    vdce_address_start_t runtime_params;
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
    runtime_params.buffers[VDCE_BUF_IN].index =0;/* Index number */
    runtime_params.buffers[VDCE_BUF_OUT].index =0;/* Index number */
    int i = 0;
    /* Set the input and output pitch */ 
    runtime_params.src_horz_pitch = in_pitch;
    runtime_params.res_horz_pitch = out_pitch;

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

    /* Start the Timer */
    startTimer(&startTime);
    for (i=0;i < LOOPCOUNT;i++)
    {
        /* Trigger Resize */
        if (ioctl(vdcefd, VDCE_START, &runtime_params) < 0) {
            perror("ge start failed \n");
            return -1;
        }
    }
    /* Stop the Timer and get the usecs elapsed */
    elapsedUsecs = stopTimer (&startTime);

    /* Get CPU Load figures */ 
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

    PERFLOG("\nTotal Time Taken for %d Resize of %dx%d image to %dx%d image is %ld microseconds\n", LOOPCOUNT,in_width, in_height, out_width, out_height, elapsedUsecs);
    PERFLOG("\nTime for Resize of %dx%d image to %dx%d image is %ld microseconds\n", in_width, in_height, out_width, out_height,(elapsedUsecs/LOOPCOUNT));

    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("vdceResize: percentage cpu load for Resize of %dx%d image to %dx%d image is %.2f%%\n", in_width, in_height, out_width, out_height, percentageCpuLoad);

    return 0;
}

/* vim: set ts=4 sw=4 tw=80 et:*/
