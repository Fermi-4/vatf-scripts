
/*******************************************************************************
**+--------------------------------------------------------------------------+**
**|                            ****                                          |**
**|                            ****                                          |**
**|                            ******o***                                    |**
**|                      ********_///_****                                   |**
**|                      ***** /_//_/ ****                                   |**
**|                       ** ** (__/ ****                                    |**
**|                           *********                                      |**
**|                            ****                                          |**
**|                            ***                                           |**
**|                                                                          |**
**|         Copyright (c) 1998-2005 Texas Instruments Incorporated           |**
**|                        ALL RIGHTS RESERVED                               |**
**|                                                                          |**
**| Permission is hereby granted to licensees of Texas Instruments           |**
**| Incorporated (TI) products to use this computer program for the sole     |**
**| purpose of implementing a licensee product based on TI products.         |**
**| No other rights to reproduce, use, or disseminate this computer          |**
**| program, whether in part or in whole, are granted.                       |**
**|                                                                          |**
**| TI makes no representation or warranties with respect to the             |**
**| performance of this computer program, and specifically disclaims         |**
**| any responsibility for any damages, special or consequential,            |**
**| connected with the use of this program.                                  |**
**|                                                                          |**
**+--------------------------------------------------------------------------+**
*******************************************************************************/

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <sys/mman.h>
//#include <davincifb.h>
#include "st_common.h"
#include "st_linuxdevio.h"
#include "st_vpbe_interface.h"
#include <video/davincifb.h>
//#define NTSC

#ifdef NTSC
#define HORIZONTAL 720
#define VERTICAL 480
#endif /*  */
extern char fb_dev_names[][20];
extern unsigned long yuv_image_720x480[];
extern int fbfd[];
extern struct fb_var_screeninfo vinfo_vidx[];
struct fb_fix_screeninfo finfo_vidx[4];
struct fb_image image_vidx[4];
struct fb_fillrect frect;
struct zoom_params zoom_parameters[4];
char *mmap_vidx[4];
static long int screensize_vidx = 0;

int test_vpbe_interface_get_standard(framebuffer_to_open)
{
	int retval;
	long value=0;
    retval= ioctl (fbfd[framebuffer_to_open], FBIO_GETSTD, &value);
    printTerminalf("IOCTL (FBIO_GETSTD) value= %u \n",value);
	if (131073==value)
	{
		 printTerminalf("STANDARD:: PAL - COMPOSITE\n");
	}
	if (131074==value)
	{
		 printTerminalf("STANDARD:: PAL - S-VIDEO\n");
	}
	if (131075==value)
	{
		 printTerminalf("STANDARD:: PAL - COMPONENT\n");
	}
	if(65537==value)
	{
		 printTerminalf("STANDARD:: NTSC - COMPOSITE\n");
	}

	if(65538==value)
	{
		 printTerminalf("STANDARD:: NTSC - S-VIDEO\n");
	}
	if(65539==value)
	{
		 printTerminalf("STANDARD:: NTSC - COMPONENT\n");
	}
return(retval);
}

