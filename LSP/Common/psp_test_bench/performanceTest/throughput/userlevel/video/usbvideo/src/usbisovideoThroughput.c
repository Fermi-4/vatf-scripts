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
 **|         Copyright (c) 2007-2008 Texas Instruments Incorporated          |**
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
 *  \file   usbisovideoThroughput.c
 *
 *  \brief  USB ISO Video Capture Performance Test
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \author     Prachi Sharma
 *
 *  \note       
 *              
 *
 *  \version    0.1     Prachi         Created
 */

/******************************************************************************
  Header File Inclusion
 ******************************************************************************/
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <errno.h>
#include <linux/videodev.h>
#include <linux/videodev2.h>
#ifndef LSP_1_1_PRODUCT
#include <media/davinci/adv7343.h>
#include <asm/arch/davinci_vdce.h>
#endif
#include <linux/fb.h>
#include <sys/types.h>
#include <linux/fb.h>
#include <stdlib.h>
#include <sys/time.h>
#include <asm/types.h>		/* for videodev2.h */
#include <time.h>

#ifdef LSP_1_1_PRODUCT
#include <media/davinci_vpfe.h>
#include <video/davincifb.h>
#include <video/davinci_vpbe.h>
#else
#include <media/davinci/davinci_vpfe.h>
#include <video/davincifb_ioctl.h>
#include <media/davinci/davinci_display.h>
#endif



/******************************************************************************
  Performance Test Header Files
 ******************************************************************************/
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

/*Maximum frame count that can be given*/
#define MAXLOOPCOUNT	10000

/*Sysfs paths*/
#define OUTPUTPATH  "/sys/class/davinci_display/ch0/output"
#define STDPATH     "/sys/class/davinci_display/ch0/mode"

#define CLEAR(x)        memset (&(x), 0, sizeof (x))

/* GLOBALS*/
struct buffer {
        void *                  start;
        size_t                  length;
};

struct buffer *         buffers         = NULL;
static unsigned int     n_buffers       = 0;
char usb_devicename[15];
char outname[80];
int c_size, c_offset;
struct v4l2_format fmt;
int usbisovideo_perf(int, const char**);
static int usb_init(int *capture_fd);
static int usb_start(int *);
static int usb_stop(int *);
void   usage_usb(void);

/*=====================usb_init========================*/
static int usb_init(int *capture_fd)
{
    int mode=O_RDWR, ret, i;
    struct v4l2_requestbuffers reqbuf;
    struct v4l2_buffer buf;
    struct v4l2_capability cap;

    /* Open the capture device */
    *capture_fd = open((const char *)usb_devicename, mode);
    if (capture_fd <= 0) {
        PERFLOG("Cannot open = %s device\n", usb_devicename);
        return -1;
    }

    /*Query Capabilities*/
    if (-1 == ioctl (*capture_fd, VIDIOC_QUERYCAP, &cap)) 
    {
        perror("VIDIOC_QUERYCAP\n");
        return -1;
    }

    if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) 
    {   PERFLOG("%s is no video capture device\n", usb_devicename);
        return -1;
    }   
    
    if (!(cap.capabilities & V4L2_CAP_STREAMING))
    {   PERFLOG("%s does not support streaming i/o\n", usb_devicename);
        return -1;
    }

    /* Set Format*/
    CLEAR (fmt);
    fmt.type                = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    fmt.fmt.pix.width       = 320;
    fmt.fmt.pix.height      = 240;
    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
    fmt.fmt.pix.field       = V4L2_FIELD_INTERLACED;

    if (-1 == ioctl (*capture_fd, VIDIOC_S_FMT, &fmt))
        perror("VIDIOC_S_FMT\n");

    c_offset = fmt.fmt.pix.sizeimage/2;
    c_size = fmt.fmt.pix.width * fmt.fmt.pix.height;
 
   /* Allocate buffers*/
    reqbuf.memory = V4L2_MEMORY_MMAP;
    reqbuf.count = 4;
    reqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    ret = ioctl(*capture_fd, VIDIOC_REQBUFS, &reqbuf);
    if (ret < 0) 
    {   perror("cannot allocate memory\n");
        return -1;
    }
    
    if (reqbuf.count < 2) 
    {   perror("Insufficient buffer memory\n");
        return -1;
    }

    buffers = calloc (reqbuf.count, sizeof (*buffers));
    if (!buffers) 
    {   perror("Out of memory\n");
        return -1;
    }

    /*Query for the physical address of each buffer and then mmap them*/
    for (n_buffers = 0; n_buffers < reqbuf.count; ++n_buffers) 
    {   CLEAR (buf);
        buf.type        = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf.memory      = V4L2_MEMORY_MMAP;
        buf.index       = n_buffers;
        
        if (-1 == ioctl (*capture_fd, VIDIOC_QUERYBUF, &buf))
            perror("VIDIOC_QUERYBUF\n");

        buffers[n_buffers].length = buf.length;
        buffers[n_buffers].start = mmap (NULL /* start anywhere */, buf.length,
PROT_READ | PROT_WRITE /* required */, MAP_SHARED /* recommended */, *capture_fd, buf.m.offset);
        if (MAP_FAILED == buffers[n_buffers].start)
            perror("mmap\n");
    }

    /*Enqueue the buffers*/
    for (i = 0; i < reqbuf.count; i++) 
    {   CLEAR(buf);
        buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf.index = i;
        buf.memory = V4L2_MEMORY_MMAP;
        ret = ioctl(*capture_fd, VIDIOC_QBUF, &buf);
        if (ret < 0) 
        {   perror("VIDIOC_QBUF\n");
            return -1;
        }
    }

    return 0;
}

