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
*******************************************************************************
 \file   ST_Nand_Parser.h
 \brief  DaVinci ARM PSP System Testing Functionalities related to NAND driver
    for Linux OS Support.

   
    NOTE: THIS FILE IS PROVIDED FOR INITIAL DEMO RELEASE AND MAY BE
          REMOVED AFTER THE DEMO OR THE CONTENTS OF THIS FILE ARE SUBJECT 
          TO CHANGE. 

    (C) Copyright 2006, Texas Instruments, Inc

    @author     Pradeep K
    @version    0.1 - Created	19/Oct/2005

    @author 	Anand Patil
    @version    0.2 - Created	10/Apr/2006
********************************************************************************/

#ifndef _TEST_NANDPARSER_H_
#define _TEST_NANDPARSER_H_

#include <linux/hdreg.h>
#include "st_common.h"
#include <stdint.h>
#include <mtd/mtd-abi.h>
#include "st_common.h"
#include "st_linuxdev.h"
#include "st_fstests.h"
#include "st_blk_dev.h"

void ST_NAND_Ioctl(void);
void ST_Nand_stress(void);
void ST_NAND_MountFormat(void);



#endif /* _TEST_NFCPARSER_H_ */
    
