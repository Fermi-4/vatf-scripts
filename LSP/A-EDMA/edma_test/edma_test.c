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
**|         Copyright (c) 1998-2005 Texas Instruments Incorporated           |**
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

/** \file   edma_test.c
    \brief  DM355 DMA Controller

    This file contains DM355 DMA Controller Test  code.

    NOTE: THIS FILE IS PROVIDED ONLY FOR INITIAL DEMO RELEASE AND MAY BE
          REMOVED AFTER THE DEMO OR THE CONTENTS OF THIS FILE ARE SUBJECT
          TO CHANGE.

    (C) Copyright 2004, Texas Instruments, Inc

    @author     	Anand Patil
    @version    0.1 -
    			Created on 31/09/05 
                Assumption: Channel and ParamEntry has 1 to 1 mapping
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/interrupt.h>
#include <asm/io.h>
#include <asm/arch/memory.h>
#include <linux/moduleparam.h>
#include <asm/arch/edma.h>
//#include "dma_osdep.h"
#include <linux/sysctl.h>
//#include <linux/malloc.h>
#include <linux/mm.h>

#define ALIGN_BYTES 			32
#define FAIL 	-1
#define PASS	0

#define DISPLAY_INFO
//#define DISPLAY_BUFFER

static int irqRaised =0;

/*  Command Line Arguments need to be taken for Scanning 
the Req DMA Parameters required at runtime for testing */


static int 		        Trnsfr_sw;
static unsigned short ACnt = 128, BCnt = 2, CCnt = 0;
static unsigned short ACnt1 = 128, BCnt1 = 2, CCnt1 = 0;
static unsigned short ACnt2 = 128, BCnt2 = 2, CCnt2 = 0;
static unsigned short ACnt3 = 128, BCnt3 = 2, CCnt3 = 0;
static int test_loop = 1;
static int event_q = EVENTQ_0; //EVENTQ_0
static char *Chnl_data;

module_param(Trnsfr_sw,int,666 );
module_param(ACnt,ushort,666 );
module_param(BCnt,ushort,666 );
module_param(CCnt,ushort,666 );
module_param(ACnt1,ushort,666 );
module_param(BCnt1,ushort,666 );
module_param(CCnt1,ushort,666 );
module_param(ACnt2,ushort,666 );
module_param(BCnt2,ushort,666 );
module_param(CCnt2,ushort,666 );
module_param(ACnt3,ushort,666 );
module_param(BCnt3,ushort,666 );
module_param(CCnt3,ushort,666 );
module_param(test_loop, int, 666);
module_param(event_q, int, 666);

int ST_EdmaMemToMemCpyTest_ASYNC_INCR(unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt, int is_open_chan, int dma_ch);
int ST_EdmaMemToMemCpyTest_ABSYNC_INCR(unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt, int is_open_chan, int dma_ch);
void ST_EdmaLinkTest_ASYNC_INCR (unsigned short ACnt1 ,unsigned short BCnt1 , unsigned short CCnt1, unsigned short ACnt2 ,unsigned short BCnt2 , unsigned short CCnt2);
void ST_EdmaChainTest_ASYNC_INCR (unsigned short ACnt1 ,unsigned short BCnt1 , unsigned short CCnt1, unsigned short ACnt2 ,unsigned short BCnt2 , unsigned short CCnt2);
void ST_EdmaChainTest_ABSYNC_INCR (unsigned short ACnt1 ,unsigned short BCnt1 , unsigned short CCnt1, unsigned short ACnt2 ,unsigned short BCnt2 , unsigned short CCnt2);
void	ST_EdmaMemToMemCpyTest_ASYNC_FIFO (unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt);
void ST_EdmaMemToMemCpyTest_ABSYNC_FIFO (unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt);
void Stress_ASYNC_INCR(unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt, int loop);
void Stress_ABSYNC_INCR(unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt, int loop);

/* Intermediate Functions use */
void  EDMA_Set_Params(int dma_ch,unsigned long SrcAddr,unsigned long DestAddr,enum sync_dimension sync_mode, enum address_mode addr_mode, int fifo_width,unsigned short ACnt, unsigned short BCnt,unsigned short CCnt, unsigned short BCnt_Rld);
void	EDMA_Trigger(int dma_ch,unsigned int loop);
void ChannelParams(int dma_ch,unsigned long SrcAddr,unsigned long DesAddr,enum address_mode mode,
					enum fifo_width fwid, short bidx , short cidx);

void	OPT_Func(unsigned int opt);
void	 edma_tc_init(unsigned int  Trnsfr_sw);


//extern unsigned long DAVINCI_gettimeoffset(void);
#define NUM_SECTORS 1024
#define CACHE_LINE_SIZE_IN_BYTES	32

 char *srcBuff2,  *dstBuff2;
 char *srcBuff1,  *dstBuff1;
 char *srcBuff3,  *dstBuff3;

static void callback(int lch, unsigned short ch_status, void *data)
{
	Chnl_data=(char *)data;
	irqRaised = 1;
	printk(KERN_INFO" Channel status is:\t %u\n", ch_status);
}


int  edma_test_init(void)
{
	srcBuff1=NULL;
	dstBuff1=NULL;
	srcBuff2=NULL;
	dstBuff2=NULL;
	
	printk(KERN_INFO" Inside our st_edma_test module\n");
	
	//srcBuff1=(char *)kmalloc (0, GFP_DMA | GFP_ATOMIC | GFP_KERNEL );
	srcBuff1=(char *)kmalloc (131072, GFP_KERNEL );
	if(srcBuff1==NULL)
	 return -ENODEV;
	dstBuff1=(char *)kmalloc (131072, GFP_DMA | GFP_ATOMIC | GFP_KERNEL );
	if(dstBuff1==NULL)	
	 return -ENODEV;
#if 1 
	srcBuff2=(char *)kmalloc (131072, GFP_DMA | GFP_ATOMIC);
	if(srcBuff2==NULL)
	 return -ENODEV;
	dstBuff2=(char *)kmalloc (131072, GFP_DMA | GFP_ATOMIC);
	if(dstBuff2==NULL)	
	 return -ENODEV;
#endif
#if 0	
	srcBuff3=(char *)kmalloc (10240, 0);
	if(srcBuff3==NULL)
	 return -ENODEV;
	dstBuff3=(char *)kmalloc (10240, 0);
	if(srcBuff3==NULL)	
	 return -ENODEV;
#endif

	

	edma_tc_init(Trnsfr_sw);

	return 0; 
}		

void edma_test_exit(void)
{
	 kfree(srcBuff1);
	 kfree(dstBuff1);
	 kfree(srcBuff2);
	 kfree(dstBuff2);
#if 1	 
	 kfree(srcBuff3);
	 kfree(dstBuff3);
#endif	 
	printk(KERN_INFO" ST_Exit_EDMA\n");	
}	

void ChannelParams(int dma_ch,unsigned long SrcAddr,unsigned long DesAddr,enum address_mode mode,
					enum fifo_width fwid, short bidx , short cidx)
{

	davinci_set_dma_src_params(dma_ch,SrcAddr , mode, fwid);
	davinci_set_dma_dest_params (dma_ch,DesAddr, mode, fwid);	
	
	davinci_set_dma_src_index(dma_ch, bidx, cidx);
	davinci_set_dma_dest_index(dma_ch, bidx, cidx);

}

void EDMA_Trigger(int dma_ch,unsigned int  loop)
{
  struct paramentry_descriptor Param_entry;
  short int  temp = 0;
  int indx,i;
  
	for(indx = 0; indx <loop; indx++)	{
		
#ifdef DISPLAY_INFO
		printk(KERN_INFO"\n\n Before DMA TRANSFER \n\n");
		davinci_get_dma_params(dma_ch, &Param_entry);
		printk(KERN_INFO" The Opt is:\t %x\n", Param_entry.opt);
		printk(KERN_INFO" The src is:\t %x\n", Param_entry.src);
		printk(KERN_INFO" The dst is:\t %x\n", Param_entry.dst);
		printk(KERN_INFO" The a_b_cnt is:\t %x\n", Param_entry.a_b_cnt);
		temp = Param_entry.a_b_cnt & 0x0000ffff;
		printk(KERN_INFO" The Value of ACnt is:\t%x\n", temp);
		temp = (Param_entry.a_b_cnt  & 0xffff0000)>>16;	
		printk(KERN_INFO" The Value of BCnt is:\t%x\n", temp);
		printk(KERN_INFO" The CCnt is:\t %x\n", Param_entry.ccnt);		
		printk(KERN_INFO" The src_dst_bidx is:\t %x\n", Param_entry.src_dst_bidx);
		printk(KERN_INFO" The src_dst_cidx is:\t %x\n", Param_entry.src_dst_cidx);
		printk(KERN_INFO" The link_bcntrld is:\t %x\n", Param_entry.link_bcntrld);
		printk("\n\n");
#endif		

		printk(" Performing the DMA_START for:\t %d time(s).\n", indx);
		davinci_start_dma(dma_ch);
	
		for(i =0; i < 1000000; i++)
		//for(i =0; i < 10000; i++)
			asm("NOP");


#ifdef DISPLAY_INFO
		printk(KERN_INFO"\n\n After DMA TRANSFER \n\n");
		davinci_get_dma_params(dma_ch, &Param_entry);

		printk(KERN_INFO" The Opt is:\t %x\n", Param_entry.opt);
		OPT_Func(Param_entry.opt);
		printk(KERN_INFO" The src is:\t %x\n", Param_entry.src);
		printk(KERN_INFO" The dst is:\t %x\n", Param_entry.dst);
		printk(KERN_INFO" The a_b_cnt is:\t %x\n", Param_entry.a_b_cnt);
		temp = Param_entry.a_b_cnt & 0x0000ffff;
		printk(KERN_INFO" The Value of ACnt is:\t%x\n",temp);
		temp = (Param_entry.a_b_cnt & 0xffff0000)>>16;
		printk(KERN_INFO" The Value of BCnt is:\t%x\n",temp);
		printk(KERN_INFO" The CCnt is:\t %x\n", Param_entry.ccnt);
		printk(KERN_INFO" The src_dst_bidx is:\t %x\n", Param_entry.src_dst_bidx);
		printk(KERN_INFO" The src_dst_cidx is:\t %x\n", Param_entry.src_dst_cidx);
		printk(KERN_INFO" The link_bcntrld is:\t %x\n", Param_entry.link_bcntrld);
		printk("\n\n");
#endif	
		davinci_stop_dma(dma_ch);	
	}

}

