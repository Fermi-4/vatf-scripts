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


/** \file   vlynq_cpu_transfer.c
    \brief   VLYNQ Performance measurment

     This file contains VLYNQ Test code to measure time taken to transfer data from CPU to VLYNQ space for different data sizes.

    NOTE: THIS FILE IS PROVIDED ONLY FOR INITIAL DEMO RELEASE AND MAY BE
          REMOVED AFTER THE DEMO OR THE CONTENTS OF THIS FILE ARE SUBJECT
          TO CHANGE.

    (C) Copyright 2004, Texas Instruments, Inc

    @author         Jayanthi Sri
    @version    0.1 -
                Created on 29/09/2007
 *  \version   1.1 - Surendra Puduru: Updated prints according to automation requirements
 */

#include <linux/module.h>
#include <asm/io.h>
#include <asm/pgtable.h>

#include <asm/arch/hardware.h>
#include <asm/arch-davinci/memory.h>

#ifdef LSP_1_3_PRODUCT
#include <asm/arch/vlynq/vlynq_os.h>
#include <asm/arch/vlynq/vlynq_dev.h>
#include "kStTimer.h"
#define TEMP_VLYNQ_TYPE
#else /* not LSP_1_3_PRODUCT */
#include <linux/vlynq/vlynq_os.h>
#include <linux/vlynq/vlynq_dev.h>
#include "kStTimer.h"
#define TEMP_VLYNQ_TYPE struct
#endif /* LSP_1_3_PRODUCT */



#define AUTOMATION

#ifdef CONFIG_MACH_DAVINCI_EVM
#define VLYNQ_CONTROL_BASE          (DAVINCI_VLYNQ_BASE)
#endif

#ifdef CONFIG_ARCH_DAVINCI_DM646x
#define VLYNQ_CONTROL_BASE          (DAVINCI_DM646X_VLYNQ_BASE)
#endif


#define VLYNQ_APP_ERROR             -1u
#define VLYNQ_APP_SUCCESS            0u
#define dataCount (2048*4)

/* VLYNQ space */
//#define LOCAL_VLYNQ_TXADR_MAP          (DAVINCI_DM6467_VLYNQ_REMOTE_BASE)
#ifdef CONFIG_MACH_DAVINCI_EVM
#define LOCAL_VLYNQ_TXADR_MAP          (DAVINCI_VLYNQ_REMOTE_BASE)
#endif

#ifdef CONFIG_ARCH_DAVINCI_DM646x
#define LOCAL_VLYNQ_TXADR_MAP          (DAVINCI_DM646X_VLYNQ_REMOTE_BASE)
#endif
#define LOCAL_VLYNQ_REMOTE_ADR         (0xE0000000u) /* DDR */

#define LOCAL_ADDRESS_MAP_OFFSET_1     (LOCAL_VLYNQ_REMOTE_ADR + (0x0u))
#define LOCAL_ADDRESS_MAP_OFFSET_2     (LOCAL_VLYNQ_REMOTE_ADR + (0x3100u))
#define LOCAL_ADDRESS_MAP_OFFSET_3     (LOCAL_VLYNQ_REMOTE_ADR + (0x3200u))
#define LOCAL_ADDRESS_MAP_OFFSET_4     (LOCAL_VLYNQ_REMOTE_ADR + (0x3300u))

#define LOCAL_VLYNQ_RXADRSIZE1         (0x00003100u)   /* Rx-1 Size = 256 Bytes */
#define LOCAL_VLYNQ_RXADRSIZE2         (0x00000100u)   /* Rx-2 Size = 256 Bytes */
#define LOCAL_VLYNQ_RXADRSIZE3         (0x00000100u)   /* Rx-3 Size = 256 Bytes */
#define LOCAL_VLYNQ_RXADRSIZE4         (0x00000100u)   /* Rx-4 Size = 256 Bytes */


/* PEER VLYNQ Configuration */

#define REMOTE_VLYNQ_TXADR_MAP         (0x38000100u) /* VLYNQ space, DM648 side */
#define PEER_VLYNQ_REMOTE_ADR          (0xE0000000u) /* DDR*/

