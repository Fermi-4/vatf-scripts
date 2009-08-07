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
#include <media/davinci/ccdc_dm355.h>
#include <asm/arch/imp_previewer.h>
#include <asm/arch/imp_resizer.h>
#include <asm/arch/dm355_ipipe.h>

char dev_name_prev[1][30] = {"/dev/davinci_previewer"};
char dev_name_rsz[1][30] = {"/dev/davinci_resizer"};

#define APP_NUM_BUFS 3
#define CAPTURE_DEVICE  "/dev/video0"
//#define CAP_FORMAT1		(V4L2_STD_MT9T001_VGA_30FPS)
//#define CAP_FORMAT1		(V4L2_STD_MT9T001_480p_30FPS)
#define CAP_FORMAT1		VPFE_STD_AUTO

#define V4L2VID0_DEVICE    "/dev/video2"
#define V4L2VID1_DEVICE    "/dev/video3"
#define CLEAR(x) memset (&(x), 0, sizeof (x))
int en_preview_rsz=1;


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

int flag = 0;

/* IN_XXX should match with CAP_FORMAT1 */
#define IN_WIDTH 	720
#define IN_HEIGHT 	480
#define OUT_WIDTH 	720
#define OUT_HEIGHT 	480
#define BYTESPERPIXEL 2

void usage()
{
	printf("Usage:capture_prev_rsz_onthe_fly\n");
}

int init_resizer(unsigned int user_mode, int out_width, int out_height)
{
	int rsz_fd;
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
	rsz_chan_config.chain  = 1;
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
	rsz_chan_config.chain = 1;
	rsz_chan_config.len = sizeof(struct rsz_single_shot_config);
	rsz_chan_config.config = &rsz_ss_config;

	if (ioctl(rsz_fd, RSZ_G_CONFIG, &rsz_chan_config) < 0) {
		perror("Error in getting resizer channel configuration from driver\n");
		close(rsz_fd);
		return -1;
	}
		
	// we can ignore the input spec since we are chaining. So only
	// set output specs
	rsz_ss_config.output1.enable = 1;
	rsz_ss_config.output1.width = out_width;
	rsz_ss_config.output1.height = out_height;	
	rsz_chan_config.oper_mode = IMP_MODE_SINGLE_SHOT;
	rsz_chan_config.chain = 1;
	rsz_chan_config.len = sizeof(struct rsz_single_shot_config);
	rsz_chan_config.config = &rsz_ss_config;
	if (ioctl(rsz_fd, RSZ_S_CONFIG, &rsz_chan_config) < 0) {
		perror("Error in setting configuration in resizer\n");
		close(rsz_fd);
		return -1;
	}
	printf("Resizer initialized\n");
	return rsz_fd;
}

