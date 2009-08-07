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
 *  \file    st_edma_ASync_INCR.c
 *
 *  \brief   This file Tests A-Sync INCR mode transfer for DMA Channels
 *  
 *  \desc  It allocates source and destination buffers in kernel space and performes a Manual trigger on EDMA 
 *            channel and accomplishes the transfer
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1    Srinivas.B.N    Created
 *  \version   1.1 - Surendra Puduru: Updated prints according to automation requirements
 */
#define MAX_TESTCASES_INIT 10
#define MAX_TRIALS 10
#define AUTOMATION

#include "edmaCommon.h"
#include "debugLog.h"

transferCounts edmaTransferparams[MAX_TESTCASES_INIT]= 
{
   /*ACnt    BCnt   CCnt*/
    {1024,   64,     1},
    {4096,   16,     1},
    {8192,   8,      1},
    {16384,  4,      1},
    {32767,  2,      1},
    {65535,  1,      1},
};



/* ======================================================== 
 * @func: callback
 *
 * @desc: Callback function which modifies a variable when
 *        the transfer completes and the TCC is returned.
 *
 * @modif: Global parameter irqRaised 
 *
 * @inputs: s32 lch                   :Channel number
 *          unsigned short ch_status  :Status of the channel
 *          void *data                :buffer 
 * 
 * @outputs: NONE
 * 
 * @return: NONE
 * ========================================================= */
static void callback(s32 lch, u16 ch_status, void *data)
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

/* ========================================================  
 *  @func: st_edma_01_Async_INCR_init
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
 * ========================================================= */
s32 st_edma_Async_INCR_init(void)
{
    s32 index = 0;
    srcBuff1 = NULL;
    dstBuff1 = NULL;
    
#ifndef AUTOMATION
    DBG_PRINT_TRC(("\n******************************************************************"));
    DBG_PRINT_TRC(("\nEDMA:NOTIFY	:DMA Memory to Memory Transfer A-Sync INCR\n"));
    DBG_PRINT_TRC(("\n******************************************************************\n"));
#endif

    /*Specify the number of memory buffers required */ 
	st_memory_alloc(ONE_BUFFER);

    for (index = 0; index < MAX_TESTCASES; index++)
    { 
#ifndef AUTOMATION
        DBG_PRINT_TRC(("\nACnt =%d :BCnt =%d :CCnt =%d\n",edmaTransferparams[index].ACnt,edmaTransferparams[index].BCnt,edmaTransferparams[index].CCnt));
#else      
        DBG_PRINT_TRC(("edma: async: A Count: %d\n",edmaTransferparams[index].ACnt));
        DBG_PRINT_TRC(("edma: async: B Count: %d\n",edmaTransferparams[index].BCnt));
        DBG_PRINT_TRC(("edma: async: C Count: %d\n",edmaTransferparams[index].CCnt));
#endif
        st_edma_Async_incr(edmaTransferparams[index].ACnt , edmaTransferparams[index].BCnt , edmaTransferparams[index].CCnt);  
    }

    return 0;
}



/* ============================================================= 
 * @func: st_edma_Async_incr
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
 * @inputs: u16 ACnt        : Ranges from 1 to 65535
 *          u16 BCnt        : Ranges from 1 to 65535 
 *          u16 CCnt        : Ranges from 1 to 65535
 * 
 * @outputs: NONE
 * 
 * @return: NONE
 * =============================================================== */
