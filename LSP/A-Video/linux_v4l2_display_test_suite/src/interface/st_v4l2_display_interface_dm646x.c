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
 **|         Copyright (c) 2007-2008 Texas Instruments Incorporated           |**
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
/*	File Name :   st_v4l2_display_interface.c

    This file calls V4L2_DISPLAY driver functions and takes parameters given from testcase functions. 

    (C) Copyright 2008, Texas Instruments, Inc

    @author     Prathap M.S 
    @version    0.1 - Created             
 */


/* generic headers */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* V4L2_DISPLAY structs, enums, macros defined */
#include "st_v4l2_display_interface.h"

/* Macros */

/* Channel 0 output path & mode */
#define CH0_OUTPUTPATH  "/sys/class/davinci_display/ch0/output"
#define CH0_MODE        "/sys/class/davinci_display/ch0/mode"

/* Device nodes supported */
#define VID2_NODE "/dev/video2"

/* Device parameters */
#define V4L2_DEV1       "/dev/video3"
#define V4L2_DEV2       "/dev/video2"

#define V4L2_DISPLAY_DEV1 3
#define V4L2_DISPLAY_DEV2 2


/* Default settings/values for display */
#define DEFAULT_HEIGHT NTSC_HEIGHT

#define DEFAULT_WIDTH  NTSC_WIDTH

#define DEFAULT_NODE VID2_NODE

#define DEFAULT_PIX_FMT  V4L2_PIX_FMT_YUV422UVP

#define DEFAULT_ROTATION 0

#define DEFAULT_CROP_FACTOR 0

#define DEFAULT_ZOOM_FACTOR 0

#define DEFAULT_NO_BUFFERS 3

#define DEFAULT_NO_FRAMES 1000

/* Height and width of standards */
#define NTSC_HEIGHT         480 
#define NTSC_WIDTH          720

#define PAL_HEIGHT          576
#define PAL_WIDTH           720 

#define HD_HEIGHT           1080
#define HD_WIDTH            1920

#define HDP_HEIGHT          720
#define HDP_WIDTH           1280 

/* Global Variables */

/* v4l2_display window file descriptors */
static int fd_dev1 = 0;
static int fd_dev2 = 0;

/* Display width, height,buffer size and pitch */
int dispwidth;
int dispheight;
int sizeimage;
int disppitch;

/* Structures used in request buffer and query buffer ioctl calls */
struct v4l2_buffer buf;
struct v4l2_requestbuffers reqbuf;
struct buf_info {
    int index;
    unsigned int length;
    char *start;
};

/* Buffers for display */
static struct buf_info display_buff_info[MAX_BUFFERS];
/* Structure for set format ioctl- carries info on width,height,pixel format */
struct v4l2_format format;
/* Structure carrying test case options */
struct v4l2_display_testparams testoptions;
/* Standard name */
extern char *standard;
/* Interface name */
extern char *interface;

/***********Function Definitions****************************************/

/****************************************************************************
 * Function             - init_test_params
 * Functionality        - This function initilaizes the default values for
 * various test case options(which will be exposed as command line arguments)
 * Input Params         -  None
 * Return Value         -  None
 * Note                 -  None
 ****************************************************************************/
void init_v4l2_display_test_params()
{
    testoptions.devnode = DEFAULT_NODE;
    testoptions.height = DEFAULT_HEIGHT;
    testoptions.width = DEFAULT_WIDTH;
    testoptions.rotation = DEFAULT_ROTATION;
    testoptions.noofbuffers = DEFAULT_NO_BUFFERS;
    testoptions.noofframes = DEFAULT_NO_FRAMES;
    testoptions.pixfmt = DEFAULT_PIX_FMT;
    testoptions.openmode = DEFAULT_OPEN_MODE; 
    testoptions.cropfactor = DEFAULT_CROP_FACTOR;
    testoptions.zoomfactor = DEFAULT_ZOOM_FACTOR;
}