#define PEER_ADDRESS_MAP_OFFSET_1      (PEER_VLYNQ_REMOTE_ADR + (0x0u))
#define PEER_ADDRESS_MAP_OFFSET_2      (PEER_VLYNQ_REMOTE_ADR + (0x3100u))
#define PEER_ADDRESS_MAP_OFFSET_3      (PEER_VLYNQ_REMOTE_ADR + (0x3200u))
#define PEER_ADDRESS_MAP_OFFSET_4      (PEER_VLYNQ_REMOTE_ADR + (0x3300u))

#define PEER_VLYNQ_RXADRSIZE1          (0x00003100u)   /* Rx-1 Size = 256 Bytes */
#define PEER_VLYNQ_RXADRSIZE2          (0x00000100u)   /* Rx-2 Size = 256 Bytes */
#define PEER_VLYNQ_RXADRSIZE3          (0x00000100u)   /* Rx-3 Size = 256 Bytes */
#define PEER_VLYNQ_RXADRSIZE4          (0x00000100u)   /* Rx-4 Size = 256 Bytes */




static TEMP_VLYNQ_TYPE vlynq_config vlynq_cfg;
static TEMP_VLYNQ_TYPE vlynq_dev_hnd *ptr_vlynq_dev = NULL;
static TEMP_VLYNQ_TYPE vlynq_hnd *ptr_vlynq = NULL;
volatile int delayCount = 0;

/* memory mapping of LOCAL & PEER vlynq Regions  */
typedef struct  {
        int id;
        u32 offset;
        u32 size;
        u8 remote;
} region_config_t;

/* Set these values to the RX registers to map regions */
static region_config_t region_config[] = {
        {0, LOCAL_ADDRESS_MAP_OFFSET_1, LOCAL_VLYNQ_RXADRSIZE1, 0},
        {1, LOCAL_ADDRESS_MAP_OFFSET_2, LOCAL_VLYNQ_RXADRSIZE2, 0},
        {2, LOCAL_ADDRESS_MAP_OFFSET_3, LOCAL_VLYNQ_RXADRSIZE3, 0},
        {3, LOCAL_ADDRESS_MAP_OFFSET_4, LOCAL_VLYNQ_RXADRSIZE4, 0},
        {0, PEER_ADDRESS_MAP_OFFSET_1, PEER_VLYNQ_RXADRSIZE1, 1},
        {1, PEER_ADDRESS_MAP_OFFSET_2, PEER_VLYNQ_RXADRSIZE2, 1},
        {2, PEER_ADDRESS_MAP_OFFSET_3, PEER_VLYNQ_RXADRSIZE3, 1},
        {3, PEER_ADDRESS_MAP_OFFSET_4, PEER_VLYNQ_RXADRSIZE4, 1},
        {-1, 0, 0, 0}
};

#define BUFFER_SIZE_IN_WORDS 2048
#define BYTES_PER_WORD 4
#define BUFFER_SIZE_IN_BYTES (BUFFER_SIZE_IN_WORDS*BYTES_PER_WORD)

/* Input and Output Buffers: for loop back */
static u32 TxBuf[BUFFER_SIZE_IN_WORDS];
static u32 RxBuf[BUFFER_SIZE_IN_WORDS];

static int vlynq_initialization(void);
static int EVM_vlynq_init(void);
static int vlynq_cpu_data_transfer(void);
static void vlynq_cpu_transfer_perf_test(void);
static int __init vlynq_test_init(void);
static void vlynq_test_exit(void);

extern void start_Timer(void);
extern u32 stop_Timer(void);



static void vlynq_cpu_transfer_perf_test(void)
{
        int error;


        /* Start VLYNQ intialization */
        error = vlynq_initialization();
        if (error != VLYNQ_APP_SUCCESS)
        {
                printk("VLYNQ Initialization Failed.\n\r");
                return;
        }

        /* checking status of LINK again before sending data */
        if (0u == vlynq_get_link_status(ptr_vlynq))
        {
                printk
                ("VLYNQ MASTER:ERROR: Link is down between LOCAL & PEER.\n\r");
                return;
        }

#ifndef AUTOMATION
        printk
        ("VLYNQ MASTER:SUCCESS: Link is established between LOCAL & PEER.\n\r");

        /* WRITE */
        printk("VLYNQ MASTER :IO Transfer \n\r");
#endif
        error = vlynq_cpu_data_transfer();
        if (VLYNQ_APP_SUCCESS != error)
        {
                printk("VLYNQ MASTER :Error in trasmitting data.\n");
                return;
        }
#ifndef AUTOMATION
        printk("VLYNQ MASTER :Data transfer completed.\n\r");
#endif
}