void Stress_ASYNC_INCR(unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt, int loop)
{
        int i=0, j=0;
        int dma_ch = 0, tcc = EDMA_TCC_ANY;
        int rtn = 0;

        rtn = davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch, &tcc, event_q);
        if(rtn != 0)
        {
                printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel %d Error Val= %d\n", dma_ch, rtn);
                return;
        }

        for(i=0; i<loop; i++){
                for(j =0; j < 100000000; j++)
                        asm("NOP");
                printk(KERN_INFO" \n\nLoop count is: %d\n ", i);
                if(PASS != ST_EdmaMemToMemCpyTest_ASYNC_INCR(ACnt, BCnt, CCnt, 0, dma_ch))
                {
                        printk(KERN_INFO"Stress Test Failed when loop is %d\n", i);
                        break;
                }

        }
        davinci_free_dma(dma_ch);
}

void Stress_ABSYNC_INCR(unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt, int loop)
{	
	int i=0;
	unsigned long j=0;
	int dma_ch = 0, tcc = EDMA_TCC_ANY;
	int rtn = 0;
  //printk("<1>size of long is %ld\n", sizeof(long));
	rtn = davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "AB-SYNC_DMA0", callback, NULL, &dma_ch, &tcc, event_q);
	if(rtn != 0)
	{
		printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel %d Error Val= %d\n", dma_ch, rtn);
		return;
	}

	for(i=0; i<loop; i++){
		printk(KERN_INFO" \n\nLoop count is: %d\n ", i);
		if(PASS != ST_EdmaMemToMemCpyTest_ABSYNC_INCR(ACnt, BCnt, CCnt, 0, dma_ch))
		{
			printk(KERN_INFO"Stress Test Failed when loop is %d\n", i);
			break;
		}
		
		for(j =0; j < 100000000; j++)
			asm("NOP");
	}
	davinci_free_dma(dma_ch);
}

// Working Code.
// A-SYNC Mode, INCR Mode 
int ST_EdmaMemToMemCpyTest_ASYNC_INCR(unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt, int is_open_chan, int dma_channel)
{
	int dma_ch = 0, tcc = EDMA_TCC_ANY , count = 0,  failure_flag = 0, indx = 0;
	short srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, BCntRdl = 0 ;
       	unsigned int loop=0;
	int rtn = 0;

	struct paramentry_descriptor Param_entry;
	
	BCntRdl = BCnt;
	
	for (count = 0; count < (ACnt * BCnt * CCnt) ; count++) 
    	{
		srcBuff1[count] = 'A' + (count % 26);	
		dstBuff1[count] = 0;
	}

	if(is_open_chan)
	{
		rtn = davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch, &tcc, event_q);
		if(rtn != 0)
		{
      			printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel %d Error Val= %d\n", dma_ch, rtn);
			return 0;
			
		}
	}
	else
		dma_ch = dma_channel;

  printk("allocated dma_ch=%d", dma_ch);

	davinci_set_dma_src_params(dma_ch, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	
	davinci_set_dma_dest_params (dma_ch, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);
	
	srcbidx = desbidx = ACnt;
	srccidx = descidx = ((ACnt * BCnt) - (ACnt * (BCnt - 1)));
	davinci_set_dma_src_index(dma_ch, srcbidx, srccidx);
					
	davinci_set_dma_dest_index(dma_ch, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch, ACnt, BCnt, CCnt, BCntRdl, ASYNC);

	loop=(BCnt * CCnt);
	
#ifdef DISPLAY_INFO
	printk(KERN_INFO" Before trigger EDMA \n");
	davinci_get_dma_params(dma_ch, &Param_entry);
	OPT_Func(Param_entry.opt);
#endif	
  printk("Before trigger, allocated dma_ch=%d", dma_ch);
	EDMA_Trigger(dma_ch, loop);
  printk("After trigger, allocated dma_ch=%d", dma_ch);
	printk(KERN_INFO"Comparing SRC and DST buffer...\n");
	//compairing srcBuff with dstBuff
	for (indx= 0; indx < (ACnt * BCnt * CCnt); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest_ASYNC_INCR: EDMA :Data write-read matching failed at = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

#ifdef DISPLAY_BUFFER	
	for (count = 0; count < (ACnt * BCnt * CCnt); count++) 
		printk("srcBuff [ %d ] is = %c and DesBuff [ %d ] is = %c\n", count, srcBuff1[count], count, dstBuff1[count]);
#endif		

	//printk(KERN_INFO"ST_EdmaMemToMemCpyTest_ASYNC_INCR: EDMA :Src_Addr = %p Dest_Addr %p\n",srcBuff1, dstBuff1);		
	if(failure_flag)
	{
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest_ASYNC_INCR: EDMA Data Transfer Failed For Channel %d\n", dma_ch);		
		davinci_free_dma( dma_ch);
		return FAIL;
	}
	else
	{
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest_ASYNC_INCR: EDMA Data Transfer Successfull For Channel %d\n", dma_ch);
	}

//	printk(KERN_INFO "\"ST_EdmaMemToMemCpyTest_ASYNC_INCR: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch);

	if(is_open_chan)
	davinci_free_dma( dma_ch);
	return PASS;
}

// A-SYNC Mode, FIFO Mode 

void ST_EdmaMemToMemCpyTest_ASYNC_FIFO (unsigned short ACnt, unsigned short BCnt, unsigned short CCnt)
{
	int dma_ch = 0, tcc = EDMA_TCC_ANY , count = 0,  failure_flag = 0, indx = 0;
	short srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, BCntRdl = 0,temp1=0,temp2=0;
	unsigned int loop;
	int rtn = 0;
	struct paramentry_descriptor Param_entry;

	printk(KERN_INFO "Src Addr = %p and Dst Addr= %p", srcBuff1,dstBuff1);
		
#if 0
	/* 32 byte Aligning SRC and DST Index */
	temp1=ACnt;
	temp1=((temp1+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));
//	temp1=ACnt;
	srcbidx = desbidx = temp1;

	temp2=((ACnt * BCnt) - (ACnt * (BCnt - 1)));
	
	temp2=((temp2+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));
	//temp2=((ACnt * BCnt) - (ACnt * (BCnt - 1)));
#endif

	temp1 = ACnt;
	temp2 = ((ACnt * BCnt) - (ACnt * (BCnt - 1)));

	for (count = 0; count < (ACnt * BCnt * CCnt) ; count++) 
        {
            srcBuff1[count] = 'A' + (count % 26);
            dstBuff1[count] = 0;
	}
	
	rtn = davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch, &tcc, event_q);

		if(rtn != 0)
		{
      			printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel %d Error Val= %d\n", dma_ch, rtn);
			return;
			
		}
	davinci_set_dma_src_params(dma_ch, virt_to_phys((unsigned int *)(srcBuff1)), FIFO, W256BIT);
  	davinci_set_dma_dest_params (dma_ch, virt_to_phys((unsigned int *)dstBuff1), FIFO, W256BIT);

	//davinci_set_dma_src_params(dma_ch, virt_to_phys((unsigned int *)srcBuff1), FIFO, W8BIT);
  	//davinci_set_dma_dest_params (dma_ch, virt_to_phys((unsigned int *)dstBuff1), FIFO, W8BIT);

	srcbidx = desbidx = temp1;
	srccidx = descidx =temp2 ;
	
	davinci_set_dma_src_index(dma_ch, srcbidx, srccidx);
					
	davinci_set_dma_dest_index(dma_ch, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch, ACnt, BCnt, CCnt, BCntRdl, ASYNC);
	//davinci_set_dma_transfer_params(dma_ch, 128, 2, 1, 2, ASYNC);
	
	loop=BCnt * CCnt;

//Setting the SAM Bit.
printk(KERN_INFO" Before trigger EDMA \n");
#ifdef DISPLAY_INFO
	davinci_get_dma_params(dma_ch, &Param_entry);
	OPT_Func(Param_entry.opt);
//	Param_entry.opt|=0x00000001;
//	davinci_set_dma_params(dma_ch, &Param_entry);
//	davinci_get_dma_params(dma_ch, &Param_entry);
#endif	
	
	EDMA_Trigger(dma_ch, loop);
		
	for (indx= 0; indx < (ACnt * BCnt * CCnt); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: srcBuff1[%u]=%u and dstBuff1[%u]=%u\n", indx, srcBuff1[indx], indx, dstBuff1[indx]);		
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at = %u\n",indx);
			failure_flag = 1;
			//break;
		}
	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull\n");

#ifdef DISPLAY_BUFFER	
	int i;
	for (i = 0; i < (ACnt * BCnt * CCnt); i++) 
		printk("srcBuff [ %d ] is = %d and DesBuff [ %d ] is = %c\n", i, srcBuff1[i], i, dstBuff1[i]);
#endif
		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch);

	davinci_free_dma( dma_ch);

}

// Working Code.
// AB-SYNC Mode , INCR mode.
\
int ST_EdmaMemToMemCpyTest_ABSYNC_INCR (unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt, int is_open_chan, int dma_channel)
{
	int dma_ch = 0, tcc = EDMA_TCC_ANY , count = 0,failure_flag = 0, indx = 0;
	short srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, BCntRdl = 0;
	unsigned int loop;
	int rtn = 0;	
	BCntRdl = BCnt;
	struct paramentry_descriptor Param_entry;
	
	for (count = 0; count < (ACnt * BCnt * CCnt) ; count++) 
        {
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
	}
	
	if((is_open_chan==1))
		rtn = davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "AB-SYNC_DMA0", callback, NULL, &dma_ch, &tcc, event_q);
		if(rtn != 0)
		{
      			printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel %d Error Val= %d\n", dma_ch, rtn);
			return 0;
			
		}
	else
		dma_ch = dma_channel;

