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
 *  \file   v4l2display_dm6467.c
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
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <errno.h>
#include<linux/videodev.h>
#include<linux/videodev2.h>
#include <string.h>
/*  Performance Test Header Files */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

/******************************************************************************
 Macros
 MAX_BUFFER     : Changing the following will result different number of 
		  instances of buf_info structure.
 OUTPUTNAME	: Name of the output interface
 MODENAME	: Name of the mode
 MAXLOOPCOUNT	: Display loop count
 OUTPUTPATH     : This indicates absolute path of the sysfs entry for
                  controlling output
 STDPATH        : This indicates absolute path of the sysfs entry for
                  controlling standard
 ******************************************************************************/
#define MAX_BUFFER	8
#define OUTPUTNAME	"COMPOSITE"
/* NTSC */
#define MODENAME	"NTSC"
#define MAXLOOPCOUNT	10000	
#define OUTPUTPATH      "/sys/class/davinci_display/ch0/output"
#define STDPATH         "/sys/class/davinci_display/ch0/mode"

static int display_fd = 0;

struct buf_info {
	int index;
	unsigned int length;
	char *start;
};

/* Device node that will be passed by user */
static char out_devicename[15];
static struct v4l2_buffer bufc, bufd;

static struct buf_info display_buff_info[MAX_BUFFER];
int maxbuffers;

/******************************************************************************
                        Function Definitions
 ******************************************************************************/
static int releaseDisplay();
static int startDisplay();
static int stopDisplay();
static void *getDisplayBuffer();
static int putDisplayBuffer( void *addr);
void color_bar(unsigned char *addr, int pitch, int h, int size, int order);
int v4l2display_perf(int,const char**);
void v4l2displayusage(void);
/*
        This routine unmaps all the buffers
        This is the final step.
*/
static int releaseDisplay()
{
	int i;
	for (i = 0; i < maxbuffers; i++) {
		munmap(display_buff_info[i].start,
			display_buff_info[i].length);
		display_buff_info[i].start = NULL;
	}
	close(display_fd);
	display_fd = 0;
	return 0;
}
/*
	Starts Streaming
*/
static int startDisplay()
{
	int a = V4L2_BUF_TYPE_VIDEO_OUTPUT, ret;
	ret = ioctl(display_fd, VIDIOC_STREAMON, &a);
	if (ret < 0) {
		perror("VIDIOC_STREAMON\n");
		return -1;
	}
	return 0;
}

/*
 Stops Streaming
*/
static int stopDisplay()
{
	int ret, a = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(display_fd, VIDIOC_STREAMOFF, &a);
	return ret;
}

/* 
	Does a DEQUEUE and gets/returns the address of the 
	dequeued buffer
*/
static void *getDisplayBuffer()
{
	int ret;
	struct v4l2_buffer buf;
	//memset(&buf, 0, sizeof(buf));
	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(display_fd, VIDIOC_DQBUF, &buf);
	if (ret < 0) {
		perror("VIDIOC_DQBUF\n");
		return NULL;
	}
	return display_buff_info[buf.index].start;
}

/*
	Takes the adrress, finds the appropriate index 
	of the buffer, and QUEUEs the buffer to display
	If this part is done in the main loop,
	there is no need of this conversionof address 
	to index as both are available.
*/
static int putDisplayBuffer( void *addr)
{
	int i, index = 0;
	int ret;
	if (addr == NULL)
		return -1;
//	memset(&buf, 0, sizeof(buf));

	for (i = 0; i < maxbuffers; i++) {
		if (addr == display_buff_info[i].start) {
			index = display_buff_info[i].index;
			break;
		}
	}
	bufd.m.offset = (unsigned long) addr;
	bufd.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	bufd.memory = V4L2_MEMORY_MMAP;
	bufd.index = index;
	ret = ioctl(display_fd, VIDIOC_QBUF, &bufd);
	return ret;
}

/* Following array keeps track of Y and C data for 4 colors of 240 pixels.
 * First index is for colors, second index is for Y and C data and third
 * index is for pixels. These values are used in filling up the buffers.
 */
unsigned char lines[4][2][240];

