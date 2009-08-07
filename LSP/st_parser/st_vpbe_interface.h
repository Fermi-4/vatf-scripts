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

#ifndef __ST_VPBE
#define __ST_VPBE

int test_vpbe_interface_open_fb(int);

int test_vpbe_resize_interface_image_display(int,int,int);
int test_vpbe_interface_image_display(int framebuffer);
int test_vpbe_interface_getScreenInfo_vidx(int);
int test_vpbe_interface_setScreenInfo_vidx(int,int,int,int);
int test_vpbe_interface_get_fix_ScreenInfo_vidx(int);
int test_vpbe_interface_blankUnblankScreen_vidx(int framebuffer);
int test_vpbe_interface_relocate_vidx(int framebuffer);
int test_vpbe_intrface_tripleBuffer_vidx(int);
int test_vpbe_interface_readImage_display(int framebuffer_to_open);
int test_vpbe_interface_flip_to_buffer(int number,int framebuffer);
int test_vpbe_interface_closeDevice(int framebuffer_to_close);
int test_vpbe_interface_stress_test_vid(int framebuffer_to_open);
int test_vpbe_interface_stress_test_osd(int framebuffer_to_open);
int test_vpbe_interface_create_blend(int framebuffer_to_open,int blend_value);
int test_vpbe_interface_create_blend_ioctl(int framebuffer_to_open,int blend_value);
int test_vpbe_interface_play_video(int framebuffer_to_open);
int test_vpbe_interface_mmap_vidx(int framebuffer_to_open);
int test_vpbe_interface_set_zoom(int framebuffer_to_open,int window_ID,int zoom_hvalue,int zoom_vvalue);
int test_vpbe_interface_get_standard(int framebuffer_to_open);

#endif
