#include <stdio.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <getopt.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <linux/videodev.h>
#include <linux/videodev2.h>
#include <media/davinci/davinci_vpfe.h>	
#include <media/davinci/ccdc_dm365.h>
#include <asm/arch/imp_previewer.h>
#include <asm/arch/imp_resizer.h>
#include <asm/arch/dm365_ipipe.h>

char dev_name_prev[1][30] = {"/dev/davinci_previewer"};
char dev_name_rsz[1][30] = {"/dev/davinci_resizer"};

#define APP_NUM_BUFS 4
#define CAPTURE_DEVICE  "/dev/video0"
//#define CAP_FORMAT1		(V4L2_STD_MT9T001_VGA_30FPS)
#define CAP_FORMAT1		VPFE_STD_AUTO
#define V4L2VID0_DEVICE    "/dev/video2"
#define V4L2VID1_DEVICE    "/dev/video3"
#define CLEAR(x) memset (&(x), 0, sizeof (x))

/* 0 - UYVY, 1 - NV12 */
int out_format=0;

#define IN_WIDTH 	1280	
#define IN_HEIGHT 	720	
#define OUT_WIDTH 	1280
#define OUT_HEIGHT 	720
#define BYTESPERPIXEL   2
#define WIDTH_NTSC		720
#define HEIGHT_NTSC		480
#define WIDTH_PAL		720
#define HEIGHT_PAL		576
#define WIDTH_720P		1280
#define HEIGHT_720P		720	
#define WIDTH_1080I		1920
#define HEIGHT_1080I		1080
#define DISPLAY_INTERFACE_COMPOSITE	"COMPOSITE"
#define DISPLAY_INTERFACE_COMPONENT	"COMPONENT"
#define DISPLAY_MODE_PAL	"PAL"
#define DISPLAY_MODE_NTSC	"NTSC"
#define DISPLAY_MODE_720P	"720P-60"		
#define DISPLAY_MODE_1080I	"1080I-30"	

/* Standards and output information */
#define ATTRIB_MODE		"mode"
#define ATTRIB_OUTPUT		"output"

int in_width = IN_WIDTH, in_height = IN_HEIGHT;
int out_width = OUT_WIDTH, out_height = OUT_HEIGHT;
static int printfn = 1;
int input_index = 0;
int rsz_opt = 0;
char *inputs[] = { "COMPOSITE", "SVIDEO", "COMPONENT" };
static struct v4l2_cropcap cropcap;
static int nWidthFinal;
static int nHeightFinal;
static int stress_test = 1;
static v4l2_std_id cur_std;
static int rsz_fd, prev_fd;
static int start_loopCnt = 500;

struct app_buf_type {
    void *start;
    int offset;
    int length;
    int index;
};
	
struct app_buf_type capture_buffers[APP_NUM_BUFS];
struct app_buf_type prev_rsz_out_buffers1[APP_NUM_BUFS];
struct app_buf_type prev_rsz_out_buffers2[APP_NUM_BUFS];
struct app_buf_type display_buffers[APP_NUM_BUFS];

static int display_image_size;
/*******************************************************************************
 *	Function will use the SysFS interface to change the output and mode
 */
static int change_sysfs_attrib(char *attribute, char *value)
{
	int sysfd = -1;
	char init_val[32];
	char attrib_tag[128];

	bzero(init_val, sizeof(init_val));
	strcpy(attrib_tag, "/sys/class/davinci_display/ch0/");
	strcat(attrib_tag, attribute);

	sysfd = open(attrib_tag, O_RDWR);
	if (!sysfd) {
		printf("Error: cannot open %d\n", sysfd);
		return -1;
	}
	printf("%s was opened successfully\n", attrib_tag);

	read(sysfd, init_val, 32);
	lseek(sysfd, 0, SEEK_SET);
	printf("Current %s value is %s\n", attribute, init_val);
	write(sysfd, value, 1 + strlen(value));
	lseek(sysfd, 0, SEEK_SET);

	memset(init_val, '\0', 32);
	read(sysfd, init_val, 32);
	lseek(sysfd, 0, SEEK_SET);
	printf("Changed %s to %s\n", attribute, init_val);

	close(sysfd);
	return 0;
}

void usage()
{
	printf("Usage:capture_prev_rsz_onthe_fly\n");
}

