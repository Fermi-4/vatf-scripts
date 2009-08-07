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
#include "st_vpfe.h"

static char * dev_name = "/dev/video0";

void vpfe_parser(void)
{
	int i=0;
	char cmd[40];
	char cmdlist[][40] = {
		"open",
		"init_mmap",
		"uninit_mmap",
		"close", 
		"enum_format",
		"enum_std",
		"get_capabilities",
		"get_ctrl",
		"get_std",
		"set_crop_capabilities",
		"set_std",
		"set_format",
		"help"
	};
	
	while(1)
	{
		i=0;
		printTerminalf("\nvpfe> ");
		scanTerminalf("%s", cmd);
		if(0 == strcmp(cmd, "exit"))
		{
			printTerminalf("Exiting VPFE Mode to Main Parser\n");	
			break;
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_open_device();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_init_mmap();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_uninit_mmap();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_close_device();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_enum_format();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_enum_std();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_query_capabilities();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_query_control();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_query_std();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_set_crop_capabilities();
		}
	       	else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_set_std();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpfe_set_fmt();
		}
		else 
		{
			int j=0;
			printTerminalf("Available VFBE Functions: \n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf("%s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}

	}

	return;
}

void test_vpfe_open_device(void)
{
	int retval;

	retval = test_vpfe_interface_open_device(dev_name);
	
	switch(retval)
	{
		case -1:
			printTerminalf("Could not open %s: %d\n",
					dev_name, errno);
			break;
		case -2:
			printTerminalf("%s is not a valid device\n", dev_name);
			break;

		case -3:
			printTerminalf("open of %s failed: %d\n", dev_name, errno);
			break;
		default:
			printTerminalf("open of %s success\n", dev_name);
			break;
	}
}

void test_vpfe_close_device(void)
{
	if(-1 == test_vpfe_interface_close_device())
	{
		printTerminalf("close of %s failed\n", dev_name);
	} else {
		printTerminalf("close of %s success\n", dev_name);
	}
	
	return;
}

void test_vpfe_query_capabilities(void)
{
	struct v4l2_capability cap;	

	if(-1 == test_vpfe_interface_query_capabilities(&cap)) 
	{
		printTerminalf("Query Capabilities failed: %d\n", errno);
	} else {
		printTerminalf("driver:       %s\n", cap.driver);
		printTerminalf("card:         %s\n", cap.card);
		printTerminalf("bus_info:     %s\n", cap.bus_info);
		printTerminalf("version:      %d\n", cap.version);
		printTerminalf("capabilities: %d\n", cap.capabilities);
		if(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)
			printTerminalf("\tSupports V4L2_CAP_VIDEO_CAPTURE\n");
		if(cap.capabilities & V4L2_CAP_VIDEO_OUTPUT)
			printTerminalf("\tSupports V4L2_CAP_VIDEO_OUTPUT\n");
		if(cap.capabilities & V4L2_CAP_VIDEO_OVERLAY)
			printTerminalf("\tSupports V4L2_CAP_VIDEO_OVERLAY\n");
		if(cap.capabilities & V4L2_CAP_VBI_CAPTURE)
			printTerminalf("\tSupports V4L2_CAP_VBI_CAPTURE\n");
		if(cap.capabilities & V4L2_CAP_VBI_OUTPUT)
			printTerminalf("\tSupports V4L2_CAP_VBI_OUTPUT\n");
		if(cap.capabilities & V4L2_CAP_RDS_CAPTURE)
			printTerminalf("\tSupports V4L2_CAP_RDS_CAPTURE\n");
		if(cap.capabilities & V4L2_CAP_TUNER)
			printTerminalf("\tSupports V4L2_CAP_TUNER\n");
		if(cap.capabilities & V4L2_CAP_AUDIO)
			printTerminalf("\tSupports V4L2_CAP_AUDIO\n");
		if(cap.capabilities & V4L2_CAP_RADIO)
			printTerminalf("\tSupports V4L2_CAP_RADIO\n");
		if(cap.capabilities & V4L2_CAP_READWRITE)
			printTerminalf("\tSupports V4L2_CAP_READWRITE\n");
		if(cap.capabilities & V4L2_CAP_ASYNCIO)
			printTerminalf("\tSupports V4L2_CAP_ASYNCIO\n");
		if(cap.capabilities & V4L2_CAP_STREAMING)
			printTerminalf("\tSupports V4L2_CAP_STREAMING\n");

		printTerminalf("reserved:     %d\n", cap.reserved);
	}
}

