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
//#include <media/davinci/mt9t001.h>
#include <media/davinci/tvp514x.h>
#include <media/davinci/davinci_vpfe.h>	
#include <media/davinci/ccdc_dm365.h>
#include <asm/arch/imp_resizer.h>
#include <asm/arch/dm365_ipipe.h>

char dev_name_rsz[1][30] = {"/dev/davinci_resizer"};

#define APP_NUM_BUFS 3
#define CAPTURE_DEVICE  "/dev/video0"
//#define CAP_FORMAT1		(V4L2_STD_MT9T001_VGA_30FPS)
//#define CAP_FORMAT1		(V4L2_STD_MT9T001_480p_30FPS)
#define CAP_FORMAT1		VPFE_STD_AUTO

#define V4L2VID0_DEVICE    "/dev/video2"
#define V4L2VID1_DEVICE    "/dev/video3"
#define CLEAR(x) memset (&(x), 0, sizeof (x))
#define DISPLAY_INTERFACE_COMPOSITE	"COMPOSITE"
#define DISPLAY_INTERFACE_COMPONENT	"COMPONENT"
#define DISPLAY_MODE_PAL	"PAL"
#define DISPLAY_MODE_NTSC	"NTSC"
#define DISPLAY_MODE_720P	"720P-60"		
#define DISPLAY_MODE_1080I	"1080I-30"		

/* Standards and output information */
#define ATTRIB_MODE		"mode"
#define ATTRIB_OUTPUT		"output"

struct app_buf_type {
    void *start;
    int offset;
    int length;
    int index;
};
	
struct app_buf_type capture_buffers[APP_NUM_BUFS];
struct app_buf_type rsz_out_buffers1[APP_NUM_BUFS];
struct app_buf_type display_buffers[APP_NUM_BUFS];

int flag = 0;

/* 0 - UYVY, 1 - NV12 */
int out_format=0;
/* IN_XXX should match with CAP_FORMAT1 */
#define IN_WIDTH 	1280	
#define IN_HEIGHT 	720	
#define OUT_WIDTH 	1280
#define OUT_HEIGHT 	720
#define BYTESPERPIXEL 2

#define WIDTH_NTSC		720
#define HEIGHT_NTSC		480
#define WIDTH_PAL		720
#define HEIGHT_PAL		576
#define WIDTH_720P		1280
#define HEIGHT_720P		720	
#define WIDTH_1080I		1920
#define HEIGHT_1080I		1080

int in_width = IN_WIDTH, in_height = IN_HEIGHT;
int out_width = OUT_WIDTH, out_height = OUT_HEIGHT;
static int printfn = 1;
int rsz_opt =0;
int input_index = 0;
char *inputs[] = { "COMPOSITE", "SVIDEO", "COMPONENT" };
static struct v4l2_cropcap cropcap;
static int nWidthFinal;
static int nHeightFinal;
static int stress_test = 1;
static int rsz_fd;
static v4l2_std_id cur_std;

int init_rsz_buffers(void);
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