int test_vpbe_interface_set_zoom(framebuffer_to_open,window_ID,zoom_hvalue,zoom_vvalue)
{
 
  int retval;
  zoom_parameters[framebuffer_to_open].window_id=window_ID;
  zoom_parameters[framebuffer_to_open].zoom_h=zoom_hvalue;
  zoom_parameters[framebuffer_to_open].zoom_v=zoom_vvalue;
//	vinfo_vidx[framebuffer_to_open].reserved[3]=zoom_value;

 if ((retval=(ioctl(fbfd[framebuffer_to_open],FBIO_SETZOOM,&zoom_parameters[framebuffer_to_open])))<0 )
 {
	printTerminalf("retval =%d\n",retval);
        return retval;
 }
return 0;

}
int test_vpbe_interface_mmap_vidx(int framebuffer_to_open)
{

      // Get variable screen information
      if ((ioctl (fbfd[framebuffer_to_open], FBIOGET_VSCREENINFO, &vinfo_vidx[framebuffer_to_open])) < 0)
	{
	  return -1;
	}

      // Figure out the size of the screen in bytes
      screensize_vidx =
	vinfo_vidx[framebuffer_to_open].xres * vinfo_vidx[framebuffer_to_open].yres *
	vinfo_vidx[framebuffer_to_open].bits_per_pixel / 8;
	printTerminalf("screensize(NTSC=691200 , PAL=829440)= %ld\n",screensize_vidx);
	// For OSD(Double Buffering)	
	if( 0 == framebuffer_to_open || 2 == framebuffer_to_open)
	{
         // Map the device to memory
           mmap_vidx[framebuffer_to_open] =
	   (char *) mmap (0, screensize_vidx * 2, PROT_READ | PROT_WRITE,MAP_SHARED, fbfd[framebuffer_to_open], 0);
           if ((int) mmap_vidx[framebuffer_to_open] < 0)

 		{
		  printTerminalf ("MMap error: %d\n", (int) mmap_vidx[framebuffer_to_open]);
	  	  return ((int) mmap_vidx[framebuffer_to_open]);
		}
	}
         //For VID0/VID1(Triple Buffering)
	else if( 1 == framebuffer_to_open || 3 == framebuffer_to_open )
	{
		
         // Map the device to memory
           mmap_vidx[framebuffer_to_open] =
	   (char *) mmap (0, screensize_vidx * 3, PROT_READ | PROT_WRITE,MAP_SHARED, fbfd[framebuffer_to_open], 0);
           if ((int) mmap_vidx[framebuffer_to_open] < 0)

 		{
		  printTerminalf ("MMap error: %d\n", (int) mmap_vidx[framebuffer_to_open]);
	  	  return ((int) mmap_vidx[framebuffer_to_open]);
	        }
	}
            return 0;
}


