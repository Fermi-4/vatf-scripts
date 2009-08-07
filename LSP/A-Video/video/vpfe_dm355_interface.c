/* This file contains the DM355 Specific APIs,Constants and Global Variables definitions used for the initialization, Configuration and usage of VPFE modules provided in the Linux Support package version 2.10

			Author	: 	Arun Vijay Mani
			Date	:	06/17/2008
			Version	:	0.1
***************************************************************************************************************************/
//Including the files
#include "vpfe_interface.h"
#include "vpfe_dm355_interface.h"

int Vpfe_Open(int device_id, int mode)
{
	int fd_capture;
	if(device_id == VID_IN0)
	{
		fd_capture = open(VID_IN0_DEV,mode);
		if(fd_capture <= 0)
		{
			printf("Error in opening the VPFE Device \n");
			return -1;
		}
	}
	return fd_capture;
}

int Vpfe_Open_Close( int ch )
{
	int fd_cap;
	if(ch == 0)
	{
		fd_cap = open(VID_IN0_DEV, O_RDWR);
	}
		
	if(fd_cap < 0)
	{
		return -1;
	}
	if((close(fd_cap)) < 0)
	{
		return -1;
	}
	return 0;  
}

int Init_Capture(int fd, int ip_type, int ch, int plat)
{
	struct v4l2_capability cap;
	struct v4l2_input input_fmt;
	int vid_type = 0;
	char vid_type_nm[15];
	
	/* Check the capture capabilities */
	if (ioctl (fd, VIDIOC_QUERYCAP, &cap) == -1)
    	{
      		printf ("Init:ioctl:VIDIOC_QUERYCAP:\n");
      		return -1;
    	}

	if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE))
    	{
      		printf ("Init: capture is not supported on \n");
      		return -1;
    	}

	
	/* Check the MMAP capability of the capture device */
	if (!(cap.capabilities & V4L2_CAP_STREAMING))
    	{
      		printf ("Init:IO method MMAP is not supported on\n");
    		return -1;
	}

	memset (&input_fmt, 0, sizeof (input_fmt));
	input_fmt.index = 0;
	if(plat == 0 || plat == 1 ) // For DM355 and DM6446
	{
		if(ip_type == 0)
		{
			strcpy(vid_type_nm,"COMPOSITE");
		}
		else if(ip_type == 1)
		{
			strcpy(vid_type_nm,"SVIDEO");
		}
		else
		{
			printf("Invalid Input type for the platform \n");
			return -1;	
		}
	}
	else if(plat == 3)
	{
		if(ip_type == 0)
		{
			strcpy(vid_type_nm,"SVIDEO");
		}
		else if(ip_type == 1)
		{
			strcpy(vid_type_nm,"COMPONENT");
		}
		else
		{
			printf("Invalid Input type for the platform \n");
			return -1;	
		}
	}
	else if(plat == 2 && ch == 0)
	{
		if(ip_type == 0)
		{
			strcpy(vid_type_nm,"COMPOSITE");
		}
		else if(ip_type == 1)
		{
			strcpy(vid_type_nm,"COMPONENT");
		}
		else
		{
			printf("Invalid Input type for the platform \n");	
			return -1;
		}
	}
	else if(plat == 2 && ch ==1)
	{
		if(ip_type == 0)
		{
			strcpy(vid_type_nm,"SVIDEO");
		}
		else
		{
			printf("Invalid Input type for the platform \n");	
			return -1;
		}
	}
			
	while(1)	
	{
		if ( ioctl (fd, VIDIOC_ENUMINPUT, &input_fmt) == -1)
		{
			printf (" Init : VIDIOC_ENUMINPUT \n");
			return -1;
  		}
			
		if(strcmp(input_fmt.name,vid_type_nm) == 0)
		{
			
			vid_type = input_fmt.index;
			printf("Set to input %s \n", input_fmt.name);
			printf(" The type is : %d \n", input_fmt.type);
			break;
		}
		else
		{
			input_fmt.index = (input_fmt.index) + 1;
		}
		
	}
	
  	if ( ioctl (fd, VIDIOC_S_INPUT, &vid_type) == -1)
	{
		printf (" Init AVM : VIDIOC_S_INPUT \n");
		return -1;
  	}	
  	
	if ( ioctl (fd, VIDIOC_G_INPUT, &vid_type) == -1)
	{
		printf (" Init : VIDIOC_G_INPUT \n");
		return -1;
  	}
  	input_fmt.index = vid_type;

  
  	if ( ioctl (fd, VIDIOC_ENUMINPUT, &input_fmt) == -1)
	{
		printf (" Init : VIDIOC_ENUMINPUT \n");
		return -1;
  	}
  	printf ("Current input: %s\n", input_fmt.name);

	return 0;
}