int init_resizer(void)
{
	int user_mode = IMP_MODE_SINGLE_SHOT;
	unsigned int oper_mode;
	struct rsz_channel_config rsz_chan_config;
	struct rsz_single_shot_config rsz_ss_config; // continuous mode
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
		printf("Successfully set mode to single shot in resizer\n");
	else {
		printf("failed to set mode to single shot in resizer\n");
		close(rsz_fd);
		return -1;
	}
		
	// set configuration to chain resizer with preview
	rsz_chan_config.oper_mode = user_mode;
	rsz_chan_config.chain  = 0;
	rsz_chan_config.len = 0;
	rsz_chan_config.config = NULL; /* to set defaults in driver */
	if (ioctl(rsz_fd, RSZ_S_CONFIG, &rsz_chan_config) < 0) {
		perror("Error in setting default configuration in resizer\n");
		close(rsz_fd);
		return -1;
	}
	
	printf("default configuration setting in Resizer successfull\n");
	bzero(&rsz_ss_config, sizeof(struct rsz_single_shot_config));
	rsz_chan_config.oper_mode = user_mode;
	rsz_chan_config.chain = 0;
	rsz_chan_config.len = sizeof(struct rsz_single_shot_config);
	rsz_chan_config.config = &rsz_ss_config;

	if (ioctl(rsz_fd, RSZ_G_CONFIG, &rsz_chan_config) < 0) {
		perror("Error in getting resizer channel configuration from driver\n");
		close(rsz_fd);
		return -1;
	}
		
	// we can ignore the input spec since we are chaining. So only
	// set output specs
	rsz_ss_config.input.image_width = in_width;
	if ((cur_std & V4L2_STD_NTSC) || (cur_std & V4L2_STD_PAL) || ((cur_std & V4L2_STD_1080I_60) ||
		   (cur_std & V4L2_STD_1080I_50)))
	rsz_ss_config.input.image_height = in_height/2;
	else
	rsz_ss_config.input.image_height = in_height;

	//rsz_ss_config.input.ppln = rsz_ss_config.input.image_width + 8;
	//rsz_ss_config.input.lpfr = rsz_ss_config.input.image_height + 10;
	rsz_ss_config.input.ppln = (3 * rsz_ss_config.input.image_width);
	rsz_ss_config.input.lpfr = (rsz_ss_config.input.image_height + 10) ;
	rsz_ss_config.input.clk_div.m = 1;
	rsz_ss_config.input.clk_div.n = 6;
	rsz_ss_config.input.pix_fmt = IPIPE_UYVY;
	if (out_format == 1)
		rsz_ss_config.output1.pix_fmt = IPIPE_YUV420SP;
	else
		rsz_ss_config.output1.pix_fmt = IPIPE_UYVY;
	rsz_ss_config.output1.enable = 1;
	rsz_ss_config.output1.width = out_width;
	rsz_ss_config.output1.height = out_height;
	rsz_ss_config.output2.enable = 0;
	rsz_chan_config.len = sizeof(struct rsz_single_shot_config);
	rsz_chan_config.config = &rsz_ss_config;
	if (ioctl(rsz_fd, RSZ_S_CONFIG, &rsz_chan_config) < 0) {
		perror("Error in setting configuration in resizer\n");
		close(rsz_fd);
		return -1;
	}
	printf("Resizer initialized, fd = %d\n", rsz_fd);
	return rsz_fd;
}

