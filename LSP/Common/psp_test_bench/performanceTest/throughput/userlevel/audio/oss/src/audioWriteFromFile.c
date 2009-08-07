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
/**
 *  \file   audioWriteFromFileThroughput.c
 *
 *  \brief  This file implements the audio write throughput test case in sync
 *  mode. The data to be written to the device is read from a file.
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     K.R.Baalaaji     Created
 */

/* Include standard headers here */
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <linux/soundcard.h>

/* Include package headers here */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

#define AUTOMATION 1

int throughputAudioWriteFromFile(int numArgs, const char ** argv)
{
    int audioFD              = 0;
    int playbackFD           = 0;
    int writeRet             = 0;
    int readRet              = 0;
    int status               = 0;
    int numBits              = 16;
    int numChans             = 2;
    int retSamplingRate      = 0;
    int loopIndex            = 0;
    char * buffPtr           = 0;
    int bsize                = 0;
    int totalSize            = 0;
    int samplingRate         = 8000;
    char devNode[1024];
    int loopCount            = 0;
    char fileName[1024]      = {0,};
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    double elapsedSecs       = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;

    /* Parse all input parameters */

    /* Get the device node */
    getNextTokenString(&numArgs, argv, devNode);

    /* Get the absolute path of the file */
    getNextTokenString(&numArgs, argv, fileName);

    /* Get the sampling rate */
    getNextTokenInt(&numArgs, argv, &samplingRate);

    /* Get the buffer size for each operation */
    getNextTokenInt(&numArgs, argv, &bsize);

    /* Get the total size of operation */
    getNextTokenInt(&numArgs, argv, &totalSize);

    do
    {
        /* Allocate memory for the buffPtr, size = bsize */
        buffPtr = (char * ) perfAllocateBuffer(bsize * (sizeof(char)));
        if (NULL == buffPtr)
        {
            break;
        }

        loopCount = totalSize/bsize;

        /* Open the device in write mode */
        audioFD = open((const char *)devNode, O_RDWR | O_SYNC);
        if(-1 == audioFD)
        {
            perror("\nopen ");
            break;
        }

        /* Open the file in read mode */
        playbackFD = open(fileName, O_RDONLY | O_SYNC);
        if(-1 == playbackFD)
        {
            perror("\nfopen ");
            close(audioFD);
            break;
        }

        /* Do the initializtion for the tests to set the params  */

        /* Set the number of bits */
        status = ioctl(audioFD, SOUND_PCM_WRITE_BITS, &numBits);
        if (-1 == status)
        {
            perror("\nioctl:SOUND_PCM_WRITE_BITS");
        }

	/* Set the number of channels */
        status = ioctl(audioFD, SOUND_PCM_WRITE_CHANNELS, &numChans);
        if (-1 == status)
        {
            perror("\nioctl:SOUND_PCM_WRITE_CHANNELS");
        } 

        /* Set the sampling rate  */
        status = ioctl(audioFD, SOUND_PCM_WRITE_RATE, &samplingRate);
        if (-1 == status)
        {
            perror("\nioctl:SOUND_PCM_WRITE_RATE");
        }

       /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

        /* Start the Timer */
        startTimer(&startTime); 

        /* Perform the operation loopCount times */
        for(loopIndex = 0 ; loopIndex < loopCount; loopIndex++)
        {
            /* Read data from file */
            readRet = read(playbackFD, buffPtr, bsize);
            if(bsize != readRet)
            {
                perror("\nfread");
            }

            /* Perform the write operation */
            writeRet = write(audioFD, buffPtr, bsize);
            if(bsize != writeRet)
            {
                perror("\nwrite");
            }
        }

        /* Stop the Timer and get the usecs elapsed */
        elapsedUsecs = stopTimer (&startTime);

        elapsedSecs = (double) elapsedUsecs / 1000000u;

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

        /* Get the number of bits */
        status = ioctl(audioFD, SOUND_PCM_READ_BITS, &numBits);
        if (-1 == status)
        {
            perror("\nioctl:SOUND_PCM_READ_BITS");
        } else {
#ifndef AUTOMATION
            PERFLOG("SOUND_PCM_READ_BITS: %d\n", numBits);
#else      
        printf("audio_file: write: Word Length in bits: %d\n", numBits);
#endif
        }

        /* Get the number of channels */
        status = ioctl(audioFD, SOUND_PCM_READ_CHANNELS, &numChans);
        if (-1 == status)
        {
            perror("\nioctl:SOUND_PCM_READ_CHANNELS");
        } else {
#ifndef AUTOMATION
            PERFLOG("SOUND_PCM_READ_CHANNELS: %d\n", numChans);
#else      
        printf("audio_file: write: No. of channels per sample: %d\n", numChans);
#endif
        }

        /* Get the sampling rate */
        status = ioctl(audioFD, SOUND_PCM_READ_RATE, &retSamplingRate);
        if (-1 == status)
        {
            perror("\nioctl:SOUND_PCM_READ_RATE");
        } else {
#ifndef AUTOMATION
            PERFLOG("SOUND_PCM_READ_RATE: %d\n",
                    retSamplingRate);
#else      
        printf("audio_file: write: Sampling Rate in Hz: %d\n", retSamplingRate);
#endif
        }

#ifndef AUTOMATION
        PERFLOG("throughput is %lf bits/sec\n", 
                ((double)(totalSize * 8) / elapsedSecs));
        /* print the time taken */
        PERFLOG("completed in %lf seconds\n",
                elapsedSecs);
        PERFLOG("Theoretical throughput = %d bits/sec\n"
                , numBits * numChans * retSamplingRate);
#else      
        printf("audio_file: write: Duration in Sec: %lf\n", elapsedSecs);
        printf("audio_file: write: No. of bits/Sec: %.0lf\n", ((double)(totalSize * 8) / elapsedSecs));
#endif

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("audio: write: percentage cpu load: %.2f%%\n", percentageCpuLoad);

#if FLUSH_BEFORE_CLOSE
        /* Flush the descriptor before the close */
        status = fflush(audioFD);
        if(-1 == status)
        {
            perror("\nflush ");
        } else {
            PERFLOG("flushed the FD\n");
        }
#endif
        /* close the descriptor */
        status = close(playbackFD);
        if(-1 == status)
        {
            perror("\nfclose ");
        }

        /* close the descriptor */
        status = close(audioFD);
        if(-1 == status)
        {
            perror("\nclose ");
        }

    } while (0);

    /* Free  memory for the buffPtr, size = bsize */
    if(NULL != buffPtr) 
    {
        perfFreeBuffer(buffPtr);
    }

    return status;
}

/* vim: set ts=4 sw=4 tw=80 et:*/
