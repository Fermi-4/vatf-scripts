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

#ifndef __ST_VPFE_INTERFACE
#define __ST_VPFE_INTERFACE
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <asm/types.h>
#include <linux/videodev2.h>

typedef struct buffer
{
	void* start;
	size_t length;
} buffer;

int test_vpfe_interface_open_device(char* dev_name);
int test_vpfe_interface_init_mmap(int number_of_buffers);
int test_vpfe_interface_uninit_mmap(void);
int test_vpfe_interface_close_device(void);

int test_vpfe_interface_enum_fmt(struct v4l2_fmtdesc* fmt);
int test_vpfe_interface_enum_std(struct v4l2_standard* std);

int test_vpfe_interface_query_capabilities(struct v4l2_capability* cap);
int test_vpfe_interface_query_control(struct v4l2_queryctrl* ctrl);
int test_vpfe_interface_query_std(v4l2_std_id* std);
int test_vpfe_interface_set_crop_capabilities(unsigned int type);
int test_vpfe_interface_set_std(v4l2_std_id* std);
int test_vpfe_interface_set_fmt(struct v4l2_format* fmt);
#endif
