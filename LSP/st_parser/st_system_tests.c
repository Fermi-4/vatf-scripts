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
                                                   
/** \file  System_Tests.c 
    \brief Captures the code for system test cases 

    (C) Copyright 2005, Texas Instruments, Inc

    @author     K R Baalaaji
    @version    0.1 - Created
				0.2 - Features added include - run for ever, cleanup MSC tx files, 
						calculation of total bytes transfered, individual buffer sizes/
						buffer increments/num times before increment for each task
					  Cleanup includes - allocation pool, comments from test team review
				0.3 - Adapted to linux
                
**/


//<PEND> Have one common source file for both linux and PrOS
#include "st_automation_io.h"
#include "st_common.h"
#include "st_fstests.h"
#include <stdio.h>

//Tune these based on the needs
#define MAX_ST_TASKS	24

//Use printf for CCS console out and printTerminalf for UART console out
//Based on the need, change the STLog definition in ST_Common.h

extern int ST_memPoolId;

//return values
#define ERROR	-1
#define SUCCESS	0

#define FORCE_LOG	1

//status defines
#define FREE	1
#define BUSY	0

//All IO functions have to have this signature.
//Intrepretations can be different
typedef int (*IO) (char *, char *, int);

//Task Structure
struct taskParam
{
	char isFree;						//FREE if task free or BUSY if task occupied
	int processId;						//processId of the task spawned
	IO src;								//source(read) function
	IO sink;							//sink(write function
	char * rxParam;						//read parameter - filename for MSC, dev name for serial devices
	char * txParam;						//write parameter - filename for MSC, dev name for serial devices
	char * buffer;						//pointer to buffer
	unsigned int initBuffSize;			//initial buffer size for IO
	unsigned int buffSize;				//the current buffer size for IO
	int bufferIncrement;  				//increment for buffer size (could be negative) after defined number of iteration
	unsigned int numTimesBeforeBuffInc;	//number of iterations before buffer size increment
	unsigned int maxIterations;			//number of iterations to be carried out
	unsigned int currIteration;			//current number of completed iteration
	unsigned int cleanupTxFile;			//flag to indicate whether to clean up the Tx MSC file after the max iterations
	unsigned int repeatForEver;			//flag to keep repeating the iterations in a loop for ever
	int logToHyperTerminal;				//flag to log the messages to Hyper Terminal
};

//Global array of System Test Tasks
struct taskParam ST_Tasks[MAX_ST_TASKS];

//Index of the task to be spawned
int currIndex;

//Function declarations
void createTask();
void initTaskArray();
int entryTask();
void cleanupTask(struct taskParam * task);

//Declare all IO functions here
int txMSC(char * fileName, char * buff, int size);
int rxMSC(char * fileName, char * buff, int size);
int rxSERIAL(char * fileName, char * buff, int size);
int txSERIAL(char * fileName, char * buff, int size);

//Function to log info onto a MMC/SD card
//Change systemLog to take a printf kind of arguments <PEND>
void systemLog(char * buff, int logToHT);

//Function to initialize all the task parameters
void initTaskArray()
{
	int taskIndex = 0;

	for(taskIndex=0; taskIndex < MAX_ST_TASKS; taskIndex++)
	{
		ST_Tasks[taskIndex].isFree = FREE;
		ST_Tasks[taskIndex].processId = 0;
		ST_Tasks[taskIndex].src = 0;
		ST_Tasks[taskIndex].sink = 0;
		ST_Tasks[taskIndex].rxParam = 0;
		ST_Tasks[taskIndex].txParam = 0;
		ST_Tasks[taskIndex].buffer = 0;
		ST_Tasks[taskIndex].buffSize = 0;
		ST_Tasks[taskIndex].initBuffSize = 0;
		ST_Tasks[taskIndex].bufferIncrement = 0;
		ST_Tasks[taskIndex].numTimesBeforeBuffInc = 0;
		ST_Tasks[taskIndex].maxIterations = 0;
		ST_Tasks[taskIndex].currIteration = 0;
		ST_Tasks[taskIndex].cleanupTxFile = 0;
		ST_Tasks[taskIndex].repeatForEver = 0;
		ST_Tasks[taskIndex].logToHyperTerminal = 0;
	}

	//Initialize all the peripherals here
	
}

