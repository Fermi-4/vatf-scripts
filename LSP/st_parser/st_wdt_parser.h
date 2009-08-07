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
**|         Copyright (c) 1998-2006 Texas Instruments Incorporated           |**
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

/** \file   ST_WDT_Parser.h
    \brief  Watch Dog Timer Test Functionalities  for DaVinci on Linux

    (C) Copyright 2006, Texas Instruments, Inc

    @author     Anand Patil
    @version    0.1 
    @date 		10/12/2006
                                
 */

#ifndef _ST_WDT_Parser_
#define _ST_WDT_Parser_


#include <sys/types.h>
#include <sys/stat.h>
#include <linux/watchdog.h>
#include "st_linuxdevio.h"
#include "st_common.h"


/*Default Timout for WDT */

#define DEFAULT_TIMEOUT 60

/** Declarations of the WDT Test Functions used  **/

void ST_WDT_Open(void);
void ST_WDT_Close(void);
void ST_WDT_Features(void);
void ST_WDT_GetTimeout(void);
void ST_WDT_SetTimeout(void);
int  ST_WDT_Alive(void);
int  ST_WDT_Write(void);
int  ST_WDT_Seek(void);
void ST_WDT_PingTask(void);
void Ping_on_WDT( int swtch, unsigned int count );


#endif

