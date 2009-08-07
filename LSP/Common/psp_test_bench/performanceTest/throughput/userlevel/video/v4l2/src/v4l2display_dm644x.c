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
 *  \file   videoThroughput.c
 *
 *  \brief  Video Loopback Performance Test
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \author     Prathap M S
 *
 *  \note       
 *              
 *
 *  \version    0.4     Prachi          Made changes to give user inputs.
 *  \history    0.3     Prachi          Made SYSFS changes.
 *                                      Made changes to update the perf report.
 *              0.2     Siddharth       Cleaned up the code to remove warnings
 *                                      due to unused variables. 
 *                                      Changed all PERFLOGs to PERFLOGs
 *              0.1     Prathap         Created
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

#ifndef LSP_1_1_PRODUCT
/* DM6467 specfic Driver header files */
#include <media/davinci/adv7343.h>
#include <asm/arch/davinci_vdce.h>
#endif

/* Fbdev specific header file */
#include <linux/fb.h>
#ifdef LSP_1_1_PRODUCT
#include <video/davinci_vpbe.h>
#else
#include <video/davincifb_ioctl.h>
/* DM644x specfic Driver header files */
#include <media/davinci/davinci_vpfe.h>
#include <media/davinci/davinci_display.h>
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

/* DM6467 VDCE driver device node */
#define VDCE_DEVICE	"/dev/DavinciHD_vdce"

/* sysfs paths for controlling output and standard */ 
#define OUTPUTPATH  "/sys/class/davinci_display/ch0/output"
#define STDPATH     "/sys/class/davinci_display/ch0/mode"

/* Width and Height used for DM644x capture/display drivers */
#define WIDTH       720
#define HEIGHT      480

/* Minimum buffers needed for loopback to run smoothly */
#define MIN_BUFFERS 2

/* DM644x specific OSD device nodes */
#define OSD0_DEVICE	"/dev/fb/0"
#define OSD1_DEVICE	"/dev/fb/2"

#define CLEAR(x)        memset (&(x), 0, sizeof (x))

struct buf_info {
    int index;
    unsigned int length;
    char *start;
};

/* Capture and display buffers mmaped */
static struct buf_info display_buff_info[MAX_BUFFER];
/* Device node that will be passed by user */
static char out_devicename[15];
/* Platform name that will be passed by user-DM644x or DM6467 */
char platformname[15];
/* OSD0 and OSD1 handles */
static int fd_osd0, fd_osd1;
static int disppitch, dispheight, dispwidth,sizeimage;
unsigned char lines[4][2][240];

static struct v4l2_buffer bufdis;
/* Function declarations */
void color_bar(unsigned char *addr, int pitch, int h, int size, int order);
void fill_lines(void);
int v4l2display_perf(int, const char**);
static int initDisplay(int *, int *, char *, char *);
static int releaseDisplay(int *, int );
static int startDisplay(int *);
static int stopDisplay(int *);
void   v4l2displayusage(void);

/*=====================putDisplayBuffer====================*/
/* This function en-queues a buffer, which contains frame  *
 * to be displayed, into the display device's incoming     *
 * queue.						   */
static int putDisplayBuffer(int *display_fd, int numbuffers, void *addr)
{
	int i, index = 0;
	int ret;
	if (addr == NULL)
		return -1;


	/* Find index of the buffer whose address is passed as the argument */
	for (i = 0; i < numbuffers; i++) {
		if (addr == display_buff_info[i].start) {
			index = display_buff_info[i].index;
			break;
		}
	}

	if(i == numbuffers)
		return -1;

	/* Enqueue the buffer */
	bufdis.m.offset = (unsigned long) addr;
	bufdis.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	bufdis.memory = V4L2_MEMORY_MMAP;
	bufdis.index = index;
	ret = ioctl(*display_fd, VIDIOC_QBUF, &bufdis);
	if(ret < 0) {
		perror("VIDIOC_QBUF\n");
	}
	return ret;
}

