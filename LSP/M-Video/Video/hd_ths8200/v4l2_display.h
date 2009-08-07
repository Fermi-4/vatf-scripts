#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>	
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include <asm/types.h>
#include <linux/videodev.h>
#include <media/davinci/davinci_vpfe.h>
#include <media/davinci/davinci_display.h>
#include <media/davinci/tvp514x.h>
#include <media/davinci/tvp7002.h>

#include <linux/fb.h>
//#include <video/davincifb.h>
//#include <video/davincifb_ioctl.h>

#define CAPTURE_DEVICE "/dev/video0"



extern int platform;
extern int vid0_driver;
extern int vid1_driver;
extern int vid_output;
extern int vid_input;
extern int vid_fmt;
extern int osd0_en;
extern int osd1_en;
extern int blend_no;
extern int fdcap;
extern int fddisp0;
extern int fddisp1;
extern int fdosd0;
extern int cap_plane;
extern int WIDTH;
extern int HEIGHT;
extern int IN_WIDTH;
extern int IN_HEIGHT;

int Init_display( int );
int Init_osd0( );
int startloop ( int , int );
int DisplayFrame ( int , void * );
void *getDisplayBuffer ( int );
int putDisplayBuffer ( int , void *);
int display_osd0 ( );
//int stream_disp ( int );