/*
 * vlynq_initialization
 * Function does VLYNQ initialization.
 *
 * This function will initialize VLYNQ for testing
 *
 */
static int vlynq_initialization(void)
{
        int error;

        /*Initialize the VLYNQ control module */
        error = vlynq_init();
        if (VLYNQ_APP_SUCCESS == error) {
#ifndef AUTOMATION
                printk("VLYNQ MASTER:Success in Initializing vlynq "
                        "configuration \n\r");
#else
                ;
#endif
        } else {
                printk("VLYNQ MASTER:Error  in Initializing vlynq "
                        "configuration \n\r");
                return VLYNQ_APP_ERROR;
        }

        /* Configure the LOCAL & PEER vlynq devices, maintain vlynq device chain And after
        setting up the memory map of regions create a link between them. so after
        successful execution of this function, a LINK established between LOCAL &
        PEER vlynq. */
        error = EVM_vlynq_init();
        if (VLYNQ_APP_SUCCESS == error) {
#ifndef AUTOMATION
                printk ("VLYNQ MASTER:Success in LOCAL & PEER vlynq "
                        "configuration.\n\r");
#else
                ;
#endif
        } else {
                printk ("VLYNQ MASTER:Error in LOCAL & PEER vlynq "
                        "configuration.\n\r");
                return VLYNQ_APP_ERROR;
        }

        return VLYNQ_APP_SUCCESS;
}


/*
 * EVM_vlynq_init
 * Function creates link between LOCAL and PEER VLYNQ.
 *
 * This function will perform VLYNQ initialization and creates a link between
 * LOCAL & PEER VLYNQ.
 *
 * Returns VLYNQ_APP_SUCCESS if success and VLYNQ_APP_ERROR if failure
 */