int init_resizer(unsigned int user_mode)
{
	int rsz_fd;
	unsigned int oper_mode;
	struct rsz_channel_config rsz_chan_config;
	struct rsz_continuous_config rsz_cont_config; // continuous mode
	printf("opening resize device\n");
	rsz_fd = open((const char *)dev_name_rsz[0], O_RDWR);
	if(rsz_fd <= 0) {
		printf("Cannot open resize device \n");
		return -1;
	}

	if (ioctl(rsz_fd, RSZ_S_OPER_MODE, &user_mode) < 0) {
		perror("Can't get operation mode\n");
		close(rsz_fd);
		return -1;
	}

	if (ioctl(rsz_fd, RSZ_G_OPER_MODE, &oper_mode) < 0) {
		perror("Can't get operation mode\n");
		close(rsz_fd);
		return -1;
	}

	if (oper_mode == user_mode) 
		printf("Successfully set mode to continuous in resizer\n");
	else {
		printf("failed to set mode to continuous in resizer\n");
		close(rsz_fd);
		return -1;
	}
		
	// set configuration to chain resizer with preview
	rsz_chan_config.oper_mode = user_mode;
	rsz_chan_config.chain  = 1;
	rsz_chan_config.len = 0;
	rsz_chan_config.config = NULL; /* to set defaults in driver */
	if (ioctl(rsz_fd, RSZ_S_CONFIG, &rsz_chan_config) < 0) {
		perror("Error in setting default configuration in resizer\n");
		close(rsz_fd);
		return -1;
	}
	
	printf("default configuration setting in Resizer successfull\n");
	bzero(&rsz_cont_config, sizeof(struct rsz_continuous_config));
	rsz_chan_config.oper_mode = user_mode;
	rsz_chan_config.chain = 1;
	rsz_chan_config.len = sizeof(struct rsz_continuous_config);
	rsz_chan_config.config = &rsz_cont_config;

	if (ioctl(rsz_fd, RSZ_G_CONFIG, &rsz_chan_config) < 0) {
		perror("Error in getting resizer channel configuration from driver\n");
		close(rsz_fd);
		return -1;
	}
		
	// we can ignore the input spec since we are chaining. So only
	// set output specs
	rsz_cont_config.output1.enable = 1;
	rsz_cont_config.output2.enable = 0;
	rsz_chan_config.len = sizeof(struct rsz_continuous_config);
	rsz_chan_config.config = &rsz_cont_config;
	if (((cur_std & V4L2_STD_720P_60) ||
		   (cur_std & V4L2_STD_720P_50)) && (rsz_opt < 2)) {
		/*printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_720P, HEIGHT_720P);
		in_width = fmt.fmt.pix.width = WIDTH_720P;
		in_height = fmt.fmt.pix.height = HEIGHT_720P;*/
		//fmt.fmt.pix.field = V4L2_FIELD_NONE;
		rsz_cont_config.output1.en_down_scale = 1;
		rsz_cont_config.output1.h_dscale_ave_sz = IPIPE_DWN_SCALE_1_OVER_2;
		rsz_cont_config.output1.v_dscale_ave_sz = IPIPE_DWN_SCALE_1_OVER_2;
	} else if (((cur_std & V4L2_STD_1080I_60) ||
		   (cur_std & V4L2_STD_1080I_50)) && (rsz_opt < 2)) {
	/*	printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_1080I, HEIGHT_1080I);
		in_width = fmt.fmt.pix.width = WIDTH_1080I;
		in_height = fmt.fmt.pix.height = HEIGHT_1080I;*/
		//fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		rsz_cont_config.output1.en_down_scale = 1;
		rsz_cont_config.output1.h_dscale_ave_sz = IPIPE_DWN_SCALE_1_OVER_2;
		rsz_cont_config.output1.v_dscale_ave_sz = IPIPE_DWN_SCALE_1_OVER_2;
	}

	if (ioctl(rsz_fd, RSZ_S_CONFIG, &rsz_chan_config) < 0) {
		perror("Error in setting configuration in resizer\n");
		close(rsz_fd);
		return -1;
	}
	printf("Resizer initialized\n");
	return rsz_fd;
}

