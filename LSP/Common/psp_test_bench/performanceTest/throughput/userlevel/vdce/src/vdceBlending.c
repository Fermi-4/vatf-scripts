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
 *  \file   vdceBlendimg.c
 *
 *  \brief  This file measures the time taken for blending the YUV image
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \history    0.1     Prathap MS     Created
 *              0.2     Prathap MS     Updated as per driver code changes 
 *              0.3     Saumya         Updated for taking parameters as command
 *                                     line arguments 
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

/* Variables for input/ouput height/width/pitch and bitmap height/width/pitch */
static int in_width, in_height, in_pitch, out_width, out_height, out_pitch, bmp_width,
           bmp_height, bmp_pitch, bmp_hsp, bmp_vsp;

static char inputfile[25];
void prepare_bitmap_data(unsigned char *);

#define LOOPCOUNT 2000
/* Output YUV file-This has blended output */
#define OUTPUTFILE "blending_output.yuv"

/* Function for Blending */
int  blending(int, int);
int start_vdce_engine(int);
extern void read_frame_from_file(unsigned char*,char*,int);
extern void write_frame_to_file(unsigned char*,char*, int);
/* Function to show usage of blending */
void usage_blending(void)
{  
    PERFLOG("./perfTest FRBlending {Device name} {input width} {input height} {input Filename} {bmp width} {bmp height} {bmp pitch} {bmp hsp} {bmp vsp}\n");
}

/******************************************************************************
  Program Main
 *******************************************************************************/
int vdce_blending(int argc, const char **argv)
{
    int ret          =   0;
    int vdcefd       =   0;
    vdce_reqbufs_t	reqbuf;
    vdce_buffer_t buffer;
    void *inaddress,*outaddress,*bmpaddress;

    if(argc == 0 || argc < 9)
    {   usage_blending();
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

    /* get bmp width */
    getNextTokenInt(&argc, argv, &bmp_width);

    /* get bmp height */
    getNextTokenInt(&argc, argv, &bmp_height);

    /* get bmp pitch */
    getNextTokenInt(&argc, argv, &bmp_pitch);

    /* get bmp hsp */
    getNextTokenInt(&argc, argv, &bmp_hsp);

    /* get bmp vsp */
    getNextTokenInt(&argc, argv, &bmp_vsp);



    in_pitch = in_width;
    out_width = in_width;
    out_height = in_height;
    out_pitch = in_pitch;    

    /* Open VDCE device */
    vdcefd = open(devicename,O_RDWR);
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
        perror("buffer allocation error.\n");
        return -1; 
    }

    /* request output buffer */
    reqbuf.buf_type = VDCE_BUF_OUT;
    reqbuf.num_lines = out_height;
    reqbuf.bytes_per_line = out_pitch;
    reqbuf.image_type = VDCE_IMAGE_FMT_422;
    reqbuf.count =1;
    if (ioctl(vdcefd, VDCE_REQBUF, &reqbuf) < 0) {
        perror("buffer allocation error.\n");
        return -1; 
    }

    /* request for 1 bitmap buffer of size 160*64*2*/
    reqbuf.buf_type = VDCE_BUF_BMP;
    reqbuf.num_lines = bmp_height;
    reqbuf.bytes_per_line = bmp_pitch;
    reqbuf.image_type = VDCE_IMAGE_FMT_422;
    reqbuf.count =1;
    if (ioctl(vdcefd, VDCE_REQBUF, &reqbuf) < 0) {
        perror("buffer allocation error.\n");
        return -1; 
    }


    buffer.buf_type = VDCE_BUF_IN;
    buffer.index = 0;
    if (ioctl(vdcefd, VDCE_QUERYBUF, &buffer) < 0) {
        perror("buffer query  error.\n");
        return -1; 
    }
    inaddress =
        mmap(NULL, buffer.size,
                PROT_READ | PROT_WRITE, MAP_SHARED,
                vdcefd, buffer.offset);
    /* mapping input buffer */
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
    outaddress =
        mmap(NULL, buffer.size,
                PROT_READ | PROT_WRITE, MAP_SHARED,
                vdcefd, buffer.offset);
    /* mapping output buffer */
    if (outaddress == MAP_FAILED) {
        perror("\nerror in mmaping output buffer");
        return -1; 
    }

    /* quering physical address for bitmap buffer */
    buffer.buf_type = VDCE_BUF_BMP;
    buffer.index = 0;
    if (ioctl(vdcefd, VDCE_QUERYBUF, &buffer) < 0) {
        perror("buffer query  error.\n");
        return -1; 
    }
    bmpaddress =
        mmap(NULL, buffer.size,
                PROT_READ | PROT_WRITE, MAP_SHARED,
                vdcefd, buffer.offset);
    /* mapping bitmap buffer */
    if (bmpaddress == MAP_FAILED) {
        perror("\nerror in mmaping bitmap buffer");
        return -1;
    }


    /* Read a frame from input YUV file */
    read_frame_from_file(inaddress,inputfile,((in_height*in_pitch*2)));

    /* Prepare Bitmap data */
    prepare_bitmap_data(bmpaddress);

    /* Set the VDCE parameters */ 
    ret = start_vdce_engine(vdcefd);
    if(-1 == ret) {
        perror("Cannot initialize Vdce Driver\n");
        return -1;
    }

    /* Function call to perform blending */
    ret = blending(vdcefd,(unsigned int)inaddress);

    if(ret < 0) {
        perror("blending operation failed\n");
        return -1;
    }


    /* Write the output YUV frame to output YUV file */ 
    write_frame_to_file(outaddress, OUTPUTFILE, out_height* out_pitch* 2);

    PERFLOG("Blending complete. \n\n");

    /*Close the file handle and unmap the buffers
     */
    if(-1 == munmap(inaddress, in_height*in_pitch*2))
        perror("Unmap for input address failed\n");
    if(-1 == munmap(outaddress, out_height* out_pitch*2))
        perror("Unmap for output address failed\n");
    if(-1 == munmap(bmpaddress, bmp_height*bmp_pitch*2))
        perror("Unmap for bitmap address failed\n");

    if (0 < vdcefd) {
        if(-1 == close(vdcefd))
            perror("Close of vdce handle failed\n");
    }
    return ret;
}


