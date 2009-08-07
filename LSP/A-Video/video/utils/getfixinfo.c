/*
 * Filename: getfixinfo.c
 * 
 * Function: Verify FBIOGET_FSCREENINFO.
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

void printFixInfo(struct fb_fix_screeninfo *fixInfo, char *device)
{

 printf("Identification string: %s\n",fixInfo->id);
 printf("start memory: %ul\n",fixInfo->smem_start);
 printf("Length of frame buffer mem:%d\n",fixInfo->smem_len);
 printf("type:%d\n",fixInfo->type);
 printf("type_aux:%d\n",fixInfo->type_aux);
 printf("visual:%d\n",fixInfo->visual);
 printf("xpanstep:%d\n",fixInfo->xpanstep);
 printf("ypanstep:%d\n",fixInfo->ypanstep);
 printf("ywrapstep:%d\n",fixInfo->ywrapstep);
 printf(" Line length:%d\n",fixInfo->line_length);
 printf("Memory map start:%ul\n",fixInfo->mmio_start);
 printf("Length of memory map:%d\n",fixInfo->mmio_len);
 printf("Chip ID:%d\n", fixInfo->accel);
}
int main(int argc, char *argv[])
{

  FILE * fp;
  int c;
  char d1[5];
  char d2[50];
  struct fb_fix_screeninfo fix;

  int fd = 0; //Handle for device file descriptors

  if ( argc != 2 ){
                 printf ("Format:\t getfixinfo [window]\n");
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
  

  fd = open(FB_DEVICE,O_RDWR);

  if (fd < 0){
   printf("Unable to open OSD1\n");
   return -1;
   }

  printf("Opened %s successfully\n", FB_DEVICE);

  // 1. Get the fscreen info using FBIOGET_FSCREENINFO.

  printf("Getting fix screen info\n");
 printf("================================================\n");

  if (ioctl(fd,FBIOGET_FSCREENINFO,&fix) < 0){
         printf("FBIOGET_VSCREENINFO Failed\n");
         return -1;
         }

  printFixInfo(&fix,FB_DEVICE);  

  return 0;
}