/*=====================usb_start========================*/
/* This function starts streaming on the capture device	   */
static int usb_start(int *capture_fd)
{   int a = V4L2_BUF_TYPE_VIDEO_CAPTURE, ret;
    /* Here type of device to be streamed on is required to be passed */
    ret = ioctl(*capture_fd, VIDIOC_STREAMON, &a);
    if (ret < 0) {
        perror("VIDIOC_STREAMON\n");
        return -1;
    }
    return 0;
}

/*=====================usb_stop========================*/
/* This function stops streaming on the capture device	  */
static int usb_stop(int *capture_fd)
{
    int ret, a = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    /* Here type of device to be streamed off is required to be passed */
    ret = ioctl(*capture_fd, VIDIOC_STREAMOFF, &a);
    if (ret < 0) {
        perror("VIDIOC_STREAMOFF\n");
        return -1;
    }
    return 0;
}

/*=====================usbisovideo_perf===========================*/
int usbisovideo_perf(int numargs,const char **argv)
{
    long ctime[MAXLOOPCOUNT];
    double diffc[MAXLOOPCOUNT];
    int i = 0,j=0;
    int counter = 0;
    int ret = 0;
    struct v4l2_buffer buf1;
    int capture_fd;
    int frmc=0;
    float avgc, sumc=0;
    int frames,frame;
    FILE *fp;
    ST_TIMER_ID currentTime;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;

    if(numargs == 0 || numargs < 4)
    {   usage_usb();
        return -1;
    }

    /* get the device name*/
    getNextTokenString(&numargs, argv, usb_devicename);
    
    /* get the no. of frames */
    getNextTokenInt(&numargs, argv, &frames);
    if(frames > MAXLOOPCOUNT)
    {   PERFLOG("Invalid number of frames.\nPlease give number of frames to be less than 10000.\n");
        usage_usb();
        return -1;
    }
       
    /* get the frame to be captured*/
    getNextTokenInt(&numargs, argv, &frame);
    if(frame > frames || frame <= 0)
    {   PERFLOG("Invalid frame.\nPlease give correct frame number.\n");
        usage_usb();
        return -1;
    }

    /* get the file name*/
    getNextTokenString(&numargs, argv, outname);
   
    /* open capture channel */
    ret = usb_init(&capture_fd);
    if(ret < 0) {
        PERFLOG("Error in opening capture device for channel 0\n");
        return ret;
    }

    /* start capturing */
    ret = usb_start(&capture_fd);
    if(ret < 0) {
        PERFLOG("Error in starting capturing for channel \n");
        return ret;
    }
    PERFLOG("Capturing frames:\n");     

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

    while(counter < frames) 
    {   
        CLEAR (buf1);
        buf1.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf1.memory = V4L2_MEMORY_MMAP;

        if (-1 == ioctl(capture_fd, VIDIOC_DQBUF, &buf1)) {
                perror("capture VIDIOC_DQBUF\n");
                return -1;
            }

        getTime(&currentTime);
        ctime[j++]=currentTime.tv_usec;

        if(counter == (frame-1))
        {       fp=fopen(outname, "wb");
                if(fp==NULL)
                {   printf("Cannot open file\n");
                    return -1;
                }
                fwrite(buffers[buf1.index].start, c_size, 1, fp);
                fwrite(buffers[buf1.index].start + c_offset, c_size, 1, fp);
                fclose(fp);
        }
        ret = ioctl(capture_fd, VIDIOC_QBUF, &buf1);
        if(ret < 0) {
            perror("capture VIDIOC_QBUF\n");
            return -1;
        }
        counter ++;
    }
    
    /* Get CPU Load figures */ 
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

    /* stop capturing */
    ret = usb_stop(&capture_fd);
    if(ret < 0) {
        PERFLOG("Error in stopping capturing for channel 0\n");
        return ret;
    }

   /*Unmap and free the buffers*/
     for (i = 0; i < n_buffers; ++i)
    {   if (-1 == munmap (buffers[i].start, buffers[i].length))
        {   perror("munmap");    
        }
    }

    free(buffers);

    if (-1 == close(capture_fd))
        perror("close");

   /*Close the channel*/
     capture_fd = -1;

   /*Calculate the frame rate*/
     for(j=0;j<(frames-1);j++)
    {   if(ctime[j+1] > ctime[j])
        {    diffc[j]=ctime[j+1]-ctime[j];
             diffc[j]= (1/(diffc[j]/1000000));
        } 
        else
            diffc[j] = 0;
    }
    
    for(j=0; j<(frames-1); j++)
    {   if(diffc[j]>0)
        {   sumc=sumc+diffc[j];
            frmc++;
        }
    } 
    avgc=sumc/(frmc-1);

    PERFLOG("Capture frame rate: %lf \n",avgc);
 
    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("usbisovideo: capture: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    return ret;
}

void usage_usb(void)
{   PERFLOG("./perfTest FRusbisovideocapture {Capture device} {number of frames} {frame to be captured} {output yuv file}\n");
}

/* vim: set ts=4 sw=4 tw=80 et:*/