int V4l2_Cap_std_Ioctl(int fd, int stds ) 
{
	v4l2_std_id prev_std, cur_std, check_std;
	struct v4l2_standard std_struct;
	int std_idx = 0;
	//int cap_width, cap_height;
	if(stds == 0)
		cur_std = prev_std = V4L2_STD_NTSC;
	else if(stds == 1)
		cur_std = prev_std = V4L2_STD_PAL;
	else if(stds == 2)
		cur_std = prev_std = V4L2_STD_525P_60;
	else if(stds == 3)
		cur_std = prev_std = V4L2_STD_625P_50;	
	else if(stds == 4)
		cur_std = prev_std = V4L2_STD_720P_60;
	else if(stds == 5)
		cur_std = prev_std = V4L2_STD_1080I_50;
	else if(stds == 6)
		cur_std = prev_std = V4L2_STD_1080I_60;
	else if(stds == 7)
		cur_std = prev_std = V4L2_STD_720P_50;

	if ( ioctl (fd, VIDIOC_S_STD, &cur_std) == -1)
    	{
      		printf ("Init : unable to set capture standard automatically\n");
		return -1;
    	}
  	sleep (1);
	if ( ioctl (fd, VIDIOC_G_STD, &check_std) == -1)
    	{
      		printf ("Init : unable to set capture standard automatically\n");
		return -1;
    	}

	std_struct.index = 0;
	while(1)
	{
		
		if ( ioctl (fd, VIDIOC_ENUMSTD, &std_struct) == -1)
    		{
      			printf ("Init : unable to set capture standard automatically\n");
			return -1;
    		}
		if(stds == 0 && (!(strcmp(std_struct.name,"NTSC"))))
		{
			printf("The std is set properly \n");
			return 0;
		}
		else if(stds == 1 && (!(strcmp(std_struct.name,"PAL"))))
		{
			printf("The std is set properly \n");
			return 0;
		}
		else if(stds == 2 && std_struct.id == V4L2_STD_525P_60)
		{
			printf("The std is set properly \n");
			return 0;
		}
		else if(stds == 0 && std_struct.id == V4L2_STD_625P_50)
		{
			printf("The std is set properly \n");
			return 0;
		}
		else if(stds == 0 && std_struct.id == V4L2_STD_720P_60)
		{
			printf("The std is set properly \n");
			return 0;
		}
		else if(stds == 0 && std_struct.id == V4L2_STD_1080I_50)
		{
			printf("The std is set properly \n");
			return 0;
		}
		else if(stds == 0 && std_struct.id == V4L2_STD_1080I_60)
		{
			printf("The std is set properly \n");
			return 0;
		}
		else if(stds == 0 && std_struct.id == V4L2_STD_720P_50)
		{
			printf("The std is set properly \n");
			return 0;
		}
		else
		{
			std_struct.index = std_struct.index + 1;
			
		}
	}
	return 0;
}

