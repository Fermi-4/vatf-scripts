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
**|         Copyright (c) 1998-2004 Texas Instruments Incorporated          |**
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
 *  \file   stBufferMgr.h
 *
 *  \brief  This file exports all the buffer management functions 
 *          All tests should use these functions rather than malloc.
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \author     Siddharth Heroor
 *
 *  \note       
 *              
 *
 *  \history    0.1     Siddharth Heroor   Created
 */
  

#ifndef _ST_BUFFER_MGR_H_
#define _ST_BUFFER_MGR_H_

/* Standard include files */
#include <stdlib.h>
#include <stDefines.h>

/*******************************************************************************
 * Function             : st_alloc_mem
 * Functionality        : To allocate memory
 * Input Params         : size    - Memory size to be allocated
 *                      : mem_ptr - variable which will hold address allocated
 * Return Value         : 0 if success and -1 incase of error
 ******************************************************************************/
Int32 st_alloc_mem (IN Uint32 size, INOUT void ** mem_ptr);

/*******************************************************************************
 * Function             : st_free_mem
 * Functionality        : To free the allocate memory
 * Input Params         : mem_ptr - variable which will hold address allocated
 * Return Value         : Zero
 ******************************************************************************/
Int32 st_free_mem (IN void * mem_ptr);
 


/*******************************************************************************
 * Function             : st_alloc_aligned_mem
 * Functionality        : To allocate memory and align it
 * Input Params         : size       - Memory size to be allocated
 *                      : alignment  - Value for which memory is to be aligned
 *                      : mem_ptr    - variable which hold address allocated
 *                      : MEM_Handle - Variable which will hold aligned address
 * Return Value         : 0 if successful and -1 incase of failure
 ******************************************************************************/
Int32 st_alloc_aligned_mem (IN Uint32 size, IN Uint32 alignment, INOUT void **
mem_ptr, INOUT void ** MEM_Handle);



/*******************************************************************************
 * Function             : st_free_aligned_mem
 * Functionality        : To free the aligned memory
 * Input Params         : MEM_Handle - variable which will hold aligned address 
 * Return Value         : Zero
 ******************************************************************************/
Int32 st_free_aligned_mem (IN void * MEM_Handle);


/* This function will be eliminated in future, it is kept now since it is used
 * by perfTest *
 * Allocate Buffer */
void * perfAllocateBuffer(size_t size);

/* This function will be eliminated in future, it is kept now since it is used
 * by perfTest *
 * Free Buffer */
void perfFreeBuffer(void * perfBuffer);

#endif /* _ST_BUFFER_MGR_H_ */

/* vim: set ts=4 sw=4 tw=80 et:*/

