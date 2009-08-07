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


#include <unistd.h>
#include <errno.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/mman.h>
#include "st_common.h"
#include "st_vpbeparser.h"
#include "st_linuxdevio.h"

extern int test_vpbe_interface_open_fb(int);
extern int test_vpbe_resize_interface_image_display(int,int,int);
extern int test_vpbe_interface_image_display(int number);
extern int test_vpbe_interface_getScreeninfo_vidx(int );
extern int test_vpbe_interface_setScreenInfo_vidx(int,int,int,int);
extern int test_vpbe_interface_getScreenInfo_vidx(int);
extern int test_vpbe_interface_get_fix_ScreenInfo_vidx(int framebuffer);
extern int test_vpbe_interface_blankUnblankScreen_vidx(int framebuffer);
extern int test_vpbe_interface_relocate_vidx(int framebuffer);
extern int test_vpbe_interface_tripleBuffer_vidx(int framebuffer_to_open);
extern int test_vpbe_interface_readImage_display(int framebuffer_to_open);
extern int test_vpbe_interface_closeDevice(int framebuffer_to_close);
extern int test_vpbe_interface_stress_test_vid(int framebuffer_to_open);
extern int test_vpbe_interface_stress_test_osd(int framebuffer_to_open);
extern int test_vpbe_interface_create_blend(int framebuffer_to_open,int blend_value);
extern int test_vpbe_interface_create_blend_ioctl(int framebuffer_to_open,int blend_value);
extern int test_vpbe_interface_play_video(int framebuffer_to_open);
extern int test_vpbe_interface_mmap_vidx(int framebuffer_to_open);
extern int test_vpbe_interface_set_zoom(int framebuffer_to_open,int window_ID,int zoom_hvalue,int zoom_vvalue);
extern int test_vpbe_interface_get_standard(int framebuffer_to_open);

int fbfd[VPBE_NUMBER_OF_FRAMEBUFFERS] = {0,};
char fb_dev_names[VPBE_NUMBER_OF_FRAMEBUFFERS][20] = {"/dev/fb0", "/dev/fb1", "/dev/fb2", "/dev/fb3"};
struct fb_var_screeninfo vinfo_vidx[4];
extern struct fb_fix_screeninfo finfo_vidx[];


void vpbe_parser(void)
{
	int i=0;
	char cmd[40];
	char cmdlist[][40] = {
		"open_device",
		"mmap_vidx",
		"make_blend",
		"make_blend_ioctl",
		"display_image",
	      	"change_resolution",
		"set_screen_info",
		"get_screen_info",
		"get_standard",
		"get_fix_screen_info",
		"relocate_video",
		"triple_buffer",
		"readImage_display",
		"play_video",
		"set_zoom",
		"stress_test_vidx",
		"stress_test_osd",
//		"blankUnblank_screen",
		"close_device",
		"help"
	};
	
	while(1)
	{
		i=0;
		printTerminalf("vpbe>> ");
		scanTerminalf("%s", cmd);
		if(0 == strcmp(cmd, "exit"))
		{
			printTerminalf("Exiting VPBE Mode to Main Parser\n");	
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_open_device();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_mmap_vidx();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_create_blend();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_create_blend_ioctl();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_image_vidx();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_changeResolution_vidx();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_setScreenInfo_vidx();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_getScreenInfo_vidx();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_get_standard();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_get_fixScreenInfo_vidx();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_relocate_vidx();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_tripleBuffer_vidx();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_readImage_display();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_play_video();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_set_zoom();
		}

		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_stress_test_vid();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_stress_test_osd();
		}
//		else if(0 == strcmp(cmd, cmdlist[i++]))
//		{
//			test_vpbe_blankUnblankScreen_vidx();
//		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_vpbe_close_device();
		}
		else 
		{
			int j=0;
			printTerminalf("Available VPBE Functions: \n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf("%s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	}
}


void  test_vpbe_get_standard()
{
	int retval;
	int framebuffer_to_open;
        printTerminalf("Enter the Framebuffer Opened: \n");
        scanTerminalf("%d",&framebuffer_to_open);
	retval=test_vpbe_interface_get_standard(framebuffer_to_open);
	if (retval<0)
	{
	printTerminalf("IOCTL FBIO_GETSTD Failed.\n");
	}

	else
	{
		printTerminalf("IOCTL FBIO_GETSTD Successful.\n");
	}

}






