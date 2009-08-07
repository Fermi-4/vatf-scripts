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
 *  \file   v4l2capture_dm644x.c
 *
 *  \brief  V4L2 Capture Performance Test for DM6446
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \author     Prachi Sharma
 *
 *  \note       
 *              
 *
 *  \version    0.1     Prachi          Created.
 */

/******************************************************************************
  Header File Inclusion
 ******************************************************************************/
/* Linux specifc generic header files */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <errno.h>
#include <sys/types.h>
#include <stdlib.h>
#include <sys/time.h>
#include <asm/types.h>		
#include <time.h>

/* V4L2 specific header files */
#include <linux/videodev.h>
#include <linux/videodev2.h>

/* DM644x specfic Driver header files */
/* temp dirty fix for supporting lsp2.1 */
#ifdef LSP_1_1_PRODUCT
#include <media/davinci_vpfe.h>
#elif LSP_1_2_PRODUCT
#include <media/davinci/davinci_vpfe.h>
#include <media/davinci/davinci_display.h>
#elif LSP_1_3_PRODUCT
#include <media/davinci/davinci_vpfe.h>
#include <media/davinci/davinci_display.h>
#elif LSP_2_0_PRODUCT
#include <media/davinci/davinci_vpfe.h>
#include <media/davinci/davinci_display.h>
#else
#include <media/davinci/davinci_vpfe.h>
#include <media/davinci/davinci_display.h>
#include <media/davinci/tvp5146.h>
#endif

/*  Performance Test Header Files */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

/* Maximum buffers that can be requested */
#define MAX_BUFFER	8
/* Pitch of the image */
#define BUFFER_PITCH	1920
/* Height of the image */
#define BUFFER_HEIGHT	1080
/* Loop count - Number of frames captured/displayed */
#define MAXLOOPCOUNT	10000

/* Width and Height used for DM644x capture drivers */
#define WIDTH       720
#define HEIGHT_NTSC      480
#define HEIGHT_PAL      576

/* DM644x specific OSD device nodes */
#define OSD0_DEVICE	"/dev/fb/0"
#define OSD1_DEVICE	"/dev/fb/2"

#define CLEAR(x)        memset (&(x), 0, sizeof (x))

struct buf_info {
    int index;
    unsigned int length;
    char *start;
};
static struct v4l2_buffer bufcap;

/* Capture and display buffers mmaped */
static struct buf_info capture_buff_info[MAX_BUFFER];
/* Device node that will be passed by user */
static char devicename[15];
/* V4L2 cropcap structure */
static struct v4l2_cropcap cropcap;
/* Settings for capture/display of images */
static int nWidthFinal;
static int nHeightFinal;
extern int errno;

/* Function declarations */
int v4l2capture_perf(int, const char**);
static int initCapture(int *capture_fd, int *numbuffers, char *outputname, 
        char *stdname);
static int startCapture(int *);
static int stopCapture(int *);
static int releaseCapture(int *, int *);
void   v4l2captureusage(void);
/*=====================initCapture========================*/
/* This function initializes capture device. It detects   *
 * first input connected on the channel-0 and detects the *
 * standard on that input. It, then, enqueues all the     *
 * buffers in the driver's incoming queue.		  */
