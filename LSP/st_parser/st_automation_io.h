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

/** \file   ST_Automation_IO.h
    \brief  ST Test UART based IO wrappers for automation

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Shivanand Pujar, Aniruddha, Anand, Baalaaji
    @version    0.1 	01-Aug-2005	- Created
                
 */

#ifndef _PARSER_COMMON_H
#define _PARSER_COMMON_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <stdarg.h>
#include "st_common.h"
void printTerminalf(const char *fmt, ...);
void scanTerminalf(const char *fmt, ...);
void readString(char *cmd);
int isspace(char space);
void itoa(int n, char * s);
void itox(unsigned int x, char * s);
int st_atoi(char * s);
void ST_Open_UART(void);
void ST_Close_UART(void);
char readChar(void);

#endif
