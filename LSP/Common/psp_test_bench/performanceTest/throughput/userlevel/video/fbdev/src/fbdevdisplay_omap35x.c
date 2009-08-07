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
 *  \file   fbdevdisplay_omap35x.c
 *
 *  \brief  FBDEV Display Performance Test for OMAP3530
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
/*Linux specific generic header files */
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>

/*FBDEV specific header files*/
#include <linux/fb.h>

/*Performance Test Header Files */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

/*Macros*/
#define FBIO_WAITFORVSYNC       _IOW('F', 0x20, __u32)
#define MAXLOOPCOUNT		10000
#define WIDTH			480
#define HEIGHT			640
#define BITS_PER_PIXEL		16
#define RED_LENGTH		5
#define GREEN_LENGTH		6
#define BLUE_LENGTH		5
#define RED_OFFSET		11
#define GREEN_OFFSET		5
#define BLUE_OFFSET		0
#define WIDTH_VIRTUAL		480
#define HEIGHT_VIRTUAL		640*2

/*Sysfs paths for controlling output*/
#define OUTPUTPATH "/sys/class/display_control/omap_disp_control/graphics"

static char out_devicename[80];
static short ycbcr[8] = {
	(0x1F << 11) | (0x3F << 5) | (0x1F),
	(0x00 << 11) | (0x00 << 5) | (0x00),
	(0x1F << 11) | (0x00 << 5) | (0x00),
	(0x00 << 11) | (0x3F << 5) | (0x00),
	(0x00 << 11) | (0x00 << 5) | (0x1F),
	(0x1F << 11) | (0x3F << 5) | (0x00),
	(0x1F << 11) | (0x00 << 5) | (0x1F),
	(0x00 << 11) | (0x3F << 5) | (0x1F),
};

/*Function Declarations*/
int fbdevdisplay_perf(int , const char **);
void fbdevdisplayusage(void);
void fill_color_bar(unsigned char *, int, int); 

/*===============================fill_color_bar===============================*/
/*Function to fill up buffer with color bars. */
void fill_color_bar(unsigned char *addr, int width, int height)
{	unsigned short *start = (unsigned short *)addr;
	unsigned int size = width * (height / 8);
	int i, j;

	for(i = 0 ; i < 8 ; i ++) 
	{	for(j = 0 ; j < size / 2 ; j ++) 
		{	*start = ycbcr[i];
			start ++;
		}
	}
}