printk("<1>dma_ch is %d\n", dma_ch);

	davinci_set_dma_src_params(dma_ch, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	
	davinci_set_dma_dest_params (dma_ch, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);
	
	srcbidx = desbidx = ACnt;
	
	srccidx = descidx = (ACnt * BCnt) ;
	
	davinci_set_dma_src_index(dma_ch, srcbidx, srccidx);
					
	davinci_set_dma_dest_index(dma_ch, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch, ACnt, BCnt, CCnt, BCntRdl, ABSYNC);

	loop=CCnt;
  
#ifdef DISPLAY_INFO
	printk(KERN_INFO" Before trigger EDMA \n");
	davinci_get_dma_params(dma_ch, &Param_entry);
	OPT_Func(Param_entry.opt);
#endif	

	EDMA_Trigger(dma_ch, loop);
printk("<1>dma_ch after trigger is %d\n", dma_ch);

	printk(KERN_INFO"Comparing SRC and DST buffer...\n");
	for (indx= 0; indx < (ACnt * BCnt * CCnt); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest_AB_SYNC_INCR: EDMA :Data write-read matching failed at = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

#ifdef DISPLAY_BUFFER 
	int i;		
	for (i = 0; i < (ACnt * BCnt * CCnt); i++) 
		printk(KERN_INFO"srcBuff [ %d ] is = %d and DesBuff [ %d ] is = %d\n", i, srcBuff1[i], i, dstBuff1[i]);
		
	//printk(KERN_INFO "\"ST_EdmaMemToMemCpyTest_AB_SYNC_INCR: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch);
#endif 

	if(failure_flag)
	{
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest_AB_SYNC_INCR: EDMA Data Transfer Failed For Channel %d\n", dma_ch);		
		davinci_free_dma( dma_ch);
		return FAIL;
	}
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest_AB_SYNC_INCR: EDMA Data Transfer Successfull For Channel %d\n", dma_ch);

	if((is_open_chan==1))
	davinci_free_dma( dma_ch);

	return PASS;
}

// AB-SYNC Mode, FIFO 

void ST_EdmaMemToMemCpyTest_ABSYNC_FIFO (unsigned short ACnt, unsigned short BCnt, unsigned short CCnt)
{
	int dma_ch = 0, tcc = EDMA_TCC_ANY , count = 0, failure_flag = 0, indx = 0;
	short srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, BCntRdl = 0, rtn;
	unsigned int loop=0;
	struct paramentry_descriptor Param_entry;
//	ACnt = 32; 
//	BCnt = 4; 
//	CCnt = 2;
	
	BCntRdl = BCnt;
	
	for (count = 0; count < (ACnt * BCnt * CCnt) ; count++) 
        {
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
	}
	
	rtn = davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "AB-SYNC_DMA0", callback, NULL, &dma_ch, &tcc, event_q);
    	printk(KERN_INFO" davinci_request_dma: rtn= %d\n", rtn);
	if(rtn!=0)
    {
      printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel %d Error Val= %d\n", dma_ch, rtn);
	return;
    }  
    rtn=0;

	davinci_set_dma_src_params(dma_ch, virt_to_phys((unsigned int *)(srcBuff1)), FIFO, W16BIT);
	
	davinci_set_dma_dest_params (dma_ch, virt_to_phys((unsigned int *)(dstBuff1)), FIFO, W16BIT);
	
	srcbidx = desbidx = ACnt;
	
	srccidx = descidx = (ACnt * BCnt) ;
	
	davinci_set_dma_src_index(dma_ch, srcbidx, srccidx);
					
	davinci_set_dma_dest_index(dma_ch, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch, ACnt, BCnt, CCnt, BCntRdl, ABSYNC);

//Setting the SAM Bit 

	loop=CCnt;
	EDMA_Trigger(dma_ch, loop);

	for (indx= 0; indx < (ACnt * BCnt * CCnt); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull\n");

#if 0
		
	for (i = 0; i < (ACnt * BCnt * CCnt); i++) 
		printk(KERN_INFO"srcBuff [ %d ] is = %d and DesBuff [ %d ] is = %c\n", i, srcBuff1[i], i, dstBuff1[i]);
#endif
		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch);


	davinci_free_dma( dma_ch);

}

void OPT_Func(unsigned int opt)
{

	unsigned int temp = opt;

	temp=(opt & 0x00800000)>>23;
	printk(KERN_INFO" OPT: Intermediate Chaining Enabled [1] or Disbaled [0]:\t %x\n", temp );
	temp = opt;
	printk(KERN_INFO" OPT: Transfer Complete Chaining Enabled: Chaining Enabled [1] or Chaining Disbaled [0]:\t %x\n", (temp & 0x00400000)>>22);
	temp = opt;
	printk(KERN_INFO" OPT: Intermediate Transfer compeletion Interrupt Enabled: Interrupt Enabled [1] or Interrupt Disbaled [0]:\t %x\n", (temp & 0x00200000)>>21);
	temp = opt;
	printk(KERN_INFO" OPT: Transfer complete Interrupt Enable: Interrupt Enabled [1] or Interupt Disbaled [0]:\t %x\n", (temp & 0x00100000)>>20);
        temp = opt;
        printk(KERN_INFO" OPT: Transfer Compelete Code: \t %x\n", (temp & 0x000003F000)>>12);	
        temp = opt;
	printk(KERN_INFO" OPT: Transfer Compelete Mode: Normal mode [0] Early Completion [1]:\t %x\n", (temp & 0x00000800)>>11);
	temp = (opt & 0x00000F00)>>8;
	printk(KERN_INFO" OPT: FIFO Width 8 [0] 16 [1] 32 [2] 64 [3] 128 [4] 256 [5] RESERVED [6]:\t %x\n",temp );
	temp = opt;
	printk(KERN_INFO" OPT: Transfer Sync Mode: A-SYNC [0] AB-SYNC [1]:\t %x\n", (temp & 0x00000004)>>2);
	temp = opt;
	printk(KERN_INFO" OPT: Destination Address Mode: INCR [0]  FIFO [1] Mode [0]:\t %x\n", (temp & 0x00000002)>>1);
	temp = opt;
	printk(KERN_INFO" OPT: Source Address Mode: INCR [0]  FIFO [1] Mode [0]:\t %x\n", (temp & 0x00000001));	
}

// Linking
// Working Code.
// A-SYNC Mode, INCR Mode 


void ST_EdmaLinkTest_ASYNC_INCR (unsigned short ACnt1 ,unsigned short BCnt1 , unsigned short CCnt1, unsigned short ACnt2 ,unsigned short BCnt2 , unsigned short CCnt2)
{
	int dma_ch1 = 0, dma_ch2 = 0, tcc1 = EDMA_TCC_ANY , tcc2 = EDMA_TCC_ANY , count = 0,  indx = 0;
	short  int  srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, temp = 0, rtn=0;
	unsigned short BCntRdl1 = 0;
	unsigned short BCntRdl2 = 0;
	int failure_flag=0, failure_flag1=0, failure_flag2=0;
	struct paramentry_descriptor Param_entry;
	//struct paramentry_descriptor Param_entry = {0, };

	BCntRdl1 = BCnt1;
	BCntRdl2 = BCnt2;	
	for (count = 0; count < (ACnt1 * BCnt1 * CCnt1) ; count++) 
        {
        
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
	}
	
	for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++) 
	{
	    srcBuff2[count] = 'a' + (count % 26);	
            dstBuff2[count] = 0;
	}
	
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch1, &tcc1, event_q);

		if(rtn!=0)
		{
		  printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 1 Error Val= %d\n", rtn);
			return;
		 // printk(KERN_INFO" davinci_request_dma:\t %d\n", rtn);
		 // exit(1);
		}  
		rtn=0;
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch2, &tcc2, event_q);

		if(rtn!=0)
		{
		  printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 2 Error Val= %d\n", rtn);
			return;
		  //exit(1);
		}
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", EDMA_QDMA_CHANNEL_ANY);
	
		printk(KERN_INFO" Channel -1 = %d\n", dma_ch1);
		printk(KERN_INFO" Channel -2 = %d\n", dma_ch2);
			
	//davinci_request_dma(DAVINCI_EDMA_PARAM_ANY, "A-SYNC_LINK_DMA0", callback, NULL, &dma_ch2, &tcc2, event_q);
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", DAVINCI_EDMA_PARAM_ANY);

//Channel -1 Configs	
	davinci_set_dma_src_params(dma_ch1, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch1, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);

	srcbidx = desbidx =ACnt1;
	srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

	davinci_set_dma_src_index(dma_ch1, srcbidx, srccidx);
	davinci_set_dma_dest_index(dma_ch1, desbidx, descidx);	
	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ASYNC);

//Channel -2 Configs	
	davinci_set_dma_src_params(dma_ch2, virt_to_phys((unsigned int *)(srcBuff2)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	
	temp=ACnt2;
	//temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srcbidx = desbidx =temp;

	temp=((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));
	//temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srccidx = descidx = temp;

	davinci_set_dma_src_index(dma_ch2, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch2, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);

#ifdef DISPLAY_INFO
printk(KERN_INFO" Before link and trigger EDMA \n");
davinci_get_dma_params(dma_ch1, &Param_entry);
OPT_Func(Param_entry.opt);
davinci_get_dma_params(dma_ch2, &Param_entry);
OPT_Func(Param_entry.opt);
#endif	

#if 0
	davinci_get_dma_params(dma_ch2, &Param_entry);
	OPT_Func(Param_entry.opt);
	Param_entry.opt|=0x00000001;
	davinci_set_dma_params(dma_ch2, &Param_entry);
	davinci_get_dma_params(dma_ch2, &Param_entry);
#endif	
		// Linking the channels
	printk("\n\nParams of  Before Linked the DMA-1 and DMA-2 channels\n\n");
	davinci_dma_link_lch(dma_ch1, dma_ch2);
	
	printk("\n\nLinked the DMA-1 and DMA-2 channels\n\n");

	EDMA_Trigger(dma_ch1,(BCnt1 * CCnt1));
	
	//This is for Src-1 and Dest-1		
#if  0
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}

#endif	


	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] !=(dstBuff1[indx])) 
		{
			printk(KERN_INFO"ST_EdmaLinkTest_ASYNC_INCR: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag1 = 1;
			break;
		}

	}

