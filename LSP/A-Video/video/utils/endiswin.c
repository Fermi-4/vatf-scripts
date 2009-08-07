/*
 * Filename: endiswin.c
 * 
 * Function: Verify FBIO_ENABLE_DISABLE_WIN.
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

  int fd = 0; //Handle for device file descriptors

  if ( argc != 3 ){
                 printf ("Format:\t endiswin [window] [enable,disable]\n");
                 printf(" Valid Window values are OSD0,OSD1, VID0, VID1\n");
                 printf("enable: enables window\n");
                 printf("disable: disables window\n");
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
         printf("Please enter window id to blank (OSD0,OSD1,VID0,VID1)\n");
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


if (strcmp(argv[2],"disable") == 0){ 
                           if (ioctl(fd,FBIO_ENABLE_DISABLE_WIN,0) < 0){
                           printf(" Unable to disable %s\n",FB_DEVICE);
                           return -1;
                           }

                           printf("Disabled %s\n",FB_DEVICE);
                           }

  else if (strcmp(argv[2],"enable") == 0){
                                // Enable OSD1 Display using FBIOBLANK.  

                                if (ioctl(fd,FBIO_ENABLE_DISABLE_WIN,1) < 0){
                                printf(" Unable to enable %s\n",FB_DEVICE);
                                return -1;
                                }

                                printf("Enabled %s\n",FB_DEVICE);
                                }
 else printf("Please enter enable or disable\n");

  return 0;
}