int test_vpbe_interface_play_video(int framebuffer_to_open)
{
	int i;
  	FILE *pFile=0;
	int ret=0;
  	int retval;
	char *buffer_frame1,*buffer_frame2;
	// frame_size(NTSC) = 720 x 480 x 2= 0xa8c00;
         long frame_size=0xa8c00;
	
	//frame size(PAL)=720 x 576 x 2 =0xca800
       // long frame_size=0xca800;
        
        //buffer1 memory allocation
        buffer_frame1 = (char *) malloc (frame_size);
        if (buffer_frame1 == NULL)
	{
	 	 return -1;
	}
          
        //buffer2 memory allocation
        buffer_frame2 = (char *) malloc (frame_size);
        if (buffer_frame2 == NULL)
	{
		 return -2;
	}
	//for OSD0
 	 retval =
    		ioctl (fbfd[framebuffer_to_open], FBIOGET_VSCREENINFO, &vinfo_vidx[framebuffer_to_open]);
	  if (retval < 0)

    		{
      			return -9;
    		}
 
	if( 0 == framebuffer_to_open)

	{

//Commented on 8/March	if ((pFile = fopen ("rgb_movie.rgb", "r")) < 0)
  		if ((pFile = fopen ("rgb_movie1.rgb", "r")) < 0)
    		{
      			 return -3;
    		}

//Commented on 8/march	for (i=0; i<9 ;i++)
		for (i=0; i<42 ;i++)
		{
	 
		
       			if ( (fread (buffer_frame1, 1, frame_size, pFile)) < 0)
			{
	  			return -4;
			}
      	 		memcpy (mmap_vidx[framebuffer_to_open], buffer_frame1, frame_size);
  			
			vinfo_vidx[framebuffer_to_open].yoffset =  vinfo_vidx[framebuffer_to_open].yres * 0 ;
  			
			retval = ioctl(fbfd[framebuffer_to_open],FBIOPAN_DISPLAY,&vinfo_vidx[framebuffer_to_open]);
  			if (retval < 0)

    			{
			      return -7;
    			}
			
 			
                        if ((ret = ioctl (fbfd[framebuffer_to_open], FBIO_WAITFORVSYNC, 0)) )
			{	

                        	printf("ioctl FBIO_WAITFORVSYNC failed\n");

                                return -8;

                        }            

//Commented on 8/March	sleep(1);
			       	           
			if ( (fread (buffer_frame2, 1, frame_size, pFile)) < 0)
			{
	  			return -5;
			}
			
			memcpy ((void *)mmap_vidx[framebuffer_to_open]+0xa8c00, buffer_frame2, 0xa8c00);
  			vinfo_vidx[framebuffer_to_open].yoffset =  vinfo_vidx[framebuffer_to_open].yres * 1 ;
			
  			retval = ioctl(fbfd[framebuffer_to_open],FBIOPAN_DISPLAY,&vinfo_vidx[framebuffer_to_open]);
  			if (retval < 0)

    			{
			      return -7;
    			}
			
                        if ((ret = ioctl (fbfd[framebuffer_to_open], FBIO_WAITFORVSYNC, 0)) )
			{	

                        	printf("ioctl FBIO_WAITFORVSYNC failed\n");

                                return -8;

                        }            
//Commented on 8/March		sleep(1);
	        	  
		}	
	}
	// for VID0/VID1
	else if( 1 == framebuffer_to_open || 3 == framebuffer_to_open )
	{

	//For NTSC Open capture_720_480

//Commented(7/march)	
  	//	if ((pFile = fopen ("1000_fr_ntsc_uyvy.yuv", "r")) < 0)
                if ((pFile = fopen ("capture_720_480.yuv", "r")) < 0)
  		if ((pFile = fopen ("capture_720_480.yuv", "r")) < 0)
    		{
      			 return -3;
    		}


	//For PAL Open capture_720_576
  	//	if ((pFile = fopen ("capture_720_576.yuv", "r")) < 0)
    		{
      			 return -3;
    		}
	
//Commented (7/march)
//		for ( i=0 ; i<500 ; i++ )
		for ( i=0 ; i<5 ; i++ )

		{
	 	
       			if ( (fread (buffer_frame1, 1, frame_size, pFile)) < 0)
			{
	  			return -4;
			}
      	 		memcpy (mmap_vidx[framebuffer_to_open], buffer_frame1, frame_size);
  			
			vinfo_vidx[framebuffer_to_open].yoffset =  vinfo_vidx[framebuffer_to_open].yres * 0 ;
  			
			retval = ioctl(fbfd[framebuffer_to_open],FBIOPAN_DISPLAY,&vinfo_vidx[framebuffer_to_open]);
  			if (retval < 0)

    			{
			      return -7;
    			}
			
 			
                        if ((ret = ioctl (fbfd[framebuffer_to_open], FBIO_WAITFORVSYNC, 0)) )
			{	

                        	printf("ioctl FBIO_WAITFORVSYNC failed\n");

                                return -8;

                        }            

		//Commented (7/March)	sleep(1);
			       	           
			if ( (fread (buffer_frame2, 1, frame_size, pFile)) < 0)
			{
	  			return -5;
			}
		// For NTSC	
			memcpy ((void *)mmap_vidx[framebuffer_to_open]+0xa8c00, buffer_frame2, 0xa8c00);
		//For PAL
		//	memcpy ((void *)mmap_vidx[framebuffer_to_open]+0xca800, buffer_frame2, 0xca800);
  			vinfo_vidx[framebuffer_to_open].yoffset =  vinfo_vidx[framebuffer_to_open].yres * 1 ;
			
  			retval = ioctl(fbfd[framebuffer_to_open],FBIOPAN_DISPLAY,&vinfo_vidx[framebuffer_to_open]);
  			if (retval < 0)

    			{
			      return -7;
    			}
			
                        if ((ret = ioctl (fbfd[framebuffer_to_open], FBIO_WAITFORVSYNC, 0)) )
			{	

                        	printf("ioctl FBIO_WAITFORVSYNC failed\n");

                                return -8;

                        }            
	//Commented(7/March)		sleep(1);
		}	
	}

      fclose (pFile);

      free (buffer_frame1);
      free (buffer_frame2);
      //memory unmapping.
      if ( (munmap (mmap_vidx[framebuffer_to_open], screensize_vidx)) < 0)
	{
	  return -6;
	}
  return 0;
}

		
		