#if 0
	for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++) 
	{
	    srcBuff1[count] = 'a' + (count % 26);	
            dstBuff1[count] = 0;
	}
#endif 

	//This is for Src-2 and Dest-2
	//failure_flag = 0; // resetting it back.

	EDMA_Trigger(dma_ch1,(BCnt2 * CCnt2));
	

	for (indx= 0; indx < (ACnt2 * BCnt2 * CCnt2); indx++) 
	{
		if (srcBuff2[indx] !=dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaLinkTest_ASYNC_INCR: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag2 = 1;
			break;
		}

	}

	if((failure_flag1)||(failure_flag2))
		printk(KERN_INFO "ST_EdmaLinkTest_ASYNC_INCR: EDMA Data Transfer Failed\n");		
	else
		printk(KERN_INFO "ST_EdmaLinkTest_ASYNC_INCR: EDMA Data Transfer Successfull\n");

		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);


#if 1  /* unlinking*/
        for (count = 0; count < (ACnt1 * BCnt1 * CCnt1) ; count++)
        {
            srcBuff1[count] = 'A' + (count % 26);
            dstBuff1[count] = 0;
        }

       for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++)
        {
            srcBuff2[count] = 'a' + (count % 26);
            dstBuff2[count] = 0;
        }

	davinci_dma_unlink_lch(dma_ch1, dma_ch2);
	printk("\n\n UNLINKED the DMA-1 and DMA-2 channels\n\n");
			
	davinci_set_dma_src_params(dma_ch1, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	davinci_set_dma_src_params(dma_ch2, virt_to_phys((unsigned int *)(srcBuff2)), INCR, W8BIT);
	
	davinci_set_dma_dest_params (dma_ch1, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	
	srcbidx = desbidx =ACnt1;
	srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

	
	davinci_set_dma_src_index(dma_ch1, srcbidx, srccidx);
	davinci_set_dma_dest_index(dma_ch1, desbidx, descidx);	

	srcbidx = desbidx =ACnt2;
	srccidx = descidx = ((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));
	
	davinci_set_dma_src_index(dma_ch2, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch2, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ASYNC);
	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);

	EDMA_Trigger(dma_ch1,(BCnt1 * CCnt1));
	
	//This is for Src-1 and Dest-1				
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES - 1\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - SRC /DES - 1\n");

	//This is for Src-2 and Dest-2
	failure_flag = 0; // set it for negative test. after unlink, the src-2 and dst-2 should not match.

	EDMA_Trigger(dma_ch1,(BCnt2 * CCnt2));
		
	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read do not match starting from SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

  // The data transfer should not happen for second channel.
	if(failure_flag)
		printk(KERN_INFO "ST_EdmaLinkTest_ASYNC_INCR: Unlinking test pass. SRC-2 is not match DST-2\n");		
	else
		printk(KERN_INFO "ST_EdmaLinkTest_ASYNC_INCR: Unlinking test fail. SRC-2 match DST-2\n");

		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);

#endif
		
	davinci_free_dma(dma_ch1);
	davinci_free_dma(dma_ch2);

}

void ST_EdmaLinkTest_ABSYNC_INCR (unsigned short ACnt1 ,unsigned short BCnt1 , unsigned short CCnt1, unsigned short ACnt2 ,unsigned short BCnt2 , unsigned short CCnt2)
{
	int dma_ch1 = 0, dma_ch2 = 0, tcc1 = EDMA_TCC_ANY , tcc2 = EDMA_TCC_ANY , count = 0,  indx = 0;
	short  int  srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, temp = 0, rtn=0;
	unsigned short BCntRdl1 = 0;
	unsigned short BCntRdl2 = 0;
	int failure_flag=0, failure_flag1=0, failure_flag2=0;
	struct paramentry_descriptor Param_entry;
	//struct paramentry_descriptor Param_entry = {0, };

	BCntRdl1 = BCnt1;
	BCntRdl2 = BCnt2;	
	for (count = 0; count < (ACnt1 * BCnt1 * CCnt1) ; count++) 
        {
        
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
	}
	
	for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++) 
	{
	    srcBuff2[count] = 'a' + (count % 26);	
            dstBuff2[count] = 0;
	}
	
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "AB-SYNC_LINK_DMA0", callback, NULL, &dma_ch1, &tcc1, event_q);
	printk(KERN_INFO"dma_ch1=%d\n", dma_ch1);
		//if(rtn!=0)
		if(rtn<0)
		{
		  	printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 1 Error Val= %d\n", rtn);
			return;
		}  
		rtn=0;
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "AB-SYNC_LINK_DMA1", NULL, NULL, &dma_ch2, &tcc2, event_q);

		//if(rtn!=0)
		if(rtn<0)
		{
		  printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 2 Error Val= %d\n", rtn);
			return;
		  //exit(1);
		}
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", EDMA_QDMA_CHANNEL_ANY);
	
		printk(KERN_INFO" Channel -1 = %d\n", dma_ch1);
		printk(KERN_INFO" Channel -2 = %d\n", dma_ch2);
	
		
	//davinci_request_dma(DAVINCI_EDMA_PARAM_ANY, "A-SYNC_LINK_DMA0", callback, NULL, &dma_ch2, &tcc2, event_q);
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", DAVINCI_EDMA_PARAM_ANY);

//Channel -1 Configs
	
	davinci_set_dma_src_params(dma_ch1, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch1, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);


	srcbidx = desbidx =ACnt1;
	//srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));
	srccidx = descidx = (ACnt1 * BCnt1);
	
	davinci_set_dma_src_index(dma_ch1, srcbidx, srccidx);
	davinci_set_dma_dest_index(dma_ch1, desbidx, descidx);	


	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ABSYNC);

//Channel -2 Configs	

	davinci_set_dma_src_params(dma_ch2, virt_to_phys((unsigned int *)(srcBuff2)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	
	temp=ACnt2;
	//temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srcbidx = desbidx =temp;

	//temp=((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));
	//temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	

	temp=(ACnt2 * BCnt2);
	srccidx = descidx = temp;
	
	davinci_set_dma_src_index(dma_ch2, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch2, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ABSYNC);

#ifdef DISPLAY_INFO
printk(KERN_INFO" Before linking and trigger EDMA \n");
davinci_get_dma_params(dma_ch1, &Param_entry);
OPT_Func(Param_entry.opt);
davinci_get_dma_params(dma_ch2, &Param_entry);
OPT_Func(Param_entry.opt);
#endif	

#if 0
	davinci_get_dma_params(dma_ch2, &Param_entry);
	OPT_Func(Param_entry.opt);
	Param_entry.opt|=0x00000001;
	davinci_set_dma_params(dma_ch2, &Param_entry);
	davinci_get_dma_params(dma_ch2, &Param_entry);
#endif	
		// Linking the channels
	printk("\n\nParams of  Before Linked the DMA-1 and DMA-2 channels\n\n");
	davinci_dma_link_lch(dma_ch1, dma_ch2);

	printk("\n\nLinked the DMA-1 and DMA-2 channels\n\n");

	EDMA_Trigger(dma_ch1,CCnt1);
	
	//This is for Src-1 and Dest-1	
		
#if  0
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}
#endif	

	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] !=(dstBuff1[indx])) 
		{
			printk(KERN_INFO"ST_EdmaLinkTest_ASYNC_INCR: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag1 = 1;
			break;
		}

	}

#if 0
	for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++) 
	{
	    srcBuff1[count] = 'a' + (count % 26);	
            dstBuff1[count] = 0;
	}
#endif 

	//This is for Src-2 and Dest-2
	//failure_flag = 0; // resetting it back.

	EDMA_Trigger(dma_ch1,(CCnt2));
	

	for (indx= 0; indx < (ACnt2 * BCnt2 * CCnt2); indx++) 
	{
		if (srcBuff2[indx] !=dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaLinkTest_ASYNC_INCR: EDMA :Data write-read do not match at SRC/DES - 2:\t = %u\n",indx);
			failure_flag2 = 1;
			break;
		}

	}

	if((failure_flag1)||(failure_flag2))
		printk(KERN_INFO "ST_EdmaLinkTest_ASYNC_INCR: EDMA Data Transfer Failed\n");		
	else
		printk(KERN_INFO "ST_EdmaLinkTest_ASYNC_INCR: EDMA Data Transfer Successfull\n");

		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);


#if 1   /* unlinking*/
       for (count = 0; count < (ACnt1 * BCnt1 * CCnt1) ; count++)
        {
            srcBuff1[count] = 'A' + (count % 26);
            dstBuff1[count] = 0;
        }

       for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++)
        {
            srcBuff2[count] = 'a' + (count % 26);
            dstBuff2[count] = 0;
        }

	davinci_dma_unlink_lch(dma_ch1, dma_ch2);
	printk("\n\n UNLINKED the DMA-1 and DMA-2 channels\n\n");

			
	davinci_set_dma_src_params(dma_ch1, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	davinci_set_dma_src_params(dma_ch2, virt_to_phys((unsigned int *)(srcBuff2)), INCR, W8BIT);
	
	davinci_set_dma_dest_params (dma_ch1, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	
	srcbidx = desbidx =ACnt1;
	srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

	
	davinci_set_dma_src_index(dma_ch1, srcbidx, srccidx);
	davinci_set_dma_dest_index(dma_ch1, desbidx, descidx);	

	srcbidx = desbidx =ACnt2;
	srccidx = descidx = ((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));

	
	davinci_set_dma_src_index(dma_ch2, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch2, desbidx, descidx);


	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ASYNC);
	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);

	EDMA_Trigger(dma_ch1,(BCnt1 * CCnt1));
	
	//This is for Src-1 and Dest-1		
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES - 1\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - SRC /DES - 1\n");

	//This is for Src-2 and Dest-2
	failure_flag = 0; // resetting it back.

	EDMA_Trigger(dma_ch1,(BCnt2 * CCnt2));
	
	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read do not match at SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

  // The data transfer should not happen for second channel.
	if(failure_flag)
		printk(KERN_INFO "ST_EdmaLinkTest_ASYNC_INCR: Unlinking test pass. SRC-2 is not match DST-2\n");		
	else
		printk(KERN_INFO "ST_EdmaLinkTest_ASYNC_INCR: Unlinking test fail. SRC-2 match DST-2\n");

		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);
