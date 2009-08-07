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
**| Copyright (c) 1998-2006 Texas Instruments Incorporated             |**
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
* FILE:   		ST_BLK_MultiTask.c
*
* Brief:  		MultiProcess and MultiThreading Test Definitions for Block Devices
*
* Platform: 	Linux 2.6
*
* Author: 	Anand Patil
*
* History: 	Pulled Code from "Multiprocess.c"
*
*Comments:	Integrity of data is applications responsibility.
*			Modify the printfs, scanfs and function calls as per required
*			Change Process creation call as per OS (made as per LINUX)
*			For viewing this file use tab = 4 (se ts =4)
*
********************************************************************************/

/* Include required header files */
#include "st_blk_multitask.h"

// Gloabal  variables

static Uint32 size = WRITEREADDATA;				/* Data size */
static Uint32 mode,processnum;
static int Thread_usage=0;
char gST_Mount_Pt[50]="";

//Extern variables

extern int ST_LogFlag;


/***************************************************************************
 * Function		- ST_Multi_ProcThread_parser
 * Functionality	- Test user Interface funcitonality for mulitasking on block devices  
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
static void ST_Multi_ProcThread_parser(void)
{
	printTerminalf("MultiTask:: Enter the Write (0), Read (1) or Write and Read (2) mode, Quit (3)\n");
       scanTerminalf("%d", &mode);

	if (3 == mode)
	{
		return;
	}

	printTerminalf("MultiTask:: Enter number of bytes to Write / Read/ Write & Read\n");
    	scanTerminalf("%d", &size);

	printTerminalf("MultiTask:: Enter number of  Processes/Threads to Spawn\n");
   	scanTerminalf("%d", &processnum);

	printTerminalf("MultiTask:: Enter Device Mount Point (Absolute Path)\n");
   	scanTerminalf("%s", gST_Mount_Pt);

	ST_LogFlag=1; //Set the flag to disable the logging on to the terminal	

	
}


/***************************************************************************
 * Function		- ST_BLK_MultiProcess_parser
 * Functionality	- Spawns processes by forking with the intended function I/O for the process
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_BLK_MultiProcess_parser(void)
{

	Uint8 loop = 0;
	pid_t pid[MAX_PROCESS];
	int proc_status;
	int Failiure_Flg=0;
	char rm_string[20]="rm  ";
	char temp[20];

		
		
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
						   		printTerminalf("\nST_BLK_MultiProcess_parser: Write Process %d is spawned\n",getpid());							     
								exit(0);
								break;
							}	
							case 1 :
							{
								readtest();
								printTerminalf("\nST_BLK_MultiProcess_parser: Read Process %d is spawned\n",getpid());
								exit(0);
								break;
							}
							case 2 :
							{
								writereadtest();
								printTerminalf("\nST_BLK_MultiProcess_parser: Read/Write Process %d  is spawned\n",getpid());						     
								exit(0);								
								break;
							}
							
						}
					}					

				case -1: // Child process creation Failed
						{
							printTerminalf("ST_BLK_MultiProcess_parser: Error creating Process\r\n");
        						//STLog("ATA multiProcess_parser: Error creating Process\r\n");

							break;/* Break if process fails */	
						}
				default: // Parent process
						{
							//(size<=DATASIZE_MAX)?(size++):(size=100);
							//wait(0);
							printTerminalf("ST_BLK_MultiProcess_parser: Parent process Executed\r\n");

							
							//exit(0);
						}
			}//End of Switch Fork
			
		}//End of For loop
	
	/* Waiting for all the Spawned Processes to complete */
	
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
		printTerminalf("ST_BLK_MultiProcess_parser:Completed with Failiure\n");
	else
		printTerminalf("ST_BLK_MultiProcess_parser:Completed Successfully\n");		


		/* Concatentaing for getting th proper mount point to perfrom the clean up activity after a Muliple task I/O operation
	    to render space for the subsequent test to on go */

		strcpy(temp, gST_Mount_Pt);
		strcat(temp,"*");
		strcat(rm_string,temp);

		printTerminalf("\nRemoving files  from %s\n",rm_string);
		ST_System(rm_string);


				
}

