/******************************************************************************
 **+-------------------------------------------------------------------------+**
 **|                            ****                                         |**
 **|                            ****                                         |**
 **|                            ******o***                                   |**
 **|                      ********_///_****                                  |**
 **|                      ***** /_//_/ ****                                  |**
 **|                       ** ** (__/ ****                                   |**
 **|                           *********                                     |**
 **|                            ****                                         |**
 **|                            ***                                          |**
 **|                                                                         |**
 **|         Copyright (c) 1998-2007 Texas Instruments Incorporated          |**
 **|                        ALL RIGHTS RESERVED                              |**
 **|                                                                         |**
 **| Permission is hereby granted to licensees of Texas Instruments          |**
 **| Incorporated (TI) products to use this computer program for the sole    |**
 **| purpose of implementing a licensee product based on TI products.        |**
 **| No other rights to reproduce, use, or disseminate this computer         |**
 **| program, whether in part or in whole, are granted.                      |**
 **|                                                                         |**
 **| TI makes no representation or warranties with respect to the            |**
 **| performance of this computer program, and specifically disclaims        |**
 **| any responsibility for any damages, special or consequential,           |**
 **| connected with the use of this program.                                 |**
 **|                                                                         |**
 **+-------------------------------------------------------------------------+**
 ******************************************************************************/

/** 
 *  \file   kPerfLog.h
 *  \brief  Common header file for kernel level logging
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \version  Author                Description
 *
 *    1.0     Nagabhushan Reddy     Created
 *
 */

#ifndef _KPERFLOG_H_
#define _KPERFLOG_H_


/*----------------------------------------------------------------------------
  Include Files
  ----------------------------------------------------------------------------*/

#include <asm/io.h>


/*----------------------------------------------------------------------------
  Define Macros
  ----------------------------------------------------------------------------*/

/* Macros used to enable different levels of logs */


/*Printing very minute detail log. print it only if required */
#define DBG_PRINT_TRC0(x) 

/* Enable the trace logs */
#define DBG_PRINT_TRC(x) printk x 


/* Enable the warning logs */
#define DBG_PRINT_WRG(x) printk("Warning Line: %d, File: %s - ", \
                                __LINE__, __FILE__); \
                         printk x ; 

/* Enable the error logs */
#define DBG_PRINT_ERR(x) printk("*ERROR* Line: %d, File: %s - ", \
	                            __LINE__, __FILE__); \
	                     printk x ;

#define DBG_PRINT_TST(x) printk x  /* Enable the test logs */


#endif  /* _ST_DEBUG_LOG_H_ */


/* vim: set ts=4 sw=4 tw=80 et:*/
