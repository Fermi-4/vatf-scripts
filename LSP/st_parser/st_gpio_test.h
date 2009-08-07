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
**|         Copyright (c) 1998-2006 Texas Instruments Incorporated           |**
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

/** \file   ST_GPIO_Test.h
    \brief  Watch Dog Timer Test Functionalities  for DaVinci on Linux

    (C) Copyright 2006, Texas Instruments, Inc

    @author     Anand Patil
    @version    0.1 
    @date 		10/12/2006
                                
 */

#ifndef _ST_GPIO_Test_
#define _ST_GPIO_Test_


#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/interrupt.h>
#include <asm/io.h>
#include <asm/arch/io.h>
#include <asm/arch/hardware.h>
#include <asm/arch/gio.h>
#include <asm/mach-types.h>
#include <asm/mach/arch.h>
#include <asm/mach/map.h>
#include "davinci_gio.h"

#define ST_POLLED 0
#define ST_RISING_EDGE  0
#define ST_IN_PROGRESS 0xFFFF
#define ST_GPIO_OBJECTS 2


#define PINMUX0     __REG(0x01c40000)
#define PINMUX1     __REG(0x01c40004)



/* Structure Definition of GPIO Attribute Object */
struct ST_GPIOAttrs
		{
			int gpio_num;
			int opmode;
			int trig_edge;
			int bank_num;
			int direction;
			int irq_num;
		};


/* Declaration of GPIO Local Function Defintiions */

int 	ST_GPIO_LoopbackFunc(struct ST_GPIOAttrs* gio_tx ,struct ST_GPIOAttrs* gio_rx, int count);
int 	ST_GPIO_ToggleOutput(struct ST_GPIOAttrs* gio_tx );
int 	ST_GPIO_WriteData(struct ST_GPIOAttrs* gio_tx ,int data);
int 	ST_GPIO_ReadData(struct ST_GPIOAttrs* gio_rx);
void ST_GPIO_Init(int gio_tx,int opmode1,int trig1,int dir1, int irq_num1,int gio_rx,int opmode2,int trig2,int dir2 ,int irq_num2, int enble_loopbck, int data_cnt);
void ST_GPIO_regIRQ(struct ST_GPIOAttrs *gio);
void ST_GPIO_Config(struct ST_GPIOAttrs *gio);
void ST_GPIO_GetDirRegInfo(int gio);
void ST_GPIO_GetOutDataRegInfo(int gio);
void ST_GPIO_GetInputDataRegInfo(int gio);
void ST_GPIO_GetInterruptStatusRegInfo(int gio);
void ST_GPIO_unregIRQ(struct ST_GPIOAttrs *gio);


static irqreturn_t ST_GPIO_IRQ_RxHdlr(int irq, void *dev_id, struct pt_regs *regs);
static irqreturn_t ST_GPIO_IRQ_TxHdlr(int irq, void *dev_id, struct pt_regs *regs);



#endif