//If free task available, gather input for the task to be spawned and spawn it
int ST_EntryPoint()
{
	int taskIndex = 0;
	int source = 0;
	int destination = 0;
	int alloc = 0;
	char rxParam[50];
	char txParam[50];
		
	//Go through the task list to find a free task	
	for(taskIndex=0; taskIndex < MAX_ST_TASKS; taskIndex++)
	{
		if(FREE == ST_Tasks[taskIndex].isFree)
		{	
			//get source and destination devices
			printTerminalf("Enter the source (0 for MSC, 1 for Serial)\n");
			scanTerminalf("%d", &source);
	
			printTerminalf("Enter the destination (0 for MSC, 1 for Serial)\n");
			scanTerminalf("%d", &destination);

			switch(source)
			{
				//case "ata" : case "mmc" : case "nand" : case "usb-host" :
				case 0 :
					ST_Tasks[taskIndex].src = rxMSC;
					break;
			
				//case "uart" : case : "i2C" case "spi" :
				case 1 :
					ST_Tasks[taskIndex].src = rxSERIAL;
					break;
			}

			switch(destination)
			{
				//case "ata" : case "mmc" : case "nand" : case "usb-host" :
				case 0 :
					ST_Tasks[taskIndex].sink = txMSC;

					printTerminalf("Enter 1 to cleanup the files after the run\n");
					scanTerminalf("%d", &ST_Tasks[taskIndex].cleanupTxFile);

					break;
			
				//case "uart" : case : "i2C" case "spi" :
				case 1 :
					ST_Tasks[taskIndex].sink = txSERIAL;
					break;
			}

			//The parameter distinguishes which MSC (ATA/MMC/NAND/USB-Host) device to act on 
			//Correct mount path should be provided for the MSC devices.
			//The parameter distinguishes which serial (UART/I2C/SPI) device to act on 
			printTerminalf("Enter the rxParam (For MSC - file name and for Serial - \"uart\" \"i2c\" or \"spi\"\n");
			scanTerminalf("%s", rxParam);

			printTerminalf("Enter the txParam (For MSC - file name and for Serial - \"uart\" \"i2c\" or \"spi\"\n");
			scanTerminalf("%s", txParam);

			// To do for different slaves <PEND>
			#if 0
			if((0 == strcmp(rxParam, "i2c")) || (0 == strcmp(txParam, "i2c")))
			{
				printTerminalf("Enter the slave address\n");
				scanTerminalf("%d", slaveAddress);
			}
			#endif

			ST_Tasks[taskIndex].rxParam = (char *) malloc(strlen(rxParam)+1);
			if(0 == ST_Tasks[taskIndex].rxParam)
			{
				systemLog("ST_EntryPoint, Alloc of rxParam failed\n", FORCE_LOG);
				return ERROR;
			}
			else
			{	
				//ST_Tasks[taskIndex].rxParam = (char*)((int)(ST_Tasks[taskIndex].rxParam + CACHE_LINE_SIZE_IN_BYTES-1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));
				strcpy(ST_Tasks[taskIndex].rxParam, rxParam);
			}
					
			ST_Tasks[taskIndex].txParam = (char *) malloc(strlen(txParam)+1);
			if(0 == ST_Tasks[taskIndex].txParam)
			{
				cleanupTask(&ST_Tasks[currIndex]);
				systemLog("ST_EntryPoint, Alloc of txParam failed\n", FORCE_LOG);
				return ERROR;
			}
			else
			{	
				//ST_Tasks[taskIndex].txParam = (char*)((int)(ST_Tasks[taskIndex].txParam + CACHE_LINE_SIZE_IN_BYTES-1) & ~(CACHE_LINE_SIZE_IN_BYTES - 1));
				strcpy(ST_Tasks[taskIndex].txParam, txParam);
			}

			printTerminalf("Enter the maximum number of iterations\n");
			scanTerminalf("%d", &ST_Tasks[taskIndex].maxIterations);

			printTerminalf("Enter the Initial Buffer Size\n");
			scanTerminalf("%d", &ST_Tasks[taskIndex].initBuffSize);

			printTerminalf("Enter the buffer increment (Could be negative to step down)\n");
			scanTerminalf("%d", &ST_Tasks[taskIndex].bufferIncrement);

			printTerminalf("Enter the number of iterations before buffer size increment\n");
			scanTerminalf("%d", &ST_Tasks[taskIndex].numTimesBeforeBuffInc);
			
			printTerminalf("Enter 1 to repeat the tests for ever\n");
			scanTerminalf("%d", &ST_Tasks[taskIndex].repeatForEver);

			printTerminalf("Enter 1 to log to HT or 0 not to log\n");
			scanTerminalf("%d", &ST_Tasks[taskIndex].logToHyperTerminal);
			
			ST_Tasks[taskIndex].isFree = BUSY;
			ST_Tasks[taskIndex].buffSize = ST_Tasks[taskIndex].initBuffSize;
			
			STLog("ST_EntryPoint, Source : %d\nDestination : %d\nRxParam : %s\nTxParam : %s\nInitial Buffer Size : %d\nMaximum Iterations : %d\nBuffer Increment : %d\nNumber of times before Increment : %d\nRepeat Forever : %d\nLog To Hyperterminal : %d\n", source, destination, ST_Tasks[taskIndex].rxParam, ST_Tasks[taskIndex].txParam, ST_Tasks[taskIndex].buffSize, ST_Tasks[taskIndex].maxIterations, ST_Tasks[taskIndex].bufferIncrement, ST_Tasks[taskIndex].numTimesBeforeBuffInc, ST_Tasks[taskIndex].repeatForEver, ST_Tasks[taskIndex].logToHyperTerminal);
			
			//Index of the task to be spawned
			currIndex = taskIndex;			

			//Create the task
			createTask();
			
			//Task allocation succeeded
			alloc = 1;
			
			STLog("ST_EntryPoint, Finished Spawning %d\n", taskIndex);
			systemLog("--- Spawned Task --- ", FORCE_LOG);
			
			break;
		}
	}

	//If alloc is '0', no tasks are free
	if(0 == alloc)
	{
		STLog("ST_EntryPoint, No free tasks\n");
		return ERROR;
	}
	else
	{
		return SUCCESS;
	}
}