void test_vpbe_set_zoom()
{

	int window_ID;
	int retval;
	int zoom_hvalue,zoom_vvalue;
	int framebuffer_to_open;
        printTerminalf("Enter the Framebuffer Opened: \n");
        scanTerminalf("%d",&framebuffer_to_open);

        printTerminalf("Enter the Window ID: \n");
        printTerminalf("0: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("1: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("2: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&window_ID);
	
        printTerminalf("Enter the horizontal zoom value: \n");
        scanTerminalf("%d",&zoom_hvalue);
        printTerminalf("Enter the vertical zoom value: \n");
        scanTerminalf("%d",&zoom_vvalue);


        retval=	test_vpbe_interface_set_zoom(framebuffer_to_open,window_ID,zoom_hvalue,zoom_vvalue);
	if(retval <0)
	{

        	printTerminalf("Error setting Zoom. ERROR::%d\n",errno);
	}
	else
	{
	
        	printTerminalf("Zoom Sucessful\n");
	}

}

void test_vpbe_mmap_vidx()
{

	int framebuffer_to_open;
	int retval;
        printTerminalf("Enter the framebuffer opened to be memory mapped: \n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("2: OSD1 (%s)\n", fb_dev_names[VPBE_OSD1_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer_to_open);
	
        retval=	test_vpbe_interface_mmap_vidx(framebuffer_to_open);
	switch(retval)
	{
					
		case -1:
		 	printTerminalf("IOCTL FBIOGET_VSCREENINFO Failed .ERROR::%d\n",errno);
			break;
		default:
		        printTerminalf("Memory Mapping sucessful.\n");
	
	}
}

void test_vpbe_play_video()
{
	int framebuffer_to_open;
	int retval;
        printTerminalf("Enter the framebuffer opened: \n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer_to_open);
	
        retval=	test_vpbe_interface_play_video(framebuffer_to_open);
	switch(retval)
	{
					
		case -1:
		 	printTerminalf("Buffer memory allocation for buffer-1 failed.ERROR::%d\n",errno);
			break;
		case -2:
		 	printTerminalf("Buffer memory allocation for buffer-2 failed.ERROR::%d\n",errno);
			break;
		case -3:
	               	printTerminalf("file opening (video file) failed.ERROR::%d\n",errno);
			break;
		case -4:
	               	printTerminalf("fread(for frame_buffer1) function failed.ERROR::%d\n",errno);
			break;
		case -5:
	               	printTerminalf("fread(for frame_buffer2) function failed.ERROR::%d\n",errno);
			break;
		case -6:
	               	printTerminalf("memory unmapping failed.ERROR::%d\n",errno);	
			break;
		case -7:
	               	printTerminalf("IOCTL FBIOPAN_DISPLAY Failed.ERROR::%d\n",errno);	
			break;
		case -8:
	               	printTerminalf("memory FBIO_WAITFORVSYNC failed.ERROR::%d\n",errno);	
			break;
		case -9:
	               	printTerminalf("IOCTL FBIOGET_VSCREENINFO Failed.ERROR::%d\n",errno);	
			break;
		default:
		        printTerminalf("Video display sucessful.\n");
	
	}
}


void test_vpbe_create_blend_ioctl()
{

	int blend_value;
	int retval;
	int framebuffer_to_open;
	framebuffer_to_open=2;
	printTerminalf("Enter the blend value between 0-7:\nfor eg: \nblend-0:VID-visible OSD-invisible\nblend-7:OSD-visible VID-invisible: \n");
	scanTerminalf("%d",&blend_value);

	retval= test_vpbe_interface_create_blend_ioctl(framebuffer_to_open,blend_value);
	if(retval <0)
	{
        	printTerminalf("blend setting failed IOCTL FBIO_SETATTRIBUTE Failed. Error::%d \n",errno);
	}
	else
	{
        	printTerminalf("blend implementation through ioctl FBIO_SETATTRIBUTE Sucess.\n");
	}
}


void test_vpbe_create_blend(void)
{
	int blend_value;
	int retval;
	int framebuffer_to_open;
	framebuffer_to_open=2;
	printTerminalf("Enter the blend value between 0-7:\nfor eg: \nblend-0:VID-visible OSD-invisible\nblend-7:OSD-visible VID-invisible: \n");
	scanTerminalf("%d",&blend_value);

	retval= test_vpbe_interface_create_blend(framebuffer_to_open,blend_value);
	switch(retval)
	{
		case -1:
		 	printTerminalf("File open failed.ERROR::%d\n",errno);
			break;
		case -2:
			printTerminalf("write function failed.ERROR::%d\n",errno);
			break;
		case -3:
	               	printTerminalf("fopen function failed.ERROR::%d\n",errno);
			break;
		case -4:
	               	printTerminalf("fseek function failed.ERROR::%d\n",errno);
			break;
		case -5:
	               	printTerminalf("ftell function failed.ERROR::%d\n",errno);
			break;
		case -6:
	               	printTerminalf("buffer memory allocation failed.ERROR::%d\n",errno);	
			break;
		case -7:
	               	printTerminalf("buffer memory unmapping failed.ERROR::%d\n",errno);	
			break;
		default:
		        printTerminalf("Blend sucessful.\n");
	
	}

}



void test_vpbe_close_device(void)
{
	int framebuffer_to_close=0, retval;

        printTerminalf("Enter the framebuffer to be closed: \n");
	printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]); 
	printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]); 
	printTerminalf("2: OSD1 (%s)\n", fb_dev_names[VPBE_OSD1_FRAMEBUFFER]); 
	printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]); 
	scanTerminalf("%d",&framebuffer_to_close);

	retval = test_vpbe_interface_closeDevice(framebuffer_to_close);
	if(retval < 0)
	{
		printTerminalf("Device close failed:Retval:%d::ERROR::%d\n",retval,errno);

	}
	else
	{
		printTerminalf("Device close SUCCESS\n");

	}

}

