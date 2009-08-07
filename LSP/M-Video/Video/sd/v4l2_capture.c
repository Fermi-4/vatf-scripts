#include "v4l2_capture.h"
#include "v4l2_generic.h"

int nBuffers = 0;
int Init_capture( int fd)
{
  	struct v4l2_capability cap;
  	//struct v4l2_crop crop;
	struct v4l2_cropcap cropcap;
	struct v4l2_input input_fmt;
  	int vid_type;

	/*if ( vid_input == 0)
	{
		vid_type = 0;
	}
	else
	{
		vid_type = 1;
	}*/	

	/* Check the capture capabilities */
	if (ioctl (fd, VIDIOC_QUERYCAP, &cap) == -1)
    	{
      		printf ("Init:ioctl:VIDIOC_QUERYCAP:\n");
      		goto errorexit;
    	}

	if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE))
    	{
      		printf ("Init: capture is not supported on:%s\n", CAPTURE_DEVICE);
      		goto errorexit;
    	}

	
	/* Check the MMAP capability of the capture device */
	if (!(cap.capabilities & V4L2_CAP_STREAMING))
    	{
      		printf ("Init:IO method MMAP is not supported on:%s\n",CAPTURE_DEVICE);
      		goto errorexit;
    	}

	/*select cropping as deault rectangle */
  	cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

  	if (ioctl (fd, VIDIOC_CROPCAP, &cropcap) == -1)
    	{
      		printf ("InitDevice:ioctl:VIDIOC_CROPCAP\n");
      		/*ignore error */
    	}

	memset (&input_fmt, 0, sizeof (input_fmt));
	/*input_fmt.type = V4L2_INPUT_TYPE_CAMERA;
	input_fmt.index = 0;*/
	input_fmt.type = V4L2_INPUT_TYPE_CAMERA;
	input_fmt.index = 0;
  	while (-EINVAL != ioctl(fd,VIDIOC_ENUMINPUT, &input_fmt)) { 
		printf("input.name = %s\n", input_fmt.name);
		printf("Input.index = %d \n", input_fmt.index);
		if(vid_input == 0)
		{
		if (!strcmp(input_fmt.name, "COMPOSITE"))
			break;
		}
		else if(vid_input == 1)
		{
		if (!strcmp(input_fmt.name, "SVIDEO"))
			break;
		}
		input_fmt.index++;
  	}

  	if ( ioctl (fd, VIDIOC_S_INPUT, &input_fmt.index) == -1)
	{
		printf (" Init : VIDIOC_S_INPUT \n");
		goto errorexit;
  	}	
  	
	if ( ioctl (fd, VIDIOC_G_INPUT, &vid_type) == -1)
	{
		printf (" Init : VIDIOC_G_INPUT \n");
		goto errorexit;
  	}
  	input_fmt.index = vid_type;

  
  	if ( ioctl (fd, VIDIOC_ENUMINPUT, &input_fmt) == -1)
	{
		printf (" Init : VIDIOC_ENUMINPUT \n");
		goto errorexit;
  	}
  	printf ("Current input: %s\n", input_fmt.name);



	return 0;

	errorexit:
	return -1;

}

