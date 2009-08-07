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

/** \file   ST_AUDIO_multiprocess.c
    \brief  DaVinci ARM Linux PSP System multi-process AUDIO Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created - Linux AUDIO multi-process
                
 */

#include <pthread.h>
#include "st_audio.h"


/* Mode defines */
#define AUDIO_WRITEMODE				0
#define AUDIO_READMODE				1
#define AUDIO_WRITEREADMODE			2 
#define AUDIO_DEFAULT_MODE			0

/* Data size defines */
#define AUDIO_WRITEREADDATA			450
#define AUDIO_INCDATA				50

#define AUDIO_DEFAULT_PROCESS_NUM	5				/* Process number */



static Int32 audio_size = AUDIO_WRITEREADDATA;		/* Data size */
		
static Int32 processnum = AUDIO_DEFAULT_PROCESS_NUM;
static Int32 mode = AUDIO_DEFAULT_MODE;


extern int fd_audio;

extern Uint32 st_audio_instance;
	
extern Uint32 st_audio_automation_instance;

extern Uint32 st_audio_driver[PSP_AUDIO_NUM_INSTANCES];

extern Int32 st_audio_driver_timeout;

extern Uint32 st_audio_io_reporting;

extern char io_status_buffer[100];





void test_audio_driver_wr(Uint32 txmlen);
void test_audio_driver_rd(Uint32 rxmlen);
void ST_Audio_Multi_ProcThread_parser(void);
static void writetest(void);
static void readtest(void);
static void writereadtest(void);



void test_audio_driver_wr(Uint32 txmlen)
{
	Uint32 txLen = 1024*8;
	Uint32 txBuf[1024*8] = {'a', };
	Int8 status = AUDIO_FAILURE;

	printTerminalf("test_audio_driver_wr: Starting Test\n");
	
	status = ST_Write(st_audio_driver[st_audio_instance], txBuf, txLen);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_wr: Failed:: Status = %d\n", status);
	} 
	else 
	{
		printTerminalf("test_audio_driver_wr: Success:: Status = %d\n", status);	
	}
	
	
	return;
}



void test_audio_driver_rd(Uint32 rxm)
{
	Uint32 rxLen = 1024*8;
	Uint32 rxBuf[1024*8] = {'a', };
	Int8 status = AUDIO_FAILURE;

	
#ifdef Cache_enable
	Uint8* srcArray= 0;
#endif

	printTerminalf("test_audio_driver_rd: Starting Test");
	
	status = ST_Read(st_audio_driver[st_audio_instance], rxBuf, rxLen);
	
	if (status != AUDIO_SUCCESS) 
	{
		printTerminalf("test_audio_driver_rd: Failed:: Status = %d\n", status);
	}
   	else
   	{
		printTerminalf("test_audio_driver_rd: Success:: Status = %d\n", status);
	}
}




void ST_Audio_Multi_ProcThread_parser(void)
{
	printTerminalf("ST_Audio_Multi_ProcThread_parser:: Enter the Write (0), Read (1) or Write and Read (2) mode, Quit (3)\n");
    scanTerminalf("%d", &mode);

	if (3 == mode)
	{
		return;
	}

	/* If pressed enter or space keep mode to write only mode */

	if ('\0' == mode)
	{
		mode = AUDIO_DEFAULT_MODE;
	}	


	printTerminalf("ST_Audio_Multi_ProcThread_parser:: Enter number of bytes to Write / Read/ Write & Read\n");
    scanTerminalf("%d", &audio_size);

	printTerminalf("ST_Audio_Multi_ProcThread_parser:: Enter number of processes to execute\n");
   	scanTerminalf("%d", &processnum);
	
}





/* MultiProcess routine for Write and Read */