#endif
		
	davinci_free_dma(dma_ch1);
	davinci_free_dma(dma_ch2);

}

void ST_QdmaLinkTest_ASYNC_INCR (unsigned short ACnt1, unsigned short BCnt1, unsigned short CCnt1, unsigned short ACnt2, unsigned short BCnt2, unsigned short CCnt2, unsigned short ACnt3, unsigned short BCnt3, unsigned short CCnt3 )
{
	int dma_ch1 = 0, dma_ch2 = 0, dma_ch3=0, tcc1 = EDMA_TCC_ANY, tcc2 = EDMA_TCC_ANY, count = 0, failure_flag = 0, indx = 0;
	short  int  srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, temp = 0, rtn=0;
	unsigned short BCntRdl1 = 0, BCntRdl2 = 0, BCntRdl3 = 0;
	//short  int ACnt1, BCnt1,CCnt1, BCntRdl1 = 0;
	//short  int ACnt2, BCnt2,CCnt2, BCntRdl2 = 0;
	//short  int ACnt3, BCnt3,CCnt3, BCntRdl3 = 0;
	struct paramentry_descriptor Param_entry = {0, };
	
	BCntRdl1 = BCnt1;
	BCntRdl2 = BCnt2;	
	BCntRdl3 = BCnt3;		
	
	for (count = 0; count < (ACnt1 * BCnt1 * CCnt1) ; count++) 
        {
        
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
	}
	
	for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++) 
	{
	    srcBuff2[count] = 'a' + (count % 26);	
            dstBuff2[count] = 0;
	}
	
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch1, &tcc1, event_q);

	if(rtn!=0)
	{
		printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 1 Error Val= %d\n", rtn);
		return;
	}  
	rtn=0;
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch2, &tcc2, event_q);

	if(rtn!=0)
	{
	  printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 2 Error Val= %d\n", rtn);
		return;
	  //exit(1);
	}
	rtn=davinci_request_dma(EDMA_QDMA_CHANNEL_ANY, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch2, &tcc2, event_q);

	if(rtn!=0)
	{
	  printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 3 Error Val= %d\n", rtn);
		return;
	  //exit(1);
	}
		
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", EDMA_QDMA_CHANNEL_ANY);
	
	printk(KERN_INFO" Channel -1 = %d\n", dma_ch1);
	printk(KERN_INFO" Channel -2 = %d\n", dma_ch2);
	printk(KERN_INFO" Channel -2 = %d\n", dma_ch3);	
		
	//davinci_request_dma(DAVINCI_EDMA_PARAM_ANY, "A-SYNC_LINK_DMA0", callback, NULL, &dma_ch2, &tcc2, event_q);
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", DAVINCI_EDMA_PARAM_ANY);

//Channel -1 Configs
	
	davinci_set_dma_src_params(dma_ch1, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch1, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);


	srcbidx = desbidx =ACnt1;
	srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

	
	davinci_set_dma_src_index(dma_ch1, srcbidx, srccidx);
	davinci_set_dma_dest_index(dma_ch1, desbidx, descidx);	


	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ASYNC);

//Channel -2 Configs	

	davinci_set_dma_src_params(dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	
	temp=ACnt2;
	temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srcbidx = desbidx =temp;


	temp=((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));
	temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srccidx = descidx = temp;
	
	davinci_set_dma_src_index(dma_ch2, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch2, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);

#if 1
	davinci_get_dma_params(dma_ch2, &Param_entry);
	OPT_Func(Param_entry.opt);
	Param_entry.opt|=0x00000001;
	davinci_set_dma_params(dma_ch2, &Param_entry);
	davinci_get_dma_params(dma_ch2, &Param_entry);
#endif	

//Channel -3 Configs	

	davinci_set_dma_src_params(dma_ch3, virt_to_phys((unsigned int *)(dstBuff3)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch3, virt_to_phys((unsigned int *)(dstBuff3)), INCR, W8BIT);
	
	temp=ACnt3;
	temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srcbidx = desbidx =temp;

	temp=((ACnt3 * BCnt3) - (ACnt3 * (BCnt3 - 1)));
	temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srccidx = descidx = temp;
	
	davinci_set_dma_src_index(dma_ch3, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch3, desbidx, descidx);

	davinci_set_dma_transfer_params(dma_ch3,  ACnt3, BCnt3,CCnt3, BCntRdl3, ASYNC);

	// Linking the channels
	printk("\n\nParams of  Before Linked the DMA-1 and DMA-2 channels\n\n");
	davinci_dma_link_lch(dma_ch1, dma_ch3);
		
	printk("\n\nLinked the DMA-1 and DMA-2 channels\n\n");

	EDMA_Trigger(dma_ch1,(BCnt1 * CCnt1));
	
	//This is for Src-1 and Dest-1				
#if  0
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}

#endif	


	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] !=(dstBuff1[indx])) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES - 1\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - SRC /DES - 1\n");

	//This is for Src-2 and Dest-2
	failure_flag = 0; // resetting it back.

	EDMA_Trigger(dma_ch1,(BCnt2 * CCnt2));
	
#if 0	
	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

#endif 

	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff2[indx] !=dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES -2\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - - SRC /DES -2\n");

	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);

//Param Entry 

	EDMA_Trigger(dma_ch2,(BCnt2 * CCnt2));
	
	//This is for Src-1 and Dest-1
	
#if  0
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}

#endif	


	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] !=(dstBuff1[indx])) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES - 1\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - SRC /DES - 1\n");

#if 0   /* unlinking*/

	davinci_dma_unlink_lch(dma_ch1, dma_ch2);
	printk("\n\n UNLINKED the DMA-1 and DMA-2 channels\n\n");

			
	davinci_set_dma_src_params(dma_ch1, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	davinci_set_dma_src_params(dma_ch2, virt_to_phys((unsigned int *)(srcBuff2)), INCR, W8BIT);
	
	davinci_set_dma_dest_params (dma_ch1, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	
	srcbidx = desbidx =ACnt1;
	srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

	
	davinci_set_dma_src_index(dma_ch1, srcbidx, srccidx);
	davinci_set_dma_dest_index(dma_ch1, desbidx, descidx);	

	srcbidx = desbidx =ACnt2;
	srccidx = descidx = ((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));

	
	davinci_set_dma_src_index(dma_ch2, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch2, desbidx, descidx);


	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ASYNC);
	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);



	EDMA_Trigger(dma_ch1,(BCnt1 * CCnt1));

	
	//This is for Src-1 and Dest-1
	
			
		
			
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES - 1\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - SRC /DES - 1\n");

	//This is for Src-2 and Dest-2
	failure_flag = 0; // resetting it back.

	EDMA_Trigger(dma_ch1,(BCnt2 * CCnt2));
	
	
	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

  // The data transfer should not happen for second channel.
	if(failure_flag)
		printk(KERN_INFO "ST_QdmaLinkTest_ASYNC_INCR: Unlinking test pass. SRC-2 is not match DST-2\n");		
	else
		printk(KERN_INFO "ST_QdmaLinkTest_ASYNC_INCR: Unlinking test fail. SRC-2 match DST-2\n");

		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);



#endif
		
	davinci_free_dma(dma_ch1);
	davinci_free_dma(dma_ch2);
	davinci_free_dma(dma_ch3);
	
}

void ST_MultiLinkTest_ASYNC_INCR (unsigned short ACnt1, unsigned short BCnt1, unsigned short CCnt1, unsigned short ACnt2, unsigned short BCnt2, unsigned short CCnt2, unsigned short ACnt3, unsigned short BCnt3, unsigned short CCnt3)
{
	int dma_ch1 = 0, dma_ch2 = 0, dma_ch3=0, tcc1 = EDMA_TCC_ANY, tcc2 = EDMA_TCC_ANY, count = 0, failure_flag = 0, indx = 0;
	short  int  srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, temp = 0, rtn=0;
	unsigned short BCntRdl1 = 0, BCntRdl2 = 0,  BCntRdl3 = 0;
	struct paramentry_descriptor Param_entry = {0, };
	
	BCntRdl1 = BCnt1;
	BCntRdl2 = BCnt2;	
	BCntRdl3 = BCnt3;		
	
	for (count = 0; count < (ACnt1 * BCnt1 * CCnt1) ; count++) 
        {
        
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
	}
	
	for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++) 
	{
	    srcBuff2[count] = 'a' + (count % 26);	
            dstBuff2[count] = 0;
	}
	
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch1, &tcc1, event_q);

		if(rtn!=0)
		{
		  printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 1 Error Val= %d\n", rtn);
			return;
		}  
		rtn=0;
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch2, &tcc2, event_q);

		if(rtn!=0)
		{
		  printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 2 Error Val= %d\n", rtn);
			return;
		}
	rtn=davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch2, &tcc2, event_q);

		if(rtn!=0)
		{
			printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 3 Error Val= %d\n", rtn);
			return;
		  //exit(1);
		}
		
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", EDMA_QDMA_CHANNEL_ANY);
	
		printk(KERN_INFO" Channel -1 = %d\n", dma_ch1);
		printk(KERN_INFO" Channel -2 = %d\n", dma_ch2);
		printk(KERN_INFO" Channel -2 = %d\n", dma_ch3);	
		
	//davinci_request_dma(DAVINCI_EDMA_PARAM_ANY, "A-SYNC_LINK_DMA0", callback, NULL, &dma_ch2, &tcc2, event_q);
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", DAVINCI_EDMA_PARAM_ANY);

//Channel -1 Configs
	
	davinci_set_dma_src_params(dma_ch1, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch1, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);


	srcbidx = desbidx =ACnt1;
	srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

	
	davinci_set_dma_src_index(dma_ch1, srcbidx, srccidx);
	davinci_set_dma_dest_index(dma_ch1, desbidx, descidx);	


	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ASYNC);

