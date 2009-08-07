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
 *  \file   fbdevdisplay_dm644x.c
 *
 *  \brief  FBDEV Display Performance Test for DM6446
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \author     Saumya Agarwal
 *
 *  \note
 *
 *
 *  \version    0.1     Saumya          Created.
 */

/******************************************************************************
  Header File Inclusion
 ******************************************************************************/
/*Linux specific generic header files*/
#include <stdio.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <getopt.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <unistd.h>
#include <unistd.h>
#include <sys/time.h>
#include <asm/types.h>
#include <time.h>

/*FBDEV specific header file*/
#include <linux/fb.h>

#ifdef LSP_1_1_PRODUCT
#include <video/davincifb.h>
#else
#include <video/davincifb_ioctl.h>
#endif

/*Performance Test Header Files */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

/* Maximum buffers that can be requested */
#define MAX_BUFFER  8
/* Pitch of the image */
#define BUFFER_PITCH    1440
/* Height of the image */
#define BUFFER_HEIGHT   576
/* Loop count - Number of frames displayed */
#define MAXLOOPCOUNT    10000

/* sysfs paths for controlling output and standard */ 
#define OUTPUTPATH  "/sys/class/davinci_display/ch0/output"
#define STDPATH     "/sys/class/davinci_display/ch0/mode"

#define CLEAR(x)        memset (&(x), 0, sizeof (x))


/* Function error codes */
#define SUCCESS         0
#define FAILURE         -1

/* Bits per pixel for video window */
#define BPP          16

#define round_32(width) ((((width) + 31) / 32) * 32 )

/* default WIDTH, HEIGHT and FRAME_SIZE, VMODE */
#define WIDTH   720
#define HEIGHT  480
#define FRAME_SIZE  (WIDTH * HEIGHT)

/* D1 screen dimensions */
#define NTSC_WIDTH      720
#define NTSC_HEIGHT		480
#define NTSC_FRAME_SIZE		(NTSC_WIDTH * NTSC_HEIGHT)

#define PAL_WIDTH 		720
#define PAL_HEIGHT		576
#define PAL_FRAME_SIZE		(PAL_WIDTH*PAL_HEIGHT)

#define MAX_YRES        576

#define	XPOS		0
#define	YPOS		0

//Globals
/* ************************************************************************/
char *vid_display[MAX_BUFFER] = {NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};
int fd = 0;
struct fb_var_screeninfo vid_varInfo;
struct fb_fix_screeninfo vid_fixInfo;
int width = 0;
int height = 0;
int vid_size = 0;

/* command line arguments */
int maxbuffers;
int frames;
static char devicename[15];
char stdname[15];
char outputname[15];

/* functions */
static int DisplayFrame ();
int unmap_and_disable ();
int FlipVideoBuffers (int nBufIndex);
int mmap_vid ();
int init_vid_device (int fd, struct fb_var_screeninfo *pvarInfo);
void close_video_window ();
int open_video_window ();
void usage();

/* frame rate calculation variables */
long cTime[MAXLOOPCOUNT];
int timeIndex = 0;


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


/* This function is used to fill up buffer with color bars. */
void fill_color_bar(unsigned char *addr, int width, int height)
{
    unsigned short *start = (unsigned short *)addr;
    unsigned int size = width * (height / 8);
    int i, j;

    for(i = 0 ; i < 8 ; i ++) {
        for(j = 0 ; j < size / 2 ; j ++) {
            *start = ycbcr[i];
            start ++;
        }
    }
}


/******************************************************************************
 * Display frames 
 ******************************************************************************/
static int DisplayFrame ()
{
    static unsigned int nDisplayIdx = 0;
    static unsigned int nWorkingIndex = 1;
    char *src;
    unsigned int line_length;	

    src = vid_display[nWorkingIndex];
    line_length = vid_fixInfo.line_length;

    nWorkingIndex = (nWorkingIndex + 1) % maxbuffers;
    nDisplayIdx = (nDisplayIdx + 1) % maxbuffers;
    if ((FlipVideoBuffers (nDisplayIdx)) < 0)
        return -1;

    return 0;
}



/******************************************************************************
 * Flip buffers 
 ******************************************************************************/
