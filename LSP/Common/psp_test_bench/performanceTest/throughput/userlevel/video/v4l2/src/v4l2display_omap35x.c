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
**|         Copyright (c) 1998-2004 Texas Instruments Incorporated           |**
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
/* saUserptrDisplay.c
 *
 * 
 * This is a V4L2 sample application to show the display functionality
 * The app puts a moving horizontal bar on the display device in various 
 * shades of colors. It uses user pointer buffer exchange mechanism. It 
 * takes buffers from FBDEV drive and provides virtual address of the 
 * buffers to the V4L2. This appplication runs in RGB565 mode with VGA
 * display resolution. 
 */
 /******************************************************************************
  Header File Inclusion
 ******************************************************************************/
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <errno.h>
#include <string.h>
#include <linux/videodev.h>
#include <linux/videodev2.h>
#include <linux/fb.h>
/*Performance Test Header Files */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>
/******************************************************************************
 Macros
 MAX_BUFFER     : Changing the following will result different number of 
		  instances of buf_info structure.
 MAXLOOPCOUNT	: Display loop count
 WIDTH		: Width of the output image
 HEIGHT		: Height of the output image
 ******************************************************************************/
#define MAX_BUFFER	9
#define MAXLOOPCOUNT    10000
#define WIDTH		480
#define HEIGHT		640

static int display_fd = 0;
static int fbdev_fd = 0;

static char out_devicename[20];
static char fbdev_driver_name[20] = {"/dev/fb0"};
/* absolute path of the sysfs entry for controlling video1 to channel0 */
#define OUTPUTPATH      "/sys/class/display_control/omap_disp_control/video1"
/* absolute path of the sysfs entry for controlling channel0 to DVI */
#define OUTPUTPATH_1      "/sys/class/display_control/omap_disp_control/ch0_output"

struct buf_info {
	int index;
	unsigned int length;
	char *start;
};

static struct buf_info display_buff_info[MAX_BUFFER];
static int numbuffers = MAX_BUFFER;
int maxbuffers;

/******************************************************************************
                        Function Definitions
 ******************************************************************************/
static int releaseDisplay(int ret_flag);
static int startDisplay();
static int stopDisplay();
void color_bar(unsigned char *addr, int w, int h, int order);
int v4l2display_perf(int,const char **);
void v4l2displayusage();