int init_previewer(unsigned int user_mode)
{
	
	int preview_fd;
	unsigned int oper_mode;
	struct prev_channel_config prev_chan_config;
	struct prev_continuous_config prev_cont_config; // continuous mode
	

	preview_fd = open((const char *)dev_name_prev[0], O_RDWR);
	if(preview_fd <= 0) {
		printf("Cannot open previewer device\n");
		return -1;
	}

	if (ioctl(preview_fd,PREV_S_OPER_MODE, &user_mode) < 0) {
		perror("Can't get operation mode\n");
		close(preview_fd);
		return -1;
	}

	if (ioctl(preview_fd,PREV_G_OPER_MODE, &oper_mode) < 0) {
		perror("Can't get operation mode\n");
		close(preview_fd);
		return -1;
	}

	if (oper_mode == user_mode) 
		printf("Operating mode changed successfully to continuous in previewer");
	else {
		printf("failed to set mode to continuous in resizer\n");
		close(preview_fd);
		return -1;
	}

	printf("Setting default configuration in previewer\n");
	prev_chan_config.oper_mode = oper_mode;
	prev_chan_config.len = 0;
	prev_chan_config.config = NULL; /* to set defaults in driver */
	if (ioctl(preview_fd, PREV_S_CONFIG, &prev_chan_config) < 0) {
		perror("Error in setting default configuration\n");
		close(preview_fd);
		return -1;
	}

	printf("default configuration setting in previewer successfull\n");
	prev_chan_config.oper_mode = oper_mode;
	prev_chan_config.len = sizeof(struct prev_continuous_config);
	prev_chan_config.config = &prev_cont_config;

	if (ioctl(preview_fd, PREV_G_CONFIG, &prev_chan_config) < 0) {
		perror("Error in getting configuration from driver\n");
		close(preview_fd);
		return -1;
	}
	
	prev_chan_config.oper_mode = oper_mode;
	prev_chan_config.len = sizeof(struct prev_continuous_config);
	prev_chan_config.config = &prev_cont_config;
	
	if (ioctl(preview_fd, PREV_S_CONFIG, &prev_chan_config) < 0) {
		perror("Error in setting default configuration\n");
		close(preview_fd);
		return -1;
	}

	printf("previewer initialized\n");
	return preview_fd;
}