static int EVM_vlynq_init(void)
{
        char dev_name[] = "DaVinci";
        int instance = 1;
        int retCode = VLYNQ_APP_SUCCESS;
        u32 virt_addr = 0;
        region_config_t * init_p_region = &region_config[0];
        if(NULL == init_p_region)
        {
                retCode = VLYNQ_APP_ERROR;
        }

#ifdef CONFIG_MACH_DAVINCI_EVM
        virt_addr = IO_ADDRESS(VLYNQ_CONTROL_BASE);
#endif

#ifdef CONFIG_ARCH_DAVINCI_DM646x
        virt_addr = DM646X_VLYNQ_CNTRL_P2V(VLYNQ_CONTROL_BASE);
#endif

        if (VLYNQ_APP_SUCCESS == retCode)
        {
                /* Setup LOCAL & REMOTE vlynq configruation */
                vlynq_cfg.on_soc = 1u;
                vlynq_cfg.base_addr = virt_addr;
                vlynq_cfg.local_clock_dir = VLYNQ_CLK_DIR_OUT;
                vlynq_cfg.local_clock_div = 0x3;
                vlynq_cfg.local_intr_local = 0x1;
                vlynq_cfg.local_intr_vector = 31;
                vlynq_cfg.local_intr_enable = 0;
                vlynq_cfg.local_int2cfg = 1;
                /* Ignored in case int2cfg is set */
                vlynq_cfg.local_intr_pointer = (0x14u);
                vlynq_cfg.local_endianness = VLYNQ_ENDIAN_LITTLE;

#ifdef CONFIG_MACH_DAVINCI_EVM
                vlynq_cfg.local_tx_addr = 0;
#endif

#ifdef CONFIG_ARCH_DAVINCI_DM646x
                vlynq_cfg.local_tx_addr = DAVINCI_DM646X_VLYNQ_REMOTE_BASE;
#endif

                vlynq_cfg.local_rtm_cfg_type = VLYNQ_NO_RTM_CGF;
                vlynq_cfg.local_tx_fast_path = 0u;

                /* Peer Config */
                vlynq_cfg.peer_clock_div = (0x3u);
                vlynq_cfg.peer_clock_dir = VLYNQ_CLK_DIR_IN;
                vlynq_cfg.peer_intr_local = 0x0;
                vlynq_cfg.peer_intr_vector = 30;
                vlynq_cfg.peer_intr_enable = 0;
                vlynq_cfg.peer_int2cfg = 0;
                 /* Valid in case int2cfg is reset */
                vlynq_cfg.peer_intr_pointer = (0x14u);
                vlynq_cfg.peer_endianness = VLYNQ_ENDIAN_LITTLE;
                vlynq_cfg.peer_tx_addr = 0;
                vlynq_cfg.peer_rtm_cfg_type = VLYNQ_NO_RTM_CGF;
                vlynq_cfg.peer_tx_fast_path = 0u;
                vlynq_cfg.init_swap_flag = 0;

                /*  Initialize the VLYNQ control module */
                ptr_vlynq = vlynq_init_soc(&vlynq_cfg);
                if (NULL == ptr_vlynq)
                {
                        printk ("VLYNQ MASTER: Failed to initialize the "
                                "vlynq 0x%08x\n\r", vlynq_cfg.base_addr);
                        printk ("VLYNQ MASTER:The error msg: %s\n\r",
                                vlynq_cfg.error_msg);
                        goto av_vlynq_init_fail;
                }

                /* Create a VLYNQ device in the chain of VLYNQ devices */
                ptr_vlynq_dev = (TEMP_VLYNQ_TYPE vlynq_dev_hnd *) vlynq_dev_create(ptr_vlynq, dev_name,
                                                        instance, 0, 0u);
                if (NULL == ptr_vlynq_dev)
                {
                        printk("VLYNQ MASTER: Failed to create the %s%d "
                                "reference for vlynq\n\r", dev_name, instance);
                        goto av_vlynq_dev_fail;
                }

                /* Add This device in the chain of VLYNQ devices */
                if (VLYNQ_APP_SUCCESS !=vlynq_add_device(ptr_vlynq, ptr_vlynq_dev, 0u))
                {
                        printk("VLYNQ MASTER: Failed to add %s%d reference "
                                "into vlynq\n\r", dev_name, instance);
                        goto av_vlynq_add_device_fail;
                }

                /*
                 * Map the memory regions of the device for remote/local VLYNQ
                 * depending on the region ID to be mapped and the size and
                 * offset.
                 */
                while (init_p_region->id > -1)
                {
                        if (VLYNQ_APP_SUCCESS != vlynq_map_region(ptr_vlynq,
                                                        init_p_region->remote,
                                                        init_p_region->id,
                                                        init_p_region->offset,
                                                        init_p_region->size,
                                                        ptr_vlynq_dev))
                        {
                                init_p_region->id = -1;
                                printk("VLYNQ MASTER: Failed to map regions "
                                        "for %s%d in vlynq\n\r", dev_name,
                                                                instance);
                                goto av_vlynq_map_region_fail;
                        }
                        init_p_region++;
                }
                return VLYNQ_APP_SUCCESS;

                av_vlynq_map_region_fail: printk("VLYNQ MASTER: Un mapping the "
                                                "VLYNQ regions\n\r");

                /*
                 * UnMap the memory regions of the device for remote/local
                 * VLYNQ depending on the region ID to be mapped and the size
                 * and offset.
                 */
                init_p_region = &region_config[0];
                while (init_p_region->id > -1)
                {
                        vlynq_unmap_region(ptr_vlynq, init_p_region->remote,
                        init_p_region->id, ptr_vlynq_dev);
                        init_p_region++;
                }

                /* Remove this VLYNQ device from the chain of VLYNQ devices */
                vlynq_remove_device(ptr_vlynq, ptr_vlynq_dev);

                return (VLYNQ_APP_ERROR);

                av_vlynq_add_device_fail:printk("VLYNQ MASTER: Destroying "
                                                "the VLYNQ device\n\r");

                /* Destroy this VLYNQ device */
                vlynq_dev_destroy(ptr_vlynq_dev);

                return (VLYNQ_APP_ERROR);

                av_vlynq_dev_fail: printk("VLYNQ MASTER:Cleaning up\n\r");

                /* CleanUp this VLYNQ device configuration */
                if (VLYNQ_APP_SUCCESS != vlynq_cleanup(ptr_vlynq))
                {
                        printk("VLYNQ MASTER: It is not a Clean shut down\n\r");
                }

                return (VLYNQ_APP_ERROR);

                av_vlynq_init_fail: return (VLYNQ_APP_ERROR);
        }

        return retCode;
}


/*
 * vlynq_write_test
 * Function performs write operation on VLYNQ.
 *
 * Data transmission from LOCAL VLYNQ to PEER VLYNQ.
 *
 * Returns VLYNQ_APP_SUCCESS if success and VLYNQ_APP_ERROR if failure
 */
