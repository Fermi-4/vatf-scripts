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

/** \file   i2cWriteThroughput.c

  This file implements the i2c Write Throughput test case

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
#include <sys/ioctl.h>
/* Include package headers here */
#include <stTimer.h>
#include <stTokenizer.h>
#include <stBufferMgr.h>
#include <stLog.h>
#include <i2cPerf.h>
#include <stCpuLoad.h>
#define AUTOMATION
int writetoeeprom(int fd,int bufsize,int count)
{

    unsigned char wBuf[] = { 0x05,0x00,'D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','I',
        '2', 'C','D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','I',
        '2', 'C','D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','I',
        '2', 'C','D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','I',
        '2', 'C','D', 'A', 'V', 'I', 'N', 'C', 'I', 'H','D','I',
        '2', 'C','D', 'A', 'V', 'I'};
    int j      =0;
    int writeRet =0;
    int flag    = 0;  
    char pageno =DEFAULT_PAGE_NUMBER; 
    char byteno =DEFAULT_BYTE_NUMBER;


    for(j=0;j<count;j++)
    {
        writeRet= write(fd, wBuf, bufsize);

        byteno = byteno+bufsize;
        if (byteno >= PAGE_SIZE)  
        { 
            pageno++;
            byteno = DEFAULT_BYTE_NUMBER;
        }

        wBuf[0] = (pageno & PAGE_MASK_MSB ) >> PAGE_MSB_SHIFT;
        wBuf[1] = (pageno & PAGE_MASK_LSB) <<  PAGE_LSB_SHIFT; 
        wBuf[1] |= (byteno & BYTE_MASK);
        usleep(DELAY_MICROSECS);      

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
int throughputI2cWrite(int numArgs, const char ** argv)
{
    int fdes            = 0;
    int result          = 0;
    int addrFmt         = 0;
    int slaveAddr       = SLAVE_ADDR;   
    int bsize      = DEFAULT_BUFFER_SIZE;
    int totalSize  = DEFAULT_TOTAL_SIZE;
    int loopcount       = 0;
    long int Actualtime    = 0;
    float calc; 
    char dev_node[15];
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;

    do {
        /*Get the next token for dev node like /dev/i2c/0 */
        getNextTokenString(&numArgs, argv, dev_node);

        /*Get the next token for app buffer size */
        getNextTokenInt(&numArgs, argv,&bsize);

        /* Get the next token for Total Buffer Size */
        getNextTokenInt(&numArgs,argv,&totalSize);
#ifndef AUTOMATION
        PERFLOG("  App Buffer Size %d \n",bsize); 
        PERFLOG("  Total Buffer Size %d \n",totalSize);
#else      
        printf("I2C: Write: Application buffer Size in Bytes: %d\n", bsize);
        printf("I2C: Write: Total buffer Size in Bytes: %d\n", totalSize);
#endif

        loopcount = totalSize/bsize;

        fdes = open((const char *)dev_node, O_RDWR);

        if(ST_FAIL == fdes)
        {
            perror("\n open ");
            break;
        }
        result = ioctl(fdes,I2C_TENBIT,addrFmt);
        if (result < 0)
        {
            perror("Ioctl I2C_TENBIT failed");
            close(fdes);
            break;
        }    
        result = ioctl(fdes,I2C_SLAVE,slaveAddr);
        if (result < 0)
        {
            perror("Ioctl I2C_SLAVE failed");
            close(fdes);
            break;
        }

       /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

        /* Start Timer */
        startTimer(&startTime);

        result = writetoeeprom(fdes,bsize,loopcount);
        if (result < 0)
        {
            perror("writetoeeprom func failed");
            close(fdes);
            break;
        }

        /* Stop the Timer and get the usecs elapsed */
        elapsedUsecs = stopTimer (&startTime);

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

        result = close(fdes);
        if(ST_FAIL == result)
        {
            perror("\n close ");
            break ;
        }

        Actualtime = (elapsedUsecs - (loopcount*DELAY_MICROSECS));
        calc = ((totalSize*1000000)/(elapsedUsecs));
        calc = (calc*BYTE_TO_BIT_CONV)/BIT_TO_KBIT_CONV;
        //calc = (totalSize*1000000/elapsedUsecs) ;

#ifndef AUTOMATION
        /* print the difference */
        PERFLOG("\n\rACTUAL_TIME(), completed in %ld microseconds\n",
                Actualtime);
        PERFLOG("\n\rthroughputI2cWrite(), completed in %ld microseconds\n",
                elapsedUsecs);
        PERFLOG("throughputI2cWrite(), completed in %f Kbits/sec \r\n",
                calc);
#else
        printf("I2C: Write: Duration in uSec: %ld\n", Actualtime);
        printf("I2C: Write: Kbits/Sec: %f\n", calc);
#endif

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("I2C: Write: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    }while (0);

    return result;
}


/* vim: set ts=4 sw=4 tw=80 et:*/
