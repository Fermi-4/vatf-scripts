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
 **|         Copyright (c) 1998-2008 Texas Instruments Incorporated           |**
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
 *  \file   stCpuLoad.c
 *
 *  \brief  This file implements the functions that evaluates the CPU Status and through which
 *  CPU Load is measured
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \history    0.1     Surendra Puduru     Created
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#include <stCpuLoad.h>

/*
 * Moving definition into GENDEFS and makefile
#define CPULOAD_DEBUG
*/

int enableCpuLoad = FALSE;

/******************************************************************************
 * getcpuStatus
 ******************************************************************************/
/**
 * @brief       Get the current Status from the Cpu.
 *
 * @param[in]   cpuStatus        The #ST_CPU_STATUS_ID to update the cpu status to.
 *
 */
static void getcpuStatus(OUT ST_CPU_STATUS_ID *cpuStatus)
{
    static FILE *fp = NULL;
    int num;
    char buf[256+64];

    if (cpuStatus == NULL)
    {
        printf("error: Null pointer passed to CpuLoadMeasurement().");
        return;
    }

    if (!fp)
    {
        if (!(fp = fopen("/proc/stat", "r")))
	{
            printf("Failed /proc/stat open: %s", strerror(errno));
	    return;
	}
    }
    rewind(fp);
    fflush(fp);

    /* first value the last slot with the cpu summary line */
    if (!fgets(buf, sizeof(buf), fp))
    {
        printf("failed /proc/stat read");
        return;
    }

    /* populate evrying to 0 as we are not sure about the support in the kernel */
    cpuStatus->user = 0;
    cpuStatus->nice = 0;
    cpuStatus->system = 0;
    cpuStatus->idle = 0;
    cpuStatus->iowait = 0;
    cpuStatus->irq = 0;
    cpuStatus->softirq = 0;
    cpuStatus->steal = 0;
    cpuStatus->user_rt = 0;
    cpuStatus->system_rt = 0;

    num = sscanf(buf, "cpu %Lu %Lu %Lu %Lu %Lu %Lu %Lu %Lu %Lu %Lu",
                 &(cpuStatus->user),
                 &(cpuStatus->nice),
                 &(cpuStatus->system),
                 &(cpuStatus->idle),
                 &(cpuStatus->iowait),
                 &(cpuStatus->irq),
                 &(cpuStatus->softirq),
                 &(cpuStatus->steal),
                 &(cpuStatus->user_rt),
                 &(cpuStatus->system_rt)
                );
    if (num < 4)
    {
        printf("failed /proc/stat read");
        return;
    }
    
    return;
}

/******************************************************************************
 * getCpuLoad
 ******************************************************************************/
/**
 * @brief       Get the Load from the Cpu.
 *
 * @param[in]   cpuStatusStart       The #ST_CPU_STATUS_ID to get the cpu start status from.
 * @param[in]   cpuStatusStop        The #ST_CPU_STATUS_ID to get the cpu stop status from.
 * @param[out]  cpuLoad              The cpu load is returned here. Returns -1 on error.
 *
 */
