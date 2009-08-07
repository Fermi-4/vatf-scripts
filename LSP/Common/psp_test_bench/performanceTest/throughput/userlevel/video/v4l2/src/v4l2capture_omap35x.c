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
 **| performance of this computer program, and specifically disclaims        |****| any responsibility for any damages, special or consequential,           |**
 **| connected with the use of this program.                                 |**
 **|                                                                         |**
 **+-------------------------------------------------------------------------+**
 ******************************************************************************/
/**
 *  \file   v4l2capture_omap35xx.c
 *
 *  \brief  V4L2 Capture Performance Test for OMAP35xx 
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \author     Prathap MS
 *
 *  \note
 *
 *
 *  \version    0.1     Prathap MS      Created.
 *  \history    0.1     Prathap MS      Created.
 */

/* Linux specifc generic header files */
#include <stdio.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/time.h>

/* V4L2 specific header files */
#include <linux/videodev.h>
#include <linux/videodev2.h>

/*  Performance Test Header Files */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>


/* structure used to store information of the buffers */
struct buf_info {
	int index;
	unsigned int length;
	char *start;
};

/* Changing the following will result in different number of buffers used */
#define MAX_BUFFER	8	
/* device to be used for capture */
#define CAPTURE_DEVICE		"/dev/video0"
#define CAPTURE_NAME		"Capture"
#define DISPLAY_SUPPORT

#ifdef DISPLAY_SUPPORT
/* device to be used for display */
#define DISPLAY_DEVICE		"/dev/video1"
#define DISPLAY_NAME		"Display"
/* absolute path of the sysfs entry for controlling output to LCD */
#define OUTPUTPATH      "/sys/class/display_control/omap_disp_control/video1"
#endif

/* number of frames to be captured and displayed */
#define MAXLOOPCOUNT		1000

#define WIDTH 720
#define HEIGHT 480
#define DEF_PIX_FMT		V4L2_PIX_FMT_UYVY

/* capture_buff_info and display_buff_info stores buffer information of capture
   and display respectively. */
static struct buf_info capture_buff_info[MAX_BUFFER];
static struct buf_info display_buff_info[MAX_BUFFER];
void   usage(void);

/*===============================initCapture==================================*/
/* This function initializes capture device. It selects an active input
 * and detects the standard on that input. It then allocates buffers in the
 * driver's memory space and mmaps them in the application space.
 */