int do_resize(int rsz_fd, 
	void *capbuf_addr, 
	void *display_buf)
{
	struct imp_convert convert;
	int index;

	bzero(&convert,sizeof(convert));
	convert.in_buff.buf_type = IMP_BUF_IN;
	convert.in_buff.index = -1;
	convert.in_buff.offset = (unsigned int)capbuf_addr;
	convert.in_buff.size = in_width*(in_height/2)*2;
	convert.out_buff1.buf_type = IMP_BUF_OUT1;

	for (index=0; index < APP_NUM_BUFS; index++) {
		if (rsz_out_buffers1[index].offset == (unsigned int)display_buf) {
			break;
		}
	}
	if (index == APP_NUM_BUFS) {
		printf("Couldn't find display buffer index\n");
		return -1;
	}

	convert.out_buff1.index = index;
	convert.out_buff1.offset = (unsigned int)display_buf;
	convert.out_buff1.size = out_width*out_height*BYTESPERPIXEL;

	if (ioctl(rsz_fd, RSZ_RESIZE, &convert) < 0) {
		perror("Error in doing resize\n");
		return -1;
	} 
	return 0;
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
	char temp[40];


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
		printf ("InitDevice:ioctl:VIDIOC_G_INPUT, selected INPUT input %s\n",inputs[temp_input]);
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

	if (std & V4L2_STD_NTSC) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_NTSC, HEIGHT_NTSC);
		in_width = fmt.fmt.pix.width = WIDTH_NTSC;
		in_height = fmt.fmt.pix.height = HEIGHT_NTSC;
		//out_width = WIDTH_NTSC;
		//out_height = HEIGHT_NTSC;
		//fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		fmt.fmt.pix.field = V4L2_FIELD_SEQ_TB;
	} else if (std & V4L2_STD_525P_60) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_NTSC, HEIGHT_NTSC);
		in_width = fmt.fmt.pix.width = WIDTH_NTSC;
		in_height = fmt.fmt.pix.height = HEIGHT_NTSC;
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	} else if ((std & V4L2_STD_PAL) ||
		(std & V4L2_STD_PAL_M) ||
		(std & V4L2_STD_PAL_N)) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_PAL, HEIGHT_PAL);
		in_width = fmt.fmt.pix.width = WIDTH_PAL;
		in_height = fmt.fmt.pix.height = HEIGHT_PAL;
		fmt.fmt.pix.field = V4L2_FIELD_SEQ_TB;//V4L2_FIELD_INTERLACED;
	} else if (std & V4L2_STD_625P_50) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_PAL, HEIGHT_PAL);
		in_width = fmt.fmt.pix.width = WIDTH_PAL;
		in_height = fmt.fmt.pix.height = HEIGHT_PAL;
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	} else if ((std & V4L2_STD_720P_60) ||
		   (std & V4L2_STD_720P_50)) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_720P, HEIGHT_720P);
		in_width = fmt.fmt.pix.width = WIDTH_720P;
		in_height = fmt.fmt.pix.height = HEIGHT_720P;
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	} else if ((std & V4L2_STD_1080I_60) ||
		   (std & V4L2_STD_1080I_50)) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_1080I, HEIGHT_1080I);
		in_width = fmt.fmt.pix.width = WIDTH_1080I;
		in_height = fmt.fmt.pix.height = HEIGHT_1080I;
		out_width = 1920;
		out_height = 1080;
		fmt.fmt.pix.field = V4L2_FIELD_SEQ_TB;
		//fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	}
	if (rsz_opt == 0) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_NTSC, HEIGHT_NTSC);
		//in_width = fmt.fmt.pix.width = WIDTH_NTSC;
		//in_height = fmt.fmt.pix.height = HEIGHT_NTSC;
		out_width = WIDTH_NTSC;
		out_height = HEIGHT_NTSC;
		//fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
		//fmt.fmt.pix.field = V4L2_FIELD_SEQ_TB;
	}  else if (rsz_opt == 2) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_720P, HEIGHT_720P);
		out_width = WIDTH_720P;
		out_height = HEIGHT_720P;
		//fmt.fmt.pix.field = V4L2_FIELD_NONE;
	} else if (rsz_opt == 3) {
		printf("set_data_format:requesting width:%d height:%d\n",
		       WIDTH_1080I, HEIGHT_1080I);
		//in_width = fmt.fmt.pix.width = WIDTH_1080I;
		//in_height = fmt.fmt.pix.height = HEIGHT_1080I;
		out_width = 1920;
		out_height = 1080;
		//fmt.fmt.pix.field = V4L2_FIELD_SEQ_TB;
		//fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	}

	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;

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

    // intialize resizer in continuous mode
    rsz_fd = init_resizer();
    if (rsz_fd < 0) {
	return -1;
    }

	
    if (init_rsz_buffers() < 0) {
	close(rsz_fd);
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
		out_width = 720;
		out_height = 480;
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
		out_width = 1920;
		out_height = 1080;
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
		//out_width = 720;
		//out_height = 480;
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
		out_width = 1920;
		out_height = 1080;
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
	//fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
	if (out_format == 0) {
		fmt.fmt.pix.bytesperline = out_width * 2;
		fmt.fmt.pix.sizeimage =
		    fmt.fmt.pix.bytesperline * out_height;
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	}
	else {
		fmt.fmt.pix.bytesperline = out_width;
		fmt.fmt.pix.width = out_width;
		fmt.fmt.pix.height = out_height;
		fmt.fmt.pix.sizeimage =
		    fmt.fmt.pix.bytesperline * out_height * 1.5;
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_NV12;
	}
	ret = ioctl(fdDisplay, VIDIOC_S_FMT, &fmt);
	if (ret) {
		perror("VIDIOC_S_FMT failed\n");
		goto error;
	}

	/* Enqueue buffers */
	for (i = 0; i < req.count; i++) {
		bzero(&buf, sizeof(buf));
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.index = i;
		buf.memory = V4L2_MEMORY_USERPTR;
		buf.m.userptr = (unsigned long)rsz_out_buffers1[i].start;
		ret = ioctl(fdDisplay, VIDIOC_QBUF, &buf);
		if (ret) {
			printf("VIDIOC_QBUF\n");
			goto error;
		}
	}

	a = 0;
	ret = ioctl(fdDisplay, VIDIOC_STREAMON, &a);
	if (ret < 0) {
		perror("VIDIOC_STREAMON failed\n");
		goto error;
	}
	printf("Enabled streaming on display device\n");
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

void *get_capture_frame(int fdCapture, int *index)
{
	
	struct v4l2_buffer buf;
	CLEAR(buf);
	buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	buf.memory = V4L2_MEMORY_MMAP;
	if (-1 == ioctl(fdCapture, VIDIOC_DQBUF, &buf)) {
		if (EAGAIN == errno)
			return NULL ;
	}
	*index = buf.index;
	return ((void *)capture_buffers[buf.index].offset);
}

void *getDisplayBuffer(int fd, int *index)
{
	int ret, i;
	struct v4l2_buffer buf;

	memset(&buf, 0, sizeof(buf));
	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	ret = ioctl(fd, VIDIOC_DQBUF, &buf);
	if (ret < 0) {
		perror("VIDIOC_DQBUF\n");
		return NULL;
	}
	*index = buf.index;
	return (void *)rsz_out_buffers1[buf.index].offset;
}

int putDisplayBuffer(int fd, void *addr, int size)
{
	struct v4l2_buffer buf;
	int i, index = 0;
	int ret=0;

	if (addr == NULL)
		return -1;

	memset(&buf, 0, sizeof(buf));

	for (i = 0; i < APP_NUM_BUFS; i++) {
		if (addr == (void *)rsz_out_buffers1[i].offset) {
			index = rsz_out_buffers1[i].index;
			break;
		}
	}

	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	buf.memory = V4L2_MEMORY_USERPTR;
	buf.index = index;
	buf.length = size; 
	buf.m.userptr = (unsigned int)rsz_out_buffers1[index].start;
	ret = ioctl(fd, VIDIOC_QBUF, &buf);
	return ret;
}

int return_capture_buffer (int fdCapture, int index)
{
	static struct v4l2_buffer buf;
	CLEAR(buf);
	buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	buf.memory = V4L2_MEMORY_MMAP;
	buf.index = index;
	if (-1 == ioctl(fdCapture, VIDIOC_QBUF, &buf)) {
		perror("VIDIOC_QBUF failed\n");
		return -1;
	}
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

int main(int argc, char *argp[])
{
	char shortoptions[] = "s:p:i:f:r:";
	int mode = O_RDWR,c,ret,index, disp_index;
	int capt_fd, display_fd, dev_idx;
	unsigned int oper_mode, user_mode=IMP_MODE_SINGLE_SHOT;
	int level;
	int *capbuf_addr;
	fd_set fds;
	struct timeval tv;
	int r, i;
	int quit=0;
	struct timezone zone;
	int frame_count=0;
	void *display_buf;
	void *src, *dest;
	v4l2_std_id cur_std;
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

	// intialize capture
	capt_fd = init_camera_capture();

	if (capt_fd < 0) {
		close(rsz_fd);
		exit(1);
	}
	
	display_fd = init_display_device(0);
	if (display_fd < 0) {
		close(rsz_fd);
		close(capt_fd);
		exit(1);
	}

	printf("Initialized display\n");	

	if (start_capture_streaming(capt_fd) < 0) {
		cleanup_capture(capt_fd);
		cleanup_display(display_fd);
		close(rsz_fd);
		exit(1);
	}

	while (!quit)
	{

		bzero((void *)&zone, sizeof (struct timezone));

		FD_ZERO (&fds);
		FD_SET (capt_fd, &fds); 

		/* Timeout. */
		tv.tv_sec = 2;
		tv.tv_usec = 0;
		r = select (capt_fd + 1, &fds, NULL, NULL, &tv);
		if (-1 == r)
		{
			if (EINTR == errno)
	    		continue;
			quit=1;
		}

		if (0 == r)
		{
			continue;
		}
		capbuf_addr = get_capture_frame(capt_fd, &index);
		if (capbuf_addr) {
			frame_count++;
			display_buf = getDisplayBuffer(display_fd, &disp_index);
			if (display_buf) {
				if (do_resize(rsz_fd, 
					capbuf_addr,
					display_buf) < 0) {
						printf("resize error\n");
						putDisplayBuffer(display_fd, display_buf,out_width*out_height*BYTESPERPIXEL);
						return_capture_buffer(capt_fd, index);
						quit=1;
						continue;
				}
				if (printfn)
					printf("time:%lu    frame:%u\n", (unsigned long)time(NULL), captFrmCnt++);

				putDisplayBuffer(display_fd, display_buf,out_width*out_height*BYTESPERPIXEL);
			}
			if (return_capture_buffer(capt_fd, index) < 0) {
				printf("dispay_frame error\n");
				quit=1;
			}
		}
	}
	printf("Cleaning capture\n");
	cleanup_capture(capt_fd);
	printf("Cleaning display\n");
	cleanup_display(display_fd);
	printf("Cleaning display - end\n");
	close(rsz_fd);
	printf("closing resize - end\n");
	exit(0);
}

int init_rsz_buffers(void)
{
	struct imp_reqbufs req_buf;
	struct imp_buffer buf_out;
	int i,j;


	req_buf.buf_type = IMP_BUF_OUT1;
	req_buf.size = (out_width*out_height*BYTESPERPIXEL);
	//req_buf.size = (1920*1080*BYTESPERPIXEL);
	req_buf.count = 3;
	
	if (ioctl(rsz_fd, RSZ_REQBUF, &req_buf) < 0) {
		perror("Error in PREV_REQBUF for IMP_BUF_OUT1\n");
		return -1;
	}

	for (i = 0; i < 3; i++) {
		buf_out.index = i;
		buf_out.buf_type = IMP_BUF_OUT1;
		if (ioctl(rsz_fd, RSZ_QUERYBUF, &buf_out) < 0) {
			perror("Error in PREV_QUERYBUF for IMP_BUF_OUT1\n");
			return -1;
		}
		rsz_out_buffers1[i].index = i;
		rsz_out_buffers1[i].offset = buf_out.offset;
		rsz_out_buffers1[i].length = buf_out.size;
		rsz_out_buffers1[i].start = mmap(
									NULL,
									buf_out.size, 
									PROT_READ|PROT_WRITE, 
									MAP_SHARED, 
									rsz_fd, 
									buf_out.offset);
		
		if (rsz_out_buffers1[i].start == MAP_FAILED) {
			for (j= 0; j < i; j++) {
				munmap(
					rsz_out_buffers1[j].start,
					rsz_out_buffers1[j].length 
					);
			}
			printf("init_rsz_buffers: error in mmap\n");
			return -1;
		}
	}
	return 0;
}

