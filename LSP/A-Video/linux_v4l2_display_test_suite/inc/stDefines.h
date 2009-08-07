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
 **|         Copyright (c) 1998-2008 Texas Instruments Incorporated           |**
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

/** \file   stDefines.h

  This file contains the standard definitions used in the performance test suite

  (C) Copyright 2008, Texas Instruments, Inc

  \author     (Reusing from LPTB)
  \version    1.0
 */
/*******************************************************************************/
#ifndef _ST_DEFINES_H_
#define _ST_DEFINES_H_


/* Use these defines to improve readability */

#define IN 
#define OUT
#define INOUT
#define OPT

typedef void * Ptr;

typedef signed char         Int8 ;      /*  8 bit value */
typedef signed short int    Int16 ;     /* 16 bit value */
typedef signed long  int    Int32 ;     /* 32 bit value */

typedef unsigned char       Uint8 ;     /*  8 bit value */
typedef unsigned short int  Uint16 ;    /* 16 bit value */
typedef unsigned long  int  Uint32 ;    /* 32 bit value */

typedef short int           Bool ;      /* 16 bit value */

#endif /* _ST_DEFINES_H_ */

/* vim: set ts=4 sw=4 tw=80 et:*/

