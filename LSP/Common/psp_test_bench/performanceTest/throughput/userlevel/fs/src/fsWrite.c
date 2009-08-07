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

/** \file   fsWriteThroughput.c

  This file implements the FS Write Throughput Performance test case

  (C) Copyright 2006, Texas Instruments, Inc

  \author     Somasekar.M
  \version    1.0
  \version	    1.1 - Surendra Puduru: Updated prints according to automation requirements
 */
/*******************************************************************************/
/* Include standard headers here */
#include <sys/time.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
/* Include package headers here */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <stCpuLoad.h>

static int MTDBlkIO = FALSE;

#define PATHSIZE 25
#define AUTOMATION

static int throughputFileWrite(int numArgs, const char ** argv)
{
    int fdes                = 0;
    int writeRet            = 0;
    int result              = 0;
    char *buffPtr           = NULL;
    char *filePtr           = NULL;
    int i                   = 0;
    int bsize          = 0;
    int totalSize      = 0;
    int loopcount           = 0;
    int remainder           = 0;
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;

    do {
        /* Allocation for file name buffer */
        filePtr = (char * ) perfAllocateBuffer(PATHSIZE);
        if (NULL == filePtr)
        {
            perror("fileptr:");
            break;
        }

        /* Do the initializtion for the tests to set the params on  */
        /* Get the next token for filename */
        getNextTokenString(&numArgs, argv, filePtr);
        /* Get the next token for app buffer size */
        getNextTokenInt(&numArgs, argv,&bsize);

#ifndef AUTOMATION
        PERFLOG(" FILE PATH %s \n ",filePtr);
        PERFLOG(" App Buffer Size %d \n",bsize); 
#else      
        printf("filewrite: Buffer Size in bytes: %d\n", bsize);
#endif
        /* Get the next token for Total Buffer Size */
        getNextTokenInt(&numArgs,argv,&totalSize);
#ifndef AUTOMATION
        PERFLOG(" Total Buffer Size %d \n",totalSize);
#else      
        printf("filewrite: FileSize in bytes: %d\n", totalSize);
#endif

        /* Allocate memory for the buffPtr, size = bsize */
        buffPtr = (char * ) perfAllocateBuffer(bsize * (sizeof(char)));
        if (NULL == buffPtr)
        {
            perror("buffPtr:");
            break;
        }

        loopcount = totalSize/bsize; 
        remainder = totalSize%bsize;
#ifndef AUTOMATION
        PERFLOG(" Loop count is %d \n",loopcount); 
        PERFLOG(" Remainder is %d \n",remainder); 
#endif
       /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

        /* Start Timer */ 
        startTimer(&startTime);

        /* Perform the write operation */
        /* TODO Filename needs to be obtained from arguments */
        fdes = open((const char*)filePtr, O_WRONLY | O_CREAT);
        if(-1 == fdes)
        {
            perror("\n open ");
            break;
        }

        for(i = 0 ; i < loopcount; i++)
        {
            writeRet = write(fdes, buffPtr, bsize) ;
            if(bsize != writeRet)
            {
                close(fdes);
                perror("\n write ") ;
                break;
            }
        }

        if(remainder)
        {
            writeRet = write(fdes, buffPtr, remainder) ;
            if(remainder != writeRet)
            {
                close(fdes);
                perror("\n write ") ;
                break;
            }
        }

        if(TRUE != MTDBlkIO)
        {
	        result = fsync(fdes);
	        if (-1 == result)
	        {
	            perror("\n fsync");
	            break;
            }
        }

        result = close(fdes);
        if(-1 == result)
        {
            perror("\n close ");
            break;
        }

        /* Stop the Timer and get the usecs elapsed */
        elapsedUsecs = stopTimer (&startTime);

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

#ifndef AUTOMATION
        /* print the difference */
        PERFLOG("filewrite(), completed in %d microseconds\n",
                elapsedUsecs);

        PERFLOG("filewrite(), completed in %ld bytes/sec \r\n",
                ((totalSize/elapsedUsecs) *1000000));
#else      
        printf("filewrite: Durartion in usecs: %ld\n", elapsedUsecs);
        printf("filewrite: Mega Bytes/Sec: %lf\n", (float)(((float)totalSize/(float)elapsedUsecs)));
#endif

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("filewrite: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    } while(0); 

    /* Free  memory for the filePtr,buffPtr, size = bsize */
    if (NULL != filePtr)
    {
        perfFreeBuffer(filePtr);
    }

    if (NULL != buffPtr)
    {
        perfFreeBuffer(buffPtr);
    }
    return result;
}

int throughputMTDBlkWrite(int numArgs, const char ** argv)
{
    MTDBlkIO = TRUE;
    return(throughputFileWrite(numArgs, argv));
}

int throughputFSWrite(int numArgs, const char ** argv)
{
    MTDBlkIO = FALSE;
    return(throughputFileWrite(numArgs, argv));
}

/* vim: set ts=4 sw=4 tw=80 et:*/