int V4l2_cap_std_neg(int fd, int val_ioctl, int neg_val)
{
	v4l2_std_id prev_std, cur_std, check_std;
	struct v4l2_standard std_struct;
	int std_idx = 0;

	if(val_ioctl == 0)
	{
		if(neg_val == 0)
		{
			if ( ioctl (fd, VIDIOC_G_STD, NULL) == -1)
    			{
      				printf ("Init : unable to set capture standard automatically\n");
				return 0;
    			}
		}
		/*else if ( ioctl (fd, VIDIOC_G_STD, &neg_val) == -1)
    		{
      			printf ("Init : unable to set capture standard automatically\n");
			return 0;
    		}*/
	}
	else if(val_ioctl == 1)
	{
		if(neg_val == 0)
		{
			if ( ioctl (fd, VIDIOC_S_STD, NULL) == -1)
    			{
      				printf ("Init : unable to set capture standard automatically\n");
				return 0;
    			}
		}
		//neg_val = 20;
		//printf(" the neg_val is %d"
		cur_std = 0x10000000;//(v4l2_std_id) -1;
		if ( ioctl (fd, VIDIOC_S_STD, &cur_std) == -1)
    		{
      			printf ("Init : unable to set capture standard automatically\n");
			return 0;
    		}
	}
	else if(val_ioctl == 2)
	{
		if(neg_val == 0)
		{
			if ( ioctl (fd, VIDIOC_ENUMSTD, NULL) == -1)
    			{
      				printf ("Init : unable to set capture standard automatically\n");
				return 0;
    			}
		}
		printf(" the neg val is %d \n",neg_val);
		std_struct.index = (unsigned int)neg_val;
		if ( ioctl (fd, VIDIOC_ENUMSTD, &std_struct) == -1)
    		{
      			printf ("Init : unable to set capture standard automatically\n");
			return 0;
    		}
	}
	return -1;
}

int V4l2_Cap_fmt_Ioctl(int fd, int fmts)
{
	struct v4l2_format fmt, fmt_g;
	struct v4l2_fmtdesc fmtdesc;

	CLEAR(fmt);
	CLEAR(fmt_g);

	fmt.fmt.pix.height = 720;
	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt.fmt.pix.width = 480;	
	//fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;

	if(fmts == 0)
	{
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	}
	else if(fmts == 1)
	{
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_NV12;
	}

	if ( ioctl (fd, VIDIOC_TRY_FMT, &fmt) == -1)
    	{
      		printf ("SetDataFormat:ioctl:VIDIOC_TRY_FMT\n");
		return -1;
    	}

	if ( ioctl (fd, VIDIOC_S_FMT, &fmt) == -1)
    	{
      		printf ("SetDataFormat:ioctl:VIDIOC_S_FMT\n");
		return -1;
    	}
	
	fmt_g.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if ( ioctl (fd, VIDIOC_G_FMT, &fmt_g) == -1)
    	{
      		printf ("SetDataFormat:ioctl:VIDIOC_GET_FMT\n");
		return -1;
    	}
	fmtdesc.index = 0;
	fmtdesc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	while(1)
	{
		if ( ioctl (fd, VIDIOC_ENUM_FMT, &fmtdesc) == -1)
    		{
      			printf ("SetDataFormat:ioctl:VIDIOC_ENUM_FMT\n");
			return -1;	
    		}
		
		if(fmts == 0 && (fmtdesc.pixelformat == 1498831189))
		{
			printf("The FMT is set properly \n");
			return 0;
		}
		else if(fmts == 1 && (fmtdesc.pixelformat == 842094158))
		{
			printf("The FMT is set properly \n");
			return 0;
		}
		else
		{
			fmtdesc.index = fmtdesc.index + 1;
		}	
	}
	return 0;
}	