/****************************************************************************
 * Function             - st_v4l2_display_open_interface
 * Functionality        - This function opens V4L2_DISPLAY window
 * Input Params         - V4L2_DISPLAY device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_open_interface(int dev)
{
    int retVal = SUCCESS;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        fd_dev1 = open (V4L2_DEV1 , O_RDWR);
        retVal =  fd_dev1;
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        fd_dev2 = open (V4L2_DEV2, O_RDWR);
        retVal  =  fd_dev2;
    }

    if (0 >= retVal)
        return FAILURE;

    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_open_nonblock_interface
 * Functionality        - This function opens V4L2_DISPLAY window in non
 *                        blocking mode
 * Input Params         - V4L2_DISPLAY device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_open_nonblock_interface(int dev)
{
    int retVal = SUCCESS;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        fd_dev1 = open (V4L2_DEV1 , O_RDWR | O_NONBLOCK);
        retVal =  fd_dev1;
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        fd_dev2 = open (V4L2_DEV2, O_RDWR | O_NONBLOCK);
        retVal  =  fd_dev2;
    }

    if (0 >= retVal)
        return FAILURE;

    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_close_v4l2_display_inteface
 * Functionality        - This function closes V4L2_DISPLAY window
 * Input Params         - V4L2_DISPLAY device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_close_interface(int dev)
{
    int retVal = SUCCESS;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = close (fd_dev1);
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = close (fd_dev2);
    }
    if (SUCCESS != retVal)
    {
        return FAILURE;
    }

    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_setimg_interface
 * Functionality        - This function sets V4L2_DISPLAY width,height & pixel
 * format
 * Input Params         - V4L2_DISPLAY, device number,width,height & pix fmt
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_setimg_interface(int dev, struct st_v4l2_format* st_fmt)
{
    int retVal = SUCCESS;

    format.fmt.pix.pixelformat=st_fmt->pixelformat;
    format.fmt.pix.width = st_fmt->width;
    format.fmt.pix.height = st_fmt->height;
    format.type = st_fmt->type;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = ioctl(fd_dev1, VIDIOC_S_FMT, &format);
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = ioctl(fd_dev2, VIDIOC_S_FMT, &format);
    }

    if (SUCCESS != retVal)
    {
        return FAILURE;
    }

    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_tryimg_interface
 * Functionality        - This function tries the setting for V4L2_DISPLAY width,height & pixel
 *                        format
 * Input Params         - V4L2_DISPLAY, device number,width,height & pix fmt
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_tryimg_interface(int dev, struct st_v4l2_format* st_fmt)
{
    int retVal = SUCCESS;

    format.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;;
    format.fmt.pix.pixelformat = V4L2_PIX_FMT_YUV422UVP;
    format.fmt.pix.bytesperline = st_fmt->width;
    format.fmt.pix.field = V4L2_FIELD_INTERLACED;;
    format.fmt.pix.width = st_fmt->width;
    format.fmt.pix.height = st_fmt->height;
    format.fmt.pix.field = V4L2_FIELD_INTERLACED;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = ioctl(fd_dev1, VIDIOC_TRY_FMT, &format);
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = ioctl(fd_dev2, VIDIOC_TRY_FMT, &format);
    }

    if (SUCCESS != retVal)
    {
        return FAILURE;
    }

    return SUCCESS;
}


/****************************************************************************
 * Function             - st_v4l2_display_getimg_interface
 * Functionality        - This function gets V4L2_DISPLAY width,height & pixel
 * format
 * Input Params         - V4L2_DISPLAY device number, format type 
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_getimg_interface(int dev, struct st_v4l2_format* st_fmt)
{
    int retVal = SUCCESS;

    format.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = ioctl(fd_dev1, VIDIOC_G_FMT, &format);
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = ioctl(fd_dev2, VIDIOC_G_FMT, &format);
    }

    if (SUCCESS != retVal)
    {
        return FAILURE;
    }
    st_fmt->width = format.fmt.pix.bytesperline;
    st_fmt->height = format.fmt.pix.height;
    dispheight = format.fmt.pix.height;
    dispwidth = format.fmt.pix.width;
    disppitch = format.fmt.pix.bytesperline;
    sizeimage = format.fmt.pix.sizeimage; 

    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_request_buffer_interface
 * Functionality        - This function implements the REQBUF ioctl
 * Input Params         - device number,no of display_buff_info
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_request_buffer_interface(int dev, int count)
{

    int retVal = SUCCESS;

    reqbuf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
    reqbuf.memory = V4L2_MEMORY_MMAP;
    reqbuf.count = count; 

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = ioctl(fd_dev1, VIDIOC_REQBUFS, &reqbuf);
    }

    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = ioctl(fd_dev2, VIDIOC_REQBUFS, &reqbuf);
    }

    if (SUCCESS != retVal)
    {
        return FAILURE;
    }

    return SUCCESS;
}


/****************************************************************************
 * Function             - st_v4l2_display_query_buffer_mmap_interface
 * Functionality        - This function implements the QUERYBUF ioctl and mmap
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_query_buffer_mmap_interface(int dev)
{

    int retVal = SUCCESS;
    int i=0;   

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        for (i = 0; i < reqbuf.count ; i++) {

            buf.index = i;
            buf.type =  V4L2_BUF_TYPE_VIDEO_OUTPUT;
            buf.memory= V4L2_MEMORY_MMAP; 

            retVal = ioctl(fd_dev1, VIDIOC_QUERYBUF, &buf);

            if(SUCCESS != retVal)
            {
                return QUERYBUFFAIL;
            } 
            /* Mmap */   
            display_buff_info[i].length= buf.length;
            display_buff_info[i].index = i;

            display_buff_info[i].start = mmap(NULL, buf.length, PROT_READ |
                    PROT_WRITE, MAP_SHARED,
                    fd_dev1, buf.m.offset);

            if ((unsigned int)display_buff_info[i].start == MAP_FAILED || (unsigned int)display_buff_info[i].start == MAP_SHARED ){

                return FAILURE;

            }

            memset(display_buff_info[i].start,0x80,buf.length);

        }
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        for (i = 0; i < reqbuf.count ; i++) {

            buf.index = i;
            buf.type =  V4L2_BUF_TYPE_VIDEO_OUTPUT;
            buf.memory= V4L2_MEMORY_MMAP; 

            retVal = ioctl(fd_dev2, VIDIOC_QUERYBUF, &buf);

            if(SUCCESS != retVal)
            {
                return QUERYBUFFAIL;
            } 
            /* Mmap */   
            display_buff_info[i].length= buf.length;
            display_buff_info[i].index = i;

            display_buff_info[i].start = mmap(NULL, buf.length, PROT_READ |
                    PROT_WRITE, MAP_SHARED,
                    fd_dev2, buf.m.offset);

            if ((unsigned int)display_buff_info[i].start == MAP_FAILED || (unsigned int)display_buff_info[i].start == MAP_SHARED ){

                return FAILURE;
            }

            memset(display_buff_info[i].start,0x80,buf.length);
        } 
    }

    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_query_buffer_mmap_interface_file
 * Functionality        - This function implements the QUERYBUF ioctl and mmap
 *                        for file display
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_query_buffer_mmap_interface_file(int dev)
{

    int retVal = SUCCESS;
    int i=0;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        for (i = 0; i < reqbuf.count ; i++) {

            buf.index = i;
            buf.type =  V4L2_BUF_TYPE_VIDEO_OUTPUT;
            buf.memory= V4L2_MEMORY_MMAP;

            retVal = ioctl(fd_dev1, VIDIOC_QUERYBUF, &buf);

            if(SUCCESS != retVal)
            {
                return QUERYBUFFAIL;
            }
            /* Mmap */
            display_buff_info[i].length= buf.length;
            display_buff_info[i].index = i;

            display_buff_info[i].start = mmap(NULL, buf.length, PROT_READ |
                    PROT_WRITE, MAP_SHARED,
                    fd_dev1, buf.m.offset);

            if ((unsigned int)display_buff_info[i].start == MAP_FAILED ||
                    (unsigned int)display_buff_info[i].start == MAP_SHARED ){

                return FAILURE;

            }

        }
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        for (i = 0; i < reqbuf.count ; i++) {

            buf.index = i;
            buf.type =  V4L2_BUF_TYPE_VIDEO_OUTPUT;
            buf.memory= V4L2_MEMORY_MMAP;

            retVal = ioctl(fd_dev2, VIDIOC_QUERYBUF, &buf);

            if(SUCCESS != retVal)
            {
                return QUERYBUFFAIL;
            }
            /* Mmap */
            display_buff_info[i].length= buf.length;
            display_buff_info[i].index = i;

            display_buff_info[i].start = mmap(NULL, buf.length, PROT_READ |
                    PROT_WRITE, MAP_SHARED,
                    fd_dev2, buf.m.offset);

            if ((unsigned int)display_buff_info[i].start == MAP_FAILED ||
                    (unsigned int)display_buff_info[i].start == MAP_SHARED ){

                return FAILURE;
            }

        }
    }

    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_querycap_interface
 * Functionality        - This function implements the QUERYCAP ioctl
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_querycap_interface(int dev)
{
    struct v4l2_capability capability;
    int retVal;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = ioctl(fd_dev1, VIDIOC_QUERYCAP, &capability);
    }

    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = ioctl(fd_dev2, VIDIOC_QUERYCAP, &capability);
    }

    if(retVal < 0)
    {
        return FAILURE;
    }
    if(capability.capabilities & V4L2_CAP_VIDEO_OUTPUT)
    {
        DBG_PRINT_TRC0(("Display capability is supported\n"));
    }
    else
    {
        DBG_PRINT_TRC0(("Display capability is not supported\n"));
    }
    if(capability.capabilities & V4L2_CAP_STREAMING)
    {
        DBG_PRINT_TRC0(("Streaming is supported\n"));
    }
    else
    {
        DBG_PRINT_TRC0(("Streaming is not supported\n"));
    }
    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_querycrop_interface
 * Functionality        - This function implements the CROPCAP ioctl
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_query_crop_interface(int dev)
{
    struct v4l2_cropcap cropcap;
    int retVal;
    cropcap.type = V4L2_BUF_TYPE_VIDEO_OUTPUT; 
    
    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = ioctl(fd_dev1, VIDIOC_CROPCAP, &cropcap);
    }

    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = ioctl(fd_dev2, VIDIOC_CROPCAP, &cropcap);
    }

    if(retVal < 0)
    {
        return FAILURE;
    }
    return SUCCESS;
}


