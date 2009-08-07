/*
 * Contains all the utilities for v4L2 capture
 */

/* 
 * Header files
 */
#include "fbdev_display.h"

int nWidthFinal = 0;
int nHeightFinal = 0;

/*
 * struct variables
 */
struct buffer *buffers = NULL;
struct v4l2_cropcap cropcap;

/*
 * Initializing static globals
 */
static int nBuffers = 0;

/*
 * Initializing Non static globals
 */
int fdCapture = -1;

/*
 * Declaring static functions
 */

static int InitCaptureDevice (void);
static int SetDataFormat ();
static int InitCaptureBuffers (void);
static int StartStreaming (void);

/* ************************************************************************/

void
Initialize_Capture ()
{
  printf ("initializing capture device\n");
  InitCaptureDevice ();
  printf ("setting data format\n");
  SetDataFormat ();
  printf ("initializing capture buffers\n");
  InitCaptureBuffers ();
  printf ("initializing display device\n");
  StartStreaming ();
}

/* ************************************************************************/

static int
InitCaptureDevice (void)
{

  struct v4l2_capability cap;
  struct v4l2_input input_svideo;
  int vid_type=0;

  /*input-0 is selected by default, so no need to set it */
  if ((fdCapture = open (CAPTURE_DEVICE, O_RDWR | O_NONBLOCK, 0)) <= -1)
    {
      printf ("InitDevice:open::\n");
      return -1;
    }

  /*is capture supported? */
  if (-1 == ioctl (fdCapture, VIDIOC_QUERYCAP, &cap))
    {
      printf ("InitDevice:ioctl:VIDIOC_QUERYCAP:\n");
      return -1;
    }

  if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE))
    {
      printf ("InitDevice:capture is not supported on:%s\n", CAPTURE_DEVICE);
      return -1;
    }

  /*is MMAP-IO supported? */
  if (!(cap.capabilities & V4L2_CAP_STREAMING))
    {
      printf ("InitDevice:IO method MMAP is not supported on:%s\n",
	      CAPTURE_DEVICE);
      return -1;
    }

  /*select cropping as deault rectangle */
  cropcap.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

  if (-1 == ioctl (fdCapture, VIDIOC_CROPCAP, &cropcap))
    {
      printf ("InitDevice:ioctl:VIDIOC_CROPCAP\n");
      /*ignore error */
    }

  printf
    ("Default crop capbility bounds - %d %d %d %d ; default - %d %d %d %d \n",
     cropcap.bounds.left, cropcap.bounds.top, cropcap.bounds.width,
     cropcap.bounds.height, cropcap.defrect.left, cropcap.defrect.top,
     cropcap.defrect.width, cropcap.defrect.height);

  /* Added by AVM for S-VIDEO*/

  if (svideoinput == 1) {
                        vid_type = 1;
                        memset (&input_svideo, 0, sizeof (input_svideo));
                        if (-1 == ioctl (fdCapture, VIDIOC_S_INPUT, &vid_type)) {
                        perror ("VIDIOC_S_INPUT");
                        exit (EXIT_FAILURE);
                        }
                        if (-1 == ioctl (fdCapture, VIDIOC_G_INPUT, &vid_type)) {
                        perror ("VIDIOC_G_INPUT");
                        exit (EXIT_FAILURE);
                        }
                        input_svideo.index = vid_type;


                        if (-1 == ioctl (fdCapture, VIDIOC_ENUMINPUT, &input_svideo)) {
                        perror ("VIDIOC_ENUMINPUT");
                        exit (EXIT_FAILURE);
                        }
                        printf ("Current input: %s\n", input_svideo.name);
                } // end of svideoinput
            else // Set up for composite video
              if (-1 == ioctl (fdCapture, VIDIOC_S_INPUT, &vid_type)) {
                        perror ("VIDIOC_S_INPUT");
                        exit (EXIT_FAILURE);
                        }
 
  

  return 0;
}