int V4l2_cap_fmt_neg(int fd, int val_ioctl, int neg_val)
{
	struct v4l2_format fmt, fmt_g;
	struct v4l2_fmtdesc fmtdesc;	
	if(val_ioctl == 0)
	{
		if(neg_val == 0)
		{
			if ( ioctl (fd, VIDIOC_G_FMT, NULL) == -1)
    			{
      				printf ("Init : unable to set capture format automatically\n");
				return 0;
    			}
		}
		/*else if ( ioctl (fd, VIDIOC_G_STD, &neg_val) == -1)
    		{
      			printf ("Init : unable to set capture standard automatically\n");
			return 0;
    		}*/
	}
	else if(val_ioctl == 1)
	{
		if(neg_val == 0)
		{
			if ( ioctl (fd, VIDIOC_S_FMT, NULL) == -1)
    			{
      				printf ("Init : unable to set capture format automatically\n");
				return 0;
    			}
		}
		//neg_val = 20;
		//printf(" the neg_val is %d"
		//cur_std = 0x10000000;//(v4l2_std_id) -1;
		
		/*if ( ioctl (fd, VIDIOC_S_STD, &cur_std) == -1)
    		{
      			printf ("Init : unable to set capture standard automatically\n");
			return 0;
    		}*/
	}
	else if(val_ioctl == 2)
	{
		if(neg_val == 0)
		{
			if ( ioctl (fd, VIDIOC_ENUM_FMT, NULL) == -1)
    			{
      				printf ("Init : unable to set capture format automatically\n");
				return 0;
    			}
		}
		//printf(" the neg val is %d \n",neg_val);
		//std_struct.index = (unsigned int)neg_val;
		fmtdesc.index = 20;
		fmtdesc.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		if ( ioctl (fd, VIDIOC_ENUMSTD, &fmtdesc) == -1)
    		{
      			printf ("Init : unable to set capture format automatically\n");
			return 0;
    		}
	}
	else if(val_ioctl == 3)
	{
		if(neg_val == 0)
		{
			if ( ioctl (fd, VIDIOC_TRY_FMT, NULL) == -1)
    			{
      				printf ("Init : unable to set capture format automatically\n");
				return 0;
    			}
		}
		//neg_val = 20;
		//printf(" the neg_val is %d"
		//cur_std = 0x10000000;//(v4l2_std_id) -1;
		
		/*if ( ioctl (fd, VIDIOC_S_STD, &cur_std) == -1)
    		{
      			printf ("Init : unable to set capture standard automatically\n");
			return 0;
    		}*/
	}

	return -1;
}

int Init_Fmt_Cap(int fd, v4l2_std_id std_format, int cap_width, int cap_height, int device_type)
{
	v4l2_std_id prev_std, cur_std;
	struct v4l2_format fmt;
	int min;

	
	cur_std = prev_std = std_format;
	
	if ( ioctl (fd, VIDIOC_S_STD, &cur_std) == -1)
    	{
      		printf ("Init : unable to set capture standard automatically\n");
		return -1;
    	}
  	sleep (1);
	if(device_type == YUV_CAP)
	{
		if ( ioctl (fd, VIDIOC_QUERYSTD, &cur_std) == -1)
    		{
      			printf ("Init Capture_VIDIOC_QUERYSTD:\n");
			return -1;
    		}

		if (cur_std == V4L2_STD_NTSC)
    			printf ("Input video standard is NTSC.\n");
	  	else if (cur_std == V4L2_STD_PAL)
    			printf ("Input video standard is PAL.\n");
	  	else if (cur_std == V4L2_STD_PAL_M)
    			printf ("Input video standard is PAL-M.\n");
		else if (cur_std == V4L2_STD_PAL_N)
    			printf ("Input video standard is PAL-N.\n");
	  	else if (cur_std == V4L2_STD_SECAM)
    			printf ("Input video standard is SECAM.\n");
	  	else if (cur_std == V4L2_STD_PAL_60)
    			printf ("Input video standard to PAL60.\n");

		CLEAR(fmt);
		fmt.fmt.pix.height = cap_height;
		fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		fmt.fmt.pix.width = cap_width;	
  		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	}
	else
	{
		CLEAR(fmt);
		fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
		fmt.fmt.pix.width = cap_width;
		fmt.fmt.pix.height = cap_height;
		fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_SBGGR8;
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	}
	printf("Format init \n");
	if ( ioctl (fd, VIDIOC_S_FMT, &fmt) == -1)
    	{
      		printf ("SetDataFormat:ioctl:VIDIOC_S_FMT\n");
		return -1;
    	}

	return 0;
}
int V4l2_Cap_crop_Ioctl(int fd)
{
	struct v4l2_crop crop, crop_g;
	struct v4l2_cropcap cropcap;

	
	cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

  	if (ioctl (fd, VIDIOC_CROPCAP, &cropcap) == -1)
    	{
      		printf ("InitDevice:ioctl:VIDIOC_CROPCAP\n");
      		/*ignore error */
    	}

	crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

	crop.c.height = 240;
	crop.c.left = 0;
	crop.c.width = 320;
	crop.c.top = 0;
	
	if ( ioctl(fd, VIDIOC_S_CROP, &crop) == -1)
	{
		printf (" INIT : VIDIOC_S_CROP\n");
		return -1;
	}

	crop_g.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if ( ioctl(fd, VIDIOC_G_CROP, &crop_g) == -1)
	{
		printf (" INIT : VIDIOC_S_CROP\n");
		return -1;
	}

	if(crop_g.c.height != 240 || crop_g.c.width != 320)
	{
		printf("Error in setting the cropping parameters \n");
		return -1;
	}
	return 0;
}