int FlipVideoBuffers (int nBufIndex)
{
    struct fb_var_screeninfo vInfo;
    ST_TIMER_ID currentTime;

    if (ioctl (fd, FBIOGET_VSCREENINFO, &vInfo) < -1)
    {
        PERFLOG ("FlipVideoBuffers:FBIOGET_VSCREENINFO\n");
        PERFLOG ("\n");
        return -1;
    }

    vInfo.yoffset = vInfo.yres * nBufIndex;
    /* Swap the working buffer for the displayed buffer */
    if (ioctl (fd, FBIOPAN_DISPLAY, &vInfo) < -1)
    {
        PERFLOG ("FlipVideoBuffers:FBIOPAN_DISPLAY\n");
        PERFLOG ("\n");
        return -1;
    }

    /* calculate display time stamp */
    getTime(&currentTime);
    cTime[timeIndex++] = currentTime.tv_usec;    

    return 0;
}

/******************************************************************************
 * mmap buffers 
 ******************************************************************************/
int mmap_vid ()
{
    int i;
    vid_size = vid_fixInfo.line_length * vid_varInfo.yres;

    /* Map the video0 buffers to user space */
    vid_display[0] = (char *) mmap (NULL,
            vid_size * maxbuffers,
            PROT_READ | PROT_WRITE,
            MAP_SHARED, fd, 0);

    if (vid_display[0] == MAP_FAILED)
    {
        PERFLOG ("\nFailed mmap on %s", devicename);
        return FAILURE;
    }

    /* Store each buffer addresses in the local variable. These buffer
     * addresses can be used to fill the image. */
    for(i = 1 ; i < maxbuffers; i++) 
    {
        vid_display[i] = vid_display[i-1] + vid_size;
    }
    return 0;
}


/******************************************************************************
 * unmap buffers and disable video window 
 ******************************************************************************/
int unmap_and_disable(void)
{

    if (munmap (vid_display[0], vid_size * maxbuffers) == -1)
    {
        PERFLOG ("\nFailed munmap on %s", devicename);
        return FAILURE;
    }

/* disable vid window */
#ifdef LSP_1_1_PRODUCT
    if (ioctl(fd, FBIO_ENABLE_DISPLAY, VPBE_DISABLE) < 0) {
		PERFLOG("Failed  FBIO_ENABLE_DISPLAY\n");
		return FAILURE;
	}
#else    
    if (ioctl(fd, FBIOBLANK, 1) < 0) {
        PERFLOG("Failed  FBIOBLANK\n");
        return FAILURE;
    }
#endif    

    return SUCCESS;
}


/******************************************************************************
 * initialize video window 
 ******************************************************************************/
int init_vid_device(int fd, struct fb_var_screeninfo *pvarInfo)
{
    vpbe_window_position_t pos;

    if (ioctl(fd, FBIOGET_FSCREENINFO, &vid_fixInfo) < 0) {
        PERFLOG("\nFailed FBIOGET_FSCREENINFO vid");
        return FAILURE;
    }

    /* Get Existing var_screeninfo */
    if (ioctl(fd, FBIOGET_VSCREENINFO, pvarInfo) < 0) {
        PERFLOG("\nFailed FBIOGET_VSCREENINFO");
        return FAILURE;
    }

    /* Modify the resolution and bpp as required */
    pvarInfo->xres = width;
    pvarInfo->yres = height;
    pvarInfo->bits_per_pixel = BPP;

    /* Change the virtual Y-resolution for buffer flipping  */
    pvarInfo->yres_virtual = MAX_YRES * maxbuffers;

#ifdef LSP_1_1_PRODUCT
    if (!strcmp(stdname, "480P-60") || !strcmp(stdname, "576P-50"))
        pvarInfo->vmode = FB_VMODE_NONINTERLACED;
    else if(!strcmp(stdname, "NTSC") || !strcmp(stdname, "PAL"))
        pvarInfo->vmode = FB_VMODE_INTERLACED;

#endif


    /* Set window parameters */
    if (ioctl(fd, FBIOPUT_VSCREENINFO, pvarInfo) < 0) {
        PERFLOG("\nFailed FBIOPUT_VSCREENINFO");
        return FAILURE;
    }

    /* Set window position */
    pos.xpos = XPOS;
    pos.ypos = YPOS;

    if (ioctl(fd, FBIO_SETPOS, &pos) < 0) {
        PERFLOG("\nFailed  FBIO_SETPOS");
        return FAILURE;
    }
    
/* enable display */
#ifdef LSP_1_1_PRODUCT
    if (ioctl(fd, FBIO_ENABLE_DISPLAY, VPBE_ENABLE)) {
		PERFLOG("Failed  FBIO_ENABLE_DISPLAY\n");
		return FAILURE;
	}
#else    

    if (ioctl(fd, FBIOBLANK, 0) < 0) {
        PERFLOG("Failed  FBIOBLANK\n");
        return FAILURE;
    }
#endif
    return SUCCESS;
}