static int initCapture(int *capture_fd, int *numbuffers, char *outputname, 
        char *stdname)
{
    int mode, ret, i;
    struct v4l2_requestbuffers reqbuf;
    struct v4l2_buffer buf;
    struct v4l2_format fmt;
    v4l2_std_id std;
    unsigned int min;

        mode = O_RDWR;
    
    /* Open the channel-0 capture device */
    *capture_fd = open((const char *)devicename, mode);
    if (capture_fd <= 0) {
        PERFLOG("Cannot open = %s device\n", devicename);
        return -1;
    }

       /* select cropping as default rectangle */
	    cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

	    if(-1 == ioctl (*capture_fd, VIDIOC_CROPCAP, &cropcap)) {
		    perror("VIDIOC_CROPCAP\n");
		    /*ignore error */
	    }
        std = VPFE_STD_AUTO;
	    if(-1 == ioctl (*capture_fd, VIDIOC_S_STD, &std)) {
		    perror("unable to set standard automatically\n");
	    }

	    sleep (1);	/* wait until decoder is fully locked */
	
    /* Detect the standard in the input detected */
    ret = ioctl(*capture_fd, VIDIOC_QUERYSTD, &std);
    if (ret < 0) {
        perror("VIDIOC_QUERYSTD\n");
        return -1;
    }
    if (std == V4L2_STD_NTSC) {
        fmt.fmt.pix.height = HEIGHT_NTSC;
    } else {
        fmt.fmt.pix.height = HEIGHT_PAL;
    }

	    CLEAR (fmt);
	    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	    fmt.fmt.pix.width = WIDTH;
	    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	    fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;

	    if (-1 == ioctl (*capture_fd, VIDIOC_S_FMT, &fmt)) 
        {   perror ("VIDIOC_S_FMT\n");
	    }

	    if (-1 == ioctl (*capture_fd, VIDIOC_G_FMT, &fmt))
        {   perror ("VIDIOC_G_FMT:\n");
	    }

    	nWidthFinal = fmt.fmt.pix.width;
	    nHeightFinal = fmt.fmt.pix.height;

    	/*checking what is finally negotiated */
	    min = fmt.fmt.pix.width * 2;
	    if (fmt.fmt.pix.bytesperline < min) 
        {   PERFLOG("driver reports bytes_per_line:%d(bug)\n",fmt.fmt.pix.bytesperline);

		    /*correct it */
		    fmt.fmt.pix.bytesperline = min;
	    }

	    min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
	    if (fmt.fmt.pix.sizeimage < min) 
        {   PERFLOG ("driver reports size:%d(bug)\n", fmt.fmt.pix.sizeimage);

		    /*correct it */
		    fmt.fmt.pix.sizeimage = min;
	    }
    
    

       CLEAR (reqbuf);
	    reqbuf.count = *numbuffers;
	    reqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	    reqbuf.memory = V4L2_MEMORY_MMAP;
        if (-1 == ioctl (*capture_fd, VIDIOC_REQBUFS, &reqbuf)) 
        {   perror ("cannot allocate memory:VIDIOC_REQBUFS\n");
		    return -1;
	    }

	    *numbuffers = reqbuf.count;

        memset(&buf, 0, sizeof(buf));
	
	    for (i = 0; i < reqbuf.count; i++) 
        {   buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		    buf.memory = V4L2_MEMORY_MMAP;
		    buf.index = i;
            if (-1 == ioctl (*capture_fd, VIDIOC_QUERYBUF, &buf)) 
            {   perror("VIDIOC_QUERYBUF:\n\n");
			    return -1;
		    }

		    capture_buff_info[i].length = buf.length;
		    capture_buff_info[i].index = i;
		    capture_buff_info[i].start = mmap(NULL, buf.length, PROT_READ | PROT_WRITE, MAP_SHARED, *capture_fd, buf.m.offset);
        
            if (MAP_FAILED == capture_buff_info[i].start) 
            {   perror("Cannot mmap:\n");
			    return -1;
		    }
            memset(capture_buff_info[i].start, 0x80, capture_buff_info[i].length);
	    } 
        for (i = 0; i <reqbuf.count; i++) 
        {   buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		    buf.memory = V4L2_MEMORY_MMAP;
		    buf.index = i;
			if (-1 == ioctl (*capture_fd, VIDIOC_QBUF, &buf))
			    perror("VIDIOC_QBUF:\n");
	    }  

    return 0;
}

/*=====================startCapture========================*/
/* This function starts streaming on the capture device	   */
static int startCapture(int *capture_fd)
{   int a = V4L2_BUF_TYPE_VIDEO_CAPTURE, ret;
    /* Here type of device to be streamed on is required to be passed */
    ret = ioctl(*capture_fd, VIDIOC_STREAMON, &a);
    if (ret < 0) {
        perror("VIDIOC_STREAMON\n");
        return -1;
    }
    return 0;
}

/*=====================stopCapture========================*/
/* This function stops streaming on the capture device	  */
static int stopCapture(int *capture_fd)
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

/*=====================releaseCapture========================*/
/* This function un-maps all the mmapped buffers of capture  *
 * and closes the capture file handle			     */
static int releaseCapture(int *capture_fd, int *numbuffers)
{
    int i;
    for (i = 0; i < *numbuffers; i++) {
        munmap(capture_buff_info[i].start,
                capture_buff_info[i].length);
        capture_buff_info[i].start = NULL;
    }
    close(*capture_fd);
    *capture_fd = 0;
    return 0;
}

