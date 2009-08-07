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
 *  \file   stBufferMgr.c
 *
 *  \brief  This file defines the buffer management functions.
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \author     Jayanthi Sri
 *
 *  \history    0.1   -  Jayanthi Sri - Initial draft
 */
  
/* Generic header files */
#include <stDefines.h>
#include <stBufferMgr.h>


/*************************************************************************************
 * Function             : st_alloc_mem
 * Functionality        : To allocate memory
 * Input Params         : size    - Memory size to be allocated
 *                      : mem_ptr - variable which will hold the address allocated
 * Return Value         : 0 if success and -1 incase of error
 **************************************************************************************/

Int32 st_alloc_mem (IN Uint32 size, INOUT void ** mem_ptr)
{
  Int32 status =0;

 *mem_ptr = (void *)malloc(size);
 if(NULL != *mem_ptr)
 {
  status = 0;
 }else{
  status = -1;
 }

 return status;
}

 

/*************************************************************************************
 * Function             : st_free_mem
 * Functionality        : To free the allocate memory
 * Input Params         : mem_ptr - variable which will hold the address allocated
 * Return Value         : Zero
 **************************************************************************************/

Int32 st_free_mem (IN void * mem_ptr)
{
    free(mem_ptr);
    return 0;
}
 


/*************************************************************************************
 * Function             : st_alloc_aligned_mem
 * Functionality        : To allocate memory and align it
 * Input Params         : size       - Memory size to be allocated
 *                      : alignment  - Value for which memory is to be aligned
 *                      : mem_ptr    - variable which will hold the address allocated
 *                      : MEM_Handle - Variable which will hold aligned address
 * Return Value         : 0 if successful and -1 incase of failure
 **************************************************************************************/

Int32 st_alloc_aligned_mem (IN Uint32 size, IN Uint32 alignment, INOUT void ** mem_ptr, INOUT void ** MEM_Handle)
{
 Int32 status;
 
 *mem_ptr = malloc(size);
 if(NULL != *mem_ptr)
 {
  status = 0;
 }else{
  status = -1;
 }
 
 *MEM_Handle = (Ptr)(((Uint32)((*mem_ptr + ((Uint32)alignment)) - 1u)) & (~(((Uint32)alignment) - 1u)));
 if(NULL != *MEM_Handle)
 {
  status = 0;
 }else{
  status = -2;
 }

  return status;
}



/*************************************************************************************
 * Function             : st_free_aligned_mem
 * Functionality        : To free the aligned memory
 * Input Params         : MEM_Handle - variable which will hold the alignes address 
 * Return Value         : Zero
 **************************************************************************************/

Int32 st_free_aligned_mem (IN void * MEM_Handle)
{
 free(MEM_Handle);
 return 0;
}


/* This function will be eliminated in future, it is kept now since it is used
 * by perfTest */

/*Allocate Buffer*/
void * perfAllocateBuffer(size_t size)
{
    return malloc(size);
}
/*
void * perfAllocateBuffer(size_t size)
{
    void *mem_ptr;
    int status =0 ;
    
    status = st_alloc_mem (size, &mem_ptr);
    if(status ==0)
    {
      return mem_ptr;
    }
    return status;
}
*/

/* This function will be eliminated in future, it is kept now since it is used
 * by perfTest */

/* Free a Buffer */
void perfFreeBuffer(void * perfBuffer)
{
    free(perfBuffer);
    return;
}
/*
void perfFreeBuffer(void * perfBuffer)
{
    int status =0 ;
    
    status = st_free_mem(perfBuffer);
    return status;
}
*/






/* vim: set ts=4 sw=4 tw=80 et:*/
