/*
 * Filename: setblinkint.c
 * 
 * Function: Verify FBIO_SET_BLINK_INTERVAL.
 * Sets the blink interval of OSD0 window.
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
 
  vpbe_blink_option_t blinkInfo; 

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

  printf("Opened OSD1 successfully\n");

 if ((argc == 1) || (argc > 2)){
              printf("Usage: setblinkint [blink-interval]\n");
              printf("Usage: [blink-interval:0-3]\n");
              printf("Usage: 'setblinkint disable' to disable blinking\n");
              return -1;
              }

 if(strcmp("disable",argv[1]) == 0){
                   blinkInfo.blinking = 0;
                   blinkInfo.interval = 0;
                   } 
 else {
          blinkInfo.blinking = VPBE_ENABLE;
          blinkInfo.interval = atoi(argv[1]);
      }
  

 if(ioctl(fd,FBIO_SET_BLINK_INTERVAL,&blinkInfo) < 0){
                  perror("FBIO_SET_BLINK_INTERVAL Failed:");
                  printf("Error #:%d",errno);
                  }

 /*printf("Blinking is %d\n", blinkInfo.blinking);
 
 if(blinkInfo.blinking == 1){
      printf("Blink interval is set to %d\n",blinkInfo.interval);
      }*/

 close(fd);
 
  return 0;
}