void test_vpfe_enum_format(void)
{
	struct v4l2_fmtdesc fmt;	
	int i=0, ret;

	memset(&fmt, 0, sizeof(fmt));

	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	do{
		fmt.index = i++;
		ret = test_vpfe_interface_enum_fmt(&fmt);
		if(ret != -1) {
			printTerminalf("format description: %s.\n", fmt.description);
			switch(fmt.pixelformat)
			{
				case V4L2_PIX_FMT_UYVY:
					printTerminalf("V4L2_PIX_FMT_UYVY.\n");
					break;
				case V4L2_PIX_FMT_YUYV:
					printTerminalf("V4L2_PIX_FMT_YUYV.\n");
					break;
				default:
					printTerminalf("Unknown Format:%d\n", fmt.pixelformat);
			}

		}
	}while(ret != -1);

}

void test_vpfe_enum_std(void)
{
	struct v4l2_standard std;	
	int i=0, ret;

	memset(&std, 0, sizeof(std));

	do{
		std.index = i++;
		ret = test_vpfe_interface_enum_std(&std);
		if(ret != -1) {
			printTerminalf("standard name: %s.\n", std.name);
			printTerminalf("number of lines per frame: %d.\n", std.framelines);
			printTerminalf("frame period. %d / %d.\n",
					std.frameperiod.numerator, std.frameperiod.denominator);
			if(std.id & V4L2_STD_525_60) {
				printf("the video standard is V4L2_STD_525_60.\n");
			}else if(std.id & V4L2_STD_625_50) {
				printf("the video standard is V4L2_STD_625_50.\n");
			}else if(std.id == VPFE_STD_625_50_SQP){
				printf("the video standard is VPFE_STD_625_50_SQP square pixel.\n");
			}else if(std.id == VPFE_STD_525_60_SQP){
				printf("the video standard is VPFE_STD_525_60_SQP square pixel.\n");
			}else if(std.id == VPFE_STD_AUTO) {
				printf("the video standard is VPFE_STD_AUTO.\n");
			}else if(std.id == VPFE_STD_AUTO_SQP) {
				printf("the video standard is VPFE_STD_AUTO_SQP.\n");
			}else{
				printf("un-supported video standard.\n");
			}
		} else {
			perror("STDENUM");
		}
	}while(ret != -1);

}

void test_vpfe_query_control(void)
{
	struct v4l2_queryctrl ctrl;	
	
	memset(&ctrl, 0, sizeof(ctrl));

	for(ctrl.id = V4L2_CID_BASE; ctrl.id < V4L2_CID_LASTP1; ctrl.id++){
		if(-1 == test_vpfe_interface_query_control(&ctrl)) 
		{
			printTerminalf("Query ctrl failed: %d\n", errno);
		} else {
			if(ctrl.flags & V4L2_CTRL_FLAG_DISABLED)
			{
				continue;
			}
			printTerminalf("control name: %s\n", ctrl.name);
			printTerminalf("control range: %d - %d:step size %d\n",
					ctrl.minimum, ctrl.maximum, ctrl.step);
			printTerminalf("default value: %d\n", ctrl.default_value);
		}

	}
}

void test_vpfe_query_std(void)
{
	v4l2_std_id std;	
	
	if(-1 == test_vpfe_interface_query_std(&std)) 
	{
		printTerminalf("Query std failed: %d\n", errno);
	} else {
		switch (std){
			case V4L2_STD_NTSC:
				printf("video standard is NTSC\n");
				break;
			case V4L2_STD_PAL:
				printf("video standard is PAL\n");
				break;
			case V4L2_STD_PAL_M:
				printf("video standard is PAL_M\n");
				break;
			case V4L2_STD_PAL_N:
				printf("video standard is PAL_N\n");
				break;
			case V4L2_STD_SECAM:
				printf("video standard is SECAM\n");
				break;
			case V4L2_STD_PAL_60:
				printf("video standard is PAL_60\n");
				break;
			default:
				printTerminalf("video standard is unknown:%d\n");
		}

	}

}