/******************************************************************************/
static int set_data_format(int fdCapture)
{
	v4l2_std_id std;
	struct v4l2_format fmt;
	unsigned int min;
	struct v4l2_input input;
	int temp_input;
	int input_detected = 0;


	// first set the input
	input.type = V4L2_INPUT_TYPE_CAMERA;
	input.index = 0;
	printf("Detecting if driver supports %s\n", inputs[input_index]); 
  	while (0 == ioctl(fdCapture,VIDIOC_ENUMINPUT, &input)) { 
		printf("input.name = %s\n", input.name);
		if (!strcmp(input.name, inputs[input_index])) {
			input_detected = 1;
			break;
		}
		input.index++;
  	}

	if (!input_detected) {
		perror("Can't detect input  from the capture driver\n");
		return -1;
	} 

  	if (-1 == ioctl (fdCapture, VIDIOC_S_INPUT, &input.index))
  	{
		printf ("InitDevice:ioctl:VIDIOC_S_INPUT\n");
      		return -1;
  	}
	if (-1 == ioctl (fdCapture, VIDIOC_G_INPUT, &temp_input))
	{
		printf ("error: InitDevice:ioctl:VIDIOC_G_INPUT\n");
		return -1;
	}
	
	if (temp_input == input.index)
		printf ("InitDevice:ioctl:VIDIOC_G_INPUT, selected INPUT input \n");
	else {
		printf ("InitDevice:ioctl:VIDIOC_G_INPUT, Couldn't select input\n");
		return -1;
  	}

	if (-1 == ioctl(fdCapture, VIDIOC_QUERYSTD, &std)) {
		printf("set_data_format:ioctl:VIDIOC_QUERYSTD:\n");
		return -1;
	}

	cur_std = std;
	if (std & V4L2_STD_NTSC)
		printf("Input video standard is NTSC.\n");
	else if (std & V4L2_STD_PAL)
		printf("Input video standard is PAL.\n");
	else if (std & V4L2_STD_PAL_M)
		printf("Input video standard is PAL-M.\n");
	else if (std & V4L2_STD_PAL_N)
		printf("Input video standard is PAL-N.\n");
	else if (std & V4L2_STD_SECAM)
		printf("Input video standard is SECAM.\n");
	else if (std & V4L2_STD_PAL_60)
		printf("Input video standard to PAL60.\n");
	else if (std & V4L2_STD_720P_60)
		printf("Input video standard to 720p-60.\n");
	else if (std & V4L2_STD_1080I_60)
		printf("Input video standard to 1080I-60.\n");
	else if (std & V4L2_STD_1080I_50)
		printf("Input video standard to 1080I-50.\n");
	else if (std & V4L2_STD_720P_50)
		printf("Input video standard to 720p-50.\n");
	else if (std & V4L2_STD_525P_60)
		printf("Input video standard to 525p-60.\n");
	else if (std & V4L2_STD_625P_50)
		printf("Input video standard to 625p-50.\n");
	else {
		printf("Detection failed, std = %llx, %llx\n", std, V4L2_STD_NTSC);
		return -1;
	}

	/* select cropping as deault rectangle */
	cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

	if (-1 == ioctl(fdCapture, VIDIOC_CROPCAP, &cropcap)) {
		printf("InitDevice:ioctl:VIDIOC_CROPCAP\n");
		/* ignore error */
	}

	printf("Default crop capbility bounds - %d %d %d %d"
	       " ; default - %d %d %d %d \n",
	       cropcap.bounds.left, cropcap.bounds.top,
	       cropcap.bounds.width, cropcap.bounds.height,
	       cropcap.defrect.left, cropcap.defrect.top,
	       cropcap.defrect.width, cropcap.defrect.height);

	printf("set_data_format:setting data format\n");
	CLEAR(fmt);
#if 1
	if (std & V4L2_STD_NTSC) {
		/*printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_NTSC, HEIGHT_NTSC);
		in_width = fmt.fmt.pix.width = WIDTH_NTSC;
		in_height = fmt.fmt.pix.height = HEIGHT_NTSC;*/
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	} else if (std & V4L2_STD_525P_60) {
		/*printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_NTSC, HEIGHT_NTSC);
		in_width = fmt.fmt.pix.width = WIDTH_NTSC;
		in_height = fmt.fmt.pix.height = HEIGHT_NTSC;*/
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	} else if ((std & V4L2_STD_PAL) ||
		(std & V4L2_STD_PAL_M) ||
		(std & V4L2_STD_PAL_N)) {
		/*printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_PAL, HEIGHT_PAL);
		in_width = fmt.fmt.pix.width = WIDTH_PAL;
		in_height = fmt.fmt.pix.height = HEIGHT_PAL;*/
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	} else if (std & V4L2_STD_625P_50) {
	/*	printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_PAL, HEIGHT_PAL);
		in_width = fmt.fmt.pix.width = WIDTH_PAL;
		in_height = fmt.fmt.pix.height = HEIGHT_PAL;*/
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	} else if ((std & V4L2_STD_720P_60) ||
		   (std & V4L2_STD_720P_50)) {
		/*printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_720P, HEIGHT_720P);
		in_width = fmt.fmt.pix.width = WIDTH_720P;
		in_height = fmt.fmt.pix.height = HEIGHT_720P;*/
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	} else if ((std & V4L2_STD_1080I_60) ||
		   (std & V4L2_STD_1080I_50)) {
	/*	printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_1080I, HEIGHT_1080I);
		in_width = fmt.fmt.pix.width = WIDTH_1080I;
		in_height = fmt.fmt.pix.height = HEIGHT_1080I;*/
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	}
#endif
	if (rsz_opt == 0) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_NTSC, HEIGHT_NTSC);
		in_width = fmt.fmt.pix.width = WIDTH_NTSC;
		in_height = fmt.fmt.pix.height = HEIGHT_NTSC;
		//fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	} else if (rsz_opt == 1) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_PAL, HEIGHT_PAL);
		in_width = fmt.fmt.pix.width = WIDTH_PAL;
		in_height = fmt.fmt.pix.height = HEIGHT_PAL;
		//fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	} else if (rsz_opt == 2) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_720P, HEIGHT_720P);
		in_width = fmt.fmt.pix.width = WIDTH_720P;
		in_height = fmt.fmt.pix.height = HEIGHT_720P;
		//fmt.fmt.pix.field = V4L2_FIELD_NONE;
	} else if (rsz_opt == 3) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_1080I, HEIGHT_1080I);
		in_width = fmt.fmt.pix.width = WIDTH_1080I;
		in_height = fmt.fmt.pix.height = HEIGHT_1080I;
		//fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	}

	out_width = in_width;
	out_height = in_height;

	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if (!out_format)
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	else
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_NV12;

	if (-1 == ioctl(fdCapture, VIDIOC_S_FMT, &fmt)) {
		printf("set_data_format:ioctl:VIDIOC_S_FMT\n");
		return -1;
	}

	if (-1 == ioctl(fdCapture, VIDIOC_G_FMT, &fmt)) {
		printf("set_data_format:ioctl:VIDIOC_QUERYSTD:\n");
		return -1;
	}

	nWidthFinal = fmt.fmt.pix.width;
	nHeightFinal = fmt.fmt.pix.height;

	printf("set_data_format:finally negotiated width:%d height:%d\n",
	       nWidthFinal, nHeightFinal);

	/* checking what is finally negotiated */
	min = fmt.fmt.pix.width * 2;
	if (fmt.fmt.pix.bytesperline < min) {
		printf
		    ("set_data_format:driver reports bytes_per_line:%d(bug)\n",
		     fmt.fmt.pix.bytesperline);
		/*correct it */
		fmt.fmt.pix.bytesperline = min;
	}

	min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
	if (fmt.fmt.pix.sizeimage < min) {
		printf("set_data_format:driver reports size:%d(bug)\n",
		       fmt.fmt.pix.sizeimage);

		/*correct it */
		fmt.fmt.pix.sizeimage = min;
	}
	printf("set_data_format:Finally negitaited width:%d height:%d\n",
	        nWidthFinal, nHeightFinal);
	return 0;
}

