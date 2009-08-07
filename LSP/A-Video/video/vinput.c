// An Attempt to write a main file 06/19/2008
#include"vloop_inc.h"
#include <linux/videodev.h>
#include <media/davinci/davinci_vpfe.h>
#include <media/davinci/ccdc_dm355.h>
#include <media/davinci/tvp5146.h>
#include <media/davinci/mt9t001.h>
//#include "vpfe_dm355_interface.h"
//#include "vpbe_dm355_interface.h"
//#include "ipipe_dm355_interface.h"

int main()
{
	
	int fd;
	struct buffer *cap_buffers, *disp_buffers, *out_prev_buf;
	//void * user_prev_config;
	//struct prev_channel_config * user_prev_chan_config;
	//char * in_buffer, out_buffer;
	struct timeval tv;
	struct v4l2_buffer buf;
	//struct imp_buffer *in_buff, *out_buff;
	int out_buf_idx =0;
	int vid_type = 0, r;
	int cap_width = 720, cap_height = 480;
	struct v4l2_capability cap;
	struct v4l2_input input_fmt;
	v4l2_std_id cap_std;
	fd_set fds;
	


	
	//Open all devices
	//fd_cap = Vpfe_Open(VID_IN0, O_RDWR);
	//fd_disp = V4l2_Vpbe_Open(VID_OUT0, O_RDWR);
	
	fd = open("/dev/video0",O_RDWR);
		if(fd <= 0)
		{
			printf("Error in opening the VPFE Device \n");
			return -1;
		}

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

	while(1)	
	{
		if ( ioctl (fd, VIDIOC_ENUMINPUT, &input_fmt) == -1)
		{
			printf (" Init : VIDIOC_ENUMINPUT \n");
			return -1;
  		}
		if(strcmp(input_fmt.name,"COMPOSITE") == 0)
		{
			printf("Set to COMPOSITE \n");
			vid_type = input_fmt.index;
			printf(" The index is : %d \n", input_fmt.index);
			break;
		}
		else
		{
			input_fmt.index = (input_fmt.index) + 1;
		}
	}

  	if ( ioctl (fd, VIDIOC_S_INPUT, &vid_type) == -1)
	{
		printf (" Init : VIDIOC_S_INPUT \n");
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


	
	//printf("hi you are here \n");

	/*
	if(Init_Capture( fd_cap ) == -1)
	{
		close( fd_cap );
		return-1;
	}	
	cap_std = VPFE_STD_AUTO;
	//printf("before format cap \n");
	if(Init_Fmt_Cap(fd_cap, cap_std , cap_width, cap_height, YUV_CAP) == -1)
	{
		close ( fd_disp );
		return -1;
	}
	
	if(Init_Cap_Buffer(fd_cap, 3, cap_buffers) == -1)
	{
		close (fd_cap);
		close (fd_disp);
		return -1;
	}

	if(Start_Streaming(fd_cap, 3) == -1)
	{
		close (fd_cap);
		close (fd_disp);
		return -1;
	}*/

	/*if(Prev_Init(fd_prev,IMP_MODE_SINGLE_SHOT, user_prev_config, 720, 480, 0) == -1)
	{
		close (fd_cap);
		close (fd_prev);
		return -1;
	}
	
	if(Set_Prev_Config(fd_prev, user_prev_chan_config) == -1)
	{
		close (fd_cap);
		close (fd_prev);
		return -1;
	}

	if(Init_Prev_Param(fd_prev) == -1)
	{
		close (fd_prev);
		return -1;
	}*/

	/*if(Init_Prev_Buffer(fd_prev, IMP_BUF_IN, &in_buffer, 720, 480) == -1)
	{
		close (fd_prev);
		return -1;
	}*/

	/*if(Init_Prev_Buffer(fd_prev, IMP_BUF_OUT1, out_prev_buf, 720, 480) == -1)
	{
		close (fd_prev);
		return -1;
	}*/
	
	/*
	if(V4l2_Vpbe_init(fd_disp, &vid_op_type, STD_NTSC) == -1)
	{
		close (fd_disp);
		return -1;
	}
	
	if(Init_Vpbe_Fmt(fd_disp, 720, 480) == -1)
	{
		close (fd_disp);
		return -1;
	}

	if(Init_Vpbe_Buffer(fd_disp, 3, disp_buffers) == -1)
	{
		close (fd_disp);
		return -1;
	}

	if(Start_Disp_Streaming(fd_disp, 3) == -1)
	{
		close (fd_cap);
		close (fd_disp);
		return -1;
	}

	while(1)
	{
		FD_ZERO (&fds);
      		FD_SET (fd_cap, &fds);
		

		r = select (fd_cap + 1, &fds, NULL, NULL, &tv);

      		if ( r == -1 )
		{
	  		if (EINTR == errno)
	    		continue;

	  		printf ("EXEC : StartCameraCaputre:select\n");
	  		return -1;
		}

		CLEAR (buf);
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      
		if ( ioctl (fd_cap, VIDIOC_DQBUF, &buf) == -1)
		{
	  		if (EAGAIN == errno)
	    		continue;
	  		printf (" Exec : StartCameraCaputre:ioctl:VIDIOC_DQBUF\n");
	  		return -1;
		}*/
	
		/*in_buff->index = -1;
		in_buff->offset = buf.m.offset;
		in_buff->size = buf.length;
		out_buff->index = out_buf_idx;
		
		if( Set_Prev_Buf(fd_prev, &in_buff, &out_buff) == -1)
		{
			printf("Error in setting the preview mode \n");
			return -1;
		}*/
		

		
		 
/*
		if( DisplayFrame (fd_disp, cap_buffers[buf.index].start, disp_buffers, 720, 480 ) == -1)
		{
			printf ( "EXEC : Error in displaying the freames \n");
			return -1;
		}

		if ( ioctl (fd_cap, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("EXEC : StartCameraCaputre:ioctl:VIDIOC_QBUF\n");
			return -1;
		}
	}
	return 0;*/
}

			
		

	 

	

	

	
	
	