/*=====================initDisplay========================*/
/* This function initializes display device. It sets      *
 * output and standard on channel-2. These output and     *
 * standard are same as those detected in capture device. *
 * It, then, enqueues all the buffers in the driver's     *
 * incoming queue.*/
static int initDisplay(int *display_fd, int *numbuffers, char *outputname, 
        char *stdname)
{   int mode = O_RDWR;
        struct v4l2_buffer buf;
        int ret, i=0;
        struct v4l2_requestbuffers reqbuf;
        struct v4l2_format fmt, setfmt;
        struct v4l2_fmtdesc format;

       fd_osd0 = open(OSD0_DEVICE, mode);
	    ioctl(fd_osd0, FBIOBLANK, 1);

	    fd_osd1 = open(OSD1_DEVICE, mode);
        ioctl(fd_osd1, FBIOBLANK, 1);

	    /**
	    *	1.	Open display channel
	    */
	    *display_fd	= open(out_devicename, mode);
	    if(-1 == *display_fd) 
        {   perror("failed to open VID1 display device\n");
		    return -1;
	    }
	    i=0;
        while(1) 
        {   format.index = i;
		    format.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		    ret = ioctl(*display_fd, VIDIOC_ENUM_FMT, &format);
		    if(ret < 0) 
            {   break;
		    }
      		i++;
	    }

	    /**
	    *	Now for the buffers. Request the number of buffers needed
	    *	and the kind of buffers (User buffers or kernel buffers
	    *	for memory mapping).
	    *	Please note that the return value in the reqbuf.count
	    *	might be lesser than numbuffers under some low memory
	    *	circumstances
	    */
	    reqbuf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	    reqbuf.count = *numbuffers;
	    reqbuf.memory = V4L2_MEMORY_MMAP;
	    ret = ioctl(*display_fd, VIDIOC_REQBUFS, &reqbuf);
	    if(ret < 0) 
        {   perror("\n\tError: Could not allocate the buffers: VID1\n");
		    return -1;
	    }
	    
        setfmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
    	setfmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	    setfmt.fmt.pix.sizeimage = WIDTH*HEIGHT*2;
	    setfmt.fmt.pix.bytesperline = WIDTH*2;
	    setfmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	    setfmt.fmt.pix.width = WIDTH;
	    setfmt.fmt.pix.height = HEIGHT;
	    ret = ioctl(*display_fd, VIDIOC_S_FMT, &setfmt);
	    if(ret < 0) 
        {   perror("VIDIOC_S_FMT\n");
		    close(*display_fd);
		    return -1;
	    }

	    /**
	    *	It is necessary for applications to know about the
	    *	buffer chacteristics that are set by the driver for
	    *	proper handling of buffers
	    *	These are : width,height,pitch and image size
	    */
	    fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	    ret = ioctl(*display_fd, VIDIOC_G_FMT, &fmt);
	    if(ret<0) 
        {  perror("VIDIOC_G_FMT");
		    return -1;
    	}
	    dispheight = fmt.fmt.pix.height;
	    disppitch = fmt.fmt.pix.bytesperline;
	    dispwidth = fmt.fmt.pix.width;

	    /**
	    *	Map the buffers to the user space so the app can write
	    *	on to them. (This is for driver buffers and not for User
	    *	pointers). This is done in two stages:
	    *	1. Query for the buffer info like the phys address
	    *	2. mmap the buffer to user space.
	     *
	    *	This information anout the buffers is currently stored in
	    *	a user level data structue
	    */
	    *numbuffers = reqbuf.count;
        memset(&buf, 0, sizeof(buf));

	    for(i = 0 ; i < reqbuf.count; i++) 
        {   buf.index = i;
		    buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		    buf.memory = V4L2_MEMORY_MMAP;
		    ret = ioctl(*display_fd, VIDIOC_QUERYBUF, &buf);
		    if (ret < 0) 
            {   perror("\tError: Querying buffer info failed: VID1\n");
			    return -1;
		    }

            /* Mmap the buffers in application space */
		    display_buff_info[i].length = buf.length;
		    display_buff_info[i].index = i;
		    display_buff_info[i].start =
			mmap(NULL, buf.length, PROT_READ | PROT_WRITE,
				MAP_SHARED, *display_fd, buf.m.offset);
            if ((unsigned int) display_buff_info[i].start == MAP_SHARED) 
            {   perror("Cannot mmap buffer");
			    return -1;
            }
		

	    	/**
		    *	After mapping each buffer, it is a good
		    *	idea to first "zero" them out.
		    *	Here it is being set to a mid grey-scale
		    *	Y=0x80, Cb=0x80, Cr=0x80 for channel 0 &
		    *	it is being set to a shade of green -
		    *	Y=0x00, Cb=0x00, Cr=0x00 - for channel 1
		    */
		    memset(display_buff_info[i].start, 0x80, display_buff_info[i].length);
	    }

        fill_lines();

        for (i = 0; i < reqbuf.count; i++) 
        {   buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		    buf.memory = V4L2_MEMORY_MMAP;
		    buf.index = i;
		    ret = ioctl(*display_fd, VIDIOC_QBUF, &buf);
		    if (ret < 0) 
            {   perror("\n\tError: Enqueuing buffer in VID1");
			    return -1;
		    }
            color_bar(display_buff_info[i].start, disppitch, dispheight,
                                sizeimage, 0);
	    }


            
    
        return 0;
}   