void ST_Audio_MultiProcess_parser(void)
{
	Int32 loop = 0, Pid =0;	

	ST_Audio_Multi_ProcThread_parser();
	
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
								printTerminalf("ST_Audio_MultiProcess_parser: Write Process is complete\n");
								exit(0);
								
						case 1: printTerminalf("\nRead Test\n");
								readtest();
								printTerminalf("ST_Audio_MultiProcess_parser: Read Process is complete\n");
								exit(0);
								
						case 2: printTerminalf("\nWrite & Read Test\n");
								writereadtest();
								printTerminalf("ST_Audio_MultiProcess_parser: Write and Read Process is complete\n");
								exit(0);
						default:
								printTerminalf("ST_Audio_MultiProcess_parser: Invalid Selection\n");
								break;
								
					}//End of Inner switch.		
				} //End of Case 0 
			break;
			
			case -1: // Child process creation Failed
					{
						printTerminalf("ST_Audio_MultiProcess_parser: Error creating Process\r\n");
    				}
			break;										/* Break if process fails */	

			default: // Parent process	
					//if( audio_size >= MAX_AUDIO_DATASIZE)
			    	//	audio_size = 1;
			    	//else
			    	//	audio_size += AUDIO_INCDATA;		
			    		
					//Pid = wait(NULL);
					printTerminalf("\n\nST_Audio_MultiProcess_parser: Process %d COMPLETED\n\n", Pid);
			break;
		} // end of Switch
	}

	/*Set to default values */
	audio_size = AUDIO_WRITEREADDATA;		
	processnum = AUDIO_DEFAULT_PROCESS_NUM;
	mode = AUDIO_DEFAULT_MODE;
}




/* Multi-Thread routine for Write and Read */

void ST_Audio_MultiThread_parser(void)
{
	Int32 loop = 0;
	pthread_t Thread = 0;

	ST_Audio_Multi_ProcThread_parser();
	
	for(loop = 0; loop<processnum; loop++)
	{	
			
		switch (mode)	
		{
				case 0:	
						printTerminalf("\nWrite Test\n");
						if( 0 < pthread_create(&Thread, NULL, (void *) writetest, NULL))
							printTerminalf("ST_Audio_MultiThread_parser: Creating the writetest Thread failed\n");
						break;

				case 1: 
						printTerminalf("\nRead Test\n");
						if( 0 < pthread_create(&Thread, NULL, (void *) readtest, NULL))
							printTerminalf("ST_Audio_MultiThread_parser: Creating the readtest Thread failed\n");
						break;
			
				case 2: 
						printTerminalf("\nWrite & Read Test\n");
						if( 0 < pthread_create(&Thread, NULL, (void *) writereadtest, NULL))
							printTerminalf("ST_Audio_MultiThread_parser: Creating the writetest Thread failed\n");
						break;

				default:
						printTerminalf("ST_Audio_MultiThread_parser: Invalid Selection\n");
						break;

		}//End of switch.		
		
	
		//if( audio_size >= MAX_AUDIO_DATASIZE)
	    //	audio_size = 1;
	    //else
	    //	audio_size += AUDIO_INCDATA;		
	} // End of For

	pthread_join(Thread, NULL); // Used for Sync - similar to wait() call.
	printTerminalf("ST_Audio_MultiThread_parser:: Completed\n");
	
	/*Set to default values */
	audio_size = AUDIO_WRITEREADDATA;		
	processnum = AUDIO_DEFAULT_PROCESS_NUM;
	mode = AUDIO_DEFAULT_MODE;
	
	return;
}






/* Write Process */
void writetest(void)
{
    printTerminalf("\n\nwritetest: Write Process %d Start\n\n", getpid());
	
	audio_size = audio_size + AUDIO_INCDATA;

	/* Write function to be executed */

	test_audio_driver_wr(audio_size);	/* Call Write function to execute */

	printTerminalf("\n\nwritetest: Write Process %d COMPLETED\n\n", getpid());
}


/* Read Process */

void readtest(void)
{
	printTerminalf("\n\nreadtest: Read Process %d Start\n\n", getpid());
		
	audio_size = audio_size + AUDIO_INCDATA;

	/* Read function to be executed */

	test_audio_driver_rd(audio_size);	/* Call Read function to execute */

	printTerminalf("\n\nreadtest: Read Process %d COMPLETED\n\n", getpid());
}



/* Write and Read Process */

void writereadtest(void)
{
	printTerminalf("\n\nwritereadtest: Process %d Start\n\n", getpid());
	
	audio_size = audio_size + AUDIO_INCDATA;

/* Write and Read function to be executed with comparison - Modify as per required */

	switch (fork())	
	{
		case 0:				
			{
				test_audio_driver_wr(audio_size);	/* Call Write function to execute */
			}

		default: // Parent process	
			//Pid = wait(NULL);
			printTerminalf("\n\nwritereadtest: Write Process %d COMPLETED\n\n", getpid());
	}


	switch (fork())	
	{
		case 0:				
			{
				test_audio_driver_rd(audio_size);	/* Call Read function to execute */
			}

		default: // Parent process	
			//Pid = wait(NULL);
			printTerminalf("\n\nwritereadtest: Read Process %d COMPLETED\n\n", getpid());
	}
			
	printTerminalf("\n\nwritereadtest: Process %d Completed\n\n", getpid());
}
