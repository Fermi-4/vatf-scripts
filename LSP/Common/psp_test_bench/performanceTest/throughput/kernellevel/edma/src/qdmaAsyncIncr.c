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
 *  \file    st_qdma_ASync_incr.c
 *
 *  \brief  This File Tests QDMA in A-Sync Incr mode
 *  
 *  \desc  Allocates Source and Destination Buffers in the kernel memory , and perfroms 
 *         a data transfer between them using QDMA channel in A-Sync mode
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1    Srinivas.B.N    Created
 *  \version   1.1 - Surendra Puduru: Updated prints according to automation requirements
 */
#define MAX_TESTCASES_INIT 10
#define MAX_TRIALS 1
#define AUTOMATION

#include "edmaCommon.h"
#include "debugLog.h"


transferCounts edmaTransferparams[MAX_TESTCASES_INIT] =
{
    {1024,  64, 1},
    {4096,  16,  1},
    {8192,  8,  1},
    {16348, 4,  1},
    {32767, 2,  1},
    {65534, 1,  1},
    
};



/* =========================================================
 * @func: callback
 *
 * @desc: Gets called upon fnish of transfer or event miss 
 *
 * @modif: Object is taken out of the kernel
 *
 * @inputs: NONE
 * 
 * @outputs: NONE
 * 
 * @return: NONE
 * ==========================================================
 */
static void callback(s32 lch, u32 ch_status, void *data)
{
    switch(ch_status)
    {
        case DMA_COMPLETE:
            irqRaised = 1;
            break;
#if 0
        case DMA_EVT_MISS_ERROR:
            irqRaised = -1;
            break;
        case QDMA_EVT_MISS_ERROR:
            irqRaised = -2;
            break;
#endif
        default:
            irqRaised = -1;
            break;
    }

}



/* =========================================================
 * @func: st_qdma_Async_INCR_init
 *
 * @desc: a)Initiates the module
 *        b)Allocates the Source buffer
 *        c)Allocates the Destination buffer
 *
 * @modif: Object is taken out of the kernel
 *
 * @inputs: NONE
 * 
 * @outputs: NONE
 * 
 * @return: 0 for sucessfull initialization of module
 * ==========================================================
 */
int  st_qdma_Async_INCR_init(void)
{
    s32 index = 0;

#ifndef AUTOMATION
    DBG_PRINT_TRC(("\n*************************************************************"));
    DBG_PRINT_TRC(("\nEDMA:NOTIFY	:QDMA Memory to Memory Transfer A-Sync INCR"));
    DBG_PRINT_TRC(("\n*************************************************************"));
#endif
    st_memory_alloc(ONE_BUFFER);
    for (index = 0; index < MAX_TESTCASES; index++)
    { 
#ifndef AUTOMATION
        DBG_PRINT_TRC(("\nACnt =%d :BCnt =%d :CCnt =%d\n",edmaTransferparams[index].ACnt,edmaTransferparams[index].BCnt,edmaTransferparams[index].CCnt));
#else      
        DBG_PRINT_TRC(("qdma: async: A Count: %d\n", edmaTransferparams[index].ACnt));
        DBG_PRINT_TRC(("qdma: async: B Count: %d\n", edmaTransferparams[index].BCnt));
        DBG_PRINT_TRC(("qdma: async: C Count: %d\n", edmaTransferparams[index].CCnt));
#endif
        st_qdma_Async_incr(edmaTransferparams[index].ACnt , edmaTransferparams[index].BCnt , edmaTransferparams[index].CCnt);  
    }
    return 0;

}



/* ==============================================================
 * @func: st_qdma_Async_incr
 *
 * @desc: a) Allocates the Channel 
 *        b) Sets the Channel parameters
 *        c) Triggers the Transfer
 *        d) Waits in loop for Call back to return
 *        e) Makes data comparison between source and destination
 *        f) Frees the Channel
 *
 * @modif: Destination data is replaced by source 
 *         data upon calling this function
 *
 * @inputs: short ACnt        : Ranges from 1 to 65535
 *          short BCnt        : Ranges from 1 to 65535 
 *          short CCnt        : Ranges from 1 to 65535
 * 
 * @outputs: NONE
 * 
 * @return: NONE
 * ================================================================
 */