static int InitCaptureBuffers(int fdCapture)
{
	struct v4l2_requestbuffers req;
	int nIndex = 0, i;

	CLEAR(req);
	req.count = APP_NUM_BUFS;
	req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	req.memory = V4L2_MEMORY_MMAP;

	if (-1 == ioctl(fdCapture, VIDIOC_REQBUFS, &req)) {
		perror("InitCaptureBuffers:ioctl:VIDIOC_REQBUFS");
		return -1;
	} else
		printf("\nREQBUF Done\n");

	for (nIndex = 0; nIndex < req.count; ++nIndex) {

		struct v4l2_buffer buf;
		CLEAR(buf);
		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		buf.memory = V4L2_MEMORY_MMAP;
		buf.index = nIndex;

		if (-1 == ioctl(fdCapture, VIDIOC_QUERYBUF, &buf)) {
			perror
			    ("InitCaptureBuffers:ioctl:VIDIOC_QUERYBUF:\n");
			return -1;
		} else
			printf("\nQUERYBUF Done\n");

		capture_buffers[nIndex].length = buf.length;
		capture_buffers[nIndex].start =
		    mmap(NULL, buf.length, PROT_READ | PROT_WRITE,
			 MAP_SHARED, fdCapture, buf.m.offset);
		capture_buffers[nIndex].offset = buf.m.offset;

		if (MAP_FAILED == capture_buffers[nIndex].start) {
			perror("InitCaptureBuffers:mmap:");
			for (i = 0; i < nIndex; i++) {
				munmap(capture_buffers[i].start,
                capture_buffers[i].length);			
			}
			return -1;
		}
	}
	return 0;
}

int init_camera_capture(void)
{
	int capt_fd;
    int ret = 0;
    struct v4l2_capability cap;

    if ((capt_fd = open(CAPTURE_DEVICE, O_RDWR | O_NONBLOCK, 0)) <= -1) {

        perror("init_camera_capture:open::");
		return -1;
    }

    /*Is capture supported? */
    if (-1 == ioctl(capt_fd, VIDIOC_QUERYCAP, &cap)) {
        perror("init_camera_capture:ioctl:VIDIOC_QUERYCAP:");
		close(capt_fd);
		return -1;
    }

    if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
        printf("InitDevice:capture is not supported on:%s\n",
               CAPTURE_DEVICE);
		close(capt_fd);
		return -1;
    }

    /*is MMAP-IO supported? */
    if (!(cap.capabilities & V4L2_CAP_STREAMING)) {
        printf
            ("InitDevice:IO method MMAP is not supported on:%s\n",
             CAPTURE_DEVICE);
		close(capt_fd);
		return -1;
    }

	printf("setting data format\n");
	if (set_data_format(capt_fd) < 0) {
		printf("SetDataFormat failed\n");
		close(capt_fd);
		return -1;
	}

	printf("initializing capture buffers\n");
	if (InitCaptureBuffers(capt_fd) < 0) {
		printf("InitCaptureBuffers failed\n");
		close(capt_fd);
		return -1;
	}
	printf("Capture initialized\n");
	return capt_fd;
}

