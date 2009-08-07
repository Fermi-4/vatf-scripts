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
**|         Copyright (c) 1998-2005 Texas Instruments Incorporated           |**
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

#include "st_common.h"
#include "st_linuxdevio.h"
#include "st_vpfe_interface.h"

static int fd = -1;
static buffer* mmap_buffers = NULL;
static unsigned int number_of_mmap_buffers = 0;

int test_vpfe_interface_open_device(char* dev_name)
{
	struct stat st;

	if(-1 == stat(dev_name, &st))
	{
		return -1; 
	}
	
	if(!S_ISCHR(st.st_mode)) 
	{
		return -2;
	}

	fd = open(dev_name, O_RDWR | O_NONBLOCK, 0);
	if(-1 == fd)
	{
		return -3;
	}
	
	return 0;
}

int test_vpfe_interface_init_mmap(int number_of_buffers)
{
	struct v4l2_requestbuffers req;
	unsigned int i;

	memset (&req, 0, sizeof(req));

	req.count = number_of_buffers;
	req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	req.memory = V4L2_MEMORY_MMAP;

	if(-1 == ioctl(fd, VIDIOC_REQBUFS, &req)) 
	{
		return -1;
	}

	mmap_buffers = calloc(req.count, sizeof(*mmap_buffers));
	if(NULL == mmap_buffers)
	{
		return -2;
	}
	
	for(i = 0; i < req.count; i++)
	{
		struct v4l2_buffer buf;
		memset(&buf,0,sizeof(buf));

		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		buf.memory = V4L2_MEMORY_MMAP;
		buf.index = i;

		if(-1 == ioctl(fd, VIDIOC_QUERYBUF, &buf)) 
		{
			return -3;
		}

		mmap_buffers[i].length = buf.length;
		mmap_buffers[i].start = 
			mmap(NULL,
				buf.length,
				PROT_READ | PROT_WRITE,
				MAP_SHARED,
				fd, buf.m.offset);
		if(MAP_FAILED == mmap_buffers[i].start)
		{
			return -4;
		}
	}

	number_of_mmap_buffers = req.count; //Store the number of buffers

	return 0;
}

int test_vpfe_interface_uninit_mmap(void)
{
	unsigned int i;
	
	for(i = 0; i < number_of_mmap_buffers; i++)
	{
		if(-1 == munmap(mmap_buffers[i].start, mmap_buffers[i].length))
		{
			return -1;
		}
	}

	free(mmap_buffers);

	return 0;
}

int test_vpfe_interface_close_device(void)
{
	return close(fd);
}

int test_vpfe_interface_enum_fmt(struct v4l2_fmtdesc* fmt)
{
	return ioctl(fd, VIDIOC_ENUM_FMT, fmt);
}

int test_vpfe_interface_enum_std(struct v4l2_standard* std)
{
	return ioctl(fd, VIDIOC_ENUMSTD, std);
}

int test_vpfe_interface_query_capabilities(struct v4l2_capability* cap)
{
	return ioctl(fd, VIDIOC_QUERYCAP, cap);
}

int test_vpfe_interface_query_control(struct v4l2_queryctrl* ctrl)
{
	return ioctl(fd, VIDIOC_QUERYCTRL, ctrl);
}

int test_vpfe_interface_query_std(v4l2_std_id* std)
{
	return ioctl(fd, VIDIOC_QUERYSTD, std);
}

int test_vpfe_interface_set_crop_capabilities(unsigned int type)
{
	struct v4l2_cropcap cap;	
	struct v4l2_crop crop;

	cap.type = type;

	if(-1 == ioctl(fd, VIDIOC_CROPCAP, &cap)) 
	{
		return -1;
	} 

	crop.type = type;
	crop.c = cap.defrect;

	if(-1 == ioctl(fd, VIDIOC_S_CROP, &crop))
	{
		return -2;
	}

	return 0;
}

int test_vpfe_interface_set_std(v4l2_std_id* std)
{
	return ioctl(fd, VIDIOC_S_STD, std);
}

int test_vpfe_interface_set_fmt(struct v4l2_format* fmt)
{
	return ioctl(fd, VIDIOC_S_FMT, fmt);
}
