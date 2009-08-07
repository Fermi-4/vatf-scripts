#include "v4l2_display.h"
#include "v4l2_generic.h"
//#include "Image_640x480_YCC_vidwin1_idata.h"
#include "osd16.h"

int stress = 0;
int startLoopCnt = 5000;
int line_length;
struct fb_var_screeninfo prev_osd0_var;
struct fb_fix_screeninfo osd_fixInfo;
char *osd0_display[2] = { NULL, NULL };

int Init_display( int fd)
{

	struct v4l2_requestbuffers req;
	struct v4l2_buffer buf;
	struct v4l2_format fmt;
	//struct v4l2_standard standard;
	int i,j, a = 0;
	struct v4l2_crop crop;
	//v4l2_std_id std_id;
	int fd_mode, fd_output;


	fd_output = open("/sys/class/davinci_display/ch0/output", O_RDWR);
	if ( fd_output == -1 )
	{
		printf(" Error in opening the sysfs for mode \n");
		goto errorexit;
	}

	fd_mode = open("/sys/class/davinci_display/ch0/mode", O_RDWR);
	if ( fd_mode == -1 )
	{
		printf(" Error in opening the sysfs for mode \n");
		goto errorexit;
	}
	if (vid_output == 0)
	{
		if ( (write(fd_output, "COMPOSITE" , 10) == -1 ) )
		{
			printf( " Error in writing the output \n " );
			goto errorexit;
		}
		printf(" successfully configured COMPOSITE \n" );
	}
	else if (vid_output == 1)
	{
		if ( (write(fd_output, "LCD" , 4) == -1 ) )
		{
			printf( " Error in writing the output \n " );
			goto errorexit;
		}
		printf(" successfully configured LCD \n" );
	}
	else if (vid_output == 2)
	{
		if ( (write(fd_output, "COMPONENT" , 10) == -1 ) )
		{
			printf( " Error in writing the output \n " );
			goto errorexit;
		}
		printf(" successfully configured HD \n" );
	}
	
	if ( vid_fmt == 0)
	{
		//printf(" successfully configuring NTSC \n" );
		if ( (write(fd_mode, "NTSC" , 5) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			goto errorexit;
		}
		printf(" successfully configured NTSC \n" ); 
	}
	else if (vid_fmt == 1)
	{
		if ( (write(fd_mode, "PAL" , 4) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			goto errorexit;
		}
		printf(" successfully configured PAL \n" ); 
	}
	else if (vid_fmt == 2)
	{
		if ( (write(fd_mode, "640x480" , 8) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			goto errorexit;
		}
		printf(" successfully configured 640x480 \n" ); 
	}
	else if (vid_fmt == 3)
	{
		if ( (write(fd_mode, "640x400" , 8) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			goto errorexit;
		}
		printf(" successfully configured 640x400 \n" ); 
	}
	else if (vid_fmt == 4)
	{
		if ( (write(fd_mode, "640x350" , 8) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			goto errorexit;
		}
		printf(" successfully configured 640x350 \n" ); 
	}
	else if (vid_fmt == 5)
	{
		if ( (write(fd_mode, "720P-60" , 8) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			goto errorexit;
		}
		printf(" successfully configured 720P \n" ); 
	}
	else if (vid_fmt == 6)
	{
		if ( (write(fd_mode, "1080I-30" , 9) == -1 ) )
		{
			printf( " Error in writing the mode \n " );
			goto errorexit;
		}
		printf(" successfully configured 1080 \n" ); 
	}


	
	/*if ( ioctl(fd, VIDIOC_S_STD, &std_id) == -1 )
	{
		printf(" Init : VIDIOC_S_STD\n");
		goto errorexit;
	}


	if ( ioctl (fd, VIDIOC_G_STD, &std_id) == -1)
	{
		printf(" Initi : VIDIOC_G_STD \n");
		goto errorexit;
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
	printf("the fd = %d \n",fd);
	req.count = 4;
	req.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	req.memory = V4L2_MEMORY_MMAP;

	if ( ioctl(fd, VIDIOC_REQBUFS, &req) == -1)
	{
		perror("Init: cannot allocate memory for displaying\n");
		goto errorexit;
	}


	disp_buff_info = (struct buffer *) malloc(sizeof( struct buffer ) * req.count);
	if (!disp_buff_info) {
		printf("Init: cannot allocate memory for display_buff_info\n");
		goto errorexit;
	}

	for (i = 0; i < req.count; i++) 
	{
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.index = i;
		if ( ioctl(fd, VIDIOC_QUERYBUF, &buf) == -1)
		{
			printf(" Init : Display VIDIOC_QUERYCAP\n");
			for (j = 0; j < i; j++)
				munmap(disp_buff_info[j].start,disp_buff_info[j].length);
			goto errorexit;
		}
		disp_buff_info[i].length = buf.length;
		disp_buff_info[i].index = buf.index;

		disp_buff_info[i].start = mmap(NULL, buf.length, PROT_READ | PROT_WRITE,MAP_SHARED, fd, buf.m.offset);

		if ((unsigned int) disp_buff_info[i].start == MAP_SHARED) 
		{
			printf("Cannot mmap = %d buffer\n", i);
			for (j = 0; j < i; j++)
				munmap(disp_buff_info[j].start,disp_buff_info[j].length);
			goto errorexit;
		}
	}

	fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;	
	
	
	if (vid_output == 0)
	{
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	}
	else if (vid_output == 1)
	{	
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	}
	else if (vid_output == 2 && vid_fmt == 6)
	{	
		fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	}
	else if (vid_output == 2 && vid_fmt == 5)
	{	
		fmt.fmt.pix.field = V4L2_FIELD_NONE;
	}
		
	

	crop.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	if ((((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 0)))
	{
		fmt.fmt.pix.width = WIDTH;
		fmt.fmt.pix.height = HEIGHT;
		printf("The height is %d \n", HEIGHT);
		printf("The width is %d \n", WIDTH);
		crop.c.width= WIDTH;
		crop.c.height= HEIGHT;
		crop.c.top  = 0;
		crop.c.left = 0;
		line_length = WIDTH*2;
	}
	else if ((((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 1)))
	{
		fmt.fmt.pix.width = WIDTH;
		fmt.fmt.pix.height = HEIGHT;
		printf("The height is %d \n", fmt.fmt.pix.height);
		printf("The width is %d \n", fmt.fmt.pix.width);
		crop.c.width= WIDTH/2;
		crop.c.height= IN_HEIGHT/2;
		//crop.c.top  = (IN_WIDTH/2) - (IN_WIDTH/4);
		//crop.c.left = (IN_HEIGHT/2) - (IN_HEIGHT/4);
		crop.c.top  = 0;
		crop.c.left = 0;
		line_length = (WIDTH/2)*2;
	}
	else if(vid_output == 2)
	{
		fmt.fmt.pix.width = WIDTH;
		fmt.fmt.pix.height = HEIGHT;
		printf("The height is %d \n", HEIGHT);
		printf("The width is %d \n", WIDTH);
		crop.c.width= IN_WIDTH;
		crop.c.height= IN_HEIGHT;
		crop.c.top  = 0;
		crop.c.left = 0;
		line_length = WIDTH*2;
	}
	else
	{
		fmt.fmt.pix.width = WIDTH;
		fmt.fmt.pix.height = HEIGHT;
		printf("The height is %d \n", HEIGHT);
		printf("The width is %d \n", WIDTH);
		crop.c.width= WIDTH;
		crop.c.height= HEIGHT;
		crop.c.top  = 0;
		crop.c.left = 0;
		line_length = WIDTH*2;
	}

	
	
	if ( ioctl(fd, VIDIOC_S_FMT, &fmt) == -1)
	{
		printf (" Init: Display_VIDIOC_S_FMT \n");
		goto errorexit;
	}


	if ( ioctl(fd, VIDIOC_S_CROP, &crop) == -1 )
	{
		printf (" INIT : VIDIOC_S_CROP\n");
		for (j = 0; j < req.count; j++)
		{
			munmap(disp_buff_info[j].start, disp_buff_info[j].length);
		}
		goto errorexit;
	}



	/* Enqueue buffers */
	for (i = 0; i < req.count; i++)
	{
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.index = i;
		buf.memory = V4L2_MEMORY_MMAP;
		if ( ioctl(fd, VIDIOC_QBUF, &buf)  == -1)
		{
			printf (" Init : Display_VIDIOC_QBUF \n");
			for (j = 0; j < req.count; j++)
				munmap(disp_buff_info[j].start,disp_buff_info[j].length);
			goto errorexit;
		}
	}


	if ( ioctl(fd, VIDIOC_STREAMON, &a)  == -1)
	{
		printf (" Init : Display_VIDIOC_STREAMON\n");
		for (i = 0; i < req.count; i++)
			munmap(disp_buff_info[i].start, disp_buff_info[i].length);
		goto errorexit;
	}
	
	return 0;

errorexit:
	return -1;

}

#if 0
int Init_osd0 ( )
{
	
	vpbe_window_position_t pos;
	int i, osd0_size;

        if (ioctl(fdosd0, FBIOGET_FSCREENINFO, &osd_fixInfo) < 0) 
	{
                printf("\nFailed FBIOGET_FSCREENINFO osd");
                goto errorexit;
        }

        /* Get Existing var_screeninfo */
        if (ioctl(fdosd0, FBIOGET_VSCREENINFO, &prev_osd0_var) < 0) {
                printf("\nFailed FBIOGET_VSCREENINFO");
                goto errorexit;
        }

        //prev_osd0_var = *pvarInfo;
        /* Modify the resolution and bpp as required */
        /*pvarInfo->xres = test_data.osd0_width;
        pvarInfo->yres = test_data.osd0_height;
        pvarInfo->bits_per_pixel = test_data.osd0_bpp;
        pvarInfo->vmode = test_data.osd0_vmode;*/
	if (osd0_en == 0)
	{
		prev_osd0_var.xres = 0;
		prev_osd0_var.yres = 0;	
	}
	else if (osd0_en == 1)
	{
		prev_osd0_var.xres = WIDTH/4;
		prev_osd0_var.yres = HEIGHT/4;
		prev_osd0_var.bits_per_pixel = 16;
		if (vid_output == 0)
		{
			prev_osd0_var.vmode = FB_VMODE_INTERLACED;
		}
		else if (vid_output == 1)
		{	
			prev_osd0_var.vmode = FB_VMODE_NONINTERLACED;
		}
		pos.xpos = WIDTH/2;
		pos.ypos = HEIGHT/2;
	}		


        /* Set window parameters */
        if (ioctl(fdosd0, FBIOPUT_VSCREENINFO, &prev_osd0_var) < 0) 
	{
                printf("\nFailed FBIOPUT_VSCREENINFO");
                goto errorexit;
        }

	if (osd0_en ==1)
	{
		if (ioctl(fdosd0, FBIO_SETPOS, &pos) < 0) 
		{
                	printf("\nFailed FBIO_SETPOS");
                	goto errorexit;
        	}
		printf (" the osd0-size-line-length = %d \n",osd_fixInfo.line_length);
		osd0_size = osd_fixInfo.line_length * prev_osd0_var.yres;
		printf (" the osd0-size = %d \n",osd0_size);
		osd0_display[0] = (char *) mmap (NULL,osd0_size * 2, PROT_READ | PROT_WRITE, MAP_SHARED, fdosd0, 0);
		if (osd0_display[0] == MAP_FAILED)
    		{
      			printf ("\nFailed mmap on %s", "ODS0");
      			goto errorexit;
    		}

  		for (i = 0; i < 1; i++)
    		{
      			osd0_display[i + 1] = osd0_display[i] + osd0_size;
      			//printf ("Display buffer %d mapped to address %#lx\n", i + 1,
	      		//(unsigned long) osd0_display[i + 1]);
    		}
	}

	

	printf (" xres = %d , yres = %d ", prev_osd0_var.xres, prev_osd0_var.yres );

	return 0;

	errorexit:

	return -1;

}
#endif


int startloop ( int fdcap, int fddisp )
{
	struct v4l2_buffer buf;
  	//static int captFrmCnt = 0;
 	//char *ptrPlanar = NULL;
  	//int dummy;
  	//struct timeval timev;
  	struct timezone zone;
	int a, i, osd0_size;//, count = 0;
	//ptrPlanar = (char *) calloc (1, WidthFinal * nHeightFinal * 2);

  	while (1)
    	{
      		fd_set fds;
      		struct timeval tv;
      		int r;
	  	bzero((void *)&zone, sizeof (struct timezone));

      		if (stress)
		{
	  		startLoopCnt--;
	  		if (startLoopCnt == 0)
	    		{
	      			startLoopCnt = 50;
	      			break;
	    		}
		}
		FD_ZERO (&fds);
      		FD_SET (fdcap, &fds);

      		/* Timeout. */
      		tv.tv_sec = 2;
      		tv.tv_usec = 0;

      		r = select (fdcap + 1, &fds, NULL, NULL, &tv);

      		if ( r == -1 )
		{
			if (EINTR == errno)
	    		continue;

	  		printf ("EXEC : StartCameraCaputre:select\n");
	  		goto errorexit;
		}

      		if ( r == 0 )
		{
	  		continue;
		}
		
		//if(count == 100)
		//{
      		CLEAR (buf);
      		buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      		buf.memory = V4L2_MEMORY_MMAP;
      
		if ( ioctl (fdcap, VIDIOC_DQBUF, &buf) == -1)
		{
	  		if (EAGAIN == errno)
	    		continue;
	  		printf (" Exec : StartCameraCaputre:ioctl:VIDIOC_DQBUF\n");
	  		goto errorexit;
		}


		if( DisplayFrame (fddisp, cap_buffers[buf.index].start) == -1)
		{
			printf ( "EXEC : Error in displaying the freames \n");
			goto errorexit;
		}

		if ( ioctl (fdcap, VIDIOC_QBUF, &buf) == -1)
		{
	  		printf ("EXEC : StartCameraCaputre:ioctl:VIDIOC_QBUF\n");
			goto errorexit;
		}
		//sleep(6);
		//break;
		//}
		if (osd0_en == 1)
		{
			if (display_osd0() == -1)
			{
				printf ("Error in displaying the image in OSD0 \n");
				goto errorexit;
			}
		}
		//count = count + 1;
	}	

	if ( ioctl(fddisp, VIDIOC_STREAMOFF, &a) == -1 )
	{
		printf("VIDIOC_STREAMOFF\n");
		for (i = 0; i < 4; i++)
		{
			munmap(disp_buff_info[i].start, disp_buff_info[i].length);
		}
		goto errorexit;
	}
    
	
	for (i = 0; i < 4; i++)
	{
		munmap(disp_buff_info[i].start, disp_buff_info[i].length);
	}
#if 0
	osd0_size = osd_fixInfo.line_length * prev_osd0_var.yres;
	printf ("the osd0_size = %d \n", osd0_size);
	if (munmap (osd0_display[0], osd0_size * 2) == -1)
	{
	  printf ("\nFailed munmap on %s", "OSD0");
	  goto errorexit;
	}
#endif


	return 0;

	errorexit:

	return -1;
}

int DisplayFrame ( int fd, void *ptrBuffer )
{
	int i;
  	//int y, xres, yres;
  	void *buf_new;
  	unsigned int in_line_length = IN_WIDTH*2;
	char *src, *dest;
	//int fd1;
	//struct v4l2_buffer buf1;

	//printf("LINE_LENGTH : %d \n", line_length);
  	buf_new = getDisplayBuffer(fd);

	if (buf_new == NULL)
  	{
		printf(" Display : Error in getting display buffer\n");
		goto errorexit;
  	}

	src = ptrBuffer;
  	dest = buf_new;
	for (i=0; i < HEIGHT; i++)
	{
	  	memcpy (dest,src,line_length);
		dest += line_length;
		src += in_line_length;
      	}

	 

  	if (putDisplayBuffer(fd,buf_new) < 0)
  	{
		printf(" Display : Error in put display buffer\n");
		goto errorexit;
  	}

	/*if ((vid0_driver == 1) && (vid1_driver == 1))
	{
		if (cap_plane == 0)
		{
			fd1 = fddisp1;
		}
		else
		{
			fd1 = fddisp0;
		}
		memset(&buf1, 0, sizeof(buf1));
		buf1.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		if ( ioctl(fd1, VIDIOC_DQBUF, &buf1) == -1) 
		{
			printf("DQBUF : VIDIOC_DQBUF\n");
			for (i = 0; i < 3; i++)
			{
				munmap(buff_info[i].start,buff_info[i].length);
			}
			goto errorexit;
		}
		//start of putdisplaybuffer
		//if (buff_info[buf1.index].start == NULL)
		//{
		//	printf("Error in getting display buffer\n");
		//	goto errorexit;
		//}

		buf1.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf1.memory = V4L2_MEMORY_MMAP;
		if ( ioctl(fd1,VIDIOC_QBUF, &buf1) == -1)
		{
			printf("QBUF : Error in put display buffer\n");
			goto errorexit;
		}
	}*/


  	return 0;

	errorexit:

	return -1;

}

int putDisplayBuffer ( int fd , void *addr )
{
	struct v4l2_buffer buf;
	int i, index = 0;

	memset(&buf, 0, sizeof(buf));

	for (i = 0; i < 4; i++) 
	{
		if (addr == disp_buff_info[i].start)
		 {
			index = disp_buff_info[i].index;
			break;
		}
	}

	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	buf.memory = V4L2_MEMORY_MMAP;
	buf.index = index;

	if ( ioctl(fd, VIDIOC_QBUF, &buf) == -1)
	{
		printf(" EXEC : error in queuing the buffer \n");
		goto errorexit;
	}


	return 0;

	errorexit:

	return -1;
} 

void *getDisplayBuffer ( int fd )
{
	int i;
	struct v4l2_buffer buf;

	memset(&buf, 0, sizeof(buf));
	buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	if ( ioctl(fd, VIDIOC_DQBUF, &buf) == -1)
	{
		printf (" EXEC : VIDIOC_DQBUF\n");
		for (i = 0; i < 4; i++)
			munmap(disp_buff_info[i].start,disp_buff_info[i].length);
		goto errorexit;
	}

	return disp_buff_info[buf.index].start;

	errorexit:

	return NULL;


}

int display_osd0 ( )

{
	char *src, *dst;
	int i;
	struct fb_var_screeninfo vInfo;
	
	dst = osd0_display[0];
	if ( dst == NULL )
	{
		printf ("Error in mapping the user buffer to kernel buffer area \n ");
		goto errorexit;
	}
	src = (char *) rgb16;
	for (i=0; i < (HEIGHT/4); i++)
	{
		memcpy(dst, src, (WIDTH/2));
		dst += osd_fixInfo.line_length;
		src += (704*2);
	}

	if (ioctl (fdosd0, FBIOGET_VSCREENINFO, &vInfo) < -1)
    	{
      		printf ("FlipbitmapBuffers:FBIOGET_VSCREENINFO\n");
      		goto errorexit;
    	}

  	vInfo.yoffset = 0;

	if (ioctl (fdosd0, FBIOPAN_DISPLAY, &vInfo) < -1)
    	{
      		printf ("FlipbitmapBuffers:FBIOPAN_DISPLAY\n");
	      	goto errorexit;
    	}

  	return 0;

	errorexit:

	return -1;
}
/*int stream_disp ( int fd )
{
	struct v4l2_requestbuffers req;
	struct v4l2_buffer buf;
	//struct buffer buff_info;
	struct v4l2_crop crop;
	//struct v4l2_format fmt;
	int i, j, a;

	req.count = 2;
	req.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;

	req.memory = V4L2_MEMORY_MMAP;

	if ( ioctl(fd, VIDIOC_REQBUFS, &req) == -1)
	{
		printf("cannot allocate memory\n");
		goto errorexit;
	}

	buff_info = (struct buffer *) malloc(sizeof(struct buffer) * req.count);
	if (!buff_info) 
	{
		printf("Init : cannot allocate memory for buff_info\n");
		goto errorexit;
	}

	for (i = 0; i < req.count; i++) {
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.index = i;
		if ( ioctl(fd, VIDIOC_QUERYBUF, &buf) == -1 )
		 {
			printf("Error in VIDIOC_QUERYCAP\n");
			for (j = 0; j < i; j++)
			{
				munmap(buff_info[j].start,buff_info[j].length);
			}
			goto errorexit;
		}
		buff_info[i].length = buf.length;

		buff_info[i].start = mmap(NULL, buf.length, PROT_READ | PROT_WRITE,MAP_SHARED, fd, buf.m.offset);

		printf("buff_info[i].length = %d",buff_info[i].length);

		if ((unsigned int) buff_info[i].start == MAP_SHARED)
		{
			printf("Cannot mmap = %d buffer\n", i);
			for (j = 0; j < i; j++)
			{
				munmap(buff_info[j].start,buff_info[j].length);
			}
			goto errorexit;
		}
		strncpy((char *)buff_info[i].start,(char *)vidwin1_640_480_YCC_idata,(640*480*2));
	}*/
	
	/*fmt.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;	
	fmt.fmt.pix.width= 720;	
	fmt.fmt.pix.height= 480;	
	fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
	if ( ioctl(fd, VIDIOC_S_FMT, &fmt) == -1)
	{
		printf("FMT : VIDIOC_S_FMT\n");
		goto errorexit;
	}*/


	/*crop.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
	crop.c.top  = 0;
	crop.c.left = 240;
	crop.c.width= 320;
	crop.c.height= 240;

	if ( ioctl(fd, VIDIOC_S_CROP, &crop) == -1) 
	{
		printf(" CROP : VIDIOC_S_CROP\n");
		for (j = 0; j < req.count; j++)
		{
			munmap(buff_info[j].start, buff_info[j].length);
		}
		goto errorexit;
	}*/


	/* Enqueue buffers */
	/*for (i = 0; i < req.count; i++)
   	{
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.index = i;
		buf.memory = V4L2_MEMORY_MMAP;
		//memset(buff_info[i].start,0xff,buff_info[i].length);
		if (ioctl(fd, VIDIOC_QBUF, &buf) == -1)
        	{
			printf ("ENQUEUE : VIDIOC_QBUF\n");
			for (j = 0; j < req.count; j++)
			{
				munmap(buff_info[j].start,buff_info[j].length);
			}
			goto errorexit;
		}
	}
	
	if ( ioctl(fd, VIDIOC_STREAMON, &a) == -1)
    	{
		printf ("STREAMON : VIDIOC_STREAMON\n");
		for (i = 0; i < req.count; i++)
		{
			munmap(buff_info[i].start, buff_info[i].length);
		}
		goto errorexit;
	}

	//while(1)
	//{
		//start of getdisplaybuffer
		memset(&buf, 0, sizeof(buf));
		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		if ( ioctl(fd, VIDIOC_DQBUF, &buf) == -1) 
		{
			printf("DQBUF : VIDIOC_DQBUF\n");
			for (i = 0; i < 3; i++)
			{
				munmap(buff_info[i].start,buff_info[i].length);
			}
			goto errorexit;
		}
		//start of putdisplaybuffer
		if (buff_info[buf.index].start == NULL)
		{
			printf("Error in getting display buffer\n");
			goto errorexit;
		}

		buf.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;
		buf.memory = V4L2_MEMORY_MMAP;
		if ( ioctl(fd,VIDIOC_QBUF, &buf) == -1)
		{
			printf("QBUF : Error in put display buffer\n");
			goto errorexit;
		}
	}



	
	return 0;

	errorexit:

	return -1;
}*/