int Init_Format_capture ( int fd )
{
	v4l2_std_id  cur_std;
	struct v4l2_format fmt;
	//struct v4l2_crop crop;
	int min;

	cur_std = VPFE_STD_AUTO;

	if ( ioctl (fd, VIDIOC_S_STD, &cur_std) == -1)
    	{
      		printf ("Init : unable to set capture standard automatically\n");
		goto errorexit;
    	}
  	sleep (1);
	//printf(" the cur_std = %x \n", cur_std);
	if ( ioctl (fd, VIDIOC_QUERYSTD, &cur_std) == -1)
    	{
      		printf ("Init Capture_VIDIOC_QUERYSTD:\n");
		goto errorexit;
    	}
//printf(" the cur_std = %x \n", cur_std);
//cur_std = V4L2_STD_NTSC;


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
//printf(" the NTSC_std = %x \n", cur_std);

	CLEAR(fmt);

	fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	fmt.fmt.pix.width = IN_WIDTH;	
  	fmt.fmt.pix.height = IN_HEIGHT;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
	fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;


	/*crop.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	
	if ((((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 0)))
	{
		crop.c.width= IN_WIDTH;
		crop.c.height= IN_HEIGHT;
		crop.c.top  = 0;
		crop.c.left = 0;
	}
	else if ((((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 1)))
	{
		//crop.c.width= 352;
		//crop.c.height= IN_HEIGHT/2;
		//crop.c.top  = (IN_WIDTH/2) - (IN_WIDTH/4);
		//crop.c.left = (IN_HEIGHT/2) - (IN_HEIGHT/4);
		crop.c.width= IN_WIDTH;
		crop.c.height= IN_HEIGHT;
		crop.c.top  = 0;
		crop.c.left = 0;

	}
	else 
	{
		crop.c.width= IN_WIDTH;
		crop.c.height= IN_HEIGHT;
		crop.c.top  = 0;
		crop.c.left = 0;
	}

	if ( ioctl(fd, VIDIOC_S_CROP, &crop) == -1 )
	{
		printf (" INIT : VIDIOC_S_CROP\n");
		goto errorexit;
	}*/

	if ( ioctl (fd, VIDIOC_S_FMT, &fmt) == -1)
    	{
      		printf ("SetDataFormat:ioctl:VIDIOC_S_FMT\n");
		goto errorexit;
    	}


	min = fmt.fmt.pix.width * 2;
  	if (fmt.fmt.pix.bytesperline < min)
    	{
      		printf ("Init : capture driver reports bytes_per_line:%d(bug)\n",fmt.fmt.pix.bytesperline);
      		fmt.fmt.pix.bytesperline = min;
    	}
	min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
  	if (fmt.fmt.pix.sizeimage < min)
    	{
      		printf ("Init : Capture driver reports size:%d(bug)\n",fmt.fmt.pix.sizeimage);
		fmt.fmt.pix.sizeimage = min;
    	}

	
	return 0;

	errorexit:

	return -1;

}

int Init_Buffer_capture ( int fd )
{
	struct v4l2_requestbuffers req;
  	int nIndex = 0;

  	CLEAR (req);
  	req.count = 2;
  	req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  	req.memory = V4L2_MEMORY_MMAP;

  	if ( ioctl (fd, VIDIOC_REQBUFS, &req) == -1)
    	{
      		printf (" Init: CaptureBuffers:ioctl:VIDIOC_REQBUFS\n");
      		goto errorexit;
    	}

  	if (req.count < 2)
    	{
      		printf ("Init: CaptureBuffers not sufficient buffers avilable \n");
      		goto errorexit;
    	}

  	nBuffers = req.count;
  	cap_buffers = ( struct buffer *) calloc (req.count, sizeof ( struct buffer));
  	if (!cap_buffers)
    	{
      		printf ("Init : cannot allocate CaptureBuffers\n");
      		goto errorexit;
    	}

  	for (nIndex = 0; nIndex < req.count; ++nIndex)
    	{

      		struct v4l2_buffer buf;
      		CLEAR (buf);
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = nIndex;

      		if ( ioctl (fd, VIDIOC_QUERYBUF, &buf) == -1)
		{
	  		printf ("Init : CaptureBuffers:ioctl:VIDIOC_QUERYBUF:\n");
	  		goto errorexit;
		}
      		cap_buffers[nIndex].length = buf.length;
      		cap_buffers[nIndex].start = mmap (NULL, buf.length, PROT_READ | PROT_WRITE, MAP_SHARED, fd,buf.m.offset);
		if (MAP_FAILED == cap_buffers[nIndex].start)
		{
	  		printf ("Init : cannot map CaptureBuffers\n");
	  		goto errorexit;
		}
    	}

  	return 0;

	errorexit:

	return -1;
}

int start_stream ( int fd )
{
	int i = 0;
  	enum v4l2_buf_type type;

  	for (i = 0; i < nBuffers; i++)
    	{
      		struct v4l2_buffer buf;
      		CLEAR (buf);
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = i;
      	  	if (ioctl (fd, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("StartStreaming:ioctl:VIDIOC_QBUF:\n");
			goto errorexit;
		}
    	}
  	/* all done , get set go */
  	type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  	if ( ioctl (fd, VIDIOC_STREAMON, &type) == -1)
    	{
      		printf ("StartStreaming:ioctl:VIDIOC_STREAMON:\n");
		goto errorexit;
    	}

  	return 0;

	errorexit:
	
	return -1;	
}

	
 

	
	




