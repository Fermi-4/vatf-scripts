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
 *  \file   stTimer.h
 *
 *  \brief  This file implements the timer wrappers
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     K.R.Baalaaji     Created
 *  \           0.2     Surendra Puduru     Modified to start and stop timer
 */

#ifndef _ST_TIMER_H_
#define _ST_TIMER_H_

/* Standard include files */
#include <sys/time.h>
#include <stdlib.h>

#include <stDefines.h>

typedef struct timeval ST_TIMER_ID;

/* Initialize Timer module */
void initTimerModule(void);


/* Get the current time, update the pTimerHandle */
void getTime(INOUT ST_TIMER_ID * pTimerHandle);


/* Start the timer and update the pTimerHandle */
void startTimer(INOUT ST_TIMER_ID * pTimerHandle);


/* Stop the Timer and return the elapsed usecs  */
unsigned long stopTimer(IN ST_TIMER_ID * pTimerHandle);


#endif /* _ST_TIMER_H_ */

/* vim: set ts=4 sw=4 tw=80 et:*/