void st_qdma_Async_incr(u32 ACnt,u32 BCnt,u32 CCnt)
{
    s32 dma_ch = 0;
    s32 tcc = EDMA_TCC_ANY;
    s32 count = 0;
    s32 Failure_flag = 0;
    s32 indx = 0;
    s16 srcbidx = 0;
    s16 desbidx = 0;
    s16 srccidx = 0;
    s16 descidx = 0;
    s16 BCntRdl = 0;
    s32 result=0; 
    u32 loop;
    u32 size=0; 
    edmacc_paramentry_regs param_set;
	s32 i ;
    u32 sample_Time[MAX_TRIALS] = {0,};
    u32 total_Time = 0;
    u32 trial = 0;
    /*A,B,C counts are modified during PaRAM update ; Save the values before use*/
    u32 storeAcnt = ACnt;
    u32 storeBcnt = BCnt;
    u32 storeCcnt = CCnt;

for (trial = 0; trial <= MAX_TRIALS; trial++)
    {
    /*Save the total size*/
    size=(ACnt*BCnt*CCnt);


    /*B-Count Reload field should be BCnt*/
    BCntRdl = BCnt;

    /*Source and Destination B-Indexes*/
    srcbidx = desbidx = ACnt;

    /*Source and Destination C-Indexes*/
    srccidx = descidx = ((ACnt * BCnt) - (ACnt * (BCnt - 1)));

    /*Populating the source and destination buffers*/
    for (count = 0; count < (ACnt * BCnt * CCnt) ; count++) 
    {
        srcBuff1[count] = 'A' + (count % 26);	
        dstBuff1[count] = 0;
    }

    /*Request QDMA Channels*/
    result=davinci_request_dma(EDMA_QDMA_CHANNEL_ANY, "A-SYNC_DMA0", (void *)&callback, NULL, &dma_ch, &tcc, 0);
    if (0 == result)
    {
#ifndef AUTOMATION
        DBG_PRINT_TRC0(("\nEDMA:PASS :Allocating QDMA Channel"));
#else
                ;
#endif
    }
    else
    {
        DBG_PRINT_TRC(("\nEDMA:FAIL  :Allocating QDMA Channel %d ",result));
    }

    /*Set Source Parameters*/
    davinci_set_dma_src_params(dma_ch, (unsigned long)(dmaphyssrc1), INCR, W8BIT);

#ifndef AUTOMATION
    DBG_PRINT_TRC0(("\nEDMA:PASS  :Setting Source Params"));
#endif
    /*Set Destination Parameters*/

    davinci_set_dma_dest_params (dma_ch, (unsigned long)(dmaphysdest1), INCR, W8BIT);

#ifndef AUTOMATION
    DBG_PRINT_TRC0(("\nEDMA:PASS  :Setting Destination Params"));
#endif
    /*Set DMA source Index*/
    davinci_set_dma_src_index(dma_ch, srcbidx, srccidx);

#ifndef AUTOMATION
    DBG_PRINT_TRC0(("\nEDMA:PASS  :Setting Source index"));
#endif
    /*Set DMA Destination Index*/
    davinci_set_dma_dest_index(dma_ch, desbidx, descidx);

#ifndef AUTOMATION
    DBG_PRINT_TRC0(("\nEDMA:PASS  :Setting Destination index"));
#endif
    /* Enable the Interrupts on QDMA Channel */
    davinci_get_dma_params (dma_ch, &param_set);
    param_set.opt |= (1 << ITCINTEN_SHIFT);
    param_set.opt |= (1 << TCINTEN_SHIFT);

    /* Write some other fields */
    param_set.link_bcntrld &= 0x0000ffff;
    param_set.link_bcntrld |= ((BCntRdl & 0xFFFFu) << 16);
    param_set.opt &= (~SYNCDIM);

    result = davinci_start_dma(dma_ch);
    if (0 == result)
    {
#ifndef AUTOMATION
        DBG_PRINT_TRC0(("\nEDMA:PASS	:Starting the QDMA transfer"));
#else
                ;
#endif
    }
    else
    {
        DBG_PRINT_TRC(("\nEDMA:FAIL	:Error:%d the QDMA transfer",result));
    }

    loop = BCnt * CCnt;

    if (loop == 0)
    {
        loop =  1;
    }

	START_TIMING

    for (i = 0; i < loop; i++)
    {
        /*Reset callback variable before trigger*/
        irqRaised = RESET;

        if (i == (loop-1u))
        {
            /**
             * Since OPT.STATIC field should be SET for isolated
             * QDMA transfers or for the final transfer in a linked
             * list of QDMA transfers, do the needful for the last
             * request.
             */
            param_set.opt |= (1 << STATIC_SHIFT);
        }

        param_set.a_b_cnt = (((BCnt & 0xFFFFu) << 16) | ACnt);
        param_set.ccnt = CCnt;


        /* Trigger the PaRam */
        davinci_set_dma_params(dma_ch, &param_set);

        /* Wait for the Completion ISR. */
        while(RESET == irqRaised)
        {
        };

        if (0 > irqRaised)
        {
            DBG_PRINT_TRC(("\nEDMA:FAIL :Event miss occured"));
            break;
        }

        /*
         * Now modify the BCOUNT and CCOUNT. Since these counts will
         * be decremented after every transfer, we have to correctly
         * modify them for the next updation.
         * Either we keep track of those counts, or we read them from the
         * PaRAM Set, both are correct. We will choose the second (easier)
         * option.
         */
        davinci_get_dma_params (dma_ch, &param_set);
        BCnt = ((param_set.a_b_cnt & 0xFFFF0000) >> 16);
        CCnt = param_set.ccnt;

    }

     sample_Time[trial] = STOP_TIMING

    /*Make data comparison for data integrity*/
    for (indx= 0; indx < (storeAcnt * storeBcnt * storeCcnt); indx++) 
    {
        if (srcBuff1[indx] != dstBuff1[indx]) 
        {
            DBG_PRINT_TRC(("\nEDMA:FAIL	:Data write-read matching failed at = %u",indx));
            Failure_flag = 1;
            result = -2; //-2 is for data mismatch
            break;
        }

    }	

    if(Failure_flag)
    {
        DBG_PRINT_TRC(("\nEDMA:FAIL :QDMA A-Sync INCR ACnt =%d :BCnt =%d :CCnt =%d Total Size = %d\n",storeAcnt,storeBcnt,storeCcnt,size));
		break;
	}
    else
    {
#ifndef AUTOMATION
        DBG_PRINT_TRC0(("\nEDMA:PASS :QDMA A-Sync INCR ACnt =%d :BCnt =%d :CCnt =%d Total Size = %d\n",storeAcnt,storeBcnt,storeCcnt,size));
#else
                ;
#endif
    }

    /*Free the channel*/
    davinci_free_dma(dma_ch);
  }

   total_Time = 0;

    for (trial = 0; trial < MAX_TRIALS; trial++)
    { 
        total_Time += sample_Time[trial];
    }

    if (!Failure_flag)
#ifndef AUTOMATION
        DBG_PRINT_TRC(("EDMA: Avg Time Elapsed is %d micro-sec for %d Bytes\n", (total_Time/MAX_TRIALS),size));
#else      
        DBG_PRINT_TRC(("qdma: async: Application buffer Size in Kbits: %d\n", size));
        DBG_PRINT_TRC(("qdma: async: Time Elapsed in usec: %d\n", (total_Time/MAX_TRIALS)));    
#endif

}




/* =========================================================
 * @func: st_qdma_Async_INCR_exit
 *
 * @desc: Function to exit form A-Sync , INCR mode testing
 *
 * @modif: Object is taken out of the kernel
 *
 * @inputs: NONE
 * 
 * @outputs: NONE
 * 
 * @return: NONE
 * ==========================================================
 */
void st_qdma_Async_INCR_exit(void)
{
    st_memory_free(ONE_BUFFER);
#ifndef AUTOMATION
	DBG_PRINT_TRC(("\nEDMA:NOTIFY	:Exiting QDMA Transfer A-Sync INCR\n"));	
#endif
}

module_init(st_qdma_Async_INCR_init);
module_exit(st_qdma_Async_INCR_exit);

/* vim: set ts=4 sw=4 tw=80 et:*/
