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
**+--------------------------------------------------------------------------+**
*******************************************************************************/

/** \file   ST_Types.h
 * \brief  Davinci ARM Types used by  different API's

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Anand Patil
    @version    0.1 - Created 
 */

#ifndef _ST_TYPES_H
#define _ST_TYPES_H

/*
    The purpose of this header file is to consolidate all the primitive "C"
    data types into one file. This file is expected to be included in the
    basic types file exported by other software components, for example CSL.
 */


typedef int		Bool;
#define TRUE		((Bool) 1)
#define FALSE		((Bool) 0)


typedef int             Int;
typedef unsigned int    Uns;    /* deprecated type */
typedef char            Char;
typedef char *          String;
typedef void *          Ptr;

/* unsigned quantities */
typedef unsigned int   	Uint32;
typedef unsigned short 	Uint16;
typedef unsigned char   Uint8;

/* signed quantities */
typedef int             Int32;
typedef short           Int16;
typedef char            Int8;




#endif /* _ST_TYPES_H*/