/*=============================fbdevdisplay_perf==============================*/
int fbdevdisplay_perf(int numargs, const char **argv)
{
	int display_fd;
	struct fb_fix_screeninfo fixinfo;
	struct fb_var_screeninfo varinfo, org_varinfo;
	int buffersize, ret;
	unsigned char *buffer_addr[15];
	int i,j=0;
	char str[80];
	int frames ;
    	long dtime[MAXLOOPCOUNT];
    	double diffd[MAXLOOPCOUNT];
	int frmd=0;
        float avgd, sumd=0;
	int maxbuffers;
	char outputname[15];
	ST_TIMER_ID currentTime;
	ST_CPU_STATUS_ID cpuStatusId;
	float percentageCpuLoad = 0;
	
	if(numargs == 0 || numargs < 4)
	{	fbdevdisplayusage();
        	return -1;
    	}

    	/* get the output device name*/
    	getNextTokenString(&numargs, argv, out_devicename);

    	/* get the no. of buffers*/
    	getNextTokenInt(&numargs, argv, &maxbuffers);
    	if(maxbuffers < 1 || maxbuffers > 5)
    	{   	PERFLOG("Invalid buffer number. Please give buffer number as anything between 1 & 5 (inclusive).\n");
       		fbdevdisplayusage();
        	return -1;
    	}

    	/* get the no. of frames */
    	getNextTokenInt(&numargs, argv, &frames);
    	if(frames > MAXLOOPCOUNT)
    	{   	PERFLOG("Invalid number of frames. Please give number of frames to be less than 10000.\n");
        	fbdevdisplayusage();
        	return -1;
    	}

    	/* get the output interface name*/
        getNextTokenString(&numargs, argv, outputname);
        if(strcmp(outputname, "lcd") ==0)
        {	/*do nothing */ }
        else if(strcmp(outputname, "tv") ==0)
        { 	/*do nothing */ }
        else
        {   	PERFLOG("Invalid output name.\nPlease give it as 'lcd' or 'tv'.\n");
                fbdevdisplayusage();
                return -1;
        }


	/* Set the output for graphics.*/
	strcpy(str, "echo ");
	strcat(str, outputname);
	strcat(str, " > ");
	strcat(str, "OUTPUTPATH");
	if(system(str)) 
	{	exit(0);
	}

	/* Open the display device */
	display_fd = open((unsigned char*)out_devicename, O_RDWR);
	if (display_fd <= 0)
	{	perror("Could not open device\n");
		return -1;
	}

	/* Get fix screen information. Fix screen information gives
	 * fix information like panning step for horizontal and vertical 
	 * direction, line length, memory mapped start address and length etc.
	 */
	ret = ioctl(display_fd, FBIOGET_FSCREENINFO, &fixinfo);
	if (ret < 0) 
	{	perror("Error reading fixed information.\n");
		exit(2);
	}

	/* Get variable screen information. Variable screen information
	 * gives informtion like size of the image, bites per pixel, 
	 * virtual size of the image etc. */
	ret = ioctl(display_fd, FBIOGET_VSCREENINFO, &varinfo);
	if (ret < 0) 
	{	perror("Error reading variable information.\n");
		exit(3);
	}

	memcpy(&org_varinfo, &varinfo, sizeof(varinfo));

	/* Change screen resolution and bits per pixel. Application can 
	 * change resolution parameters, buffer format parameters, 
	 * rotation parameters, buffer size parameters and timing parameters 
	 * through FBIOPUT_VSCREENINFO ioctl. */
	varinfo.xres = WIDTH;
	varinfo.yres = HEIGHT;
	varinfo.xres_virtual = WIDTH_VIRTUAL;
	varinfo.yres_virtual = HEIGHT_VIRTUAL;
	varinfo.bits_per_pixel = BITS_PER_PIXEL;
	varinfo.red.length = RED_LENGTH;
	varinfo.green.length = GREEN_LENGTH;
	varinfo.blue.length = BLUE_LENGTH;
	varinfo.red.offset = RED_OFFSET;
	varinfo.green.offset = GREEN_OFFSET;
	varinfo.blue.offset = BLUE_OFFSET;

	ret = ioctl(display_fd, FBIOPUT_VSCREENINFO, &varinfo);
	if (ret < 0) 
	{	perror("Error writing variable information.\n");
		exit(3);
	}

	/* It is better to get fix screen information again. its because 
	 * changing variable screen info may also change fix screen info. */
	ret = ioctl(display_fd, FBIOGET_FSCREENINFO, &fixinfo);
	if (ret < 0) 
	{	perror("Error reading fixed information.\n");
		exit(2);
	}

	/* Mmap the driver buffers in application space so that application
	 * can write on to them. Driver allocates contiguous memory for 
	 * three buffers. These buffers can be displayed one by one. */
	buffersize = fixinfo.line_length * varinfo.yres;
	buffer_addr[0] = (unsigned char *)mmap (0, buffersize*maxbuffers, 
			(PROT_READ|PROT_WRITE),
			MAP_SHARED, display_fd, 0);

	if ((int)buffer_addr[0] == -1) 
	{	PERFLOG("MMap failed\n");
		return -ENOMEM;
	}

	/* Store each buffer addresses in the local variable. These buffer
	 * addresses can be used to fill the image. */
	for(i = 1 ; i < maxbuffers ; i ++) 
	{	buffer_addr[i] = buffer_addr[i-1] + buffersize;
	}

	/* Fill the buffers with the color bars */
	for(i = 0 ; i < maxbuffers ; i ++) 
	{	fill_color_bar(buffer_addr[i], fixinfo.line_length, 
				varinfo.yres);
	}

       /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

	/* Main loop */
	for (i = 0 ; i <  frames; i ++) 
	{	/* Get the variable screeninfo just to get the resolution. */
		ret = ioctl(display_fd, FBIOGET_VSCREENINFO, &varinfo);
		if(ret < 0) 
		{	perror("Cannot get variable screen info\n");
			munmap(buffer_addr[0], buffersize*maxbuffers);
			close(display_fd);
			exit(0);
		}

		/* Pan the display to the next line. As all the buffers are 
		 * filled with the same color bar, moving to next line gives 
		 * effect of moving color color bar. 
		 * Application should provide y-offset in terms of number of 
		 * lines to have panning effect. To entirely change to next 
		 * buffer, yoffset needs to be changed to yres field. */
		varinfo.yoffset = i % varinfo.yres;

		/* Change the buffer address */
		ret = ioctl(display_fd, FBIOPAN_DISPLAY, &varinfo);
		if(ret < 0) 
		{	perror("Cannot pan display\n");
			munmap(buffer_addr[0], buffersize*maxbuffers);
			close(display_fd);
			exit(0);
		}

		getTime(&currentTime);
        	dtime[j++]=currentTime.tv_usec;

		/* Wait for the currect frame buffer to get displayed. */
		ret = ioctl(display_fd, FBIO_WAITFORVSYNC, 0);
		if(ret < 0) 
		{	perror("FBIO_WAITFORVSYNC\n");
			munmap(buffer_addr[0], buffersize*maxbuffers);
			close(display_fd);
			exit(0);
		}
	}

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

	/* It is better to revert back to original configuration */
	ret = ioctl(display_fd, FBIOPUT_VSCREENINFO, &org_varinfo);
	if (ret < 0) 
	{	perror("Error reading variable information.\n");
		exit(3);
	}

	munmap(buffer_addr[0], buffersize*maxbuffers);
	close(display_fd);
	
	/*Calculate the frame rate */
    	for(j=0;j<(frames-1);j++)
    	{	if(dtime[j+1] > dtime[j])
        	{	diffd[j]=dtime[j+1]-dtime[j];
             		diffd[j]= (1/(diffd[j]/1000000));
        	}
        	else
           		diffd[j] = 0;
    	}
	
    	for(j=0; j<(frames-1); j++)
    	{	if(diffd[j]>0)
        	{   	sumd=sumd+diffd[j];
            		frmd++;
        	}
	}

    	avgd=sumd/(frmd-1);

        PERFLOG("Display frame rate: %lf \n",avgd);

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("fbdev: display: percentage cpu load: %.2f%%\n", percentageCpuLoad);

	return 0;
}

void fbdevdisplayusage(void)
{	PERFLOG("\n./pspTest ThruPut FRfbdevdisplay {Display device} {number of buffers} {number of frames} {output}\n");
   	PERFLOG("\n{Display device}: '/dev/fb0'\n{number of buffers}: anything between 1 to 5\n{number of frames}:anything less than 10000\n{output}:'lcd' or 'tv'\n");
}

