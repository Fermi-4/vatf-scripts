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
******************************************************************************
 \file   ST_Nor_Parser.h
    \brief  System Test Definitions for NOR driver Davinci Platform .

  @Platform  Linux 
  
    NOTE: THIS FILE IS PROVIDED FOR INITIAL DEMO RELEASE AND MAY BE
          REMOVED AFTER THE DEMO OR THE CONTENTS OF THIS FILE ARE SUBJECT 
          TO CHANGE. 

    (C) Copyright 2006, Texas Instruments, Inc

    @author    Anand Patil
    @version    0.1 - Created	18/Oct/2006
    @history    Pulled from ST_Nand_Parser.c
******************************************************************************/

#ifndef _TEST_NORPARSER_H_
#define _TEST_NORPARSER_H_

#include <linux/hdreg.h>
#include "st_common.h"
#include <stdint.h>
#include <mtd/mtd-abi.h>
#include "st_common.h"
#include "st_linuxdev.h"
#include "st_fstests.h"
#include "st_blk_dev.h"

void  ST_NOR_Ioctl(void);
void ST_NOR_stress(void);
void ST_NOR_MountFormat(void);


#endif /* _TEST_NFCPARSER_H_ */
    