//Channel -2 Configs	

	davinci_set_dma_src_params(dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	
	
	

	temp=ACnt2;
	//temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srcbidx = desbidx =temp;


	temp=((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));
	//temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srccidx = descidx = temp;

	
	davinci_set_dma_src_index(dma_ch2, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch2, desbidx, descidx);


	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);


#if 1
	davinci_get_dma_params(dma_ch2, &Param_entry);
	OPT_Func(Param_entry.opt);
	Param_entry.opt|=0x00000001;
	davinci_set_dma_params(dma_ch2, &Param_entry);
	davinci_get_dma_params(dma_ch2, &Param_entry);
#endif	

//Channel -3 Configs	

	davinci_set_dma_src_params(dma_ch3, virt_to_phys((unsigned int *)(dstBuff3)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch3, virt_to_phys((unsigned int *)(dstBuff3)), INCR, W8BIT);
	
	
	

	temp=ACnt3;
	//temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srcbidx = desbidx =temp;


	temp=((ACnt3 * BCnt3) - (ACnt3 * (BCnt3 - 1)));
	//temp=((temp+ CACHE_LINE_SIZE_IN_BYTES - 1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));	
	srccidx = descidx = temp;

	
	davinci_set_dma_src_index(dma_ch3, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch3, desbidx, descidx);


	davinci_set_dma_transfer_params(dma_ch3,  ACnt3, BCnt3,CCnt3, BCntRdl3, ASYNC);

		// Linking the channels
	printk("\n\nParams of  Before Linked the DMA-1 and DMA-2 channels\n\n");
	davinci_dma_link_lch(dma_ch2, dma_ch3);

		
	printk("\n\nLinked the DMA-1 and DMA-2 channels\n\n");

	EDMA_Trigger(dma_ch1,(BCnt1 * CCnt1));

	
	//This is for Src-1 and Dest-1
	
			
		
#if  0
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}

#endif	


	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] !=(dstBuff1[indx])) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}





	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES - 1\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - SRC /DES - 1\n");

	//This is for Src-2 and Dest-2
	failure_flag = 0; // resetting it back.

	EDMA_Trigger(dma_ch1,(BCnt2 * CCnt2));
	
#if 0	
	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

#endif 

	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff2[indx] !=dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}


//Param Entry 

	EDMA_Trigger(dma_ch1,(BCnt3 * CCnt3));

	
	//This is for Src-1 and Dest-1
	
			
		
#if  0
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}

#endif	


	for (indx= 0; indx < (ACnt3 * BCnt3 * CCnt3); indx++) 
	{
		if (srcBuff3[indx] !=(dstBuff3[indx])) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 3:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}





	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES - \n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - SRC /DES - 1\n");

#if 0   /* unlinking*/

	davinci_dma_unlink_lch(dma_ch1, dma_ch2);
	printk("\n\n UNLINKED the DMA-1 and DMA-2 channels\n\n");

			
	davinci_set_dma_src_params(dma_ch1, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	davinci_set_dma_src_params(dma_ch2, virt_to_phys((unsigned int *)(srcBuff2)), INCR, W8BIT);
	
	davinci_set_dma_dest_params (dma_ch1, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);
	davinci_set_dma_dest_params (dma_ch2, virt_to_phys((unsigned int *)(dstBuff2)), INCR, W8BIT);
	
	srcbidx = desbidx =ACnt1;
	srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

	
	davinci_set_dma_src_index(dma_ch1, srcbidx, srccidx);
	davinci_set_dma_dest_index(dma_ch1, desbidx, descidx);	

	srcbidx = desbidx =ACnt2;
	srccidx = descidx = ((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));

	
	davinci_set_dma_src_index(dma_ch2, srcbidx, srccidx);					
	davinci_set_dma_dest_index(dma_ch2, desbidx, descidx);


	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ASYNC);
	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);



	EDMA_Trigger(dma_ch1,(BCnt1 * CCnt1));

	
	//This is for Src-1 and Dest-1
	
			
		
			
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}

	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES - 1\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - SRC /DES - 1\n");

	//This is for Src-2 and Dest-2
	failure_flag = 0; // resetting it back.

	EDMA_Trigger(dma_ch1,(BCnt2 * CCnt2));
	
	
	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES -2\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - - SRC /DES -2\n");

		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);



#endif
		
	davinci_free_dma(dma_ch1);
	davinci_free_dma(dma_ch2);
	davinci_free_dma(dma_ch3);
	
}


void ST_EdmaChainTest_ASYNC_INCR (unsigned short ACnt1 ,unsigned short BCnt1 , unsigned short CCnt1, unsigned short ACnt2 ,unsigned short BCnt2 , unsigned short CCnt2)
{
	int dma_ch1 = 0, dma_ch2 = 0, tcc1 = EDMA_TCC_ANY, tcc2 = EDMA_TCC_ANY, count = 0,  indx = 0;
	short  int  srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0 ;
	//short  int ACnt1, BCnt1,CCnt1, 
	unsigned short BCntRdl1 = 0;
	unsigned short BCntRdl2 = 0;
	//short  int ACnt2, BCnt2,CCnt2, BCntRdl2 = 0;
	int failure_flag1=0, failure_flag2=0;
//edmacc_regs my_edmacc_regs={0, };

	struct paramentry_descriptor Param_entry = {0, };

	BCntRdl1 = BCnt1;
	BCntRdl2 = BCnt2;	
	for (count = 0; count < (ACnt1 * BCnt1 * CCnt1) ; count++) 
        {
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
	}
	
	for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++) 
	{
	    srcBuff2[count] = 'a' + (count % 26);	
            dstBuff2[count] = 0;
	}
	
	davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch1, &tcc1, event_q);
		//printk(KERN_INFO" davinci_request_dma:\t %d\n", EDMA_DMA_CHANNEL_ANY);
		
	davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch2, &tcc2, event_q);
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", EDMA_DMA_CHANNEL_ANY);
	//davinci_request_dma(DAVINCI_EDMA_PARAM_ANY, "A-SYNC_LINK_DMA0", callback, NULL, &dma_ch2, &tcc2, event_q);
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", DAVINCI_EDMA_PARAM_ANY);
#if 0		
	
      	davinci_request_dma(DAVINCI_DMA_GPIO_GPINT1, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch3, &tcc2, event_q);
		printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", EDMA_DMA_CHANNEL_ANY);
#endif

	
	
	
	srcbidx = desbidx =ACnt1;
	srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

//Channel 1
	ChannelParams(dma_ch1,virt_to_phys((unsigned int *)(srcBuff1)),virt_to_phys((unsigned int *)(dstBuff1)),
				INCR,W8BIT,srcbidx , srccidx);

	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ASYNC);


	srcbidx = desbidx =ACnt2;
	srccidx = descidx = ((ACnt2 * BCnt2) - (ACnt2 * (BCnt2 - 1)));
//Channel 2
	ChannelParams(dma_ch2,virt_to_phys((unsigned int *)(srcBuff2)),virt_to_phys((unsigned int *)(dstBuff2)),
				INCR,W8BIT,srcbidx , srccidx);
	
	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);

#if 0
//Channel 3

	ChannelParams(dma_ch3,virt_to_phys((unsigned int *)(srcBuff1)),virt_to_phys((unsigned int *)(dstBuff1)),
				INCR,W8BIT,srcbidx , srccidx);
	
	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);

#endif


		printk(KERN_INFO "BEFORE   CHAINING \n ");
		davinci_get_dma_params(dma_ch1, &Param_entry);
		OPT_Func(Param_entry.opt);

//yan
//printk(KERN_INFO "Register CER value: %d\n", my_edmacc_regs.cer);

		// chaining the channels
		davinci_dma_chain_lch(dma_ch1, dma_ch2);
		printk(KERN_INFO "AFTER CHAINING \n ");

//yan
//printk(KERN_INFO "Register CER value: %d\n", my_edmacc_regs.cer);


		davinci_get_dma_params(dma_ch1, &Param_entry);
		OPT_Func(Param_entry.opt);

//Disable  Transfer Complete Chaining and Enable Intermediate Chaining
#if 0
	davinci_get_dma_params(dma_ch1, &Param_entry);
	OPT_Func(Param_entry.opt);
	Param_entry.opt&=~(0x00600000);	
	Param_entry.opt|=0x00800000;
	davinci_set_dma_params(dma_ch1, &Param_entry);
	//davinci_get_dma_params(dma_ch, &Param_entry);
#endif	
		
		
	//	Param_entry.opt&=~(0x00800000);
	//	Param_entry.opt|=(dma_ch2<<12);
	//	Param_entry.opt|=(0x1<<22);		
		//davinci_set_dma_params(dma_ch1, &Param_entry);	
		

	//	printk(KERN_INFO "AFTER SETTING INTERMEDIATE CHAINING\n ");		
 
		printk("\n\nChained the DMA-1 and DMA-2 channels\n\n");
		davinci_get_dma_params(dma_ch1, &Param_entry);
		OPT_Func(Param_entry.opt);

#if 0

		davinci_dma_chain_lch(dma_ch1, dma_ch3);

		printk("\n\nLinked the DMA-1 and DMA-3 channels\n\n");

		davinci_get_dma_params(dma_ch1, &Param_entry);
		OPT_Func(Param_entry.opt);

#endif
	 	EDMA_Trigger(dma_ch1,(BCnt1 * CCnt1));

//yan
//printk(KERN_INFO "After dma_start, Register CER value: %d\n",my_edmacc_regs.cer);


	
//This is for Src-1 and Dest-1	
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaChainTest_ASYNC_INCR: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag1 = 1;
			break;
		}
	}

	if(failure_flag1)
		printk(KERN_INFO "ST_EdmaChainTest_ASYNC_INCR: EDMA Data Transfer Failed - SRC /DES - 1\n");		
	else
		{
		 printk(KERN_INFO "ST_EdmaChainTest_ASYNC_INCR: EDMA Data Transfer Successfull - SRC /DES - 1\n");
	}
