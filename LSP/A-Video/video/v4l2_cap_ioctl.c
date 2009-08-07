// This file is the main file for the open and closing of the video capture devices. Dated : 07/17/2008

#include"vloop_inc.h"
#include "vpfe_dm355_interface.h"

int main(int argc, char *argv[])
{
	char shortoptions[] = "o:p:c:n:i:s:";
	int options = 1, stds = 0, ch = 0, plat = 0, ips = 0, neg = 0, d,j, result, fd_cap, vals;

	for(;;)
	{
		d = getopt_long(argc, argv, shortoptions, (void *) NULL,&index);
		if (-1 == d)
			break;
		switch (d) {
			case 'o':
			case 'O':
				options = atoi(optarg);
				break;
			case 'p':
			case 'P':
				plat = atoi(optarg);
				break;
			case 'c':
			case 'C':
				ch = atoi(optarg);
				break;
			case 'n':
			case 'N':
				neg = atoi(optarg);
				break;
			case 'i':
			case 'I':
				ips = atoi(optarg);
				break;
			case 's':
			case 'S':
				stds = atoi(optarg);
				break;
			default:
				break;
		}
	}

	fd_cap = Vpfe_Open(VID_IN0, O_RDWR);
	if(fd_cap == -1)	
	{
		printf("Error in opening the device \n");
		printf("Failed INPUT \n");
		return -1;
	}
	if(options == 1)
	{
		if(Init_Capture(fd_cap, ips, ch, plat) == -1)
		{
			printf("Failed INPUT \n");
			return -1;
		}
		else
		{
			printf("Success INPUT \n");	
		}
	}
	if(options == 2)
	{
		if(Init_Capture(fd_cap, ips, ch, plat) == -1)
		{
			printf("Failed STD \n");
			return -1;
		}
		
		if(neg >= 1) //for get_std ioctl
		{
			if(stds == 0)
			{
				vals = 0;
			}
			else if(stds == 1)
			{
				vals = 20;
			}
			if(V4l2_cap_std_neg(fd_cap, (neg-1), vals) == -1)
			{
				printf("Failed Negative Test \n");
				return -1;
			}
			else
			{
				printf("Passed Negative Test \n");
				return 0;
			}
		}
		if(V4l2_Cap_std_Ioctl(fd_cap, stds) == -1)
		{ 
			printf("Failed STD \n");
			return -1;
		}
		else
		{
			printf("Success STD \n");
			return 0;
		}
		
	}
	if(options == 3)
	{
		if(Init_Capture(fd_cap, ips, ch, plat) == -1)
		{
			printf("Failed FMT \n");
			return -1;
		}
		
		if(neg >= 1) //for get_std ioctl
		{
			if(stds == 0)
			{
				vals = 0;
			}
			else if(stds == 1)
			{
				vals = 20;
			}
			if(V4l2_cap_fmt_neg(fd_cap, (neg-1), vals) == -1)
			{
				printf("Failed Negative Test \n");
				return -1;
			}
			else
			{
				printf("Passed Negative Test \n");
				return 0;
			}
		}
		if(V4l2_Cap_fmt_Ioctl(fd_cap, stds) == -1)
		{ 
			printf("Failed FMT \n");
			return -1;
		}
		else
		{
			printf("Success FMT \n");
			return 0;
		}
		
	}
	if(options == 4)
	{
		if(Init_Capture(fd_cap, ips, ch, plat) == -1)
		{
			printf("Failed CROP \n");
			return -1;
		}
		if(neg >= 1)
		{
			if(V4l2_cap_crop_neg(fd_cap, (neg-1)) == -1)
			{
				printf("Failed Negative Test \n");
				return -1;
			}
			else
			{
				printf("Passed Negative Test \n");
				return 0;
			}
		}
		if(V4l2_Cap_crop_Ioctl(fd_cap) == -1)
		{ 
			printf("Failed CROP \n");
			return -1;
		}
		else
		{
			printf("Success CROP \n");
			return 0;
		}
	}
	if (options == 5)
	{
		if(Init_Capture(fd_cap, ips, ch, plat) == -1)
		{
			printf("Failed BUF \n");
			return -1;
		}

		if(neg >= 1)
		{
			if(V4l2_cap_buf_neg(fd_cap, (neg-1), stds) == -1)
			{
				printf("Failed Negative Test \n");
				return -1;
			}
			else
			{
				printf("Passed Negative Test \n");
				return 0;
			}

		}	
		if(V4l2_Cap_buf_Ioctl(fd_cap, 3) == -1)
		{
			printf("Failed BUF \n");
			return -1;
		}
		else
		{
			printf("Success BUF \n");
			return 0;
		}
			
	}				
		
		
		
		

		
	return 0;
}	

	