/* ************************************************************************/
static int
SetDataFormat ()
{
  v4l2_std_id prev_std, cur_std;
  struct v4l2_format fmt;
  unsigned int min;

  cur_std = prev_std = VPFE_STD_AUTO;
  printf ("SetDataFormat:setting std to auto select\n");
  if (-1 == ioctl (fdCapture, VIDIOC_S_STD, &cur_std))
    {
      printf ("SetDataFormat:unable to set standard automatically\n");
    }
  sleep (1);			/* wait until decoder is fully locked */
  if (-1 == ioctl (fdCapture, VIDIOC_QUERYSTD, &cur_std))
    {
      printf ("SetDataFormat:ioctl:VIDIOC_QUERYSTD:\n");
    }

  if (cur_std == V4L2_STD_NTSC)
    printf ("Input video standard is NTSC.\n");
  else if (cur_std == V4L2_STD_PAL)
    printf ("Input video standard is PAL.\n");
  else if (cur_std == V4L2_STD_PAL_M)
    printf ("Input video standard is PAL-M.\n");
  else if (cur_std == V4L2_STD_PAL_N)
    printf ("Input video standard is PAL-N.\n");
  else if (cur_std == V4L2_STD_SECAM)
    printf ("Input video standard is SECAM.\n");
  else if (cur_std == V4L2_STD_PAL_60)
    printf ("Input video standard to PAL60.\n");

  printf ("SetDataFormat:setting data format\n");
  //printf ("SetDataFormat:requesting width:%d height:%d\n", WIDTH, HEIGHT);
  CLEAR (fmt);
  fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

                  if (test_data.vid1_width == LCDWIDTH){
		                //Our I/p stream is 720 pixels always.
				//So change this accordingly
				fmt.fmt.pix.width = NTSCWIDTH;
				}
		  else
                  fmt.fmt.pix.width = test_data.vid1_width;	//SSK Buffer Size
                  fmt.fmt.pix.height = test_data.vid1_height;
                  fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY;
  /* the field can be either interlaced together or
     separated in a top, bottom fashion */
  //fmt.fmt.pix.field     = V4L2_FIELD_SEQ_TB;
  fmt.fmt.pix.field = V4L2_FIELD_INTERLACED;
  if (-1 == ioctl (fdCapture, VIDIOC_S_FMT, &fmt))
    {
      printf ("SetDataFormat:ioctl:VIDIOC_S_FMT\n");
    }



  if (-1 == ioctl (fdCapture, VIDIOC_G_FMT, &fmt))
    {
      printf ("SetDataFormat:ioctl:VIDIOC_QUERYSTD:\n");
    }

  nWidthFinal = fmt.fmt.pix.width;
  nHeightFinal = fmt.fmt.pix.height;

  printf ("SetDataFormat:finally negotiated width:%d height:%d\n",
	  fmt.fmt.pix.width, fmt.fmt.pix.height);

  /*checking what is finally negotiated */
  min = fmt.fmt.pix.width * 2;
  if (fmt.fmt.pix.bytesperline < min)
    {
      printf ("SetDataFormat:driver reports bytes_per_line:%d(bug)\n",
	      fmt.fmt.pix.bytesperline);
      /*correct it */
      fmt.fmt.pix.bytesperline = min;
    }

  min = fmt.fmt.pix.bytesperline * fmt.fmt.pix.height;
  if (fmt.fmt.pix.sizeimage < min)
    {
      printf ("SetDataFormat:driver reports size:%d(bug)\n",
	      fmt.fmt.pix.sizeimage);

      /*correct it */
      fmt.fmt.pix.sizeimage = min;
    }

  /*printf ("SetDataFormat:Finally negitaited width:%d height:%d\n",
	  nWidthFinal, nHeightFinal);*/

  return 0;
}

/* ************************************************************************/
static int
InitCaptureBuffers (void)
{
  struct v4l2_requestbuffers req;
  int nIndex = 0;

  CLEAR (req);
  req.count = MIN_BUFFERS;
  req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  req.memory = V4L2_MEMORY_MMAP;

  if (-1 == ioctl (fdCapture, VIDIOC_REQBUFS, &req))
    {
      printf ("InitCaptureBuffers:ioctl:VIDIOC_REQBUFS\n");
      return -1;
    }

  if (req.count < MIN_BUFFERS)
    {
      printf ("InitCaptureBuffers only:%d buffers avilable, can't proceed\n",
	      req.count);
      return -1;
    }

  nBuffers = req.count;
  //printf ("device buffers:%d\n", req.count);
  buffers = (struct buffer *) calloc (req.count, sizeof (struct buffer));
  if (!buffers)
    {
      printf ("InitCaptureBuffers:calloc:\n");
      return -1;
    }

  for (nIndex = 0; nIndex < req.count; ++nIndex)
    {

      struct v4l2_buffer buf;
      CLEAR (buf);
      buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      buf.memory = V4L2_MEMORY_MMAP;
      buf.index = nIndex;

      if (-1 == ioctl (fdCapture, VIDIOC_QUERYBUF, &buf))
	{
	  printf ("InitCaptureBuffers:ioctl:VIDIOC_QUERYBUF:\n\n");
	  return -1;
	}
	//printf("\nBuf.offset=%d\n",buf.m.offset);
      buffers[nIndex].length = buf.length;
      buffers[nIndex].start =
	mmap (NULL, buf.length, PROT_READ | PROT_WRITE, MAP_SHARED, fdCapture,
	      buf.m.offset);

      //printf ("buffer:%d phy:%x mmap:%x length:%d\n", buf.index,
	      //buf.m.offset, buffers[nIndex].start, buf.length);

      if (MAP_FAILED == buffers[nIndex].start)
	{
	  printf ("InitCaptureBuffers:mmap:\n");
	  return -1;
	}
      //printf("buffer:%d addr:%x\n",nIndex,buffers[nIndex].start);
    }

  return 0;
}

/* ************************************************************************/
static int
StartStreaming (void)
{
  int i = 0;
  enum v4l2_buf_type type;

  for (i = 0; i < nBuffers; i++)
    {
      struct v4l2_buffer buf;
      CLEAR (buf);
      buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
      buf.memory = V4L2_MEMORY_MMAP;
      buf.index = i;
      //printf ("Queing buffer:%d\n", i);

      if (-1 == ioctl (fdCapture, VIDIOC_QBUF, &buf))
	{
	  printf ("StartStreaming:ioctl:VIDIOC_QBUF:\n");
	}
    }
  /* all done , get set go */
  type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (-1 == ioctl (fdCapture, VIDIOC_STREAMON, &type))
    {
      printf ("StartStreaming:ioctl:VIDIOC_STREAMON:\n");
    }

  return 0;
}
/* ************************************************************************/

