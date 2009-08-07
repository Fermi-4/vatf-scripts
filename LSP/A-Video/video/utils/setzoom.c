/*
 * Filename: setzoom.c
 * 
 * Function: verify IOCTL FBIO_SETZOOM.
 *
 * 
 * The blend factor will be set across the area entire area covered by OSD1.
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
#include <errno.h>
#include <video/davincifb_ioctl.h>

/* True of false enumeration */
#define TRUE            1
#define FALSE           0

// Do not Initialise these anymore. They should be updated only if the device exists.
char *FB_DEVICE = NULL;


int main(int argc, char *argv[])
{

  FILE * fp;
  int c;
  char d1[5];
  char d2[50];

  int fd = 0; //Handle for device file descriptors
  
  struct zoom_params zoom;
  
  if ( argc != 4 ){
                 printf ("Format:\t setzoom [window] [hzoom] [vzoom]\n");
                 printf(" Valid Window values are OSD0,OSD1, VID0, VID1\n");
                 printf("hzoom:0,1,2\n");
                 printf("vzoom:0,1,2\n");
                 return -1;
                 }

  fp = fopen("/proc/fb","r");

  if (fp == NULL){
                  printf(" Unable to open /proc/fb for reading\n");
                 }  

   
  while( fscanf(fp,"%s",d1) != EOF)
  {
   fscanf(fp,"%s",d2);
    
    if (strcmp(argv[1],"OSD1") == 0){
                          if (strcmp(d2,"dm_osd1_fb") == 0){
                                                           FB_DEVICE = malloc(10);
                                                           strcpy(FB_DEVICE,"/dev/fb/");
                                                           strcat(FB_DEVICE,d1);
                                                           break;
                                                           }
                          }
    else if (strcmp(argv[1],"OSD0") == 0){
                          if (strcmp(d2,"dm_osd0_fb") == 0){
                                                           FB_DEVICE = malloc(10);
                                                           strcpy(FB_DEVICE,"/dev/fb/");
                                                           strcat(FB_DEVICE,d1);
                                                           break;
                                                           }
                          }

   else if (strcmp(argv[1],"VID0") == 0){
                          if (strcmp(d2,"dm_vid0_fb") == 0){
                                                           FB_DEVICE = malloc(10);
                                                           strcpy(FB_DEVICE,"/dev/fb/");
                                                           strcat(FB_DEVICE,d1);
                                                           break;
                                                           }
                          }

   else if (strcmp(argv[1],"VID1") == 0){
                          if (strcmp(d2,"dm_vid1_fb") == 0){
                                                           FB_DEVICE = malloc(10);
                                                           strcpy(FB_DEVICE,"/dev/fb/");
                                                           strcat(FB_DEVICE,d1);
                                                           break;
                                                           }
                          }

   else {
         printf("Please enter window id to zoom (OSD0,OSD1,VID0,VID1)\n");
         return -1;
        }

  }

  fd = open(FB_DEVICE,O_RDWR);

  if (fd < 0){
   printf("Unable to open %s\n",FB_DEVICE);
   return -1;
   }

  printf("Opened %s successfully\n",FB_DEVICE);
  
  // Fill in zoom structure information before passing it to the IOCTL.
  
  // Set up window ID.
  zoom.window_id = fd;
  // Initialize Horizontal zoom
  zoom.zoom_h = atoi(argv[2]);
  // Initialize Vertical zoom
  zoom.zoom_v = atoi(argv[3]);
  
  //Do not do any range checking here. if zoom values are out of range, the IOCTL call
  // Should return error.
  
  if (ioctl(fd,FBIO_SETZOOM,&zoom) < 0){
              perror("FBIO_SETZOOM failed \n");
	      return -1;
	      }
	      else printf("FBIO_SETZOOM Successful\n");
	      
	      
	      return 0;
 }