#if 0
		  //clear dstbuf1 as it is used  for channel 3
		 for( count=0;count<(ACnt2 * BCnt2 * CCnt2) ;count++)
 			 dstBuff1[count]=0;	
		}
		
#endif
//This is for Src-2 and Dest-2
//	failure_flag = 0; // resetting it back.

	
	
	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaChainTest_ASYNC_INCR: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag2 = 1;
			break;
		}
	}	

	if((failure_flag1)||(failure_flag2))
		printk(KERN_INFO "ST_EdmaChainTest_ASYNC_INCR: EDMA Data Transfer Failed\n");		
	else
		printk(KERN_INFO "ST_EdmaChainTest_ASYNC_INCR: EDMA Data Transfer Successfull\n");

#if 0		
	for (i = 0; i < (ACnt2 * BCnt2 * CCnt2); i++) 
		printk("srcBuff - 2 [ %d ] is = %c and DesBuff - 2 [ %d ] is = %c\n", i, srcBuff2[i], i, dstBuff2[i]);


//This is for Src-3 and Dest-3
	failure_flag = 0; // resetting it back.


	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES -2\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - - SRC /DES -2\n");



#endif 

		
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
	printk(KERN_INFO "\"EDMA_Set_Params: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);

	davinci_free_dma(dma_ch1);
	davinci_free_dma(dma_ch2);
//	davinci_free_dma(dma_ch3);


}


void ST_EdmaChainTest_ABSYNC_INCR (unsigned short ACnt1 ,unsigned short BCnt1 , unsigned short CCnt1, unsigned short ACnt2 ,unsigned short BCnt2 , unsigned short CCnt2)
{
	int dma_ch1 = 0, dma_ch2 = 0, tcc1 = EDMA_TCC_ANY, tcc2 = EDMA_TCC_ANY, count = 0,  indx = 0;
	short  int  srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0;
	unsigned short BCntRdl1 = 0;
	unsigned short BCntRdl2 = 0;
	int 	 failure_flag1=0, failure_flag2=0;

	struct paramentry_descriptor Param_entry = {0, };


	
	BCntRdl1 = BCnt1;
	BCntRdl2 = BCnt2;	
	for (count = 0; count < (ACnt1 * BCnt1 * CCnt1) ; count++) 
        {
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = '0';
	}
	
	for (count = 0; count < (ACnt2 * BCnt2 * CCnt2) ; count++) 
	{
	    srcBuff2[count] = 'a' + (count % 26);	
            dstBuff2[count] = '0';
	}
	
	davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch1, &tcc1, event_q);
		//printk(KERN_INFO" davinci_request_dma:\t %d\n", EDMA_DMA_CHANNEL_ANY);
		
	davinci_request_dma(EDMA_DMA_CHANNEL_ANY, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch2, &tcc2, event_q);
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", EDMA_DMA_CHANNEL_ANY);
	//davinci_request_dma(DAVINCI_EDMA_PARAM_ANY, "A-SYNC_LINK_DMA0", callback, NULL, &dma_ch2, &tcc2, event_q);
	//	printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", DAVINCI_EDMA_PARAM_ANY);
#if 0		
	
      	davinci_request_dma(DAVINCI_DMA_GPIO_GPINT1, "A-SYNC_LINK_DMA0", NULL, NULL, &dma_ch3, &tcc2, event_q);
		printk(KERN_INFO" davinci_request_dma_LINK:\t %d\n", EDMA_DMA_CHANNEL_ANY);
#endif

	//srcbidx = desbidx =ACnt1;
	//srccidx = descidx = ((ACnt1 * BCnt1) - (ACnt1 * (BCnt1 - 1)));

//Channel 1

	srcbidx = desbidx = ACnt1;
	srccidx = descidx = (ACnt1 * BCnt1) ;


	ChannelParams(dma_ch1,virt_to_phys((unsigned int *)(srcBuff1)),virt_to_phys((unsigned int *)(dstBuff1)),
				INCR,W8BIT,srcbidx , srccidx);

	davinci_set_dma_transfer_params(dma_ch1, ACnt1, BCnt1, CCnt1, BCntRdl1, ABSYNC);


//Channel 2
	srcbidx = desbidx = ACnt2;
	srccidx = descidx = (ACnt2 * BCnt2) ;


	ChannelParams(dma_ch2,virt_to_phys((unsigned int *)(srcBuff2)),virt_to_phys((unsigned int *)(dstBuff2)),
				INCR,W8BIT,srcbidx , srccidx);
	
	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ABSYNC);

	

#if 0
//Channel 3

	ChannelParams(dma_ch3,virt_to_phys((unsigned int *)(srcBuff1)),virt_to_phys((unsigned int *)(dstBuff1)),
				INCR,W8BIT,srcbidx , srccidx);
	
	davinci_set_dma_transfer_params(dma_ch2,  ACnt2, BCnt2,CCnt2, BCntRdl2, ASYNC);

#endif


		printk(KERN_INFO "BEFORE   CHAINING \n ");
		davinci_get_dma_params(dma_ch1, &Param_entry);
		OPT_Func(Param_entry.opt);



		// chaining the channels
		davinci_dma_chain_lch(dma_ch1, dma_ch2);
		printk(KERN_INFO "AFTER CHAINING \n ");


		davinci_get_dma_params(dma_ch1, &Param_entry);
		OPT_Func(Param_entry.opt);
		
	//	Param_entry.opt&=~(0x00800000);
	//	Param_entry.opt|=(dma_ch2<<12);
	//	Param_entry.opt|=(0x1<<22);		
		davinci_set_dma_params(dma_ch1, &Param_entry);	
		

		printk("\n\nChained the DMA-1 and DMA-2 channels\n\n");
		davinci_get_dma_params(dma_ch1, &Param_entry);
		OPT_Func(Param_entry.opt);

#if 0

		davinci_dma_chain_lch(dma_ch1, dma_ch3);

		printk("\n\nLinked the DMA-1 and DMA-3 channels\n\n");

		davinci_get_dma_params(dma_ch1, &Param_entry);
		OPT_Func(Param_entry.opt);

#endif
#ifdef DISPLAY_BUFFER	
	printk("before trigging chain transfer:\n");
	for (indx = 0; indx < (ACnt2 * BCnt2 * CCnt2); indx++) 
		printk("\nsrcBuff [ %d ] is = %c and DesBuff [ %d ] is = %c\n", indx, srcBuff2[indx], indx, dstBuff2[indx]);
#endif		
	 	EDMA_Trigger(dma_ch1,(CCnt1));


	
//This is for Src-1 and Dest-1	
	for (indx= 0; indx < (ACnt1 * BCnt1 * CCnt1); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaChainTest_ABSYNC_INCR: EDMA :Data write-read matching failed at SRC/DES - 1:\t = %u\n",indx);
			failure_flag1 = 1;
			break;
		}

	}	

	
#ifdef DISPLAY_BUFFER	
	for (indx = 0; indx < (ACnt2 * BCnt2 * CCnt2); indx++) 
		printk("srcBuff [ %d ] is = %c and DesBuff [ %d ] is = %c\n", indx, srcBuff2[indx], indx, dstBuff2[indx]);
#endif		

	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaChainTest_ABSYNC_INCR: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag2 = 1;
			break;
		}
	}	

	if((failure_flag1)||(failure_flag2))
		printk(KERN_INFO "ST_EdmaChainTest_ABSYNC_INCR: EDMA Data Transfer Failed\n");		
	else
		printk(KERN_INFO "ST_EdmaChainTest_ABSYNC_INCR: EDMA Data Transfer Successfull\n");

#if 0		
	for (i = 0; i < (ACnt2 * BCnt2 * CCnt2); i++) 
		printk("srcBuff - 2 [ %d ] is = %c and DesBuff - 2 [ %d ] is = %c\n", i, srcBuff2[i], i, dstBuff2[i]);


