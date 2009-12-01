/*
 * perfTimer.c 
 * 
 * This file implements the timer wrappers
 * 
 * 
 *
 * Copyright (C) 2009 Texas Instruments Incorporated - http://www.ti.com/ 
 * 
 * 
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions 
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright 
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the 
 *    documentation and/or other materials provided with the   
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/interrupt.h>
#include <linux/moduleparam.h>
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

MODULE_AUTHOR("Texas Instruments");
MODULE_LICENSE("GPL");

/* vim: set ts=4 sw=4 tw=80 et:*/