/*=====================releaseDisplay========================*/
/* This function un-maps all the mmapped buffers for display *
 * and closes the capture file handle			     */
static int releaseDisplay(int *display_fd, int numbuffers)
{
    int i;
    for (i = 0; i < numbuffers; i++) {
        munmap(display_buff_info[i].start,
                display_buff_info[i].length);
        display_buff_info[i].start = NULL;
    }
    close(*display_fd);
    *display_fd = 0;
    return 0;
}

/*=====================startDisplay========================*/
/* This function starts streaming on the display device	   */
static int startDisplay(int *display_fd)
{
    int a = 0, ret;
    /* Here type of device to be streamed on is required to be passed */
    a = V4L2_BUF_TYPE_VIDEO_OUTPUT;
    ret = ioctl(*display_fd, VIDIOC_STREAMON, &a);
    if (ret < 0) {
        perror("VIDIOC_STREAMON\n");
        return -1;
    }
    return 0;
}

/*=====================stopDisplay========================*/
/* This function stops streaming on the display device	  */
static int stopDisplay(int *display_fd)
{
    int ret, a=V4L2_BUF_TYPE_VIDEO_OUTPUT;
    ret = ioctl(*display_fd, VIDIOC_STREAMOFF, &a);
    if(ret < 0) {
        perror("display:VIDIOC_STREAMOFF\n");
        return -1;
    }
    return 0;
}

/*=====================getDisplayBuffer====================*/
/* This function de-queues displayed empty buffer from the *
 * display device's outgoing queue. 			   */
static void *getDisplayBuffer(int *display_fd)
{
	int ret;
	struct v4l2_buffer buf;
	/* Dequeue buffer
	 * VIDIOC_DQBUF ioctl de-queues a displayed empty buffer from driver.
	 * This call can be blocking or non blocking. For blocking call, it
	 * blocks untill an empty buffer is available. For non-blocking call,
	 * it returns instantaneously with success or error depending on 
	 * empty buffer is available or not. */
	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(*display_fd, VIDIOC_DQBUF, &buf);
	if (ret < 0) {
		perror("VIDIOC_DQBUF\n");
		return NULL;
	}
	return display_buff_info[buf.index].start;
}

