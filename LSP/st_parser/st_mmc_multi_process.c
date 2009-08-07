/*************************************************************************
**+--------------------------------------------------------------------+**
**|                                   ****                             |**
**|                                   ****                             |**
**|                                   ******o***                       |**
**|                             ********_///_****                      |**
**|                             ***** /_//_/ ****                      |**
**|                             ** ** (__/ ****                        |**
**|                             *********                              |**
**|                             ****                                   |**
**|                             ***                                    |**
**|                                                                    |**
**| Copyright (c) 1998-2005 Texas Instruments Incorporated             |**
**| ALL RIGHTS RESERVED                                                |**
**|                                                                    |**
**| Permission is hereby granted to licensees of Texas Instruments     |**
**| Incorporated (TI) products to use this computer program for sole   |**
**| purpose of implementing a licensee product based on TI products.   |**
**| No other rights to reproduce, use, or disseminate this computer    |**
**| program, whether in part or in whole, are granted.                 |**
**|                                                                    |**
**| TI makes no representation or warranties with respect to the       |**
**| performance of this computer program, and specifically disclaims   |**
**| any responsibility for any damages, special or consequential,      |**
**| connected with the use of this program.                            |**
**|                                                                    |**
**+--------------------------------------------------------------------+**
* FILE:   	ST_MMC_Multi_Process.c
*
* Brief:  	MMC MultiTask Operation Support.
*
* Platform: 	Linux 2.6 
*
* Author: 	Anand Patil
*
* History: 	Pulled Code from "Multi_Process.c"
*
*Comments:		Integrity of data is applications responsibility.
*			Modify the printfs, scanfs and function calls as per required
*			Change Process creation call as per OS (made as per LINUX)
*			For viewing this file use tab = 4 (se ts =4)
*
********************************************************************************/

/* Include required header files */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <pthread.h>
#include "st_common.h"
#include "st_fstests.h"
#include "st_linuxfile.h"
/* Mode defines */
#define WRITEMODE				0
#define READMODE				1
#define WRITEREADMODE			2 
#define DEFAULT_MODE			2

/* Data size defines */
#define WRITEREADDATA				450
#define INCDATA					50
#define DEFAULT_PROCESS_NUM			5			/* Process number */
#define CHANNELNO				2
#define DATASIZE_MAX				10240
#define RAND_SLEEPMAX				5
#define ST_scanf scanTerminalf

#define ENABLE_SLEEP
#define MAX_THREAD				30
#define MAX_PROCESS				30
#define MAX_FILE_LENGTH				50

static Uint32 size = WRITEREADDATA;				/* Data size */
static Int32 rand_sleep = 0;
static Uint32 mode,processnum;
static int Thread_usage=0;
static int RetVal=ST_FAIL;

void ST_MMC_MultiThread_parser(void);
void ST_MMC_multiProcess_parser(void);

static void ST_Multi_ProcThread_parser(void);
static void writetest(void);
static void readtest(void);
static void writereadtest(void);
static unsigned int ST_getTask_id(int Thread_usage);



/* Common routine, used both in Process and Thread context. */

static void ST_Multi_ProcThread_parser(void)
{
	printTerminalf("MultiProcess: MMC:: Enter the Write (0), Read (1) or Write and Read (2) mode, Quit (3)\n");
    scanTerminalf("%d", &mode);

	if (3 == mode)
	{
		return;
	}

	printTerminalf("MultiProcess: MMC:: Enter number of bytes to Write / Read/ Write & Read\n");
    	scanTerminalf("%d", &size);

	printTerminalf("MultiProcess: MMC:: Enter number of write processes to execute\n");
   	scanTerminalf("%d", &processnum);
	
}


