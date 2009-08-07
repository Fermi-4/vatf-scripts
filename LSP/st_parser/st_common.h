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

/** \file   ST_Common.h
    \brief  System Test Common Defines

    This file contains the common defines used by system test

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Shivanand Pujar, Aniruddha, Anand, Baalaaji
    @version    0.1 	01-Aug-2005	- Created
                
**/

#ifndef ST_COMMON
#define ST_COMMON

#include <stdio.h>
#include <stdarg.h>
#include <fcntl.h>
#include "st_automation_io.h"
#include "st_types.h"

//With ccs stdout can be used
#define STLog	printTerminalf

//Standard return values from any ST wrapper
#define ST_PASS 0
#define ST_FAIL 1

#define CMD_LENGTH 50

#define ST_APPEND	1
#define ST_WRITE	0
#define ST_IDENTICAL	2
#define ST_NOT_IDENTICAL 3

#define ST_TEST_TASK_PRIO        10
#define ST_TEST_TASK_STK_SIZE    0x2000

#define PSP_WAIT_FOREVER -1

#define ST_UART_PRINT_IO_REPORTING	1
#define ST_UART_STORE_IO_REPORTING	0

/* Added on 26/12/2005 */
#define VPBE_NUMBER_OF_FRAMEBUFFERS 4

#define VPBE_VID0_FRAMEBUFFER 1
#define VPBE_VID1_FRAMEBUFFER 3

#define VPBE_OSD0_FRAMEBUFFER 0
#define VPBE_OSD1_FRAMEBUFFER 2

int ST_main_parser(void);
void usage(void);
void ST_Parser(void);
Int8 ST_LinuxDevErrnum(char * Fn);
Int32 ST_mknod(const char *pathname, mode_t mode, dev_t dev);
int ST_System(char *string);


//External function refrences

extern void atahdd_parser(void);
extern void nand_parser(void);
extern void uart_parser(void);
//extern void spi_parser(void);
extern void audio_parser(void);
extern void i2c_parser(void);
extern void mmcsd_parser(void);
extern void fs_parser(void);
extern void vpbe_parser(void);
extern void vpfe_parser(void);
extern void initTaskArray(void);
extern int ST_EntryPoint(void); 
extern void WDT_parser(void);
extern void timer_parser(void);


#endif
