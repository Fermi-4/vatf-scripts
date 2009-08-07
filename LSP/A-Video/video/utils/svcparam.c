/*
 * Filename: svcparam.c
 * 
 * Function: Verify FBIO_SET_VIDEO_CONFIG_PARAMS.
 *
 * 
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

  vpbe_video_config_params_t vid_conf_params;

  int fd = 0; //Handle for device file descriptors

  if ((argc == 1) || ( argc > 2 )){
                 printf ("Format:\t svcparam [window] \n");
                 printf(" Valid Window values are OSD0,OSD1,VID0, VID1\n");
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
         printf("Please enter window id to set (OSD0,OSD1,VID0,VID1)\n");
         return -1;
        }

  }

  fd = open(FB_DEVICE,O_RDWR);

  if (fd < 0){
   printf("Unable to open %s\n",FB_DEVICE);
   return -1;
   }


  printf("Enter Chroma order: 0 for cb cr and 1 for cr cb\n");
  scanf("%d",&vid_conf_params.cb_cr_order);
  printf("\nEnter Horizontal expansions status: 0 for 1/1, 1 for 9/8, 2 for 3/2\n");
  scanf("%d",&vid_conf_params.exp_info.horizontal);
  printf("\nEnter Vertical expansions status: 0 for 1/1, 1 for 6/5\n");
  scanf("%d",&vid_conf_params.exp_info.vertical);
  

 
  if(ioctl(fd,FBIO_SET_VIDEO_CONFIG_PARAMS,&vid_conf_params) < 0 ){
                perror("FBIO_SET_VIDEO_CONFIG_PARAMS fAILED:");
                return -1;
               }
  close(fd);

  return -1;

}
