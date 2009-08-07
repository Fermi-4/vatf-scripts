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

/** \file   ST_LinuxDev.h
    \brief  System Test wrappers for LinuxDev APIs

    This file contains the declarations for LinuxDev APIs

    (C) Copyright 2004, Texas Instruments, Inc

    @author     Anand PAtil 
    @version    0.1
                
**/

#ifndef _ST_LinuxDev_
#define _ST_LinuxDev_

#include "st_common.h"
#include "st_types.h"
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/mount.h>
#include <fcntl.h>

#ifndef _LF_STAT_
#define  _LF_STAT_
typedef  struct stat LF_STAT;
#endif

Int8 ST_Create(char * fileName, mode_t mode, Int32 * fd);
Int8 ST_Open(char * fileName, Int32 flag, Int32 * fd);
Int8 ST_Close(Int32 fd);
Int8 ST_Sync(Int32 fd);
Int8 ST_Read(Int32 fd,Ptr buffer,Uint32 bytes);
Int8 ST_Write(Int32 fd,Ptr buffer,Uint32 bytes);
Int8 ST_Seek(Int32 fd, Uint32 offset, Uint32 origin);
Int8 ST_Status(Int32 fd, LF_STAT * fstatInst);
Int8 ST_Ioctl(Int32 fd, int req, Ptr arg);
#endif

