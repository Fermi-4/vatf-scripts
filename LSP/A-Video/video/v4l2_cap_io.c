// This file is the main file for the open and closing of the video capture devices. Dated : 07/17/2008

#include"vloop_inc.h"
#include "vpfe_dm355_interface.h"

int main(int argc, char *argv[])
{
	char shortoptions[] = "i:c:";
	int iter, ch, d,j, result;

	for(;;)
	{
		d = getopt_long(argc, argv, shortoptions, (void *) NULL,&index);
		if (-1 == d)
			break;
		switch (d) {
			case 'i':
			case 'I':
				iter = atoi(optarg);
				break;
			case 'c':
			case 'C':
				ch = atoi(optarg);
				break;
			default:
				iter = 1;
				ch = 0;
				break;
		}
	}
		

	for(j = 0; j < iter; j++)
	{
		if( Vpfe_Open_Close((ch-1)) == -1)
		{
			result = 0;
			break;
		}
		result = 1;
	}

	if( result == 0 )
	{
		printf("Failed Open/Close \n");
	}
	else if( result == 1)
	{
		printf("Success Open/Close \n");
	}
	return 0;
}