static float getCpuLoad(IN ST_CPU_STATUS_ID cpuStatusStart, IN ST_CPU_STATUS_ID cpuStatusEnd)
{
    ST_CPU_STATUS_ID cpuStatusDiff = {0,};
    float cpuLoad = 0, totalTime = 0, idleTime = 0;

    cpuStatusDiff.user      = cpuStatusEnd.user      - cpuStatusStart.user;
    cpuStatusDiff.nice      = cpuStatusEnd.nice      - cpuStatusStart.nice; 
    cpuStatusDiff.system    = cpuStatusEnd.system    - cpuStatusStart.system;
    cpuStatusDiff.idle      = cpuStatusEnd.idle      - cpuStatusStart.idle;
    cpuStatusDiff.iowait    = cpuStatusEnd.iowait    - cpuStatusStart.iowait; 
    cpuStatusDiff.irq       = cpuStatusEnd.irq       - cpuStatusStart.irq; 
    cpuStatusDiff.softirq   = cpuStatusEnd.softirq   - cpuStatusStart.softirq; 
    cpuStatusDiff.steal     = cpuStatusEnd.steal     - cpuStatusStart.steal; 
    cpuStatusDiff.user_rt   = cpuStatusEnd.user_rt   - cpuStatusStart.user_rt; 
    cpuStatusDiff.system_rt = cpuStatusEnd.system_rt - cpuStatusStart.system_rt; 

    totalTime = (float)(cpuStatusDiff.user
                       +cpuStatusDiff.nice
                       +cpuStatusDiff.system
                       +cpuStatusDiff.idle
                       +cpuStatusDiff.iowait
                       +cpuStatusDiff.irq
                       +cpuStatusDiff.softirq
                       +cpuStatusDiff.steal
                       +cpuStatusDiff.user_rt
                       +cpuStatusDiff.system_rt
                       );
    idleTime = (float)cpuStatusDiff.idle;
    /* IOwait should not be accounted in CPU perspective, refer: http://kbase.redhat.com/faq/FAQ_80_5637.shtm */
    idleTime += (float)cpuStatusDiff.iowait;
    /* steal should not be accounted in CPU perspective, as steal is used for virtualisation */
    idleTime += (float)cpuStatusDiff.steal;

    if(totalTime)
    {
         cpuLoad   = ((totalTime - idleTime) * 100) / totalTime;
    }
    else
    {
        printf("\n !!! Warning: Unable to calculate cpuLoad,                              !!! \n");
        printf("\n !!!          total time of exectuiton is too low (lesser than a jiffy) !!! \n");
        cpuLoad = -1;
    }

#ifdef CPULOAD_DEBUG
    printf("\n");
    printf("--------------------------------------------------------\n");
    printf("          |              Time(in jiffies)               \n");
    printf("CPU state |---------------------------------------------\n");
    printf("          |       <start>      <end>     <diff>         \n");
    printf("--------------------------------------------------------\n");
    printf("user      |    %10Lu %10Lu %10Lu\n", cpuStatusStart.user,      cpuStatusEnd.user,      cpuStatusDiff.user);
    printf("nice      |    %10Lu %10Lu %10Lu\n", cpuStatusStart.nice,      cpuStatusEnd.nice,      cpuStatusDiff.nice);
    printf("system    |    %10Lu %10Lu %10Lu\n", cpuStatusStart.system,    cpuStatusEnd.system,    cpuStatusDiff.system);
    printf("idle      |    %10Lu %10Lu %10Lu\n", cpuStatusStart.idle,      cpuStatusEnd.idle,      cpuStatusDiff.idle);
    printf("iowait    |    %10Lu %10Lu %10Lu\n", cpuStatusStart.iowait,    cpuStatusEnd.iowait,    cpuStatusDiff.iowait);
    printf("irq       |    %10Lu %10Lu %10Lu\n", cpuStatusStart.irq,       cpuStatusEnd.irq,       cpuStatusDiff.irq);
    printf("softirq   |    %10Lu %10Lu %10Lu\n", cpuStatusStart.softirq,   cpuStatusEnd.softirq,   cpuStatusDiff.softirq);
    printf("steal     |    %10Lu %10Lu %10Lu\n", cpuStatusStart.steal,     cpuStatusEnd.steal,     cpuStatusDiff.steal);
    printf("user_rt   |    %10Lu %10Lu %10Lu\n", cpuStatusStart.user_rt,   cpuStatusEnd.user_rt,   cpuStatusDiff.user_rt);
    printf("system_rt |    %10Lu %10Lu %10Lu\n", cpuStatusStart.system_rt, cpuStatusEnd.system_rt, cpuStatusDiff.system_rt);
    printf("--------------------------------------------------------\n");
    printf("                         totalTime = %10Lu*10ms\n", (unsigned long long)totalTime);
    printf("   idleTime == (idle+iowait+steal) = %10Lu*10ms\n", (unsigned long long)idleTime);
    printf("--------------------------------------------------------\n");
    printf("cpuLoad == (totalTime-idleTime)*100/totalTime = %3.2f%% \n", cpuLoad);
    printf("--------------------------------------------------------\n");
#endif
    return cpuLoad;
}

/******************************************************************************
 * startCpuLoadMeasurement
 ******************************************************************************/
/**
 * @brief       Get the current Status from the Cpu.
 *
 * @param[inout]   cpuStatusStart        The #ST_CPU_STATUS_ID to update the cpu status to.
 *
 */
void startCpuLoadMeasurement(OUT ST_CPU_STATUS_ID * cpuStatusStart)
{
    if(enableCpuLoad)
    {
        getcpuStatus(cpuStatusStart);
    }
    return;
}

/******************************************************************************
 * stopCpuLoadMeasurement
 ******************************************************************************/
/**
 * @brief       Stop CPU Load measurement and return % CPU Load. Returns -1 on error.
 *
 * @param[in]   cpuStatusStart        The #ST_CPU_STATUS_ID to get the cpu start status from.
 *
 */
float stopCpuLoadMeasurement(IN const ST_CPU_STATUS_ID * cpuStatusStart)
{
    ST_CPU_STATUS_ID cpuStatusEnd;

    if(enableCpuLoad)
    {
        getcpuStatus(&cpuStatusEnd);
        return (getCpuLoad(*cpuStatusStart, cpuStatusEnd));
    }
    else
    {
        return (CPULOAD_NOT_ENABLED);
    }
}



/* vim: set ts=4 sw=4 tw=80 et:*/
