// An Attempt to write a main file 06/19/2008
#include"vloop_inc.h"
#include "vpfe_dm355_interface.h"
#include "vpbe_dm355_interface.h"
#include "ipipe_dm355_interface.h"

int main()
{
	
	int fd_cap, fd_prev, fd_disp;
	struct buffer *cap_buffers, *disp_buffers, *out_prev_buf;
	void * user_prev_config;
	struct prev_channel_config * user_prev_chan_config;
	//char * in_buffer, out_buffer;
	struct timeval tv;
	struct v4l2_buffer buf;
	struct imp_buffer *in_buff, *out_buff;
	int out_buf_idx =0;
	int vid_op_type = 0, r;
	int cap_width = 720, cap_height = 480, cap_std;
	fd_set fds;
	


	
	//Open all devices
	fd_cap = Vpfe_Open(VID_IN0, O_RDWR);
	fd_disp = V4l2_Vpbe_Open(VID_OUT0, O_RDWR);
	fd_prev = Imp_Open(DEV_PREV, O_RDWR);

	if(Init_Capture( fd_cap ) == -1)
	{
		close( fd_cap );
		return-1;
	}
	cap_std = VPFE_STD_AUTO;
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
	}

	if(Prev_Init(fd_prev,IMP_MODE_SINGLE_SHOT, user_prev_config, 720, 480, 0) == -1)
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
	}

	/*if(Init_Prev_Buffer(fd_prev, IMP_BUF_IN, &in_buffer, 720, 480) == -1)
	{
		close (fd_prev);
		return -1;
	}*/

	if(Init_Prev_Buffer(fd_prev, IMP_BUF_OUT1, out_prev_buf, 720, 480) == -1)
	{
		close (fd_prev);
		return -1;
	}
	
	
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
		}
	
		in_buff->index = -1;
		in_buff->offset = buf.m.offset;
		in_buff->size = buf.length;
		out_buff->index = out_buf_idx;
		
		if( Set_Prev_Buf(fd_prev, &in_buff, &out_buff) == -1)
		{
			printf("Error in setting the preview mode \n");
			return -1;
		}
		
		 

		if( DisplayFrame (fd_disp, out_prev_buf->start, disp_buffers, 720, 480 ) == -1)
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
	return 0;
}

			
		

	 

	

	

	
	
	
