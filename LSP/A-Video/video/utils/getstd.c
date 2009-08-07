/*
 * Filename: getstd.c
 *
 *Reads sysfs to determine the current display standard set up.Replaces FBIOGETSTD
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


char *mode = NULL;
char *output = NULL;


/*
 *Reads sysfs to determine the current display standard set up.Replaces FBIOGETSTD
 */

int main()
{

  FILE * fp1;
  FILE * fp2;
  int c;
  char d1[10];
  char d2[10];
 
  fp1 = fopen("/sys/class/davinci_display/ch0/mode","r");
  fp2 = fopen("/sys/class/davinci_display/ch0/output","r");


  if (fp1 == NULL){
           printf(" Unable to read mode\n");
                 }  
  if (fp2 == NULL){
         printf(" Unable to read output\n");
                 }  

  while( fscanf(fp1,"%s",d1) != EOF)
  {
      mode = malloc(10);
      strcpy(mode,d1);
  }

  while( fscanf(fp2,"%s",d2) != EOF)
  {
      output = malloc(10);
      strcpy(output,d2);
  }
 

  printf("Mode:%s\toutput:%s\n",mode,output);

  return 0;
}