/*
        This routine unmaps all the buffers
        This is the final step.
*/
static int releaseDisplay(int ret_flag)
{
	int i;
	if(ret_flag > -6) {
		for (i = 0; i < maxbuffers; i++) {
			munmap(display_buff_info[i].start,
					display_buff_info[i].length);
			display_buff_info[i].start = NULL;
		}
	}
	close(display_fd);
	close(fbdev_fd);
	display_fd = 0;
	fbdev_fd = 0;
	return 0;
}
/*
	Starts Streaming
*/
static int startDisplay()
{
	int a = V4L2_BUF_TYPE_VIDEO_OUTPUT, ret, i;
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

static unsigned short ycbcr[8] = {
	(0x1F << 11) | (0x3F << 5) | (0x1F),
	(0x00 << 11) | (0x00 << 5) | (0x00),
	(0x1F << 11) | (0x00 << 5) | (0x00),
	(0x00 << 11) | (0x3F << 5) | (0x00),
	(0x00 << 11) | (0x00 << 5) | (0x1F),
	(0x1F << 11) | (0x3F << 5) | (0x00),
	(0x1F << 11) | (0x00 << 5) | (0x1F),
	(0x00 << 11) | (0x3F << 5) | (0x1F),
};

void color_bar(unsigned char *addr, int width, int height, int order)
{
	unsigned short *ptr = (unsigned short *)addr + order*width;
	int i, j, k;

	for(i = 0 ; i < 8 ; i ++) {
		for(j = 0 ; j < height / 8 ; j ++) {
			for(k = 0 ; k < width / 2 ; k ++, ptr++) {
				if((unsigned int)ptr >= (unsigned int)addr +
								width*height)
					ptr = (unsigned short *)addr;
				*ptr = ycbcr[i];
			}
		}
	}
}

int v4l2display_perf(int numargs, const char **argv)
{
	int mode = O_RDWR;
	struct v4l2_requestbuffers reqbuf;
	v4l2_std_id stdid;
	struct v4l2_buffer buf;
	struct v4l2_format fmt;
	int i = 0, j = 0, l=0,kount=0;
	void *displaybuffer;
	int counter = 0;
	int ret = 0;
	struct v4l2_output output;
	int dispheight, dispwidth, sizeimage;
	int color = 0;
	unsigned long buffer_addr[MAX_BUFFER];
	struct fb_fix_screeninfo fixinfo;
	struct fb_var_screeninfo varinfo;
	int buffersize;
	char str[80];
	ST_TIMER_ID currentTime;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
char outputname[15];
        int frames;
        long dtime[MAXLOOPCOUNT];
        double diffd[MAXLOOPCOUNT];
        int frmd=0 ;
        float avgd=0.0, sumd=0.0;

	if(numargs == 0 || numargs < 4)
        {   v4l2displayusage();
                return -1;
        }

        /* get the output device name*/
        getNextTokenString(&numargs, argv, out_devicename);

        /* get the no. of buffers*/
        getNextTokenInt(&numargs, argv, &maxbuffers);
    /*  if(maxbuffers < 3 || maxbuffers > 5)
        {   PERFLOG("Invalid buffer number.\nPlease give buffer number as anything between 3 & 5 (inclusive).\n");
        v4l2displayusage();
        return -1;
        }*/

        /* get the no. of frames */
        getNextTokenInt(&numargs, argv, &frames);
        if(frames > MAXLOOPCOUNT)
	{   PERFLOG("Invalid number of frames.\nPlease give number of frames to be less than 10000.\n");
                v4l2displayusage();
                return -1;
        }

	 /* get the output interface name*/
        getNextTokenString(&numargs, argv, outputname);
        if(strcmp(outputname, "LCD") ==0)
        { /*do nothing */ }
        else if(strcmp(outputname, "DVI") ==0)
        { /*do nothing */ }
        else if(strcmp(outputname, "SVIDEO") ==0)
        { /*do nothing */ }
        else
        {   PERFLOG("Invalid output name.\nPlease give it as 'LCD' or 'DVI' or 'SVIDEO'.\n");
                v4l2displayusage();
                return -1;
        }

	/* Set the video1 pipeline to channel0 overlay */
        if(strcmp(outputname, "SVIDEO") ==0)
        	strcpy(str, "echo channel1 > ");
	else
        	strcpy(str, "echo channel0 > ");
	strcat(str, OUTPUTPATH);
	if (system(str)) {
		printf("Cannot set video1 pipeline to channel 0\n");
		exit(0);
	}
	/* Set the output of channel0 to DVI */
	strcpy(str, "echo ");
	strcpy(str, outputname);
	strcpy(str, " > ");
	strcat(str, OUTPUTPATH_1);
	if (system(str)) {
		printf("Cannot set output\n");
		exit(0);
	}

	/* open display channel */
	display_fd = open((const char *)out_devicename, mode);
	if(display_fd == -1) {
		printf("Failed to open display device\n");
		return 0;
	}

	fbdev_fd = open((const char *)fbdev_driver_name, O_RDWR);
	if(fbdev_fd <= 0) {
		perror("Cound not open device\n");
		close(display_fd);
		return 0;
	}

	/* Set the image size to 640x480 and pixel format to RGB565 */
	fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	fmt.fmt.pix.width = WIDTH;
	fmt.fmt.pix.height = HEIGHT;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB565;
	ret = ioctl(display_fd, VIDIOC_S_FMT, &fmt);
	if(ret < 0) {
		perror("Set Format failed\n");
		return -1;
	}

	/* It is necessary for applications to know about the 
	 * buffer chacteristics that are set by the driver for 
	 * proper handling of buffers 
	 * These are : width,height,pitch and image size */
	fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(display_fd, VIDIOC_G_FMT, &fmt);
	if(ret < 0) {
		perror("Get Format failed\n");
		return -2;
	}
	dispheight = fmt.fmt.pix.height;
	dispwidth = fmt.fmt.pix.bytesperline;
	sizeimage = fmt.fmt.pix.sizeimage;

	/* Now for the buffers.Request the number of buffers needed and 
	 * the kind of buffers(User buffers or kernel buffers for memory 
	 * mapping). Please note that the return value in the reqbuf.count
	 * might be lesser than maxbuffers under some low memory 
	 * circumstances */
	reqbuf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	reqbuf.count = maxbuffers;
	reqbuf.memory = V4L2_MEMORY_USERPTR;

	ret = ioctl(display_fd, VIDIOC_REQBUFS, &reqbuf);
	if (ret < 0) {
		perror("Could not allocate the buffers\n");
		return -3;
	}

	/* Now allocate physically contiguous buffers. Application uses 
	 * FBDEV driver to get the physically contiguous buffer. Any other 
	 * mechanism can be used to get the buffer and provide user 
	 * space virtual address to the V4L2 drier. 
	 * Using physical contiguous buffer from FBDEV driver is not 
	 * standard/recomded method. Application should use cmem or any 
	 * other method to have physically contiguous buffer. We are FBDEV 
	 * due to lack of having any other method for physically contiguous 
	 * buffer. Make sure that size of the buffer in FBDEV is enough to 
	 * store the complete frame of 640*480*2 size */

	/* Get fix screen information. Fix screen information gives
	 * fix information like panning step for horizontal and vertical
	 * direction, line length, memory mapped start address and length etc.
	 * Here fix screen info is used to get line length/pitch.
	 */
	ret = ioctl(fbdev_fd, FBIOGET_FSCREENINFO, &fixinfo);
	if (ret < 0) {
		perror("Error reading fixed information.\n");
		return -4;
	}

	/* Get variable screen information. Variable screen information
	 * gives informtion like size of the image, bites per pixel,
	 * virtual size of the image etc. Here variable screen info is 
	 * used to get the screen resolution */
	ret = ioctl(fbdev_fd, FBIOGET_VSCREENINFO, &varinfo);
	if (ret < 0) {
		perror("Error reading variable information.\n");
		return -5;
	}

	/* Mmap the driver buffers in application space so that application
	 * can write on to them. Driver allocates contiguous memory for
	 * three buffers. These buffers can be displayed one by one. */
	buffersize = fixinfo.line_length * varinfo.yres;
	printf("Buffer size = %d, X - %d, Y - %d\n",fixinfo.line_length * 
		varinfo.yres * MAX_BUFFER, fixinfo.line_length, varinfo.yres);

	buffer_addr[0] = (unsigned long)mmap ((void*)0, buffersize*MAX_BUFFER, 
			(PROT_READ|PROT_WRITE), MAP_SHARED, fbdev_fd, 0) ;
	if (buffer_addr[0] == (unsigned long)MAP_FAILED) {
		printf("MMap failed for %d x %d  of %d\n", fixinfo.line_length,
				varinfo.yres*MAX_BUFFER, fixinfo.smem_len);
		return -6;
	}
	//memset((void*)buffer_addr[0], 0, buffersize*MAX_BUFFER);

	/* Store each buffer addresses in the local variable */
	for(i = 1 ; i < MAX_BUFFER ; i++) {
		buffer_addr[i] = buffer_addr[i-1] + buffersize;
	}
	/* enqueue all the buffers in the driver's incoming queue. Driver 
	 * will take buffers one by one from this incoming queue. 
	 * buffer length is must parameter for user pointer buffer exchange 
	 * mechanism. Using this parameters, driver validates user buffer 
	 * size with the size required to store image of given resolution. */
	memset(&buf,  0, sizeof(buf));
	for(i = 0 ; i < reqbuf.count ; i ++) {
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.memory = V4L2_MEMORY_USERPTR;
		buf.index = i;
		buf.m.userptr = buffer_addr[i];
		buf.length = buffersize;
		ret = ioctl(display_fd, VIDIOC_QBUF, &buf);
		if (ret < 0) {
			perror("VIDIOC_QBUF\n");
			return -7;
		}
	}

	/* Start Displaying */
	ret = startDisplay();
	if(ret < 0) {
		perror("Error in starting display\n");
		return -8;
	}

	/*
	   This is a running loop where the buffer is 
	   DEQUEUED  <-----|
	   PROCESSED	|
	   & QUEUED -------|
	 */

	/* Start CPU Load calcaulation */
    startCpuLoadMeasurement (&cpuStatusId);

	counter = 0;
	while(counter < frames) {
		/* Get display buffer using DQBUF ioctl */
		ret = ioctl(display_fd, VIDIOC_DQBUF, &buf);
		if (ret < 0) {
			perror("VIDIOC_DQBUF\n");
			return -9;
		}
		displaybuffer = (void*)buffer_addr[buf.index];
	getTime(&currentTime);
                dtime[j++]= currentTime.tv_usec;	
		/* Process it
		   In this example, the "processing" is putting a horizontally 
		   moving color bars with changing starting line of display.
		 */
		//color_bar(displaybuffer, dispwidth, dispheight, counter%(dispheight/2));
		/* Now queue it back to display it */
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.memory = V4L2_MEMORY_USERPTR;
		buf.m.userptr = buffer_addr[buf.index];
		buf.length = buffersize;
		ret = ioctl(display_fd, VIDIOC_QBUF, &buf);
		if (ret < 0) {
			perror("VIDIOC_QBUF\n");
			return -10;
		}

		counter++;
	}
	/* Get CPU Load figures */
    percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

	/* Once the streaming is done  stop the display hardware */
	ret = stopDisplay();
	if(ret < 0) {
		perror("Error in stopping display\n");
		return -11;
	}
	 /*Calculate the frame rate */
        for(j=0;j<(frames-1);j++)
        {       if(dtime[j+1] > dtime[j])
                {       diffd[j]=dtime[j+1]-dtime[j];
                        diffd[j]= (1/(diffd[j]/1000000));
                }
                else
                {	diffd[j] = (1000000 - dtime[j]) + dtime[j+1];
                        diffd[j]= (1/(diffd[j]/1000000));
		}
        }

        for(j=0; j<(frames-1); j++)
        {
                if(diffd[j]>0)
                {   sumd=sumd+diffd[j];
                        frmd++;
                }
        }

    avgd=sumd/(frmd-1);

        PERFLOG("Display frame rate: %lf \n",avgd);
	if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("v4l2: display: percentage cpu load: %.2f%%\n", percentageCpuLoad);
	return 0;
}


void v4l2displayusage(void)
{
        PERFLOG("./pspTest ThruPut FRv4l2display {Display device} {number of buffers} {number of frames} {LCD/DVI/SVIDEO}\n");
}


