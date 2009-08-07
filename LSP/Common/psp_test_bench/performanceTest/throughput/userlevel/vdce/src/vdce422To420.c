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
 **|         Copyright (c) 1998-2008 Texas Instruments Incorporated           |**
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
 *  \file   vdce422_420.c
 *
 *
 *  \brief  This file measures the time taken for the chroma conversion from YUV
 *  422 to YUV 420 format
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     Prathap MS     Created
 *              0.2     Prathap MS     Updated as per driver code changes 
 *              0.3     Saumya Agarwal  Updated for user input
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

static char inputfile[25];

/* File in the current directory which is used as output */
#define OUTPUTFILE	"CCV422to420_output.yuv"
#define LOOPCOUNT 2000


/******************************************************************************
  Function Declarations
 ******************************************************************************/
/* Functions to read/write frame from/to YUV file */
extern void read_frame_from_file(unsigned char *,char *,int);
extern void write_frame_to_file(unsigned char *, char *,int);

/* Function to initialize and set the  required parameters*/
int  initialize_vdce_engine(int);

/* Function that performs the YUV 422 to 420 conversion */
int  ccv422_420(int);

void usage_CCV422to420(void)
{  
    PERFLOG("./perfTest FRResize {Device name} {input width} {input height} {input Filename} \n");
}

/******************************************************************************
  Program Main function that calls all other required functions
 *******************************************************************************/