static int initCapture(int *capture_fd, int *numbuffers, char *inputname,
		char *stdname, struct v4l2_format *fmt)
{
	int ret, i, j;
	struct v4l2_requestbuffers reqbuf;
	struct v4l2_buffer buf;
	struct v4l2_capability capability;
	struct v4l2_input input;
	v4l2_std_id std_id;
	struct v4l2_standard standard;
	int index;

	/* Open the capture device */
	*capture_fd  = open((const char *) CAPTURE_DEVICE, O_RDWR);
	if (*capture_fd  <= 0) {
		printf("Cannot open = %s device\n", CAPTURE_DEVICE);
		return -1;
	}
	printf("\n%s: Opened Channel\n", CAPTURE_NAME);

	/* Get any active input */
	if (ioctl(*capture_fd, VIDIOC_G_INPUT, &index) < 0) {
		perror("VIDIOC_G_INPUT");
		goto ERROR;
	}

	/* Enumerate input to get the name of the input detected */
	memset(&input, 0, sizeof(input));
	input.index = index;
	if (ioctl(*capture_fd, VIDIOC_ENUMINPUT, &input) < 0) {
		perror("VIDIOC_ENUMINPUT");
		goto ERROR;
	}

	printf("%s: Current Input: %s\n", CAPTURE_NAME, input.name);
	/* Store the name of the output as per the input detected */
	strcpy(inputname, input.name);

	/* Detect the standard in the input detected */
	if (ioctl(*capture_fd, VIDIOC_QUERYSTD, &std_id) < 0) {
		perror("VIDIOC_QUERYSTD");
		goto ERROR;
	}

	/* Get the standard*/
	if (ioctl(*capture_fd, VIDIOC_G_STD, &std_id) < 0) {
		/* Note when VIDIOC_ENUMSTD always returns EINVAL this
		   is no video device or it falls under the USB exception,
		   and VIDIOC_G_STD returning EINVAL is no error. */
		perror("VIDIOC_G_STD");
		goto ERROR;
	}

	memset(&standard, 0, sizeof(standard));
	standard.index = 0;
	while (1) {
		if (ioctl(*capture_fd, VIDIOC_ENUMSTD, &standard) < 0) {
			perror("VIDIOC_ENUMSTD");
			goto ERROR;
		}

		/* Store the name of the standard */
		if (standard.id & std_id) {
			strcpy(stdname, standard.name);
			printf("%s: Current standard: %s\n",
					CAPTURE_NAME, standard.name);
			break;
		}
		standard.index++;
	}

	/* Check if the device is capable of streaming */
	if (ioctl(*capture_fd, VIDIOC_QUERYCAP, &capability) < 0) {
		perror("VIDIOC_QUERYCAP");
		goto ERROR;
	}
	if (capability.capabilities & V4L2_CAP_STREAMING)
		printf("%s: Capable of streaming\n", CAPTURE_NAME);
	else {
		printf("%s: Not capable of streaming\n", CAPTURE_NAME);
		goto ERROR;
	}

	fmt->type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	ret = ioctl(*capture_fd, VIDIOC_G_FMT, fmt);
	if (ret < 0) {
		perror("VIDIOC_G_FMT");
		goto ERROR;
	}

	fmt->fmt.pix.pixelformat = DEF_PIX_FMT;
	ret = ioctl(*capture_fd, VIDIOC_S_FMT, fmt);
	if (ret < 0) {
		perror("VIDIOC_S_FMT");
		goto ERROR;
	}

	ret = ioctl(*capture_fd, VIDIOC_G_FMT, fmt);
	if (ret < 0) {
		perror("VIDIOC_G_FMT");
		goto ERROR;
	}

	if (fmt->fmt.pix.pixelformat != DEF_PIX_FMT) {
		printf("%s: Requested pixel format not supported\n",
				CAPTURE_NAME);
		goto ERROR;
	}

	/* Buffer allocation
	 * Buffer can be allocated either from capture driver or
	 * user pointer can be used
	 */
	/* Request for MAX_BUFFER input buffers. As far as Physically contiguous
	 * memory is available, driver can allocate as many buffers as
	 * possible. If memory is not available, it returns number of
	 * buffers it has allocated in count member of reqbuf.
	 * HERE count = number of buffer to be allocated.
	 * type = type of device for which buffers are to be allocated.
	 * memory = type of the buffers requested i.e. driver allocated or
	 * user pointer */
	reqbuf.count = *numbuffers;
	reqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	reqbuf.memory = V4L2_MEMORY_MMAP;
	ret = ioctl(*capture_fd, VIDIOC_REQBUFS, &reqbuf);
	if (ret < 0) {
		perror("Cannot allocate memory");
		goto ERROR;
	}
	/* Store the number of buffers actually allocated */
	*numbuffers = reqbuf.count;
	printf("%s: Number of requested buffers = %d\n", CAPTURE_NAME,
			*numbuffers);

	memset(&buf, 0, sizeof(buf));

	/* Mmap the buffers
	 * To access driver allocated buffer in application space, they have
	 * to be mmapped in the application space using mmap system call */
	for (i = 0; i < (*numbuffers); i++) {
		buf.type = reqbuf.type;
		buf.index = i;
		buf.memory = reqbuf.memory;
		ret = ioctl(*capture_fd, VIDIOC_QUERYBUF, &buf);
		if (ret < 0) {
			perror("VIDIOC_QUERYCAP");
			*numbuffers = i;
			goto ERROR1;
		}


		capture_buff_info[i].length = buf.length;
		capture_buff_info[i].index = i;
		capture_buff_info[i].start = mmap(NULL, buf.length,
				PROT_READ |
				PROT_WRITE,
				MAP_SHARED,
				*capture_fd,
				buf.m.offset);

		if (capture_buff_info[i].start == MAP_FAILED) {
			printf("Cannot mmap = %d buffer\n", i);
			*numbuffers = i;
			goto ERROR1;
		}

		memset((void *) capture_buff_info[i].start, 0x80,
				capture_buff_info[i].length);
		/* Enqueue buffers
		 * Before starting streaming, all the buffers needs to be
		 * en-queued in the driver incoming queue. These buffers will
		 * be used by thedrive for storing captured frames. */
		ret = ioctl(*capture_fd, VIDIOC_QBUF, &buf);
		if (ret < 0) {
			perror("VIDIOC_QBUF");
			*numbuffers = i + 1;
			goto ERROR1;
		}
	}

	printf("%s: Init done successfully\n\n", CAPTURE_NAME);
	return 0;

ERROR1:
	for (j = 0; j < *numbuffers; j++)
		munmap(capture_buff_info[j].start,
				capture_buff_info[j].length);
ERROR:
	close(*capture_fd);

	return -1;
}