/******************************************************************************
* close video window 
******************************************************************************/

void close_video_window ()
{
    close (fd);
}

/******************************************************************************
* open, disable and close all window
******************************************************************************/

int open_and_disable()
{
    int fd0, fd1, fd2, fd3;

    /* open all windows */
    if ((fd0 = open ("/dev/fb/0", O_RDWR)) < 0)
    {
        return FAILURE;
    }
    if ((fd1 = open ("/dev/fb/1", O_RDWR)) < 0)
    {
        return FAILURE;
    }
    if ((fd2 = open ("/dev/fb/2", O_RDWR)) < 0)
    {
        return FAILURE;
    }
    if ((fd3 = open ("/dev/fb/3", O_RDWR)) < 0)
    {
        return FAILURE;
    }

    /* disable osd0 and disable display on all windows */
#ifdef LSP_1_1_PRODUCT
    if (fd0 >= 0)
    {
        if (ioctl(fd0, FBIO_ENABLE_DISPLAY, VPBE_DISABLE) < 0) {
            PERFLOG("Failed  FBIO_ENABLE_DISPLAY\n");
            return FAILURE;
        }

        if (ioctl(fd0, FBIO_ENABLE_DISABLE_WIN, VPBE_DISABLE) < 0) {
            PERFLOG("Failed  FBIO_ENABLE_DISABLE_WIN\n");
            return FAILURE;
        }
        close(fd0);
    }
    if (fd1 >= 0)
    {
        if (ioctl(fd1, FBIO_ENABLE_DISPLAY, VPBE_DISABLE) < 0) {
            PERFLOG("Failed  FBIO_ENABLE_DISPLAY\n");
            return FAILURE;
        }
        close(fd1);
    }
    if (fd2 >= 0)
    {
        if (ioctl(fd2, FBIO_ENABLE_DISPLAY, VPBE_DISABLE) < 0) {
            PERFLOG("Failed  FBIO_ENABLE_DISPLAY\n");
            return FAILURE;
        }
        close(fd2);
    }
    if (fd3 >= 0)
    {
        if (ioctl(fd3, FBIO_ENABLE_DISPLAY, VPBE_DISABLE) < 0) {
            PERFLOG("Failed  FBIO_ENABLE_DISPLAY\n");
            return FAILURE;
        }
        close(fd3);
    }

#else
    if (fd0 >= 0)
    {
        if (ioctl(fd0, FBIOBLANK, 1) < 0) {
            PERFLOG("Failed  FBIOBLANK\n");
            return FAILURE;
        }
        close(fd0);
    }
    if (fd1 >= 0)
    {
        if (ioctl(fd1, FBIOBLANK, 1) < 0) {
            PERFLOG("Failed  FBIOBLANK\n");
            return FAILURE;
        }
        close(fd1);
    }
    if (fd2 >= 0)
    {
        if (ioctl(fd2, FBIOBLANK, 1) < 0) {
            PERFLOG("Failed  FBIOBLANK\n");
            return FAILURE;
        }
        close(fd2);
    }
    if (fd3 >= 0)
    {
        if (ioctl(fd3, FBIOBLANK, 1) < 0) {
            PERFLOG("Failed  FBIOBLANK\n");
            return FAILURE;
        }
        close(fd3);
    }

#endif

return 0;

}

