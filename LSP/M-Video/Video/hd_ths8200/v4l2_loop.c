
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>	
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <string.h>

#include "v4l2_capture.h"
#include "v4l2_display.h"


int platform = 0;
int vid0_driver = 1;
int vid1_driver = 0;
int vid_output = 0;
int vid_input = 0;
int vid_fmt = 0;
int osd0_en = 0;
int osd1_en = 0;
int blend_no = 0;
int fdcap = 0;
int fddisp0 = 0;
int fddisp1 = 0;
int fdosd0 = 0;
int cap_plane = 0;
int WIDTH = 720;
int HEIGHT = 480;
int IN_WIDTH = 720;
int IN_HEIGHT = 480;


#define CAPTURE_DEVICE "/dev/video0"
#define DISPLAY_DEVICE1 "/dev/video2"
#define DISPLAY_DEVICE2 "/dev/video3"
#define OSD0_DEVICE "/dev/fb/0"

int open_all_win()
{
	#if 0
	if ( (fdosd0 = open(OSD0_DEVICE, O_RDWR)) < 0 )
	{
		printf (" Error in opening OSD0 window \n " );
		goto errorexit;
	}
	#endif

	if ((fdcap = open (CAPTURE_DEVICE, O_RDWR | O_NONBLOCK)) < 0)
    	{
		goto errorexit;
	}
	if (((vid0_driver == 1) && (vid1_driver == 0)) || (((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 0)))
	//if(vid0_driver ==1)
	{
		if ((fddisp0 = open (DISPLAY_DEVICE1, O_RDWR)) < 0)
    		{
			goto errorexit;
		}
	}
	if (((vid0_driver == 0) && (vid1_driver == 1)) || (((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 1)))
	//if(vid1_driver == 1)
	{
		if ((fddisp1 = open (DISPLAY_DEVICE2, O_RDWR)) < 0)
    		{
			goto errorexit;
		}
	}

	return 0;

errorexit:
	return -1;

	
}

int close_all_win ( )
{

	close(fdcap);
	if ( vid0_driver == 1 )
	{
		close(fddisp0);
	}
	if ( vid1_driver == 1 )
	{
		close(fddisp1);
	}
	#if 0
	if (osd0_en == 1 )
	{
		close(fdosd0);
	}
	#endif
	return 0;
}


int main(int argc,  char *argv[])
{
	//char options[] = "c:f:s:";
	//int d;
	int inr = 1;
	//char line[80];
	//char *opt;
	//FILE *conf_fd;

	//To parse the command line arguments
	char shortoptions[] = "f:i:o:v:c:";
	/*const struct option longOptions[] = {
	{"Format", required_argument, NULL, 'f'},
	{"Input", required_argument, NULL, 'i'},
	{"Output", required_argument, NULL, 'o'},
	{"Video o/p", required_argument, NULL, 'v'},
	{"Capture Plane", required_argument, NULL, 'c'}
	};*/
	int c, index =0, vid_driver;
	for(;;)
	{
	 	c = getopt_long(argc, argv, shortoptions, (void *)NULL, &index);
		if (c == -1)	
		{
			//perror("Invalid Arguments \n");
			//goto errorexit;
			break;
		}
		switch (c) {
		case 'F':
		case 'f':  vid_fmt = atoi(optarg);
			   break;
		case 'I':
		case 'i':  vid_input = atoi(optarg);
			   break;
		case 'O':
		case 'o':  vid_output = atoi(optarg);
			   break;
		case 'V':
		case 'v':  vid_driver = atoi(optarg);
			   break;
		case 'C':
		case 'c':  cap_plane = atoi(optarg);
			   break;
		default :  perror("Invalid Argument \n");
			   goto errorexit;
		}
	}

	/*conf_fd = fopen( "video.conf" , "r+" );
	for(inr = 1; inr <= 10; inr++)
	{
		fscanf(conf_fd, "%s", line);
		opt = strtok(line, "=");
		opt = strtok(NULL, "\0");
		switch(inr)
		{
			case 1:
				{
				platform = atoi(opt);
				//printf("The channel no is : %d \n", ch_no);
				break;
				}
			case 2:
				{
				vid0_driver = atoi(opt);
				//printf("The Format no is : %d \n", vid_fmt);
				break;
				}
			case 3:
				{
				vid1_driver = atoi(opt);
				//printf("The Standard no is : %d \n", vid_std);
				break;
				}
			case 4:
				{
				vid_input = atoi(opt);
				//printf("The Standard no is : %d \n", vid_std);
				break;
				}
			case 5:
				{
				vid_output = atoi(opt);
				//printf("The Standard no is : %d \n", vid_std);
				break;
				}
			case 6:
				{
				vid_fmt = atoi(opt);
				//printf("The Standard no is : %d \n", vid_std);
				break;
				}
			case 7:
				{
				osd0_en = atoi(opt);
				//printf("The Standard no is : %d \n", vid_std);
				break;
				}
			case 8:
				{
				osd1_en = atoi(opt);
				//printf("The Standard no is : %d \n", vid_std);
				break;
				}
			case 9:
				{
				blend_no = atoi(opt);
				//printf("The Standard no is : %d \n", vid_std);
				break;
				}
			case 10:
				{
				cap_plane = atoi(opt);
				//printf("The Standard no is : %d \n", vid_std);
				break;
				}
			
		}
	}*/
#if 0	
	if ((platform < 0) || (platform > 1))
	{
		printf("usage: Error in platform selected \n");
		goto errorexit;
	}
	else if (platform == 0)
	{
		if ((vid_input < 0) || (vid_input > 1))
		{
			printf("usage: Error in Input selected \n");
			goto errorexit;
		}
		if ( (vid_output < 0) || (vid_output > 1))
		{
			printf("usage: Error in Output selected \n");
			goto errorexit;
		}
	}
	else if (platform == 1)
	{
		if ((vid_input < 0) || (vid_input > 1))
		{
			printf("usage: Error in Input selected \n");
			goto errorexit;
		}
		if ((vid_output < 0) || (vid_output > 3))
		{
			printf("usage: Error in Input selected \n");
			goto errorexit;
		}

	}
	

	if ((vid0_driver < 0) || (vid0_driver > 1))
	{
		printf("usage: Error in Driver selected for video 0\n");
		goto errorexit;
	}
	if ((vid1_driver < 0) || (vid1_driver > 1))
	{
		printf("usage: Error in Driver selected for video 1\n");
		goto errorexit;
	}
#endif
	#if 0
	if ((osd0_en < 0) || (osd0_en > 1))
	{
		printf("usage: Error in ODS0 selection \n");
		goto errorexit;
	}
	
	if ((osd1_en < 0) || (osd1_en > 1))
	{
		printf("usage: Error in OSD1 selection \n");
		goto errorexit;
	}
	if ( osd1_en == 1 )
	{
		if ((blend_no < 0) || (blend_no > 7))
		{
			printf("usage: Error in Driver selected \n");
			goto errorexit;
		}
	}
	else
	{
		blend_no = 4;
	}
	#endif 
	if ( (cap_plane < 0) || (cap_plane > 1))
	{
			printf("usage: Error in OSD1 selection \n");
		goto errorexit;
	}
	if ( ((vid0_driver == 1) && (cap_plane == 0)) || ((vid0_driver == 1) && (cap_plane == 1)) )
	{
		if ( (vid_fmt < 0) || (vid_fmt > 6) )
		{
			printf(" Error in setting the mode of the Video \n" );
			goto errorexit;
		}
	}
	else if ( ((vid0_driver == 2) && (cap_plane == 0)) || ((vid0_driver == 2) && (cap_plane == 1)) )
	{
		if ( (vid_fmt < 0) || (vid_fmt > 5) )
		{
			printf(" Error in setting the mode of the Video \n" );
			goto errorexit;
		}
	}

	if (vid_fmt == 0)
	{	
		HEIGHT = 480;
		IN_HEIGHT = 480;
	}
	else if (vid_fmt == 1)
	{
		HEIGHT = 576;
		IN_HEIGHT = 576;
	}
	else if (vid_fmt == 2)
	{
		WIDTH = 640;
		HEIGHT = 480;
	}
	else if (vid_fmt == 3)
	{
		WIDTH = 640;
		HEIGHT = 400;
	}
	else if (vid_fmt == 4)
	{
		WIDTH = 640;
		HEIGHT = 350;
	}
	else if (vid_fmt == 5 && vid_output == 2)
	{
		//scanf("ENTER the WIDTH of the DISPLAY : %d \n", &WIDTH);
		//scanf("ENTER the HEIGHT of the DISPLAY : %d \n", &HEIGHT);
		WIDTH = 1280;
		HEIGHT = 720;
		IN_WIDTH = 1280;
		IN_HEIGHT = 720;
	}
	else if (vid_fmt == 6 && vid_output == 2)
	{
		//scanf("ENTER the WIDTH of the DISPLAY : %d \n", &WIDTH);
		//scanf("ENTER the HEIGHT of the DISPLAY : %d \n", &HEIGHT);
		WIDTH = 1920;
		HEIGHT = 1080;
		IN_WIDTH = 1920;
		IN_HEIGHT = 1080;
	}
	else if (vid_fmt == 5 && vid_output == 3)
	{
		//scanf("ENTER the WIDTH of the DISPLAY : %d \n", &WIDTH);
		//scanf("ENTER the HEIGHT of the DISPLAY : %d \n", &HEIGHT);
		WIDTH = 1280;
		HEIGHT = 720;
		IN_WIDTH = 720;
		IN_HEIGHT = 480;
	}
	else if (vid_fmt == 6 && vid_output == 2)
	{
		//scanf("ENTER the WIDTH of the DISPLAY : %d \n", &WIDTH);
		//scanf("ENTER the HEIGHT of the DISPLAY : %d \n", &HEIGHT);
		WIDTH = 1920;
		HEIGHT = 1080;
		IN_WIDTH = 720;
		IN_HEIGHT = 480;
	}


		
		
		 
	
	if (open_all_win() == -1)
	{
		printf("Open Device: Error in opening the video devices \n");
		goto errorexit;
	}
#if 0
	if (Init_osd0( ) == -1)
	{
		printf("Init: Error in Initializing the OSD0 \n");
		goto errorexit;
	}
#endif
		
	if (Init_capture( fdcap ) == -1)
	{
		printf("Init: Error in Initializing the Capture \n");
		goto errorexit;
	}

	if (Init_Format_capture( fdcap ) == -1)
	{
		printf("Init: Error in Initializing the Format for Capture \n");
		goto errorexit;
	}

	if (Init_Buffer_capture( fdcap ) == -1)
	{
		printf("Init: Error in Initializing the Buffers for Capture \n");
		goto errorexit;
	}

	if (start_stream( fdcap ) == -1)
	{
		printf("Problem with the Streaming \n");
		goto errorexit;
	}

	if (((vid0_driver == 1) && (vid1_driver == 0)) || (((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 0)))
	{
		printf("This is video 0 plane \n");
		if (Init_display( fddisp0 ) == -1)
		{
			printf("Init: Error in Initializing the Display \n");
			goto errorexit;
		}
		/*if ((((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 0)))
		{
			printf ("Entering the VGA STREAM \n");
			if (stream_disp( fddisp1 ) == -1)
			{
				printf("EXEC : Error in streaming a vga \n");
				goto errorexit;
			}
		}*/
		if (startloop( fdcap, fddisp0 ) == -1)
		{
			printf("Exec : Error in Playing the loopback \n");
			goto errorexit;
		}
	}
	else if (((vid0_driver == 0) && (vid1_driver == 1)) || (((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 1)))
	{
		printf("This is video 1 plane \n");
		printf("the fd = %d \n",fddisp1);

		if (Init_display( fddisp1 ) == -1)
		{
			printf("Init: Error in Initializing the Display \n");
			goto errorexit;
		}
		/*if ((((vid0_driver == 1) && (vid1_driver == 1)) && (cap_plane == 1)))
		{
			if (stream_disp( fddisp0 ) == -1)
			{
				printf("EXEC : Error in streaming a vga \n");
				goto errorexit;
			}
		}*/
		if (startloop( fdcap, fddisp1 ) == -1)
		{
			printf("Exec : Error in Playing the loopback \n");
			goto errorexit;
		}
	}
	
			
	
	close_all_win();
	return 0;

errorexit:

	close_all_win();
	return 0;
				
}


