/*
 * Filename: setbitmapbf.c
 * 
 * Function: Verify IOCTL FBIO_SET_BITMAP_BLEND_FACTOR.
 *
 * 
 * The blend factor will be set across the area entire area covered by the bitmap window.
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
 vpbe_bitmap_blend_params_t bitmapblend;
  
  int fd = 0; //Handle for device file descriptors

  if ( argc != 4 ){
                 printf ("Format:\t bitmapblend [window] [blend-factor] [enable_colorkey]\n");
                 printf(" Valid Window values are OSD0,OSD1\n");
                 printf("blend-factor:0-7\n");
                 printf("enable_colorkey:0->disable, 1->enable\n");
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

   else {
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

  bitmapblend.bf = (unsigned )(atoi(argv[2]));

  bitmapblend.enable_colorkeying = (unsigned )(atoi(argv[3]));

  //If colorkeying is enabled, the color key determines the transparency factor of OSD window.
  // It has been observed that if the colorkey is greater than 0, the OSD window is opaque.
  // i.e. does not blend.
  if ( bitmapblend.enable_colorkeying == 1 ) {
           printf("Enter Color Key:");
           scanf("%u",&bitmapblend.colorkey);
           printf("colorkey is %u\n",bitmapblend.colorkey);
           printf("\n");
           }

  if(ioctl(fd,FBIO_SET_BITMAP_BLEND_FACTOR,&bitmapblend) < 0){
            perror("FBIO_SET_BITMAP_BLEND_FACTOR:\n");
            return -1;
            }

  printf("FBIO_SET_BITMAP_BLEND_FACTOR success\n");

 return 0;

}


