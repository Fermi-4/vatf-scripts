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

/** \file   fsReadThroughput.c

  This file implements the FS Read Throughput test case

  (C) Copyright 2006, Texas Instruments, Inc

  \author     Somasekar.M
  \version    1.0
  \version	    1.1 - Surendra Puduru: Updated prints according to automation requirements
 */
/*******************************************************************************/
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

#define PATHSIZE 25
#define AUTOMATION
int throughputFSRead(int numArgs, const char ** argv)
{
    int fdes            = 0;
    int result          = 0;
    char *buffPtr       = NULL; 
    char *filePtr       = NULL; 
    int i               = 0;
    int readRet         = 0;
    int bsize      = 0;
    int totalSize  = 0;
    int loopcount       = 0;
    int remainder       = 0; 
    int totbytread      = 0;    
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;

    do {

        /* Allocation for file name buffer */

        filePtr = (char *)perfAllocateBuffer(PATHSIZE);      
        if (NULL == filePtr)
        {
            perror("filePtr");
            break;
        }  

        /* Do the initializtion for the tests to set the params on  */
        /* Get the next token for filename */
        getNextTokenString(&numArgs, argv, filePtr);

        /* Get the next token for app buffer size */
        getNextTokenInt(&numArgs, argv,&bsize);
#ifndef AUTOMATION
        PERFLOG("  App Buffer Size %d \n",bsize); 
#else      
        printf("fileread: Buffer Size in bytes: %d\n", bsize);
#endif
		
        /* Get the next token for Total Buffer Size */
        getNextTokenInt(&numArgs,argv,&totalSize);
#ifndef AUTOMATION
        PERFLOG("  Total Buffer Size %d \n",totalSize);
#else      
        printf("fileread: FileSize in bytes: %d\n", totalSize);
#endif

        loopcount = totalSize/bsize;
        remainder = totalSize%bsize;
        /* Allocate memory for the buffPtr, size = bsize */
        buffPtr = (char * ) perfAllocateBuffer(bsize * (sizeof(char)));
        if (NULL == buffPtr)
        {
            perror("buffPtr");
            break;
        }

       /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

        /* Start Timer */  
        startTimer(&startTime);
        /* Perform the read operation */
        /* TODO Filename needs to be obtained from arguments */

        fdes = open((const char*)filePtr, O_RDONLY);
        if(-1 == fdes)
        {
            perror("\n open ");
            break;
        }

        for(i = 0 ; i < loopcount; i++)
        {
            readRet = read(fdes, buffPtr, bsize) ;
            totbytread = totbytread + readRet;
            if(bsize != readRet)
            {
                perror("\n Read ") ;
                close(fdes);
                break;
            }
        }

        if(remainder)
        {
            readRet = read(fdes, buffPtr, remainder) ;
            totbytread = totbytread + readRet;
            if(remainder != readRet)
            {
                 perror("\n Read ") ;
                close(fdes);
                break;
            }
        }
        result = close(fdes);
        if(-1 == result)
        {
            perror("\n close ");
            break ;
        }


        /* Stop the Timer and get the usecs elapsed */
        elapsedUsecs = stopTimer (&startTime);

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

#ifndef AUTOMATION
        PERFLOG(" Bytes read is %d \n",totbytread); 
        /* print the difference */
        PERFLOG("\n\rthroughputFSRead(), completed in %d microseconds\n",
                elapsedUsecs);
        PERFLOG("throughputFSRead(), completed in %ld bytes/sec \r\n",
                ((totalSize/elapsedUsecs) *1000000));
#else      
        printf("fileread: Durartion in usecs: %ld\n", elapsedUsecs);
        printf("fileread: Mega Bytes/Sec: %lf\n", (float)(((float)totalSize/(float)elapsedUsecs)));
#endif

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("fileread: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    }while (0);
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


/* vim: set ts=4 sw=4 tw=80 et:*/