int test_vpbe_interface_create_blend_ioctl(int framebuffer_to_open,int blend_value)
{

 int retval;
// struct fb_fillrect frect;
 frect.dx=0;
 frect.dy=0;
 frect.width=720;
 frect.height=576;
 frect.color=blend_value;
 
printTerminalf("blend =%d\n",frect.color);
 if ((retval=(ioctl(fbfd[framebuffer_to_open], FBIO_SETATTRIBUTE, &frect)))<0 )
 {
	printTerminalf("retval =%d\n",retval);
        return retval;
 }
return 0;

}


int
test_vpbe_interface_relocate_vidx (int framebuffer)
{
  int retval;
  unsigned long xpos,ypos;
 // move x position of VID0 to 80(top left)(new position=(80,0))
 xpos=80;
  retval =
    ioctl (fbfd[framebuffer], FBIO_SETPOSX,xpos);
  if (retval < 0)

    {
          printTerminalf("FBIO_SETPOSX Failed....\n");
  	  return (retval);
    }

  else

    {
      sleep (1);
    }

 //move x position of VID0 to 320(top right)(new position=(320,0))

  xpos = 320;
  retval =
    ioctl (fbfd[framebuffer], FBIO_SETPOSX,xpos);
  if (retval < 0)

    {
      return (retval);
    }

  else

    {
      sleep (1);
    }

  //move y position of VID0 to 180(bottom right)(new position=(320,320))

	ypos=100;
  retval =
    ioctl (fbfd[framebuffer], FBIO_SETPOSY,ypos );
  if (retval < 0)
    {
      return (retval);
    }

  else
    {
      sleep (1);
    }

  //move x position of VID0 to 80(bottom left)(new position=(80,180))

  xpos = 80;
  retval =
    ioctl (fbfd[framebuffer], FBIO_SETPOSX,xpos );
  if (retval < 0)

    {
      return (retval);
    }

  else

    {
      sleep (1);
    }

  //move y position of VID0 to 30(top left)(new position=(80,30))

  ypos = 30;
  retval =
    ioctl (fbfd[framebuffer], FBIO_SETPOSY,ypos );
  if (retval < 0)

    {
      return (retval);
    }

  else

    {
      sleep (1);
    }

  //move x position of VID0 to 0(original position)
  xpos = 0;
  retval =
    ioctl (fbfd[framebuffer], FBIO_SETPOSX,xpos );
  if (retval < 0)

    {
      return (retval);
    }

  else

    {
      sleep (1);
    }
  //move y position of VID0 to 0(original position)
  ypos = 0;
  retval =
    ioctl (fbfd[framebuffer], FBIO_SETPOSY,ypos );
  if (retval < 0)

    {
      return (retval);
    }

  else

    {
      sleep (1);
    }
  return 0;
}

int
test_vpbe_interface_create_blend(int framebuffer_to_open, int blend_value)
{
  unsigned int blend_values[8] = { 0x00,0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77 };
  int j, k, fd, ret;
  FILE *pFile;
  char *memory_pointer;
  long lsize;
  fd = open ("filename_toCreate", O_CREAT | O_RDWR, 0755);
  if (fd < 0)

    {
      return -1;
    }
  for (j = 0; j < VERTICAL; j++)

    {
      for (k = 0; k < HORIZONTAL; k++)

	{
	  ret = write (fd, &blend_values[blend_value], 1);
	  if (ret < 0)

	    {
	      return -2;
	    }
	}
    }
  close (fd);
  if ((pFile = fopen ("filename_toCreate", "r")) < 0)

    {
      return -3;
    }

  // obtain file size (as lsize).
  if ((fseek (pFile, 0, SEEK_END)) < 0)

    {
      return -4;
    }
  lsize = ftell (pFile);
  if (lsize < 0)

    {
      return -5;
    }
  rewind (pFile);
  //Allocate memory for lsize.
	memory_pointer = (char *) malloc (lsize+32);
//	printTerminalf("size of File =%d\n",lsize);
  if (memory_pointer == NULL)
  	  {
      		return -6;
    	}
  // copy the file into the buffer.
  if(fread (memory_pointer,1,lsize,pFile)<0)
	{
		return -8;
	}
  memcpy(mmap_vidx[framebuffer_to_open], memory_pointer, lsize);
  fclose(pFile);
/*if i free than error::Alignment trap for all the blend values except 7 and 6*/
     //free the memory_pointer
//	free(memory_pointer);
//        printTerminalf("freeing memory success\n");
   if ((munmap (mmap_vidx[framebuffer_to_open], screensize_vidx)) < 0)
	{
	  return -7;
	}
  return 0;
}

