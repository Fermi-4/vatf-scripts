/*
 * kSt_edma_qdma.c
 *
 * This file demonstrates the qdma mem to mem copy
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
#include "kSt_edma.h"


/****************************************************************************
 * Function            		- kSt_edma3_memtomemcpytest_qdma
 * Functionality      		- This function recieves the EDMA params and performs mem to mem
 *						copy with QDMA channel
 * Input Params   	 	-  acnt,bcnt,ccnt,sync_mode,event_queue
 * Return Value        		 -0 - Succes, -1 - Failure
 * Note                 	-  None
 ****************************************************************************/

/* QDMA Channel, Mem-2-Mem Copy, ASYNC Mode, INCR Mode */
int kSt_edma3_memtomemcpytest_qdma(int acnt, int bcnt, int ccnt, int sync_mode,
                               int event_queue)
{
        int result = 0;
        unsigned int qdma_ch = 0;
        unsigned int tcc = ST_EDMA_TCC_ANY;
        int i;
        int count = 0;
        unsigned int Istestpassed = 0u;
        unsigned int numenabled = 0;
        unsigned int BRCnt = 0;
        int srcbidx = 0;
        int desbidx = 0;
        int srccidx = 0;
        int descidx = 0;
        st_edma_param_set param_set;
        int bcount = bcnt;
        int ccount = ccnt;
	s32 trial =0;
	u32 sample_Time[MAX_TRIALS] = {0,};
	u32 total_Time = 0;
	printk(">>>>>>before for loop\n");
	for (trial = 0; trial <= MAX_TRIALS; trial++)
	{
		bcount = bcnt;
		ccount = ccnt;

	        /* Initalize source and destination buffers */
		for (count = 0u; count < (acnt * bcnt * ccnt); count++) {
                	dmabufsrc1[count] = 'A' + (count % 26);
                	dmabufdest1[count] = 0;
		}

  	      irqraised1 = 0;

		/* Set B count reload as B count. */
		BRCnt = bcnt;

		/* Setting up the SRC/DES Index */
		srcbidx = acnt;
		desbidx = acnt;

		if (sync_mode == ASYNC) {
			/* A Sync Transfer Mode */
			srccidx = acnt;
			descidx = acnt;
			/*result = davinci_request_dma (EDMA_QDMA_CHANNEL_5, "A-SYNC_DMA0",*/
			result = kSt_davinci_request_dma(ST_QDMA_CHANNEL_ANY, "A-SYNC_DMA0",
										 kSt_callback1, NULL,
										 &qdma_ch, &tcc, event_queue);

			printk ("qdma_ch is: %d\n", qdma_ch);
		} else if (sync_mode == ABSYNC) {
			/* AB Sync Transfer Mode */
			srccidx = acnt * bcnt;
			descidx = acnt * bcnt;
			/*result = davinci_request_dma (EDMA_QDMA_CHANNEL_5, "AB-SYNC_DMA0",*/
			result = kSt_davinci_request_dma(ST_QDMA_CHANNEL_ANY, "AB-SYNC_DMA0",
										 kSt_callback1, NULL,
										 &qdma_ch, &tcc, event_queue);
			printk ("qdma_ch is: %d\n", qdma_ch);

		} else {
			printk (" Invalid Transfer mode \n");
		}


	        if (0 != result) {
        	        DBG_PRINT_ERR(("test_qdma::davinci_request_dma failed for qdma_ch, error:%d\n", result));
			return result;
		}

		kSt_davinci_set_dma_src_params(qdma_ch, (unsigned long)(dmaphyssrc1),
					INCR, W8BIT);

		kSt_davinci_set_dma_dest_params(qdma_ch, (unsigned long)(dmaphysdest1),
					INCR, W8BIT);

		kSt_davinci_set_dma_src_index(qdma_ch, srcbidx, srccidx);

		kSt_davinci_set_dma_dest_index(qdma_ch, desbidx, descidx);

		/* Enable the Interrupts on QDMA Channel */
		printk(">>>>>>>>>>before enabling interrupt on qdma\n");
		kSt_davinci_get_dma_params(qdma_ch, &param_set);
		param_set.opt |= (1 << ITCINTEN_SHIFT);
		param_set.opt |= (1 << TCINTEN_SHIFT);
		/* Write some other fields */
		param_set.link_bcntrld &= 0x0000ffff;
		param_set.link_bcntrld |= ((BRCnt & 0xFFFFu) << 16);

		if (sync_mode == ASYNC) {
			/* A Sync Transfer Mode */
			param_set.opt &= (~SYNCDIM);
		} else if (sync_mode == ABSYNC) {
			/* AB Sync Transfer Mode */
			param_set.opt |= SYNCDIM;
		} else {
			printk (" Invalid Transfer mode \n");
		}
			printk(">>>>>>>>before calling kSt_davinci_start_dma\n");
	        result = kSt_davinci_start_dma(qdma_ch);
			printk(">>>>>>>>after calling kSt_davinci_start_dma with result %d\n",result);
			
		if (result != 0) {
			DBG_PRINT_ERR(("test_qdma: kSt_davinci_start_dma failed"));
			return result;
		}
		if (sync_mode == ASYNC) {
			numenabled = bcnt * ccnt;
		} else if (sync_mode == ABSYNC) {
			numenabled = ccnt;
		} else {
			printk (" Invalid Transfer mode \n");
		}


	        //set QCHMAP4 manually
	        //*(unsigned int*) IO_ADDRESS(0x01C00000 + 0x210) = (57<<5) | (7<<2);
	   //     *(unsigned int*) IO_ADDRESS(0x01C00000 + 0x200) = (0<<5) | (0<<2);

		if (performance == 1)	
			start_Timer();

	        for (i = 0; i < numenabled; i++) {
        	        irqraised1 = 0;

			if (i == (numenabled - 1u)) {
                        	/* Since OPT.STATIC field should be SET for isolated
                        	* QDMA transfers or for the final transfer in a linked
                        	* list of QDMA transfers, do the needful for the last
                        	* request.
                        	*/
                        	param_set.opt |= (1 << STATIC_SHIFT);
               		}

        	        /* Set the acount, bcount, ccount registers */
             		param_set.a_b_cnt = (((bcount & 0xFFFFu) << 16) | acnt);
                	param_set.ccnt = ccount;

              		/* Trigger the PaRam */
                	kSt_davinci_set_dma_params(qdma_ch, &param_set);

                	/* Wait for the Completion ISR. */
					printk(">>>>>>>>>>>> before while(irqraised1 == 0u)\n");
                	while (irqraised1 == 0u) ;

                	/* Check the status of the completed transfer */
                	if (irqraised1 < 0) {
                        	/* Some error occured, break from the FOR loop. */
                      		DBG_PRINT_ERR(("test_qdma: Event Miss Occured!!!"));
                        	break;
                	}

                	/* Now modify the BCOUNT and CCOUNT. Since these counts will
                 	* be decremented after every transfer, we have to correctly
                 	* modify them for the next updation.
                 	* Either we keep track of those counts, or we read them from the
                 	* PaRAM Set, both are correct. We will choose the second (easier)
                 	* option.
                 	*/
                	kSt_davinci_get_dma_params(qdma_ch, &param_set);
                	bcount = ((param_set.a_b_cnt & 0xFFFF0000) >> 16);
                	ccount = param_set.ccnt;
        	}
		if (performance == 1)	
			sample_Time[trial] = stop_Timer();

        	for (i = 0; i < (acnt * bcnt * ccnt); i++) {
                	if (dmabufsrc1[i] != dmabufdest1[i]) {
                       		DBG_PRINT_ERR(("test_qdma: Data write-read matching failed at = %u\n",i));
                        	Istestpassed = 0u;
				result = -1;
                        	break;
               		}
        	}

        	if (i == (acnt * bcnt * ccnt)) {
                	Istestpassed = 1u;
        	}

        	kSt_davinci_stop_dma(qdma_ch);
        	kSt_davinci_free_dma(qdma_ch);
	}	
	if(performance) {
		total_Time = 0;
		for (trial = 0; trial < MAX_TRIALS; trial++)
		{
			total_Time += sample_Time[trial];
		}
	}
	if (Istestpassed == 1u) {
		DBG_PRINT_TRC0( ("test_qdma: Transfer controller/event_queue: %d", event_queue));
		DBG_PRINT_TRC0( ("test_qdma: Mode: %d  0 -> ASYNC, 1 -> ABSYNC", sync_mode));		
		if (performance == 1) { 
			DBG_PRINT_TRC0(("test_qdma: Time Elapsed in usec: %d", (total_Time/MAX_TRIALS)));
		} else {
			DBG_PRINT_TRC0(("test_qdma: EDMA Data Transfer Successfull "));
		}
	} else {
		DBG_PRINT_TRC0(("test_qdma: EDMA Data Transfer Failed "));
	}
        return result;
}