#ifdef DISPLAY_SUPPORT
/*===============================initDisplay==================================*/
/* This function initializes display device. It sets output and standard for
 * LCD. These output and standard are same as those detected in capture device.
 * It, then, allocates buffers in the driver's memory space and mmaps them in
 * the application space */
static int initDisplay(int *display_fd, int *numbuffers, char *stdname,
		struct v4l2_format *fmt)
{
	int ret, i, j;
	struct v4l2_requestbuffers reqbuf;
	struct v4l2_buffer buf;
	struct v4l2_capability capability;
	int rotation;
	char str[200];

	/* Set the output of video pipeline to LCD */
/*	strcpy(str, "echo lcd > ");
	strcat(str, OUTPUTPATH);
	if (system(str)) {
		printf("Cannot set output to LCD\n");
		exit(0);
	} */
	/* Open the video display device */
	*display_fd = open((const char *) DISPLAY_DEVICE, O_RDWR);
	if (*display_fd <= 0) {
		printf("Cannot open = %s device\n", DISPLAY_DEVICE);
		return -1;
	}
	printf("\n%s: Opened Channel\n", DISPLAY_NAME);

	/* Check if the device is capable of streaming */
	if (ioctl(*display_fd, VIDIOC_QUERYCAP, &capability) < 0) {
		perror("VIDIOC_QUERYCAP");
		goto ERROR;
	}

	if (capability.capabilities & V4L2_CAP_STREAMING)
		printf("%s: Capable of streaming\n", DISPLAY_NAME);
	else {
		printf("%s: Not capable of streaming\n", DISPLAY_NAME);
		goto ERROR;
	}

	/* Get the format */
	fmt->type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(*display_fd, VIDIOC_G_FMT, fmt);
	if (ret < 0) {
		perror("VIDIOC_G_FMT");
		goto ERROR;
	}

	fmt->fmt.pix.width = WIDTH;
	fmt->fmt.pix.height = HEIGHT;
	fmt->fmt.pix.pixelformat = DEF_PIX_FMT;
	ret = ioctl(*display_fd, VIDIOC_S_FMT, fmt);
	if (ret < 0) {
		perror("VIDIOC_S_FMT");
		goto ERROR;
	}

	ret = ioctl(*display_fd, VIDIOC_G_FMT, fmt);
	if (ret < 0) {
		perror("VIDIOC_G_FMT");
		goto ERROR;
	}

	if (fmt->fmt.pix.pixelformat != DEF_PIX_FMT) {
		printf("%s: Requested pixel format not supported\n",
				CAPTURE_NAME);
		goto ERROR;
	}

	/* Buffer allocation
	 * Buffer can be allocated either from capture driver or
	 * user pointer can be used
	 */
	/* Request for MAX_BUFFER input buffers. As far as Physically contiguous
	 * memory is available, driver can allocate as many buffers as
	 * possible. If memory is not available, it returns number of
	 * buffers it has allocated in count member of reqbuf.
	 * HERE count = number of buffer to be allocated.
	 * type = type of device for which buffers are to be allocated.
	 * memory = type of the buffers requested i.e. driver allocated or
	 * user pointer */
	reqbuf.count = *numbuffers;
	reqbuf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	reqbuf.memory = V4L2_MEMORY_MMAP;
	ret = ioctl(*display_fd, VIDIOC_REQBUFS, &reqbuf);
	if (ret < 0) {
		perror("Cannot allocate memory");
		goto ERROR;
	}
	/* Store the numbfer of buffers allocated */
	*numbuffers = reqbuf.count;

	memset(&buf, 0, sizeof(buf));

