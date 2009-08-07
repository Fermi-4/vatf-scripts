/* This file contains the DM355 Specific APIs,Constants and Global Variables declarations used for the initialization, Configuration and usage of VPFE modules provided in the Linux Support package version 2.10 for DM355 platform

			Author	: 	Arun Vijay Mani
			Date	:	06/17/2008
			Version	:	0.1
***************************************************************************************************************************/
#include <linux/videodev.h>
#include <media/davinci/davinci_vpfe.h>
#include <media/davinci/ccdc_dm355.h>
#include <media/davinci/tvp5146.h>
#include <media/davinci/mt9t001.h>

// Constants

#define VID_IN0_DEV "/dev/video0"
#define VID_IN0 0
#define YUV_CAP 0
#define CLEAR(x) memset (&(x), 0, sizeof (x))


int Vpfe_Open(int device_id, int mode);
int Vpfe_Open_Close(int ch);
int Init_Capture(int fd, int ip_type, int ch, int plat);
int V4l2_Cap_std_Ioctl(int fd, int stds );
int V4l2_Cap_fmt_Ioctl(int fd, int fmts );
int V4l2_Cap_crop_Ioctl(int fd);
int V4l2_Cap_buf_Ioctl(int fd, int bufs );
int V4l2_cap_std_neg(int fd_cap, int val_ioctl, int neg_val);
int V4l2_cap_fmt_neg(int fd_cap, int val_ioctl, int neg_val);
int V4l2_cap_crop_neg(int fd_cap, int val_ioctl);
int V4l2_cap_buf_neg(int fd_cap, int val_ioctl, int neg_val);
int Init_Fmt_Cap(int fd,  v4l2_std_id std_format, int cap_width, int cap_height, int device_type);
int Init_Cap_Crop(int fd, int width, int height, int top, int left);
int Init_Cap_Buffer(int fd, int buf_count);
int Start_Streaming(int fd, int buf_count);
int Init_Camera_Cap(int fd, void * raw_params);


