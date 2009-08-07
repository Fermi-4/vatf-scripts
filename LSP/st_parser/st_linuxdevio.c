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

/** \file   ST_LinuxDevIO.c
    \brief  System Test,  SystemCall  Tests

    This file contains the basic Systemcall tests 
    for the media driver.

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Anand Patil
    @version    0.1 - Created
**/
#define PERFROMANCE


#include "st_linuxdevio.h"

/* global params */
Int32 globalfd; // Global File Descriptor to Store FD for Open/Close Tests
extern Uint32 ST_BuffSize;
extern Uint32 Elapsed_Time;

void ST_FS_create()
{
	char fileName[FILE_NAME_LENGTH];
	mode_t mode = 0;
			
	printTerminalf("Enter the FileName and Flag/s(Refer asm/fcntl.h)\n ST_FS_create >");
	scanTerminalf("%s", fileName);
	scanTerminalf("%d", &mode);
	
	if(ST_PASS == ST_Create(fileName, mode, &globalfd))
	{
		printTerminalf("ST_FS_create, Create Successful\n");
		ST_Close(globalfd);
	}
	else
		printTerminalf("ST_FS_create, Create Failed\n");
}

void ST_FS_open()
{
	char fileName[FILE_NAME_LENGTH];
	Int32 flag;
			
	printTerminalf("Enter the FileName and Flag/s(Refer asm/fcntl.h)\n ST_FS_open >");
/*	printTerminalf("\n Flags can be used \ 
	 O_ACCMODE	   0003
	 O_RDONLY	     00
	 O_WRONLY	     01
	 O_RDWR		     02
	 O_CREAT	    0100
	 O_EXCL		   0200	
	 O_NOCTTY	   0400	
	 O_TRUNC	   01000
	 O_APPEND	  02000
	 O_NONBLOCK	  04000
	 O_NDELAY	O_NONBLOCK
	 O_SYNC		 010000
	 FASYNC		 020000
	 O_DIRECT	 040000
	 O_LARGEFILE	0100000 
	 O_DIRECTORY	0200000	
	 O_NOFOLLOW	0400000 
	 O_ATOMICLOOKUP	01000000 
	 \n");	*/
	scanTerminalf("%s", fileName);
	scanTerminalf("%d", &flag);
	
	if(ST_PASS == ST_Open(fileName, flag, &globalfd))
		printTerminalf("ST_FS_open, Open Successful\n");
	else
		printTerminalf("ST_FS_open, Open Failed\n");
}


void ST_FS_close()
{

	printTerminalf("To be called after open() only\n");
	if(ST_PASS == ST_Close(globalfd))
		printTerminalf("ST_FS_close, Close Successful\n");
	else
		printTerminalf("ST_FS_close, Close Failed\n");
}

void ST_FS_seek()
{
	int offset = 0;
	int origin = 0;

	printTerminalf("To be called after open() only\n");
	printTerminalf("Enter Offset and Origin (0=  be called after open() only\n");
	scanTerminalf("%d", &offset);
	scanTerminalf("%d", &origin);

	if(ST_PASS == ST_Seek(globalfd, offset, origin))
		printTerminalf("ST_FS_seek, Seek Successful\n");
	else
		printTerminalf("ST_FS_seek, Seek Failed\n");
}


void ST_FS_read()
{
	char     fileName[FILE_NAME_LENGTH];
	Uint32 size;
		
	printTerminalf("Enter the FileName to Read (Ex: /hd/test)\n ST_FS_read >"); 		
	scanTerminalf("%s", fileName);
	scanTerminalf("%d",&size);
	
	if((ST_PASS == ST_ReadFrom_SysFile(fileName,size)))
	{
		printTerminalf("ST_FS_read, Read Successful\n");
	}
	else
		printTerminalf("ST_FS_read, Read Failed\n");
}

void ST_FS_write()
{
	char fileName[FILE_NAME_LENGTH];
	Uint32 size = 0;
	
	printTerminalf("Enter the  FileName (Ex:- /hd/test) and Size of Data in Bytes\n ST_FS_write >"); 		
	scanTerminalf("%s", fileName);
	scanTerminalf("%d", &size);
	
	if(ST_PASS == ST_WriteTo_SysFile(fileName, size, ST_WRITE))
	{	

		printTerminalf("ST_FS_write, Write Successful\n");
	}
	else
		printTerminalf("ST_FS_write, Write Failed\n");
}



