/*
 * Filename: setbkgcolor.c
 * 
 * Function: Verify FBIO_SET_BACKG_COLOR.
 *
 * To test this IOCTL, disable all the windows and check the background color.
 * If the IOCTL is successfull, the background color changes.
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
  
  vpbe_backg_color_t backg_color;

  int fd = 0; //Handle for device file descriptors

  if ( argc != 4 ){
                 printf ("Format:\t setbkgcolor [window] [clut] [color]\n");
                 printf(" Valid Window values are OSD0,OSD1, VID0, VID1\n");
                 printf("clut: 0->ROM_CLUT0,1->ROM_CLUT1,2->RAM_CLUT\n");
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
         printf("Please enter window id to color (OSD0,OSD1,VID0,VID1)\n");
         return -1;
        }

  }

  printdev();


  fd = open(FB_DEVICE,O_RDWR);

  if (fd < 0){
   printf("Unable to open %s\n",FB_DEVICE);
   return -1;
   }


  backg_color.clut_select = (unsigned char)(atoi(argv[2])); 
  backg_color.color_offset = (unsigned char)(atoi(argv[3])); 

  
  printf("clut_select  is %d\n",backg_color.clut_select);
  printf("color_offset is %d\n",backg_color.color_offset);

  if(ioctl(fd,FBIO_SET_BACKG_COLOR,&backg_color) < 0){
                      perror("FBIO_SET_BACKG_COLOR Failed:");
                      return -1;
                      }
 return 0;
}
