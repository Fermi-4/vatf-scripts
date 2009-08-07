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
 **|    `                                                                      |**
 **+--------------------------------------------------------------------------+**
 *******************************************************************************/

/** \file   spiReadThroughput.c

  This file implements the spi Write Throughput test case

  (C) Copyright 2006, Texas Instruments, Inc

  \author     Somasekar.M
  \version    1.0
  \version	    1.1 - Surendra Puduru: Updated prints according to automation requirements
  \version	    1.2 - Yan: Removed hardcoding of device entry
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
#include "spiPerf.h"
#include <stCpuLoad.h>

#define AUTOMATION

int readfromSpieeprom(int fd,int bufsize,int count,char *bufPtr)
{   
    char wBuf[]             = {0x05,0x05, 0x00}; 
    int j                   =0;
    int readRet             =0;
    int writeRet            =0;
    int flag                = 0;
    char pageno             =DEFAULT_PAGE_NUMBER;
    char byteno             =DEFAULT_BYTE_NUMBER;

    //PERFLOG("  Entering write ");
    for(j=0;j<count;j++)
    {
        writeRet = write(fd,wBuf,sizeof(wBuf));
        if(writeRet != sizeof(wBuf))
        {
            flag =1;
            perror("\n write():failed");
            break;
        }
        //PERFLOG("  Entering read ");  
        readRet= read(fd, bufPtr, bufsize);
        if(readRet != bufsize)
        {
            flag =1;
            perror("\n read():failed");
            break;
        }
        //PERFLOG("  \n data  %s  \n",bufPtr);
        if (byteno >= PAGE_SIZE)
        {
            byteno = DEFAULT_BYTE_NUMBER;
            pageno++;
        }
        wBuf[1] = (pageno & PAGE_MASK_MSB) >> PAGE_MSB_SHIFT;
        wBuf[2] = (pageno & PAGE_MASK_LSB) << PAGE_LSB_SHIFT;
        wBuf[2] |= (byteno & BYTE_MASK);        
        //PERFLOG("  writeBuf %d \n",wBuf[0]);

    }

    if (flag == 0)
    {
        return ST_PASS;
    }

    return ST_FAIL;
}

int throughputSpiRead(int numArgs, const char ** argv)
{
    char *buffPtr           = NULL;
    int fdes                = 0;
    int result              = 0;
    int bsize          = DEFAULT_BUFFER_SIZE;
    int totalSize      = DEFAULT_TOTAL_SIZE;
    int loopcount           = 0;
    float calc              = 0;
    ST_TIMER_ID timerId;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
    char dev_node[15];

    do {
        /*Get the next token for dev node like /dev/mtd5 */
        getNextTokenString(&numArgs, argv, dev_node);

        /* Get the next token for app buffer size */
        getNextTokenInt(&numArgs, argv,&bsize);

        getNextTokenInt(&numArgs, argv,&totalSize);
#ifndef AUTOMATION
        PERFLOG("  App Buffer Size %d \n",bsize);
        PERFLOG("  Total Buffer Size %d \n",totalSize); 
#else      
        printf("SPI: Read: Application buffer Size in Bytes: %d\n", bsize);
        printf("SPI: Read: Total buffer Size in Bytes: %d\n", totalSize);
        printf("SPI: Read: Device Node: %s\n", dev_node);
#endif

        loopcount = totalSize/bsize;
        /* Allocate memory for the buffPtr, size = bsize */
        buffPtr = (char * ) perfAllocateBuffer(bsize * (sizeof(char)));
        if (NULL == buffPtr)
        {
            perror("buffPtr");
            return ST_FAIL;
        }

        /* Perform the write operation */
        /* TODO Filename needs to be obtained from arguments */

        fdes = open((const char *)dev_node, O_RDWR);
        if(-1 == fdes)
        {
            perror("\n open ");
            break;
        }

       /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

        /* Start the Timer */
        startTimer(&timerId);

        result =  readfromSpieeprom(fdes,bsize,loopcount,buffPtr);
        if (result < 0)
        {
            perror("readfromSpieeprom failed");
            close(fdes); 
            break;
        }

        /* Stop the Timer and get the usecs elapsed */
        elapsedUsecs = stopTimer (&timerId);

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

        result = close(fdes);
        if(-1 == result)
        {
            perror("\n close ");
            break ;
        }


        /* Get the time stamp after the operation */
        calc = (totalSize*1000000/elapsedUsecs);
        calc = (calc* BYTE_TO_BIT_CONV)/BIT_TO_KBIT_CONV;

#ifndef AUTOMATION
        /* print the difference */
        PERFLOG("\n\rthroughputSpiRead(), completed in %d microseconds\n",
                elapsedUsecs);
        PERFLOG("throughputSpiRead(), completed in %f  Kbits/sec \r\n",(calc));
#else
        printf("SPI: Read: Duration in uSec: %ld\n", elapsedUsecs);
        printf("SPI: Read: Kbits/Sec: %f\n", calc);
#endif

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("SPI: Read: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    }while (0);
    /* Free  memory for the buffPtr, size = bsize */

    if (NULL != buffPtr)
    {
        perfFreeBuffer(buffPtr);
    }
    return result;
}


/* vim: set ts=4 sw=4 tw=80 et:*/
