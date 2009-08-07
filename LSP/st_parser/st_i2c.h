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

/** \file   ST_I2C.h
    \brief  System Test Common Defines for I2C

    This file contains the common defines used by system test

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Shivanand Pujar
    @version    0.1 	09-Aug-2005	- Created
    		0.2	14-Sep-2005 - Added prototypes for Update functions.
		0.3	17-Oct-2005 - Added prototypes for MSP Slave device details.                
**/


#ifndef _ST_I2C_H
#define _ST_I2C_H

#include "st_types.h"
#define MAX_I2C_DATASIZE	64	//64
#define I2C_DEV			"/dev/i2c/0"
//#define I2C_DEV			"/dev/i2c-1"

#ifndef INCDATA
	#define INCDATA	8
#endif

#define I2C_SLAVE	0x0706
#define	I2C_TENBIT	0x0704

/* this is used by the I2C_RDWR IOCTL command. */
#ifndef I2C_M_RD
	#define I2C_M_RD	0x01
#endif	

#define	I2C_ACK_TEST	0x0710

#define I2C_RETRIES     0x0701  /* number times a device address should */
                                /* be polled when not acknowledging     */
#define I2C_TIMEOUT     0x0702  /* set timeout - call with int          */

#define I2C_FUNCS       0x0705  /* Get the adapter functionality */
#define I2C_RDWR        0x0707  /* Combined R/W transfer (one stop only)*/

/* ... algo-bit.c recognizes */
#define I2C_UDELAY      0x0705  /* set delay in microsecs between each  */
                                /* written byte (except address)        */
#define I2C_MDELAY      0x0706  /* millisec delay between written bytes */

#define I2C_SMBUS       0x0720  /* SMBus-level access */

// Slave devices

#if defined(DM355)
//General Call
#define I2C_GC			0x00
//LED
#define I2C_LED			0x25
//#define I2C_LED			0x38
//EEPROM
#define I2C_EEPROM		0x50
//AIC33
#define	I2C_CODEC		0x1B
//Own Address
#define	I2C_OWN_ADDRESS		0x1
//MSP - RTC, IR, LED
#define I2C_MSP_ADDR		0x25	

#elif defined(DM644X)
//General Call
#define I2C_GC          0x00
//LED
#define I2C_LED         0x38
//EEPROM
#define I2C_EEPROM      0x50
//AIC33
#define I2C_CODEC       0x1A
//Own Address
#define I2C_OWN_ADDRESS     0x21
//MSP - RTC, IR
#define I2C_MSP_ADDR        0x23

#elif defined(DM365)
//General Call
#define I2C_GC          0x00
//EEPROM
#define I2C_EEPROM      0x50
//AIC33
#define I2C_CODEC       0x18
//Own Address
#define I2C_OWN_ADDRESS     0x21
//MSP - RTC, IR
#define I2C_MSP_ADDR        0x25

#define I2C_TVP5146_ADDR	0x5D

#else
//General Call
#define I2C_GC          0x00
//EEPROM
#define I2C_EEPROM      0x50
//AIC33
#define I2C_CODEC       0x18
//Own Address
#define I2C_OWN_ADDRESS     0x21
//MSP - RTC, IR
#define I2C_MSP_ADDR        0x25

#define I2C_TVP5146_ADDR	0x5D

#endif

/* One-Stop Write/read Operations */

typedef struct i2c_msg {
	Uint16 addr;	// slave address
 	Uint16 flags;		
 	Uint16 len;	// msg length
 	Uint8 *buf;	// pointer to msg data
}MSG;

/* This is extracted from i2c-dev.c file.
 * This is the structure as used in the I2C_RDWR ioctl call
 */
typedef struct i2c_rdwr_ioctl_data {
	MSG *msgs;	// pointers to i2c_msgs
	Uint32 nmsgs;			// number of i2c_msgs
}MSG_SET;



void test_i2c_driver_update(void);
void test_i2c_update_Init_Opmode(void);
void test_i2c_update_Channel_Config(void);
void test_i2c_update_ReadWrite_DataSize(void);
void test_i2c_update_Stability(void);
void test_i2c_update_AddressFormat(void);
void test_i2c_update_Timeout(void);
void test_i2c_update_Retry(void);


void ST_I2C_Init(void);
void ST_I2C_Terminate(void);
void ST_I2C_Open(void);
void ST_I2C_Close(void);
void ST_I2C_EEPROM_Read(void);
void ST_I2C_EEPROM_Write(void);
void ST_I2C_Ioctl(void);
void ST_I2C_LoopBack(void);
void ST_I2C_EEPROM_WriteRead(void);
void ST_I2C_Stability(void);
void ST_I2C_Stress(void);
void ST_I2C_MultipleSlave_Test(void);
void ST_I2C_Max_Fd(void);
void ST_I2C_OneStop_Test(void);
void ST_I2C_Scan_Test(void);
void ST_I2C_Ack_Test(void);

void ST_I2C_MultiProcess_parser(void);
void ST_I2C_MultiThread_parser(void);

void ST_I2C_LED_WriteRead(void);

void ST_I2C_MSP_RTC_Write(void);
void ST_I2C_MSP_RTC_Read(void);

void ST_I2C_MSP_IR_ReadRecent(void);
void ST_I2C_MSP_IR_ReadAll(void);
//void ST_I2C_MSP_IR_ReadAll2(void);

void ST_I2C_MSP_IR_GetInputStatus(void);
void ST_I2C_MSP_IR_SetOutputStatus(void);

void ST_I2C_MSP_IR_GetEventStatus(void);

void ST_I2C_Performance(void);
void ST_I2C_Codec_WriteRead(void);
void ST_I2C_Codec_Read(void);
void ST_I2C_Codec_One_Shot(void);
void ST_Test_MXP430(void);

#endif