static int vlynq_cpu_data_transfer(void)
{
         int wordsTransferred=0;
         u32 *vlynqBuff = NULL;
	 int i=0;
	unsigned long int time_taken;
         

#ifdef CONFIG_MACH_DAVINCI_EVM
        vlynqBuff = (u32 *) DM644X_VLYNQ_REMOTE_P2V(LOCAL_VLYNQ_TXADR_MAP);
#endif

#ifdef CONFIG_ARCH_DAVINCI_DM646x
        vlynqBuff = (u32 *) DM646X_VLYNQ_REMOTE_P2V(LOCAL_VLYNQ_TXADR_MAP);
#endif
	
  
   for(wordsTransferred=256; wordsTransferred <= 2048; wordsTransferred = wordsTransferred*2)
    {
         /* Fill buffer to be transmitted with known values */
        for (i = 0; i < BUFFER_SIZE_IN_WORDS; i++)
        {
                TxBuf[i] = i;
                RxBuf[i] = 0;
        }

	   
#ifndef AUTOMATION
	printk("\nNumber of bytes Written=%d",wordsTransferred*BYTES_PER_WORD);
#else      
        printk("\nVLYNQ: CPU mode write: Buffer Size in Bytes: %d\n", wordsTransferred*BYTES_PER_WORD);
#endif
	
        /* writing data to VLYNQ Remote Memory Map */
	start_Timer();
        for (i = 0; i < wordsTransferred; i++) {
                vlynqBuff[i] = TxBuf[i];/*TxBuf is of size 4 bytes*/
        }
	time_taken = stop_Timer();
#ifdef AUTOMATION
        printk("\nVLYNQ: CPU mode write: Duration in uSec: %ld\n", time_taken);
        printk("\nVLYNQ: CPU mode write: Data Rate in Mbps: %ld\n", (wordsTransferred*BYTES_PER_WORD*8)/ time_taken);
	
#else
        printk("\nWrite Completed");
#endif
       

        /* delay loop to wait untill transmission completes */
        for (delayCount = 0; delayCount < 500; delayCount++) {
        }
       

#ifndef AUTOMATION
	printk("\nNumber of bytes to be read=%d",wordsTransferred*BYTES_PER_WORD);
#else      
        printk("\nVLYNQ: CPU mode read: Buffer Size in Bytes: %d\n", wordsTransferred*BYTES_PER_WORD);
#endif
	 
        /* Reading data to VLYNQ Remote Memory Map */
	start_Timer();
        for (i = 0; i < wordsTransferred; i++) {
                 RxBuf[i]= vlynqBuff[i];
        }
	time_taken = stop_Timer();
#ifdef AUTOMATION
        printk("\nVLYNQ: CPU mode read: Duration in uSec: %ld\n", time_taken);
	printk("\nVLYNQ: CPU mode read: Data Rate in Mbps: %ld\n", (wordsTransferred*BYTES_PER_WORD*8)/ time_taken);
#endif
	
#ifndef AUTOMATION
        printk("\nRead Completed");
#endif
        /* delay loop to wait untill transmission completes */
        for (delayCount = 0; delayCount < 500; delayCount++) {
        }
		
        /*Data Integrity*/
	for (i = 0; i < wordsTransferred; i++)
	{
		if(TxBuf[i] != RxBuf[i])
		{		
		printk("\n Value of TxBuf = 0x%x ,RxBuf = 0x%x ",TxBuf[i],RxBuf[i]); 
		printk("\nData integrity failed at  %d bytes",i);
		}
	}
	
#ifndef AUTOMATION
	printk("\nData integrity Success");
#endif  
    }/*Count*/
   
   	
    return VLYNQ_APP_SUCCESS;
}


static int __init vlynq_test_init(void)
{
#ifndef AUTOMATION
        printk("Starting Vlynq CPU Performance Test Case...\n");
#endif
        vlynq_cpu_transfer_perf_test();

        return 0;
}

static void vlynq_test_exit(void)
{
#ifndef AUTOMATION
        printk("Exiting Vlynq CPU Performance Test Case...\n");
#endif
}

MODULE_AUTHOR("Texas Instruments India");

MODULE_DESCRIPTION("TI DAVINCI VLYNQ Module");
MODULE_LICENSE("GPL");

module_init(vlynq_test_init);
module_exit(vlynq_test_exit);