/******************************************************************************
 * open video window 
 ******************************************************************************/
int open_video_window ()
{

    if ((fd = open (devicename, O_RDWR)) < 0)
    {
        close_video_window();
        return FAILURE;
    }

#ifdef LSP_1_1_PRODUCT
    if (ioctl(fd, FBIO_ENABLE_DISABLE_WIN, VPBE_ENABLE)) {
	    PERFLOG("Failed  FBIO_ENABLE_DISABLE_WIN\n");
        close_video_window();
		return FAILURE;
	}
#endif

    return SUCCESS;


}


/******************************************************************************
 * Displays usage of command 
 ******************************************************************************/
void usage()
{

    PERFLOG("Enter        : ./fbdevdisplay [devicename] [noofbuffers] [noofframes] [modename] [outputname]\n\n");
    PERFLOG("devicename   : /dev/fb/1 for video 0 \n\t     /dev/fb/3 for video 3\n");
    PERFLOG("noofbuffers  : \n2 for /dev/fb/0 and /dev/fb/2 \n 3 to 8 for /dev/fb/1 and /dev/fb/3\n");
    PERFLOG("Bootargs should be changed according to the noofbuffers requested\n\n"); 
    PERFLOG("noofframes   : 500 to 10000\n");
    PERFLOG("modename     : NTSC/PAL/480P-60/576P-50\n");
    PERFLOG("outputname   : COMPOSITE/COMPONENT/SVIDEO\n\n"); 
}


