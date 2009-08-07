/*
 * Contains utilities for Display driver.
 */

/*
 *  Header Files 
 */

#include "fbdev_display.h"
#include "test_8.h"
#include "osd16.h"

/* 
 * Initializing struct variables
 */

struct vpbe_test_info test_data = {
 //Variables for initializing VID0 to NTSC YUV422
  NTSCWIDTH,
  NTSCHEIGHT,
  YUV_422_BPP,
  VID0_VMODE,

 // Variables for initializing VID1 to NTSC YUV422
  NTSCWIDTH,
  NTSCHEIGHT,
  YUV_422_BPP,
  VID1_VMODE,

 // Variables for initializing OSD0 to NTSC, RGB565
  NTSCWIDTH,
  NTSCHEIGHT,
  RGB_565_BPP,
  OSD0_VMODE,

 // Variables for initializing OSD1 to NTSC, Attribute mode
  NTSCWIDTH,
  NTSCHEIGHT,
  BITMAP_BPP_4,
  OSD1_VMODE,


 // Variables to Initialize all windows to (0,0)
  OSD0_XPOS,
  OSD0_YPOS,
  OSD1_XPOS,
  OSD1_YPOS,
  VID0_XPOS,
  VID0_YPOS,
  VID1_XPOS,
  VID1_YPOS,

};

/*
 * Initializing Non static globals
 */

int svideoinput = FALSE;
int stress_test = 0;
int startLoopCnt = 100;
int fd_vid0 = 0, fd_vid1 = 0, fd_osd0 = 0, fd_osd1 = 0;
int NTSCDISPLAY = FALSE;
int PALDISPLAY = FALSE;
int LCDDISPLAY = FALSE;
int osd0Win = FALSE;
int vid0Win = FALSE;
int vid1Win = FALSE; 

char *vid0_display[VIDEO_NUM_BUFS] = { NULL, NULL, NULL };
char *vid1_display[VIDEO_NUM_BUFS] = { NULL, NULL, NULL };
char *osd0_display[OSD_NUM_BUFS] = { NULL, NULL };
char *osd1_display[OSD_NUM_BUFS] = { NULL, NULL };
char *OSD0_DEVICE = NULL; 
char *OSD1_DEVICE = NULL;
char *FBVID0_DEVICE = NULL ;
char *FBVID1_DEVICE = NULL;

/*
 * Non-static function definitions
 */
int FlipBitmapBuffers(int, int);
int FlipVideoBuffers(int, int);

/* 
 * static function definitions
 */
static int DisplayFrame (char, void *);
static int Displaybitmaposd0(void);

/*
 * Initializing existing frame buffer device nodes by reading /proc/fb entries
 */
void initDevNodes()
{

  FILE * fp;
  char d1[5];
  char d2[50];
 
  fp = fopen("/proc/fb","r");

  if (fp == NULL){
                  printf(" Unable to open /proc/fb for reading\n");
                 }  

  while( fscanf(fp,"%s",d1) != EOF)
  {
   fscanf(fp,"%s",d2);

    if (strcmp(d2,"dm_osd0_fb") == 0){
      //osd0 exists. variable d1 stores the corresponding framebuffer device # as a string.
      OSD0_DEVICE = malloc(10);
      strcpy(OSD0_DEVICE,"/dev/fb/");
      strcat(OSD0_DEVICE,d1);
      //OSD0 device should be /dev/fb/"d1". Similarly for the other devices.
      }
    if (strcmp(d2,"dm_osd1_fb") == 0){
      OSD1_DEVICE = malloc(10);
      strcpy(OSD1_DEVICE,"/dev/fb/");
      strcat(OSD1_DEVICE,d1);
      }
    if (strcmp(d2,"dm_vid0_fb") == 0){
      FBVID0_DEVICE = malloc(10);
      strcpy(FBVID0_DEVICE,"/dev/fb/");
      strcat(FBVID0_DEVICE,d1);
      }
    if (strcmp(d2,"dm_vid1_fb") == 0){
      FBVID1_DEVICE = malloc(10);
      strcpy(FBVID1_DEVICE,"/dev/fb/");
      strcat(FBVID1_DEVICE,d1);
      }
  }

 return;
}