void ST_FS_getstat()
{
	LF_STAT fstatusInst;
	
	if(ST_PASS == ST_Status(globalfd, &fstatusInst))
		printTerminalf("ST_FS_getstat, Get File Statue Successful\n");
	else
		printTerminalf("ST_FS_getstat, Get File Statue Failed\n");
}



void ST_FS_Ioctl()
{
	int cmd=ST_FAIL;
	int val=ST_FAIL;
	Ptr arg;
	
	scanTerminalf("%d", cmd);
	scanTerminalf("%d",&val);
	arg=(int *)&val;
	
	if(ST_PASS == ST_Ioctl(globalfd,cmd,arg))
		printTerminalf("ST_FS_Ioctl, Ioctl issued Successful\n");
	else
		printTerminalf("ST_FS_getstat, Ioctl issued Failed\n");
}





/***************************************************************************
 * Function		- ST_ReadFrom_SysFile
 * Functionality	- Read a file and send buffer
 * Input Params		- fileName
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_ReadFrom_SysFile(char * srcfn, Uint32 size)
{
	Int32 sfd;
	Int8 retCode = ST_FAIL;
	//Uint32 size = 0;
	Uint32 unit = ST_BuffSize;
	Uint32 numBlocks = 0;
	Uint32 remainder = 0;
	Uint32 cnt;
	char * rB = 0;
	struct timeval time;
	long Start_Time=0;
	long End_Time=0;
	long Start_UTime=0;
	long End_UTime=0;
	double Elapsed_UTime=0.0000000;
		




	LF_STAT fstatusInst;
	
	
	//size = fstatusInst.st_size;
	numBlocks = size / unit;
	remainder = size % unit;
	
	#ifdef PERFROMANCE
	if(ST_FAIL == ST_Open(srcfn, O_RDONLY|O_SYNC,&sfd))
	#else	
	if(ST_FAIL == ST_Open(srcfn, O_RDONLY,&sfd))		
	#endif
		return ST_FAIL;
	
//	printTerminalf("ST_ReadFromFile, opened\n");

	if(ST_FAIL == ST_Status(sfd, &fstatusInst))
		return ST_FAIL;

	rB=(char *)malloc(ST_BuffSize);
	if(NULL== rB)
	{
		printTerminalf("ST_ReadFromFile, Mem Alloc of rB failed\n");
		ST_Close(sfd);
		return ST_FAIL;
	}
	
	
	//ST_Seek(sfd,0,0);// Seek Operation being Perfromed  

//	printTerminalf("ST_ReadFromFile, seeked\n");

	if(0 == numBlocks)
	{
		if(ST_FAIL != ST_Read(sfd,rB,size))
		{
			retCode = ST_PASS;
		}
	}
	else
	{
#ifdef PERFROMANCE
		if(-1!=gettimeofday(&time,NULL)) 
		{
			Start_Time=time.tv_sec;
			Start_UTime=time.tv_usec;
		}
		else
		perror("gettimeofday"); 	
#endif
		
		for(cnt = 0;cnt<numBlocks; cnt++)

		{
			if(ST_FAIL != ST_Read(sfd,rB,unit))
			{
			//printTerminalf("count=%d\t",cnt);

			}
			else
			{
				break;
			}
		}
		if(cnt == numBlocks)
		{
			if(0 != remainder)
			{

				if(ST_FAIL != ST_Read(sfd,rB, remainder))
				{
					retCode = ST_PASS;
				}
			}
			else
				retCode = ST_PASS;
		}
	}


	
	
	if(ST_FAIL == ST_Close(sfd))
	return ST_FAIL;
	
#ifdef PERFROMANCE
	gettimeofday(&time,NULL); 
	End_Time=time.tv_sec;
	End_UTime=time.tv_usec;
	
	printf("Buffer Size =%d\n",ST_BuffSize);
	printf("File   Size =%d\n",size);
	printf("Start Time  (Secs) =%ld\n",Start_Time);
	printf("End   Time  (Secs) =%ld\n",End_Time);
	printf("Start Time  (USecs)=%ld\n",Start_UTime);
	printf("End   Time  (USecs)=%ld\n",End_UTime);


	Elapsed_Time=End_Time-Start_Time;
	Elapsed_UTime=(End_UTime-Start_UTime)/1000000.0;
	Elapsed_UTime=(double)(End_Time-Start_Time)+ Elapsed_UTime;
	printf("Read Performance = %lfMBPS\n",((double)size/((Elapsed_UTime)*1048576)));
#endif	

	free(rB);
	return retCode;
}

/***************************************************************************
 * Function		- ST_WriteTo_SysFile
 * Functionality	- Writes/Appends a file
 * Input Params		- fileName, number of bytes, flag to indicate write or append
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_WriteTo_SysFile(char * fileName, Uint32 size, Uint32 writeFlag)
{
	Int8 retCode = ST_FAIL;
	Int8 openRetCode = ST_FAIL;
	char fillChar = 'A';
	char *	wB = 0;
	Uint32 MB_Size = ST_BuffSize;
	Uint32 numBlocks = 0;
	Uint32 numTimes;
	Uint32 remainder = 0;
	Int32 fd;
	struct timeval time;
	long Start_Time=0;
	long End_Time=0;
	long Start_UTime=0;
	long End_UTime=0;
	double Elapsed_UTime=0.000000;	


	if(fillChar == 'Z')
		fillChar = 'A';

	
	if(writeFlag == ST_APPEND)
		openRetCode = ST_Open(fileName, O_CREAT|O_APPEND, &fd);
	else
		{
		  #ifdef PERFROMANCE
		  openRetCode = ST_Open(fileName, O_CREAT|O_WRONLY|O_SYNC, &fd);
		  #else
		  openRetCode = ST_Open(fileName, O_CREAT|O_WRONLY, &fd);		  
		  #endif
		  
		 }
		
	if(ST_FAIL == openRetCode)
		return ST_FAIL;
	wB=(char *)malloc(ST_BuffSize);
	if(NULL==wB)
	{
		printTerminalf("ST_WriteToFile, Mem Alloc of wB failed\n");
		ST_Close(fd);
		return ST_FAIL;
	}
	
	memset(wB, fillChar++, MB_Size);
		
	
	if( size <= MB_Size)
	{	
		if(ST_FAIL != ST_Write(fd,wB,size))
		{
			retCode = ST_PASS;

		}
	}
	else
	{
	    numBlocks = (size/MB_Size);
	    remainder = size % MB_Size;
		    
#ifdef PERFROMANCE
	if(-1!=gettimeofday(&time,NULL)) 
	{
		Start_Time=time.tv_sec;
		Start_UTime=time.tv_usec;
	}
	else
	     perror("gettimeofday"); 			
#endif
	  for(numTimes = 0;numTimes < numBlocks; numTimes++)

	 {


			if(ST_FAIL != ST_Write(fd,wB,MB_Size))
			{
//			printTerminalf("count=%d\t",numTimes);

			}
			else
			{
				break;
			}
		}
		if(numTimes == numBlocks)
		{
			if(0 != remainder)
			{

				if(ST_FAIL != ST_Write(fd,wB,MB_Size))
				{
					retCode = ST_PASS;
				}
			}

			else
			{
				retCode = ST_PASS;
			}
		
		}
     

		 
  }
 

	if(ST_FAIL == ST_Close(fd))
	return ST_FAIL;
	
#ifdef PERFROMANCE
	gettimeofday(&time,NULL); 
	End_Time=time.tv_sec;
	End_UTime=time.tv_usec;
	printf("\nBuffer Size =%d\n",ST_BuffSize);
	printf("File   Size =%d\n",size);
	printf("Start Time  (Secs) =%ld\n",Start_Time);
	printf("End   Time  (Secs) =%ld\n",End_Time);
	printf("Start Time  (USecs)=%ld\n",Start_UTime);
	printf("End   Time  (USecs)=%ld\n",End_UTime);

//Calculations Perfromed
	Elapsed_Time=End_Time-Start_Time;
	Elapsed_UTime=((double)(End_UTime-Start_UTime))/1000000.0;
	Elapsed_UTime=(double)(End_Time-Start_Time)+ Elapsed_UTime;

	printf("Write Perfromance = %lfMBPS\n",((double)size/((Elapsed_UTime)*1048576)));
#endif	

	free(wB);
	return retCode;
}


