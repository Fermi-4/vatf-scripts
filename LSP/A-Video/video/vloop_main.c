// An Attempt to write a main file 06/19/2008
#include"vloop_inc.h"
#include "vpfe_dm355_interface.h"
#include "vpbe_dm355_interface.h"
//#include "ipipe_dm355_interface.h"

int main(int argc, char *argv[])
{
	
	char shortoptions[] = "c:n:i:o:w:h:";
	int fd_cap, fd_prev, fd_disp;
	//struct buffer *cap_buffers, *disp_buffers, *out_prev_buf;
	//void * user_prev_config;
	//struct prev_channel_config * user_prev_chan_config;
	//char * in_buffer, out_buffer;
	struct timeval tv;
	struct v4l2_buffer buf;
	//struct imp_buffer *in_buff, *out_buff;
	int out_buf_idx =0;
	int vid_op_type = 0, r;
	int cap_width = 720, cap_height = 480, d, buf_count, ch_no, ip_type;
	//int op_type;
	v4l2_std_id cap_std;
	fd_set fds;
	
	

	for (;;) 
	{
		d = getopt_long(argc, argv, shortoptions, (void *) NULL,
				&index);
		if (-1 == d)
			break;
		switch (d) {
			case 0:
				break;
			case 'c':
			case 'C':
				ch_no = atoi(optarg);
				break;
			case 'N':
			case 'n':
				buf_count = atoi(optarg);
				break;
		        case 'I':
			case 'i':
				ip_type = atoi(optarg);
				break;
			case 'O':
			case 'o':
				vid_op_type = atoi(optarg);
				break;
			case 'W':
			case 'w':
				cap_width = atoi(optarg);
				break;
			case 'H':
			case 'h':
				cap_height = atoi(optarg);
				break;
			default:
				exit(1);
		}
	}

	
	//Open all devices
	fd_cap = Vpfe_Open(VID_IN0, O_RDWR);
	if(ch_no == 0)
	{
		fd_disp = V4l2_Vpbe_Open(VID_OUT0, O_RDWR);
	}
	else
	{	
		fd_disp = V4l2_Vpbe_Open(VID_OUT0, O_RDWR);
	}
		
	
	//printf("hi you are here \n");


	if(Init_Capture( fd_cap, ip_type ) == -1)
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
	
	if(Init_Cap_Buffer(fd_cap, buf_count) == -1)
	{
		close (fd_cap);
		close (fd_disp);
		return -1;
	}

	if(Start_Streaming(fd_cap, buf_count) == -1)
	{
		close (fd_cap);
		close (fd_disp);
		return -1;
	}

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
	
	if(V4l2_Vpbe_init(fd_disp, vid_op_type, STD_NTSC) == -1)
	{
		close (fd_disp);
		return -1;
	}
	if(Init_Vpbe_Fmt(fd_disp, cap_width, cap_height) == -1)
	{
		close (fd_disp);
		return -1;
	}

	if(Init_Vpbe_Buffer(fd_disp, buf_count) == -1)
	{
		close (fd_disp);
		return -1;
	}
	
	if(Start_Disp_Streaming(fd_disp, buf_count) == -1)
	{
		close (fd_cap);
		close (fd_disp);
		return -1;
	}
	//printf(" I am here 3 \n");
	while(1)
	{
		FD_ZERO (&fds);
      		FD_SET (fd_cap, &fds);
		
		//printf("the fd_cap is %d \n", fd_cap);
		r = select (fd_cap + 1, &fds, NULL, NULL, &tv);

      		if ( r == -1 )
		{
	  		if (EINTR == errno)
	    		continue;

	  		printf ("EXEC : StartCameraCaputre:select\n");
	  		return -1;
		}
		
		if (r == 0)
		{
			continue;
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
		//printf("DQBUF success \n");
	
		/*in_buff->index = -1;
		in_buff->offset = buf.m.offset;
		in_buff->size = buf.length;
		out_buff->index = out_buf_idx;
		
		if( Set_Prev_Buf(fd_prev, &in_buff, &out_buff) == -1)
		{
			printf("Error in setting the preview mode \n");
			return -1;
		}*/
		

		
		 

		if( DisplayFrame (fd_disp, cap_buffers[buf.index].start, 720, 480 ) == -1)
		{
			printf ( "EXEC : Error in displaying the frames \n");
			return -1;
		}
		
		if ( ioctl (fd_cap, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("EXEC : StartCameraCaputre:ioctl:VIDIOC_QBUF\n");
			return -1;
		}
		//printf("The QBUF is success \n");
	}
	return 0;
}

			
		

	 

	

	

	
	
	
