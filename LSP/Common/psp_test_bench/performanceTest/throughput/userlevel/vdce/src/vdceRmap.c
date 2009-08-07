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
 *  \file   vdceRmap.c
 *
 *  \brief  This file measures the time taken for the range mapping operation
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     Prathap MS     Created
 *              0.2     Prathap MS     Updated as per driver code changes 
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


static void *inaddress,*outaddress;

#define LOOPCOUNT 2000
#define OUTPUTFILE    "Rmap_output.yuv"


/* Initialize Range mapping parameters */
#define COMMON_DEFAULT_PARAMS {VDCE_PROGRESSIVE,VDCE_FRAME_MODE, VDCE_FRAME_MODE,VDCE_FRAME_MODE,\
    VDCE_LUMA_CHROMA_ENABLE,VDCE_TOP_BOT_ENABLE,720,480,120,60,0,10,0,0,10,720,480,0,0}
#define RMAP_PARAMS {10,VDCE_FEATURE_ENABLE,10,VDCE_FEATURE_ENABLE}

void usage_Rmap(void)
{  
    PERFLOG("./perfTest FRResize {Device name} {input width} {input height} {input Filename} \n");
}

/******************************************************************************
  Function Declarations
 ******************************************************************************/
/* Functions to read/write YUV frame from/to YUV file */
extern void read_frame_from_file(unsigned char *,char *,int);
extern void write_frame_to_file(unsigned char *, char *,int);
int rmap(int vdcefd);
/* Function to configure range mapping params */
int  configure_vdce_rmap(int);

/* Function to perform  Range mapping */
int  rmap_HD(int);


/* Initialize range mapping params */
vdce_params_t vdce_params = {
    VDCE_OPERATION_RANGE_MAPPING,
    0x0,
    COMMON_DEFAULT_PARAMS,
    .vdce_mode_params.epad_params = RMAP_PARAMS
};

/******************************************************************************
  Main function that calls other required functions	
 *******************************************************************************/
int vdce_rmap(int argc, const char **argv)
{
    int ret         =  0;
    char inputfile[25];
    int vdcefd      =  0;
    vdce_reqbufs_t	reqbuf;
    vdce_buffer_t buffer;

    if(argc == 0 || argc < 4)
    {   usage_Rmap();
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


    in_pitch = in_width;
    out_width = in_width;
    out_height = in_height;
    out_pitch = in_pitch;

    vdcefd = open(devicename,O_RDWR);
    if( vdcefd < 0){
        perror("Unable to open VDCE Driver.\n");
        return -1;
    }

    /* Request Input buffer */
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

    /* map input buffers to user space */
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
        PERFLOG("\nerror in mmaping output buffer");
        return -1;
    }

    /* Read a frame from input YUV file */
    read_frame_from_file(inaddress,inputfile,((in_height*in_pitch*2)));

    /* Configure range mapping parameters */
    ret = configure_vdce_rmap(vdcefd);
    if(ret < 0) {
        perror("Cannot initialize Vdce Driver\n");
        return -1;
    }

    /* Function to do edge padding */
    ret = rmap(vdcefd);
    if(ret < 0) {
        perror("Range map operation failed\n");
        return -1;
    }

    write_frame_to_file(outaddress, OUTPUTFILE, out_height* out_pitch* 2);

    PERFLOG("Range mapping Completed \n\n");

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
 *=====================config_vdce_rmap===========================*/
int configure_vdce_rmap(int vdcefd)
{

    if (ioctl(vdcefd, VDCE_GET_DEFAULT, &vdce_params) < 0) {
        PERFLOG("default params failed error.\n");
        return -1;
    }

    /* Setting input width and height based on the input YUV image */ 
    vdce_params.common_params.src_hsz_luminance = in_width;
    vdce_params.common_params.src_vsz_luminance = in_height;

    /* Setting output width and height based on the output YUV image */ 
    vdce_params.common_params.dst_hsz_luminance = out_width;
    vdce_params.common_params.dst_vsz_luminance= out_height;
    vdce_params.common_params.prcs_unit_value= 256;
    /* call ioctl to set parameters */
    if (ioctl(vdcefd, VDCE_SET_PARAMS, &vdce_params) < 0) {
        PERFLOG("set params failed \n");
        return -1;
    }
    return 0;
}

/*
 *=====================rmap===========================*/
/*This function triggers the range mapping operation */
int rmap(int vdcefd)
{
    vdce_address_start_t runtime_params;
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
    int i = 0;

    runtime_params.buffers[VDCE_BUF_IN].index =0;/* Index number */
    runtime_params.buffers[VDCE_BUF_OUT].index =0;/* Index number */

    /* Setting input and output pitch */
    runtime_params.src_horz_pitch = in_pitch;
    runtime_params.res_horz_pitch = out_pitch;

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

    /* Start the Timer */
    startTimer(&startTime);
    for (i=0;i < LOOPCOUNT;i++)
    {

        /* ioctl call to trigger range mapping */ 
        if (ioctl(vdcefd, VDCE_START, &runtime_params) < 0) {
            perror("VDCE start failed \n");
            return -1;
        }
    }    
    /* Stop the Timer and get the usecs elapsed */
    elapsedUsecs = stopTimer (&startTime);

    /* Get CPU Load figures */ 
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

    PERFLOG("Total Time taken for %d  %dx%d Range mapping is %ld microseconds\n",LOOPCOUNT,in_width,in_height,elapsedUsecs);
    PERFLOG("Time for %dx%d Range mapping is %ld microseconds\n",in_width,in_height, (elapsedUsecs/LOOPCOUNT));

    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("vdceRmap: percentage cpu load for %dx%d range mapping is %.2f%%\n",in_width,in_height, percentageCpuLoad);

    return 0;
}

/* vim: set ts=4 sw=4 tw=80 et:*/