/*
 *=====================init_vdce_engine===========================*/
/* set the necessary parameters */
int start_vdce_engine(int vdcefd)
{
    vdce_params_t vdce_params;
    int i=0;
    /* Bitmap array used for blending. Changing the values of Y CB and CR
       will result into different colors of blend windows. With evey Y,Cb CR
       values there is an blend factor associate. Blend factor 0xff means
       opaque and 0x0 means transperent */

    unsigned char crcbyfactor[4][4] = {
        {0xf0, 0x5a, 0x51,0xff},/* blue color component values of cr cb & y */
        {0x22, 0x36, 0x91,0xc0},/* red color component values of cr cb & y*/
        {0x6e, 0xf0, 0x29,0x80},/* green color component values of cr cb & y*/
        {0xde, 0xca, 0x6a,0x40},/* magenta color component values of cr cb & y*/

    };
    /* Setting VDCE mode of operation to Blending
     */
    vdce_params.vdce_mode = VDCE_OPERATION_BLENDING;

    /* Get the default set of parameters to save ourselves from
       enetring a whole host of parameters and using wrong parameters
     */
    if (ioctl(vdcefd, VDCE_GET_DEFAULT, &vdce_params) < 0) {
        PERFLOG("default params failed error.\n");
        return -1;
    }
    /* change input and output size from the defaults
       applicable for the current need
     */
    vdce_params.common_params.src_hsz_luminance = bmp_width;
    vdce_params.common_params.src_vsz_luminance = bmp_height;

    /* set output size  */
    vdce_params.common_params.dst_hsz_luminance = bmp_width;
    vdce_params.common_params.dst_vsz_luminance= bmp_height;

    /* set the bitmap size */
    vdce_params.common_params.bmp_hsize = bmp_width;
    vdce_params.common_params.bmp_vsize = bmp_height;

    vdce_params.common_params.src_processing_mode = VDCE_PROGRESSIVE;
    vdce_params.common_params.src_mode = VDCE_FRAME_MODE;
    vdce_params.common_params.res_mode = VDCE_FRAME_MODE;
    vdce_params.common_params.src_bmp_mode = VDCE_FRAME_MODE;

    /* Postions the bitmap windows on the overall image window .This
       values governs the stating of bitmap on image */
    vdce_params.common_params.res_vsp_bitmap = 0;
    vdce_params.common_params.res_hsp_bitmap = 0;

    /* Fill the blend values associated with every blend table */
    for(i=0;i<MAX_BLEND_TABLE;i++){
        vdce_params.vdce_mode_params.blend_params.
            bld_lut[i].blend_cr =  crcbyfactor[i][0];
        vdce_params.vdce_mode_params.blend_params.
            bld_lut[i].blend_cb = crcbyfactor[i][1];
        vdce_params.vdce_mode_params.blend_params.
            bld_lut[i].blend_y = crcbyfactor[i][2];
        vdce_params.vdce_mode_params.blend_params.
            bld_lut[i].blend_value= crcbyfactor[i][3];
    }

    vdce_params.common_params.prcs_unit_value =256;
    /* call ioctl to set parameters */
    if (ioctl(vdcefd, VDCE_SET_PARAMS, &vdce_params) < 0) {
        PERFLOG("set params failed \n");
        return -1;
    }
    return 0;
}