int
test_vpbe_interface_closeDevice (int framebuffer_to_close)
{
  int retval;
  retval = close (fbfd[framebuffer_to_close]);
  return (retval);
}

int
test_vpbe_interface_stress_test_osd (int framebuffer_to_open)
{
  int retval;
  unsigned int i;
  int j, k, l;
  FILE *pFile;
  long lsize;
/*  int framebuffer=2,ret;
  int blend_value=5;	
  ret=test_vpbe_interface_open_fb (framebuffer);
  if(ret <0) 
  {
	return (ret);	
  }
  ret = test_vpbe_interface_create_blend(framebuffer,blend_value); 	
  if(ret<0)
  {
 	return(ret);
  }*/
//      char filename[55];
  char *buffer;
  for (i = 0; i < 9000; i++)

    {
      retval = test_vpbe_interface_open_fb (framebuffer_to_open);
      if (retval < 0)

	{
	  return (retval);
	  break;
	}
      retval = test_vpbe_interface_mmap_vidx(framebuffer_to_open);
      if (retval < 0)

	{
	  return (retval);
	  break;
	}
      if ((pFile = fopen ("flower_720_480.raw", "r")) < 0)

	{
	  return ((int) pFile);
	}

      // obtain file size (as lsize).

      if ((j = (fseek (pFile, 0, SEEK_END))) < 0)

	{
	  return (j);
	}
      lsize = ftell (pFile);
      
	if (lsize < 0)

	{
	  return lsize;
	}

      rewind (pFile);

      //buffer memory allocation
      buffer = (char *) malloc ( lsize);
      if (buffer == NULL)

	{
	  return -6;
	}
     // Read the opened file into the buffer
      if ((k = (fread (buffer, 1,lsize, pFile))) < 0)

	{
	  return k;
	}
      memcpy (mmap_vidx[framebuffer_to_open], buffer, lsize);
      printTerminalf("image displayed successfully : %d\n ",i);
	fclose (pFile);
      free (buffer);

      printTerminalf("buffer_free done\n ");
      //memory unmapping.
      if ((l =
	   (munmap (mmap_vidx[framebuffer_to_open], screensize_vidx))) < 0)

	{
	  return l;
	}
      printTerminalf("mem unmapping done\n ");
      retval = test_vpbe_interface_closeDevice (framebuffer_to_open);
      if (retval < 0)

	{
	  return (retval);
	  break;
	}
      printTerminalf ("Completed cycle:%d\n ",i );
    }
  return 0;
}

int
test_vpbe_interface_stress_test_vid(int framebuffer_to_open)
{

  int retval;
  unsigned int i;
// int ret;
//  int framebuffer=2;
//  int blend_value=4;	
//  ret=test_vpbe_interface_open_fb (framebuffer);
//  if(ret <0) 
//  {
//	return (ret);	
//  }
//	printTerminalf("1.interface_open_fb success\n");
//  ret = test_vpbe_interface_create_blend(framebuffer,blend_value); 	
//  if(ret<0)
//  {
//	printTerminalf("2.entered interface_create_blend\n");
// 	return(ret);
//  }
//	printTerminalf("1.interface_create_blend success\n");
  for (i = 0; i < 9000; i++)

    {
      	retval = test_vpbe_interface_open_fb (framebuffer_to_open);
	    if (retval < 0)

		{
		  return (retval);
		  break;
		}
      	retval = test_vpbe_interface_mmap_vidx (framebuffer_to_open);
	    if (retval < 0)

		{
		  return (retval);
		  break;
		}
	    retval = test_vpbe_interface_image_display (framebuffer_to_open);
    	if (retval < 0)

		{
		  return (retval);
		  break;
		}
	    retval = test_vpbe_interface_closeDevice (framebuffer_to_open);
    	if (retval < 0)

		{
		  return (retval);
		  break;
		}
      	printTerminalf ("completed cycle:%d\n", i);
    }
  return 0;
}