/******************************************************************************/
/* main function */ 
int fbdevdisplay_perf(int numargs, char **argv)
{
    double diffc[MAXLOOPCOUNT];
    int frmc=0;
    float avgc=0.0, sumc=0.0;

    int i = 0;
    int j = 0;
    int dummy;
#ifndef LSP_1_1_PRODUCT
    char command[80];
#endif

    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;


    if( numargs == 0 || numargs < 5)
    {   
        usage();
        return FAILURE;
    }


    /* get the device name:OSD0 is "/dev/fb/0" and OSD1 is "/dev/fb/2" */
    getNextTokenString(&numargs, argv, devicename);

    /* get the no. of buffers*/
    getNextTokenInt(&numargs, argv, &maxbuffers);

    if(maxbuffers < 2 || maxbuffers > 8)
    {   
        PERFLOG("Invalid buffer number.\nPlease give buffer number as anything between 2 & 8 (inclusive).\n");
        usage();
        return FAILURE;
    }

    /* get the no. of frames */
    getNextTokenInt(&numargs, argv, &frames);

    if(frames > MAXLOOPCOUNT || frames < 500)
    {   PERFLOG("Invalid number of frames.\nPlease give number of frames between 500 and 10000.\n");
        usage();
        return FAILURE;
    }

    /* get standard - NTSC, PAL, 480P-60, 576P-50 */
    getNextTokenString(&numargs, argv, stdname);
    if ((!strcmp(stdname, "NTSC")) || (!strcmp(stdname, "480P-60")))
    {
        width = NTSC_WIDTH;
        height = NTSC_HEIGHT;
    }
    else if ((!strcmp(stdname, "PAL")) || (!strcmp(stdname, "576P-50")))
    {
        width = PAL_WIDTH;
        height = PAL_HEIGHT;    
    }
    else
    {
        PERFLOG("Invalid standard name\n");   
        usage();
        return FAILURE;
    }
    /* get output name - COMPOSITE, COMPONENT, SVIDEO */
    getNextTokenString(&numargs, argv, outputname);    
    if ((strcmp(outputname, "COMPOSITE") != 0) && (strcmp(outputname,"COMPONENT")!=0) && (strcmp(outputname,"SVIDEO") != 0))
    {
        PERFLOG("Invalid output name\n");
        usage();
        return FAILURE;
    }

    /* open. disable and close all windows*/
    if (open_and_disable () !=0)
    {
        PERFLOG ("Could not open and disable all Windows\n");
        return FAILURE;
    }
    /* open vid window */      
    if (open_video_window () != 0)
    {
        PERFLOG ("Could not open Video Window\n");
        return FAILURE;
    }

    /* disable window */
#ifdef LSP_1_1_PRODUCT
    if (ioctl(fd, FBIO_ENABLE_DISPLAY, VPBE_DISABLE) < 0) {
        PERFLOG("Failed  FBIO_ENABLE_DISPLAY\n");
        return FAILURE;
    }
#else

    if (ioctl(fd, FBIOBLANK, 1) < 0) {
        PERFLOG("Failed  FBIOBLANK\n");
        return FAILURE;
    }
#endif


#ifdef LSP_1_1_PRODUCT
    vpbe_mode_info_t mode_info;

    if (!strcmp(stdname, "NTSC"))
    {
        mode_info.mode_idx = NTSC;
    }
    else if (!strcmp(stdname, "PAL"))   
    {
        mode_info.mode_idx = PAL;
    }
    else if (!strcmp(stdname, "480P-60")) 
    {  
        mode_info.mode_idx = P525;
    }
    else if (!strcmp(stdname, "576P-50"))   
    {
        mode_info.mode_idx = P625;
    }


    if (!strcmp(outputname, "COMPOSITE"))
    {
        mode_info.interface = COMPOSITE;
    }
    else if (!strcmp(outputname, "COMPONENT"))
    {
        mode_info.interface = COMPONENT;
    }
    else if (!strcmp(outputname, "SVIDEO"))
    {
        mode_info.interface = SVIDEO;
    }

    /* Query mode */
    if (ioctl(fd, FBIO_QUERY_TIMING, &mode_info) < 0) {
        PERFLOG("Failed  FBIO_QUERY_TIMING\n");
        close(fd);
        return FAILURE;
    }

    if (!strcmp(mode_info.vid_mode.name, "\0")) {
        PERFLOG("Mode not supported\n");
        close(fd);
        return FAILURE;
    }
    
    /* Set MODE */
    if (ioctl(fd, FBIO_SET_TIMING, &mode_info.vid_mode) < 0) {
        PERFLOG("Failed  FBIO_SET_TIMING\n");
        close(fd);
        return FAILURE;
    }

#else

    /* set sysfs variables */

    /* set output path */
    strcpy(command, "echo ");
    strcat(command, outputname);
    strcat(command, " > ");
    strcat(command, OUTPUTPATH);

    if (system(command))
    {
        PERFLOG("outputname not set\n");
        return FAILURE;
    }

    /* set mode */
    strcpy(command, "echo ");
    strcat(command, stdname);
    strcat(command, " > ");
    strcat(command, STDPATH);

    if (system(command))
    {
        PERFLOG("stdname not set\n");
        return FAILURE;
    }
#endif

    /* Initialize video device */
    if ((init_vid_device (fd, &vid_varInfo)) < 0)
    {
        PERFLOG ("Failed to init video window\n");
        return FAILURE;
    }

    /* mmap buffers */
    if (mmap_vid() == FAILURE)
    {
        PERFLOG("Failed to map buffers\n");
        return FAILURE; 
    }

    /* Fill the buffers with the color bars */
    for(i = 0 ; i < maxbuffers ; i ++)
    {
        fill_color_bar(vid_display[i], vid_fixInfo.line_length, vid_varInfo.yres);
    }

    PERFLOG("\nRunning Display:\n");

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

    /* Display frames */
    for (i = 0; i < frames; i++)
    {
        DisplayFrame();

        /* Wait for vertical sync */
        if (ioctl (fd, FBIO_WAITFORVSYNC, &dummy) < 0)
        {
            PERFLOG ("Failed FBIO_WAITFORVSYNC\n");
            return FAILURE;
        }
    }

    /* Get CPU Load figures */ 
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

    /* unmap video buffers */
    if (unmap_and_disable () < 0)
        return FAILURE;

    /* close vid window */
    close_video_window ();


    /* Calculate Display Frame rate */
    for(j=0;j<(frames-1);j++)
    {   if(cTime[j+1] > cTime[j])
        {    diffc[j]=cTime[j+1]-cTime[j];
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

    PERFLOG("\nDisplay frame rate: %lf \n\n",avgc);

    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("fbdev: display: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    return 0;
}

/* vim: set ts=4 sw=4 tw=80 et:*/
