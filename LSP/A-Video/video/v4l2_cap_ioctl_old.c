// This file is the main file for the open and closing of the video capture devices. Dated : 07/17/2008

#include"vloop_inc.h"
#include "vpfe_dm355_interface.h"

int main(int argc, char *argv[])
{
	char shortoptions[] = "o:i:c:p:";
	int options, params, ch, plat,d,j, result, fd_cap;

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
			case 'i':
			case 'I':
				params = atoi(optarg);
				break;
			case 'c':
			case 'C':
				ch = atoi(optarg);
				break;
			case 'p':
			case 'P':
				plat = atoi(optarg);
				break;
			default:
				options = 1;
				params = 1;
				ch = 0;
				plat = 0;
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
		if(Init_Capture(fd_cap, params, ch, plat) == -1)
		{
			printf("Failed INPUT \n");
			return -1;
		}
		else
		{
			printf("Success INPUT \n");	
		}
	}
	return 0;
}	

	


