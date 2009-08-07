/*************************************************************************
**+--------------------------------------------------------------------+**
**|                                   ****                             |**
**|                                   ****                             |**
**|                                   ******o***                       |**
**|                             ********_///_****                      |**
**|                             ***** /_//_/ ****                      |**
**|                             ** ** (__/ ****                        |**
**|                             *********                              |**
**|                             ****                                   |**
**|                             ***                                    |**
**|                                                                    |**
**| Copyright (c) 1998-2005 Texas Instruments Incorporated             |**
**| ALL RIGHTS RESERVED                                                |**
**|                                                                    |**
**| Permission is hereby granted to licensees of Texas Instruments     |**
**| Incorporated (TI) products to use this computer program for sole   |**
**| purpose of implementing a licensee product based on TI products.   |**
**| No other rights to reproduce, use, or disseminate this computer    |**
**| program, whether in part or in whole, are granted.                 |**
**|                                                                    |**
**| TI makes no representation or warranties with respect to the       |**
**| performance of this computer program, and specifically disclaims   |**
**| any responsibility for any damages, special or consequential,      |**
**| connected with the use of this program.                            |**
**|                                                                    |**
**+--------------------------------------------------------------------+**
* FILE:   		ST_BLK_MultiTask.h
*
* Brief:  		MultiProcess and MultiThreading Test Definitions for Block Devices
*
* Platform: 	Linux 2.6
*
* Author: 	Anand Patil
*
*
*Comments:	Integrity of data is applications responsibility.
*			Modify the printfs, scanfs and function calls as per required
*			Change Process creation call as per OS (made as per LINUX)
*			For viewing this file use tab = 4 (se ts =4)
*
********************************************************************************/

/* Include required header files */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include<pthread.h>
#include "st_common.h"
#include "st_fstests.h"
#include "st_linuxfile.h"

/* Mode defines */
#define WRITEMODE				0
#define READMODE				1
#define WRITEREADMODE			2 
#define DEFAULT_MODE			2

/* Data size defines */
#define WRITEREADDATA					450
#define INCDATA							50
#define DEFAULT_PROCESS_NUM			5			/* Process number */
#define CHANNELNO						2
#define DATASIZE_MAX					10240
#define RAND_SLEEPMAX					5
#define MAX_THREAD						30
#define MAX_PROCESS					30
#define MAX_FILE_LENGTH				50

void ST_BLK_MultiThread_parser(void);
void ST_BLK_MultiProcess_parser(void);
static void ST_Multi_ProcThread_parser(void);
static void  writetest(void);
static void readtest(void);
static void writereadtest(void);

static unsigned int ST_getTask_id(int Thread_usage);