int init_previewer(unsigned int user_mode, int in_width, int in_height, int in_format)
{
	
	int preview_fd, ret;
	unsigned int oper_mode;
	struct prev_channel_config prev_chan_config;
	struct prev_single_shot_config prev_ss_config; // single shot mode
	struct prev_cap cap;
	struct prev_module_param mod_param;
	struct prev_wb wb;
	struct prev_lum_adj lum_adj;
	struct prev_gamma gamma;
	struct prev_prefilter;
	

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
	prev_chan_config.len = sizeof(struct prev_single_shot_config);
	prev_chan_config.config = &prev_ss_config;

	if (ioctl(preview_fd, PREV_G_CONFIG, &prev_chan_config) < 0) {
		perror("Error in getting configuration from driver\n");
		close(preview_fd);
		return -1;
	}
	
	prev_chan_config.oper_mode = oper_mode;
	prev_chan_config.len = sizeof(struct prev_single_shot_config);
	prev_chan_config.config = &prev_ss_config;
	prev_ss_config.input.image_width = in_width;
	prev_ss_config.input.image_height = in_height;
	prev_ss_config.input.ppln = prev_ss_config.input.image_width + 8 ;
	prev_ss_config.input.lpfr = prev_ss_config.input.image_height + 10;
	if (in_format == 0) {
		prev_ss_config.input.pix_fmt = IPIPE_BAYER;
		prev_ss_config.output.pix_fmt = IPIPE_UYVY;
	} else {
		prev_ss_config.input.pix_fmt = IPIPE_UYVY;
		prev_ss_config.output.pix_fmt = IPIPE_UYVY;
	}
	
	
#if 0
	prev_cont_config.input.colp_elep= IPIPE_RED;
	prev_cont_config.input.colp_elop= IPIPE_GREEN_RED;
	prev_cont_config.input.colp_olep= IPIPE_GREEN_BLUE;
	prev_cont_config.input.colp_olop= IPIPE_BLUE;
/*
	B Gb
	Gr R
*/
	prev_cont_config.input.colp_elep= IPIPE_BLUE;
	prev_cont_config.input.colp_elop= IPIPE_GREEN_BLUE;
	prev_cont_config.input.colp_olep= IPIPE_GREEN_RED;
	prev_cont_config.input.colp_olop= IPIPE_RED;
#endif
/*
	GB B 
	R GR
*/
#if 0
	prev_cont_config.input.colp_elep= IPIPE_GREEN_BLUE;
	prev_cont_config.input.colp_elop= IPIPE_BLUE;
	prev_cont_config.input.colp_olep= IPIPE_RED;
	prev_cont_config.input.colp_olop= IPIPE_GREEN_RED;
#endif

/* Gr R
   B Gb
*/
#if 0
	prev_cont_config.input.colp_elep= IPIPE_GREEN_RED;
	prev_cont_config.input.colp_elop= IPIPE_RED;
	prev_cont_config.input.colp_olep= IPIPE_BLUE;
	prev_cont_config.input.colp_olop= IPIPE_GREEN_BLUE;
#endif

	if (ioctl(preview_fd, PREV_S_CONFIG, &prev_chan_config) < 0) {
		perror("Error in setting default configuration\n");
		close(preview_fd);
		return -1;
	}

	cap.index=0;
	while (1) {
		ret = ioctl(preview_fd , PREV_ENUM_CAP, &cap);
		if (ret < 0) {
			break;	
		}
		// find the defaults for this module
	
		strcpy(mod_param.version,cap.version);
		mod_param.module_id = cap.module_id;
		// try set parameter for this module
#if 0
		if (cap.module_id == PREV_WB) {
			wb.dgn.integer = 2;
			wb.dgn.decimal = 0;
			wb.gain_r.integer = 2;
			wb.gain_r.decimal = 0x10;
			wb.gain_gr.integer = 1;
			wb.gain_gr.decimal = 0x70;
			wb.gain_gb.integer = 1;
			wb.gain_gb.decimal = 0x70;
			wb.gain_b.integer = 2;
			wb.gain_b.decimal = 0x30;
			mod_param.len = sizeof(struct prev_wb);
			mod_param.param = &wb;
		} else if (cap.module_id == PREV_LUM_ADJ) {
			lum_adj.brightness = 0x10;
			lum_adj.contast = 0x10;
			mod_param.len = sizeof (struct prev_lum_adj);
			mod_param.param = &lum_adj;
		} else if (cap.module_id == PREV_GAMMA) {
#endif
		if ((cap.module_id == PREV_GAMMA) && flag && (!in_format)) {
			printf("Setting gamma for %s\n", cap.module_name);
			bzero((void *)&gamma, sizeof (struct prev_gamma));
			gamma.bypass_r = 0;
			gamma.bypass_b = 0;
			gamma.bypass_g = 0;
			gamma.tbl_sel = IPIPE_GAMMA_TBL_ROM;
			mod_param.len = sizeof (struct prev_gamma);
			mod_param.param = &gamma;
		}
		else {
			// using defaults
			printf("Setting default for %s\n", cap.module_name);
			mod_param.param = NULL;
		}
		if (ioctl(preview_fd, PREV_S_PARAM, &mod_param) < 0) {
			perror("Error in Setting wb params from driver\n");
			close(preview_fd);
			return -1;
		}
		cap.index++;
	}	

	printf("previewer initialized\n");
	return preview_fd;
}

int do_preview_resize(int preview_fd, 
				int in_width,
				int in_height,
				void *capbuf_addr, 
				void *display_buf,
				int out_width,
				int out_height)
{
	struct imp_convert convert;
	int index;

	bzero(&convert,sizeof(convert));
	convert.in_buff.buf_type = IMP_BUF_IN;
	convert.in_buff.index = -1;
	convert.in_buff.offset = (unsigned int)capbuf_addr;
	convert.in_buff.size = in_width*in_height*2;
	convert.out_buff1.buf_type = IMP_BUF_OUT1;

	for (index=0; index < APP_NUM_BUFS; index++) {
		if (prev_rsz_out_buffers1[index].offset == (unsigned int)display_buf) {
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
	if (ioctl(preview_fd, PREV_PREVIEW, &convert) < 0) {
		perror("Error in doing preview\n");
		return -1;
	} 
	
	return 0;
}
	
static int SetDataFormat(int fdCapture, v4l2_std_id std, int width, int height)
{
	v4l2_std_id ipipe_std, cur_std;
	struct v4l2_format fmt;
	struct v4l2_input input;
	int ret;
	cur_std = ipipe_std = std;

	printf("SetDataFormat:setting std to %d\n", (int)cur_std);

	// first set the input
	input.type = V4L2_INPUT_TYPE_CAMERA;
	input.index = 0;
  	while (-EINVAL != ioctl(fdCapture,VIDIOC_ENUMINPUT, &input)) { 
		printf("input.name = %s\n", input.name);
		if (!strcmp(input.name, "COMPOSITE"))
			break;
		input.index++;
  	}

  	if (-1 == ioctl (fdCapture, VIDIOC_S_INPUT, &input.index))
  	{
      	printf ("InitDevice:ioctl:VIDIOC_S_INPUT\n");
      	return -1;
  	}
  	printf ("InitDevice:ioctl:VIDIOC_S_INPUT, selected COMPOSITE INPUT input\n");

	if (-1 == ioctl(fdCapture, VIDIOC_S_STD, &cur_std)) {
		printf
		    ("SetDataFormat:unable to set standard automatically\n");
		return -1;
	} else
		printf("\nS_STD Done\n");

	sleep(1);		/* wait until device is fully locked */
	cur_std = 0;
	if (-1 == ioctl(fdCapture, VIDIOC_G_STD, &cur_std)) {
		perror("SetDataFormat:ioctl:VIDIOC_G_STD:");
		return -1;
	} else
		printf("\nGetSTD Done WITH std = %u\n", (int) cur_std);

	printf("SetDataFormat:requesting width:%d height:%d\n", width, height);
	CLEAR(fmt);
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt.fmt.pix.width = width;
	fmt.fmt.pix.height = height;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	fmt.fmt.pix.field = V4L2_FIELD_SEQ_TB;
	if (-1 == ioctl(fdCapture, VIDIOC_S_FMT, &fmt)) {
		perror("SetDataFormat:ioctl:VIDIOC_S_FMT");
		return -1;
	} else
		printf("\nS_FMT Done\n");

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

int init_camera_capture(v4l2_std_id std, int width, int height)
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
	if (SetDataFormat(capt_fd, std, width, height) < 0) {
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
int init_display_device(int device, int width, int height)
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

	fd_output = open("/sys/class/davinci_display/ch0/output", O_RDWR);
	if (fd_output == -1) {
		perror(" Error in opening the sysfs for mode \n");
		goto error;
	}

	fd_mode = open("/sys/class/davinci_display/ch0/mode", O_RDWR);
	if (fd_mode == -1) {
		perror(" Error in opening the sysfs for mode \n");
		goto error;
	}

	if(width == 720 || height == 480)
	{ 
	if ( (write(fd_output, "COMPOSITE" , 10) == -1 ) ) {
		perror( " Error in writing the output \n " );
		goto error;
	}
	printf(" successfully configured COMPOSITE \n" );

	if ( (write(fd_mode, "NTSC" , 5) == -1 ) ) {
		perror( " Error in writing the mode \n " );
		goto error;
	}
	printf(" successfully configured NTSC \n" ); 
	}
	else if(width == 720 || height == 576)
	{ 
	if ( (write(fd_output, "COMPOSITE" , 10) == -1 ) ) {
		perror( " Error in writing the output \n " );
		goto error;
	}
	printf(" successfully configured COMPOSITE \n" );

	if ( (write(fd_mode, "PAL" , 4) == -1 ) ) {
		perror( " Error in writing the mode \n " );
		goto error;
	}
	printf(" successfully configured PAL \n" ); 
	}
	else if(width == 1280 || height == 720)
	{ 
	if ( (write(fd_output, "COMPONENT1" , 11) == -1 ) ) {
		perror( " Error in writing the output \n " );
		goto error;
	}
	printf(" successfully configured THS8200 \n" );

	if ( (write(fd_mode, "720P-60" , 8) == -1 ) ) {
		perror( " Error in writing the mode \n " );
		goto error;
	}
	printf(" successfully configured 720P \n" ); 
	}
	else if(width == 1920 || height == 1080)
	{ 
	if ( (write(fd_output, "COMPONENT1" , 11) == -1 ) ) {
		perror( " Error in writing the output \n " );
		goto error;
	}
	printf(" successfully configured THS8200 \n" );

	if ( (write(fd_mode, "1080I-30" , 9) == -1 ) ) {
		perror( " Error in writing the mode \n " );
		goto error;
	}
	printf(" successfully configured 1080I \n" ); 
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
	fmt.fmt.pix.bytesperline = width*BYTESPERPIXEL;
	fmt.fmt.pix.sizeimage= fmt.fmt.pix.bytesperline * height ;
	if(height == 480 || height == 576 || height == 1080)
	fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	if(height == 720)
	fmt.fmt.pix.field = V4L2_FIELD_NONE;
	//fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;

	ret = ioctl(fdDisplay, VIDIOC_S_FMT, &fmt);
	if (ret) {
		perror("VIDIOC_S_FMT failed\n");
		goto error;
	}

#if 0
	crop.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	crop.c.width = width;
	crop.c.height = height;
	crop.c.top = 0;
	crop.c.left = 0;
	if ( ioctl(fdDisplay, VIDIOC_S_CROP, &crop) == -1 ) {
		perror("VIDIOC_S_CROP failed\n");
		for (j = 0; j < req.count; j++)
			munmap(display_buffers[j].start,display_buffers[j].length);
		goto error;
	}
#endif
		
	/* Enqueue buffers */
	for (i = 0; i < req.count; i++) {
		bzero(&buf, sizeof(buf));
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.index = i;
		buf.memory = V4L2_MEMORY_USERPTR;
		buf.m.userptr = (unsigned long)prev_rsz_out_buffers1[i].start;
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
	return (void *)prev_rsz_out_buffers1[buf.index].offset;
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
		if (addr == (void *)prev_rsz_out_buffers1[i].offset) {
			index = prev_rsz_out_buffers1[i].index;
			break;
		}
	}

	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	buf.memory = V4L2_MEMORY_USERPTR;
	buf.index = index;
	buf.length = size; 
	buf.m.userptr = (unsigned int)prev_rsz_out_buffers1[index].start;
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
	}

	for (i = 0; i < APP_NUM_BUFS; i++) {
		munmap(capture_buffers[i].start,
              capture_buffers[i].length);			
	}
	if (close(fd) < 0)
		perror("Error in closing device\n");
}

int cleanup_preview(int fd)
{
	int i;
	for (i = 0; i < APP_NUM_BUFS; i++) {
		munmap(prev_rsz_out_buffers1[i].start,
              prev_rsz_out_buffers1[i].length);			
	}
	if (close(fd) < 0)
		perror("Error in closing preview device\n");
}


int cleanup_display(int fd)
{
	int i;
	enum v4l2_buf_type type;

	type = V4L2_BUF_TYPE_VIDEO_OUTPUT;

	if (-1 == ioctl(fd, VIDIOC_STREAMOFF, &type)) {
		perror("cleanup_display :ioctl:VIDIOC_STREAMOFF");
	}

	if (close(fd) < 0)
		perror("Error in closing device\n");
}

int main(int argc, char *argp[])
{
	char shortoptions[] = "w:h:t:f:";
	int mode = O_RDWR,c,ret,index, disp_index;
	int preview_fd, rsz_fd, capt_fd, display_fd, dev_idx;
	unsigned int oper_mode, user_mode=IMP_MODE_SINGLE_SHOT;
	int level;
	int in_width = IN_WIDTH, in_height = IN_HEIGHT;
	int out_width = OUT_WIDTH, out_height = OUT_HEIGHT;
	int *capbuf_addr;
	fd_set fds;
	struct timeval tv;
	int r, i;
	int quit=0;
	struct timezone zone;
	int frame_count=0;
	FILE *outp_f;
	int in_format=1;
	void *display_buf;
	void *src, *dest;

	for(;;) {
		c = getopt_long(argc, argp, shortoptions, NULL, (void *)&index);
		if(-1 == c)
			break;
		switch(c) {
			case 'w':
				out_width = atoi(optarg);
				break;
			case 'h':
				out_height = atoi(optarg);
				break;
			case 't':
				flag = atoi(optarg);
				break;
			case 'f':
				in_format = atoi(optarg);
				break;
			default:
				usage();
				exit(1);
		}
	}

	outp_f = fopen("test_vga_1.bin", "wb");
	if (outp_f == NULL) {
		perror("Error in opening output file \n");
		exit(1);
	}

	// intialize resizer in continuous mode
	rsz_fd = init_resizer(user_mode, out_width, out_height);
	if (rsz_fd < 0) {
		fclose(outp_f);
		exit(1);
	}

	// initialize previewer in continuous mode
	preview_fd = init_previewer(user_mode, in_width, in_height/2, in_format);

	if (preview_fd < 0) {
		close(rsz_fd);
		fclose(outp_f);
		exit(1);
	}
	
	if (init_preview_buffers(preview_fd, out_width, out_height) < 0) {
		close(rsz_fd);
		fclose(outp_f);
		exit(1);
	}
	// intialize capture
	capt_fd = init_camera_capture(CAP_FORMAT1, in_width, in_height);

	if (capt_fd < 0) {
		close(preview_fd);
		close(rsz_fd);
		fclose(outp_f);
		exit(1);
	}
	
	display_fd = init_display_device(0, out_width, out_height);
	if (display_fd < 0) {
		cleanup_preview(preview_fd);
		close(rsz_fd);
		close(capt_fd);
		fclose(outp_f);
		exit(1);
	}

	printf("Initialized display\n");	


	if (start_capture_streaming(capt_fd) < 0) {
		cleanup_capture(capt_fd);
		cleanup_display(display_fd);
		cleanup_preview(preview_fd);
		close(rsz_fd);
		fclose(outp_f);
		exit(1);
	}

#if 0
	if (ioctl(preview_fd, PREV_DUMP_HW_CONFIG, &level) < 0) {
		perror("Error in debug ioctl\n");
		cleanup_capture(capt_fd);
		cleanup_display(display_fd);
		close(preview_fd);
		close(rsz_fd);
		fclose(outp_f);
		exit(1);
	} 
#endif

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
				if (en_preview_rsz) {
					if (do_preview_resize(preview_fd, 
								in_width, 
								in_height/2,
								capbuf_addr,
								display_buf,
								out_width,
								out_height) < 0) {
						printf("preview error\n");
					
						putDisplayBuffer(display_fd, display_buf,out_width*out_height*BYTESPERPIXEL);
						return_capture_buffer(capt_fd, index);
						quit=1;
						continue;
					}
				} else {
					printf("frame = %d\n", frame_count);
					src = (void *)capbuf_addr;
					dest = display_buf;		
					for (i = 0 ; i < (in_height/2); i++) {
						memcpy(src,dest, (in_width*2));
						src += (in_width*2);
						dest += (out_width*2); 
					}
				}
				putDisplayBuffer(display_fd, display_buf,out_width*out_height*BYTESPERPIXEL);
			}
			if (return_capture_buffer(capt_fd, index) < 0) {
				printf("dispay_frame error\n");
				quit=1;
			}
#if 0
			if (frame_count == 10000) {
				//fwrite(capbuf_addr,1,width*height*2,outp_f);
				quit=1;
			}
#endif
		}
	}
	printf("Cleaning capture\n");
	cleanup_capture(capt_fd);
	printf("Cleaning display\n");
	cleanup_display(display_fd);
	printf("Cleaning display - end\n");
	cleanup_preview(preview_fd);
	printf("closing preview- end\n");
	close(rsz_fd);
	printf("closing resize - end\n");
	fclose(outp_f);
	exit(0);
}

int init_preview_buffers(int fd, int out_width, int out_height)
{
	struct imp_reqbufs req_buf;
	struct imp_buffer buf_out;
	int i,j;


	req_buf.buf_type = IMP_BUF_OUT1;
	req_buf.size = (out_width*out_height*BYTESPERPIXEL);
	req_buf.count = 3;
	
	if (ioctl(fd, PREV_REQBUF, &req_buf) < 0) {
		perror("Error in PREV_REQBUF for IMP_BUF_OUT1\n");
		return -1;
	}

	for (i = 0; i < 3; i++) {
		buf_out.index = i;
		buf_out.buf_type = IMP_BUF_OUT1;
		if (ioctl(fd, PREV_QUERYBUF, &buf_out) < 0) {
			perror("Error in PREV_QUERYBUF for IMP_BUF_OUT1\n");
			return -1;
		}
		prev_rsz_out_buffers1[i].index = i;
		prev_rsz_out_buffers1[i].offset = buf_out.offset;
		prev_rsz_out_buffers1[i].length = buf_out.size;
		prev_rsz_out_buffers1[i].start = mmap(
									NULL,
									buf_out.size, 
									PROT_READ|PROT_WRITE, 
									MAP_SHARED, 
									fd, 
									buf_out.offset);
		
		if (prev_rsz_out_buffers1[i].start == MAP_FAILED) {
			for (j= 0; j < i; j++) {
				munmap(
					prev_rsz_out_buffers1[j].start,
					prev_rsz_out_buffers1[j].length 
					);
			}
			printf("init_preview_buffers: error in mmap\n");
			return -1;
		}
	}
	return 0;
}

