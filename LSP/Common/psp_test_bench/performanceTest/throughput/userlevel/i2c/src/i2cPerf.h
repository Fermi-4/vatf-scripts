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

/** \file   i2cPerf.h

  This file implements the i2c Write Throughput test case

  (C) Copyright 2006, Texas Instruments, Inc

  \author     Somasekar.M
  \version    1.0
 */
/*******************************************************************************/

#define I2C_TIMEOUT     	0x0702
#define I2C_SLAVE 		0x0706
#define I2C_TENBIT 		0x0704 
#define ST_PASS 		0
#define ST_FAIL 		-1
#define I2C_ACK_TEST    	0x0710
#define PAGE_SIZE 		64
#define DEFAULT_PAGE_NUMBER 	0x7D0
#define DEFAULT_BYTE_NUMBER 	0x00
#define SLAVE_ADDR 		0x50
#define SLAVE_ADDR_VIDEOCODEC   0x5D
#define DEFAULT_BUFFER_SIZE 	64
#define DEFAULT_TOTAL_SIZE 	1024
#define PAGE_MASK_MSB 		0xFC
#define PAGE_MASK_LSB 		0x03
#define PAGE_MSB_SHIFT          2
#define PAGE_LSB_SHIFT          6
#define BYTE_MASK 		0x3F
#define DELAY_MICROSECS         3500
#define BYTE_TO_BIT_CONV        8
#define BIT_TO_KBIT_CONV        1024                                   