int
test_vpbe_interface_readImage_display (int framebuffer_to_open)
{

//      int i;
  FILE *pFile;
  long lsize;
  char filename[55];
  char *buffer;
  printTerminalf ("Enter the file to open:");
 scanTerminalf ("%s", filename);
  if ((pFile = fopen (filename, "r")) < 0)

    {
      return -1;
    }

  // obtain file size (as lsize).
  if ((fseek (pFile, 0, SEEK_END)) < 0)

    {
      return -2;
    }
  lsize = ftell (pFile);
  if (lsize < 0)

    {
      return -3;
    }
  rewind (pFile);

  //buffer memory allocation
  buffer = (char *) malloc (lsize);
  if (buffer == NULL)

    {
      return -6;
    }
  if ((fread (buffer, 1, lsize, pFile)) < 0)

    {
      return -4;
    }
  memcpy (mmap_vidx[framebuffer_to_open], buffer, lsize);
  fclose (pFile);
  free (buffer);

  //memory unmapping.
  if ((munmap (mmap_vidx[framebuffer_to_open], screensize_vidx)) < 0)

    {
      return -5;
    }

  else

    {
      return 0;
    }
  return 0;
}

int
test_vpbe_interface_tripleBuffer_vidx (int framebuffer_to_open)
{
  int number = 0;
  int i = 0, j = 0, k = 0;
  int retval;
  unsigned char col_8;
  if ((1 == framebuffer_to_open) || (3 == framebuffer_to_open))

    {

      // set second buffer to grey
      memset ((void *) mmap_vidx[framebuffer_to_open], 0x8080, 0xa8c00);
      memcpy ((void *) mmap_vidx[framebuffer_to_open] + 0xa8c00,
	      yuv_image_720x480, 0xa8c00);
    }

  else

    {

      /* fill buffer 2 with col_8 = 0xAA */
      col_8 = 0xff;
      for (i = vinfo_vidx[framebuffer_to_open].yres; i < vinfo_vidx[framebuffer_to_open].yres * 2; i++)	//vertical
	for (j = 0; j < vinfo_vidx[framebuffer_to_open].xres * vinfo_vidx[framebuffer_to_open].bits_per_pixel / 8; j++)	//horizontal
	  mmap_vidx[framebuffer_to_open][i *
					 finfo_vidx[framebuffer_to_open].
					 line_length + j] = col_8;
    }
  for (k = 0; k < 4; k++)

    {
      number = 1;
      retval =
	test_vpbe_interface_flip_to_buffer (number, framebuffer_to_open);
      if (retval < 0)

	{
	  if (-1 == retval)

	    {
	      return -1;
	    }

	  else

	    {
	      return -2;
	    }
	}
      sleep (1);
      number = 2;
      retval =
	test_vpbe_interface_flip_to_buffer (number, framebuffer_to_open);
      if (retval < 0)

	{
	  if (-1 == retval)

	    {
	      return -1;
	    }

	  else

	    {
	      return -2;
	    }
	}
      sleep (1);
    }
  munmap ((void *) mmap_vidx[framebuffer_to_open],
	  finfo_vidx[framebuffer_to_open].line_length *
	  vinfo_vidx[framebuffer_to_open].yres);
  return 0;
}

/*
int test_vpbe_interface_blankUnblankScreen_vidx(int framebuffer)
{
	int retval;
    	retval = ioctl(fbfd[framebuffer], FBIOBLANK, &vinfo_vidx[framebuffer]);
        return(retval);

}
*/
int
test_vpbe_interface_image_display (int framebuffer)
{

  // Display image onto VID0
  if ((framebuffer == 1) || (framebuffer == 3))

    {
      memcpy (mmap_vidx[framebuffer], yuv_image_720x480, 0xa8c00);
      if ((munmap (mmap_vidx[framebuffer], screensize_vidx)) < 0)

	{
	  return -1;
	}

      else

	{
	  return 0;
	}
    }
  else
	{
	  return -2;
	}
    
  return 0;
}

