/* This file contains the DM355 Specific APIs,Constants and Global Variables definitions used for the initialization, Configuration and usage of IPIPE modules provided in the Linux Support package version 2.10

			Author	: 	Arun Vijay Mani
			Date	:	06/12/2008
			Version	:	0.1
***************************************************************************************************************************/
//Including the files
#include "ipipe_interface.h"
#include "ipipe_dm355_interface.h"

int Imp_Open(int prev_device_id, int mode)
{
	int fd;
	if(prev_device_id == DEV_PREV)
	{
		fd = open(DEV_PREV_NAME,mode);
		if( fd <= 0)
		{
			printf("Error in opening the Previewer Device \n");
			return -1;
		}
	}
	else if(prev_device_id == DEV_RSZ)
	{
		fd = open(DEV_RSZ_NAME, mode);
		if( fd == -1)
		{
			printf("Error in opening the Resizer Device \n");
			return -1;
		}
	}
	return fd;
}

int Prev_Init(int fd_prev, int oper_mode, struct prev_channel_config * user_prev_config, int width, int height, int in_format)
{
	struct prev_single_shot_config *user_prev_ss_config = NULL;
	struct prev_continous_config *user_prev_cont_config = NULL;
	//struct prev_channel_config user_prev_config;
	
	//First thing to do is set the operation mode of the previewer
	if( ioctl(fd_prev, PREV_S_OPER_MODE, &oper_mode) < 0)
	{
		printf("Error is setting the operation mode for Previewer \n");
		return -1;
	}

	// Second is to verify that the mode is set correct
	if( ioctl(fd_prev, PREV_G_OPER_MODE, &oper_mode) < 0)
	{
		printf("Error is getting the operation mode for Previewer \n");
		return -1;
	}

	printf(" The operation mode changed successfully to ");
	if (oper_mode == IMP_MODE_SINGLE_SHOT) 
	{
		printf(" %s", "Single Shot\n");
	}
	else
	{
		printf(" %s", "Continuous\n");
	}

	// Initialize the previewer channel based on the operation mode
	//user_prev_config = * (struct  prev_channel_config *)  user_prev_config_void;
	user_prev_config = (struct prev_channel_config *) malloc(sizeof(struct prev_channel_config));
	user_prev_config->oper_mode = oper_mode;

	if (oper_mode == IMP_MODE_SINGLE_SHOT) 
	{
		user_prev_config->len = sizeof(struct prev_single_shot_config);	
	}
	else
	{
		//user_prev_config.len = sizeof(struct prev_continous_config);
	}
		
	user_prev_config->config = NULL; //This will initialize the config to default values of the operation mode.

	if (ioctl(fd_prev, PREV_S_CONFIG, user_prev_config) < 0 )
	{
		printf("Error in setting the default values for the previewer \n");
		return -1;
	}
	
	// Now get the default values before setting the params for previewer

	user_prev_config->oper_mode = oper_mode;

	if (oper_mode == IMP_MODE_SINGLE_SHOT) 
	{
		user_prev_ss_config = (struct prev_single_shot_config *) malloc(sizeof(struct  prev_single_shot_config));
		user_prev_config->len = sizeof(struct prev_single_shot_config);
		user_prev_config->config = &user_prev_ss_config;
		user_prev_ss_config->input.image_width = width;
		user_prev_ss_config->input.image_height = height;
		user_prev_ss_config->input.ppln = width + 8;
		user_prev_ss_config->input.lpfr = height = 10;
		if (in_format == 0)
		{
			user_prev_ss_config->input.pix_fmt = IPIPE_BAYER;
			user_prev_ss_config->output.pix_fmt = IPIPE_UYVY;
		}
		else
		{
			user_prev_ss_config->input.pix_fmt = IPIPE_BAYER;
			user_prev_ss_config->output.pix_fmt = IPIPE_UYVY;
		}			
	}
	else
	{
		//user_prev_cont_config = (struct prev_continous_config *) malloc(sizeof(struct  prev_continous_config));
		//user_prev_config.len = sizeof(struct prev_continous_config);
		//user_prev_config.config = &user_prev_cont_config;
	}
	
	return 0;
}