// assumes we use ntsc display
int init_display_device(int device)
{
	int fdDisplay;
	struct v4l2_requestbuffers req;
	struct v4l2_buffer buf;
	int a, ret, i,j;
	struct v4l2_format fmt;
	struct v4l2_crop crop;
	int fd_mode, fd_output;

	if (device == 0) {
		if ((fdDisplay = open(V4L2VID0_DEVICE, O_RDWR)) < 0) {
			printf("Open failed for vid0\n");
			return -1;
		}
	}
	else if (device == 1)
	{
		if ((fdDisplay = open(V4L2VID1_DEVICE, O_RDWR)) < 0) {
			printf("Open failed for vid1\n");
			return -1;
		}
	} else {
		printf("Invalid device id\n");
		return -1;
	}
	/* Setup Display */
#if 0
	if (cur_std & V4L2_STD_NTSC) {
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		if (change_sysfs_attrib(ATTRIB_OUTPUT, DISPLAY_INTERFACE_COMPOSITE) < 0) {
			close(fdDisplay);
			return -1;
		}
		if (change_sysfs_attrib(ATTRIB_MODE, DISPLAY_MODE_NTSC) < 0) {
			close(fdDisplay);
			return -1;
		}
	}
	else if (cur_std & V4L2_STD_PAL) {
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		if (change_sysfs_attrib(ATTRIB_OUTPUT, DISPLAY_INTERFACE_COMPOSITE) < 0) {
			close(fdDisplay);
			return -1;
		}
		if (change_sysfs_attrib(ATTRIB_MODE, DISPLAY_MODE_PAL) < 0) {
			close(fdDisplay);
			return -1;
		}
	}
	else if (cur_std & V4L2_STD_720P_60) {
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
		if (change_sysfs_attrib(ATTRIB_OUTPUT, DISPLAY_INTERFACE_COMPONENT) < 0) {
			close(fdDisplay);
			printf("error setting output\n");
			return -1;
		}
		if (change_sysfs_attrib(ATTRIB_MODE, DISPLAY_MODE_720P) < 0) {
			printf("error setting mode\n");
			close(fdDisplay);
			return -1;
		}
	}
	else if (cur_std & V4L2_STD_1080I_60) {
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		if (change_sysfs_attrib(ATTRIB_OUTPUT, DISPLAY_INTERFACE_COMPONENT) < 0) {
			close(fdDisplay);
			return -1;
		}
		if (change_sysfs_attrib(ATTRIB_MODE, DISPLAY_MODE_1080I) < 0) {
			close(fdDisplay);
			return -1;
		}
	} else {
		printf("Cannot display this standard\n");
		return -1;
	}
#endif
	if (rsz_opt == 0) {
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		if (change_sysfs_attrib(ATTRIB_OUTPUT, DISPLAY_INTERFACE_COMPOSITE) < 0) {
			close(fdDisplay);
			return -1;
		}
		if (change_sysfs_attrib(ATTRIB_MODE, DISPLAY_MODE_NTSC) < 0) {
			close(fdDisplay);
			return -1;
		}
	}
	else if (rsz_opt == 1) {
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		if (change_sysfs_attrib(ATTRIB_OUTPUT, DISPLAY_INTERFACE_COMPOSITE) < 0) {
			close(fdDisplay);
			return -1;
		}
		if (change_sysfs_attrib(ATTRIB_MODE, DISPLAY_MODE_PAL) < 0) {
			close(fdDisplay);
			return -1;
		}
	}
	else if (rsz_opt == 2) {
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
		if (change_sysfs_attrib(ATTRIB_OUTPUT, DISPLAY_INTERFACE_COMPONENT) < 0) {
			close(fdDisplay);
			printf("error setting output\n");
			return -1;
		}
		if (change_sysfs_attrib(ATTRIB_MODE, DISPLAY_MODE_720P) < 0) {
			printf("error setting mode\n");
			close(fdDisplay);
			return -1;
		}
	}
	else if (rsz_opt == 3) {
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		if (change_sysfs_attrib(ATTRIB_OUTPUT, DISPLAY_INTERFACE_COMPONENT) < 0) {
			close(fdDisplay);
			return -1;
		}
		if (change_sysfs_attrib(ATTRIB_MODE, DISPLAY_MODE_1080I) < 0) {
			close(fdDisplay);
			return -1;
		}
	} else {
		printf("Cannot display this standard\n");
		return -1;
	}

	req.count = APP_NUM_BUFS;
	req.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	req.memory = V4L2_MEMORY_USERPTR;
	ret = ioctl(fdDisplay, VIDIOC_REQBUFS, &req);
	if (ret) {
		perror("cannot allocate memory\n");
		goto error;
	}

	fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	if (out_format == 0) {
		fmt.fmt.pix.bytesperline = out_width * 2;
		fmt.fmt.pix.sizeimage =
		    fmt.fmt.pix.bytesperline * out_height;
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	}
	else {
		fmt.fmt.pix.width = out_width;
		fmt.fmt.pix.height = out_height;
               fmt.fmt.pix.bytesperline = out_width;
		fmt.fmt.pix.sizeimage =
		    fmt.fmt.pix.bytesperline * out_height * 1.5;
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_NV12;
	}

	ret = ioctl(fdDisplay, VIDIOC_S_FMT, &fmt);
	if (ret) {
		perror("VIDIOC_S_FMT failed\n");
		goto error;
	}
		
	return fdDisplay;
error:
	close(fdDisplay);
	return -1;
}

