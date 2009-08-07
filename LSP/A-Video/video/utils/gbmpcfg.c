/*
 * Filename: gbmpcfg.c
 * 
 * Function: Verify FBIO_GET_BITMAP_CONFIG_PARAMS.
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

  int fd = 0; //Handle for device file descriptors
  
  vpbe_bitmap_config_params_t bitmapConfigParams;

  if ( argc != 2 ){
                 printf ("Format:\t gbmpcfg [window]\n");
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

  if(ioctl(fd,FBIO_GET_BITMAP_CONFIG_PARAMS,&bitmapConfigParams) < 0){
            perror("FBIO_GET_BITMAP_CONFIG_PARAMS Failed:\n");
            return -1;
            }

  printf("Attenuation_enable is %d\n",bitmapConfigParams.attenuation_enable);
  printf("Clut is %d\n",bitmapConfigParams.clut_select);
  printf("clut_idx is %d\n",bitmapConfigParams.clut_idx);
  printf("FBIO_GET_BITMAP_CONFIG_PARAMS successfull\n\n");

 return 0;

} 
