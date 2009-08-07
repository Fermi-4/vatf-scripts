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

/** \file   ST_UART_multiprocess.c
    \brief  DaVinci ARM Linux PSP System multi-process UART Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created - Linux UART multi-process
                
 */

#include <pthread.h>
#include "st_uart.h"


/* Mode defines */
#define UART_WRITEMODE				0
#define UART_READMODE				1
#define UART_WRITEREADMODE			2 
#define UART_DEFAULT_MODE			0

/* Data size defines */
#define UART_WRITEREADDATA			450
#define UART_INCDATA				50

#define UART_DEFAULT_PROCESS_NUM	5				/* Process number */



static Int32 uart_size = UART_WRITEREADDATA;		/* Data size */
		
static Int32 processnum = UART_DEFAULT_PROCESS_NUM;
static Int32 mode = UART_DEFAULT_MODE;


extern int fd_uart;

extern Uint32 st_uart_instance;
	
extern Uint32 st_uart_automation_instance;

extern Uint32 st_uart_driver[PSP_UART_NUM_INSTANCES];

extern Int32 st_uart_driver_timeout;

extern Uint32 st_uart_io_reporting;

extern char io_status_buffer[100];





void test_uart_driver_wr(Uint32 txmlen);
void test_uart_driver_rd(Uint32 rxmlen);
void ST_Uart_Multi_ProcThread_parser(void);
static void writetest(void);
static void readtest(void);
static void writereadtest(void);



void test_uart_driver_wr(Uint32 txmlen)
{
	//char txBuf[1024] = {'a',};
	char *txBuf = NULL;
	Uint32 txLen=1024;
	Int32 actualLen = 0;
	char txarray[1024] = {'a', };
	int i = 0;
	
	txBuf = (Uint8 *)malloc(txLen);
	
	if (NULL != txBuf)
	{

		/* Start the Loop from 1 and NOT 0 */
		for(i=1; i < txLen; i++)
		{
		//	if(0 == i%26)
		//	{
				txarray[i]= 'a' + (i%26);
	//			txBuf = &txarray[i-1];
	//			txBuf = +1;
	//		} else {
	//				txarray[i] = txarray [i-1]+ 1; /* 'a' will result in 'b' */
	//				txBuf = &txarray[i-1];
	//				txBuf = +1;
	//				}
		}
	


	if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
	{
		printTerminalf("test_uart_driver_write_sync: Starting Test\n");
	} 
	else	
	{
		strcpy(io_status_buffer, "test_uart_driver_write_sync: Starting test_uart_driver_write_sync Test");
	}

	//actualLen = write(st_uart_driver[st_uart_instance], txBuf, txLen);
	printf("fd passed to write is: %d\n", st_uart_driver[st_uart_instance]);
	actualLen = write(st_uart_driver[st_uart_instance], txarray, txLen);
	if(actualLen < 0)
	{
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_write_sync: UART (PSP i/f)::Write Failed:%d\n", actualLen);
		} 
		else 
		{
			strcpy(io_status_buffer, "test_uart_driver_write_sync: UART (PSP i/f) Write Failed");
		}
	} 
	else 
	{
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_write_sync: UART (PSP i/f)::Write Success:%d\n", actualLen);
		} 
		else 
		{
			strcpy(io_status_buffer, "test_uart_driver_write_sync: UART (PSP i/f) Write Success");
		}
	}

	}

	else
	{
		printTerminalf("test_uart_driver_write_sync:: Tx Malloc Failed\n");
	}

	return;
}



void test_uart_driver_rd(Uint32 rxm)
{
	char rxBuf[1024] = {0,};
	Uint32 rxLen=rxm;
	Int32 actualLen = 0;

	if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
	{
		printTerminalf("test_uart_driver_read: starting Test\n");
	} 
	else	
	{
		strcpy(io_status_buffer, "test_uart_driver_read: Starting test_uart_driver_read Test");
	}
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, rxLen);

	if(actualLen == rxLen) 
	{
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_read: UART (PSP i/f)::test_uart_driver_read Success:%d\n", actualLen);
		} 
		else 
		{
			strcpy(io_status_buffer, "test_uart_driver_read: UART (PSP i/f) test_uart_driver_read Success");
		}
	}
   	else
   	{
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_read: UART (PSP i/f)::test_uart_driver_read Failed:%d\n", actualLen);
		} 
		else 
		{
			strcpy(io_status_buffer, "test_uart_driver_read: UART Read (PSP i/f) test_uart_driver_read Failed");
		}
	}
	return;
}




