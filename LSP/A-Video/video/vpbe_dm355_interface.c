/* This file contains the DM355 Specific APIs,Constants and Global Variables definitions used for the initialization, Configuration and usage of VPFE modules provided in the Linux Support package version 2.10

			Author	: 	Arun Vijay Mani
			Date	:	06/18/2008
			Version	:	0.1
***************************************************************************************************************************/
//Including the files
#include "vpbe_interface.h"
#include "vpbe_dm355_interface.h"

int V4l2_Vpbe_Open(int device_id, int mode)
{
	int fd_disp;
	if(device_id == VID_OUT0)
	{
		fd_disp = open(VID_OUT0_DEV,mode);
		if(fd_disp <= 0)
		{
			printf("Error in opening the Video0 Device \n");
			return -1;
		}
	}
	else if(device_id == VID_OUT1)
	{
		fd_disp = open(VID_OUT1_DEV,mode);
		if(fd_disp <= 0)
		{
			printf("Error in opening the Video1 Device \n");
			return -1;
		}
	}
 
	return fd_disp;
}

int V4l2_Vpbe_init(int fd, int vid_output, int vid_fmt)
{
	struct v4l2_requestbuffers req;
	struct v4l2_buffer buf;
	struct v4l2_standard standard;
	int std_id = 0;
	int fd_mode, fd_output;
	char output_str[10], mode_str[10];
	

	fd_output = open("/sys/class/davinci_display/ch0/output", O_RDWR);
	if ( fd_output == -1 )
	{
		printf(" Error in opening the sysfs for mode \n");
		return -1;
	}

	fd_mode = open("/sys/class/davinci_display/ch0/mode", O_RDWR);
	if ( fd_mode == -1 )
	{
		printf(" Error in opening the sysfs for mode \n");
		return -1;
	}
	printf("vid_output is %d \n", vid_output);
	if (vid_output == 0)
	{
		if ( (write(fd_output, "COMPOSITE" , 10) == -1 ) )
		{
			printf( " Error in writing the output \n " );
			return -1;
		}
		lseek(fd_output,0,SEEK_SET);
		bzero(output_str,10);
  		if (read(fd_output,output_str,10) < 0 ) 
		{
			perror("Error reading output\n");
			return -1;
  		}

  		printf("output changed to %s\n",output_str);

		//printf(" successfully configured COMPOSITE \n" );
	}
	else if (vid_output == 1)
	{
		if ( (write(fd_output, "LCD" , 4) == -1 ) )
		{
			printf( " Error in writing the output \n " );
			return -1;
		}
		lseek(fd_output,0,SEEK_SET);
		bzero(output_str,10);
  		if (read(fd_output,output_str,4) < 0 ) 
		{
			perror("Error reading output\n");
			return -1;
  		}

  		printf("output changed to %s\n",output_str);

	//	printf(" successfully configured LCD \n" );
	}
	else if (vid_output == 2)
	{
		if ( (write(fd_output, "SVIDEO" , 7) == -1 ) )
		{
			printf( " Error in writing the output \n " );
			return -1;
		}
		lseek(fd_output,0,SEEK_SET);
		bzero(output_str,10);
  		if (read(fd_output,output_str,7) < 0 ) 
		{
			perror("Error reading output\n");
			return -1;
  		}

  		printf("output changed to %s\n",output_str);

		//printf(" successfully configured SVIDEO \n" );
	}
	else if (vid_output == 3)
	{
		if ( (write(fd_output, "COMPONENT" , 10) == -1 ) )
		{
			printf( " Error in writing the output \n " );
			return -1;
		}
		lseek(fd_output,0,SEEK_SET);
		bzero(output_str,10);
  		if (read(fd_output,output_str,9) < 0 ) 
		{
			perror("Error reading output\n");
			return -1;
  		}

  		printf("output changed to %s\n",output_str);

		//printf(" successfully configured COMPONENT \n" );
	}
	if (close(fd_output) <0)
  	{
     		perror("error closing \n");
     		return -1;
  	}


	if ( vid_fmt == 0)
	{
		//printf(" successfully configuring NTSC \n" );
		if ( (write(fd_mode, "NTSC" , 5) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			return -1;
		}
		lseek(fd_mode,0,SEEK_SET);
		bzero(mode_str,10);
  		if (read(fd_mode,mode_str,5) < 0 ) 
		{
			perror("Error reading mode\n");
			return -1;
  		}

  		printf("mode changed to %s\n",mode_str);

		//printf(" successfully configured NTSC \n" ); 
	}
	else if (vid_fmt == 1)
	{
		if ( (write(fd_mode, "PAL" , 4) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			return -1;
		}
		lseek(fd_mode,0,SEEK_SET);
		bzero(mode_str,10);
  		if (read(fd_mode,mode_str,4) < 0 ) 
		{
			perror("Error reading mode\n");
			return -1;
  		}

  		printf("mode changed to %s\n",mode_str);
		//printf(" successfully configured PAL \n" ); 
	}
	else if (vid_fmt == 2)
	{
		if ( (write(fd_mode, "640x480" , 8) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			return -1;
		}
		lseek(fd_mode,0,SEEK_SET);
		bzero(mode_str,10);
  		if (read(fd_mode,mode_str,8) < 0 ) 
		{
			perror("Error reading mode\n");
			return -1;
  		}

  		printf("mode changed to %s\n",mode_str);
		//printf(" successfully configured 640x480 \n" ); 
	}
	else if (vid_fmt == 3)
	{
		if ( (write(fd_mode, "640x400" , 8) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			return -1;
		}
		lseek(fd_mode,0,SEEK_SET);
		bzero(mode_str,10);
  		if (read(fd_mode,mode_str,8) < 0 ) 
		{
			perror("Error reading mode\n");
			return -1;
  		}

  		printf("mode changed to %s\n",mode_str);
		//printf(" successfully configured 640x400 \n" ); 
	}
	else if (vid_fmt == 4)
	{
		if ( (write(fd_mode, "640x350" , 8) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			return -1;
		}
		lseek(fd_mode,0,SEEK_SET);
		bzero(mode_str,10);
  		if (read(fd_mode,mode_str,5) < 0 ) 
		{
			perror("Error reading mode\n");
			return -1;
  		}

  		printf("mode changed to %s\n",mode_str);
		//printf(" successfully configured 640x350 \n" ); 
	}
	if (close(fd_mode) <0)
  	{
     		perror("error closing \n");
     		return -1;
  	}

/*	if(vid_std == STD_NTSC)
	{
		std_id = V4L2_STD_525_60;
	}
	else if(vid_std == STD_PAL)
	{
		std_id = V4L2_STD_625_50;
	}

	if ( ioctl(fd, VIDIOC_S_STD, &std_id) == -1 )
	{
		printf(" Init : VIDIOC_S_STD\n");
		return -1;
	}


	if ( ioctl (fd, VIDIOC_G_STD, &std_id) == -1)
	{
		printf(" Init : VIDIOC_G_STD \n");
		return -1;
	}
	memset (&standard, 0, sizeof (standard));
	standard.index = 0;

	while ( ioctl (fd, VIDIOC_ENUMSTD, &standard) == 0)
	{
		if (standard.id & std_id) 
		{
			printf ("Current video standard: %s\n", standard.name);
		}
		standard.index++;
	}*/
	return 0;

}

int Init_Vpbe_Fmt(int fd, int width, int height)
{
	struct v4l2_format fmt;

	memset (&fmt, 0, sizeof (fmt));

	fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;	
	fmt.fmt.pix.width = width;
	fmt.fmt.pix.height = height;
	fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;

	if ( ioctl(fd, VIDIOC_S_FMT, &fmt) )
	{
		printf (" Init: Display_VIDIOC_S_FMT \n");
		return -1;
	}

	return 0;
}

int Init_Vpbe_Crop(int fd, int width, int height, int top, int left)
{
	struct v4l2_crop crop;

	crop.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	crop.c.top  = top;
	crop.c.left = left;
	crop.c.height = height;
	crop.c.width = width;

	if ( ioctl(fd, VIDIOC_S_CROP, &crop) == -1)
	{
		printf (" INIT : VIDIOC_S_CROP\n");
		return -1;
	}

	return 0;
}

int Init_Vpbe_Buffer(int fd, int buf_count)
{
	struct v4l2_requestbuffers req;
	struct v4l2_buffer buf;
	int nIndex =0;

	CLEAR (req);
  	req.count = buf_count;
  	req.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
  	req.memory = V4L2_MEMORY_MMAP;
	printf(" the buffer count is %d \n ", req.count);

  	if ( ioctl (fd, VIDIOC_REQBUFS, &req) == -1)
    	{
      		printf (" Init: DisplayBuffers:ioctl:VIDIOC_REQBUFS\n");
      		return -1;
    	}
	
	if (req.count < 2)
    	{
      		printf ("Init: DisplayBuffers not sufficient buffers avilable \n");
      		return -1;
    	}
	
	disp_buffers = ( struct buffer *) malloc(sizeof( struct buffer ) * req.count);
  	if (!disp_buffers)
    	{
      		printf ("Init : cannot allocate DisplayBuffers\n");
      		return -1;
    	}
	for (nIndex = 0; nIndex < req.count; ++nIndex)
    	{

      		memset (&buf, 0, sizeof (buf));
      		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = nIndex;

      		if ( ioctl (fd, VIDIOC_QUERYBUF, &buf) == -1)
		{
	  		printf ("Init : DisplayBuffers:ioctl:VIDIOC_QUERYBUF:\n");
	  		return -1;
		}
      		disp_buffers[nIndex].length = buf.length;
      		disp_buffers[nIndex].start = mmap (NULL, buf.length, PROT_READ | PROT_WRITE, MAP_SHARED, fd,buf.m.offset);
		disp_buffers[nIndex].index = buf.index;
		if (MAP_FAILED == disp_buffers[nIndex].start)
		{
	  		printf ("Init : cannot map DisplayBuffers\n");
	  		return -1;
		}
    	}
	
	return 0;
}

int Start_Disp_Streaming(int fd, int buf_count)
{
	struct v4l2_buffer buf;
	int i = 0, type;

	for (i = 0; i < buf_count; i++)
    	{
      		memset (&buf, 0, sizeof (buf));
      		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
      		buf.memory = V4L2_MEMORY_MMAP;
      		buf.index = i;
      	  	if (ioctl (fd, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("StartStreaming:ioctl:VIDIOC_QBUF:\n");
			return -1;
		}
    	}
  	/* all done , get set go */
  	type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
  	if ( ioctl (fd, VIDIOC_STREAMON, &type) == -1)
    	{
      		printf ("StartStreaming:ioctl:VIDIOC_STREAMON:\n");
		return -1;
    	}
	printf("Stream ON \n");
  	return 0;
}

int putDisplayBuffer ( int fd , void *addr )
{
	struct v4l2_buffer buf;
	int i, index = 0;

	if (addr == NULL)
		return -1;
	memset(&buf, 0, sizeof(buf));
	//printf(" the addr is %x \n", addr);
	//printf("the index is %d \n",buf.index);
	for (i = 0; i < 3; i++) 
	{
		//printf(" the disp_addr is %x \n",disp_buffers[i].start );
		if (addr == disp_buffers[i].start)
		 {
			index = disp_buffers[i].index;
			//printf(" the i = , index = %d %d \n", i, index);
			break;
		}
	}

	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	buf.memory = V4L2_MEMORY_MMAP;
	buf.index = index;
	

	if ( ioctl(fd, VIDIOC_QBUF, &buf) == -1)
	{
		printf(" EXEC : error in queuing the buffer \n");
		printf(" The erron no is %d \n ", errno);
		return -1;
	}
	
	
	return 0;
} 

void *getDisplayBuffer ( int fd )
{
	int ret, i;
	struct v4l2_buffer buf;

	memset(&buf, 0, sizeof(buf));
	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	if ( ioctl(fd, VIDIOC_DQBUF, &buf) == -1)
	{
		printf (" EXEC : VIDIOC_DQBUF\n");
		for (i = 0; i < 3; i++)
			munmap(disp_buffers[i].start,disp_buffers[i].length);
		return NULL;
	}
	
	return disp_buffers[buf.index].start;
}


int DisplayFrame ( int fd, void *ptrBuffer, int width, int height )
{
	int y,i;
  	int xres, yres;
  	void *buf_new;
  	unsigned int line_length = width*2;
	char *src, *dest;
	
	//printf(" good so far \n");

  	buf_new = getDisplayBuffer(fd);

  	if (buf_new == NULL)
  	{
		printf(" Display : Error in getting display buffer\n");
		return -1;
  	}

	src = ptrBuffer;
  	dest = buf_new;
	for (i=0; i < height; i++)
	{
	  	memcpy (dest,src,(width*2));
		dest += line_length;
		src += line_length;
      	}

	 

  	if (putDisplayBuffer(fd,buf_new) < 0)
  	{
		printf(" Display : Error in put display buffer\n");
		return -1;
  	}

  	return 0;
}




	
	



	