void createTask()
{
	//spawn a task with entryTask
	switch(fork())
	{
		case 0: // Child Process
			entryTask();
			//<PEND> Fill in the process id
			break;
		default:
			break;
	}
}

//task entry point. the task is cleaned up after any failure
int entryTask()
{
	int readRet = 0;
	int writeRet = 0;
	unsigned int txSize = 0;
	char logBuff[240];
	char * bufferPtr = 0;

	struct taskParam * currTask = &ST_Tasks[currIndex];

	//protect currIndex till this point
	currTask->buffer = (char *) malloc(currTask->buffSize);
	if(0 == currTask->buffer)
	{
		systemLog("entryTask, Alloc of buffer failed\n", currTask->logToHyperTerminal);
		cleanupTask(currTask);
		return ERROR;
	}

	bufferPtr = currTask->buffer;

	if(txMSC == currTask->sink)
	{
		//Check the file size here
	}

	if(rxMSC == currTask->src)
	{
		//Check the file size here
	}
	
	while(1)
	{
		//check for completion of the defined number of iterations
		if(currTask->currIteration == currTask->maxIterations)
		{
			STLog("entryTask, Task completed successfully\n");
			STLog("entryTask, Total bytes transmitted : %d\n", txSize);
			
			//Cleanup the tx file here
			if(txMSC == currTask->sink)
			{
				//<PEND>Check the file size here

				if(1 == currTask->cleanupTxFile)
				{
					ST_FileRemove(currTask->txParam);
				}
			}
		
			//Reset all values here and continue from start
			if(1 == currTask->repeatForEver)
			{
				txSize = 0;
				currTask->buffSize = currTask->initBuffSize; 
				currTask->currIteration = 0;
				continue;
			}
			
			cleanupTask(currTask);
			return SUCCESS;
		}

		//read the buffer from the source and write to the sink
		readRet = currTask->src(currTask->rxParam, bufferPtr, currTask->buffSize);

		//delay added so that tasks with the same priority can be scheduled
		sleep(1);
		if(0 == readRet) 
			writeRet = currTask->sink(currTask->txParam, bufferPtr, currTask->buffSize);
		else
		{
			STLog("entryTask, Rx of %s failed\n", currTask->rxParam);
			cleanupTask(currTask);
			return ERROR;
		}

		if(0 != writeRet)
		{
			STLog("entryTask, Tx of %s failed\n", currTask->txParam);
			cleanupTask(currTask);
			return ERROR;
		}

		//increment the execution count
		currTask->currIteration++;

		//increment the size here
		txSize = txSize + currTask->buffSize;

		sprintf(logBuff, "entryTask, Task Id : %d, Finished Iteration %d, BuffSize %d, Total Transfered %d\n", currTask->processId, currTask->currIteration, currTask->buffSize, txSize);
		systemLog(logBuff, currTask->logToHyperTerminal);	
		
		//delay added so that tasks with the same priority can be scheduled
		sleep(1);

		//after a specific number of executions, increment the buffer size and reallocate buffer
		if(0 == (currTask->currIteration) % (currTask->numTimesBeforeBuffInc))
		{
		  	free(currTask->buffer);
			currTask->buffer = 0;
			bufferPtr = 0;
			currTask->buffSize += currTask->bufferIncrement;
			currTask->buffer = (char *) malloc(currTask->buffSize);
			if(0 == currTask->buffer)
			{
				systemLog("entryTask, Re-Alloc of buffer failed\n", currTask->logToHyperTerminal);
				cleanupTask(currTask);
				return ERROR;
			}
			bufferPtr = currTask->buffer;
		}
	}
}