	/* Mmap the buffers
	 * To access driver allocated buffer in application space, they have
	 * to be mmapped in the application space using mmap system call */
	for (i = 0; i < (*numbuffers); i++) {
		/* Query physical address of the buffers */
		buf.type = reqbuf.type;
		buf.index = i;
		buf.memory = reqbuf.memory;
		ret = ioctl(*display_fd, VIDIOC_QUERYBUF, &buf);
		if (ret < 0) {
			perror("VIDIOC_QUERYCAP");
			(*numbuffers) = i;
			goto ERROR1;
		}

		/* Mmap the buffers in application space */
		display_buff_info[i].length = buf.length;
		display_buff_info[i].index =  i;
		display_buff_info[i].start = mmap(NULL, buf.length,
				PROT_READ |
				PROT_WRITE,
				MAP_SHARED,
				*display_fd,
				buf.m.offset);

		if (display_buff_info[i].start == MAP_FAILED) {
			printf("Cannot mmap = %d buffer\n", i);
			(*numbuffers) = i;
			goto ERROR1;
		}
		memset((void *) display_buff_info[i].start, 0x80,
				display_buff_info[i].length);

		/* Enqueue buffers
		 * Before starting streaming, all the buffers needs to be
		 * en-queued in the driver incoming queue. These buffers will
		 * be used by thedrive for storing captured frames. */
		ret = ioctl(*display_fd, VIDIOC_QBUF, &buf);
		if (ret < 0) {
			perror("VIDIOC_QBUF");
			(*numbuffers) = i + 1;
			goto ERROR1;
		}
	}
	printf("%s: Init done successfully\n\n", DISPLAY_NAME);
	return 0;

ERROR1:
	for (j = 0; j < *numbuffers; j++)
		munmap(display_buff_info[j].start,
				display_buff_info[j].length);
ERROR:
	close(*display_fd);

	return -1;
}
#endif

