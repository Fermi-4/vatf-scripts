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

/** \file   st_pwm.h
    \brief  DM350/ DaVinci ARM Linux PSP System Testing PWM Tests

    (C) Copyright 2007, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created -  Linux UART Test Code Integration
                
 */
#ifndef __ST_PWM__H
#define __ST_PWM__H

#include "st_common.h"
#include "st_automation_io.h"
#include <asm-arm/arch-davinci/davinci_pwm.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>

#define INSTANCE0	"/dev/davinci_pwm0"
#define INSTANCE1	"/dev/davinci_pwm1"
#define INSTANCE2	"/dev/davinci_pwm2"
#define INSTANCE3	"/dev/davinci_pwm3"

#define PWMMODE		O_RDWR
#define PWMRDWR	O_RDWR							/* Read and Write */

#define PWM_SUCCESS 	0
#define PWM_FAILURE 	-1

#define PWM_NULL 		0


#define PWM_CACHE_LINE_SIZE_IN_BYTES    32 /* cache line size in bytes */



void pwm_parser(void);
void test_pwm_ioctl_parser(void);

void test_pwm_driver_update(void);
void test_pwm_update_driver_instance(void);

void test_pwm_driver_open(void);
void test_pwm_driver_close(void);
void test_pwm_driver_general_open(void);
void test_pwm_driver_stability(void);

void test_pwm_driver_set_mode(void);
void test_pwm_driver_set_period(void);
void test_pwm_driver_set_pulse_width(void);
void test_pwm_driver_set_repeat_count(void);
void test_pwm_driver_start(void);
void test_pwm_driver_stop(void);
void test_pwm_driver_set_idle(void);
void test_pwm_driver_set_first_phase(void);

#endif  