void test_vpfe_set_crop_capabilities(void)
{
	unsigned int type = 0;
	int retval;

	printTerminalf("Enter the Buffer Type\n");
	printTerminalf("1: V4L2_BUF_TYPE_VIDEO_CAPTURE\n");
	printTerminalf("2: V4L2_BUF_TYPE_VIDEO_OUTPUT\n");
	printTerminalf("3: V4L2_BUF_TYPE_VIDEO_OVERLAY\n");
	printTerminalf("4: V4L2_BUF_TYPE_VBI_CAPTURE\n"); 
	printTerminalf("5: V4L2_BUF_TYPE_VBI_OUTPUT\n"); 
	printTerminalf("6: V4L2_BUF_TYPE_PRIVATE\n");   
	scanTerminalf("%d", &type);

	retval = test_vpfe_interface_set_crop_capabilities(type);
	switch(retval)
	{
		case -1:
			printTerminalf("IOCTL to get crop capabilities failed: %d\n", errno);
			break;
		case -2:
			printTerminalf("IOCTL to set crop failed: %d\n", errno);
			break;
		default:
			printTerminalf("Setting of Crop Success\n");
			break;
	}
}

void test_vpfe_set_std(void)
{
	v4l2_std_id std;	
	unsigned int type = 0;

	printTerminalf("Enter the STD Type\n");
	printTerminalf("1: V4L2_STD_PAL\n");
	printTerminalf("2: V4L2_STD_NTSC\n");
	printTerminalf("3: V4L2_STD_PAL_M\n");
	printTerminalf("4: V4L2_STD_PAL_N\n");
	printTerminalf("5: V4L2_STD_SECAM\n");
	printTerminalf("6: V4L2_STD_PAL_60\n");
	printTerminalf("7: V4L2_STD_ALL\n");
	scanTerminalf("%d", &type);

	switch(type)
	{
		case 1:
			std = V4L2_STD_PAL;
			break;
		case 2:
			std = V4L2_STD_NTSC;
			break;
		case 3:
			std = V4L2_STD_PAL_M;
			break;
		case 4:
			std = V4L2_STD_PAL_N;
			break;
		case 5:
			std = V4L2_STD_SECAM;
			break;
		case 6:
			std = V4L2_STD_PAL_60;
			break;
		case 7:
			std = V4L2_STD_ALL;
			break;
	}

	if(-1 == test_vpfe_interface_set_std(&std))
	{
		printTerminalf("IOCTL to set STD failed: %d\n", errno);
	} else {
		printTerminalf("Setting of STD Success\n");
	}
}

void test_vpfe_init_mmap(void)
{
	unsigned int number_of_buffers = 0;
	int retval;

	printTerminalf("Enter the number of buffers\n");
	scanTerminalf("%d", &number_of_buffers);

	retval = test_vpfe_interface_init_mmap(number_of_buffers);
	switch(retval)
	{
		case -1:	
			printTerminalf("IOCTL to request buffers failed: %d\n", errno);
			break;
		case -2:	
			printTerminalf("Insufficient memory to allocate buffers\n");
			break;
		case -3:	
			printTerminalf("IOCTL to query buffers failed: %d\n", errno);
			break;
		case -4:	
			printTerminalf("Could not mmap buffer\n");
			break;
		default:
			printTerminalf("Successfully mmapped buffers\n");
			break;
	}
}

void test_vpfe_uninit_mmap(void)
{
	int retval;

	retval = test_vpfe_interface_uninit_mmap();
	switch(retval)
	{
		case -1:	
			printTerminalf("munmap failed: %d\n", errno);
			break;
		default:
			printTerminalf("Successfully munmapped buffers\n");
			break;
	}
}