//This is for Src-3 and Dest-3
	failure_flag = 0; // resetting it back.


	for (indx= 0; indx < (ACnt2 * BCnt2 *CCnt2); indx++) 
	{
		if (srcBuff2[indx] != dstBuff2[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest: EDMA :Data write-read matching failed at SRC/DES - 2:\t = %u\n",indx);
			failure_flag = 1;
			break;
		}
	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Failed - SRC /DES -2\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest: EDMA Data Transfer Successfull - - SRC /DES -2\n");



#endif 

		
//	printk(KERN_INFO "\"ST_EdmaChainTest_ABSYNC_INCR: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch1);
//	printk(KERN_INFO "\"ST_EdmaChainTest_ABSYNC_INCR: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch2);

	davinci_free_dma(dma_ch1);
	davinci_free_dma(dma_ch2);
//	davinci_free_dma(dma_ch3);


}

void ST_QdmaTest_ASYNC_INCR(unsigned short ACnt ,unsigned short BCnt , unsigned short CCnt)
{
	int dma_ch = 0, tcc = EDMA_TCC_ANY, count = 0,  failure_flag = 0, indx = 0,rtn=0, i=0, a=2, b=1;
	short srcbidx = 0, desbidx = 0, srccidx = 0, descidx = 0, BCntRdl = 0 ;
       //unsigned int loop=0;
	   


	
	BCntRdl = BCnt;
	
	for (count = 0; count < (ACnt * BCnt * CCnt) ; count++) 
        {
            srcBuff1[count] = 'A' + (count % 26);	
            dstBuff1[count] = 0;
	}

	
	
	rtn=davinci_request_dma(EDMA_QDMA_CHANNEL_ANY, "A-SYNC_DMA0", callback, NULL, &dma_ch, &tcc, event_q);

	if(rtn!=0)
		{
		  printk(KERN_INFO" davinci_request_dma:CHANNEL ALLOCATION FAILED for Channel 1 Error Val= %d\n", rtn);
		  return;
		}  

	davinci_set_dma_src_params(dma_ch, virt_to_phys((unsigned int *)(srcBuff1)), INCR, W8BIT);
	
	davinci_set_dma_dest_params (dma_ch, virt_to_phys((unsigned int *)(dstBuff1)), INCR, W8BIT);
	
	srcbidx = desbidx = ACnt;
	
	srccidx = descidx = ((ACnt * BCnt) - (ACnt * (BCnt - 1)));
	
	davinci_set_dma_src_index(dma_ch, srcbidx, srccidx);
					
	davinci_set_dma_dest_index(dma_ch, desbidx, descidx);

	davinci_start_dma(dma_ch);

	davinci_set_dma_transfer_params(dma_ch, ACnt, BCnt, CCnt, BCntRdl, ASYNC);

	
 	while(!irqRaised)
 	{
		for(i=0;i<10240;i++)
 		a=a*b;
 	}
 	
	
	
	
	for (indx= 0; indx < (ACnt * BCnt * CCnt); indx++) 
	{
		if (srcBuff1[indx] != dstBuff1[indx]) 
		{
			printk(KERN_INFO"ST_EdmaMemToMemCpyTest_ASYNC_INCR: EDMA :Data write-read matching failed at = %u\n",indx);
			failure_flag = 1;
			break;
		}
		
	}	

	if(failure_flag)
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest_ASYNC_INCR: EDMA Data Transfer Failed\n");		
	else
		printk(KERN_INFO "ST_EdmaMemToMemCpyTest_ASYNC_INCR: EDMA Data Transfer Successfull\n");

#if 0	
	for (i = 0; i < (ACnt * BCnt * CCnt); i++) 
		printk("srcBuff [ %d ] is = %c and DesBuff [ %d ] is = %c\n", i, srcBuff1[i], i, dstBuff1[i]);
#endif
		
	printk(KERN_INFO "\"ST_EdmaMemToMemCpyTest_ASYNC_INCR: davinci_set_dma_transfer_params\" For Channel =%d\n Success\n",dma_ch);

	davinci_free_dma( dma_ch);

}

// A-SYNC Mode, FIFO Mode 




void	 edma_tc_init(unsigned int  Trnsfr_sw)
{

		switch (Trnsfr_sw) 
			{
		        	case 0:
					{


						printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer AB SYNC_INCR MODE \n\n");
						ST_EdmaMemToMemCpyTest_ABSYNC_INCR(ACnt , BCnt , CCnt, 1, 0);
						break;
		        		}	

		        	case 1:
					 {
						
						printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer ASYNC_INCR MODE \n\n");
						ST_EdmaMemToMemCpyTest_ASYNC_INCR(ACnt ,BCnt , CCnt, 1, 0);
						break;
		        		}	

			      case 2:
				  	{


						printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer AB SYNC_FIFO  MODE \n\n");
						ST_EdmaMemToMemCpyTest_ABSYNC_FIFO(ACnt , BCnt, CCnt);
						break;
		        		}	

			      case 3:     
				  	{

						printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer ASYNC_FIFO MODE \n\n");
						ST_EdmaMemToMemCpyTest_ASYNC_FIFO(ACnt , BCnt, CCnt);
						break;
		        		}	

			      case 4:
				  	{
						printk(KERN_INFO" \n\n MEMORY TO MEMORY LINK  Transfer ASYNC_INCR MODE \n\n");
						ST_EdmaLinkTest_ASYNC_INCR(ACnt1 , BCnt1 , CCnt1, ACnt2 , BCnt2 , CCnt2);
						break;
		        		}

			      case 5:     
				  	{
						printk(KERN_INFO" \n\n MEMORY TO MEMORY  Transfer ABSYNC_INCR MODE \n\n");
						ST_EdmaLinkTest_ABSYNC_INCR(ACnt1 , BCnt1 , CCnt1, ACnt2 ,BCnt2 , CCnt2);
						break;
					  
					}

			      case 6:     
				  	{
						printk(KERN_INFO" \n\n MEMORY TO MEMORY Chain Transfer ASYNC_INCR MODE \n\n");
						ST_EdmaChainTest_ASYNC_INCR(ACnt1 , BCnt1 , CCnt1, ACnt2 ,BCnt2 , CCnt2);
						break;
					  
					}
			      case 7:     
				  	{
						printk(KERN_INFO" \n\n MEMORY TO MEMORY Chain Transfer ABSYNC_INCR MODE \n\n");
						ST_EdmaChainTest_ABSYNC_INCR(ACnt1 , BCnt1 , CCnt1, ACnt2 ,BCnt2 , CCnt2);
						break;
					  
					}

			      case 8:     
				  	{
						printk(KERN_INFO" \n\n MEMORY TO MEMORY QDMA link  Transfer ASYNC_INCR MODE \n\n");
					  	ST_QdmaLinkTest_ASYNC_INCR(ACnt1,BCnt1,CCnt1,ACnt2,BCnt2,CCnt2,ACnt3,BCnt3,CCnt3);
						break;
					  
					}
			      case 9:     
				  	{
						printk(KERN_INFO" \n\n MEMORY TO MEMORY QDMA link  Transfer ASYNC_INCR MODE \n\n");
					  	ST_MultiLinkTest_ASYNC_INCR(ACnt1,BCnt1,CCnt1,ACnt2,BCnt2,CCnt2,ACnt3,BCnt3,CCnt3);
						break;
					  
					}
			      case 10:     
				  	{
						printk(KERN_INFO" \n\n MEMORY TO MEMORY QDMA  Transfer ASYNC_INCR MODE \n\n");
					  	ST_QdmaTest_ASYNC_INCR(ACnt ,BCnt , CCnt);
						break;
					}				  
				case 11:
				{
					printk(KERN_INFO" \n\n Stress_ASYNC_INCR \n");
					Stress_ASYNC_INCR(ACnt, BCnt, CCnt, test_loop);
					break;
				}

				case 12:
				{
					printk(KERN_INFO" \n\n Stress_ABSYNC_INCR \n");
					Stress_ABSYNC_INCR(ACnt, BCnt, CCnt, test_loop);
					break;
				}


			}
}





// Proc Entry for EDMA
#if 0


/* The below portion of code is for the sysctl support               
 */
#define DAVINCI_EDMA_LINK_DEBUG

//static int edma_davinci_debug = 0;

static int edma_sysctl_handler(ctl_table *ctl, int write, struct file * filp, void __user *buffer, size_t *lenp, loff_t *ppos)
{
	int ret, i=0;
	ret = proc_dointvec(ctl, write, filp, buffer, lenp, ppos);
	if (write) {
    	        int *valp = ctl->data;
		int val = *valp;

		switch (ctl->ctl_name) {
        	case DAVINCI_EDMA_DEBUG:
			{
#if 0

				printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer AB SYNC_INCR MODE \n\n");
				ST_EdmaMemToMemCpyTest_AB_SYNC_INCR();

#endif				
#if 0			

				printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer ASYNC_INCR MODE \n\n");
				ST_EdmaMemToMemCpyTest_ASYNC_INCR();
#endif				

#if 0			

				printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer AB SYNC_FIFO  MODE \n\n");
				ST_EdmaMemToMemCpyTest_AB_SYNC_FIFO();
#endif

#if 0			
     

				printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer ASYNC_FIFO MODE \n\n");
				ST_EdmaMemToMemCpyTest_ASYNC_FIFO();
#endif



#if 1			
				printk(KERN_INFO" \n\n MEMORY TO MEMORY LINK  Transfer ASYNC_INCR MODE \n\n");
				ST_EdmaLinkTest_ASYNC_INCR();


#endif

#if 0			

				printk(KERN_INFO" \n\n MEMORY TO MEMORY Chain Transfer ASYNC_INCR MODE \n\n");
				ST_EdmaChainTest_ASYNC_INCR();


#endif

				break;
			  
			}

		case 2 :							
                     {
				printk(KERN_INFO" \n\n MEMORY TO MEMORY Transfer ASYNC_FIFO MODE \n\n");
                            ST_EdmaMemToMemCpyTest_ASYNC_FIFO();
				break;
			}
#if 0
			if (val == 3)	{
				printk(KERN_INFO" \n\n  MEMORY TO MEMORY Transfer AB-SYNC_INCR MODE \n\n");			
			}	ST_EdmaMemToMemCpyTest_AB_SYNC_INCR();
			if (val == 4)	{
				printk(KERN_INFO" \n\n  MEMORY TO MEMORY Transfer AB-SYNC_FIFO MODE \n\n");
				ST_EdmaMemToMemCpyTest_AB_SYNC_FIFO();
			}			
	            	if (val == 5)	{
				printk(KERN_INFO" \n\n LINK Transfer A-SYNC_INCR MODE - LINK \n\n");

			}
			if (val == 6)	{
				printk(KERN_INFO" \n\n LINK Transfer A-SYNC_INCR MODE - LINK \n\n");

			}
			if (val == 7)	{
				printk(KERN_INFO" \n\n LINK Transfer A-SYNC_INCR MODE - LINK \n\n");

			}
			if (val == 8)	{
				printk(KERN_INFO" \n\n LINK Transfer A-SYNC_INCR MODE - LINK \n\n");

			}
#endif

		}
	}

	return ret;
}

struct edma_sysctl_debug_settings {
		int     test;
} edma_sysctl_debug_settings;

ctl_table edma_debug_table[] = {
	{
	    	.ctl_name       = DAVINCI_EDMA_DEBUG,
	        .procname       = "edma_Debug",
	        .data           = &edma_sysctl_debug_settings.test,
	        .maxlen         = sizeof(int),
	        .mode           = 0644,
	        .proc_handler   = &edma_sysctl_handler,
	},
	{
		.ctl_name = 0
	}
};


static int testDefault = 0;
static struct ctl_table_header *davinci_edma_sysctl_header;

static void edma_davinci_sysctl_register(void)
{
	static int initialized=0;

   	if (initialized == 1)
  	        return;

	davinci_edma_sysctl_header = register_sysctl_table(edma_debug_table, 1);

	/* set the defaults */
	edma_sysctl_debug_settings.test = testDefault;
	initialized = 1;
}

static void edma_davinci_sysctl_unregister(void)
{
	if (davinci_edma_sysctl_header)
  	        unregister_sysctl_table(davinci_edma_sysctl_header);
}

#endif


module_init(edma_test_init);
module_exit(edma_test_exit);