void ST_Uart_Multi_ProcThread_parser(void)
{
	printTerminalf("ST_Uart_Multi_ProcThread_parser:: Enter the Write (0), Read (1) or Write and Read (2) mode, Quit (3)\n");
    scanTerminalf("%d", &mode);

	if (3 == mode)
	{
		return;
	}

	/* If pressed enter or space keep mode to write only mode */

	if ('\0' == mode)
	{
		mode = UART_DEFAULT_MODE;
	}	


	printTerminalf("ST_Uart_Multi_ProcThread_parser:: Enter number of bytes to Write / Read/ Write & Read\n");
    scanTerminalf("%d", &uart_size);

	printTerminalf("ST_Uart_Multi_ProcThread_parser:: Enter number of processes to execute\n");
   	scanTerminalf("%d", &processnum);
	
}





/* MultiProcess routine for Write and Read */

void ST_Uart_MultiProcess_parser(void)
{
	Int32 loop = 0, Pid =0;	

	ST_Uart_Multi_ProcThread_parser();
	
	for(loop = 0; loop<processnum; loop++)
	{	
		switch(fork())
		{
			case 0: // Child Process
				{
					switch (mode)	
					{
						case 0:	printTerminalf("\nWrite Test\n");
								writetest();
								printTerminalf("ST_Uart_MultiProcess_parser: Write Process is complete\n");
								exit(0);
								
						case 1: printTerminalf("\nRead Test\n");
								readtest();
								printTerminalf("ST_Uart_MultiProcess_parser: Read Process is complete\n");
								exit(0);
								
						case 2: printTerminalf("\nWrite & Read Test\n");
								writereadtest();
								printTerminalf("ST_Uart_MultiProcess_parser: Write and Read Process is complete\n");
								exit(0);
						default:
								printTerminalf("ST_Uart_MultiProcess_parser: Invalid Selection\n");
								break;
								
					}//End of Inner switch.		
				} //End of Case 0 
			break;
			
			case -1: // Child process creation Failed
					{
						printTerminalf("ST_Uart_MultiProcess_parser: Error creating Process\r\n");
    				}
			break;										/* Break if process fails */	

			default: // Parent process	
					//if( uart_size >= MAX_UART_DATASIZE)
			    	//	uart_size = 1;
			    	//else
			    	//	uart_size += UART_INCDATA;		
			    		
					Pid = wait(NULL);
					printTerminalf("\n\nST_Uart_MultiProcess_parser: Process %d COMPLETED\n\n", Pid);
			break;
		} // end of Switch
	}

	/*Set to default values */
	uart_size = UART_WRITEREADDATA;		
	processnum = UART_DEFAULT_PROCESS_NUM;
	mode = UART_DEFAULT_MODE;
}




/* Multi-Thread routine for Write and Read */

void ST_Uart_MultiThread_parser(void)
{
	Int32 loop = 0;
	pthread_t Thread = 0;

	ST_Uart_Multi_ProcThread_parser();
	
	for(loop = 0; loop<processnum; loop++)
	{	
			
		switch (mode)	
		{
				case 0:	
						printTerminalf("\nWrite Test\n");
						if( 0 < pthread_create(&Thread, NULL, (void *) writetest, NULL))
							printTerminalf("ST_Uart_MultiThread_parser: Creating the writetest Thread failed\n");
						break;

				case 1: 
						printTerminalf("\nRead Test\n");
						if( 0 < pthread_create(&Thread, NULL, (void *) readtest, NULL))
							printTerminalf("ST_Uart_MultiThread_parser: Creating the readtest Thread failed\n");
						break;
			
				case 2: 
						printTerminalf("\nWrite & Read Test\n");
						if( 0 < pthread_create(&Thread, NULL, (void *) writereadtest, NULL))
							printTerminalf("ST_Uart_MultiThread_parser: Creating the writetest Thread failed\n");
						break;

				default:
						printTerminalf("ST_Uart_MultiThread_parser: Invalid Selection\n");
						break;

		}//End of switch.		
		
	
		//if( uart_size >= MAX_UART_DATASIZE)
	    //	uart_size = 1;
	    //else
	    //	uart_size += UART_INCDATA;		
	} // End of For

	pthread_join(Thread, NULL); // Used for Sync - similar to wait() call.
	printTerminalf("ST_Uart_MultiThread_parser:: Completed\n");
	
	/*Set to default values */
	uart_size = UART_WRITEREADDATA;		
	processnum = UART_DEFAULT_PROCESS_NUM;
	mode = UART_DEFAULT_MODE;
	
	return;
}






/* Write Process */
void writetest(void)
{
    	uart_size = uart_size + UART_INCDATA;

	/* Write function to be executed */

	test_uart_driver_wr(uart_size);	/* Call Write function to execute */
}


/* Read Process */

void readtest(void)
{
	uart_size = uart_size + UART_INCDATA;

	/* Read function to be executed */

	test_uart_driver_rd(uart_size);	/* Call Read function to execute */
}



/* Write and Read Process */

void writereadtest(void)
{
	uart_size = uart_size + UART_INCDATA;

/* Write and Read function to be executed with comparison - Modify as per required */

	/* Need to implement */
//	ST_Mcbsp_WriteRead(CHANNELNO, size);	/* Call Write & Read function to execute */
}