int
test_vpbe_interface_open_fb (int framebuffer)
{

  // Open the file for reading and writing
  fbfd[framebuffer] = open (fb_dev_names[framebuffer], O_RDWR);
  if ((fbfd[framebuffer]) < 0)

    {
      return -3;
    }

  else
    {
         return 0;
    }
/*
    {

      // Get fixed screen information
      if ((ioctl
	   (fbfd[framebuffer], FBIOGET_FSCREENINFO,
	    &finfo_vidx[framebuffer])) < 0)

	{
	  return -1;
	}

      // Get variable screen information
      if ((ioctl
	   (fbfd[framebuffer], FBIOGET_VSCREENINFO,
	    &vinfo_vidx[framebuffer])) < 0)

	{
	  return -2;
	}

      // Figure out the size of the screen in bytes
      screensize_vidx =
	vinfo_vidx[framebuffer].xres * vinfo_vidx[framebuffer].yres *
	vinfo_vidx[framebuffer].bits_per_pixel / 8;

      // Map the device to memory
      mmap_vidx[framebuffer] =
	(char *) mmap (0, screensize_vidx * 2, PROT_READ | PROT_WRITE,
		       MAP_SHARED, fbfd[framebuffer], 0);
      if ((int) mmap_vidx[framebuffer] < 0)

	{
	  printTerminalf ("MMap error: %d\n", (int) mmap_vidx[framebuffer]);
	  return ((int) mmap_vidx[framebuffer]);
	}
    }*/
 return 0;
}

int
test_vpbe_resize_interface_image_display (int framebuffer, int xVal, int yVal)
{
  int retval;
  vinfo_vidx[framebuffer].xres = xVal;
  vinfo_vidx[framebuffer].yres = yVal;
  retval =
    ioctl (fbfd[framebuffer], FBIOPUT_VSCREENINFO, &vinfo_vidx[framebuffer]);
  if (retval < 0)

    {
      return -3;
    }

  else

    {
      return 0;
    }
}
int
test_vpbe_interface_getScreenInfo_vidx (int framebuffer)
{
  int retval;
  //unsigned int value=0; 
/* Get fixed screen information */
  retval =
    ioctl (fbfd[framebuffer], FBIOGET_VSCREENINFO, &vinfo_vidx[framebuffer]);
 // return (retval);

  //  retval= ioctl (fbfd[framebuffer], FBIO_GETSTD,&value);
  //   printTerminalf(" value= %u \n",value);
  //   printTerminalf("retval= %d \n",retval);

    return(retval);

}

int
test_vpbe_interface_setScreenInfo_vidx (framebuffer, picHeight, picWidth,
					picGrayscale)
{
  int retval;
  vinfo_vidx[framebuffer].grayscale = picGrayscale;
  vinfo_vidx[framebuffer].height = picHeight;
  vinfo_vidx[framebuffer].width = picWidth;

  /* Set Varible Screen Information */
  retval =
    (ioctl
     (fbfd[framebuffer], FBIOPUT_VSCREENINFO, &vinfo_vidx[framebuffer]));
  return (retval);

}

int
test_vpbe_interface_get_fix_ScreenInfo_vidx (int framebuffer)
{
  int retval;

  /*Get Varible Screen Information */
  retval =
    (ioctl
     (fbfd[framebuffer], FBIOGET_FSCREENINFO, &finfo_vidx[framebuffer]));
  return (retval);
}

int
test_vpbe_interface_flip_to_buffer (int number, int framebuffer)
{
  int retval;
  retval =
    ioctl (fbfd[framebuffer], FBIOGET_VSCREENINFO, &vinfo_vidx[framebuffer]);
  if (retval < 0)

    {
      return -1;
    }
 
  vinfo_vidx[framebuffer].yoffset =  vinfo_vidx[framebuffer].yres * (number - 1);
  
  retval = ioctl (fbfd[framebuffer], FBIOPAN_DISPLAY, &vinfo_vidx[framebuffer]);
  if (retval < 0)

    {
      return -2;
    }
  return 0;
}