int v4l2capture_perf(int numargs, char *argv[])
{
	long ctime[MAXLOOPCOUNT];
	double diffc[MAXLOOPCOUNT];
        float avgc=0.0, sumc=0.0;
	int i = 0,j = 0;
	int ret = 0, frmc=0;
	struct v4l2_format capture_fmt;
	struct v4l2_format display_fmt;
	int capture_fd, display_fd;
	char inputname[15];
	char stdname[15];
        char devicename[15];
	int capture_numbuffers = MAX_BUFFER, display_numbuffers = MAX_BUFFER;
	int a,maxbuffers,frames;
	struct v4l2_buffer display_buf, capture_buf;
	ST_TIMER_ID currentTime;
	ST_CPU_STATUS_ID cpuStatusId;
	float percentageCpuLoad = 0;

	if(numargs == 0 || numargs < 3)
	{   usage();
		return -1;
	}

	/* get the device name*/
	getNextTokenString(&numargs, argv, devicename);
	/* get the no. of buffers*/
	getNextTokenInt(&numargs, argv, &maxbuffers);
	if(maxbuffers < 2 || maxbuffers > 8)
	{   PERFLOG("Invalid buffer number.\nPlease give buffer number as anything between 2 & 8 (inclusive).\n");
		usage();
		return -1;
	}
	/* get the no. of frames */
	getNextTokenInt(&numargs, argv, &frames);
	if(frames > MAXLOOPCOUNT)
	{   PERFLOG("Invalid number of frames.\nPlease give number of frames to be less than 10000.\n");
		usage();
		return -1;
	}

	capture_numbuffers=maxbuffers;
	for(i = 0; i < maxbuffers ; i++) {
		capture_buff_info[i].start = NULL;
		display_buff_info[i].start = NULL;
	}

	for(i = 0; i < MAXLOOPCOUNT; i++) {
		ctime[i] = 0;
		diffc[i]=0;
	}

	/* STEP1:
	 * Initialization section
	 * Initialize capture and display devices.
	 * Here one capture channel is opened and input and standard is
	 * detected on that channel.
	 * Display channel is opened with the same standard that is detected at
	 * capture channel.
	 * */
	ret = initCapture(&capture_fd, &capture_numbuffers, inputname,
			stdname, &capture_fmt);
	if(ret < 0) {
		printf("Error in opening capture device for channel 0\n");
		return ret;
	}
#ifdef DISPLAY_SUPPORT
       // display_numbuffers=maxbuffers;
	/* open display channel */
	ret = initDisplay(&display_fd, &display_numbuffers,
			stdname, &display_fmt);
	if(ret < 0) {
		printf("Error in opening display device\n");
		goto ERROR_1;
	}
#endif
	/* run section
	 * STEP2:
	 * Here display and capture channels are started for streaming. After
	 * this capture device will start capture frames into enqueued
	 * buffers and display device will start displaying buffers from
	 * the qneueued buffers */

	/* Start Streaming. on display device */
	a = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(display_fd, VIDIOC_STREAMON, &a);
	if (ret < 0) {
		perror("VIDIOC_STREAMON");
		goto ERROR;
	}
	printf("%s: Stream on...\n", DISPLAY_NAME);

	/* Start Streaming. on capture device */
	a = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	ret = ioctl(capture_fd, VIDIOC_STREAMON, &a);
	if (ret < 0) {
		perror("VIDIOC_STREAMON");
		goto ERROR;
	}
	printf("%s: Stream on...\n", CAPTURE_NAME);
#ifdef DISPLAY_SUPPORT
	/* Set the display buffers for queuing and dqueueing operation */
	display_buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	display_buf.index = 0;
	display_buf.memory = V4L2_MEMORY_MMAP;
#endif
	/* Set the capture buffers for queuing and dqueueing operation */
	capture_buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	capture_buf.index = 0;
	capture_buf.memory = V4L2_MEMORY_MMAP;

	/* One buffer is dequeued from display and capture channels.
	 * Capture buffer will be copied to display buffer.
	 * All two buffers are put back to respective channels.
	 * This sequence is repeated in loop.
	 * After completion of this loop, channels are stopped.
	 */
	startCpuLoadMeasurement (&cpuStatusId);
	for (i = 0; i < frames; i++) {
		int h;
		char *cap_ptr, *dis_ptr;
#ifdef DISPLAY_SUPPORT
		/* Dequeue display buffer */
		ret = ioctl(display_fd, VIDIOC_DQBUF, &display_buf);
		if (ret < 0) {
			perror("VIDIOC_DQBUF");
			goto ERROR;
		}
#endif
		/* Dequeue capture buffer */
		ret = ioctl(capture_fd, VIDIOC_DQBUF, &capture_buf);
		if (ret < 0) {
			perror("VIDIOC_DQBUF");
			goto ERROR;
		}
		getTime(&currentTime);
		ctime[j++]=currentTime.tv_usec;
		cap_ptr = capture_buff_info[capture_buf.index].start;
		dis_ptr = display_buff_info[display_buf.index].start;
		for (h = 0; h < display_fmt.fmt.pix.height; h++) {
			memcpy(dis_ptr, cap_ptr, display_fmt.fmt.pix.width * 2);
			cap_ptr += capture_fmt.fmt.pix.width * 2;
			dis_ptr += display_fmt.fmt.pix.width * 2;
		}

		ret = ioctl(capture_fd, VIDIOC_QBUF, &capture_buf);
		if (ret < 0) {
			perror("VIDIOC_QBUF");
			goto ERROR;
		}

#ifdef DISPLAY_SUPPORT
		ret = ioctl(display_fd, VIDIOC_QBUF, &display_buf);
		if (ret < 0) {
			perror("VIDIOC_QBUF");
			goto ERROR;
		}
	}
#endif
	percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

#ifdef DISPLAY_SUPPORT
	a = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(display_fd, VIDIOC_STREAMOFF, &a);
	if (ret < 0) {
		perror("VIDIOC_STREAMOFF");
		goto ERROR;
	}
	printf("\n%s: Stream off!!\n", DISPLAY_NAME);

#endif
	a = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	ret = ioctl(capture_fd, VIDIOC_STREAMOFF, &a);
	if (ret < 0) {
		perror("VIDIOC_STREAMOFF");
		goto ERROR;
	}
	printf("%s: Stream off!!\n", CAPTURE_NAME);

#ifdef DISPLAY_SUPPORT
ERROR:
	/* Un-map the buffers */
	for (i = 0; i < display_numbuffers; i++) {
		munmap(display_buff_info[i].start,
				display_buff_info[i].length);
		display_buff_info[i].start = NULL;
	}
	/* Close the file handle */
	close(display_fd);
#endif
ERROR_1:
	/* Un-map the buffers */
	for (i = 0; i < capture_numbuffers; i++) {
		munmap(capture_buff_info[i].start,
				capture_buff_info[i].length);
		capture_buff_info[i].start = NULL;
	}
	/* Close the file handle */
	close(capture_fd);
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
	{   if(diffc[j]>0)
		{   sumc=sumc+diffc[j];
			frmc++;
		}
	}
	avgc=sumc/(frmc-1);

	PERFLOG("Capture frame rate: %lf \n",avgc);
	if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
		printf("v4l2: capture: percentage cpu load: %.2f%%\n", percentageCpuLoad);

	return 0;
}

void usage(void)
{   PERFLOG("./pspTest ThruPut FRv4l2capture {Capture device} {number of buffers} {number of frames}\n");
}

