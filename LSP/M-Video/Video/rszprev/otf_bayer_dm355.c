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
#include <media/davinci/mt9t001.h>
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
#define CAP_FORMAT1		(V4L2_STD_MT9T001_480p_30FPS)
#define V4L2VID0_DEVICE    "/dev/video2"
#define V4L2VID1_DEVICE    "/dev/video3"
#define CLEAR(x) memset (&(x), 0, sizeof (x))


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
	rsz_cont_config.en_output1 = 1;
	rsz_cont_config.output2.enable = 0;
	rsz_chan_config.len = sizeof(struct rsz_continuous_config);
	rsz_chan_config.config = &rsz_cont_config;
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
	
	int preview_fd, ret;
	unsigned int oper_mode;
	struct prev_channel_config prev_chan_config;
	struct prev_continuous_config prev_cont_config; // continuous mode
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
	
	prev_cont_config.input.gain = 512;
#if 0
	prev_cont_config.input.colp_elep= IPIPE_RED;
	prev_cont_config.input.colp_elop= IPIPE_GREEN_RED;
	prev_cont_config.input.colp_olep= IPIPE_GREEN_BLUE;
	prev_cont_config.input.colp_olop= IPIPE_BLUE;
#endif

/*
	B Gb
	Gr R
*/
#if 0
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

	bzero(&prev_cont_config, sizeof (struct prev_continuous_config));
	// read again and verify
	if (ioctl(preview_fd, PREV_G_CONFIG, &prev_chan_config) < 0) {
		perror("Error in getting configuration from driver\n");
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
		if ((cap.module_id == PREV_GAMMA) && flag) {
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

static int configCCDCraw(int capt_fd, int width, int height)
{
//	struct mt9t001_params mtparams;
	struct ccdc_config_params_raw raw_params = {
       .pix_fmt = CCDC_PIXFMT_RAW,
       .frm_fmt = CCDC_FRMFMT_PROGRESSIVE,
       .win = VPFE_WIN_VGA,
       .fid_pol = CCDC_PINPOL_POSITIVE,
       .vd_pol = CCDC_PINPOL_POSITIVE,
       .hd_pol = CCDC_PINPOL_POSITIVE,
       .image_invert_enable = 0,
       .data_sz = _12BITS,
       .med_filt_thres = 0,
       .mfilt1 = NO_MEDIAN_FILTER1,
       .mfilt2 =  NO_MEDIAN_FILTER2,
       .ccdc_offset = 0,
       .lpf_enable = 0,
       .datasft = 2,
       .alaw = {
          .b_alaw_enable = 0,
          .gama_wd = 0},
       .blk_clamp = {
          .b_clamp_enable = 1,
          .sample_pixel = 1,
          .start_pixel = 0,
          .dc_sub = 0},
       .blk_comp = {
          .b_comp = 0,
          .gb_comp = 0,
          .gr_comp = 0,
          .r_comp = 0},
       .vertical_dft = {
          .ver_dft_en = 0},
       .lens_sh_corr = {
          .lsc_enable = 0},
	   .data_formatter_r = {
       	  .fmt_enable = 0},
       .color_space_con = {
          .csc_enable = 0},

/* Gr R
   B Gb
*/
#if 1
	   .col_pat_field0 = {
		  .elep = CCDC_GREEN_RED,
		  .elop = CCDC_RED,
		  .olep = CCDC_BLUE,
		  .olop = CCDC_GREEN_BLUE},
	   .col_pat_field1 = {
		  .elep = CCDC_GREEN_RED,
		  .elop = CCDC_RED,
		  .olep = CCDC_BLUE,
		  .olop = CCDC_GREEN_BLUE}
#endif
/*
   B Gb
   Gr R
*/
#if 0
	   .col_pat_field0 = {
		  .elep = CCDC_BLUE,
		  .elop = CCDC_GREEN_BLUE,
		  .olep = CCDC_GREEN_RED,
		  .olop = CCDC_RED},
	   .col_pat_field1 = {
		  .elep = CCDC_BLUE,
		  .elop = CCDC_GREEN_BLUE,
		  .olep = CCDC_GREEN_RED,
		  .olop = CCDC_RED},
#endif
    };

	raw_params.win.width = width;
	raw_params.win.height = height;
	if (-1 == ioctl(capt_fd, VPFE_CMD_CONFIG_CCDC_RAW, &raw_params)) {
		perror("InitDevice:ioctl:VPFE_CMD_CONFIG_CCDC_RAW:");
		return -1;
	}
#if 0
	if (-1 == ioctl(fdCapture, VPFE_CMD_G_MT9T001_PARAMS, &mtparams)) {
		perror("InitDevice:ioctl: VPFE_CMD_G_MT9T001_PARAMS");
		exit(0);
	}

	printf("the col size is : %d \n", mtparams.format.col_size);
#endif
	return 0;
}
	
static int SetDataFormat(int fdCapture, v4l2_std_id std, int width, int height)
{
	v4l2_std_id ipipe_std, cur_std;
	struct v4l2_format fmt;
	struct v4l2_input input;
	int index;
	int ret;
	cur_std = ipipe_std = std;

	printf("SetDataFormat:setting std to %d\n", (int)cur_std);

	// first set the input
	index = 0;
	if (-1 == ioctl (fdCapture, VIDIOC_S_INPUT, &index)) {
		perror("ioctl:VIDIOC_S_INPUT failed\n");
		return -1;
	}

  	printf ("InitDevice:ioctl:VIDIOC_S_INPUT, selected input\n");
	printf("\nCalling configCCDCraw()\n");
	ret = configCCDCraw(fdCapture, width, height);
	if (ret < 0) {
		perror("configCCDCraw");
		return -1;
	} else {
		printf("\nconfigCCDCraw Done\n");
	}

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
	fmt.fmt.pix.field = V4L2_FIELD_NONE;
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
	req.count = APP_NUM_BUFS;
	req.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	req.memory = V4L2_MEMORY_MMAP;
	ret = ioctl(fdDisplay, VIDIOC_REQBUFS, &req);
	if (ret) {
		perror("cannot allocate memory\n");
		goto error;
	}

	for (i = 0; i < req.count; i++) {
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.index = i;
		ret = ioctl(fdDisplay, VIDIOC_QUERYBUF, &buf);
		if (ret) {
			perror("VIDIOC_QUERYCAP failed\n");
			for (j = 0; j < i; j++)
				munmap(display_buffers[j].start,
						display_buffers[j].length);
			goto error;
		}
		display_buffers[i].length = buf.length;
		printf("the buf length is = %d \n", buf.length);
		display_buffers[i].index= buf.index;

		display_buffers[i].start =
			mmap(NULL, buf.length, PROT_READ | PROT_WRITE,
					MAP_SHARED, fdDisplay, buf.m.offset);

		if (display_buffers[i].start == MAP_FAILED) {
			printf("Cannot mmap = %d buffer\n", i);
			for (j = 0; j < i; j++)
				munmap(display_buffers[j].start,
						display_buffers[j].length);
			goto error;
		}
		memset(display_buffers[i].start, 0, 720*480*2);
	}

	fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	fmt.fmt.pix.width = 720;
	fmt.fmt.pix.height = 480;
	fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
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
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.index = i;
		buf.memory = V4L2_MEMORY_MMAP;
		ret = ioctl(fdDisplay, VIDIOC_QBUF, &buf);
		if (ret) {
			printf("VIDIOC_QBUF\n");
			for (j = 0; j < req.count; j++)
				munmap(display_buffers[j].start,
						display_buffers[j].length);
			goto error;
		}
	}

	a = 0;
	ret = ioctl(fdDisplay, VIDIOC_STREAMON, &a);
	if (ret < 0) {
		perror("VIDIOC_STREAMON failed\n");
		for (i = 0; i < req.count; i++)
			munmap(display_buffers[i].start, display_buffers[i].length);
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

int *get_capture_frame(int fdCapture, int *index)
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
	return (capture_buffers[buf.index].start);
	
}

void *getDisplayBuffer(int fd)
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
	return display_buffers[buf.index].start;
}

int putDisplayBuffer(int fd, void *addr)
{
	struct v4l2_buffer buf;
	int i, index = 0;
	int ret=0;

	if (addr == NULL)
		return -1;

	memset(&buf, 0, sizeof(buf));

	for (i = 0; i < APP_NUM_BUFS; i++) {
		if (addr == display_buffers[i].start) {
			index = display_buffers[i].index;
			break;
		}
	}

	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	buf.memory = V4L2_MEMORY_MMAP;
	buf.index = index;
	ret = ioctl(fd, VIDIOC_QBUF, &buf);
	return ret;
}

int display_frame(int fd, void *ptrBuffer,int width, int height)
{
	static int xoffset = 0;
	static int yoffset = 0;
	int i;
	char *dst, *temp;
	char *src;

	src = ptrBuffer;
	temp = dst = getDisplayBuffer(fd);

	if (dst==NULL) {
		perror("Error in getting buffer from display\n");
		return -1;
	}
	for (i = 0; i < height; i++) {
		memcpy(dst, src, width * 2 );
		dst += (720 * 2);
		src += (width * 2);
	}
	return putDisplayBuffer(fd,temp); 
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

int cleanup_display(int fd)
{
	int i;
	enum v4l2_buf_type type;

	type = V4L2_BUF_TYPE_VIDEO_OUTPUT;

	if (-1 == ioctl(fd, VIDIOC_STREAMOFF, &type)) {
		perror("cleanup_display :ioctl:VIDIOC_STREAMOFF");
	}

	for (i = 0; i < APP_NUM_BUFS; i++) {
		munmap(display_buffers[i].start,
              display_buffers[i].length);			
	}
	if (close(fd) < 0)
		perror("Error in closing device\n");
}

int main(int argc, char *argp[])
{
	char shortoptions[] = "w:h:t:";
	int mode = O_RDWR,c,ret,index;
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
	FILE *outp_f;
	 


	for(;;) {
		c = getopt_long(argc, argp, shortoptions, NULL, (void *)&index);
		if(-1 == c)
			break;
		switch(c) {
			case 'w':
				width = atoi(optarg);
				break;
			case 'h':
				height = atoi(optarg);
				break;
			case 't':
				flag = atoi(optarg);
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
	rsz_fd = init_resizer(user_mode);
	if (rsz_fd < 0) {
		exit(1);
		fclose(outp_f);
	}

	// initialize previewer in continuous mode
	preview_fd = init_previewer(user_mode);

	if (preview_fd < 0) {
		close(rsz_fd);
		fclose(outp_f);
		exit(1);
	}
	
	// intialize capture
	capt_fd = init_camera_capture(CAP_FORMAT1, width,height);

	if (capt_fd < 0) {
		close(preview_fd);
		close(rsz_fd);
		fclose(outp_f);
		exit(1);
	}
	
	display_fd = init_display_device(0, width, height);
	if (display_fd < 0) {
		close(preview_fd);
		close(rsz_fd);
		close(capt_fd);
		fclose(outp_f);
		exit(1);
	}

	printf("Initialized display\n");	


	if (start_capture_streaming(capt_fd) < 0) {
		cleanup_capture(capt_fd);
		cleanup_display(display_fd);
		close(preview_fd);
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
			if (display_frame(display_fd, capbuf_addr,width,height) < 0) {
				printf("dispay_frame error\n");
				return_capture_buffer(capt_fd, index);
				quit=1;
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
	close(preview_fd);
	printf("closing preview- end\n");
	close(rsz_fd);
	printf("closing resize - end\n");
	fclose(outp_f);
	exit(0);
}

