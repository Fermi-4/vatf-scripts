/*
 * Filename: bitmapblend.c
 * 
 * Function: Verify FBIO_ENABLE_DISABLE_ATTRIBUTE_WIN.
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

char *OSD1_DEVICE;

void printdev()
{
  if (OSD1_DEVICE == NULL){
                           printf("No OSD1 device\n");
                          }
                          else{
                               printf("OSD1 Device string is %s \n",OSD1_DEVICE);
                               }
}

int main(int argc,char *argv[])
{

  FILE * fp;
  int c = 0;
  char d1[5];
  char d2[50];

  int fd = 0; //Handle for device file descriptors
 
 if ( argc != 2 ){
                 printf ("Format:\t endisattrwin [enable,disable]\n");
                 printf("enable: enables attribute window\n");
                 printf("disable: disables attribute window\n");
                 return -1;
                 }

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
      // There need not be an else to this as OSD1 is always initialized.
  }

  //printdev();
  fd = open(OSD1_DEVICE,O_RDWR);

  if (fd < 0){
   printf("Unable to open OSD1\n");
   return -1;
   }


 if (strcmp(argv[1],"disable") == 0){ //Disable attribute function on OSD1
                           if (ioctl(fd,FBIO_ENABLE_DISABLE_ATTRIBUTE_WIN,0) < 0){
                           printf(" Unable to disable attribute window for %s\n",OSD1_DEVICE);
                           return -1;
                           }

                           printf("Disabled %s\n",OSD1_DEVICE);
                           }

  else if (strcmp(argv[1],"enable") == 0){// Enable attribute function on OSD1
                                if (ioctl(fd,FBIO_ENABLE_DISABLE_ATTRIBUTE_WIN,1) < 0){
                                printf(" Unable to enable attribute window for %s\n",OSD1_DEVICE);
                                return -1;
                                }

                                printf("Enabled %s\n",OSD1_DEVICE);
                                }
 else printf("Please enter enable or disable\n");

  return 0;
} 
