#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <fcntl.h>
#include <linux/soundcard.h>
//#include <linux/soundcard.h>
#ifdef _AIX
#include <sys/select.h>
#endif
#include <getopt.h>

// Global Declarations
int fd = 0, fd_mix = 0; // Handle for file descriptor
int srate = 48000; //variable for sampling rate. Default = 48000Hz
char buf[128 * 1024]; // DMA buffer size max permitted by driver
long int frag = 0x7fff0008;	/* 32 fragments of 2^8=256 bytes */

// Setting values for input. In future, add a user controllable option.

int linein = SOUND_MASK_LINE1; // Handle for setting input to linein
int micin = 128; // Handle for setting input to microphone

// Parses the fragment size Entered by the user. Check if the fragment size is a multiple of bytes. Then check if the fragment size is a power of 2.

// Booleans
int BLOCKING = 0;
int MIC = 0;

int getfragsize(int frg)
{
int count = 0;
int qt = 0;
 
 // Fragment size has to be multiple of 4 bytes.
 if ((frg % 4) != 0)
  {
    printf("Invalid fragment size. Fragment size should be a multiple of 4 bytes\n");
    return 0;
  }

 qt = frg;

 while(qt != 1 )
 {
  if ((qt % 2) == 0)
  {
   qt = (qt/2);
   count++;
  }
  else
  {
   printf("%d is not a power of 2\n",frg);
   return 0;
  }
 }

 // Now add this to 0x7fff0000 and see what result u get

  frag =  (0x7fff0000+count);
  return 1;
 
}
   
static void usage(void)
{
    printf("Usage: audioloop [options]\n\n"
           "Options:\n"
           "-s | --srate      Enter the required sampling rate in Hertz\n"
           "-f | --fsize      Enter the frame size as bytes in multiples of 4 bytes\n"
           "-h | --help        Print this message\n"
           "-b | --block      open the audio driver in blocking mode\n"
           "-m | --mic        Use microphone as input\n\n");
}


/******************************************************************************
 * parseArgs
 ******************************************************************************/
static void parseArgs(int argc, char *argv[])
{
    const char shortOptions[] = "s:f:hbm";
    const struct option longOptions[] = {
        {"srate", required_argument, NULL, 's'},
        {"fsize", required_argument, NULL, 'f'},
        {"help", no_argument, NULL, 'h'},
        {"block", no_argument, NULL, 'b'},
        {"mic", no_argument, NULL, 'm'},
        {0, 0, 0, 0}
    };
    int     index;
    int     c;

    for (;;) {
        c = getopt_long(argc, argv, shortOptions, longOptions, &index);

        if (c == -1) {
            break;
        }

        switch (c) {
            case 0:
                printf("This is case 0\n");
                break;

            case 's':
                // Set sampling rate variable
                srate = atoi(optarg);
                break;

            case 'f':
             /* Set fragment size variable after deriving power of 2 and adding it to 0x7fff */

                if(getfragsize(atoi(optarg)) == 0)
                  {
                   exit (-1);
                  }
                break;

           case 'b':
                
                BLOCKING = 1;
                break;

           case 'm':
    
                 MIC = 1;
                break;

            case 'h':
                usage();
                exit (-1);

            default:
                usage();
                exit (-1);
        }
    }
}

int
main (int argc, char *argv[])
{
  

  int have_data = 0;
  int n, l, iter1 = 0;
  int vol, vol1 = 0;

  // Parse the input data.

  parseArgs(argc, argv);

  
  fd_set reads, writes;

  close (0);

  if (BLOCKING){// Open in blocking mode
        if ((fd = open ("/dev/dsp", O_RDWR, 0)) == -1)
        {
         perror ("/dev/dsp open");
         exit (-1);
        }
        }
  else { // Open in Non-blocking mode
        if ((fd = open ("/dev/dsp", O_RDWR|O_NONBLOCK, 0)) == -1)
        {
         perror ("/dev/dsp open");
         exit (-1);
        }
       }

  // Set the fragment size
  ioctl (fd, SNDCTL_DSP_SETFRAGMENT, &frag);

  // Set the input source.

  if (MIC){ // Set microphone as input source
      ioctl (fd, SOUND_MIXER_WRITE_RECSRC, &micin);
          }
  else ioctl (fd, SOUND_MIXER_WRITE_RECSRC, &linein);

// Increase the volume to maximum for linein
#if 1
vol = 100;
if(!MIC)
{
/*if((fd_mix = open("dev/mixer",O_RDWR,0)) == -1)
	{
		perror("Mixer cannot be opened \n");
		exit(-1);
	}
	else
	{*/
	 	if((ioctl(fd, SOUND_MIXER_WRITE_VOLUME, &vol) == -1))
		{
			perror("Cannot set volume \n");
			exit(-1);
		}
		/*if((ioctl(fd, SOUND_MIXER_WRITE_PCM, &vol) == -1))
		{
			perror("Cannot set volume \n");
			exit(-1);
		}*/

		printf("Volume is %d \n", vol1);
		//exit(-1);
//	}
}
  //if(!MIC)
  //{
  //	if(ioctl(fd, 
#endif
  // Set the Sampling rate.
  ioctl (fd, SNDCTL_DSP_SPEED, &srate);

  while (iter1 < 100000)
    {
      struct timeval time;

      FD_ZERO (&reads);
      FD_ZERO (&writes);
	//printf("Insid loop \n");
      if (have_data)
	FD_SET (fd, &writes);
      else
	FD_SET (fd, &reads);

      time.tv_sec = 1;
      time.tv_usec = 0;
      if (select (fd + 1, &reads, &writes, NULL, &time) == -1)
	{
	  perror ("select");
	  exit (-1);
	}

      if (FD_ISSET (fd, &reads))
	{
	  struct audio_buf_info info;

	  if (ioctl (fd, SNDCTL_DSP_GETISPACE, &info) == -1)
	    {
	      perror ("select");
	      exit (-1);
	    }

	  n = info.bytes;

	  l = read (fd, buf, n);
	  if (l > 0)
	    have_data = 1;
	}

      if (FD_ISSET (fd, &writes))
	{
	  int i;

	  struct audio_buf_info info;

	  if (ioctl (fd, SNDCTL_DSP_GETOSPACE, &info) == -1)
	    {
	      perror ("select");
	      exit (-1);
	    }

	  n = info.bytes;

	  //printf ("Write %d\n", l);
	  write (fd, buf, l);
	  //printf ("OK");
	  have_data = 0;
	}
	  iter1 = iter1+1;
    }

  exit (0);
}

