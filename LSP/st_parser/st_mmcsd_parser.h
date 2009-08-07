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
**|         Copyright (c) 1998-2004 Texas Instruments Incorporated           |**
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
**+--------------------------------------------------------------------------+**/
/********************************************************************************

   \file   ST_Mmcsd_Parser.h

   \brief  Davinic ARM PSP System Testing Functionalities related to MMC/SD driver
    for Linux OS Support.

 

   

    NOTE: THIS FILE IS PROVIDED FOR INITIAL DEMO RELEASE AND MAY BE

          REMOVED AFTER THE DEMO OR THE CONTENTS OF THIS FILE ARE SUBJECT 

          TO CHANGE. 

 

    (C) Copyright 2005, Texas Instruments, Inc

 

    @author     Anand Patil

    @version    0.1 - Created        03/10/2005

******************************************************************************/


#ifndef _TEST_MMCSDPARSER_H_

#define _TEST_MMCSDPARSER_H_


#include "st_common.h"
#include "st_linuxdev.h"
#include "st_fstests.h"
#include "st_blk_dev.h"

/* Declarations of Extern Refrences */


/* Local Definitions */
void mmcsd_parser(void);
void ST_MMC_stress(void);
void ST_MMC_MountFormat(void);



#endif /* _TEST_MMCSDPARSER_H_ */
    