/*
 *====================blending===========================*/
/*This function triggers blending operation */
int blending(int vdcefd,int address)
{
    vdce_address_start_t runtime_params;
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
    int i =0;
    /* Here 0 is the index of the  Driver allocated buffer.
       If one wishes to use user pointers, the index should be set to -1
     */
    runtime_params.buffers[VDCE_BUF_OUT].index =-1;/* Index number */
    runtime_params.buffers[VDCE_BUF_OUT].virt_ptr =(int)address + (bmp_vsp
            *out_pitch) + bmp_hsp;
    runtime_params.buffers[VDCE_BUF_OUT].size = out_pitch*out_height*2;

    runtime_params.buffers[VDCE_BUF_IN].index =-1;/* Index number */
    runtime_params.buffers[VDCE_BUF_IN].virt_ptr =(int)address +
        (bmp_vsp*in_pitch) + bmp_hsp;
    runtime_params.buffers[VDCE_BUF_IN].size = in_pitch*in_height*2;
    runtime_params.buffers[VDCE_BUF_BMP].index =0;/* Index number */
    runtime_params.src_horz_pitch = in_pitch;
    runtime_params.res_horz_pitch = out_pitch;
    runtime_params.bmp_pitch = bmp_pitch;

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

    /* Start the Timer */
    startTimer(&startTime);
    for (i=0;i < LOOPCOUNT;i++)
    {
        /* ioctl call to do blending */ 
        if (ioctl(vdcefd, VDCE_START, &runtime_params) < 0) {
            perror("ge start failed \n");
            return -1;
        }
    }    
    /* Stop the Timer and get the usecs elapsed */
    elapsedUsecs = stopTimer (&startTime);

    /* Get CPU Load figures */ 
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

    PERFLOG("Total Time Taken  for %d  %dx%d bitmap and %dx%d image Blending is %ld microseconds\n",LOOPCOUNT,bmp_width, bmp_height, in_width, in_height,elapsedUsecs);   

    PERFLOG("Time for %dx%d bitmap and %dx%d image Blending is %ld microseconds\n",bmp_width, bmp_height, in_width,in_height,(elapsedUsecs/LOOPCOUNT));

    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("vdceblending: percentage cpu load for %dx%d bitmap and %dx%d image Blending is %.2f%%\n",bmp_width, bmp_height, in_width, in_height, percentageCpuLoad);

    return 0;
}

/*
 *=====================prepare_bitmap_data===========================
 It will prepare the bitmap buffer
 */
void prepare_bitmap_data(unsigned char *bmpaddress)
{
    memset((void *)bmpaddress,0,(bmp_pitch)*(bmp_height/4));
    memset((void *)(bmpaddress+((bmp_pitch) *(bmp_height/4))),
            0X55,((bmp_height/4)*(bmp_pitch)));
    memset((void *)(bmpaddress+((bmp_pitch) *(bmp_height/2))),
            0Xaa,((bmp_height/4)*(bmp_pitch)));
    memset((void *)(bmpaddress+(((bmp_pitch) *bmp_height*3)/4)),
            0Xff,((bmp_height/4)*(bmp_pitch)));
}

/* vim: set ts=4 sw=4 tw=80 et:*/

