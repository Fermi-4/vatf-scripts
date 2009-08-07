/*
 * Filename: wingetinfo.c
 * 
 * Function: Verify FBIOGET_VSCREENINFO.
 *
 * Gets the Variable screen information for the window. 
 * 
*/
/* Header files */
#include <stdio.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
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
                           printf("No FB device\n");
                          }
                          else{
                               printf("FB Device string is %s \n",FB_DEVICE);
                               }
}

void printVarInfo(struct fb_var_screeninfo *varInfo, char *device)
{

 printf("Var Info for %s\n",device);
 printf("xres:%d\n",varInfo->xres);
 printf("yres:%d\n",varInfo->yres);
 printf("xres_virtual:%d\n",varInfo->xres_virtual);
 printf("yres_virtual:%d\n",varInfo->yres_virtual);
 printf("xoffset:%d\n",varInfo->xoffset);
 printf("yoffset:%d\n",varInfo->yoffset);
 printf("bits per pixel:%d\n",varInfo->bits_per_pixel);
 printf("grayscale:%d\n",varInfo->grayscale);
 printf("nonstd:%d\n",varInfo->nonstd);
 printf("activate:%d\n",varInfo->activate);
 printf("height in mm:%d\n", varInfo->height);
 printf("width in mm:%d\n", varInfo->width);
 printf("red.length is:%d\n",varInfo->red.length);
 printf("green.length is:%d\n",varInfo->green.length);
 printf("blue.length is:%d\n",varInfo->blue.length);
 printf("pixclock is:%d\n",varInfo->pixclock);
 printf("left_margin is :%d\n",varInfo->left_margin);
 printf("right_margin is:%d\n",varInfo->right_margin);
 printf("upper_margin is:%d\n",varInfo->upper_margin);
 printf("lower_margin is:%d\n",varInfo->lower_margin);
 printf("hsync_len is:%d\n",varInfo->hsync_len);
 printf("vsync_len is:%d\n",varInfo->vsync_len);
 printf("vmode is:%d\n",varInfo->vmode);
} 

int main(int argc, char *argv[])
{

  FILE * fp;
  int c;
  char d1[5];
  char d2[50];
  struct fb_var_screeninfo var;

  int fd = 0; //Handle for device file descriptors

  if ( argc != 2 ){
                 printf ("Format:\t wingetinfo [window]\n");
                 printf(" Valid Window values are OSD0,OSD1, VID0, VID1\n");
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
         printf("Please enter correct window id (OSD0,OSD1,VID0,VID1)\n");
         return -1;
        }

  }
  printdev();


  fd = open(FB_DEVICE,O_RDWR);

  if (fd < 0){
   printf("Unable to open OSD1\n");
   return -1;
   }

  printf("Opened %s successfully\n", FB_DEVICE);

  // 1. Get the vscreen info using FBIOGET_VSCREENINFO.

  printf("Getting Vscreen info\n");
 printf("================================================\n");

  if (ioctl(fd,FBIOGET_VSCREENINFO,&var) < 0){
         printf("FBIOGET_VSCREENINFO Failed\n");
         return -1;
         }

  printVarInfo(&var,FB_DEVICE);  

  return 0;
}
