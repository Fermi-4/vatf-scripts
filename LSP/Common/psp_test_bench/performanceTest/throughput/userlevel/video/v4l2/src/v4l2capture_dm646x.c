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
 *  \file   v4l2capture_dm6467.c
 *
 *  \brief  V4L2 Capture Performance Test for DM6467
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \author     Prachi Sharma
 *
 *  \note       
 *              
 *
 *  \version    0.1     Prachi          Created.
 *  \history    0.1     Prachi          Created.
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

/* DM6467 specfic Driver header files */
#include <media/davinci/adv7343.h>
#include <asm/arch/davinci_vdce.h>

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

#define CLEAR(x)        memset (&(x), 0, sizeof (x))

struct buf_info {
    int index;
    unsigned int length;
    char *start;
};

/* Capture and display buffers mmaped */
static struct buf_info capture_buff_info[MAX_BUFFER];
/* Device node that will be passed by user */
static char devicename[15];

/* Function declarations */
int v4l2capture_perf(int, const char**);
static int initCapture(int *capture_fd, int *numbuffers, char *outputname, 
        char *stdname);
static int startCapture(int *);
static int stopCapture(int *);
static int releaseCapture(int *, int *);
static int allocateBuffers(int *, int);
void   usage(void);
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
    struct v4l2_input input;
    int input_idx;
    struct v4l2_format fmt;
    struct v4l2_standard standard;
    v4l2_std_id std;

    mode = O_RDWR;
    
    /* Open the channel-0 capture device */
    *capture_fd = open((const char *)devicename, mode);
    if (capture_fd <= 0) {
        PERFLOG("Cannot open = %s device\n", devicename);
        return -1;
    }

    /* Detect input
    * VIDIOC_G_INPUT ioctl detects the inputs connected. It returns
    * error if no inputs are connected. Otherwise it returns index of 
    * the input connected. */
    ret = ioctl(*capture_fd, VIDIOC_G_INPUT, &input_idx);
    if (ret < 0) {
        perror("VIDIOC_G_INPUT\n");
        return -1;
    }

    /* Enumerate input to get the name of the input detected */
    input.index = input_idx;
    ret = ioctl(*capture_fd, VIDIOC_ENUMINPUT, &input);
    if(ret < 0) {
        perror("VIDIOC_ENUMINPUT\n");
        return -1;
    }

    /* Store the name of the output as per the input detected */
    strcpy(outputname, input.name);
        
    /* Detect the standard in the input detected */
    ret = ioctl(*capture_fd, VIDIOC_QUERYSTD, &std);
    if (ret < 0) {
        perror("VIDIOC_QUERYSTD\n");
        return -1;
    }

    
    /*Enumerate standard to get the name of the standard detected*/
    standard.index=0;
    do
    {   ret = ioctl(*capture_fd, VIDIOC_ENUMSTD, &standard);
        if(ret < 0) {
            perror("VIDIOC_ENUM_STD\n");
            return -1;
        }
        standard.index ++;
    }while(standard.id != (std));
    /* Store the name of the standard*/
    strcpy(stdname, standard.name);
    
    
           /* Buffer allocation 
        * Informing the driver that user pointer buffer exchange 
         * mechanism will be used.
        * HERE count = number of buffer to be allocated.
        * type = type of device for which buffers are to be allocated. 
        * memory = type of the buffers requested i.e. driver allocated or 
        * user pointer */
    
        reqbuf.memory = V4L2_MEMORY_USERPTR;
        reqbuf.count = *numbuffers;
        reqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        ret = ioctl(*capture_fd, VIDIOC_REQBUFS, &reqbuf);
        if (ret < 0) 
        {   perror("cannot allocate memory\n");
            return -1;
        }
        /* Store the number of buffers actually allocated */
        *numbuffers = reqbuf.count;

        /* It is better to zero all the members of buffer structure */
        memset(&buf, 0, sizeof(buf));

        /* Enqueue buffers
        * Before starting streaming, all the buffers needs to be en-queued 
        * in the driver incoming queue. These buffers will be used by the 
        * drive for storing captured frames. */
        /* Enqueue buffers */
        for (i = 0; i < reqbuf.count; i++) 
        {   buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
            buf.index = i;
            buf.memory = V4L2_MEMORY_USERPTR;
            buf.m.userptr = (unsigned long)capture_buff_info[i].start;
            ret = ioctl(*capture_fd, VIDIOC_QBUF, &buf);
            if (ret < 0) 
            {   perror("VIDIOC_QBUF\n");
                return -1;
            }
        }

        /* As the application is using user pointer buffer
         * exchange mechanism, it must tell size of the allocated
         * buffers so that driver will be able to calculate
         * the offsets correctly. */
        fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        ret = ioctl(*capture_fd, VIDIOC_G_FMT, &fmt);
        if(ret < 0) 
        {   perror("G_FMT\n");
            return -1;
        }
        fmt.fmt.pix.sizeimage = BUFFER_PITCH * BUFFER_HEIGHT * 2;
        ret = ioctl(*capture_fd, VIDIOC_S_FMT, &fmt);
        if(ret < 0) 
        {   perror("S_FMT\n");
            return -1;
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
    double sum=0,diffc[MAXLOOPCOUNT];
    int i = 0,j=0;
        int counter = 0;
        int ret = 0;
        struct v4l2_buffer buf1;
        int capture_fd, vdce_fd;
        int capture_numbuffers;
        char outputname[15];
        char stdname[15];
        int frmc=0;
        float avg=0,avgc=0.0, sumc=0.0;
        int maxbuffers,frames;
    ST_TIMER_ID currentTime;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
for(i=0;i<MAXLOOPCOUNT;i++)
{   ctime[i]=0;
    diffc[i]=0;
}
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

    for(i = 0; i < maxbuffers; i++) {
        capture_buff_info[i].start = NULL;
    }

    for(i = 0; i < MAXLOOPCOUNT; i++) {
        ctime[i] = 0;
        diffc[i]=0;
    }
    /* STEP1:
    * Buffer Allocation
    * Allocate buffers for capture devices from the VDCE 
    * device*/
    ret = allocateBuffers(&vdce_fd, maxbuffers);
    if(ret < 0)
    return -1;
    

    /* STEP2:
     * Initialization section
     * Initialize capture and display devices. 
     * Here one capture channel is opened and input and standard is 
     * detected on thatchannel.
     * */

    /* open capture channel 0 */
    ret = initCapture(&capture_fd, &capture_numbuffers, outputname, stdname);
    if(ret < 0) {
        PERFLOG("Error in opening capture device for channel 0\n");
        return ret;
    }

    /* STEP3:
     * Here capture channels are started for streaming. After 
     * this capture device will start capture frames into enqueued 
     * buffers 
     * */

    /* start capturing for channel 0 */
    ret = startCapture(&capture_fd);
    if(ret < 0) {
        PERFLOG("Error in starting capturing for channel 0\n");
        return ret;
    }
    /* It is better to zero out all the members of v4l2_buffer */
    
    memset(&buf1, 0, sizeof(buf1));

    /* One buffer is dequeued from capture channels and queued again.
    * This sequence is repeated in loop.
    * After completion of this loop, channels are stopped.
    * */
    buf1.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf1.memory = V4L2_MEMORY_USERPTR;
    PERFLOG("Running Capture:\n");

    /* Start CPU Load calcaulation */ 
    startCpuLoadMeasurement (&cpuStatusId);

    while(counter < (frames)) {
    //    if (counter > 10)
      //  {
       // }
        ret = ioctl(capture_fd, VIDIOC_DQBUF, &buf1);
        if(ret < 0) {
            perror("capture VIDIOC_DQBUF\n");
            return -1;
        }


            getTime(&currentTime);
            ctime[j++]=currentTime.tv_usec;
        //  PERFLOG("Time for capture frame %d is %ld\n",j,currentTime.tv_usec); 
        ret = ioctl(capture_fd, VIDIOC_QBUF, &buf1);
        if(ret < 0) {
            perror("capture VIDIOC_QBUF\n");
            return -1;
        }
        counter ++;
    }

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
    /* Close the vdce file handle */
    close(vdce_fd);

    /*Calculate the frame rate */
   for(j=0;j<(frames-1);j++)
    {   if(ctime[j+1] > ctime[j])
        {   diffc[j]=ctime[j+1]-ctime[j];
            sum=sum+diffc[j];
             diffc[j]= (1/(diffc[j]/1000000));
        } 
        else
        {   diffc[j] = 1000000-ctime[j]+ ctime[j+1];
            sum=sum+diffc[j];
             diffc[j]= (1/(diffc[j]/1000000));
            
    }

}    
//sum=sum/1000000;    
for(j=0; j<(frames-1); j++)
    {  // PERFLOG("\n%lf, %d",diffc[j],j);
if(diffc[j]>0)
        {   sumc=sumc+diffc[j];
            frmc++;
        }
    }
    avgc=sumc/(frmc-1);
//avg=frames/sum;
   PERFLOG("Capture frame rate: %lf %d \n",avgc,frmc);
    
    if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
        printf("v4l2: capture: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    return ret;
}

/*=============================allocateBuffers===================*/
/* This function allocates physically contiguous memory using 	 *
 * VDCE driver for capture and display devices. 		 *
 * Ideally one should use CMEM module for allocating buffers. 	 *
 * Here VDCE module is used to get physically contiguous	 * 
 * buffers. But its not necessary.				 */
static int allocateBuffers(int *vdce_fd, int numbuffers)
{
    int i;
    vdce_reqbufs_t	reqbuf;
    vdce_buffer_t buffer;

    /* Open VDCE device */
    *vdce_fd = open(VDCE_DEVICE,O_RDWR);
    if(*vdce_fd <= 0) {
        PERFLOG("cannot open %s\n",VDCE_DEVICE);
        return -1;
    }

    /*
       VDCE allocated buffers:
       Request for 3 input buffer of size 1920x1080x2of 4:2:2 format
       Here HEIGHT = Height of Y portion of the buffer.Driver 
       understands that double the size is needed for a 4:2:2 buffer.
       PITCH is NOT restriced to be 1920. It could be more if needed.
     */
    reqbuf.buf_type = VDCE_BUF_IN;
    reqbuf.num_lines = BUFFER_HEIGHT;
    reqbuf.bytes_per_line = BUFFER_PITCH;
    reqbuf.image_type = VDCE_IMAGE_FMT_422;
    reqbuf.count = numbuffers;
    if (ioctl(*vdce_fd, VDCE_REQBUF, &reqbuf) < 0) {
        perror("buffer allocation error.\n");
        close(*vdce_fd);
        exit(-1);
    }

    /* Get the physical address of the buffer and mmap them in 
     * the user space */
    buffer.buf_type = VDCE_BUF_IN;
    for(i = 0 ; i < numbuffers ; i ++) {
        buffer.index = i;
        if (ioctl(*vdce_fd, VDCE_QUERYBUF, &buffer) < 0) {
            perror("buffer query error.\n");
            /*
               closing a device takes care of freeing up
               of the buffers automatically
             */
            close(*vdce_fd);
        }
        capture_buff_info[i].start =
            mmap(NULL, buffer.size,
                    PROT_READ | PROT_WRITE, MAP_SHARED,
                    *vdce_fd, buffer.offset);
        /* mapping input buffer */
        if (capture_buff_info[i].start == MAP_FAILED) {
            perror("error in mmaping output buffer\n");
            close(*vdce_fd);
            exit(1);
        }
        capture_buff_info[i].index = i;
        capture_buff_info[i].length = buffer.size;
    }

    return 0;
}

void usage(void)
{   PERFLOG("./pspTest ThruPut FRv4l2capture {Capture device} {number of buffers} {number of frames}\n");
}

/* vim: set ts=4 sw=4 tw=80 et:*/