void st_edma_Async_incr(u32 ACnt,u32 BCnt,u32 CCnt)
{
    s32 dma_ch = 0;
    s32 tcc = EDMA_TCC_ANY;
    s32 count = 0;
    s32 Failiure_flag = 0;
    s32 indx = 0;
    s16 srcbidx = 0;
    s16 desbidx = 0;
    s16 srccidx = 0;
    s16 descidx = 0;
    u32 BCntRdl = 0;
    s32 result = 0; 
    u32 loop;
    u32 size = 0;
    edmacc_paramentry_regs param_set;
    s32 i = 0;
    s32 trial =0;
    u32 sample_Time[MAX_TRIALS] = {0,};
    u32 total_Time = 0;

    for (trial = 0; trial <= MAX_TRIALS; trial++)
    {
        /*Save the total size*/
        size=(ACnt*BCnt*CCnt);

        /*B-Count Reload field should be BCnt*/
        BCntRdl = BCnt;

        /*Populating the source and destination buffers*/

        for (count = 0; count < (ACnt * BCnt * CCnt) ; count++) 
        {
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
        }



        /*Request DMA Channels*/
        result = davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch, &tcc, EVENTQ_0 );

        if (0 == result)
        {
#ifndef AUTOMATION
            DBG_PRINT_TRC0(("\nEDMA:PASS	:Allocating DMA Channel Num = %d,TCC =%d",dma_ch,tcc));
#else
            ;
#endif
        }

        else
        {
            DBG_PRINT_TRC(("\nEDMA:FAIL	:Allocating DMA Channel Error: %d",result));
            return ;
        }

        davinci_set_dma_src_params(dma_ch, (u32)(dmaphyssrc1), INCR, W8BIT);

#ifndef AUTOMATION
        DBG_PRINT_TRC0(("\nEDMA:PASS  	:Setting Source Parameters"));
#endif
        /*Set Destination Parameters*/
        davinci_set_dma_dest_params (dma_ch,(u32)(dmaphysdest1), INCR, W8BIT);

#ifndef AUTOMATION
        DBG_PRINT_TRC0(("\nEDMA:PASS  	:Setting Destination Parameters"));
#endif

        /*Source and Destination B-Indexes*/
        srcbidx = desbidx = ACnt;

        /*Source and Destination C-Indexes*/
        srccidx = descidx = ((ACnt * BCnt) - (ACnt * (BCnt - 1)));

        /*Set DMA source Index*/
        davinci_set_dma_src_index(dma_ch, srcbidx, srccidx);

#ifndef AUTOMATION
        DBG_PRINT_TRC0("\nEDMA:PASS  	:Setting Source Index Parameters");
#endif
        /*Set DMA Destination Index*/
        davinci_set_dma_dest_index(dma_ch, desbidx, descidx);

#ifndef AUTOMATION
        DBG_PRINT_TRC0("\nEDMA:PASS  	:Setting Destination Index Parameters");	
#endif

        /*Set Transfer Parameters*/
        davinci_set_dma_transfer_params(dma_ch, ACnt, BCnt, CCnt, BCntRdl, ASYNC);

#ifndef AUTOMATION
        DBG_PRINT_TRC0("\nEDMA:PASS  	:Setting DMA Transfer Parameters");
#endif
        davinci_get_dma_params (dma_ch, &param_set);
        param_set.opt |= (1 << ITCINTEN_SHIFT);
        param_set.opt |= (1 << TCINTEN_SHIFT);
        davinci_set_dma_params(dma_ch, &param_set);

        /*These Many number of triggers are required for ASYNC transfer*/
        loop=(BCnt * CCnt);

        if (0 == loop)
        {
            loop =  1;
        }

        START_TIMING

            for(i = 0; i < loop; i++)
            {
                irqRaised = RESET;

                result = davinci_start_dma(dma_ch);
                if (0 == result)
                {
#ifndef AUTOMATION
                    DBG_PRINT_TRC0(("\nEDMA:PASS	:Starting the DMA transfer"));
#else
                    ;
#endif
                }
                else
                {

                    DBG_PRINT_TRC(("\nEDMA:FAIL	:Error:%d the DMA transfer",result));
                }
                while (RESET == irqRaised); 
                if (0 > irqRaised  )
                {
                    DBG_PRINT_TRC(("\nEDMA:FAIL :Event miss occured"));
                    break;
                }
            }

        sample_Time[trial] = STOP_TIMING;

#ifndef AUTOMATION
        DBG_PRINT_TRC0(("\nEDMA:NOTIFY :CallBack invoked %d times",i));
#endif

        /*Make data comparison for data integrity*/
        for (indx= 0; indx < (ACnt * BCnt * CCnt); indx++) 
        {
            if (srcBuff1[indx] != dstBuff1[indx]) 
            {
                DBG_PRINT_TRC(("\nEDMA:FAIL	:Data write-read matching failed at = %u",indx));
                Failiure_flag = 1;
                break;
            }
        }



        if(Failiure_flag)
        {
            DBG_PRINT_TRC(("\nEDMA:FAIL	:DMA, A-Sync,INCR, Data Transfer Failed\n"));		
            break;
        }
        else
        {
#ifndef AUTOMATION
            DBG_PRINT_TRC0(("\nEDMA:PASS	:DMA, A-Sync,INCR, Data Transfer Successfull SIZE=%dBytes\n",size));
#else
            ;
#endif
        }

        /*Stop the DMA transfer*/
        davinci_stop_dma(dma_ch);
        /*Free the channel*/
        davinci_free_dma(dma_ch);
    }

    total_Time = 0;

    for (trial = 0; trial < MAX_TRIALS; trial++)
    { 
        total_Time += sample_Time[trial];
    }

    if (!Failiure_flag)
    {
#ifndef AUTOMATION
        DBG_PRINT_TRC(("EDMA: Avg Time Elapsed is %d micro-sec for %d Bytes\n", (total_Time/MAX_TRIALS),size));
#else      
        DBG_PRINT_TRC(("edma: async: Application buffer Size in Kbits: %d\n", size));
        DBG_PRINT_TRC(("edma: async: Time Elapsed in usec: %d\n", (total_Time/MAX_TRIALS)));

#endif
    }
}



/* ======================================================== 
 * @func: st_edma_Async_INCR_exit
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
 * ========================================================= */
void st_edma_Async_INCR_exit(void)
{
   st_memory_free(ONE_BUFFER);
#ifndef AUTOMATION
   DBG_PRINT_TRC(("EDMA:NOTIFY	:Exiting DMA Memory to Memory Transfer A-Sync INCR\n"));
#endif
}

module_init(st_edma_Async_INCR_init);
module_exit(st_edma_Async_INCR_exit);

/* vim: set ts=4 sw=4 tw=80 et:*/