int Set_Prev_Config(int fd, struct prev_channel_config * user_prev_config)
{
	if(ioctl(fd, PREV_S_CONFIG, &user_prev_config) == -1)
	{
		printf("Error in Seeting the basic configuration of the Previewer \n");
		return -1;
	}
	printf("Successfully configured the previewer \n");
	return 0;
}
	
int Init_Prev_Param(int fd)
{
	struct prev_cap cap;
	struct prev_module_param mod_param;
	int ret = 0;
	
	cap.index = 0;
	while (1)
	{
		ret = ioctl(fd, PREV_ENUM_CAP, &cap);
		if (ret < 0)
			break;
		
		strcpy(mod_param.version,cap.version);
		switch (cap.module_id) 
		{
			case PREV_PRE_FILTER:
				mod_param.len = sizeof(struct prev_prefilter);
				break;
			case PREV_DFC:
				mod_param.len = sizeof(struct prev_dfc);
				break;
			case PREV_NF:
				mod_param.len = sizeof(struct prev_nf);
				break;
			case PREV_WB:
				mod_param.len = sizeof(struct prev_wb);
				break;
			case PREV_RGB2RGB:
				mod_param.len = sizeof(struct prev_rgb2rgb);
				break;
			case PREV_GAMMA:
				mod_param.len = sizeof(struct prev_gamma);
				break;
			case PREV_RGB2YUV:
				mod_param.len = sizeof(struct prev_rgb2yuv);
				break;
			case PREV_LUM_ADJ:
				mod_param.len = sizeof(struct prev_lum_adj);
				break;
			case PREV_YUV422_CONV:
				mod_param.len = sizeof(struct prev_yuv422_conv);
				break;
			case PREV_YEE:
				mod_param.len = sizeof(struct prev_yee);
				break;
			case PREV_FCS:
				mod_param.len = sizeof(struct prev_fcs);
				break;
			default:
				return -1;
		}

		mod_param.module_id = cap.module_id;
		// using defaults
		mod_param.param = NULL;
		printf("Setting default for %s\n", cap.module_name);
		if (ioctl(fd, PREV_S_PARAM, &mod_param) < 0) 
		{
			printf("Error in Setting Preview params from driver\n");
			return -1;
		}
		cap.index ++;
	}
	return 0;
}
int Init_Prev_Buffer(int fd, int buf_type, struct buffer * io_buffer, int width, int height)
{
	struct imp_reqbufs req_buf;
	struct imp_buffer buf_io[3];
	/*struct imp_buffer buf_out1[3];
	struct imp_buffer buf_out2[3];*/
	int i;
	

	req_buf.buf_type = buf_type;
	req_buf.size = width*height;
	req_buf.count = 3;
	if (ioctl(fd, PREV_REQBUF, &req_buf) < 0)
	{
		printf("Error in setting the buffer for the IPIPE \n");
		return -1;
	}
	for(i = 0; i < 3; i++)
	{
		buf_io[i].index = i;
		buf_io[i].buf_type = buf_type;
		if (ioctl(fd, PREV_QUERYBUF, &buf_io[i]) < 0)
		{
			printf(" Error in initializing(PREV_QUERYBUF) the buffer \n");
			return -1;
		}	
	}
	io_buffer->start = mmap(NULL, buf_io[0].size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, buf_io[0].offset);
	if (io_buffer->start == MAP_FAILED)
	{
		printf("Error in mapping the buffer \n");
		return -1;
	}
	return 0;
}
int Set_Prev_Buf(int fd, struct imp_buffer* in_buf, struct imp_buffer* buf_out1)
{
	struct imp_convert * conv_prev;
	bzero(conv_prev,sizeof(struct imp_convert));
	conv_prev->in_buff.buf_type = IMP_BUF_IN;
	conv_prev->in_buff.index = in_buf->index;
	conv_prev->in_buff.offset = in_buf->offset;
	conv_prev->in_buff.size = in_buf->size;
	conv_prev->out_buff1.buf_type = IMP_BUF_OUT1;
	conv_prev->out_buff1.index = in_buf->index;
	//conv_prev->out_buff1.offset = buf_out1->offset;
	//conv_prev->out_buff1.size = in_buf->size;
	if (ioctl(fd, PREV_PREVIEW, &conv_prev) < 0)
	{
		printf(" Error in doing PREV_PREVIEW \n");
		return -1;
	}
	return 0;
}


	

	

	
			
		 
	


		

	

		

	

	
	



	