void test_vpfe_set_fmt(void)
{
	struct v4l2_format fmt;
	int tmp;

	memset(&fmt, 0, sizeof(fmt));

	printTerminalf("Enter the Buffer Type\n");
	printTerminalf("1: V4L2_BUF_TYPE_VIDEO_CAPTURE\n");
	printTerminalf("2: V4L2_BUF_TYPE_VIDEO_OUTPUT\n");
	printTerminalf("3: V4L2_BUF_TYPE_VIDEO_OVERLAY\n");
	printTerminalf("4: V4L2_BUF_TYPE_VBI_CAPTURE\n"); 
	printTerminalf("5: V4L2_BUF_TYPE_VBI_OUTPUT\n"); 
	printTerminalf("6: V4L2_BUF_TYPE_PRIVATE\n");   
	scanTerminalf("%d", &fmt.type);

	printTerminalf("Enter the Width\n");
	scanTerminalf("%d", &fmt.fmt.pix.width);

	printTerminalf("Enter the Height\n");
	scanTerminalf("%d", &fmt.fmt.pix.height);

	printTerminalf("Enter the Pixel Format\n");
	printTerminalf("1: V4L2_PIX_FMT_RGB332\n");  
	printTerminalf("2: V4L2_PIX_FMT_RGB555\n");  
	printTerminalf("3: V4L2_PIX_FMT_RGB565\n");  
	printTerminalf("4: V4L2_PIX_FMT_RGB555X\n"); 
	printTerminalf("5: V4L2_PIX_FMT_RGB565X\n"); 
	printTerminalf("6: V4L2_PIX_FMT_BGR24\n");   
	printTerminalf("7: V4L2_PIX_FMT_RGB24\n");   
	printTerminalf("8: V4L2_PIX_FMT_BGR32\n");   
	printTerminalf("9: V4L2_PIX_FMT_RGB32\n");   
	printTerminalf("10: V4L2_PIX_FMT_GREY\n");    
	printTerminalf("11: V4L2_PIX_FMT_YVU410\n");  
	printTerminalf("12: V4L2_PIX_FMT_YVU420\n");  
	printTerminalf("13: V4L2_PIX_FMT_YUYV\n");    
	printTerminalf("14: V4L2_PIX_FMT_UYVY\n");    
	printTerminalf("15: V4L2_PIX_FMT_YUV422P\n"); 
	printTerminalf("16: V4L2_PIX_FMT_YUV411P\n"); 
	printTerminalf("17: V4L2_PIX_FMT_Y41P\n");    
	scanTerminalf("%d", &tmp);
	switch(tmp)
	{
		case 1:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB332;
				break;
		case 2:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB555;
				break;
		case 3:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB565;
				break;
		case 4:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB555X;
				break;
		case 5:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB565X;
				break;
		case 6:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_BGR24;
				break;
		case 7:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB24;
				break;
		case 8:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_BGR32;
				break;
		case 9:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_RGB32;
				break;
		case 10:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_GREY;
				break;
		case 11:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YVU410;
				break;
		case 12:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YVU420;
				break;
		case 13:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
				break;
		case 14:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
				break;
		case 15:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUV422P;
				break;
		case 16:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUV411P;
				break;
		case 17:
			fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_Y41P;
				break;
	}

	printTerminalf("Enter the Field Format\n");
	printTerminalf("1: V4L2_FIELD_ANY\n");
	printTerminalf("2: V4L2_FIELD_NONE\n");
	printTerminalf("3: V4L2_FIELD_TOP\n");
	printTerminalf("4: V4L2_FIELD_BOTTOM\n");
	printTerminalf("5: V4L2_FIELD_INTERLACED\n");
	printTerminalf("6: V4L2_FIELD_SEQ_TB\n");
	printTerminalf("7: V4L2_FIELD_SEQ_BT\n");
	printTerminalf("8: V4L2_FIELD_ALTERNATE\n");
	scanTerminalf("%d", &tmp);

	switch(tmp)
	{
		case 1:
			fmt.fmt.pix.field = V4L2_FIELD_ANY;        
			break;
		case 2:
			fmt.fmt.pix.field = V4L2_FIELD_NONE;       
			break;
		case 3:
			fmt.fmt.pix.field = V4L2_FIELD_TOP;       
			break;
		case 4:
			fmt.fmt.pix.field = V4L2_FIELD_BOTTOM;   
			break;
		case 5:
			fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
			break;
		case 6:
			fmt.fmt.pix.field = V4L2_FIELD_SEQ_TB;   
			break;
		case 7:
			fmt.fmt.pix.field = V4L2_FIELD_SEQ_BT;
			break;
		case 8:
			fmt.fmt.pix.field = V4L2_FIELD_ALTERNATE;
			break;
	}

	if(-1 == test_vpfe_interface_set_fmt(&fmt))
	{
		printTerminalf("IOCTL to set FMT failed: %d\n", errno);
	} else {
		printTerminalf("Setting of FMT success\n");
	}
}