/* MultiProcess routine for Write and Read */

 void ST_MMC_multiProcess_parser(void)
{

	Uint8 loop = 0;
	pid_t pid[MAX_PROCESS];
	int proc_status;
	int Failiure_Flg=0;
	
		ST_Multi_ProcThread_parser();

		for(loop = 0; loop<processnum; loop++)
		{	
			
/* Create child process for Write */

			switch((pid[loop]=fork()))
			{
				case 0: // Child Process
					{
						switch(mode)
						{
							case 0 :
							{
								writetest();
						   		printTerminalf("\nMMC multiProcess_parser: Write Process %d is spawned\n",getpid());							     
								exit(0);	
								break;
							}	
							case 1 :
							{
								readtest();
								printTerminalf("\nMMC multiProcess_parser: Read Process %d is spawned\n",getpid());
								exit(0);	
								break;
							}
							case 2 :
							{
								writereadtest();
								printTerminalf("\nMMC multiProcess_parser: Read/Write Process %d  is spawned\n",getpid());
								exit(0);
								break;
							}
							
						}
					}					

				case -1: // Child process creation Failed
						{
							printTerminalf("MMC multiProcess_parser: Error creating Process\r\n");
        						//STLog("MMC multiProcess_parser: Error creating Process\r\n");

							break;/* Break if process fails */	
						}
				default: // Parent process
						{
							(size<=DATASIZE_MAX)?(size++):(size=100);
							#ifdef	ENABLE_SLEEP							
							(rand_sleep<=RAND_SLEEPMAX)?(rand_sleep++):(rand_sleep=0);
							#endif
							//wait(0);
							printTerminalf("MMC multiProcess_parser: Parent process Executed\r\n");
							//exit(0);
						}
			}//End of Switch Fork
			
		}//End of For loop
	
	//This snippet is for waiting for all the Spawned Processes 
	
	for(loop = 0; loop<processnum; loop++)	
	{	
		printTerminalf("I am in Parent Process Waiting for Process ID=%d\n",pid[loop]);		
		if((waitpid(pid[loop],&proc_status,0))<0)
		{	
			printTerminalf("waitpid Failed \n");			
		}
		else
		{
			printTerminalf("Process ID=%d ,returned=%d\n",pid[loop],WEXITSTATUS(proc_status));
			if ((WEXITSTATUS(proc_status))==ST_FAIL)
			{
				Failiure_Flg=1;
				printTerminalf("Process ID=%d Failed\n",pid[loop]);
			}
			}
		}
	

	if(Failiure_Flg)
		printTerminalf("ST_MMC_multiProcess_parser:Completed with Failiure\n");
	else
		printTerminalf("ST_MMC_multiProcess_parser:Completed Successfully\n");		


}


 void ST_MMC_MultiThread_parser(void)
{
	Int32 loop = 0;
	pthread_t Thread[MAX_THREAD]={0,};
	//int Thread_return=ST_FAIL;
	int *Thrd_retPtr;
	int Failiure_Flg=0;

	//Thrd_retPtr=&Thread_return;

	ST_Multi_ProcThread_parser();
	
Thread_usage=1;
	for(loop = 0; loop<processnum; loop++)
	{	
			
		switch (mode)	{
				case 0:	printTerminalf("\nWrite Test\n");
						if( 0 < pthread_create(&Thread[loop], NULL, (void *) writetest, NULL))
							printTerminalf("Creating the writetest Thread failed\n");
						break;

				case 1: printTerminalf("\nRead Test\n");
						if( 0 < pthread_create(&Thread[loop], NULL, (void *) readtest, NULL))
							printTerminalf("Creating the readtest Thread failed\n");
						break;
			
				case 2: printTerminalf("\nWrite & Read Test\n");
						if( 0 < pthread_create(&Thread[loop], NULL, (void *) writereadtest, NULL))
							printTerminalf("Creating the writetest Thread failed\n");
						break;

		}//End of switch.		
		
	//	(size<=DATASIZE_MAX)?(size++):(size=100);	
	} // End of For



//This snippet is for waiting for all the Spawned Threads 
	
	for(loop = 0; loop<processnum; loop++)	
	{	
		printTerminalf("I am in Parent Thread Waiting for Thread ID=%d\n",Thread[loop]);		
		if(pthread_join(Thread[loop], (void**)&Thrd_retPtr))
		{	
			printTerminalf("Pthread_join Failed \n");			
		}
		else
		{
			printTerminalf("Thread ID=%d ,returned=%d\n",Thread[loop],*(Thrd_retPtr));
			if ((*(Thrd_retPtr))==ST_FAIL)
			{
				Failiure_Flg=1;
				printTerminalf("Thread ID=%d Failed\n",Thread[loop]);
			}
		}
	}

	// Reset the Thread Usage Flag
	Thread_usage=0;
	if(Failiure_Flg)
		printTerminalf("ST_MMC_MultiThread_parser:Completed with Failiure\n");
	else
		printTerminalf("ST_MMC_MultiThread_parser:Completed Successfully\n");		
}
		
static unsigned int ST_getTask_id(int Thread_usage)
{
	return((Thread_usage==1)?pthread_self():getpid());
}

/* Write Process */
static void writetest(void)
{
    	//size = size + INCDATA;
	static 	Uint8* SrcBufata=NULL;
	FILE * fptr=NULL;
	char SrcName[50]="/mmc/test1";
						
	 RetVal=ST_FAIL;	// INitialize the Returning Value to Failiure 


			printTerminalf("I am in thread %d\n",pthread_self());
			SrcBufata=(Uint8*)malloc(size);
			if(SrcBufata==NULL)
			{	
				printTerminalf("Malloc Failed in Task %d\n",ST_getTask_id(Thread_usage));
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);				
				
			}
	

			itoa(ST_getTask_id(Thread_usage),&SrcName[8]);
			if(ST_PASS==ST_FileOpen(SrcName,"w+",(Ptr *)&fptr))
			{	
				if(ST_PASS==ST_FileWrite(fptr, size, 1, SrcBufata))
				{
					ST_FileClose((Ptr *)&fptr);
					printTerminalf("writetest Task: %d Write complete\n",ST_getTask_id(Thread_usage));
					RetVal=ST_PASS;
					//pthread_exit((int *)&RetVal);
					(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);
					
				}
				else
				{
					ST_FileClose((Ptr *)&fptr);
					(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);
				}
					
			}
			else
			(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);


}


