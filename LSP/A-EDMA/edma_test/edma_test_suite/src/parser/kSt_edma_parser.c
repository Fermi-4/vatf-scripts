/*
 * kSt_edma_parser.c
 *
 * EDMA test suite parser file
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


/*Testcode related header files */
#include "kSt_edma_parser.h"


/****************************************************************************
 * Function            		- kSt_callback1
 * Functionality      		- This function is a completion handler registered with EDMA driver
 * 					 	while requesting the first Master channel
 * Input Params   	 	-  lch, ch_status, data
 * Return Value        	 - None
 * Note                 		-  None
 ****************************************************************************/

void kSt_callback1(int lch, unsigned short ch_status, void *data)
{
	switch (ch_status) {
	case ST_DMA_COMPLETE:
		irqraised1 = 1;
		break;
	case ST_DMA_EVT_MISS_ERROR:
		irqraised1 = -1;
		DBG_PRINT_ERR(("From Callback 1: DMA_EVT_MISS_ERROR occured "
			   "on Channel %d", lch));
		break;
	case ST_QDMA_EVT_MISS_ERROR:
		irqraised1 = -2;
		DBG_PRINT_ERR(("From Callback 1: QDMA_EVT_MISS_ERROR occured "
			   "on Channel %d", lch));
		break;
	default:
		break;
	}
}


/****************************************************************************
 * Function            		- kSt_callback2
 * Functionality      		- This function is a completion handler registered with EDMA driver
 * 					 	while requesting the secone Master channel
 * Input Params   	 	-  lch, ch_status, data
 * Return Value        	 - None
 * Note                 		-  None
 ****************************************************************************/

void kSt_callback2(int lch, unsigned short ch_status, void *data)
{
	switch (ch_status) {
	case ST_DMA_COMPLETE:
		irqraised2 = 1;
		break;
	case ST_DMA_EVT_MISS_ERROR:
		irqraised2 = -1;
		DBG_PRINT_ERR(("From Callback 2: DMA_EVT_MISS_ERROR occured "
			   "on Channel %d", lch));
		break;
	case ST_QDMA_EVT_MISS_ERROR:
		irqraised2 = -2;
		DBG_PRINT_ERR(("From Callback 2: QDMA_EVT_MISS_ERROR occured "
			   "on Channel %d", lch));
		break;
	default:
		break;
	}
}


/****************************************************************************
 * Function            		- kSt_edma_test_init
 * Functionality      		- This function is a init function registered with module_init
 * Input Params   	 	-  None
 * Return Value        	 - 0 - Succes, -1 - Failure
 * Note                 		-  None
 ****************************************************************************/