/***************************************************************************
 * Function		- ST_BLK_MultiThread_parser
 * Functionality	- Spawns Thread by POSIX thread lib calls  with the intended function I/O for the thread
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_BLK_MultiThread_parser(void)
{
	Int32 loop = 0;
	pthread_t Thread[MAX_THREAD]={0,};
	//int Thread_return=ST_FAIL;
	int *Thrd_retPtr;
	int Failiure_Flg=0;
	char rm_string[20]="rm  ";
	char temp[20];

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
		
	} // End of For

/* Waiting for all the Spawned Threads to complete */
	
	for(loop = 0; loop<processnum; loop++)	
	{	
		printTerminalf("I am in Parent Thread Waiting for Thread ID=%d\n",Thread[loop]);		
		if(pthread_join(Thread[loop], (void **)&Thrd_retPtr))
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
		printTerminalf("ST_BLK_MultiThread_parser:Completed with Failiure\n");
	else
		printTerminalf("ST_BLK_MultiThread_parser:Completed Successfully\n");		


		/* Concatentaing for getting th proper mount point to perfrom the clean up activity after a Muliple task I/O operation
		    to render space for the subsequent test to on go */

		strcpy(temp, gST_Mount_Pt);
		strcat(temp,"*");
		strcat(rm_string,temp);

		printTerminalf("\nRemoving files  from %s\n",rm_string);
		ST_System(rm_string);


	
		
}

/***************************************************************************
 * Function		- ST_getTask_id
 * Functionality	- Gets the task ID dependingon whether a thread or a Prcess respectively 
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
static unsigned int ST_getTask_id(int Thread_usage)
{
	return((Thread_usage==1)?pthread_self():getpid());
}


/***************************************************************************
 * Function		- writetest
 * Functionality	- Performs file Write operation for the requested size 
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
static void  writetest(void)
{
	char SrcName[50]="/hd/test1";
	int RetVal=ST_FAIL;	// INitialize the Returning Value to Failiure 
	
	//		printTerminalf("\n-----------------------WRITETEST : Task %d LOGS FOLLOW---------------------- \n",ST_getTask_id(Thread_usage));

			/*Modify the filenme creation in accrodance to the mount point */
			strcpy(SrcName,gST_Mount_Pt);
			strcat(SrcName,"test1");
	 		
			printTerminalf("Iam in Task %d\n",ST_getTask_id(Thread_usage));

			/*Modify the filename inaccordance to the ID of the task so that each task works on its own file */
			itoa(ST_getTask_id(Thread_usage),&SrcName[9]);
			
			
			if(ST_FAIL==ST_WriteToFile(SrcName, size, 0))
				printTerminalf("writetest :ST_WriteToFile() Failed for Task %d\n",ST_getTask_id(Thread_usage));
			else
			{
				printTerminalf("writetest: Task %d  Write Operation Completed successfully\n",ST_getTask_id(Thread_usage));				
				RetVal=ST_PASS;
			}

	//		printTerminalf("\n-----------------------WRITETEST : Task %d LOGS END---------------------- \n",ST_getTask_id(Thread_usage));
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);
			
}