/*=====================v4l2display_perf===========================*/
int v4l2display_perf(int numargs,const char **argv)
{
    long dtime[MAXLOOPCOUNT];
    double diffd[MAXLOOPCOUNT];
    int i = 0, j=0;
        void *displaybuffer;
        int counter = 0;
        int ret = 0;
        int display_fd;
        int display_numbuffers;
        char command[80];
        char stdname[15];
        int frmd=0;
        float avgd, sumd=0;
        int maxbuffers,frames;
        char outputname[15],modename[15];
    ST_TIMER_ID currentTime;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;

    for(i=0;i<MAXLOOPCOUNT;i++)
    {   dtime[i]=0;
        diffd[i]=0;
    }

    if(numargs == 0 || numargs < 5)
    {   v4l2displayusage();
        return -1;
    }

    /* get the output device name*/
    getNextTokenString(&numargs, argv, out_devicename);
    
    /* get the no. of buffers*/
    getNextTokenInt(&numargs, argv, &maxbuffers);
    if(maxbuffers != 3)
    {   PERFLOG("Invalid buffer number.\nPlease give buffer number as 3. To change buffer numbers, first change bootargs.\n");
        v4l2displayusage();
        return -1;
    }
    
    /* get the no. of frames */
    getNextTokenInt(&numargs, argv, &frames);
    if(frames > MAXLOOPCOUNT)
    {   PERFLOG("Invalid number of frames.\nPlease give number of frames to be less than 10000.\n");
        v4l2displayusage();
        return -1;
    }
    
    /* get the output interface name*/
        getNextTokenString(&numargs, argv, outputname);
        if(strcmp(outputname, "COMPOSITE") ==0)
        { /*do nothing */ }
        else if(strcmp(outputname, "SVIDEO") ==0)
        { /*do nothing */ }
        else if(strcmp(outputname, "COMPONENT") ==0)
        { /*do nothing */ }
        else
        {   PERFLOG("Invalid output name.\nPlease give it as 'COMPOSITE' or 'COMPONENT' or 'SVIDEO'.\n");
                v4l2displayusage();
                return -1;
        }

        /* get the output mode name*/
        getNextTokenString(&numargs, argv, modename);
        if(strcmp(modename, "NTSC") ==0)
        { /*do nothing */ }
        else if(strcmp(modename, "PAL") ==0)
        { /*do nothing */ }
        else if(strcmp(modename, "480P-60") ==0)
        { /*do nothing */ }
        else if(strcmp(modename, "576P-50") ==0)
        { /*do nothing */ }
        else
        {   PERFLOG("Invalid mode name.\nPlease give it as 'NTSC' or 'PAL' or '480P-60' or '576P-50'.\n");
                v4l2displayusage();
                return -1;
        }
        /* Set the output in the encoder through sysfs */
        strcpy(command, "echo ");
        strcat(command, outputname);
        strcat(command, " > ");
        strcat(command, OUTPUTPATH);
        if(system(command)) {
                PERFLOG("Failed to set output\n");
                return -1;
        }

        /* Set the standard in the encoder through sysfs */
        strcpy(command, "echo ");
        strcat(command, modename);
        strcat(command, " > ");
        strcat(command, STDPATH);
        if(system(command)) {
                PERFLOG("Failed to set mode\n");
                return -1;
        }
        
    display_numbuffers=maxbuffers;

    for(i = 0; i < maxbuffers; i++) {
        display_buff_info[i].start = NULL;
    }

    /* STEP2:
     * Initialization section
     * Initialize capture and display devices. 
     * Here one capture channel is opened and input and standard is 
     * detected on thatchannel.
     * Display channel is opened with the same standard that is detected at
     * capture channel.
     * */

    /* open display channel */
    ret = initDisplay(&display_fd, &display_numbuffers, outputname, stdname);
    if(ret < 0) {
        PERFLOG("Error in opening display device\n");
        return ret;
    }

    /* STEP3:
     * Here display and capture channels are started for streaming. After 
     * this capture device will start capture frames into enqueued 
     * buffers and display device will start displaying buffers from 
     * the qneueued buffers */

    /* start display */
    ret = startDisplay(&display_fd);
    if(ret < 0) {
        PERFLOG("Error in starting display\n");
        return ret;
    }
        PERFLOG("Running Display:\n");

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

        while(counter < frames) {
		/* get display buffer */
		displaybuffer = getDisplayBuffer(&display_fd);
		if(NULL == displaybuffer) {
			perror("Error in get display buffer\n");
			return ret;
		}

        getTime(&currentTime);
        dtime[j++]=currentTime.tv_usec;

         /* Process it
                In this example, the "processing" is putting a horizontally
                moving color bars with changing starting line of display.
                */
                color_bar(displaybuffer, disppitch, dispheight,
                                sizeimage, counter%160);		

		/* put output buffer into display queue */
		ret = putDisplayBuffer(&display_fd, display_numbuffers, 
				displaybuffer);
		if(ret < 0) {
			PERFLOG("Error in put display buffer\n");
			return ret;
		}

		counter++;
	    }  //while 

    /* Get CPU Load figures */ 
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

    /* stop display */
    ret = stopDisplay(&display_fd);
    if(ret < 0) {
        PERFLOG("Error in stopping display\n");
        return ret;
    }
    
    /* close display channel */
    ret = releaseDisplay(&display_fd, display_numbuffers);
    if(ret < 0) {
        PERFLOG("Error in closing display device\n");
        return ret;
    }

    /*Calculate the frame rate */
    for(j=0;j<(frames-1);j++)
    {   
        if(dtime[j+1] > dtime[j])
        {    diffd[j]=dtime[j+1]-dtime[j];
             diffd[j]= (1/(diffd[j]/1000000));
        }
        else
            diffd[j] = 0;
    }
    
    for(j=0; j<(frames-1); j++)
    {   
       // PERFLOG(" %lf %d\n",diffd[j], j);
       if(diffd[j]>0)
        {   sumd=sumd+diffd[j];
            frmd++;
        }
        
    } 
   
    avgd=sumd/(frmd-1);

        PERFLOG("Display frame rate: %lf \n",avgd);
 
    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("v4l2: display: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    return ret;
}

void v4l2displayusage(void)
{   PERFLOG("./pspTest ThruPut FRv4l2display {Display device} {number of buffers} {number of frames} {output interface} {output mode/resolution}.\n");
}

void fill_lines()
{
        unsigned char CVal[4][2] = {{0x5A, 0xF0},{0x36, 0x22},
                                {0xF0, 0x6E},{0x10, 0x92}};
        int i, j ,k;
        /* Copy Y data for all 4 colors in the array */
        memset(lines[0][0], 0x51, 240);
        memset(lines[1][0], 0x91, 240);
        memset(lines[2][0], 0x29, 240);
        memset(lines[3][0], 0xD2, 240);
        /* Copy C data for all 4 Colors in the array */
        for(i = 0 ; i < 4 ; i ++) {
                for(j = 0 ; j < 2 ; j ++){
                        for(k = 0 + j ; k < 240 ; k+=2)
                                lines[i][1][k] = CVal[i][j];
                }
        }
}
void color_bar(unsigned char *addr, int pitch, int h, int size, int order)
{
        unsigned char *ptrY = addr;
        unsigned char *ptrC = addr + pitch*(size/(pitch*2));
        unsigned char *tempY, *tempC;
        int i, j;

        /* Calculate the starting offset from where Y and C data should
         * should start. */
        tempY = ptrY + pitch * 160 + 240 + order*pitch;
        tempC = ptrC + pitch * 160 + 240 + order*pitch;
        /* Fill all the colors in the buffer */
        for(j = 0; j < 4 ; j ++) {
                for(i = 0; i < 40 ; i ++) {
                        memcpy(tempY, lines[j][0], 240);
                        memcpy(tempC, lines[j][1], 240);
                        tempY += pitch;
                        tempC += pitch;
                        if(tempY > (ptrY + pitch * 320 + 240 + pitch)) {
                                tempY = ptrY + pitch * 160 + 240;
                                tempC = ptrC + pitch * 160 + 240;
                        }
                }
        }

}

/* vim: set ts=4 sw=4 tw=80 et:*/
