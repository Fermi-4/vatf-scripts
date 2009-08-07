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
 *  \file   stCpuLoad.h
 *
 *  \brief  This file has declaration of the structure for cpu load status and functions used for it
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \history    0.1     Surendra Puduru     Created
 */

#include <stDefines.h>

#define CPULOAD_NOT_ENABLED 101

typedef struct _procStat
{
	unsigned long long user;
	unsigned long long nice;
	unsigned long long system;
	unsigned long long idle;
	unsigned long long iowait;
	unsigned long long irq;
	unsigned long long softirq;
	unsigned long long steal;
	unsigned long long user_rt;
	unsigned long long system_rt;
}procStat;

extern int enableCpuLoad;

typedef struct _procStat ST_CPU_STATUS_ID; 

/**
 * @brief       Get the current Status from the Cpu.
 *
 * @param[inout]   CpuStatusStart        The #ST_CPU_STATUS_ID to update the cpu status to.
 *
 */
extern void startCpuLoadMeasurement(INOUT ST_CPU_STATUS_ID * CpuStatusStart);

/**
 * @brief       Stop CPU Load measurement and return % CPU Load. Returns -1 on error.
 *
 * @param[in]   CpuStatusStart        The #ST_CPU_STATUS_ID to get the cpu start status from.
 *
 */
extern float stopCpuLoadMeasurement(IN const ST_CPU_STATUS_ID * CpuStatusStart);