void test_vpbe_stress_test_osd(void)
{
	int retval;
	int framebuffer_to_open;
	printTerminalf("\n Enter the framebuffer(for osd) to be opened: ");
	scanTerminalf("%d",&framebuffer_to_open);
	retval=test_vpbe_interface_stress_test_osd(framebuffer_to_open);
	if(retval<0)
	{
		printTerminalf("Stress test failed.Retval::%d. Error::%d",retval,errno);
	}
	else
	{
		printTerminalf("Stress test success.");
	}
	
}


void test_vpbe_stress_test_vid(void)
{
	int retval;
	int framebuffer_to_open;
	printTerminalf("\n Enter the framebuffer(for VID,i.e 1 or 3) to be opened: ");
	scanTerminalf("%d",&framebuffer_to_open);
	retval=test_vpbe_interface_stress_test_vid(framebuffer_to_open);
	if(retval<0)
	{
		printTerminalf("\nStress test failed.Retval::%d. Error::%d",retval,errno);
	}
	else
	{
		printTerminalf("\nStress test Success.\n");
	}
	
}


void test_vpbe_readImage_display(void)
{
	int framebuffer_to_open;
	int retval;
        printTerminalf("Enter the framebuffer opened: \n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer_to_open);
	
        
	retval=	test_vpbe_interface_readImage_display(framebuffer_to_open);
	switch(retval)
	{
		case -1:
		 	printTerminalf("File open failed.ERROR::%d\n",errno);
			break;
		case -2:
			printTerminalf("fseek function failed.ERROR::%d\n",errno);
			break;
		case-3:
	               	printTerminalf("ftell function failed.ERROR::%d\n",errno);
			break;
		case-4:
	               	printTerminalf("fread function failed.ERROR::%d\n",errno);
			break;
		case-5:
	               	printTerminalf("memory unmapping failed.ERROR::%d\n",errno);
			break;
		case-6:
	               	printTerminalf("buffer memory allocation failed.ERROR::%d\n",errno);
			break;
		default:
		        printTerminalf("\n");
	}


}



void test_vpbe_tripleBuffer_vidx(void)
{

	int framebuffer_to_open;
	int retval;
        printTerminalf("Enter the framebuffer to be triple buffered \n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer_to_open);

	retval=	test_vpbe_interface_tripleBuffer_vidx(framebuffer_to_open);
	switch(retval)
	{
                case -1:
                        printTerminalf("IOCTL FBIOGET_VSCREENINFO Failed.ERROR::%d\n",errno);
                        break;
                case -2:
                        printTerminalf("IOCTL FBIOPAN_DISPLAY Failed.ERROR::%d\n",errno);
                        break;
		default:
                        printTerminalf("Display Panning Successful.\n");
                        break;
        }
	
	return;

	
}


void test_vpbe_relocate_vidx(void)
{

	int framebuffer;
	int retval;
        printTerminalf("Enter the framebuffer to get its unchangeable info\n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer);

	retval=	test_vpbe_interface_relocate_vidx(framebuffer);
	if(retval<0)
	{

		printTerminalf(" Failed IOCTL FBIOPUT_VSCREENINFO Retval:%d:Error::%d\n",retval,errno);
	}
	else
	{
		printTerminalf("Successfully relocated video window.\n");
			
	}

	return;
}



/*
void test_vpbe_blankUnblankScreen_vidx(void)
{
	int framebuffer;
	int retval;
        printTerminalf("Enter the framebuffer to get its unchangeable info\n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("2: OSD1 (%s)\n", fb_dev_names[VPBE_OSD1_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer);
	retval=	test_vpbe_interface_blankUnblankScreen_vidx(framebuffer);
	if(retval<0)
	{
		
		printTerminalf("Ioctl FBIOBLANK Failed.Retval:%d:Error::%d\n",retval,errno);
	}
	else
	{
		printTerminalf("Ioctl FBIOBLANK Success.\n");
			
	}

	return;
}*/



void test_vpbe_get_fixScreenInfo_vidx(void)
{
	int framebuffer;
	int retval;
        printTerminalf("Enter the framebuffer to get its unchangeable info\n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer);

	
	retval=	test_vpbe_interface_get_fix_ScreenInfo_vidx(framebuffer);
	if(retval<0)
	{
		
		printTerminalf("Ioctl FBIOGET__FSCREENINFO Failed:Retval:%d:Error::%d\n",retval,errno);
	}
	else
	{
		printTerminalf("Fixed Screen Info:\n length of frame buffer memory:%d\n XPanStep:%d\n YPanStep:%d \n Linelength:%d\n starting address(MMIO):%u\n",finfo_vidx[framebuffer].smem_len,finfo_vidx[framebuffer].xpanstep,finfo_vidx[framebuffer].ypanstep,finfo_vidx[framebuffer].line_length,finfo_vidx[framebuffer].mmio_start);
		
		printTerminalf("Fixed Information displayed successfully.\n");
			
	}
	return;
}

void test_vpbe_setScreenInfo_vidx()
{
        int framebuffer=0;
        int retval;
	int picHeight,picWidth;
	int picGrayScale;

        printTerminalf("Enter the framebuffer to set the screen info\n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer);
        printTerminalf("Enter the height and width like(100X100)\n");
        scanTerminalf("%d",&picHeight);
        scanTerminalf("%d",&picWidth);
        printTerminalf("Enter the grayScale like(0,1,2)\n");
        scanTerminalf("%d",&picGrayScale);
	retval=	test_vpbe_interface_setScreenInfo_vidx(framebuffer,picHeight,picWidth,picGrayScale);
	if(retval < 0)
	{
			printTerminalf("Ioctl FBIOPUT_VSCREENINFO Failed:%d\n",errno);
	}
	else
	{	
			printTerminalf("Ioctl FBIOPUT_VSCREENINFO Success.\n");
	}
	return;
	
}
			
void test_vpbe_open_device(void)
{
	int framebuffer_to_open=0, retval;

	printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]); 
	printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]); 
	printTerminalf("2: OSD1 (%s)\n", fb_dev_names[VPBE_OSD1_FRAMEBUFFER]); 
	printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]); 
	scanTerminalf("%d",&framebuffer_to_open);

	retval = test_vpbe_interface_open_fb(framebuffer_to_open);
	switch(retval)
	{
		case -1:
			printTerminalf("IOCTL FBIOGET_FSCREENINFO Failed: %d\n", errno);
			break;
		case -2:
			printTerminalf("IOCTL FBIOGET_VSCREENINFO Failed: %d\n",errno);
			break;
		
		case -3:
			printTerminalf("Framebuffer opening failed Error::%d\n",errno);
			break;
		default:
			printTerminalf("Frame buffer %s openned successfully\n", fb_dev_names[framebuffer_to_open]);
			break;
	}

	return;
}