int V4l2_cap_crop_neg(int fd, int val_ioctl)
{

	if(val_ioctl == 0)
	{
		if ( ioctl (fd, VIDIOC_G_CROP, NULL) == -1)
    		{
      			printf ("Init : unable to set capture cropping automatically\n");
			return 0;
    		}
	}
	else if(val_ioctl == 1)
	{
		if ( ioctl (fd, VIDIOC_S_CROP, NULL) == -1)
    		{
      			printf ("Init : unable to set capture cropping automatically\n");
			return 0;
    		}
	}
	else if(val_ioctl == 2)
	{
		if ( ioctl (fd, VIDIOC_CROPCAP, NULL) == -1)
    		{
      			printf ("Init : unable to set capture cropping automatically\n");
			return 0;
    		}
	}
	return -1;
}


	

int Init_Cap_Crop(int fd, int width, int height, int top, int left)
{
	struct v4l2_crop crop;

	crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

	crop.c.height = height;
	crop.c.left = left;
	crop.c.width = width;
	crop.c.top = top;
	
	if ( ioctl(fd, VIDIOC_S_CROP, &crop) == -1)
	{
		printf (" INIT : VIDIOC_S_CROP\n");
		return -1;
	}

	return 0;
}

int V4l2_Cap_buf_Ioctl(int fd, int buf_count )
{
	struct v4l2_requestbuffers req;
	struct v4l2_buffer buf, buf1;
	int nIndex =0, i, type;

	CLEAR (req);
  	req.count = buf_count;
  	req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  	req.memory = V4L2_MEMORY_MMAP;

  	if ( ioctl (fd, VIDIOC_REQBUFS, &req) == -1)
    	{
      		printf (" Init: CaptureBuffers:ioctl:VIDIOC_REQBUFS\n");
      		return -1;
    	}
	
	if (req.count < 2)
    	{
      		printf ("Init: CaptureBuffers not sufficient buffers avilable \n");
      		return -1;
    	}
	
	cap_buffers = ( struct buffer *) malloc(sizeof( struct buffer ) * req.count);
  	if (!cap_buffers)
    	{
      		printf ("Init : cannot allocate CaptureBuffers\n");
      		return -1;
    	}

  	for (nIndex = 0; nIndex < req.count; ++nIndex)
    	{

      		//CLEAR (buf);
		memset (&buf, 0, sizeof (buf));
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = nIndex;

      		if ( ioctl (fd, VIDIOC_QUERYBUF, &buf) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_QUERYBUF:\n");
	  		return -1;
		}
      		cap_buffers[nIndex].length = buf.length;
      		cap_buffers[nIndex].start = mmap (NULL, buf.length, PROT_READ | PROT_WRITE, MAP_SHARED, fd,buf.m.offset);
		if (MAP_FAILED == cap_buffers[nIndex].start)
		{
	  		printf ("Init : cannot map CaptureBuffers\n");
	  		return -1;
		}
    	}

	for (i = 0; i < buf_count; i++)
    	{
      		CLEAR (buf);
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = i;
      	  	if (ioctl (fd, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("StartStreaming:ioctl:VIDIOC_QBUF:\n");
			return -1;
		}
    	}
  	/* all done , get set go */
  	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  	if ( ioctl (fd, VIDIOC_STREAMON, &type) == -1)
    	{
      		printf ("StartStreaming:ioctl:VIDIOC_STREAMON:\n");
		return -1;
    	}
	CLEAR (buf1);
      	buf1.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      	buf1.memory = V4L2_MEMORY_MMAP;
      	if ( ioctl (fd, VIDIOC_DQBUF, &buf1) == -1)
	{
  		if (EAGAIN != errno)
    		{
			printf (" Exec : StartCameraCaputre:ioctl:VIDIOC_DQBUF\n");
			return -1;
		}
	}
	
	if ( ioctl (fd, VIDIOC_QBUF, &buf1) == -1)
	{
		printf ("EXEC : StartCameraCaputre:ioctl:VIDIOC_QBUF\n");
		return -1;
	}
	//a = 0;

	if ( ioctl(fd, VIDIOC_STREAMOFF, &type) == -1 )
	{
		printf("VIDIOC_STREAMOFF\n");
		for (i = 0; i < 3; i++)
		{
			munmap(cap_buffers[i].start, cap_buffers[i].length);
		}
		return -1;
	}

	return 0;
}	
int V4l2_cap_buf_neg(int fd, int val_ioctl, int neg_val)
{
	struct v4l2_requestbuffers req;
	struct v4l2_buffer buf, buf1;
	//printf("I am Here \n");
	if(val_ioctl == 0 && neg_val == 0)
	{
		req.count = 3;
  		req.type = 20; //V4L2_BUF_TYPE_VIDEO_CAPTURE;
  		req.memory = V4L2_MEMORY_MMAP;

  		if ( ioctl (fd, VIDIOC_REQBUFS, &req) == -1)
    		{
      			printf (" Init: CaptureBuffers:ioctl:VIDIOC_REQBUFS\n");
      			return 0;
    		}
	}
	else if(val_ioctl == 0 && neg_val == 1)
	{
		req.count = 3;
  		req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  		req.memory = 20;//V4L2_MEMORY_MMAP;

  		if ( ioctl (fd, VIDIOC_REQBUFS, &req) == -1)
    		{
      			printf (" Init: CaptureBuffers:ioctl:VIDIOC_REQBUFS\n");
      			return 0;
    		}
	}
	else if(val_ioctl == 1 && neg_val == 0)
	{
		memset (&buf, 0, sizeof (buf));
      		buf.type = 20; //V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = 0;

      		if ( ioctl (fd, VIDIOC_QUERYBUF, &buf) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_QUERYBUF:\n");
	  		return 0;
		}
	}
	else if(val_ioctl == 1 && neg_val == 1)
	{
		memset (&buf, 0, sizeof (buf));
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = 20; //V4L2_MEMORY_MMAP;
      		buf.index = 0;
		//printf("I am Here \n");
      		if ( ioctl (fd, VIDIOC_QUERYBUF, &buf) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_QUERYBUF:\n");
	  		return 0;
		}
	}
	else if(val_ioctl == 2 && neg_val == 0)
	{
		memset (&buf, 0, sizeof (buf));
      		buf.type = 20; //V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = 0;

      		if ( ioctl (fd, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_QBUF:\n");
	  		return 0;
		}
	}
	else if(val_ioctl == 2 && neg_val == 1)
	{
		memset (&buf, 0, sizeof (buf));
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = 20; //V4L2_MEMORY_MMAP;
      		buf.index = 0;
		//printf("I am Here \n");
      		if ( ioctl (fd, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_QBUF:\n");
	  		return 0;
		}
	}
	else if(val_ioctl == 3 && neg_val == 0)
	{
		memset (&buf, 0, sizeof (buf));
      		buf.type = 20; //V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = 0;

      		if ( ioctl (fd, VIDIOC_DQBUF, &buf) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_DQBUF:\n");
	  		return 0;
		}
	}
	else if(val_ioctl == 4 && neg_val == 0)
	{
		memset (&buf, 0, sizeof (buf));
      		buf.type = 20; //V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = 0;

      		if ( ioctl (fd, VIDIOC_STREAMON, &(buf.type)) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_DQBUF:\n");
	  		return 0;
		}
	}
	else if(val_ioctl == 5 && neg_val == 0)
	{
		memset (&buf, 0, sizeof (buf));
      		buf.type = 20; //V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = 0;

      		if ( ioctl (fd, VIDIOC_STREAMOFF, &(buf.type)) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_DQBUF:\n");
	  		return 0;
		}
	}

	



	return -1;
}
			

int Init_Cap_Buffer(int fd, int buf_count)
{
	struct v4l2_requestbuffers req;
	struct v4l2_buffer buf;
	int nIndex =0;

	CLEAR (req);
  	req.count = buf_count;
  	req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  	req.memory = V4L2_MEMORY_MMAP;

  	if ( ioctl (fd, VIDIOC_REQBUFS, &req) == -1)
    	{
      		printf (" Init: CaptureBuffers:ioctl:VIDIOC_REQBUFS\n");
      		return -1;
    	}
	
	if (req.count < 2)
    	{
      		printf ("Init: CaptureBuffers not sufficient buffers avilable \n");
      		return -1;
    	}
	
	cap_buffers = ( struct buffer *) malloc(sizeof( struct buffer ) * req.count);
  	if (!cap_buffers)
    	{
      		printf ("Init : cannot allocate CaptureBuffers\n");
      		return -1;
    	}

  	for (nIndex = 0; nIndex < req.count; ++nIndex)
    	{

      		//CLEAR (buf);
		memset (&buf, 0, sizeof (buf));
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = nIndex;

      		if ( ioctl (fd, VIDIOC_QUERYBUF, &buf) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_QUERYBUF:\n");
	  		return -1;
		}
      		cap_buffers[nIndex].length = buf.length;
      		cap_buffers[nIndex].start = mmap (NULL, buf.length, PROT_READ | PROT_WRITE, MAP_SHARED, fd,buf.m.offset);
		if (MAP_FAILED == cap_buffers[nIndex].start)
		{
	  		printf ("Init : cannot map CaptureBuffers\n");
	  		return -1;
		}
    	}

  	return 0;
}

int Start_Streaming(int fd, int buf_count)
{
	struct v4l2_buffer buf;
	int i = 0, type;

	for (i = 0; i < buf_count; i++)
    	{
      		CLEAR (buf);
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = i;
      	  	if (ioctl (fd, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("StartStreaming:ioctl:VIDIOC_QBUF:\n");
			return -1;
		}
    	}
  	/* all done , get set go */
  	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  	if ( ioctl (fd, VIDIOC_STREAMON, &type) == -1)
    	{
      		printf ("StartStreaming:ioctl:VIDIOC_STREAMON:\n");
		return -1;
    	}

  	return 0;
}

int Init_Camera_Cap(int fd, void * raw_params_void)
{
	/*struct ccdc_config_params_raw raw_params;
	raw_params = * (struct ccdc_config_params_raw *) raw_params_void;
	raw_params = (struct ccdc_config_params_raw) malloc(sizeof(struct ccdc_config_params_raw));
	raw_params.pix_fmt = CCDC_PIXFMT_RAW;
	raw_params.frm_fmt = CCDC_FRMFMT_PROGRESSIVE;
	raw_params.win = VPFE_WIN_VGA;
	raw_params.fid_pol = CCDC_PINPOL_POSITIVE;
	raw_params.vd_pol = CCDC_PINPOL_POSITIVE;
	raw_params.hd_pol = CCDC_PINPOL_POSITIVE;
	raw_params.image_invert_enable = 0;//FALSE;
	raw_params.data_sz = _12BITS;
	raw_params.med_filt_thres = 0;
	raw_params.mfilt1 = NO_MEDIAN_FILTER1;
	raw_params.mfilt2 =  NO_MEDIAN_FILTER2;
	raw_params.ccdc_offset = 0;
	raw_params.lpf_enable = 0;//FALSE;
	raw_params.datasft = 2;
	raw_params.alaw.b_alaw_enable = 1;//TRUE;
	raw_params.alaw.gama_wd = 0;
	raw_params.blk_clamp.b_clamp_enable = 1;//TRUE;
	raw_params.blk_clamp.sample_pixel = 1;
	raw_params.blk_clamp.start_pixel = 0;
	raw_params.blk_clamp.dc_sub = 0;
	raw_params.blk_comp.b_comp = 0;
	raw_params.blk_comp.gb_comp = 0;
	raw_params.blk_comp.gr_comp = 0;
	raw_params.blk_comp.r_comp = 0;
        raw_params.vertical_dft.ver_dft_en = 0;//FALSE;
	raw_params.lens_sh_corr.lsc_enable = 0;//FALSE;
 	raw_params.data_formatter_r.fmt_enable = 0;//FALSE;
	raw_params.color_space_con.csc_enable = 0;//FALSE;


	if (ioctl(fd, VPFE_CMD_CONFIG_CCDC_RAW, &raw_params) == -1)
	{
		printf("InitDevice:ioctl:VPFE_CMD_CONFIG_CCDC_RAW:");
		return -1;
	}*/
	return 0;
}


	



		




 
