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
 **|         Copyright (c) 1998-2007 Texas Instruments Incorporated           |**
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

/**
 *  \file    st_edma_memalloc.h
 *
 *  \brief   This file Tests A-Sync INCR mode transfer for DMA Channels
 *  
 *  \desc  It allocates source and destination buffers in kernel space and performes a Manual trigger on EDMA 
 *            channel and accomplishes the transfer
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1    Srinivas.B.N    Created
 */
#include "debugLog.h"

/*Require one set of buffer*/

#define ONE_BUFFER 1
#define TWO_BUFFERS 2


dma_addr_t dmaphyssrc1 = 0;
dma_addr_t dmaphysdest1 = 0;
dma_addr_t dmaphyssrc2 = 0;
dma_addr_t dmaphysdest2 = 0;

/*Buffers -Source and Destination*/
char  *srcBuff1;
char  *dstBuff1;
char  *srcBuff2;
char  *dstBuff2;

extern int st_memory_alloc(u32);
extern void st_memory_free(u32);


int st_memory_alloc(u32 num_buff)
 {

   if (ONE_BUFFER == num_buff || TWO_BUFFERS == num_buff)
	{
       srcBuff1 = dma_alloc_coherent (NULL,MAX_DMA_TRANSFER_IN_BYTES,&dmaphyssrc1,0);
       DBG_PRINT_TRC0(("\nEDMA:NOTIFY	:Source Buffer Address=0x%x",dmaphyssrc1));

	    if(NULL == srcBuff1)
      {
        return -ENOMEM;
      }

      dstBuff1 = dma_alloc_coherent (NULL,MAX_DMA_TRANSFER_IN_BYTES,&dmaphysdest1, 0); 
      DBG_PRINT_TRC0(("\nEDMA:NOTIFY	:Destination Buffer Address=0x%x",dmaphysdest1));

	  if(NULL == dstBuff1)
      {
        dma_free_coherent(NULL,MAX_DMA_TRANSFER_IN_BYTES, srcBuff1, dmaphyssrc1);
        return -ENOMEM;
      } 	
   	}
   
    if (TWO_BUFFERS == num_buff)
	{
      srcBuff2 = dma_alloc_coherent (NULL,MAX_DMA_TRANSFER_IN_BYTES,&dmaphyssrc2,0);
      DBG_PRINT_TRC0(("\nEDMA:NOTIFY	:Source Buffer Address=0x%x",dmaphyssrc2));
       if(NULL == srcBuff2)
       {
         dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, srcBuff1, dmaphyssrc1);
		     dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dstBuff1,dmaphysdest1);
	       return -ENOMEM;
        }
       dstBuff2 = dma_alloc_coherent (NULL, MAX_DMA_TRANSFER_IN_BYTES,&dmaphysdest2, 0); 
       DBG_PRINT_TRC0(("\nEDMA:NOTIFY	:Destination Buffer Address=0x%x",dmaphysdest2));
       if(NULL ==dstBuff2)
       {
        dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, srcBuff1, dmaphyssrc1);
		    dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dstBuff1,dmaphysdest1);
		    dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, srcBuff2, dmaphyssrc2);
	      return -ENOMEM;
       }
	}
 return 0;
		}
	


 void st_memory_free(u32 num_buff)
 {

    if (ONE_BUFFER == num_buff || TWO_BUFFERS == num_buff)
	{
        dma_free_coherent(NULL,MAX_DMA_TRANSFER_IN_BYTES, srcBuff1, dmaphyssrc1);
        dma_free_coherent(NULL,MAX_DMA_TRANSFER_IN_BYTES, dstBuff1,dmaphysdest1);
 	}
    if (TWO_BUFFERS == num_buff)
	{
        dma_free_coherent(NULL,MAX_DMA_TRANSFER_IN_BYTES, srcBuff2, dmaphyssrc2);
        dma_free_coherent(NULL,MAX_DMA_TRANSFER_IN_BYTES, dstBuff2,dmaphysdest2);
	}
	else
		{
          DBG_PRINT_TRC0(("\nEDMA:NOTIFY  :Invalid Arguments")); 
		  return;
		}
 }
