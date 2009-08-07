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

/** \file   spiWriteThroughput.c

  This file implements the spi Write Throughput test case

  (C) Copyright 2006, Texas Instruments, Inc

  \author     Somasekar.M
  \version    1.0
  \version	    1.1 - Surendra Puduru: Updated prints according to automation requirements
  \version	    1.2 - Yan : Removed hardcoding of mtd device
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
#include <spiPerf.h>
#include <stCpuLoad.h>
#define AUTOMATION
int writetoSpieeprom(int fd,int bufsize,int count)
{

    unsigned char wBuf[] = { 0x01,0x05,0x00,'D', 'A', 'V', 'I', 'N', 'C', 'I',
        'H','D','S',
        'P', 'I','D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','S',
        'P', 'I','D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','S',
        'P', 'I','D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','S',
        'P', 'I','D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','S',
        'P', 'I','D', 'A', 'V', 'I'};
    int j               = 0;
    int writeRet        = 0;
    int flag            = 0;  
    char pageno         = DEFAULT_PAGE_NUMBER; 
    char byteno         = DEFAULT_BYTE_NUMBER;

    for(j=0;j<count;j++)
    {

        writeRet= write(fd, wBuf, 1);
        if(writeRet != 1)
        {
            flag =ST_FAIL;
            perror("\n write():failed");
            break;
        }

        writeRet= write(fd, wBuf+1, bufsize);
        if(writeRet != bufsize)
        {
            flag =ST_FAIL;
            perror("\n write():failed");
            break;
        }


        byteno = byteno+bufsize;
        if (byteno >= PAGE_SIZE)  
        { 
            pageno++;
            byteno = DEFAULT_BYTE_NUMBER;
        }

        wBuf[1] = (pageno & PAGE_MASK_MSB ) >> PAGE_MSB_SHIFT;
        wBuf[2] = (pageno & PAGE_MASK_LSB) <<  PAGE_LSB_SHIFT; 
        wBuf[2] |= (byteno & BYTE_MASK);
        //        usleep(DELAY_MICROSECS);      

        if(writeRet != bufsize)
        {
            flag =ST_FAIL;
            perror("\n write():failed");
            break;
        }
    }        
    if (flag == 0)
    {
        return ST_PASS;
    }

    return ST_FAIL;
}        
int throughputSpiWrite(int numArgs, const char ** argv)
{
    int fdes            = 0;
    int result          = 0;
    int bsize           = DEFAULT_BUFFER_SIZE;
    int totalSize       = DEFAULT_TOTAL_SIZE;
    int loopcount       = 0;
    long int Actualtime    = 0;
    float calc; 
    ST_TIMER_ID timerId;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
    char dev_node[15];

    do {
        /*Get the next token for dev node like /dev/mtd5 */
        getNextTokenString(&numArgs, argv, dev_node);

        /*Get the next token for app buffer size */
        getNextTokenInt(&numArgs, argv,&bsize);

        /* Get the next token for Total Buffer Size */
        getNextTokenInt(&numArgs,argv,&totalSize);
#ifndef AUTOMATION
        PERFLOG("  App Buffer Size %ld \n",bsize); 
        PERFLOG("  Total Buffer Size %ld \n",totalSize);
#else      
        printf("SPI: Write: Application buffer Size in Bytes: %d\n", bsize);
        printf("SPI: Write: Total buffer Size in Bytes: %d\n", totalSize);
#endif

        loopcount = totalSize/bsize;

        fdes = open((const char *)dev_node, O_WRONLY);
        if(ST_FAIL == fdes)
        {
            perror("\n open ");
            break;
        }

       /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

        /* Start the Timer */
        startTimer(&timerId);

        result = writetoSpieeprom(fdes,bsize,loopcount);
        if (result < 0)
        {
            perror("writetoeeprom func failed");
            close(fdes);
            break;
        }

        /* Stop the Timer and get the usecs elapsed */
        elapsedUsecs = stopTimer (&timerId);

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);


        result = close(fdes);
        if(ST_FAIL == result)
        {
            perror("\n close ");
            break ;
        }

        calc = (totalSize*1000000)/(elapsedUsecs);
        calc = (calc*BYTE_TO_BIT_CONV)/BIT_TO_KBIT_CONV;
#ifndef AUTOMATION
        /* print the difference */
        PERFLOG("\n\rACTUAL_TIME(), completed in %ld microseconds\n",
                elapsedUsecs);
        PERFLOG("\n\rCALC() before Kbit conv, completed in %f microseconds\n",
                calc);
        PERFLOG("\n\rthroughputSpiWrite(), completed in %d microseconds\n",
                elapsedUsecs);
        PERFLOG("throughputSpiWrite(), completed in %f Kbits/sec \r\n",
                calc);
#else
        printf("SPI: Write: Duration in uSec: %ld\n", elapsedUsecs);
        printf("SPI: Write: Kbits/Sec: %f\n", calc);
#endif

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("SPI: Write: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    }while (0);

    return result;
}


/* vim: set ts=4 sw=4 tw=80 et:*/
