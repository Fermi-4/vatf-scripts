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
#define NUM_OF_VID_BUFFERS 3
#define TWO_BPP 2

char *FB_DEVICE = NULL;
char *vid_display[NUM_OF_VID_BUFFERS] = { NULL, NULL,NULL};
struct fb_fix_screeninfo vid_fixInfo;
struct fb_var_screeninfo vid_varInfo;

char *src;
char *dst;

int vid_size;
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
  FILE * imageFile;
  int c;
  char d1[5];
  char d2[50];

  int fd = 0; //Handle for device file descriptors

  int workingIndex = 0;
  int dummy;
  struct timeval tv1, tv2;
  int captFrmCnt;
  int noOfTestFrames, len;
  long double interFrameTime;
  long double avgFrameTime;

  if ( argc != 4 ){
                 printf ("Format:\t vidperf [window] [filename] [# of test frames]\n");
                 printf(" Valid Window values are VID0, VID1\n");
		 printf("Fbdev_Basic Failed \n");
                 return -1;
                 }

  fp = fopen("/proc/fb","r");

  if (fp == NULL){
                  printf(" Unable to open /proc/fb for reading\n");
		  printf("Fbdev_Basic Failed \n");
                 }  

   
  while( fscanf(fp,"%s",d1) != EOF)
  {
   fscanf(fp,"%s",d2);
    
   if (strcmp(argv[1],"VID0") == 0){
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
         printf("Please enter window id (VID0,VID1)\n");
	 printf("Fbdev_Basic Failed \n");
         return -1;
        }

  }


  noOfTestFrames = atoi(argv[3]);
  printdev();


  fd = open(FB_DEVICE,O_RDWR);


  //imageFile opened.

  // Do a get fix screen info here.

if (ioctl(fd, FBIOGET_FSCREENINFO, &vid_fixInfo) < 0) {
                printf("\nFailed FBIOGET_FSCREENINFO vid0");
		printf("Fbdev_Basic Failed \n");
                return -1;
        }


 // Get var screen info.
if (ioctl(fd, FBIOGET_VSCREENINFO, &vid_varInfo) < 0) {
                printf("\nFailed FBIOGET_VSCREENINFO");
		printf("Fbdev_Basic Failed \n");
                return -1;
        }

 printf("the line_length = %d, yres = %d \n",vid_fixInfo.line_length, vid_varInfo.yres);

  vid_size =
    vid_fixInfo.line_length * vid_varInfo.yres;
    //vid_size = 1440*480;
  /* Map the vid0 buffers to user space */
  vid_display[0] = (char *) mmap (NULL,
                                   vid_size * NUM_OF_VID_BUFFERS,
                                   PROT_READ | PROT_WRITE,
                                   MAP_SHARED, fd, 0);

  if (vid_display[0] == MAP_FAILED)
    {
      printf ("\nFailed mmap on %s", FB_DEVICE);
      printf("Fbdev_Basic Failed \n");	
      return -1;
    }

  for (i = 0; i < NUM_OF_VID_BUFFERS; i++)
    {
      vid_display[i + 1] = vid_display[i] + vid_size;
      printf ("Display buffer %d mapped to address %#lx\n", i + 1,
              (unsigned long) vid_display[i + 1]);
      //printf("Fbdev_Basic Failed \n");
    }
  if(vid_varInfo.xres > 720)
  {	
    len = vid_varInfo.xres - 720;
  }
  else
  {
    len = 720 - vid_varInfo.xres;
  }
  //while (1)
  while (captFrmCnt < noOfTestFrames)
  { 

   interFrameTime = 0.0;

   dst = vid_display[workingIndex];
   src = vid_display[workingIndex];	
  
  gettimeofday(&tv1, NULL);
  
  imageFile = fopen(argv[2],"rb");

  if (imageFile == NULL){
       perror("File open Failed:\n");
       printf("Fbdev_Basic Failed \n");
       return -1;
       }
   /*printf("vid_varInfo.xres = %d \n",vid_varInfo.xres);
   fread(src,(720*1440*2),1,imageFile);
	for (i=0; i < vid_varInfo.yres; i++)
	{
	  	printf("i = %d \n", i);
		memcpy (dst,src,(vid_varInfo.xres*2));
		dst += (vid_varInfo.xres*2);
		src += 720 * 2;
		
      	}

   fread(dst,(vid_varInfo.xres*vid_varInfo.yres_virtual*2),1,imageFile);
   //fread(dst,(720*480*2),1,imageFile);               
  fclose(imageFile);*/
  for(i = 0; i < vid_varInfo.yres ; i++)
  {
  	//printf("vid_varInfo.xres = %d \n", vid_varInfo.xres);
//	printf("720*(i+1)*2 = %d \n", 720*(i+1)*2);
	fread(src,(vid_fixInfo.line_length),1,imageFile);
	fseek(imageFile, ((720*(i+1))*2), SEEK_SET);
//	printf("src = %d \n", src);
	src += ((vid_fixInfo.line_length ));
  }
   vid_varInfo.yoffset = vid_varInfo.yres * workingIndex;

  /* Swap the working buffer for the displayed buffer */
  if (ioctl (fd, FBIOPAN_DISPLAY, &vid_varInfo) < -1)
    {
      printf ("FlipbitmapBuffers:FBIOPAN_DISPLAY\n");
      printf ("\n");
      printf("Fbdev_Basic Failed \n");
      return -1;
    }

  
  workingIndex = (workingIndex + 1) % NUM_OF_VID_BUFFERS;


  if (ioctl (fd, FBIO_WAITFORVSYNC, &dummy) < -1)
      {
              printf ("Failed FBIO_WAITFORVSYNC\n");
	      printf("Fbdev_Basic Failed \n");	
              return -1;
      }

  gettimeofday(&tv2, NULL);

  //Convert the seconds portion into microseconds and add it to the microsecond portion of timeval.
  interFrameTime =  (long double)((tv2.tv_sec - tv1.tv_sec) * 1000000 
                                          + (tv2.tv_usec - tv1.tv_usec));

  avgFrameTime = avgFrameTime + interFrameTime; 

  captFrmCnt++;

 }

 // Print the avgFrameTime outside the while loop before exiting.
 printf("# of frames sampled:%d\n",captFrmCnt);
 printf("Average Frame Interval:%lf usec\n",(long double)(avgFrameTime/captFrmCnt));
 printf("Frames Per second is:%lf FPS\n", (long double)(1000000/(avgFrameTime/captFrmCnt)));
 printf("Fbdev_Basic Passed \n");
 
 return 0;

}
