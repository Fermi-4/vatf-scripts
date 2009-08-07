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
#include <sys/types.h>
#include <sys/time.h>
#include <asm/types.h>          /* for videodev2.h */
#include <time.h>
#include <media/davinci/davinci_vpfe.h> /*kernel header file, prefix path comes from makefile */
#include <video/davincifb_ioctl.h>
#include <linux/videodev2.h>
#include <sys/select.h>
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

  int fd = 0; //Handle for device file descriptors
  struct fb_cmap cmap;

  char ram_clut[256][3];

  u_int16_t R[256];
  u_int16_t G[256];
  u_int16_t B[256];

  if ( argc != 2 ){
                 printf ("Format:\t getcmap [window]\n");
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
   else{
        printf("Please enter window id (OSD0,OSD1)\n");
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


  //Fill the palette here

  for(c = 0; c < 256; c++) {
          ram_clut[c][0]=0x4b;
          ram_clut[c][1]=0xe6;
          ram_clut[c][2]=0xAA;
          }

 printf("Calling the IOCTL\n");

 if(ioctl(fd,FBIO_SET_BITMAP_WIN_RAM_CLUT,ram_clut)){
                 perror("FBIO_SET_BITMAP_WIN_RAM_CLUT Failed:\n");
                 return -1;
                 }

 printf("FBIOPUTCMAP suceeded\n");

  return 0;

}