int start_capture_streaming(int fdCapture)
{
	int i = 0;
	enum v4l2_buf_type type;

	for (i = 0; i < APP_NUM_BUFS; i++) {
		struct v4l2_buffer buf;
		CLEAR(buf);
		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		buf.memory = V4L2_MEMORY_MMAP;
		buf.index = i;
		printf("Queing buffer:%d\n", i);

		if (-1 == ioctl(fdCapture, VIDIOC_QBUF, &buf)) {
			perror("StartStreaming:VIDIOC_QBUF failed");
			return -1;
		} else
			printf("\nQ_BUF Done\n");

	}

	/* all done , get set go */
	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if (-1 == ioctl(fdCapture, VIDIOC_STREAMON, &type)) {
		perror("StartStreaming:ioctl:VIDIOC_STREAMON:");
		return -1;
	} else
		printf("\nSTREAMON Done\n");

	return 0;
}

int cleanup_capture(int fd)
{
	int i;
	enum v4l2_buf_type type;
	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	
	if (-1 == ioctl(fd, VIDIOC_STREAMOFF, &type)) {
		perror("cleanup_capture :ioctl:VIDIOC_STREAMOFF");
		return -1;
	}

	for (i = 0; i < APP_NUM_BUFS; i++) {
		munmap(capture_buffers[i].start,
              capture_buffers[i].length);			
	}
	if (close(fd) < 0) {
		perror("Error in closing device\n");
		return -1;
	}
	return 0;
}

int cleanup_display(int fd)
{
	int i;
	enum v4l2_buf_type type;

	type = V4L2_BUF_TYPE_VIDEO_OUTPUT;

	if (-1 == ioctl(fd, VIDIOC_STREAMOFF, &type)) {
		perror("cleanup_display :ioctl:VIDIOC_STREAMOFF");
		return -1;
	}

	if (close(fd) < 0) {
		perror("Error in closing device\n");
		return -1;
	}
	return 0;
}


/******************************************************************************/
static int start_display(int fd, int index, int flag)
{
	int ret;
	struct v4l2_buffer buf;
	enum v4l2_buf_type type;

	bzero(&buf, sizeof(buf));
	/*
	 *      Queue all the buffers for the initial running
	 */
	printf("6. Test enqueuing of buffers - ");
	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	buf.memory = V4L2_MEMORY_USERPTR;
	buf.index = index;
	buf.length = display_image_size;
	buf.m.userptr = (unsigned long)capture_buffers[index].start;
	ret = ioctl(fd, VIDIOC_QBUF, &buf);
	if (ret < 0) {
		printf("\n\tError: Enqueuing buffer[%d] failed: VID1",
		       index);
		return -1;
	}
	printf("done\n");

	if (flag) {
		printf("7. Test STREAM_ON\n");
		type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		ret = ioctl(fd, VIDIOC_STREAMON, &type);
		if (ret < 0) {
			perror("VIDIOC_STREAMON\n");
			return -1;
		}
	}
	return 0;
}

/*******************************************************************************
 *	Takes the index
 *	of the buffer, and QUEUEs the buffer to display
 */
static int put_display_buffer(int vid_win, int index)
{
	struct v4l2_buffer buf;
	int i = 0;
	int ret;
	memset(&buf, 0, sizeof(buf));

	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	buf.memory = V4L2_MEMORY_USERPTR;
	buf.index = index;
	buf.length = display_image_size;
	//printf(" buf length is = %d", buf.length);
	buf.m.userptr = (unsigned long)capture_buffers[index].start;
	ret = ioctl(vid_win, VIDIOC_QBUF, &buf);
	return ret;
}

/*******************************************************************************
 *	Does a DEQUEUE and gets/returns the address of the
 *	dequeued buffer
 */
static int get_display_buffer(int vid_win)
{
	int ret;
	struct v4l2_buffer buf;
	memset(&buf, 0, sizeof(buf));
	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(vid_win, VIDIOC_DQBUF, &buf);
	if (ret < 0) {
		perror("VIDIOC_DQBUF\n");
		return -1;
	}
	return buf.index;
}

