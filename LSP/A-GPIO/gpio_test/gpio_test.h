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

/** \file   gpio_test.h
    \brief  header file for gpio test

    (C) Copyright 2007, Texas Instruments, Inc

    @author     Yan Liu
    @version    0.1 
    @date 	12/03/2007
                                
 */

#ifndef _ST_GPIO_Test_
#define _ST_GPIO_Test_


#include <linux/module.h>
#include <linux/init.h>
#include <linux/errno.h>
#include <linux/interrupt.h>
#include <linux/irq.h>
#include <asm/io.h>
#include <asm/irq.h>
#include <asm/arch/cpu.h>
#include <asm/arch/io.h>
#include <asm/arch/gpio.h>
#include <asm/arch/hardware.h>
//#include <asm/mach-types.h>
//#include <asm/mach/arch.h>
//#include <asm/mach/map.h>

// copy from asm-arm/irq.h
#if 0
#define __IRQT_FALEDGE  (1 << 0)
#define __IRQT_RISEDGE  (1 << 1)
#define __IRQT_LOWLVL   (1 << 2)
#define __IRQT_HIGHLVL  (1 << 3)

#define IRQT_NOEDGE     (0)
#define IRQT_RISING     (__IRQT_RISEDGE)
#define IRQT_FALLING    (__IRQT_FALEDGE)
#define IRQT_BOTHEDGE   (__IRQT_RISEDGE|__IRQT_FALEDGE)
#endif

//user inputs
#define IRQ_RISING_EDGE 0
#define IRQ_FALLING_EDGE 1
#define IRQ_BOTH_EDGE 2

#define GPIO_DIR_OUT 0
#define GPIO_DIR_IN 1

#define REG_PINMUX0     __REG(PINMUX0)
#define REG_PINMUX1     __REG(PINMUX1)
#define REG_PINMUX2     __REG(PINMUX2)
#define REG_PINMUX3     __REG(PINMUX3)
#define REG_PINMUX4     __REG(PINMUX4)
//#define PINMUX0     __REG(0x01c40000)
//#define PINMUX1     __REG(0x01c40004)
//#define PINMUX2     __REG(0x01c40008)
//#define PINMUX3     __REG(0x01c4000c)
//#define PINMUX4     __REG(0x01c40010)

struct gpio_attrs
{
	int gpio_num;
	int direction;
	int irq_trig_edge;	
	//int irq_num; I don't need this since gpio_to_irq().
};

void gpio_get_intstat_reg_info(int gio);
void gpio_get_set_ris_reg_info(int gio);
void gpio_get_set_fal_reg_info(int gio);
void gpio_get_in_data_reg_info(int gio);
void gpio_get_out_data_reg_info(int gio);
void gpio_get_dir_reg_info(int gio);
void gpio_write(void);
void gpio_unregister_irq(int irq_num);
void gpio_request_irq(int irq_num);
static irqreturn_t gpio_irq_handler(int irq, void *dev_id, struct pt_regs *regs);
void gpio_get_binten_reg_info(void);
void gpio_demux_pins(void);

#endif
