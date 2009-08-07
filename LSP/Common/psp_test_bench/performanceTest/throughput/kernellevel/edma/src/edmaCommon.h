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
 *  \file    st_edma_common.h
 *
 *  \brief : This is a common file to be included in all the files 
 *
 * \ description: This code supplies the macros, Include files and prototypes
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1    Srinivas.B.N    Created
 *
 */

#define EVALUATE_PERFORMANCE

#ifdef EVALUATE_PERFORMANCE
#define START_TIMING start_Timer();
#define STOP_TIMING stop_Timer();
#else /* EVALUATE_PERFORMANCE */
#define START_TIMING
#define STOP_TIMING
#endif /* EVALUATE_PERFORMANCE */


#define RESET 			0
#define MAX_DMA_TRANSFER_IN_BYTES   (1048600)
#define MAX_TESTCASES 6
#define ITCINTEN_SHIFT 21
#define TCINTEN_SHIFT  20
#define ITCCHEN_SHIFT 23
#define STATIC_SHIFT  3

#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/interrupt.h>
#include <asm/io.h>
#include <asm/arch-davinci/memory.h>
#include <linux/moduleparam.h>
#include <asm/arch/edma.h>
#include <linux/sysctl.h>
#include <linux/mm.h>
#include <asm/delay.h>
#include <linux/wait.h>
#include <linux/dma-mapping.h>
#include <asm/arch/irqs.h>
#include <asm/arch/cpu.h>
#include "edmaMemAlloc.h"
#include "kStTimer.h"

#ifdef LSP_2_0_PRODUCT
typedef struct paramentry_descriptor edmacc_paramentry_regs ;
#else
    #ifdef LSP_1_1_PRODUCT
    #define EDMA_TCC_ANY TCC_ANY
    #define EDMA_PARAM_ANY DAVINCI_EDMA_PARAM_ANY
    #define EDMA_DMA_CHANNEL_ANY DAVINCI_DMA_CHANNEL_ANY
    #define EDMA_QDMA_CHANNEL_ANY DAVINCI_DMA_QDMA7
    #endif
#endif

typedef struct transferCounts {
    u32 ACnt;
    u32 BCnt;
    u32 CCnt;
}transferCounts;

/*Flag which sets after callback*/
static volatile int irqRaised =0;
/*Flag which sets after callback*/
static volatile int irqRaised1 =0;
/*Flag which sets after callback*/
static volatile int irqRaised2 =0;

void st_edma_memcpy(void);
void st_edma_Async_incr(u32, u32, u32);
void st_edma_ABsync_incr(u32, u32, u32);
void st_edma_Async_link(u32, u32, u32);
void st_edma_ABsync_link(u32, u32, u32);
void st_edma_Async_chain(u16 , u16, u16);
void st_edma_ABsync_chain(u16, u16, u16);
void st_qdma_Async_incr(u32, u32, u32);
void st_qdma_ABsync_incr(u32, u32, u32);
void st_qdma_Async_link(u32, u32, u32);
void st_qdma_ABsync_link(u16, u16, u16);




/* vim: set ts=4 sw=4 tw=80 et:*/
