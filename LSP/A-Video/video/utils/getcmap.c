/*
 * Filename: getcmap.c
 * 
 * Function: Verify FBIOGETCMAP.
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
  struct fb_cmap cmap;

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


 cmap.start = 0;
 cmap.len=256;
 cmap.red=R;
 cmap.green=G;
 cmap.blue=B;
 cmap.transp=NULL;
  
 if(ioctl(fd,FBIOGETCMAP,&cmap) < 0){
                 perror("FBIOGETCMAP Failed:\n");
                 return -1;
                 }

 if(cmap.start < 0){
            printf("RAM CLUT not set up\n");
           return -1;
            }

 printf("RAM CLUT length is %ld\n",cmap.len);

 for (c = 0; c < cmap.len; c++,cmap.red++,cmap.green++,cmap.blue++){
      printf("R:%x,G:%x,B:%x\n",*cmap.red,*cmap.green,*cmap.blue);
      }

 return 0;

}



 

 

 
