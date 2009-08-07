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
 *  \file   perfTimer.c
 *
 *  \brief  This file implements the timer wrappers
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     Srinivas.B.N     Created
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/interrupt.h>
#include <asm/io.h>
#include <asm/arch-davinci/memory.h>
#include <linux/moduleparam.h>
#include <asm/arch/edma.h>
#include <linux/sysctl.h>
#include <linux/mm.h>

#include "kStTimer.h"

/*** DEFINE TIMER_TEST IF YOU WANT TO TEST YOUR TIMER API ***/

#define BASE_NUM_TRIALS 10


static void perf_Timer_init(void);
static void perf_Timer_exit(void);
static u32 diffTime(struct timeval * timeStart, struct timeval * timeEnd);

static int deltaTime;
static struct timeval startTime;
static struct timeval endTime;


/* Initialize Timer module */
static void perf_Timer_init(void)
{
    int i = 0;

    /* calibrate */
    deltaTime = 0;
    /* We need to average out the calibration value */
    for(i = 0; i < BASE_NUM_TRIALS; i++)
    {
        do_gettimeofday(&startTime);
        do_gettimeofday(&endTime);  
        deltaTime += diffTime(&startTime, &endTime);
    }
    deltaTime = deltaTime / BASE_NUM_TRIALS;
    printk("Delta : %d\n", deltaTime);

    return;
}


#define LOG_TIME 0
void start_Timer(void)
{
    do_gettimeofday(&startTime);
#if LOG_TIME
    printk("startTime.sec %d\n", startTime.tv_sec);
    printk("startTime.usec %d\n", startTime.tv_usec);
#endif

}

u32 stop_Timer(void)
{
    u32 usecs;
    do_gettimeofday(&endTime);
#if LOG_TIME
    printk("endTime.sec %d\n", endTime.tv_sec);
    printk("endTime.usec %d\n", endTime.tv_usec);
#endif
    usecs = diffTime(&startTime, &endTime);
    usecs -= deltaTime; /* Compensation for calibrated value */
    return usecs;
}

static u32 diffTime(struct timeval * timeStart, struct timeval * timeEnd)
{
    return ((timeEnd->tv_sec - timeStart->tv_sec) * 1000000u 
            + timeEnd->tv_usec - timeStart->tv_usec);
}



/* Return the difference between 2 timeval structs 
 * in microseconds
 */ 
static void perf_Timer_exit(void)
{
    printk("\nPerf Timer:NOTIFY	:Exiting Performance timer\n");
}

EXPORT_SYMBOL(start_Timer);
EXPORT_SYMBOL(stop_Timer);

module_init(perf_Timer_init);
module_exit(perf_Timer_exit);

/* vim: set ts=4 sw=4 tw=80 et:*/
