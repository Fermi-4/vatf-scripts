/*
 * Filename: setpos.c
 * 
 * Function: Verify FBIO_SETPOS.
 *
 * when entering window position, keep in mind the position should be set keeping the window
 * dimensions in mind. if either the x or y position is entered in such a way that the window
 * is pushed out of the display, the IOCTL fails and will return error.
 * How does such a scenario arise ?
 * if window dimensions are equal to display dimension, then the only position that can be set
 * using FBIO_SETPOS is (0,0).
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
#include <errno.h>
#include <video/davincifb_ioctl.h>

/* True of false enumeration */
#define TRUE            1
#define FALSE           0

// Do not Initialise these anymore. They should be updated only if the device exists.
char *FB_DEVICE = NULL;

void printdev()
{
  if (FB_DEVICE == NULL){
                           printf("No Framebuffer device\n");
                          }
                          else{
                               printf("Framebuffer Device string is %s \n",FB_DEVICE);
                               }
}

int main(int argc, char *argv[])
{

  FILE * fp;
  int c;
  char d1[5];
  char d2[50];
  u_int32_t posx,posy;
  vpbe_window_position_t pos;
  int fd = 0; //Handle for device file descriptors

  if ( argc != 4 ){
                 printf ("Format:\t setpos [window] [x-position] [y-position]\n");
                 printf(" Valid Window values are OSD0,OSD1, VID0, VID1\n");
                 printf("x-position: 0-720\n");
                 printf("y-position: 0-480\n");
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
         printf("Please enter window id to set x position (OSD0,OSD1,VID0,VID1)\n");
         return -1;
        }

  }

  printdev();


  fd = open(FB_DEVICE,O_RDWR);

  if (fd < 0){
   printf("Unable to open %s\n",FB_DEVICE);
   return -1;
   }

  printf("Opened %s successfully\n",FB_DEVICE);

  pos.xpos = atoi(argv[2]);
  pos.ypos = atoi(argv[3]);


  if( ioctl(fd,FBIO_SETPOS,&pos) < 0){
                    perror("FBIO_SETPOS Failed.");
                    printf(" Error #: %d\n",errno);
                    }
  
  else printf("FBIO_SETPOS successfull\n");

  return 0;

 close(fd);

}

  