/* 
 * Following function fills the lines array will Y and CbCr values for 4 colors.
 * These values are used in filling up the display buffer.
 */
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
int v4l2display_perf(int numargs,const char **argv)
{
	long dtime[MAXLOOPCOUNT];
    	double diffd[MAXLOOPCOUNT];
	int frmd=0,popbuffer;
        float avgd=0.0, sumd=0.0;
	int mode = O_RDWR;
        struct v4l2_requestbuffers reqbuf;
        struct v4l2_buffer buf;
        struct v4l2_format fmt;
	int i = 0, j = 0;
	void *displaybuffer;
	int counter = 0;
	int ret = 0;
	int dispheight, disppitch, dispwidth, sizeimage;
	char command[80];
	int frames;
	char outputname[15],modename[15];
    ST_TIMER_ID currentTime;
 
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
unsigned long elapsedUsecs = 0;

	if(numargs == 0 || numargs <5)
    	{   v4l2displayusage();
        	return -1;
    	}

	/* get the output device name*/
    	getNextTokenString(&numargs, argv, out_devicename);

    	/* get the no. of buffers*/
    	getNextTokenInt(&numargs, argv, &maxbuffers);
    	if(maxbuffers < 3 || maxbuffers > 5)
    	{   PERFLOG("Invalid buffer number.\nPlease give buffer number as anything between 3 & 5 (inclusive).\n");
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
    	else if(strcmp(modename, "720P-50") ==0)
	{ /*do nothing */ }
    	else if(strcmp(modename, "720P-60") ==0)
	{ /*do nothing */ }
    	else if(strcmp(modename, "1080I-25") ==0)
	{ /*do nothing */ }
    	else if(strcmp(modename, "1080I-30") ==0)
	{ /*do nothing */ }
        else
    	{   PERFLOG("Invalid mode name.\nPlease give it as 'NTSC' or 'PAL' or '480P-60' or '576P-50' or '720P-50' or '720P-60' or '1080I-25' or '1080I-30'.\n");
       		v4l2displayusage();
        	return -1;
    	}
	
    	/* get the no. of frames */
   /* 	getNextTokenInt(&numargs, argv, &popbuffer);*/
	/* Set the output in the encoder through sysfs */
	strcpy(command, "echo ");
	strcat(command, outputname);
	strcat(command, " > ");
	strcat(command, OUTPUTPATH);
	if(system(command)) {
		PERFLOG("Failed to set output\n");
		return -1;
	}
	for(i=0;i<MAXLOOPCOUNT;i++)
	{diffd[i]=0;
	dtime[i]=0;
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

	/* open display channel */
        display_fd = open((const char *)out_devicename, mode);
        if(display_fd == -1) {
		PERFLOG("failed to open display device\n");
        	return -1;
        }

	/*
	Now for the buffers.Request the number of buffers needed and
	the kind of buffers(User buffers or kernel buffers 
	for memory mapping).
	Please note that the return value in the reqbuf.count
	might be lesser than maxbuffers under some low memory
	circumstances 
	*/
	
        reqbuf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
        reqbuf.count = maxbuffers;
        reqbuf.memory = V4L2_MEMORY_MMAP;

        ret = ioctl(display_fd, VIDIOC_REQBUFS, &reqbuf);
        if (ret<0) {
                PERFLOG("Could not allocate the buffers\n");
                return -1;
        }
        /*
	Now map the buffers to the user space so the app can write
	on to them( This is for driver buffers and not for User 
	pointers).This is done in two stages:
	1. Query for the buffer info like the phys address
	2. mmap the buffer to user space.
	
	This information anout the buffers is currently stored in
	a user level data structue
	*/

	maxbuffers = reqbuf.count;
        for(i = 0 ; i < reqbuf.count ; i ++) {
		/* query */
                buf.index = i;
                buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
                buf.memory = V4L2_MEMORY_MMAP;
                ret = ioctl(display_fd, VIDIOC_QUERYBUF, &buf);
                if (ret < 0) {
                        PERFLOG("quering for buffer info failed\n");
                        return -1;
                }
		/* mmap */
                display_buff_info[i].length = buf.length;
                display_buff_info[i].index = i;
                display_buff_info[i].start =
                        mmap(NULL, buf.length, PROT_READ | PROT_WRITE,
                                MAP_SHARED, display_fd, buf.m.offset);
                        memset(display_buff_info[i].start,0x80,buf.length);

                if ((unsigned int) display_buff_info[i].
                        start == MAP_SHARED) {
                        PERFLOG("Cannot mmap = %d buffer\n", i);
                        return -1;
                }
		/* 
		After mapping each buffer, it is a good 
		idea to first "zero" them out.
		Here it is being set to a mid grey-scale
		Y=0x80, Cb=0x80, Cr=0x80
		*/
		memset(display_buff_info[i].start,0x80,buf.length);
        }

	/* 
	It is necessary for applications to know about the 
	buffer chacteristics that are set by the driver for 
	proper handling of buffers
	These are : width,height,pitch and image size
	*/
	fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(display_fd, VIDIOC_G_FMT, &fmt);
        if(ret<0){
                PERFLOG("Get Format failed\n");
                return -1;
	}
	dispheight = fmt.fmt.pix.height;
	disppitch = fmt.fmt.pix.bytesperline;
	dispwidth = fmt.fmt.pix.width;
	sizeimage = fmt.fmt.pix.sizeimage;
	
	/* 
	Queue all the buffers for the initial pruning
	*/
        
	/* Fill up the lines array with appropriate colors values */
	fill_lines();
        for (i = 0; i < reqbuf.count; i++) {
                buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
                buf.memory = V4L2_MEMORY_MMAP;
                buf.index = i;
                ret = ioctl(display_fd, VIDIOC_QBUF, &buf);
                if (ret < 0) {
                        perror("VIDIOC_QBUF\n");
                        return -1;
                }
		/* Fill up the buffers with the values.*/
		color_bar(display_buff_info[i].start, disppitch, dispheight, 
				sizeimage, 0);
        }

	
	ret = startDisplay();
	if(ret < 0) {
		PERFLOG("Error in starting display\n");
		return ret;
	}

	/*
	This is a running loop where the buffer is 
	DEQUEUED  <-----|
	PROCESSED	|
	& QUEUED -------|
	
	
	*/
	PERFLOG("Running Display:");
	
    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);
	
	while(counter < frames) {
		
		/*
			Get display buffer
		*/
		displaybuffer = getDisplayBuffer();
		if(NULL == displaybuffer) {
			PERFLOG("Error in getting the  display buffer\n");
			return ret;
		}

		getTime(&currentTime);
		dtime[j++]= currentTime.tv_usec;
	//	PERFLOG("Time for display frame %d is %ld\n",counter,currentTime.tv_usec);
		
		/* Process it
		In this example, the "processing" is putting a horizontally 
		moving color bars with changing starting line of display.
		*/
//if(popbuffer==1)
//{	
	color_bar(displaybuffer, disppitch, dispheight, 
				sizeimage, counter%160);
		
//}
		/* Now queue it back to display it */
		ret = putDisplayBuffer(displaybuffer);
		if(ret < 0) {
			PERFLOG("Error in putting the display buffer\n");
			return ret;
		}

		counter++;
	}

    /* Get CPU Load figures */ 
   percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

	/* 
	Once the streaming is done  stop the display 
	hardware 
	*/
	ret = stopDisplay();
	if(ret < 0) {
		PERFLOG("Error in stopping display\n");
		return ret;
	}
	/* open display channel */
	releaseDisplay();
	
	/*Calculate the frame rate */
    	for(j=0;j<(frames-1);j++)
        {	if(dtime[j+1] > dtime[j])
        	{    	diffd[j]=dtime[j+1]-dtime[j];
             		diffd[j]= (1/(diffd[j]/1000000));
        	}
        	else
            	{	diffd[j] =1000000 - dtime[j] + dtime[j+1];
             		diffd[j]= (1/(diffd[j]/1000000));
		}	
    	}

    	for(j=0; j<(frames-1); j++)
    	{  
       // PERFLOG("\n%lf %d ",diffd[j],j);
		
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
{   PERFLOG("./pspTest ThruPut FRv4l2display {Display device} {number of buffers} {number of frames} {output interface} {output mode/resolution}\n");
}



