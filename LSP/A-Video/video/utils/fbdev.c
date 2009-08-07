/*
 * Filename: fbdev.c
 * 
 * This sample application illustrates how to read the framebuffer device at run time.
 * All framebuffer devices are entered in /proc/fb and parsing the file will help us 
 * identify the required device. 
 *
*/

/* Header files */
#include <stdio.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <linux/fb.h>
#include <stdlib.h>
#include <unistd.h>
#include <video/davincifb_ioctl.h>

/* True of false enumeration */
#define TRUE            1
#define FALSE           0

// Do not Initialise these anymore. They should be updated only if the device exists.
char *OSD0_DEVICE = NULL; 
char *OSD1_DEVICE = NULL;
char *FBVID0_DEVICE = NULL ;
char *FBVID1_DEVICE = NULL;
int osd0, osd1, vid0, vid1;
int loop = 1, blocking = 1;


void printdev()
{
  int i;	
  for(i=0; i< loop; i++)
  {	
  if (OSD0_DEVICE == NULL){
                           printf("No OSD0 device\n");
                          }
                          else{
				if(blocking == 1)
				{
				osd0 = open(OSD0_DEVICE,O_RDWR);
				}
				else
				{
				osd0 = open(OSD0_DEVICE,O_RDWR | O_NONBLOCK);
				}
			       if(osd0 < 0)
				{
					printf("Error in opening fbdev device %s \n", OSD0_DEVICE);
				}
				else
				{
					printf("OSD0 Device %s opened successfuly\n",OSD0_DEVICE);
				}
				if(close(osd0) < 0)
				{
					printf("Error in closing fbdev device %s \n", OSD0_DEVICE);
				}
				else
				{
					printf("OSD0 Device %s closed successfuly\n",OSD0_DEVICE);
				}

                               }
  if (OSD1_DEVICE == NULL){
                           printf("No OSD1 device\n");
                          }
                          else{
				if(blocking == 1)
				{
				osd1 = open(OSD1_DEVICE,O_RDWR);
				}
				else
				{
				osd1 = open(OSD1_DEVICE,O_RDWR | O_NONBLOCK);
				}
				if(osd1 < 0)
				{
					printf("Error in opening fbdev device %s \n", OSD1_DEVICE);
				}
				else
				{
					printf("OSD1 Device %s opened successfuly\n",OSD1_DEVICE);
				}
				if(close(osd1) < 0)
				{
					printf("Error in closing fbdev device %s \n", OSD1_DEVICE);
				}
				else
				{
					printf("OSD1 Device %s closed successfuly\n",OSD1_DEVICE);
				}


                               }
  if (FBVID0_DEVICE == NULL){
                           printf("No VID0 device\n");
                          }
                          else{
				if(blocking == 1)
				{
				vid0 = open(FBVID0_DEVICE,O_RDWR);
				}
				else
				{
				vid0 = open(FBVID0_DEVICE,O_RDWR | O_NONBLOCK);
				}
				if( vid0 < 0)
				{
					printf("Error in opening fbdev device %s \n", FBVID0_DEVICE);
				}
				else
				{
					printf("VID0 Device %s opened successfuly\n",FBVID0_DEVICE);
				}
				if(close(vid0) < 0)
				{
					printf("Error in closing fbdev device %s \n", FBVID0_DEVICE);
				}
				else
				{
					printf("VID0 Device %s closed successfuly\n",FBVID0_DEVICE);
				}

                               }
  if (FBVID1_DEVICE == NULL){
                           printf("No VID1 device\n");
                          }
                          else{
				if(blocking == 1)
				{
				vid1 = open(FBVID1_DEVICE,O_RDWR);
				}
				else
				{
				vid1 = open(FBVID1_DEVICE,O_RDWR | O_NONBLOCK);
				}
				if( vid1 < 0)
				{
					printf("Error in opening fbdev device %s \n", FBVID1_DEVICE);
				}
				else
				{
					printf("VID1 Device %s opened successfuly\n",FBVID1_DEVICE);
				}
				if(close(vid1) < 0)
				{
					printf("Error in closing fbdev device %s \n", FBVID1_DEVICE);
				}
				else
				{
					printf("VID1 Device %s closed successfuly\n",FBVID1_DEVICE);
				}

                               }
}
}

int main(int argc, char *argv[])
{

  FILE * fp;
  //int c;
  char options[] = "l:b:";
  char d1[5];
  char d2[50];
  int d;
 
  fp = fopen("/proc/fb","r");

  //int osd0 = 0;


  if (fp == NULL){
                  printf(" Unable to open /proc/fb for reading\n");
                 }  
	for(;;)
	{
		d = getopt_long(argc, argv, options, (void *)NULL, NULL);
		if (d == -1)
			break;
		switch(d)
		{
			case 'l':
			case 'L':
				{
				loop = atoi(optarg);
				//printf("The channel no is : %d \n", ch_no);
				break;
				}
			case 'b':
			case 'B':
				{
				blocking = atoi(optarg);
				//printf("The channel no is : %d \n", ch_no);
				break;
				}

		}
	}

 // This scans the last line twice. Bad example.
  /*while(!feof(fp))
  {
   fscanf(fp,"%s",d1);
   printf("%s:",d1);
   fscanf(fp,"%s",d2);
   printf("%s\n",d2);
  }*/

  while( fscanf(fp,"%s",d1) != EOF)
  {
   fscanf(fp,"%s",d2);


    if (strcmp(d2,"dm_osd0_fb") == 0){
      //osd0 exists. variable d1 stores the corresponding framebuffer device # as a string.
      OSD0_DEVICE = malloc(10);
      strcpy(OSD0_DEVICE,"/dev/fb/");
      strcat(OSD0_DEVICE,d1);
      //OSD0 device should be /dev/fb/"d1". Similarly for the other devices.
      }
    if (strcmp(d2,"dm_osd1_fb") == 0){
      OSD1_DEVICE = malloc(10);
      strcpy(OSD1_DEVICE,"/dev/fb/");
      strcat(OSD1_DEVICE,d1);
      }
    if (strcmp(d2,"dm_vid0_fb") == 0){
      FBVID0_DEVICE = malloc(10);
      strcpy(FBVID0_DEVICE,"/dev/fb/");
      strcat(FBVID0_DEVICE,d1);
      }
    if (strcmp(d2,"dm_vid1_fb") == 0){
      FBVID1_DEVICE = malloc(10);
      strcpy(FBVID1_DEVICE,"/dev/fb/");
      strcat(FBVID1_DEVICE,d1);
      }
  }

  printdev();


  return 0;
}