//Cleanup the task buffers and state information
void cleanupTask(struct taskParam * task)
{
	char logBuff[240];

	sprintf(logBuff, "cleanupTask, cleaning up task - %d\n", task->processId);
	STLog("cleanupTask, cleaning up task - %d\n", task->processId);
	systemLog(logBuff, task->logToHyperTerminal);

	if(0 != task->buffer) 
		free(task->buffer);
	
	if(0 != task->rxParam) 
		free(task->rxParam);
	
	if(0 != task->txParam) 
		free(task->txParam);

	task->isFree = FREE;
	task->src = 0;
	task->sink = 0;
	task->buffer = 0;
	task->buffSize = 0;
	task->rxParam = 0;
	task->txParam = 0;
	task->maxIterations = 0;
	task->bufferIncrement = 0;
	task->numTimesBeforeBuffInc = 0;
	task->currIteration = 0;
	task->cleanupTxFile = 0;
	task->repeatForEver = 0;
	task->processId = 0;
	task->logToHyperTerminal = 0;
}

//Function for MSC write
int txMSC(char * fileName, char * buff, int size)
{
	FILE * fd = 0;
	int retVal = SUCCESS;

	if(ST_FAIL == ST_FileOpen(fileName,"a", (Ptr *)&fd))
		return ERROR;
		
    if(ST_FAIL == ST_FileWrite(fd, size, 1, buff))
		retVal = ERROR;

	if(ST_FAIL == ST_FileClose((Ptr *)&fd))
		retVal = ERROR;
	
	return retVal;
}

//Function for MSC read
int rxMSC(char * fileName, char * buff, int size)
{
	FILE * fd = 0;
	int retVal = SUCCESS;

	if(ST_FAIL == ST_FileOpen(fileName,"r",(Ptr *)&fd))
		return ERROR;
		
    if(ST_FAIL == ST_FileRead(fd, size, 1, buff))
		retVal = ERROR;

	if(ST_FAIL == ST_FileClose((Ptr *)&fd))
		retVal = ERROR;
	
	return retVal;
}

//Function for serial read
int rxSERIAL(char * fileName, char * buff, int size)
{
	int fd = 0;
	int retVal = SUCCESS;

	if(ST_FAIL == ST_Open(fileName, O_RDWR, &fd))
		return ERROR;
	
    if(ST_FAIL == ST_Read(fd, buff, size))
		retVal = ERROR;

	if(ST_FAIL == ST_Close(fd))
		retVal = ERROR;
	
	return retVal;
}

//Function for serial write
int txSERIAL(char * fileName, char * buff, int size)
{
	int fd = 0;
	int retVal = SUCCESS;

	if(ST_FAIL == ST_Open(fileName, O_RDWR,&fd))
		return ERROR;
	
    if(ST_FAIL == ST_Write(fd, buff, size))
		retVal = ERROR;

	if(ST_FAIL == ST_Close(fd))
		retVal = ERROR;
	
	return retVal;
}

//Function for logging
void systemLog(char * buff, int logToHT)
{
	FILE * fd = 0;

	if(ST_FAIL == ST_FileOpen("/sysLog/systemLog","a",(Ptr *)&fd))
	{
		printTerminalf("systemLog, file open failed\n");
	}
		
    if (ST_FAIL == ST_FileWrite(fd, strlen(buff), 1, buff))
	{
		printTerminalf("systemLog, file write failed\n");
	}

	if(ST_FAIL == ST_FileClose((Ptr *)&fd))
	{
		printTerminalf("systemLog, file close failed\n");
	}

	if(1 == logToHT)
		STLog(buff);
		
	return;
}

void toggleTaskLogging(int taskId)
{
	ST_Tasks[taskId].logToHyperTerminal = 1 - ST_Tasks[taskId].logToHyperTerminal;
}
