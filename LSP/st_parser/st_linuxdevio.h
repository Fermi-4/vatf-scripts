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

/** \file   ST_FSTestsDev.h
    \brief  Hibari ARM PSP System Testing  System Call Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Anand Patil
    @version    0.1 - Created 
 */



#ifndef _ST_FSTESTSDEV_H
#define _ST_FSTESTSDEV_H

#include "st_linuxdev.h"
#include <sys/time.h>

#define FILE_NAME_LENGTH 200

//#define ST_BuffSize       512*50

void ST_FS_create();
void ST_FS_open();
void ST_FS_close();
void ST_FS_read();
void ST_FS_write();
void ST_FS_getstat();
void ST_FS_seek();
void ST_FS_Ioctl();
Int8 ST_WriteTo_SysFile(char * fileName, Uint32 size, Uint32 writeFlag);
Int8 ST_ReadFrom_SysFile(char * fileName,Uint32 size);

#endif

