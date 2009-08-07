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
 *  \file   stTimer.c
 *
 *  \brief  This file implements the timer wrappers
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     K.R.Baalaaji     Created
 *  \           0.2     Surendra Puduru  Modified to start and stop timer
 */


#include <stDefines.h>
#include <stLog.h>
#include <stTimer.h>

/* Use this define to calibrate the delta value */
#define BASE_NUM_TRIALS 10

/* Delta in microseconds to be adjusted */
static int deltaTime = 0;

/* Return the difference between 2 timeval structs 
 * in microseconds
 */ 
static long diffTime(IN ST_TIMER_ID * pTimeStart, IN ST_TIMER_ID * pTimeEnd);

/* Return the time elapsed between 2 timeval structs 
 * in microseconds
 */ 
static long elapsedTime(IN ST_TIMER_ID * pTimeStart, IN ST_TIMER_ID * pTimeEnd);

/* Initialize Timer module */
void initTimerModule(void)
{
    ST_TIMER_ID startTime;
    ST_TIMER_ID endTime;
    int i = 0;

    /* Already calibrated */
    if(0 != deltaTime) return; 
    
    /* We need to average deltaTime out */
    for(i = 0; i < BASE_NUM_TRIALS; i++)
    {
        startTimer(&startTime);
        startTimer(&endTime);  

        deltaTime += diffTime(&startTime, &endTime);
    }

    deltaTime = deltaTime / BASE_NUM_TRIALS;
    
//    PERFLOG("Delta : %ld\n", deltaTime);
}

/* Get the current time, update the pTimerHandle */
void getTime(INOUT ST_TIMER_ID * pTimerHandle)
{
    startTimer(pTimerHandle);
}

/* Start the timer and update the pTimerHandle */
void startTimer(INOUT ST_TIMER_ID * pTimerHandle)
{
    ST_TIMER_ID * pStartTimeVal = pTimerHandle;
	
    gettimeofday(pStartTimeVal, NULL);

    #if LOG_TIME
    PERFLOG("timeVal.sec %ld\n", pStartTimeVal->tv_sec);
    PERFLOG("timeVal.usec %ld\n", pStartTimeVal->tv_usec);
    #endif
}

/* Stop the Timer and return the elapsed usecs  */
unsigned long stopTimer(IN ST_TIMER_ID * pTimerHandle)
{
    ST_TIMER_ID * pStartTimeVal = pTimerHandle;
    ST_TIMER_ID stopTimeVal;
    gettimeofday(&stopTimeVal, NULL);

    #if LOG_TIME
    PERFLOG("timeVal.sec %ld\n", stopTimeVal.tv_sec);
    PERFLOG("timeVal.usec %ld\n", stopTimeVal.tv_usec);
    #endif
    return((unsigned long)elapsedTime(pStartTimeVal, &stopTimeVal));
}

/* Return the difference between 2 timeval structs 
 * in microseconds
 */ 
static long diffTime(IN ST_TIMER_ID * pTimeStart, IN ST_TIMER_ID * pTimeEnd)
{
    return ((pTimeEnd->tv_sec - pTimeStart->tv_sec) * 1000000u 
            + pTimeEnd->tv_usec - pTimeStart->tv_usec);
}

/* Return the time elapsed between 2 timeval structs 
 * in microseconds
 */ 
static long elapsedTime(IN ST_TIMER_ID * pTimeStart, IN ST_TIMER_ID * pTimeEnd)
{
    return (diffTime(pTimeStart, pTimeEnd) - deltaTime);
}


/* vim: set ts=4 sw=4 tw=80 et:*/