int main(int argc, char *argp[])
{
	char shortoptions[] = "f:i:s:p:r:";
	int mode = O_RDWR,c,ret,index, display_index;
	int preview_fd, rsz_fd, capt_fd, display_fd, dev_idx;
	unsigned int oper_mode, user_mode=IMP_MODE_CONTINUOUS;
	struct rsz_channel_config rsz_chan_config;
	struct rsz_continuous_config rsz_cont_config; // continuous mode
	int level;
	int width = 720, height = 480;
	int *capbuf_addr;
	fd_set fds;
	struct timeval tv;
	int r;
	int quit=0;
	struct timezone zone;
	int frame_count=0;
	struct v4l2_buffer buf;
	static int captFrmCnt = 0;


	for(;;) {
		c = getopt_long(argc, argp, shortoptions, NULL, (void *)&index);
		if(-1 == c)
			break;
		switch(c) {
		case 'f':
			out_format = atoi(optarg);
			if (out_format < 0 || out_format > 1) {
				printf("Choose 0 - UYVY 1 - NV12 for output pix format\n");
				exit(1);
			}
			break;
		case 's':
		case 'S':
			stress_test = atoi(optarg);
			break;
		case 'p':
		case 'P':
			printfn = atoi(optarg);
			break;
		case 'i':
		case 'I':
			input_index = atoi(optarg);
			if (input_index > 2)
				printf("choose index 0 for Composite,"
					" 1 - Svideo or 2 - component\n");
			break;
		case 'r':
		case 'R':
			rsz_opt = atoi(optarg);
			break;
			default:
				usage();
				exit(1);
		}
	}

	// intialize resizer in continuous mode
	rsz_fd = init_resizer(user_mode);
	if (rsz_fd < 0) {
		exit(1);
	}

	// initialize previewer in continuous mode
	preview_fd = init_previewer(user_mode);

	if (preview_fd < 0) {
		close(rsz_fd);
		exit(1);
	}
	
	// intialize capture
	capt_fd = init_camera_capture();

	if (capt_fd < 0) {
		close(preview_fd);
		close(rsz_fd);
		exit(1);
	}
	
	if (out_format == 0)
		display_image_size = out_width * out_height * BYTESPERPIXEL;
	else
		display_image_size = out_width * out_height * 1.5;

	display_fd = init_display_device(0);
	if (display_fd < 0) {
		close(preview_fd);
		close(rsz_fd);
		close(capt_fd);
		exit(1);
	}

	printf("Initialized display\n");	

	if (start_capture_streaming(capt_fd) < 0) {
		cleanup_capture(capt_fd);
		cleanup_display(display_fd);
		close(preview_fd);
		close(rsz_fd);
		exit(1);
	}

	/*if (ioctl(preview_fd, PREV_DUMP_HW_CONFIG, &level) < 0) {
		perror("Error in debug ioctl\n");
		cleanup_capture(capt_fd);
		cleanup_display(display_fd);
		close(preview_fd);
		close(rsz_fd);
		exit(1);
	} */

	printf("Starting loop for capture and display\n");
	while (!quit)
	{
		FD_ZERO(&fds);
		FD_SET(capt_fd, &fds);

		/* Timeout */
		tv.tv_sec = 2;
		tv.tv_usec = 0;
		r = select(capt_fd + 1, &fds, NULL, NULL, &tv);
		if (-1 == r) {
			if (EINTR == errno)
				continue;
			printf("StartCameraCapture:select\n");
			return -1;
		}
		if (0 == r)
			continue;

		CLEAR(buf);
		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		buf.memory = V4L2_MEMORY_MMAP;

		/* determine ready buffer */
		if (-1 == ioctl(capt_fd, VIDIOC_DQBUF, &buf)) {
			if (EAGAIN == errno)
				continue;
			printf("StartCameraCaputre:ioctl:VIDIOC_DQBUF\n");
			return -1;
		}

		if (captFrmCnt <= 1) {
			
			if (!captFrmCnt) {
				printf("5. Test enque first buffer\n");
				ret = start_display(display_fd, buf.index, 0);
			}
			else {
				printf("5. Test enque second buffer\n");
				ret = start_display(display_fd, buf.index, 1);
			}
			if (ret < 0) {
				printf("\tError: Starting display failed:VID1\n");
				return ret;
			}
			captFrmCnt++;
			continue;
		}

		ret = put_display_buffer(display_fd, buf.index);
		if (ret < 0) {
			printf("Error in putting the display buffer\n");
			return ret;
		}

		/******************* V4L2 display ********************/
		display_index = get_display_buffer(display_fd);
		if (display_index < 0) {
			printf("Error in getting the  display buffer:VID1\n");
			return ret;
		}
		/***************** END V4L2 display ******************/

		
		if (printfn)
			printf("time:%lu    frame:%u\n", (unsigned long)time(NULL),
		       		captFrmCnt++);

		buf.index = display_index;
		/* requeue the buffer */
		if (-1 == ioctl(capt_fd, VIDIOC_QBUF, &buf))
			printf("StartCameraCaputre:ioctl:VIDIOC_QBUF\n");
		if (stress_test) {
			start_loopCnt--;
			if (start_loopCnt == 0) {
				start_loopCnt = 50;
				break;
			}
		}
	}
	printf("Cleaning capture\n");
	cleanup_capture(capt_fd);
	printf("Cleaning display\n");
	cleanup_display(display_fd);
	printf("Cleaning display - end\n");
	close(preview_fd);
	printf("closing preview- end\n");
	close(rsz_fd);
	printf("closing resize - end\n");
	exit(0);
}