int vdce_ccv422_420(int argc, const char **argv)
{
    int ret            =0;
    int vdcefd        = 0;
    vdce_reqbufs_t	reqbuf;
    vdce_buffer_t buffer;
    void *inaddress,*outaddress;

    if(argc == 0 || argc < 4)
    {   usage_CCV422to420();
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

    /* Open VDCE device handle*/
    vdcefd = open(devicename,O_RDWR);
    if( vdcefd < 0){
        perror("Unable to open VDCE Driver.\n");
        return -1; 
    }

    /* Request input buffers */
    reqbuf.buf_type = VDCE_BUF_IN;
    reqbuf.num_lines = in_height;
    reqbuf.bytes_per_line = in_pitch;
    reqbuf.image_type = VDCE_IMAGE_FMT_422;
    reqbuf.count = 1;
    if (ioctl(vdcefd, VDCE_REQBUF, &reqbuf) < 0) {
        perror("buffer allocation error.\n");
        return -1;
    }

    /* Request output buffers */
    reqbuf.buf_type = VDCE_BUF_OUT;
    reqbuf.num_lines = out_height;
    reqbuf.bytes_per_line = out_pitch;
    reqbuf.image_type = VDCE_IMAGE_FMT_420;
    reqbuf.count =1;
    if (ioctl(vdcefd, VDCE_REQBUF, &reqbuf) < 0) {
        perror("buffer allocation error.\n");
        return -1;
    }

    /* Query input buffer */ 
    buffer.buf_type = VDCE_BUF_IN;
    buffer.index = 0;
    if (ioctl(vdcefd, VDCE_QUERYBUF, &buffer) < 0) {
        perror("buffer query  error.\n");
        return -1;
    }

    /* mapping input buffer */
    inaddress =
        mmap(NULL, buffer.size,
                PROT_READ | PROT_WRITE, MAP_SHARED,
                vdcefd, buffer.offset);
    if (inaddress == MAP_FAILED) {
        perror("\nerror in mmaping output buffer");
        return -1;
    }

    /* quering physical address for output buffer */
    buffer.buf_type = VDCE_BUF_OUT;
    buffer.index = 0;
    if (ioctl(vdcefd, VDCE_QUERYBUF, &buffer) < 0) {
        perror("buffer query  error.\n");
        return -1;
    }

    /* mapping output buffer */
    outaddress =
        mmap(NULL, buffer.size,
                PROT_READ | PROT_WRITE, MAP_SHARED,
                vdcefd, buffer.offset);
    if (outaddress == MAP_FAILED) {
        PERFLOG("\nerror in mmaping output buffer");
        return -1;
    }

    /* Read a frame from input YUV file */
    read_frame_from_file(inaddress, inputfile, ((in_height*in_pitch*2)));

    /* Initialize the VDCE parameters */
    ret = initialize_vdce_engine(vdcefd);
    if(ret < 0) {
        perror("Cannot initialize Vdce Driver\n");
        return -1;
    }


    ret = ccv422_420(vdcefd);

    if(ret<0) {
        perror("ccv operation failed\n");
        return -1;
    }

    /* Dump the YUV 420 format data to file */
    write_frame_to_file(outaddress,OUTPUTFILE,(out_height*out_pitch*3)/2);

    PERFLOG("CCV 422 --- 420  complete. \n\n");

    /* Unmap the input and output buffers */
    if(-1 == munmap(inaddress, in_height*in_pitch*2))
        perror("Unmap for input address failed\n");
    if(-1 == munmap(outaddress, (out_height*out_pitch*3)/2))
        perror("Unmap for output address failed\n");

    if (0 < vdcefd) {
        if(-1 == close(vdcefd))
            perror("Close of vdce handle failed\n");
    }

    return ret;
}


/*
 *=====================init_vdce_engine===========================*/
/* set the necessary parameters */
int initialize_vdce_engine(int vdcefd)
{
    vdce_params_t vdce_params;

    /* Setting mode to indicate chroma conversion
     */

    vdce_params.vdce_mode = VDCE_OPERATION_CHROMINANCE_CONVERSION;

    /* Get the default set of parameters
     */

    if (ioctl(vdcefd, VDCE_GET_DEFAULT, &vdce_params) < 0) {
        PERFLOG("default params failed error.\n");
        return -1;
    }

    /* Set the chrominance conversion type */ 
    vdce_params.vdce_mode_params.ccv_params.conversion_type = VDCE_CCV_MODE_422_420;

    /* Setting Input and output height & width
     */
    vdce_params.common_params.src_hsz_luminance = in_width;
    vdce_params.common_params.src_vsz_luminance = in_height;

    /* set output size  */
    vdce_params.common_params.dst_hsz_luminance = out_width;
    vdce_params.common_params.dst_vsz_luminance= out_height;

    /* Set VDCE processing mode */ 
    vdce_params.common_params.src_processing_mode = VDCE_PROGRESSIVE;
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
 *=====================ccv422_42===========================*/
/*This function triggers the ccv operation */
int ccv422_420(int vdcefd)
{
    vdce_address_start_t runtime_params;
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
    int i=0;
    runtime_params.buffers[VDCE_BUF_IN].index =0;/* Index number */
    runtime_params.buffers[VDCE_BUF_OUT].index =0;/* Index number */

    /* Setting input and output pitch values */
    runtime_params.src_horz_pitch = in_pitch;
    runtime_params.res_horz_pitch = out_pitch;

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

    /* Start the Timer */
    startTimer(&startTime); 
    for (i=0;i < LOOPCOUNT;i++)
    {

        /* IOCTL call that will perform the chroma conversion */
        if (ioctl(vdcefd, VDCE_START, &runtime_params) < 0) {
            perror("ge start failed \n");
            return -1;
        }
    }
    /* Stop the Timer and get the usecs elapsed */
    elapsedUsecs = stopTimer (&startTime);

    /* Get CPU Load figures */ 
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

    printf("\nTotal Time taken for %d %dx%d image CCV from 422 to 420 is %ld microseconds\n",LOOPCOUNT,in_width, in_height, (elapsedUsecs));
    PERFLOG("CCV from %dx%d image 422 to 420 takes %ld microseconds\n",in_width,in_height, (elapsedUsecs/LOOPCOUNT));

    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("vdce422_420: percentage cpu load for %dx%d image CCV from 422 to 420 is %.2f%%\n",in_width, in_height, percentageCpuLoad);

    return 0;
}

/* vim: set ts=4 sw=4 tw=80 et:*/