/* Read Process */

static void readtest(void)
{
	//size = size + INCDATA;
	static 	Uint8* SrcBufata=NULL;
	static 	Uint8* DesBufata=NULL;
	FILE * fptr=NULL;
	char SrcName[MAX_FILE_LENGTH]="/mmc/test1";
	Uint32 i;
	int Failiure_flag=0;
	
	 RetVal=ST_FAIL;	// INitialize the Returning Value to Failiure 	
			
			SrcBufata=(Uint8*)malloc(size);
			if(SrcBufata==NULL)
			{	
				printTerminalf("Malloc Failed in Task %d\n",ST_getTask_id(Thread_usage));
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);				
				
			}
				

			DesBufata=(Uint8*)malloc(size);
			if(DesBufata==NULL)
			{	
				printTerminalf("Malloc Failed in Task %d\n",ST_getTask_id(Thread_usage));
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);				
				
			}
				

			
			itoa(ST_getTask_id(Thread_usage),&SrcName[8]); //Create Files with Task ID as FileName Suffixes
			
			if(ST_PASS==ST_FileOpen(SrcName,"w+",(Ptr *)&fptr))
			{	
				if(ST_PASS==ST_FileWrite(fptr, size, 1, SrcBufata))
				{
					ST_FileClose((Ptr *)&fptr);
				}
				else
				{
					ST_FileClose((Ptr *)&fptr);
					(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);					
				}
					
					
			
				if(ST_PASS==ST_FileOpen(SrcName,"r",(Ptr *)&fptr))
				{	
					if(ST_PASS==ST_FileRead(fptr,size,1,DesBufata))
					{
						for(i=0;i<size;i++)
						{
							if(SrcBufata[i]!=DesBufata[i])
							{
							printTerminalf("Data Mismatch at %d in Task %d\n",i,ST_getTask_id(Thread_usage));
							Failiure_flag=1;
							break;
							}
						}
						
						if(!Failiure_flag)
						{
							ST_FileClose((Ptr *)&fptr);
							RetVal=ST_PASS;
							(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);						
						}
						else
						{
							ST_FileClose((Ptr *)&fptr);
							(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);
						}
										
					}
					else
					{
						ST_FileClose((Ptr *)&fptr);
						(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);											
					}
				}
				else
				{
					ST_FileClose((Ptr *)&fptr);
					(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);					
				}
			}
			else
			{
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);				
			}

		

}



/* Write and Read Process */

static void writereadtest(void)
{
	

/* Write and Read function to be executed with comparison - Modify as per required */


	static 	Uint8* SrcBufata=NULL;
	static 	Uint8* DesBufata=NULL;
	FILE * fptr=NULL;
	char SrcName[20]="/mmc/test1";
	int Failiure_flag=0;
	Uint32 i;

	 RetVal=ST_FAIL;	// INitialize the Returning Value to Failiure 		
			
	 
			SrcBufata=(Uint8*)malloc(size);
			if(SrcBufata==NULL)
			{	
				printTerminalf("Malloc Failed in Task %d\n",ST_getTask_id(Thread_usage));
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);				
				
			}
				

			DesBufata=(Uint8*)malloc(size);
			if(DesBufata==NULL)
			{	
				printTerminalf("Malloc Failed in Task %d\n",ST_getTask_id(Thread_usage));
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);				
				
			}
				

			

			if(ST_PASS==ST_FileOpen(SrcName,"w+",(Ptr *)&fptr))
			{	
				if(ST_PASS==ST_FileWrite(fptr, size, 1, SrcBufata))
				{
					ST_FileClose((Ptr *)&fptr);
				}
				else
				{
					ST_FileClose((Ptr *)&fptr);
					(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);					
				}
					
					
			
				if(ST_PASS==ST_FileOpen(SrcName,"r",(Ptr *)&fptr))
				{	
					if(ST_PASS==ST_FileRead(fptr,size,1,DesBufata))
					{
						for(i=0;i<size;i++)
						{
							if(SrcBufata[i]!=DesBufata[i])
							{
							printTerminalf("Data Mismatch at %d in Task %d\n",i,ST_getTask_id(Thread_usage));
							Failiure_flag=1;
							break;
							}
						}
						
						if(!Failiure_flag)
						{
							ST_FileClose((Ptr *)&fptr);
							RetVal=ST_PASS;
							(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);						
						}
						else
						{
							ST_FileClose((Ptr *)&fptr);
							(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);
						}
										
					}
					else
					{
						ST_FileClose((Ptr *)&fptr);
						(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);											
					}
				}
				else
				{
					ST_FileClose((Ptr *)&fptr);
					(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);					
				}
			}
			else
			{
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);				
			}


}