void test_vpbe_image_vidx(void)
{     
	int framebuffer=0;
	int retval;

	printTerminalf("enter the framebuffer\n");
	printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]); 
	printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]); 
	scanTerminalf("%d",&framebuffer);

	retval = test_vpbe_interface_image_display(framebuffer);
	if(retval < 0)
	{
		printTerminalf("Image Display Failed. Error::%d\n",retval);
	}
	else
	{
		printTerminalf("Image Displayed Successfully\n");
	}
	
	return;
}

void test_vpbe_changeResolution_vidx(void)
{
        int framebuffer=0;
        int retval,xVal,yVal;

        printTerminalf("Enter the framebuffer\n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer);
       	printTerminalf("Current Video image paramters: %s :: %dx%d :: %dbpp\n",fb_dev_names[framebuffer], vinfo_vidx[framebuffer].xres,vinfo_vidx[framebuffer].yres, vinfo_vidx[framebuffer].bits_per_pixel );
        printTerminalf("Enter the size of X and Y resolution like(720X480,320X240,720X240,360X480)\n");
        scanTerminalf("%d",&xVal);
        scanTerminalf("%d",&yVal);

        retval = test_vpbe_resize_interface_image_display(framebuffer,xVal,yVal);
        //printTerminalf("Return Value::::%d\n",retval);
        switch(retval)
        {
         //       case -1:
         //               printTerminalf("Mapping framebuffer device to memory is failed. Error::%d\n", errno);
         //               break;
         //       case -2:
         //               printTerminalf("Modifying image size is failed. Error::%d\n", errno);
         //             break;
                  case -3:
                        printTerminalf("IOCTL FBIOPUT_VSCREENINFO Failed. Error::%d\n", errno);
                        break;
		default:
                        printTerminalf("Modified image Displayed Successfully\n");
                        break;
        }
	
	return;
}



void test_vpbe_getScreenInfo_vidx(void)
{

        int framebuffer=0;
        int retval;

        printTerminalf("Enter the framebuffer\n");
        printTerminalf("0: OSD0 (%s)\n", fb_dev_names[VPBE_OSD0_FRAMEBUFFER]);
        printTerminalf("1: VID0 (%s)\n", fb_dev_names[VPBE_VID0_FRAMEBUFFER]);
        printTerminalf("2: OSD1 (%s)\n", fb_dev_names[VPBE_OSD1_FRAMEBUFFER]);
        printTerminalf("3: VID1 (%s)\n", fb_dev_names[VPBE_VID1_FRAMEBUFFER]);
        printTerminalf("\n");
        scanTerminalf("%d",&framebuffer);
	
	retval=	test_vpbe_interface_getScreenInfo_vidx( framebuffer);
	if(retval < 0)
	{
			printTerminalf("Ioctl FBIOGET_VSCREENINFO Failed:%d\n",errno);
	}
	else
	{	
			printTerminalf("Ioctl FBIOGET_VSCREENINFO Success.\n");
			printTerminalf("\n Variable Screen Information:%s\n Resolution: %dx%d\n Bits Per Pixel: %dbpp\nVirtual Resolutions\n xres_virtual: %d\n yres_virtual: %d\nOffset form virtual to visible\n x-offset:%d\n y-offset:%d\n",fb_dev_names[framebuffer], vinfo_vidx[framebuffer].xres,vinfo_vidx[framebuffer].yres, vinfo_vidx[framebuffer].bits_per_pixel,vinfo_vidx[framebuffer].xres_virtual,vinfo_vidx[framebuffer].yres_virtual,vinfo_vidx[framebuffer].xoffset,vinfo_vidx[framebuffer].yoffset);
		//	printTerminalf("height:%d\nwidth:%d\n",vinfo_vidx[framebuffer].height,vinfo_vidx[framebuffer].width);
			printTerminalf("GrayScale:%d\n",vinfo_vidx[framebuffer].grayscale);
	}
	return;
}