/****************************************************************************
 * Function             - st_v4l2_display_setcrop_interface
 * Functionality        - This function is not supported on DM646x
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_set_crop_interface(int dev,int cropfactor)
{
    return OPERATION_NOT_SUPPORTED; 
}

/****************************************************************************
 * Function             - st_v4l2_display_getcrop_interface
 * Functionality        - This function is not supported on DM646x
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_get_crop_interface(int dev)
{
    return OPERATION_NOT_SUPPORTED; 
}

/****************************************************************************
 * Function             - st_v4l2_display_setcrop_interface
 * Functionality        - This function is not supported on DM646x
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_set_zoom_interface(int dev,int zoomfactor)
{
    return OPERATION_NOT_SUPPORTED;
}

/****************************************************************************
 * Function             - st_v4l2_display_enum_fmt_interface
 * Functionality        - This function implements the enum fmt ioctl
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_enum_fmt_interface(int dev)
{
    struct v4l2_fmtdesc fmt;
    int retVal;
    int i = 0;
    while(1)
    {
        fmt.index = i;
        // fmt.type = V4L2_BUF_TYPE_VIDEO_DISPLAY;
        if (V4L2_DISPLAY_DEV1 == dev)
        {
            retVal = ioctl(fd_dev1, VIDIOC_ENUM_FMT,&fmt);
        }
        if (V4L2_DISPLAY_DEV2 == dev)
        {
            retVal = ioctl(fd_dev2, VIDIOC_ENUM_FMT,&fmt);
        }
        if(retVal < 0)
        {
            break;
        }
        DBG_PRINT_TRC0(("description = %s\n",fmt.description));
        if(fmt.type == V4L2_BUF_TYPE_VIDEO_OUTPUT)
            DBG_PRINT_TRC0(("Video Display type\n"));
        if(fmt.pixelformat == V4L2_PIX_FMT_YUV422UVP)
            DBG_PRINT_TRC0(("V4L2_PIX_FMT_YUV422UVP\n"));
        i++;
    }
    return SUCCESS;
}


/****************************************************************************
 * Function             - st_v4l2_read_buffer_from_file_interface
 * Functionality        - This function reads the buffer from a file
 * Input Params         - File handle
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_read_buffer_from_file_interface(int fd)
{
    if (read(fd, display_buff_info[0].start, format.fmt.pix.sizeimage) != format.fmt.pix.sizeimage){

        return FAILURE;
    }
    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_enqueue_buffers
 * Functionality        - This function enqueues the buffers
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/

int st_v4l2_display_enqueue_buffers(int dev)
{

    int retval = SUCCESS;
    int i=0;   

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        for (i = 0; i < reqbuf.count ; i++) {

            buf.type =  V4L2_BUF_TYPE_VIDEO_OUTPUT;
            buf.memory=V4L2_MEMORY_MMAP;
            buf.index=i;

            retval = ioctl(fd_dev1, VIDIOC_QBUF, &buf); 

            if(retval < 0)
            {
                return FAILURE;
            }
            color_bar(display_buff_info[i].start, dispwidth,dispheight,sizeimage,0);
        }
    }     
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        for (i = 0; i < reqbuf.count ; i++) {

            buf.type =  V4L2_BUF_TYPE_VIDEO_OUTPUT;
            buf.memory=V4L2_MEMORY_MMAP;
            buf.index=i;

            retval = ioctl(fd_dev2, VIDIOC_QBUF, &buf); 

            if(retval < 0)
            {
                return FAILURE;
            }
            color_bar(display_buff_info[i].start,dispwidth,dispheight,sizeimage,0);

        }
    }     
    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_qbuf_interface
 * Functionality        - This function is wrapper for QBUF ioctl
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_qbuf_interface(int dev)
{

    int retval = SUCCESS;
    int i=0;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        for (i = 0; i < reqbuf.count ; i++) {

            buf.type =  V4L2_BUF_TYPE_VIDEO_OUTPUT;
            buf.memory=V4L2_MEMORY_MMAP;
            buf.index=i;

            retval = ioctl(fd_dev1, VIDIOC_QBUF, &buf);

            if(retval < 0)
            {
                return FAILURE;
            }
        }
    }
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        for (i = 0; i < reqbuf.count ; i++) {

            buf.type =  V4L2_BUF_TYPE_VIDEO_OUTPUT;
            buf.memory=V4L2_MEMORY_MMAP;
            buf.index=i;

            retval = ioctl(fd_dev2, VIDIOC_QBUF, &buf);

            if(retval < 0)
            {
                return FAILURE;
            }

        }
    }
    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_dequeue_buffers
 * Functionality        - This function dequeues the buffer
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_dequeue_buffers(int dev)
{

    int retval = SUCCESS;
    int i=0;   
    if (V4L2_DISPLAY_DEV1 == dev)
    {
        for(i=0;i<reqbuf.count;i++)
        {
            buf.type = reqbuf.type;
            buf.memory=V4L2_MEMORY_MMAP;
            buf.index = i;

            retval = ioctl(fd_dev1, VIDIOC_DQBUF, &buf); 

            if(SUCCESS!=retval)
            {
                return FAILURE;
            }
        }
    }     
    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        for(i=0;i<reqbuf.count;i++)
        {
            buf.type = reqbuf.type;
            buf.memory=V4L2_MEMORY_MMAP;
            buf.index = i;

            retval = ioctl(fd_dev2, VIDIOC_QBUF, &buf); 

            if(SUCCESS!=retval)
            {
                return FAILURE;
            }
        }
    }     
    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_color_bar
 * Functionality        - This function does the display of color bars
 * Input Params         - device number,number of frames to display
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_color_bar(int dev,int noframes)
{
    int retVal = SUCCESS;
    void *displaybuffer;
    int counter=0; 
    while(counter < noframes) {

        /*Get display buffer using DQBUF ioctl */

        if (V4L2_DISPLAY_DEV1 == dev)
        {
            retVal = ioctl(fd_dev1, VIDIOC_DQBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        else if (V4L2_DISPLAY_DEV2 == dev)
        {
            retVal = ioctl(fd_dev2, VIDIOC_DQBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }
        displaybuffer = display_buff_info[buf.index].start;	
        /* putting moving color bars */
        color_bar(displaybuffer,dispwidth,dispheight,sizeimage,counter%(dispheight));

        /* Now queue it back to display it */
        buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
        buf.memory = V4L2_MEMORY_MMAP;
        buf.index = buf.index;

        if (V4L2_DISPLAY_DEV1 == dev)
        {
            retVal = ioctl(fd_dev1, VIDIOC_QBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        else if (V4L2_DISPLAY_DEV2 == dev)
        {
            retVal = ioctl(fd_dev2, VIDIOC_QBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        counter++;
    }
    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_pattern_bar
 * Functionality        - This function does the display of a bar pattern
 * Input Params         - device number,number of frames to display
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_pattern_bar(int dev,int noframes)
{
    int retVal = SUCCESS;
    void *displaybuffer;
    int counter=0,l=0,kount=0,color=0;
    while(counter < noframes) {

        /*Get display buffer using DQBUF ioctl */
        if (V4L2_DISPLAY_DEV1 == dev)
        {
            retVal = ioctl(fd_dev1, VIDIOC_DQBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        else if (V4L2_DISPLAY_DEV2 == dev)
        {
            retVal = ioctl(fd_dev2, VIDIOC_DQBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }
        displaybuffer = display_buff_info[buf.index].start;
        /* putting moving color bars */
        for(l=0;l<dispheight;l++){
            memset(displaybuffer+l*disppitch+kount,color,4);
        }
        /* change the color and the X */
        kount+=3;color+=1;
        if (color >0xf0)
            color = 0;
        if (kount >(dispwidth-50)) 
            kount = 0;


        /* Now queue it back to display it */
        buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
        buf.memory = V4L2_MEMORY_MMAP;
        buf.index = buf.index;

        if (V4L2_DISPLAY_DEV1 == dev)
        {
            retVal = ioctl(fd_dev1, VIDIOC_QBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        else if (V4L2_DISPLAY_DEV2 == dev)
        {
            retVal = ioctl(fd_dev2, VIDIOC_QBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        counter++;
    }
    return SUCCESS;
}


/****************************************************************************
 * Function             - st_v4l2_display_from_file
 * Functionality        - This function does the display from a file
 * Input Params         - device number,number of frames to display
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/

int st_v4l2_display_from_file(int dev,int fd,int noframes)
{
    int retVal = SUCCESS;
    void *displaybuffer;
    int counter=0;
    int i=0;
    while(counter < noframes) {

        /*Get display buffer using DQBUF ioctl */

        if (V4L2_DISPLAY_DEV1 == dev)
        {
            retVal = ioctl(fd_dev1, VIDIOC_DQBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        else if (V4L2_DISPLAY_DEV2 == dev)
        {
            retVal = ioctl(fd_dev2, VIDIOC_DQBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }
        i = read(fd,
                display_buff_info[buf.index].start,format.fmt.pix.sizeimage);
        if (i < 0) {
            return FAILURE;
        }
        if (i != format.fmt.pix.sizeimage){
            break; 
        }

        /* Now queue it back to display it */
        buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
        buf.memory = V4L2_MEMORY_MMAP;
        buf.index = buf.index;

        if (V4L2_DISPLAY_DEV1 == dev)
        {
            retVal = ioctl(fd_dev1, VIDIOC_QBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        else if (V4L2_DISPLAY_DEV2 == dev)
        {
            retVal = ioctl(fd_dev2, VIDIOC_QBUF, &buf);
            if (SUCCESS!=retVal) {
                return FAILURE;
            }
        }

        counter++;
    }
    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_streamon_interface
 * Functionality        - This function implements the STREAMON ioctl 
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_streamon_interface(int dev)
{
    int type = V4L2_BUF_TYPE_VIDEO_OUTPUT, retVal;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = ioctl(fd_dev1, VIDIOC_STREAMON, &type);
    }

    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = ioctl(fd_dev2, VIDIOC_STREAMON, &type);
    }

    if(retVal < 0)
    {
        return FAILURE;
    }

    return SUCCESS;
}

/****************************************************************************
 * Function             - st_v4l2_display_streamoff_interface
 * Functionality        - This function implements the STREAMON ioctl 
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_streamoff_interface(int dev)
{
    int type = V4L2_BUF_TYPE_VIDEO_OUTPUT, retVal;

    if (V4L2_DISPLAY_DEV1 == dev)
    {
        retVal = ioctl(fd_dev1, VIDIOC_STREAMOFF, &type);
    }

    else if (V4L2_DISPLAY_DEV2 == dev)
    {
        retVal = ioctl(fd_dev2, VIDIOC_STREAMOFF, &type);
    }

    if(SUCCESS!=retVal)
    {
        return FAILURE;
    }

    return SUCCESS;
}


/****************************************************************************
 * Function             - st_v4l2_display_unmap_interface
 * Functionality        - This function implements the unmap call 
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
int st_v4l2_display_unmap_interface(int dev)
{
    int i,retval;

    for(i=0; i< reqbuf.count; i++)
    {
        retval=munmap(display_buff_info[i].start,display_buff_info[i].length);
    }

    if(SUCCESS!=retval)
    {
        return FAILURE;
    }

    return SUCCESS;
}

/****************************************************************************
 * Function             - check_pixel_format
 * Functionality        - This function is not implemented as DM646x supports
 *                        only 1 pixel format
 * Input Params         - None
 * Return Value         - 0 on SUCCESS -1 on FAILURE
 * Note                 - None
 ****************************************************************************/
int check_pixel_format()
{

    return SUCCESS;
}

/****************************************************************************
 * Function             - check_output_path
 * Functionality        - This function checks the ouput for LCD or TV-Not
 *                        implemented as it supports only TV out on DM646x
 * Input Params         - None
 * Return Value         - 0 on SUCCESS -1 on FAILURE
 * Note                 - None
 ****************************************************************************/
int check_output_path()
{
    return SUCCESS;
}

/****************************************************************************
 * Function             - set_sysfs_path_for_ntsc
 * Functionality        - This function sets the mode to NTSC
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_ntsc()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,NTSC_MODE_NAME);
    strcat(command, " > ");
    strcat(command, CH0_MODE);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}

/****************************************************************************
 * Function             - set_sysfs_path_for_pal
 * Functionality        - This function sets the mode to PAL
 * Input Params         - Test params structure
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_pal()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,PAL_MODE_NAME);
    strcat(command, " > ");
    strcat(command, CH0_MODE);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}


/****************************************************************************
 * Function             - set_sysfs_path_for_1080i_30
 * Functionality        - This function sets the mode to 1080i_30HZ
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_1080i_30()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,HD_1080I_30_MODE_NAME);
    strcat(command, " > ");
    strcat(command, CH0_MODE);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}

/****************************************************************************
 * Function             - set_sysfs_path_for_1080i_25
 * Functionality        - This function sets the mode to 1080i_25HZ
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_1080i_25()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,HD_1080I_25_MODE_NAME);
    strcat(command, " > ");
    strcat(command, CH0_MODE);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}


/****************************************************************************
 * Function             - set_sysfs_path_for_720p_50
 * Functionality        - This function sets the mode to 720P_50HZ
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_720p_50()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,HD_720P_50_MODE_NAME);
    strcat(command, " > ");
    strcat(command, CH0_MODE);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}


/****************************************************************************
 * Function             - set_sysfs_path_for_720p_60
 * Functionality        - This function sets the mode to 720P_60HZ
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_720p_60()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,HD_720P_60_MODE_NAME);
    strcat(command, " > ");
    strcat(command, CH0_MODE);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}


/****************************************************************************
 * Function             - set_sysfs_path_for_480p_60
 * Functionality        - This function sets the mode to 480P_60HZ
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_480p_60()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,ED_480P_60_MODE_NAME);
    strcat(command, " > ");
    strcat(command, CH0_MODE);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}


/****************************************************************************
 * Function             - set_sysfs_path_for_576p_50
 * Functionality        - This function sets the mode to 576P_50HZ
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_576p_50()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,ED_576P_50_MODE_NAME);
    strcat(command, " > ");
    strcat(command, CH0_MODE);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}



/****************************************************************************
 * Function             - check_std
 * Functionality        - This function checks the user input fot stnadard name
 * Input Params         - None
 * Return Value         - 0 on SUCCESS -1 on FAILURE
 * Note                 - None
 ****************************************************************************/
int check_std()
{
    if(strcmp(standard,"ntsc") == 0)
    {
        set_sysfs_path_for_ntsc();
    }

    else if(strcmp(standard,"pal") == 0)
    {
        set_sysfs_path_for_pal();
    }

    else if(strcmp(standard,"720p-50") == 0)
    {
        set_sysfs_path_for_720p_50();
    }

    else if(strcmp(standard,"720p-60") == 0)
    {
        set_sysfs_path_for_720p_60();
    }

    else if(strcmp(standard,"1080i-30") == 0)
    {
        set_sysfs_path_for_1080i_30();
    }

    else if(strcmp(standard,"1080i-25") == 0)
    {
        set_sysfs_path_for_1080i_25();
    }

    else if(strcmp(standard,"480p-60") == 0)
    {
        set_sysfs_path_for_480p_60();
    }

    else if(strcmp(standard,"576p-50") == 0)
    {
        set_sysfs_path_for_576p_50();
    }
    else
    { 
        DBG_PRINT_ERR(("Standard not supported\n"));
        return FAILURE;
    }

    return SUCCESS;

}

/****************************************************************************
 * Function             - check_interface
 * Functionality        - This function checks the interface
 * Input Params         - None
 * Return Value         - 0 on SUCCESS -1 on FAILURE
 * Note                 - None
 ****************************************************************************/
int check_interface()
{
    if(strcmp(interface,"composite") == 0)
    {
        set_sysfs_path_for_composite();
    }

    else if(strcmp(interface,"component") == 0)
    {
        set_sysfs_path_for_component();
    }

    else if(strcmp(interface,"svideo") == 0)
    {
        set_sysfs_path_for_svideo();
    }
    else
    {
        DBG_PRINT_ERR(("Interface not supported\n"));
        return FAILURE;
    }
    return SUCCESS;
}

/****************************************************************************
 * Function             - set_sysfs_path_for_composite
 * Functionality        - This function sets the output for composite 
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_composite()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,COMPOSITE_OUTPUT_NAME);
    strcat(command, " > ");
    strcat(command, CH0_OUTPUTPATH);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}

/****************************************************************************
 * Function             - set_sysfs_path_for_component
 * Functionality        - This function sets the output for component
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_component()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,COMPONENT_OUTPUT_NAME);
    strcat(command, " > ");
    strcat(command, CH0_OUTPUTPATH);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0); 
    }
}

/****************************************************************************
 * Function             - set_sysfs_path_for_svideo
 * Functionality        - This function sets the output for svideo
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void set_sysfs_path_for_svideo()
{
    char command[80];
    strcpy(command, "echo ");
    strcat(command,SVIDEO_OUTPUT_NAME);
    strcat(command, " > ");
    strcat(command, CH0_OUTPUTPATH);
    if(system(command)) {
        DBG_PRINT_ERR(("Failed to set output\n"));
        exit(0);
    }
}

/****************************************************************************
 * Function             - st_v4l2_set_device_number
 * Functionality        - Function sets device number for a device string
 * Input Params         - device name and numberNone
 * Note                 - None
 ****************************************************************************/
void st_v4l2_set_device_number(char* devname, int* st_dev)
{
    if (!strcmp(devname, V4L2_DEV1))
    {
        *st_dev = V4L2_DISPLAY_DEV1;
    }
    else if (!strcmp(devname, V4L2_DEV2))
    {
        *st_dev = V4L2_DISPLAY_DEV2;
    }

}
/****************************************************************************
 * Function             - print_v4l2_display_test_params
 * Functionality        - This function prints the test option values
 * Input Params         - Test params structure
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/

void print_v4l2_display_test_params(struct v4l2_display_testparams *testoptions)
{
    DBG_PRINT_TRC0(("The Test is going to start with following values |\n"));
    DBG_PRINT_TRC0(("The device node | %s\n",testoptions->devnode));
    DBG_PRINT_TRC0(("The height of the image | %d\n",testoptions->height));
    DBG_PRINT_TRC0(("The width  of the image | %d\n",testoptions->width));
    DBG_PRINT_TRC0(("The number of buffers | %d\n",testoptions->noofbuffers));
    DBG_PRINT_TRC0(("The number of frames | %d\n",testoptions->noofframes));
}

/****************************************************************************
 * Function             - display_help
 * Functionality        - This function displays the help/usage
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
void display_v4l2_display_test_suite_help(void)
{
    printf("v4l2DisplayTestSuite V %1.2f\n", VERSION_STRING);
    printf("Usage:\n"
            "./dm646xV4l2DisplayTests <options>\n\n"
            "-d       --displaynode     Device node on which display test is to be run\n"
                                        "\t\t\t\tPossible values-/dev/video2\n"
            "-T       --testname        Name of the special test\n"
                                        "\t\t\t\tPossible values-stability,api\n"
            "-w       --width           Width of the image to be displayed\n"
            "-h       --height          Height of the image to be displayed\n"
            "-c       --countofbuffers  Number of buffers to queue\n"
            "-C       --stabilitycount  Number of times to run stability test\n"
            "-t       --testcaseid      Test case id string for testers reference/logging purpose\n"
                                        "\t\t\t\tPossible values- Any String without spaces\n"
            "-n       --noofframes      Number of frames to be displayed\n"
            "-f       --filename        Name of the image file to display\n"
                                        "\t\t\t\t Make sure the file is as per -w(width),-h(height) configured & in YUV422UVP Davinci-HD format\n"
            "-s       --standard          Name of the standard\n"
                                        "\t\t\t\tPossible values-ntsc,pal,1080i-30,1080i-25,720p-50,720p-60,480p-60,576p-50\n"
            "-i       --interface       Name of the interface\n"
                                        "\t\t\t\tPossible values-composite,component,svideo\n"
            "-?       --help            Displays the help/usage\n"
            "-v       --version         Version of Display Test suite\n");
    exit(0);
}

/* vim: set ts=4 sw=4 tw=80 et:*/