/*=====================v4l2capture_perf===========================*/
int v4l2capture_perf(int numargs,const char **argv)
{
    long ctime[MAXLOOPCOUNT];
    double diffc[MAXLOOPCOUNT];
    int i = 0,j=0;
        void *capturebuffer0;
        int counter = 0;
        int ret = 0;
        int capture_fd;
        int capture_numbuffers;
        char outputname[15];
        char stdname[15];
        int frmc=0;
        float avgc=0.0, sumc=0.0;
        int maxbuffers,frames;
    ST_TIMER_ID currentTime;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
    struct v4l2_buffer buf;

    if(numargs == 0 || numargs < 3)
    {   v4l2captureusage();
        return -1;
    }

    /* get the device name*/
    getNextTokenString(&numargs, argv, devicename);
    
    /* get the no. of buffers*/
    getNextTokenInt(&numargs, argv, &maxbuffers);
    if(maxbuffers < 3 || maxbuffers > 5)
    {   PERFLOG("Invalid buffer number.\nPlease give buffer number as anything between 3 & 5 (inclusive).\n");
        v4l2captureusage();
        return -1;
    }
    
    /* get the no. of frames */
    getNextTokenInt(&numargs, argv, &frames);
    if(frames > MAXLOOPCOUNT)
    {   PERFLOG("Invalid number of frames.\nPlease give number of frames to be less than 10000.\n");
        v4l2captureusage();
        return -1;
    }

    capture_numbuffers=maxbuffers;

    for(i = 0; i < maxbuffers; i++) {
        capture_buff_info[i].start = NULL;
    }

    for(i = 0; i < MAXLOOPCOUNT; i++) {
        ctime[i] = 0;
        diffc[i]=0;
    }
    /* STEP2:
     * Initialization section
     * Initialize capture and display devices. 
     * Here one capture channel is opened and input and standard is 
     * detected on thatchannel.
     * Display channel is opened with the same standard that is detected at
     * capture channel.
     * */

    /* open capture channel 0 */
    ret = initCapture(&capture_fd, &capture_numbuffers, outputname, stdname);
    if(ret < 0) {
        PERFLOG("Error in opening capture device for channel 0\n");
        return ret;
    }

    /* STEP3:
     * Here display and capture channels are started for streaming. After 
     * this capture device will start capture frames into enqueued 
     * buffers and display device will start displaying buffers from 
     * the qneueued buffers */

    /* start capturing for channel 0 */
    ret = startCapture(&capture_fd);
    if(ret < 0) {
        PERFLOG("Error in starting capturing for channel 0\n");
        return ret;
    }
    /* It is better to zero out all the members of v4l2_buffer */
        PERFLOG("Running Capture...\n");

    CLEAR(buf);        

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

        while(counter < frames) {
        buf.type=V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf.memory = V4L2_MEMORY_MMAP;
		/* get capturing buffer for channel 0 */
    if (-1 == ioctl(capture_fd, VIDIOC_DQBUF, &buf)) 
    {   if (EAGAIN == errno)
            continue;
        PERFLOG("VIDIOC_DQBUF\n");
        return -1;
    }	
        getTime(&currentTime);
        ctime[j++]=currentTime.tv_usec;
        //PERFLOG("Timestamp %d\n",currentTime.tv_usec);

		/* put buffers in capture channels */
        if (-1 == ioctl(capture_fd, VIDIOC_QBUF, &buf))
        {   PERFLOG("VIDIOC_QBUF\n");
            return -1;
        }
		counter++;
	    }  //while 
    
    /* Get CPU Load figures */ 
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

    /* stop capturing for channel 0 */
    ret = stopCapture(&capture_fd);
    if(ret < 0) {
        PERFLOG("Error in stopping capturing for channel 0\n");
        return ret;
    }

    /* close capture channel 0 */
    ret = releaseCapture(&capture_fd, &capture_numbuffers);
    if(ret < 0) {
        PERFLOG("Error in closing capture device\n");
        return ret;
    }

    /*Calculate the frame rate */
    for(j=0;j<(frames-1);j++)
    {   if(ctime[j+1] > ctime[j])
        {    diffc[j]=ctime[j+1]-ctime[j];
             diffc[j]= (1/(diffc[j]/1000000));
        } 
        else
            diffc[j] = 0;
    }
    
    for(j=0; j<(frames-1); j++)
    {   
        if(diffc[j]>0)
        {   sumc=sumc+diffc[j];
            frmc++;
        }
    } 
   
    avgc=sumc/(frmc-1);

        PERFLOG("Capture frame rate: %lf \n",avgc);
 
    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("v4l2: capture: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    return ret;
}

void v4l2captureusage(void)
{   PERFLOG("./pspTest ThruPut FRv4l2capture {Capture device} {number of buffers} {number of frames}\n");
}

/* vim: set ts=4 sw=4 tw=80 et:*/

