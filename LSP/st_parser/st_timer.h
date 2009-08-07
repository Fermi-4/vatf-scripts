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
**|         Copyright (c) 1998-2005 Texas Instruments Incorporated           |**
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

/** \file   ST_Timer.h
    \brief  DaVinci ARM Linux PSP System Timer Tests Header

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created -  Linux Timer Test Code Header file 
                
 **/ 
#ifndef __ST_Timer__H
#define __ST_Timer__H

#include "st_common.h"
#include "st_automation_io.h"
#include "st_linuxdev.h"


#define TIMER_SUCCESS 	0
#define TIMER_FAILURE 	1

#define TIMER_NULL 		0
#define TIMER_FAIL 		-1



/***************************************************************************
 * Function			- timer_parser
 * Functionality	- Entry for timer tests.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void timer_parser(void);


/***************************************************************************
 * Function			- test_timer_gettime
 * Functionality	- Get the current time in micro-seconds.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_timer_gettime(void);
void test_timer_get_clock_sec(void);


/***************************************************************************
 * Function			- test_timer_gettime_sec
 * Functionality	- Get the current time in seconds.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_timer_gettime_sec(void);




/***************************************************************************
 * Function         - test_timer_settime
 * Functionality    - Set the current time in micro-seconds.
 * Input Params     - None
 * Return Value     - None
 * Note             - None
 ***************************************************************************
 */

void test_timer_settime(void);


/***************************************************************************
 * Function         - test_timer_settime_sec
 * Functionality    - Set the current time in seconds.
 * Input Params     - None
 * Return Value     - None
 * Note             - None
 ***************************************************************************
 */

void test_timer_settime_sec(void);










/***************************************************************************
 * Function			- test_timer_stress
 * Functionality	- Get time in a loop in micro-seconds.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_timer_stress(void);



/***************************************************************************
 * Function			- test_timer_stress_sec
 * Functionality	- Get time in a loop in seconds.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_timer_stress_sec(void);






/***************************************************************************
 * Function         - test_timer_loop_1min
 * Functionality    - Loop for 1 minute.
 * Input Params     - None
 * Return Value     - None
 * Note             - None
 ***************************************************************************
 */

void test_timer_loop_1min(void);




/***************************************************************************
 * Function         - test_timer_loop_1min_stress
 * Functionality    - Loop for 1 minute for specified loop count.
 * Input Params     - None
 * Return Value     - None
 * Note             - None
 ***************************************************************************
 */

void test_timer_loop_1min_stress(void);






/***************************************************************************
 * Function			- ST_Timer_MultiProcess_parser
 * Functionality	- To perform multi-process tests for timer.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void ST_Timer_MultiProcess_parser(void);


/***************************************************************************
 * Function			- ST_Timer_MultiThread_parser
 * Functionality	- To perform multi-threading tests for timer.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void ST_Timer_MultiThread_parser(void);


/*
 ***************************************************************************
 */


#endif  