static int __init kSt_edma_test_init(void)
{
	int result = 0;
	int modes = 2;
	int i, j;
	int mode_init = 0;
	printk("\n");
	DBG_PRINT_TRC_NEOL(("\n=======================================================\n"));
	DBG_PRINT_TRC0(("The test is going to start with following values"));
	DBG_PRINT_TRC0(("ACNT=%d, BCNT=%d, CCNT=%d", acnt, bcnt, ccnt));
	DBG_PRINT_TRC0(("Transfer buffer size = %d", acnt * bcnt *ccnt));
	DBG_PRINT_TRC0(("Number of Transfer controllers = %d", numTCs));
	DBG_PRINT_TRC_NEOL(("\n=======================================================\n"));


	/* allocate consistent memory for DMA
	   dmaphyssrc1(handle)= device viewed address.
	   dmabufsrc1 = CPU-viewed address */

	dmabufsrc1 = dma_alloc_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES,
					&dmaphyssrc1, 0);
	if (!dmabufsrc1) {
		DBG_PRINT_ERR(("dma_alloc_coherent failed for dmaphyssrc1"));
		return -ENOMEM;
	}

	dmabufdest1 = dma_alloc_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES,
					 &dmaphysdest1, 0);
	if (!dmabufdest1) {
		DBG_PRINT_ERR(("dma_alloc_coherent failed for dmaphysdest1"));

		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc1,
				  dmaphyssrc1);
		return -ENOMEM;
	}

	dmabufsrc2 = dma_alloc_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES,
					&dmaphyssrc2, 0);
	if (!dmabufsrc2) {
		DBG_PRINT_ERR(("dma_alloc_coherent failed for dmaphyssrc2"));

		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc1,
				  dmaphyssrc1);
		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufdest1,
				  dmaphysdest1);
		return -ENOMEM;
	}

	dmabufdest2 = dma_alloc_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES,
					 &dmaphysdest2, 0);
	if (!dmabufdest2) {
		DBG_PRINT_ERR(("dma_alloc_coherent failed for dmaphysdest2"));

		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc1,
				  dmaphyssrc1);
		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufdest1,
				  dmaphysdest1);
		dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc2,
				  dmaphyssrc2);
		return -ENOMEM;
	}

	if (async) {
		modes = 1;
	}

	if (absync) {
		mode_init = 1;
	}

	for (j = 0; j < numTCs; j++)
	{
		for (i = mode_init; i < modes; i++)	/* sync_mode */
		{
			if (qdma == 0 && link == 0 && chain == 0) {
				DBG_PRINT_TST_START(("test_dma"));
				result =
			    		kSt_edma3_memtomemcpytest_dma(acnt, bcnt, ccnt,
						      i, j);
				if (0 == result) {
					DBG_PRINT_TST_RESULT_PASS(("test_dma"));
				} else {
				DBG_PRINT_TST_RESULT_FAIL(("test_dma"))
				}
				DBG_PRINT_TST_END(("test_dma"));
			}

			if (0 == result && qdma == 1) {
				DBG_PRINT_TST_START(("test_qdma"));
				printk (">>>>>before calling kSt_edma3_memtomemcpytest_qdma\n");
				result =
					kSt_edma3_memtomemcpytest_qdma(acnt,bcnt,ccnt,
								i,j);
				if (0 == result) {
				DBG_PRINT_TST_RESULT_PASS(("test_qdma"));
				} else {
				DBG_PRINT_TST_RESULT_FAIL(("test_qdma"));
				}
				DBG_PRINT_TST_END(("test_qdma"));
				}


			if (0 == result && link == 1) {
				DBG_PRINT_TST_START(("test_dma_link"));
				result =
				    kSt_edma3_memtomemcpytest_dma_link(acnt,
								   bcnt,
								   ccnt,
								   i,
								   j);
				if (0 == result) {
					DBG_PRINT_TST_RESULT_PASS(("test_dma_link"));
				} else {
				DBG_PRINT_TST_RESULT_FAIL(("test_dma_link"));
				}
				DBG_PRINT_TST_END(("test_dma_link"));
			}

			if (0 == result && chain == 1) {
				DBG_PRINT_TST_START(("test_dma_chain"));
				result =
				    kSt_edma3_memtomemcpytest_dma_chain
				    (acnt, bcnt, ccnt, i, j);
				if (0 == result) {
					DBG_PRINT_TST_RESULT_PASS(("test_dma_chain"));
				} else {
					DBG_PRINT_TST_RESULT_FAIL(("test_dma_chain"));
				}
				DBG_PRINT_TST_END(("test_dma_chain"));
			}

		}
	}

	return result;
}

/****************************************************************************
 * Function            		- kSt_edma_test_exit
 * Functionality      		- This function is a exit function registered with module_exit
 * Input Params   	 	-  None
 * Return Value        	 -None
 * Note                 		-  None
 ****************************************************************************/


void kSt_edma_test_exit(void)
{
	dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc1,
			  dmaphyssrc1);
	dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufdest1,
			  dmaphysdest1);

	dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufsrc2,
			  dmaphyssrc2);
	dma_free_coherent(NULL, MAX_DMA_TRANSFER_IN_BYTES, dmabufdest2,
			  dmaphysdest2);

}


module_init(kSt_edma_test_init);
module_exit(kSt_edma_test_exit);

MODULE_AUTHOR("Texas Instruments");
MODULE_LICENSE("GPL");
