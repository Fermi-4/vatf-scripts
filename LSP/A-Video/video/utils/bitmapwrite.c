/*
 * Filename: bitmapwrite.c
 * 
 * Function: Write a bitmap file to the OSD window.
 *
 * The test file consists of data equivalent to 704x480 resolution.
 * To write to larger resolution, pad the header file test_8a.h.
 * Also make sure in line 178, you advance src by 720
*/

/* Header files */
#include <stdio.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <getopt.h>
#include <sys/types.h>
#include <linux/fb.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <video/davincifb_ioctl.h>
#include <sys/select.h>
#include "test_8.h"



/* True of false enumeration */
#define TRUE            1
#define FALSE           0

// Do not Initialise these anymore. They should be updated only if the device exists.
char *FB_DEVICE = NULL;
char *osd_display[2] = { NULL, NULL };
struct fb_fix_screeninfo osd_fixInfo;
struct fb_var_screeninfo osd_varInfo;

char *src;
char *dst;

int osd_size;
int i;
int y;

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

  if ( argc != 2 ){
                 printf ("Format:\t bitmapwrite [window]\n");
                 printf(" Valid Window values are OSD0,OSD1\n");
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
         printf("Please enter window id to write the bitmap file (OSD0,OSD1)\n");
         return -1;
        }

  }

  printdev();


  fd = open(FB_DEVICE,O_RDWR);

  // Do a get fix screen info here.

if (ioctl(fd, FBIOGET_FSCREENINFO, &osd_fixInfo) < 0) {
                printf("\nFailed FBIOGET_FSCREENINFO osd0");
                return -1;
        }


 // Get var screen info.
if (ioctl(fd, FBIOGET_VSCREENINFO, &osd_varInfo) < 0) {
                printf("\nFailed FBIOGET_VSCREENINFO");
                return -1;
        }


  osd_size =
    osd_fixInfo.line_length * osd_varInfo.yres;
  /* Map the osd0 buffers to user space */
  osd_display[0] = (char *) mmap (NULL,
                                   osd_size * 2,
                                   PROT_READ | PROT_WRITE,
                                   MAP_SHARED, fd, 0);

  if (osd_display[0] == MAP_FAILED)
    {
      printf ("\nFailed mmap on %s", FB_DEVICE);
      return -1;
    }

  for (i = 0; i < 1; i++)
    {
      osd_display[i + 1] = osd_display[i] + osd_size;
      printf ("Display buffer %d mapped to address %#lx\n", i + 1,
              (unsigned long) osd_display[i + 1]);
    }

   dst = osd_display[0];

          src = (char *)test_8;
          for (y = 0; y < osd_varInfo.yres; y++)
          {
                  memcpy (dst, src, 720);
                  dst += osd_fixInfo.line_length;
                  src += (704);
          }


   osd_varInfo.yoffset = 0;

  /* Swap the working buffer for the displayed buffer */
  if (ioctl (fd, FBIOPAN_DISPLAY, &osd_varInfo) < -1)
    {
      printf ("FlipbitmapBuffers:FBIOPAN_DISPLAY\n");
      printf ("\n");
      return -1;
    }

 return 0;

}
