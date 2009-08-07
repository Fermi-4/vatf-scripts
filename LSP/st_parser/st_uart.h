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

/** \file   ST_UART.h
    \brief  DaVinci ARM Linux PSP System Testing UART Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created -  Linux UART Test Code Integration
					- Incorporated the review comments - 20/09/2005
                
 */
#ifndef __ST_UART__H
#define __ST_UART__H

#include "st_common.h"
#include "st_automation_io.h"
#include <sys/ioctl.h>
#include <termios.h>
#include <fcntl.h>
#include <unistd.h>

#define CONSOLE_UART_IS_SYNC True
#define CONSOLE_UART_IS_ASYNC False


#define PSP_UART_NUM_INSTANCES 	3			/* Number of UART instances */

#define INSTANCE0	"/dev/ttyS0"
#define INSTANCE1	"/dev/ttyS1"
#define INSTANCE2	"/dev/ttyS2"
#define UARTMODE	O_RDWR | O_NOCTTY | O_NDELAY
#define UARTRDWR	O_RDWR							/* Read and Write */
#define UARTNOTTY	O_NOCTTY						/* No Controlling Terminal */
#define UARTNODCD	O_NDELAY						/* Don't care DCD signal */

#define MIN_RD_CHAR		1

#define UART_SUCCESS 	0
#define UART_FAILURE 	-1

#define UART_NULL 		0


#define UART_TX			0
#define UART_RX			1
#define UART_TX_RX		2


#define DEFAULT_BAUD	B115200



#define UART_CACHE_LINE_SIZE_IN_BYTES    32 /* cache line size in bytes */



void uart_parser(void);
void uart_io_parser(void);
void uart_ioctl_parser(void);

void test_uart_driver_update(void);
void test_uart_update_driver_instance(void);
void test_uart_update_io_reporting(void);
void test_uart_update_automation_instance(void);
void test_uart_update_driver_timeout(void);
void test_uart_driver_io_status(void);

void test_uart_driver_open(void);
void test_uart_driver_close(void);
void test_uart_driver_general_open(void);

void test_uart_driver_set_baud(void);
void test_uart_driver_set_stopbit(void);
void test_uart_driver_set_parity(void);
void test_uart_driver_set_data(void);
void test_uart_driver_set_flowCtrl(void);
void test_uart_driver_get_config(void);


void test_uart_driver_read(void);
void test_uart_driver_write_sync(void);
void test_uart_driver_write_async(void);
void test_uart_driver_read_sync_and_write_sync(void);
void test_uart_driver_read_async_and_write_async(void);

void test_uart_driver_sync_stress(void);
void test_uart_driver_len_in_stress(void);
void test_uart_driver_stability(void);
void test_uart_driver_sync_variable_write(void);
void test_uart_driver_sync_performance(void);
void test_uart_driver_sync_performance_9600(void);
void test_uart_driver_sync_performance_115200(void);
void test_uart_driver_sync_performance_read_115200(void);




void test_uart_driver_NULL_Instance(void);
extern void ST_Uart_MultiProcess_parser(void);
extern void ST_Uart_MultiThread_parser(void);


/* Internal functions */

Int32 test_uart_driver_tx_rx_int(Uint32 baud, Uint8 datalen, Uint8 stopbit, Uint8 parity, Uint8 flowctl, Uint32 size, Uint8 tx_rx);

#endif  
