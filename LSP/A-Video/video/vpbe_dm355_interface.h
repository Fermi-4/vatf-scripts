/* This file contains the DM355 Specific APIs,Constants and Global Variables declarations used for the initialization, Configuration and usage of VPBE modules provided in the Linux Support package version 2.10 for DM355 platform

			Author	: 	Arun Vijay Mani
			Date	:	06/17/2008
			Version	:	0.1
***************************************************************************************************************************/
#include <linux/videodev.h>
#include <media/davinci/davinci_vpfe.h>

// Constants

#define VID_OUT0_DEV "/dev/video2"
#define VID_OUT1_DEV "/dev/video3"
#define VID_OUT0 0
#define VID_OUT1 1
#define STD_NTSC 0
#define STD_PAL 1

#define CLEAR(x) memset (&(x), 0, sizeof (x))

int V4l2_Vpbe_Open(int device_id, int mode);
int V4l2_Vpbe_Init(int fd, int vid_type, int vid_std);
int Init_Vpbe_Fmt(int fd, int width, int height);
int Init_Vpbe_Cap(int fd, int width, int height, int top, int left);
int Init_Vpbe_Buffer(int fd, int buf_count);
int Start_Disp_Streaming(int fd, int buf_count);
int DisplayFrame(int fd, void * ptrbuffer, int width, int height);
int putDisplayBuffer(int fd, void * addr);
void * getDisplayBuffer(int fd);




