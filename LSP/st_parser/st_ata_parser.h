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


/** \file   ST_ATA_Parser.h
    \brief  ATA Test Definitions for DaVinci

    \platform Linux 2.6 (MVL)

    (C) Copyright 2006, Texas Instruments, Inc

    @author     Anand Patil
                
 */

#ifndef _ATA_Parser_
#define _ATA_Parser_

#include <linux/hdreg.h> 
#include "st_common.h"
#include "st_fstests.h"
#include "st_linuxdev.h"
#include "st_blk_dev.h"

/* Local Definitions */

void ST_ATA_stress();
int ST_ATA_IOCTL(int req,Ptr arg);
void ST_ATA_SetAdressing();
void ST_ATA_GetAdressing();
void ST_ATA_Opmode(void);

#endif

