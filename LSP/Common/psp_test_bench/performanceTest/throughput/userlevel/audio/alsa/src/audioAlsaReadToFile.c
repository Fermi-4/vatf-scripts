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
 **|         Copyright (c) 1998-2007 Texas Instruments Incorporated           |**
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
/******************************************************************************
FILE            : audioAlsaReadToFile.c
BRIEF           : Function to calculate the Through put of Audio Driver during Capture.
                  Captured audio data will be written to file.
PLATFORM        : Linux
AUTHOR          : Surendra Puduru

(C) Copyright 2008, Texas Instruments, Inc

******************************************************************************/


/*************** Include standard headers here **********************************/

#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>

/***************** Include alsa headers here ************************************/
#include <alsa/asoundlib.h>

/****************** Include package headers here *********************************/
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

#define AUTOMATION 1

/*********************** Global Variables/Functions *******************************/
static void read_audio_usage(void);


/************************** Main Function Definition ***************************/

/****************************************************************************
 * Function             - throughputAudioAlsaRead
 * Functionality        - Function to calculate the throughput of Audio Driver
 *                        during Capture
 * Input Params         - No. of arguments,array of arguments.
 * Return Value         - Success > 0; Failure = -1.
 * Note                 - None
 ****************************************************************************/


int throughputAudioAlsaReadToFile(int numArgs, const char ** argv)
{
    int status               = 0;
    int loopIndex            = 0;
    int loopCount               = 0;
    snd_pcm_format_t numBits    = SND_PCM_FORMAT_S16_LE; //Signed 16 bits
    snd_pcm_format_t retnumBits;
    unsigned int numChans       = 2; //Stereo
    unsigned int retSamplingRate= 0;
    int bsize                = 0;
    int totalSize       = 0;
    int getSamplingRate            = 0;
    unsigned int samplingRate = 0;
    snd_pcm_access_t access     = SND_PCM_ACCESS_RW_INTERLEAVED;
    snd_pcm_uframes_t period_size = 128;
    snd_pcm_uframes_t buffer_size = 0;
    snd_pcm_t *pcm_handle;
    unsigned long int * read_buffPtr = 0;
    char device[15] = {'\0',};
    int recordFD             = 0;
    int writeRet             = 0;
    char fileName[1024]      = {0,};
    int dir = 0, err = 0;
    snd_pcm_hw_params_t *hw_params;
    snd_pcm_state_t  state;
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    double elapsedSecs       = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;

    /*Check the correct number of Arguments*/
    if(numArgs == 0 || numArgs < 4)
        {   
            read_audio_usage();
            return -1;
        }
    

    /* Parse all input parameters */

    /* Get the device node */
    getNextTokenString(&numArgs, argv, device);

    if((strcmp(device,"plughw:0,0") != 0) && (strcmp(device,"plughw:2,0") != 0))
        {
            PERFLOG("%s is not a valid Audio Capture Device.\n", device);
            read_audio_usage();
            return(-1);
        }

    /* Get the absolute path of the file */
    getNextTokenString(&numArgs, argv, fileName);
#ifndef AUTOMATION
	printf("filename = %s", fileName);
#endif

    /* Get the sampling rate */
    getNextTokenInt(&numArgs, argv, &getSamplingRate);

    if(    (getSamplingRate != 8000)  && (getSamplingRate != 11025) \
        && (getSamplingRate != 12000) && (getSamplingRate != 16000) \
        && (getSamplingRate != 22050) && (getSamplingRate != 24000) \
        && (getSamplingRate != 32000) && (getSamplingRate != 44100) \
        && (getSamplingRate != 48000) && (getSamplingRate != 64000) \
        && (getSamplingRate != 88200) && (getSamplingRate != 96000))
        {
            PERFLOG("%d is not a Supported Sampling Rate.\n", samplingRate);
            read_audio_usage();
            return(-1);
        }

    samplingRate = getSamplingRate;

    /* Get the software buffer size for each operation */
    getNextTokenInt(&numArgs, argv, &bsize);

    buffer_size = bsize/2; //Set the Hardware buffer
    period_size = bsize/4;

    /* Get the total size of operation */
    getNextTokenInt(&numArgs, argv, &totalSize);

    do
    {
        loopCount = totalSize/bsize;

        /* Open the file in write mode */
        recordFD = open(fileName, O_CREAT | O_WRONLY | O_SYNC);
        if(-1 == recordFD)
        {
            perror("\nfopen ");
            return(-1);
        }

        /* Open the device in read mode */
        if ((status = snd_pcm_open (&pcm_handle, device, SND_PCM_STREAM_CAPTURE, 0)) < 0) 
        {
                PERFLOG("Open %s Device Failed.\n",device);
                return(-1);
        } 

        /*Set the hardware parameters*/
        if ((err = snd_pcm_hw_params_malloc (&hw_params)) < 0) 
            return(-1);

        if ((err = snd_pcm_hw_params_any (pcm_handle, hw_params)) < 0) 
            return(-1);

        if ((err = snd_pcm_hw_params_set_access (pcm_handle, hw_params,access)) < 0) 
            return(-1);
    
        if ((err = snd_pcm_hw_params_set_format (pcm_handle, hw_params,numBits)) < 0) 
            return(-1);

        if ((err = snd_pcm_hw_params_set_rate_near (pcm_handle, hw_params, &samplingRate,&dir)) < 0) 
            return(-1);
    
        if ((err = snd_pcm_hw_params_set_channels (pcm_handle, hw_params, numChans)) < 0) 
            return(-1);

        if((err = snd_pcm_hw_params_set_period_size_near(pcm_handle, hw_params, &period_size, &dir)) < 0)   
            return(-1);
    
        if((err = snd_pcm_hw_params_set_buffer_size_near(pcm_handle, hw_params,&buffer_size )) < 0) 
            return(-1);
    
        if ((err = snd_pcm_hw_params (pcm_handle, hw_params)) < 0) 
            return(-1);
    
        snd_pcm_hw_params_free (hw_params);
       
        /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

         /* Allocate memory for the buffPtr, size = bsize */
        if((read_buffPtr = (unsigned long int * ) perfAllocateBuffer(bsize)) == NULL)
        {
            PERFLOG("Memory allocation for Buffer Failed.\n");
            return(-1);
        }

        /* Start the Timer */
        startTimer(&startTime); 

        /* Perform the operation loopCount times */
        for(loopIndex = 0 ; loopIndex < loopCount; loopIndex++)
        {
            snd_pcm_sframes_t status = 0;

            /* Perform the read operation */

            if((status = (snd_pcm_readi(pcm_handle, read_buffPtr, bsize/4))) < 0)
            {
                if (status == -EAGAIN)
                {
                    snd_pcm_wait(pcm_handle, 1000);
                    loopIndex--;
                }
                else if((status = snd_pcm_recover(pcm_handle,status,0)) < 0)
                {
                    PERFLOG("Read from Device Failed\n");
                    perfFreeBuffer(read_buffPtr);
                    return(-1);
                }
            }            
            else if(status != bsize/4)
            {
                PERFLOG("failed to read all the samples %ld(%d)\n", status, bsize/4);
            }
        
            if((strcmp((snd_pcm_state_name(snd_pcm_state(pcm_handle))), "RUNNING")) != 0 )
            {
                PERFLOG("Read Device State: %s\n", snd_pcm_state_name(snd_pcm_state(pcm_handle)));
                perfFreeBuffer(read_buffPtr);
                return (-1);
            }

            /* Write data to file */
            writeRet = write(recordFD, read_buffPtr, bsize);
            if(bsize != writeRet)
            {
                perror("\nfwrite");
            }
 
        }

        /* Stop the Timer and get the usecs elapsed */
        elapsedUsecs = stopTimer (&startTime);

        elapsedSecs = (double) elapsedUsecs / 1000000u;

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

        /*Get the Hardware Parameters of the Device*/
        if(( status = snd_pcm_hw_params_malloc(&hw_params)) < 0)
        {
            PERFLOG("HW Params Malloc Failure,(%s)\n",snd_strerror(status));
            perfFreeBuffer(read_buffPtr);
            return(-1);
        }

        /*Copy the current configuration space details into the  new hardware parameter structure*/

        if((status = snd_pcm_hw_params_current(pcm_handle, hw_params)) < 0)
        {
            PERFLOG("Get HW Params Failure,(%s)\n",snd_strerror(status));
            perfFreeBuffer(read_buffPtr);
            return(-1);
        }

        /* Get the number of bits */
        if ((status = snd_pcm_hw_params_get_format(hw_params, &retnumBits) < 0) )
        {
            PERFLOG("Get Format type from Device Failed.\n");
            perfFreeBuffer(read_buffPtr);
            return(-1);
        } 
        else 
        {
            switch(retnumBits)
            {
                case SND_PCM_FORMAT_S8:
                    numBits = 8;
                break;
                case SND_PCM_FORMAT_S16_LE:
                    numBits = 16;
                break;
                case SND_PCM_FORMAT_S24_LE:
                    numBits = 24;
                break;
                case SND_PCM_FORMAT_S32_LE:
                    numBits = 32;
                break;
                default:
                        PERFLOG("Number of bits = %d\n",numBits);
                break;
            }
#ifndef AUTOMATION
            PERFLOG("NUMBER OF BITS : %d\n", numBits);
#else      
            printf("audio_file: read: Word Length in bits: %d\n", numBits);
#endif
        }
        

        /* Get the number of channels */
        if ((status = snd_pcm_hw_params_get_channels (hw_params, &numChans)) < 0) 
        {
            PERFLOG("Get Channel Failed.\n");
            perfFreeBuffer(read_buffPtr);
            return(-1);
        } 
        else 
        {
#ifndef AUTOMATION
            PERFLOG("CHANNELS : %d\n", numChans);
#else      
        printf("audio_file: read: No. of channels per sample: %d\n", numChans);
#endif
        }

        /* Get the sampling rate */
        if ((status = snd_pcm_hw_params_get_rate (hw_params, &retSamplingRate,&dir)) < 0) 
        {
            PERFLOG("Get Rate Failed.\n");
            perfFreeBuffer(read_buffPtr);
            return(-1);
        } 
        else 
        {
#ifndef AUTOMATION
            PERFLOG("SAMPLING RATE : %d\n", retSamplingRate);
#else      
        printf("audio_file: read: Sampling Rate in Hz: %d\n", retSamplingRate);
#endif
        }

#ifndef AUTOMATION
        PERFLOG("throughput is %lf bits/sec\n", 
                ((double)(totalSize * 8) / elapsedSecs));
        /* print the time taken */
        PERFLOG("completed in %lf seconds\n",
                elapsedSecs);
        PERFLOG("Theoretical throughput = %d bits/sec\n", numBits * numChans * retSamplingRate);
#else      
        printf("audio_file: read: Duration in Sec: %lf\n", elapsedSecs);
        printf("audio_file: read: No. of bits/Sec: %.0lf\n", ((double)(totalSize * 8) / elapsedSecs));
//        printf("audio_file: read: Theoretical throughput = %d bits/sec\n", numBits * numChans * retSamplingRate);
#endif

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("audio_file: read: percentage cpu load: %.2f%%\n", percentageCpuLoad);

        /* close the descriptor */
        state = snd_pcm_state(pcm_handle);

        if((state == SND_PCM_STATE_RUNNING) || (state == SND_PCM_STATE_PREPARED) || 
                (state == SND_PCM_STATE_SETUP) || (state == SND_PCM_STATE_OPEN) || 
                (state == SND_PCM_STATE_PAUSED) || (state == SND_PCM_STATE_XRUN) || 
                (state == SND_PCM_STATE_DRAINING) || (state == SND_PCM_STATE_SUSPENDED))
        {
  	        if((status = snd_pcm_close(pcm_handle)) < 0)
              {
                perfFreeBuffer(read_buffPtr);
            	return(-1);
        }
        }

    } while (0);

    /* Free  memory for the buffPtr, size = bsize */
    if(NULL != read_buffPtr) 
    {
        perfFreeBuffer(read_buffPtr);
    }

    return (status);
}

/****************************************************************************
 * Function             - read_audio_usage
 * Functionality        - Function to print the command line arguments.
 * Input Params         - None.
 * Return Value         - None.
 * Note                 - None
 ****************************************************************************/

static void read_audio_usage(void)
  {   
    PERFLOG("./pspTest ThruPut FRaudioalsaread [File for Audio Data][Capture device] [Sampling Rate] [Buffer Size] [Total Data Size]\n");
  }


/* vim: set ts=4 sw=4 tw=80 et:*/

