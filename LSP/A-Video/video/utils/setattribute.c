/*
 * Filename: setattribute.c
 * 
 * Function: verify IOCTL FBIO_SETATTRIBUTE
 *
 * 
 * The blend factor will be set across the area entire area covered by OSD1.
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
char *OSD1_DEVICE = NULL;

void printdev()
{
  if (OSD1_DEVICE == NULL){
                           printf("No OSD1 device\n");
                          }
                          else{
                               printf("OSD1 Device string is %s \n",OSD1_DEVICE);
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

} 

int main(int argc,char *argv[])
{

  FILE * fp;
  int c = 0;
  char d1[5];
  char d2[50];
  struct fb_var_screeninfo osdVarInfo;
  struct fb_fix_screeninfo osdFixInfo;
  struct fb_fillrect frect;
  int fd = 0; //Handle for device file descriptors
 
  fp = fopen("/proc/fb","r");

  if (fp == NULL){
                  printf(" Unable to open /proc/fb for reading\n");
                 }  

  while( fscanf(fp,"%s",d1) != EOF)
  {
   fscanf(fp,"%s",d2);

    if (strcmp(d2,"dm_osd1_fb") == 0){
      OSD1_DEVICE = malloc(10);
      strcpy(OSD1_DEVICE,"/dev/fb/");
      strcat(OSD1_DEVICE,d1);
      break;
      }
      // There need not be an else to this as OSD1 is alwaus initialized.
  }

  //printdev();
  fd = open(OSD1_DEVICE,O_RDWR);

  if (fd < 0){
   printf("Unable to open OSD1\n");
   return -1;
   }

  //printf("Opened OSD1 successfully\n");

 if (ioctl(fd,FBIOGET_VSCREENINFO,&osdVarInfo) < 0){
         printf("FBIOGET_VSCREENINFO Failed\n");
         return -1;
         }

 // Check if OSD1 is in Attribute mode.

  if (osdVarInfo.nonstd != 1){
       printf("OSD1 is not in attribute mode\n");
       return -1;
       }

 //printVarInfo(&osdVarInfo,"OSD1");  

 if (ioctl(fd,FBIOGET_FSCREENINFO,&osdFixInfo) < 0){
         printf("FBIOGET_FSCREENINFO Failed\n");
         return -1;
         }


 if (argc == 1){
               printf("Please enter blend factor from 0 to 7\n");
               printf("\t\t blend [0-7]\n");
               return -1;
               }

 if (argc > 2){
              printf("Too many arguments\n");
              printf("\t\t blend [0-7]\n");
              return -1;
              }

 frect.dx=0;
 frect.dy=0;
 frect.width=osdVarInfo.xres;
 frect.height=osdVarInfo.yres;
 frect.color=atoi(argv[1]);

 if ((frect.color < 0) || (frect.color > 7)){
                              printf("Please enter blend factor from 0 to 7\n");
               printf("\t\t blend [0-7]\n");
               return -1;
               }


 if(ioctl(fd,FBIO_SETATTRIBUTE, &frect) < 0){
     perror("FBIO_SETATTRIBUTE Failed: \n");
     return -1;
     }

 printf("FBIO_SETATTRIBUTE successfull\n");

 
 
  return 0;
}
