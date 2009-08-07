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

/** \file   i2cReadThroughput.c

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
/* The below functions reads the data from the EEPROM 
Input Parameters fd         - File descriptor
                 bufsize    - Application Buffer size
                 Count      - Loop count 
                 bufPtr     - pointer to store the read data 
*/
int readfromeeprom(int fd,int bufsize,int count,char *bufPtr)
{   
    char wBuf[]             = {0x05, 0x00};
    int j                   =0;
    int readRet             =0;
    int writeRet            =0;
    int flag                = 0;
    char pageno             =DEFAULT_PAGE_NUMBER;
    char byteno             =DEFAULT_BYTE_NUMBER;

      
    for(j=0;j<count;j++)
    {
        writeRet = write(fd,wBuf,sizeof(wBuf));
        if(sizeof(wBuf) != writeRet)
        {
            flag =1;
            perror("\n write():failed");
            break;
        }
        readRet= read(fd, bufPtr, bufsize);
        if(bufsize != readRet)
        {
            flag =1;
            perror("\n read():failed");
            break;
        }
        if (byteno >= PAGE_SIZE)
        {
            byteno = DEFAULT_BYTE_NUMBER;
            pageno++;
        }
        wBuf[0] = (pageno & PAGE_MASK_MSB) >> PAGE_MSB_SHIFT;
        wBuf[1] = (pageno & PAGE_MASK_LSB) << PAGE_LSB_SHIFT;
        wBuf[1] |= (byteno & BYTE_MASK);        

    }

    if (flag == 0)
    {
        return ST_PASS;
    }

    return ST_FAIL;
}

int throughputI2cRead(int numArgs, const char ** argv)
{
    char *buffPtr           = NULL;
    int fdes                = 0;
    int result              = 0;
    int addrFmt             = 0;
    int slaveAddr           = SLAVE_ADDR;   
    int bsize               = DEFAULT_BUFFER_SIZE;
    int totalSize           = DEFAULT_TOTAL_SIZE;
    int loopcount           = 0;
    float calc              = 0;
    char dev_node[15];
    ST_TIMER_ID startTime;
    unsigned long elapsedUsecs = 0;
    ST_CPU_STATUS_ID cpuStatusId;
    float percentageCpuLoad = 0;
    
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
        printf("I2C: Read: Application buffer Size in Bytes: %d\n", bsize);
        printf("I2C: Read: Total buffer Size in Bytes: %d\n", totalSize);
#endif

        loopcount = totalSize/bsize;
        /* Allocate memory for the buffPtr, size = bsize */
        buffPtr = (char * ) perfAllocateBuffer(bsize * (sizeof(char)));
        if (NULL == buffPtr)
        {
            perror("buffPtr");
            return ST_FAIL;
        }

        /* Open the descriptor */
        //fdes = open("/dev/i2c/0", O_RDWR);
        fdes = open((const char *)dev_node, O_RDWR);
        if(-1 == fdes)
        {
            perror("\n open ");
            break;
        }
        /*   Set the operating mode */        
        result = ioctl(fdes,I2C_TENBIT,addrFmt);
        if (result < 0)
        {
            perror("Ioctl I2C_TENBIT failed");
            close(fdes);
            break;
        }    
        /* Set the Slave address */
        result = ioctl(fdes,I2C_SLAVE,slaveAddr);
        if (result < 0)
        {
            perror("Ioctl I2C_SLAVE failed");
            close(fdes);
            break;
        }

       /* Start CPU Load calcaulation */ 
        startCpuLoadMeasurement (&cpuStatusId);

        /* Start the Timer */
        startTimer(&startTime);
        /* Call the read function to read from EEPROM*/
        result =  readfromeeprom(fdes,bsize,loopcount,buffPtr);
        if (result < 0)
        {
            perror("readfromeeprom failed");
            close(fdes); 
            break;
        }
        /* Stop the Timer and get the usecs elapsed */
        elapsedUsecs = stopTimer (&startTime);

        /* Get CPU Load figures */ 
        percentageCpuLoad = stopCpuLoadMeasurement (&cpuStatusId);

        /* Close the descriptor*/ 
        result = close(fdes);
        if(-1 == result)
        {
            perror("\n close ");
            break ;
        }


        /* Get the time stamp after the operation */
        calc = (totalSize*10000/elapsedUsecs) *100;
        calc = (calc* BYTE_TO_BIT_CONV)/BIT_TO_KBIT_CONV;

#ifndef AUTOMATION
        /* print the difference */
        PERFLOG("\n\rthroughputI2cRead(), completed in %ld microseconds\n",
                elapsedUsecs);
        PERFLOG("throughputI2cRead(), completed in %f  Kbits/sec \r\n",(calc));
#else
        printf("I2C: Read: Duration in uSec: %ld\n", elapsedUsecs);
        printf("I2C: Read: Kbits/Sec: %f\n", calc);
#endif

        if((percentageCpuLoad >= 0) && (percentageCpuLoad <= 100))
            printf("I2C: Read: percentage cpu load: %.2f%%\n", percentageCpuLoad);

    }while (0);
    /* Free  memory for the buffPtr, size = bsize */

    if (NULL != buffPtr)
    {
        perfFreeBuffer(buffPtr);
    }
    return result;
}


/* vim: set ts=4 sw=4 tw=80 et:*/
