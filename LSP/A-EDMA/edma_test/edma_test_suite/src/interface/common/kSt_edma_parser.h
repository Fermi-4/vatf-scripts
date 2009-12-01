/*
 * kSt_edma_parser.h
 *
 * header file accessed by the edma parser
 *
 * Copyright (C) 2009 Texas Instruments Incorporated - http://www.ti.com/
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation version 2.
 *
 * This program is distributed <93>as is<94> WITHOUT ANY WARRANTY of any
 * kind, whether express or implied; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef _KST_EDMA_PARSER_H_
#define _KST_EDMA_PARSER_H_


#include <linux/module.h>
#include <linux/init.h>
#include <linux/mm.h>
#include <linux/dma-mapping.h>
#include "kSt_edma.h"

#define MAX_DMA_TRANSFER_IN_BYTES   acnt*bcnt*ccnt

dma_addr_t dmaphyssrc1 = 0;
dma_addr_t dmaphyssrc2 = 0;
dma_addr_t dmaphysdest1 = 0;
dma_addr_t dmaphysdest2 = 0;

char *dmabufsrc1 = NULL;
char *dmabufsrc2 = NULL;
char *dmabufdest1 = NULL;
char *dmabufdest2 = NULL;

static int acnt = 512;
static int bcnt = 8;
static int ccnt = 8;

int performance = 0;
int numTCs = 2;
int qdma = 0;
int link = 0;
int chain = 0;
int async = 0;
int absync = 0;

volatile int irqraised1 = 0;
volatile int irqraised2 = 0;

module_param(acnt, int, S_IRUGO);
module_param(bcnt, int, S_IRUGO);
module_param(ccnt, int, S_IRUGO);

module_param(performance, int, S_IRUGO);
module_param(numTCs, int, S_IRUGO);
module_param(qdma, int, S_IRUGO);
module_param(link, int, S_IRUGO);
module_param(chain, int, S_IRUGO);
module_param(async, int, S_IRUGO);
module_param(absync, int, S_IRUGO);

int kSt_edma3_memtomemcpytest_dma(int acnt, int bcnt, int ccnt, int sync_mode,
			      int event_queue);
int kSt_edma3_memtomemcpytest_qdma(int acnt, int bcnt, int ccnt, int sync_mode,
			       int event_queue);
int kSt_edma3_memtomemcpytest_dma_link(int acnt, int bcnt, int ccnt, int sync_mode,
				   int event_queue);
int kSt_edma3_memtomemcpytest_dma_chain(int acnt, int bcnt, int ccnt, int sync_mode,
				    int event_queue);

#endif  /*_KST_EDMA_PARSER_H_*/