/***************************************************************************
 * Function		- readtest
 * Functionality	- Performs file File Write and Read Operation for the requested size, 
 				   Also performs FileCopy and Compare operations to check for Data Integrity check  					
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
static void readtest(void)
{
	//size = size + INCDATA;
	char SrcName[MAX_FILE_LENGTH]="/hd/test1";
	char DestName[MAX_FILE_LENGTH]="/hd/test1"; // This is used for  File copy operation perfromed before we compare files for data integrity check
	 int RetVal=ST_FAIL;	// INitialize the Returning Value to Failiure 


	//		printTerminalf("\n-----------------------READTEST : Task %d LOGS FOLLOW---------------------- \n",ST_getTask_id(Thread_usage));
			
			/*Modify the Src filenme creation in accrodance to the mount point */
			strcpy(SrcName,gST_Mount_Pt);
			strcat(SrcName,"test1");
			
			/*Modify the Dest  filename creation in accrodance to the mount point */
			strcpy(DestName,gST_Mount_Pt);
			strcat(DestName,"copy");

			/*Modify the filename inaccordance to the ID of the task so that each task works on its own file */
			itoa(ST_getTask_id(Thread_usage),&SrcName[9]);

			/*Modify the filename inaccordance to the ID of the task so that each task works on its own file */
			itoa(ST_getTask_id(Thread_usage),&DestName[9]);

			

			if(ST_FAIL==ST_WriteToFile(SrcName, size, 0))
				printTerminalf("readtest :ST_WriteToFile() Failed for Task %d\n",ST_getTask_id(Thread_usage));
			else
				printTerminalf("readtest: Task %d  File Write Operation Completed successfully\n",ST_getTask_id(Thread_usage));
			
			
			if(ST_FAIL==ST_ReadFromFile(SrcName))
			{
				printTerminalf("readtest :ST_ReadFromFile() Failed for Task %d\n",ST_getTask_id(Thread_usage));
			}
			else
			{
				printTerminalf("readtest: Task %d  File Read Operation Completed successfully\n",ST_getTask_id(Thread_usage));

			
				if(ST_FAIL==ST_FileCopy(SrcName,DestName))
					printTerminalf("readtest: Task %d  File Copy operation failed\n",ST_getTask_id(Thread_usage));
				else
				{
	
					if(ST_IDENTICAL== ST_FileCmp(SrcName, DestName))
						RetVal=ST_PASS;
					else
					printTerminalf("readtest: Task %d  Written and  Read Files are not Identical\n",ST_getTask_id(Thread_usage));
				}	
					
				
			}

	//		printTerminalf("\n-----------------------READTEST : Task %d LOGS END---------------------- \n",ST_getTask_id(Thread_usage));			
			
			(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);


}




/***************************************************************************
 * Function		- writereadtest
 * Functionality	- Performs file File Write , Seek ( at offset 0) and Read Operation for the requested size
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
static void writereadtest(void)
{
	

/* Write and Read function to be executed with comparison - Modify as per required */


	static 	Uint8* SrcBufata=NULL;
	static 	Uint8* DesBufata=NULL;
	FILE * fptr=NULL;
	char SrcName[20]="/hd/test1";
	int Failiure_flag=0;
	Uint32 i;
	int RetVal=ST_FAIL;	// INitialize the Returning Value to Failiure 

	 		
	//		printTerminalf("\n-----------------------WRITEREADTEST : Task %d LOGS FOLLOW---------------------- \n",ST_getTask_id(Thread_usage));
			/*Modify the filenme creation in accrodance to the mount point */			
			strcpy(SrcName,gST_Mount_Pt);
			strcat(SrcName,"test1");

				
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


			/*Modify the filename inaccordance to the ID of the task so that each task works on its own file */
			itoa(ST_getTask_id(Thread_usage),&SrcName[9]);

			

			if(ST_PASS==ST_FileOpen(SrcName,"w+",(Ptr *)&fptr))
			{	
				if(ST_PASS==ST_FileWrite(fptr, size, 1, SrcBufata))
				{
					/*Perform file seek operation after file write operation , since opened in w+ mode  */
					if(ST_PASS==ST_FileSeek(fptr,0,0))
					{	
						if(ST_PASS==ST_FileRead(fptr,size,1,DesBufata))
						{
							for(i=0;i<size;i++)
							{
								if(SrcBufata[i]!=DesBufata[i])
								{
									printTerminalf("Data Mismatch at %d in Task %d\n",i,ST_getTask_id(Thread_usage));
									RetVal=ST_FAIL;
									break;
								}
								else
									RetVal=ST_PASS;
							}
						}
						else
							ST_FileClose((Ptr *)&fptr);						
					}
					else
						ST_FileClose((Ptr *)&fptr);						
				}	
				else
				{
					ST_FileClose((Ptr *)&fptr);
				}
			}	


				/*free the aquired memory for Src Buffer */
				free(SrcBufata);
							
				/*free the aquired memory for Dest Buffer */
				free(DesBufata);

	//		printTerminalf("\n-----------------------WRITEREADTEST : Task %d LOGS END---------------------- \n",ST_getTask_id(Thread_usage));
				// Return the status of the task
				(Thread_usage==1)?pthread_exit((int *)&RetVal):exit(RetVal);
			
			
}