/*
 * Gets the current display standard by reading sysfs entry
 */
int getstd()
{

  FILE * fp1;
  FILE * fp2;
  char d1[10];
  char d2[10];
  char *mode = NULL;
  char *output = NULL;
 
  fp1 = fopen("/sys/class/davinci_display/ch0/mode","r");
  fp2 = fopen("/sys/class/davinci_display/ch0/output","r");


  if (fp1 == NULL){
           printf(" Unable to open /sys/class/davinci_display/ch0/mode for reading\n");
                 }  
  if (fp2 == NULL){
         printf(" Unable to open /sys/class/davinci_display/ch0/output for reading\n");
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

 printf("mode:%s\toutput:%s\n",mode,output); 

 if (strcmp(mode,"NTSC") == 0){
            printf("mode is NTSC\n");
            NTSCDISPLAY = TRUE;
            }
 else if (strcmp(mode,"PAL") == 0){
            printf("mode is PAL\n");
            PALDISPLAY = TRUE;
            }
 else if (strcmp(mode,"640x480") == 0){
            printf("mode is LCD\n");
            LCDDISPLAY = TRUE;
            }

return 0;

}

/*
 * Initializes window test settings based on display settings by reading sysfs
 */
int
initDisplay()
{

    struct vpbe_test_info *ptr_test_data = &test_data;

  getstd();

  if (NTSCDISPLAY){ // Set test_data for NTSC Here

                     printf("Setting NTSC DISPLAY\n");

                     ptr_test_data->vid0_width = NTSCWIDTH;
                     ptr_test_data->vid0_height = NTSCHEIGHT;
                     ptr_test_data->vid0_bpp = YUV_422_BPP;
                     ptr_test_data->vid0_vmode = FB_VMODE_INTERLACED;

                     ptr_test_data->vid1_width = NTSCWIDTH;
                     ptr_test_data->vid1_height = NTSCHEIGHT;
                     ptr_test_data->vid1_bpp = YUV_422_BPP;
                     ptr_test_data->vid1_vmode = FB_VMODE_INTERLACED;

                     ptr_test_data->osd0_width = 150;
                     ptr_test_data->osd0_height = 150;
                     ptr_test_data->osd0_bpp = RGB_565_BPP;
                     ptr_test_data->osd0_vmode = FB_VMODE_INTERLACED;
                     ptr_test_data->osd0_xpos = 280;
                     ptr_test_data->osd0_ypos = 160;
                    

                     ptr_test_data->osd1_width = NTSCWIDTH;
                     ptr_test_data->osd1_height = NTSCHEIGHT;
                     ptr_test_data->osd1_bpp = BITMAP_BPP_4;
                     ptr_test_data->osd1_vmode = FB_VMODE_INTERLACED;
  }

  else if (PALDISPLAY) {// Set test_data for PAL here
                     // Initialize all members in test_data for PAL.
                     printf("Setting PAL DISPLAY\n");

                     ptr_test_data->vid0_width = PALWIDTH;
                     ptr_test_data->vid0_height = PALHEIGHT;
                     ptr_test_data->vid0_bpp = YUV_422_BPP;
                     ptr_test_data->vid0_vmode = FB_VMODE_INTERLACED;

                     ptr_test_data->vid1_width = PALWIDTH;
                     ptr_test_data->vid1_height = PALHEIGHT;
                     ptr_test_data->vid1_bpp = YUV_422_BPP;
                     ptr_test_data->vid1_vmode = FB_VMODE_INTERLACED;

                     ptr_test_data->osd0_width = 150;
                     ptr_test_data->osd0_height = 150;
                     ptr_test_data->osd0_bpp = RGB_565_BPP;
                     ptr_test_data->osd0_vmode = FB_VMODE_INTERLACED;
                     ptr_test_data->osd0_xpos = 280;
                     ptr_test_data->osd0_ypos = 160;

                     ptr_test_data->osd1_width = PALWIDTH;
                     ptr_test_data->osd1_height = PALHEIGHT;
                     ptr_test_data->osd1_bpp = BITMAP_BPP_4;
                     ptr_test_data->osd1_vmode = FB_VMODE_INTERLACED;
  }

  else if (LCDDISPLAY){// Set test_data for LCD here
                     // Initialize all members in test_data for LCD.
                     printf("Setting LCD DISPLAY\n");
                     ptr_test_data->vid0_width = LCDWIDTH;
                     ptr_test_data->vid0_height = LCDHEIGHT;
                     ptr_test_data->vid0_bpp = YUV_422_BPP;
                     ptr_test_data->vid0_vmode = FB_VMODE_NONINTERLACED;

                     ptr_test_data->vid1_width = LCDWIDTH;
                     ptr_test_data->vid1_height = LCDHEIGHT;
                     ptr_test_data->vid1_bpp = YUV_422_BPP;
                     ptr_test_data->vid1_vmode = FB_VMODE_NONINTERLACED;

                     ptr_test_data->osd0_width = 150;
                     ptr_test_data->osd0_height = 150;
                     ptr_test_data->osd0_bpp = RGB_565_BPP;
                     ptr_test_data->osd0_vmode = FB_VMODE_NONINTERLACED;
		     ptr_test_data->osd0_xpos = 280;
		     ptr_test_data->osd0_ypos = 160;

                     ptr_test_data->osd1_width = LCDWIDTH;
                     ptr_test_data->osd1_height = LCDHEIGHT;
                     ptr_test_data->osd1_bpp = BITMAP_BPP_4;
                     ptr_test_data->osd1_vmode = FB_VMODE_NONINTERLACED;
  }
  else {
         printf("Display not Supported. Exiting Loopback\n");
         return -1;
  }

return 1;

}
/*
 * Starts the capture and display loop. The capture process writes the frames
 * into the capture buffer and is copied into the display buffer before being
 * displayed to the appropriate video window
 */

int
StartLoop (void)
{
  struct v4l2_buffer buf;
  char *ptrPlanar = NULL;
  int dummy;

  ptrPlanar = (char *) calloc (1, nWidthFinal * nHeightFinal * 2);

  while (1)
    {
      fd_set fds;
      struct timeval tv; 
      int r;

      if (!stress_test)
	{
	  startLoopCnt--;
	  if (startLoopCnt == 0)
	    {
	      break;
	    }
	}

      FD_ZERO (&fds);
      FD_SET (fdCapture, &fds);

      /* Timeout. */
      tv.tv_sec = 2;
      tv.tv_usec = 0;


      r = select (fdCapture + 1, &fds, NULL, NULL, &tv);

      if (-1 == r)
	{
	  if (EINTR == errno)
	    continue;

	  printf ("StartCameraCaputre:select\n");
	  return -1;
	}

      if (0 == r)
	{
	  continue;
	}

      CLEAR (buf);
      buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      buf.memory = V4L2_MEMORY_MMAP;
      //printf("Debug 6............\n");
      /*determine ready buffer */
      if (-1 == ioctl (fdCapture, VIDIOC_DQBUF, &buf))
	{
	  if (EAGAIN == errno)
	    continue;
	  printf ("StartCameraCaputre:ioctl:VIDIOC_DQBUF\n");
	  return -1;
	}

    if(vid0Win) {
      DisplayFrame (VID0, buffers[buf.index].start); 
         }
 
    if(vid1Win){
      DisplayFrame (VID1, buffers[buf.index].start);
         }

    if(osd0Win)
      Displaybitmaposd0();
      /* Wait for vertical sync */

   if(vid0Win){
              if (ioctl (fd_vid0, FBIO_WAITFORVSYNC, &dummy) < -1)
                 {
	          printf ("Failed FBIO_WAITFORVSYNC\n");
	          return -1;
                 }
               }

   if(vid1Win){
              if (ioctl (fd_vid1, FBIO_WAITFORVSYNC, &dummy) < -1)
                 {
	          printf ("Failed FBIO_WAITFORVSYNC\n");
	          return -1;
                 }
               }

      if (-1 == ioctl (fdCapture, VIDIOC_QBUF, &buf))
	{
	  printf ("StartCameraCaputre:ioctl:VIDIOC_QBUF\n");
	}
    }

 return 1;
}
/*
 * Display images to the OSD0 window for RGB565 mode or 8 bits per pixel bitmap mode.
 */
static int
Displaybitmaposd0()
{
  static unsigned int nDisplayIdx = 1;
  static unsigned int nWorkingIndex = 0;
  int y;
  char *dst;
  char *src;
  int fd;
  struct fb_var_screeninfo vInfo;

  dst = osd0_display[nWorkingIndex];
  if (dst == NULL)
	  return -1;
  fd = fd_osd0;

  //Check If OSD in RGB565 mode using FBIOGET_VSCREENINFO
  if (ioctl (fd, FBIOGET_VSCREENINFO, &vInfo) < -1)
    {
      printf ("DisplaybitmapOSD0:FBIOGET_VSCREENINFO\n");
      printf ("\n");
      return -1;
    }

 if(vInfo.bits_per_pixel == RGB_565_BPP)
  {
	  src = (char *) rgb16;
	  for (y = 0; y < test_data.osd0_height; y++)
	  {
		  memcpy (dst, src, (test_data.osd0_width * 2));
		  dst += osd0_fixInfo.line_length;
            //Advancing the source by 704 bcos of test file size restrictions
            // If testfile is padded to 720x480, we can advance source by 720
		  src += (704 * 2);
	  }
  }
 else if(vInfo.bits_per_pixel == BITMAP_BPP_8)
  {
	  src = (char *)test_8;
	  for (y = 0; y < test_data.osd0_height; y++)
	  {
		  memcpy (dst, src, (test_data.osd0_width));
		  dst += osd0_fixInfo.line_length;
		  src += (704);
	  }
  }

  //Removing support for bitmap windows. Might enable this later.
  //else //1/2/4 bit bitmap and attribute 
	//  memset (dst, test_data.osd0_coloridx, osd0_size);

  nWorkingIndex = (nWorkingIndex + 1) % OSD_NUM_BUFS;
  nDisplayIdx = (nDisplayIdx + 1) % OSD_NUM_BUFS;

  if ((FlipBitmapBuffers (fd, nDisplayIdx)) < 0)
    return -1;
  return 0;

}

/*
 * Display the YUV frames to the appropriate window
 */
static int
DisplayFrame (char id, void *ptrBuffer)
{
  static unsigned int nDisplayIdx = 0;
  static unsigned int nWorkingIndex = 1;
  int y;
  int yres;
  char *dst;
  char *src;
  int fd;
  unsigned int line_length;	

  if (id == VID0)
    {
      yres = test_data.vid0_height;
      dst = vid0_display[nWorkingIndex];
      if (dst == NULL)
	return -1;
      fd = fd_vid0;
      line_length = vid0_fixInfo.line_length;
    }
  if (id == VID1)
    {
      yres = test_data.vid1_height;
      dst = vid1_display[nWorkingIndex];
      if (dst == NULL)
	return -1;
      fd = fd_vid1;
      line_length = vid1_fixInfo.line_length;
    }
  src = ptrBuffer;
  for (y = 0; y < yres; y++)
    {
      memcpy (dst, src, (line_length));
      dst += line_length;
      src += line_length;
    }
  nWorkingIndex = (nWorkingIndex + 1) % VIDEO_NUM_BUFS;
  nDisplayIdx = (nDisplayIdx + 1) % VIDEO_NUM_BUFS;
  if ((FlipVideoBuffers (fd, nDisplayIdx)) < 0)
    return -1;
  return 0;
}

/*
 * Transfer the info from the display buffer to the actual OSD window
 */

int
FlipBitmapBuffers (int fd, int nBufIndex)
{
  struct fb_var_screeninfo vInfo;

  if (ioctl (fd, FBIOGET_VSCREENINFO, &vInfo) < -1)
    {
      printf ("FlipbitmapBuffers:FBIOGET_VSCREENINFO\n");
      printf ("\n");
      return -1;
    }

  vInfo.yoffset = vInfo.yres * nBufIndex;
  /* Swap the working buffer for the displayed buffer */
  if (ioctl (fd, FBIOPAN_DISPLAY, &vInfo) < -1)
    {
      printf ("FlipbitmapBuffers:FBIOPAN_DISPLAY\n");
      printf ("\n");
      return -1;
    }

  return 0;
}

/*
 * Transfer the frame from the display buffer to the actual video window.
 */
int
FlipVideoBuffers (int fd, int nBufIndex)
{
  struct fb_var_screeninfo vInfo;
  if (ioctl (fd, FBIOGET_VSCREENINFO, &vInfo) < -1)
    {
      printf ("FlipVideoBuffers:FBIOGET_VSCREENINFO\n");
      printf ("\n");
      return -1;
    }

  vInfo.yoffset = vInfo.yres * nBufIndex;
  /* Swap the working buffer for the displayed buffer */
  if (ioctl (fd, FBIOPAN_DISPLAY, &vInfo) < -1)
    {
      printf ("FlipVideoBuffers:FBIOPAN_DISPLAY\n");
      printf ("\n");
      return -1;
    }

  return 0;
}

/*
 * Memory map the video buffers to user space
 */
int
mmap_vid (int fd ,char fbdev)
{
  int i, j;

  switch (fbdev){

 case VID1:
  vid1_size =
    vid1_fixInfo.line_length * vid1_varInfo.yres;
  /* Map the video1 buffers to user space */
  vid1_display[0] = (char *) mmap (NULL,
				   vid1_size * VIDEO_NUM_BUFS,
				   PROT_READ | PROT_WRITE,
				   MAP_SHARED, fd, 0);

  if (vid1_display[0] == MAP_FAILED)
    {
      printf ("\nFailed mmap on VID1 device\n");
      return FAILURE;
    }

  for (i = 0; i < VIDEO_NUM_BUFS - 1; i++)
    {
      vid1_display[i + 1] = vid1_display[i] + vid1_size;
      printf ("VID1 Display buffer %d mapped to address %#lx\n", i + 1,
	      (unsigned long) vid1_display[i + 1]);
    }

  break;

 case VID0:
  vid0_size =
    vid0_fixInfo.line_length * vid0_varInfo.yres;
  /* Map the video0 buffers to user space */
  vid0_display[0] = (char *) mmap (NULL,
				   vid0_size * VIDEO_NUM_BUFS,
				   PROT_READ | PROT_WRITE,
				   MAP_SHARED, fd, 0);

  if (vid0_display[0] == MAP_FAILED)
    {
      printf ("\nFailed mmap on VID0 device\n");
      return FAILURE;
    }

  for (j = 0; j < VIDEO_NUM_BUFS - 1; j++)
    {
      vid0_display[j + 1] = vid0_display[j] + vid0_size;
      printf ("VID0 Display buffer %d mapped to address %#lx\n", j + 1,
	      (unsigned long) vid0_display[j + 1]);
    }

  break;

  default:

     break;
    }
  return SUCCESS;
}


/*
 * Memory map the OSD window to user space
 */

int
mmap_osd (int fd)
{
  int i;
  osd0_size =
    osd0_fixInfo.line_length * osd0_varInfo.yres;
  /* Map the osd0 buffers to user space */
  osd0_display[0] = (char *) mmap (NULL,
				   osd0_size * OSD_NUM_BUFS,
				   PROT_READ | PROT_WRITE,
				   MAP_SHARED, fd, 0);

  if (osd0_display[0] == MAP_FAILED)
    {
      //printf ("\nFailed mmap on %s", OSD0_DEVICE);
      printf ("\nFailed mmap on OSD device\n");
      return FAILURE;
    }

  for (i = 0; i < OSD_NUM_BUFS - 1; i++)
    {
      osd0_display[i + 1] = osd0_display[i] + osd0_size;
      printf ("OSD0 Display buffer %d mapped to address %#lx\n", i + 1,
	      (unsigned long) osd0_display[i + 1]);
    }
return 1;
}

/*
 * Initializes OSD window with the test data for OSD window.
 * Currently will set up OSD window in RGB565 mode
 */
int init_osd_device(int fd, struct fb_var_screeninfo *pvarInfo)
{
	vpbe_window_position_t pos;

        // Disable OSD window before setting it up.
        if (ioctl(fd,FBIOBLANK,1) < 0){
                     printf("FBIOBLANK Disable Failed\n");
                     return FAILURE;       
                     }
	if (ioctl(fd, FBIOGET_FSCREENINFO, &osd0_fixInfo) < 0) {
		printf("\nFailed FBIOGET_FSCREENINFO osd0");
		return FAILURE;
	}

	/* Get Existing var_screeninfo */
	if (ioctl(fd, FBIOGET_VSCREENINFO, pvarInfo) < 0) {
		printf("\nFailed FBIOGET_VSCREENINFO");
		return FAILURE;
	}

	/* Modify the resolution and bpp as required */
	pvarInfo->xres = test_data.osd0_width;
        pvarInfo->yres = test_data.osd0_height;
	pvarInfo->bits_per_pixel = test_data.osd0_bpp;
        pvarInfo->yres_virtual = (test_data.osd0_height*OSD_NUM_BUFS);
        pvarInfo->vmode = test_data.osd0_vmode;

        if((LCDDISPLAY) && (test_data.osd0_width == LCDWIDTH)){
           //Set the xres_virtual as 720 for LCD.
             pvarInfo->xres_virtual = NTSCWIDTH;}
            

       else pvarInfo->xres_virtual = test_data.osd0_width; 

	/*Set window parameters */
	if (ioctl(fd, FBIOPUT_VSCREENINFO, pvarInfo) < 0) {
		printf("\nFailed FBIOPUT_VSCREENINFO");
		return FAILURE;
	}

	/* Set window position */
	pos.xpos = test_data.osd0_xpos;
	pos.ypos = test_data.osd0_ypos;

	if (ioctl(fd, FBIO_SETPOS, &pos) < 0) {
		perror("\nFailed  FBIO_SETPOS:\n");
		return FAILURE;
	}

       // Enable OSD window
       if (ioctl(fd,FBIOBLANK,0) < 0){
                     printf("FBIOBLANK Enable Failed\n");
                     return FAILURE;
                     }

	return SUCCESS;
}

/* 
 * Initialize VID windows with window test data.
 */
int init_vid_device(int fd, struct fb_var_screeninfo *pvarInfo, char fbdev)
{
	vpbe_window_position_t pos;

  switch (fbdev) {
     case VID0:
	if (ioctl(fd, FBIOGET_FSCREENINFO, &vid0_fixInfo) < 0) {
		printf("\nFailed FBIOGET_FSCREENINFO vid1");
		return FAILURE;
	}

	/* Get Existing var_screeninfo */
	if (ioctl(fd, FBIOGET_VSCREENINFO, pvarInfo) < 0) {
		printf("\nFailed FBIOGET_VSCREENINFO");
		return FAILURE;
	}

	prev_vid0_var = *pvarInfo;
	/* Modify the resolution and bpp as required */
	pvarInfo->xres = test_data.vid0_width;
	pvarInfo->yres = test_data.vid0_height;
	pvarInfo->bits_per_pixel = test_data.vid0_bpp;
        pvarInfo->yres_virtual = (test_data.vid0_height*VIDEO_NUM_BUFS);
        pvarInfo->vmode = test_data.vid0_vmode;
  
        if (LCDDISPLAY){
        // Treat LCD display separately as the all our inputs 720 pixels per line
        // and our display is 640 pixels per line
	pvarInfo->xres_virtual = NTSCWIDTH;
         }
        else pvarInfo->xres_virtual = test_data.vid0_width;        
 

	/* Set window parameters */
	if (ioctl(fd, FBIOPUT_VSCREENINFO, pvarInfo) < 0) {
		printf("\nFailed FBIOPUT_VSCREENINFO");
		return FAILURE;
	}
	
	/* Set window position */
	pos.xpos = test_data.vid0_xpos;
	pos.ypos = test_data.vid0_ypos;

	if (ioctl(fd, FBIO_SETPOS, &pos) < 0) {
		printf("\nFailed  FBIO_SETPOS\n");
                printf("error no is:%d\n", errno);
		return FAILURE;
	}

         break;

    case VID1:
	if (ioctl(fd, FBIOGET_FSCREENINFO, &vid1_fixInfo) < 0) {
		printf("\nFailed FBIOGET_FSCREENINFO vid1");
		return FAILURE;
	}

	/* Get Existing var_screeninfo */
	if (ioctl(fd, FBIOGET_VSCREENINFO, pvarInfo) < 0) {
		printf("\nFailed FBIOGET_VSCREENINFO");
		return FAILURE;
	}

	prev_vid0_var = *pvarInfo;
	/* Modify the resolution and bpp as required */
	pvarInfo->xres = test_data.vid1_width;
	pvarInfo->yres = test_data.vid1_height;
	pvarInfo->bits_per_pixel = test_data.vid1_bpp;
        pvarInfo->yres_virtual = (test_data.vid1_height*VIDEO_NUM_BUFS);
        pvarInfo->vmode = test_data.vid1_vmode;
  
        if (LCDDISPLAY){
        // Treat LCD display separately as the all our inputs 720 pixels per line
        // and our display is 640 pixels per line
	pvarInfo->xres_virtual = NTSCWIDTH;
         }
        else pvarInfo->xres_virtual = test_data.vid1_width;        

	/* Set window parameters */
	if (ioctl(fd, FBIOPUT_VSCREENINFO, pvarInfo) < 0) {
		printf("\nFailed FBIOPUT_VSCREENINFO\n");
		return FAILURE;
	}
	
	/* Set window position */
	pos.xpos = test_data.vid1_xpos;
	pos.ypos = test_data.vid1_ypos;

	if (ioctl(fd, FBIO_SETPOS, &pos) < 0) {
		printf("\nFailed  FBIO_SETPOS\n");
                printf("error no is:%d\n", errno);
		return FAILURE;
	}

        break;

        default: 
         
               break;
       } // End of switch

	return SUCCESS;
}

/*
 * Initializes and memory map window according to user inputs
 */

int
init_mmap_win()
{

 if (vid0Win){
             // Initialize vid0
             printf("Initializing VID0\n");
             if ((init_vid_device(fd_vid0,&vid0_varInfo,VID0)) < 0)
                {
                 perror("Failed to Initialize VID0: \n");
                 return -1;
                }
             printf("mmap VID0\n");
              // if vid has been initialise, then we can map it.
            if (mmap_vid (fd_vid0,VID0) == FAILURE)
                return FAILURE;
               }
if (vid1Win){
             // Initialize vid1
             printf("Initializing VID1\n");
             if ((init_vid_device(fd_vid1,&vid1_varInfo,VID1)) < 0)
                {
                 perror("Failed to Initialize VID1: \n");
                 return -1;
                }
             printf("mmap VID1\n");
              // if vid has been initialise, then we can map it.
            if (mmap_vid (fd_vid1,VID1) == FAILURE)
                return FAILURE;
               }
if (osd0Win){
             // Initialize osd0
             printf("Initializing OSD0\n");
             if ((init_osd_device(fd_osd0,&osd0_varInfo)) < 0)
                {
                 perror("Failed to Initialize OSD0: \n");
                 return -1;
                }
             printf("mmap OSD0\n");
              // if vid has been initialise, then we can map it.
            if (mmap_osd (fd_osd0) == FAILURE)
                return FAILURE;
               }
 return SUCCESS;

}

/*
 * Unmap video window and OSD window buffers and close the devices
 */
int 
unmap_and_close()
{

 if(vid0Win){
            if (munmap (vid0_display[0], vid0_size * VIDEO_NUM_BUFS) == -1)
	        {
	         printf ("\nFailed munmap on %s", FBVID1_DEVICE);
	         return FAILURE;
	        }
                if(close(fd_vid0) < 0)
                  {
                   perror("Failed to Close VID0: \n");
                   return FAILURE;
                  }
             }
 if(vid1Win){
            if (munmap (vid1_display[0], vid1_size * VIDEO_NUM_BUFS) == -1)
	      {
	       printf ("\nFailed munmap on %s", FBVID1_DEVICE);
	       return FAILURE;
	      }
              if(close(fd_vid1) < 0)
                  {
                   perror("Failed to Close VID1: \n");
                   return FAILURE;
                  }
             }

 if(osd0Win){
            if (munmap (osd0_display[0], osd0_size * OSD_NUM_BUFS) == -1)
	    {
	     printf ("\nFailed munmap on %s", OSD0_DEVICE);
	     return FAILURE;
	    }
            if(close(fd_osd0) < 0)
              {
              perror("Failed to close OSD0: \n");
              return FAILURE;
              }
           }

 return SUCCESS;
}

void usage()
{

printf("Usage: fbloop -[OPTION] [VALUE]\n");
printf("\n\t\t -s : Use Svideoinput instead of composite");
printf("\n\t\t -c : Run the loopback test 'c' times (-1 for stress test)\n\n");
printf("\t\t      Default c=100 times \n");
printf("\n\t\t -v : 0 -> VID0, 1-> VID1, 2 -> VID0 & VID1\n");
printf("\n\t\t -o : Run loopback on OSD0\n");
printf("\n\t\t -h : Display this help text\n");
}
/******************************************************************************
 * parseArgs
 ******************************************************************************/
int parseArgs(int argc, char *argv[])
{
    const char shortOptions[] = "s:c:v:oh";
    const struct option longOptions[] = {
        {"svideo", required_argument, NULL, 's'},
        {"count", required_argument, NULL, 'f'},
        {"video", required_argument, NULL, 'd'},
        {"osd", no_argument, NULL, 'o'},
        {"help", no_argument, NULL, 'h'},
        {0, 0, 0, 0}
    };
    int     index;
    int     c,lpcnt;
    int     vidid;
   
    
    for (;;) {
        c = getopt_long(argc, argv, shortOptions, longOptions, &index);

        printf("getopt returns %d\n", c);
        if (c == -1) {
            break; //breaks out of the for loop.
        }
           switch (c) {
           case 's': svideoinput = TRUE; // Not tested at this point in the new release.
                     break;

           case 'c': lpcnt = atoi(optarg);
                     if (lpcnt == -1) {
                                      stress_test = 1;
                                      }
                      else {
                            startLoopCnt = lpcnt;
                           }
                     break;

                     
           case 'v': vidid = atoi(optarg);
                     

             printf("vidid is %d\n",vidid);
                     if (vidid == 0){//Open VID0 for loopback
                                     printf("opening VID0\n");
                                     fd_vid0 = (open(FBVID0_DEVICE,O_RDWR));
                                     if (fd_vid0 < 0){
                                         printf("Unable to open VID%d window\n",vidid);
                                         return -1;
                                         }
                                      vid0Win = TRUE;
                                     }
                     else if  (vidid == 1){//Open VID1 for loopback
                                     printf("opening VID1\n");
                                     fd_vid1 = (open(FBVID1_DEVICE,O_RDWR));
                                     if (fd_vid1 < 0){
                                         printf("Unable to open VID%d window\n",vidid);
                                         return -1;
                                         }
                                      vid1Win = TRUE;
                                     }

                    else if (vidid == 2){//Open VID0 and VID1 for Loopback
                                   printf("opening VID0\n");
                                     fd_vid0 = (open(FBVID0_DEVICE,O_RDWR));
                                     if (fd_vid0 < 0){
                                         printf("Unable to open VID0 window\n");
                                         return -1;
                                         }
                                   printf("opening VID1\n");
                                     fd_vid1 = (open(FBVID1_DEVICE,O_RDWR));
                                     if (fd_vid1 < 0){
                                         printf("Unable to open VID1 window\n");
                                         return -1;
                                         }
                                   vid0Win = TRUE;
                                   vid1Win = TRUE;
                                 } 

                     break;

          case 'o': 
                    // Initialize OSD0 window as RGB565.
              fd_osd0 = open(OSD0_DEVICE,O_RDWR); 

               if (fd_osd0 < 0){
                             printf("Unable to open osd window\n");
                             return -1;
                             }
              printf("Opened OSD0 window successfully\n");
                osd0Win = TRUE;
                break;

           case 'h':
                   usage();
                   return -1;

           default: printf("Reached default case\n");
                    usage();
                    return -1;
        }

    }
        return 0;
}
