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

/** \file   ST_FSTests.c
    \brief  System Test, File System Tests

    This file contains the basic filesystem tests 
    for the media driver.

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Anand Patil
    @version 	0.1
*/

#include "st_fstests.h"

#define PERFROMANCE
#define ENABLE_SUCCESS_PRINTS 0

/* global params */

Uint32 ST_BuffSize = BuffSize;
Uint32 gNum_Blk=1;
Uint32 Elapsed_Time;
Ptr globalfp;// Global Pointer To Store FP for Open/Close Tests


//extern variables

extern int ST_LogFlag;


/***************************************************************************
 * Function		- ST_FS_Drvmount
 * Functionality	- User Interface for Drive mount operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_Drvmount()
{
	char devicename[FILE_NAME_LENGTH], mountpt[FILE_NAME_LENGTH],filesys[25];
	Uint32 mntflags=0;
	Ptr Data=NULL;		
				
	printTerminalf("Enter the Device Name\n");
	scanTerminalf("%s", devicename);
	printTerminalf("Enter the mount point\n");
	scanTerminalf("%s", mountpt);
	printTerminalf("Enter the mount flags\n");
	scanTerminalf("%s", mntflags);
	printTerminalf("Enter the filesystem type\n");
	scanTerminalf("%s", filesys);	
		
	if(ST_PASS == ST_Drvmount(devicename,mountpt,filesys,mntflags,Data))
		printTerminalf("ST_FS_Drvmount, Open Successful\n");
	else
		printTerminalf("ST_FS_Drvmount, Open Failed\n");
}


/***************************************************************************
 * Function		- ST_FS_Drvumount
 * Functionality	- User Interface for Drive unmount operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_Drvumount()
{
	char mountpt[FILE_NAME_LENGTH]="/hd";
			
	printTerminalf("Enter the mount point\n");
	scanTerminalf("%s", mountpt);
		
	if(ST_PASS == ST_Drvumount(mountpt))
		printTerminalf("ST_FS_Drvumount, Open Successful\n");
	else
		printTerminalf("ST_FS_Drvumount, Open Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_ftruncate
 * Functionality	- User Interface for file truncate operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_ftruncate()
{
	Int32 fd=-1;
	char fileName[20];
	Int32 offset=0;
	
	printTerminalf("Enter Filename\n");
	printTerminalf("Enter FileOffset\n");
	scanTerminalf("%s",fileName);
	scanTerminalf("%d",&offset);	
	ST_Open(fileName,O_RDWR|O_CREAT,&fd);
	if(-1==ftruncate(fd,offset))
	perror("ftruncate");
	
	ST_Close(fd);

}	

/***************************************************************************
 * Function		- ST_FS_fopen
 * Functionality	- User Interface for file open operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_fopen()
{
	char fileName[FILE_NAME_LENGTH];
	char mode[3];
			
	printTerminalf("Enter FileName and Permissions (r,r+,w,w+, rw)\n ST_FS_fopen >");
	scanTerminalf("%s", fileName);
	scanTerminalf("%s", &mode);
	
	if(ST_PASS == ST_FileOpen(fileName, mode,(Ptr *) &globalfp))
		printTerminalf("ST_FS_fopen, Open Successful\n");
	else
		printTerminalf("ST_FS_fopen, Open Failed\n");
}


/***************************************************************************
 * Function		- ST_FS_fclose
 * Functionality	- User Interface for file Close operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_fclose()
{
	printTerminalf("This Function has to be used after fopen()only\n");
	printTerminalf("Enter FileName to be closed\n");
	if(ST_PASS == ST_FileClose((Ptr *)&globalfp))
		printTerminalf("ST_FS_fclose, Close Successful\n");
	else
		printTerminalf("ST_FS_fclose, Close Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_fseek
 * Functionality	- User Interface for file seek operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_fseek()
{
	int offset = 0;
	int origin = 0;

	printTerminalf("This Function has to be used after fopen()only\n");
	printTerminalf("Enter Offset and Origin ( 0=Start 1=Current  2=End )\n ST_FS_fseek");
	scanTerminalf("%d", &offset);
	scanTerminalf("%d", &origin);

	if(ST_PASS == ST_FileSeek(globalfp, offset, origin))
		printTerminalf("ST_FS_fseek, Seek Successful\n");
	else
		printTerminalf("ST_FS_fseek, Seek Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_fread
 * Functionality	- User Interface for file Read operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_fread()
{
	char     fileName[FILE_NAME_LENGTH];

	printTerminalf("\nEnter the FileName to be Read\n ST_FS_fread >"); 		
	scanTerminalf("%s", fileName);

	if((ST_PASS == ST_ReadFromFile(fileName)))
	{
		printTerminalf("ST_FS_fread, Read Successful\n");
	}
	else
		printTerminalf("ST_FS_fread, Read Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_fwrite
 * Functionality	- User Interface for file Write operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_fwrite()
{
	char fileName[FILE_NAME_LENGTH];
	Uint32 size = 0;
	
	printTerminalf("\nFile will be Opened with w Permissions\n"); 		
	printTerminalf("\nEnter the FileName(Ex:/hd/test) and Size of Data in Bytes\n ST_FS_fwrite >"); 		
	scanTerminalf("%s", fileName);
	scanTerminalf("%d", &size);
	
	if(ST_PASS == ST_WriteToFile(fileName, size, ST_WRITE))
	{	
		printTerminalf("ST_FS_fwrite, Write Successful\n");
	}
	else
		printTerminalf("ST_FS_fwrite, Write Failed\n");
}


/***************************************************************************
 * Function		- ST_FS_fappend
 * Functionality	- User Interface for file append operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_fappend()
{
	char fileName[FILE_NAME_LENGTH];
	int size = 0;
	
	printTerminalf("File will be Opened with a+ Permissions\n"); 		
	printTerminalf("Enter the FileName(Ex:/hd/test) and Size of Data in Bytes\n ST_FS_fappend >"); 		
	scanTerminalf("%s", fileName);
	scanTerminalf("%d", &size);
	
	if(ST_PASS == ST_WriteToFile(fileName, size, ST_APPEND))
		printTerminalf("ST_FS_fappend, Append Successful\n");
	else
		printTerminalf("ST_FS_fappend, Append Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_fcompare
 * Functionality	- User Interface to Copy Src and Dest files operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_fcopy()
{
	char srcfName[FILE_NAME_LENGTH];
	char dstfName[FILE_NAME_LENGTH];

	printTerminalf("Enter the SrcFileName(Ex:/hd/test) and DestFileName (Ex:/hd1/test1)\n ST_FS_fcopy >"); 		
	scanTerminalf("%s", srcfName);
	scanTerminalf("%s", dstfName);
	
	if(ST_PASS == ST_FileCopy(srcfName, dstfName))
		printTerminalf("ST_FS_fcopy, Copy Successful\n");
	else
		printTerminalf("ST_FS_fcopy, Copy Failed\n");
}


/***************************************************************************
 * Function		- ST_FS_fcompare
 * Functionality	- User Interface to Compare Src and Dest  files operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_fcompare()
{
	char srcfName[FILE_NAME_LENGTH];
	char dstfName[FILE_NAME_LENGTH];
	Int8 retCode = 0;
	
	printTerminalf("Enter the SrcFileName (Ex:/hd/test) and DestFileName (Ex:/hd1/test1)\n ST_FS_fcompare >"); 		
	scanTerminalf("%s", srcfName);
	scanTerminalf("%s", dstfName);
	
	retCode = ST_FileCmp(srcfName, dstfName);
	if(ST_IDENTICAL == retCode)
		printTerminalf("ST_FS_fcompare, Files are identical\n");
	else if(ST_NOT_IDENTICAL == retCode)
		printTerminalf("ST_FS_fcompare, Files are not identical\n");
	else
		printTerminalf("ST_FS_fcompare, Error during compare\n");
}

/***************************************************************************
 * Function		- ST_FS_getfstat
 * Functionality	- User Interface to Get  FileStatus operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_getfstat()
{
	char fileName[FILE_NAME_LENGTH];
	// File Status Information instance
	LF_STAT fstatusInst;
	
	printTerminalf("Enter the FileName\n ST_FS_getfstat >"); 		
	scanTerminalf("%s", fileName);
	if(ST_PASS == ST_FileStatus(fileName, &fstatusInst))
		printTerminalf("ST_FS_getstat, Get File Statue Successful\n");
	else
		printTerminalf("ST_FS_getstat, Get File Statue Failed\n");
}


/***************************************************************************
 * Function		- ST_FS_frename
 * Functionality	- User Interface to Rename File operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_frename()
{
	char oldfName[FILE_NAME_LENGTH];
	char newfName[FILE_NAME_LENGTH];
		
	scanTerminalf("%s", oldfName);
	scanTerminalf("%s", newfName);
	
	printTerminalf("Enter the OldFileName and NewFileName\n ST_FS_frename >"); 		
	if(ST_PASS == ST_FileRename(oldfName, newfName))
		printTerminalf("ST_FS_frename, Rename Successful\n");
	else
		printTerminalf("ST_FS_frename, Rename Failed\n");
}


/***************************************************************************
 * Function		- ST_FS_mkdir
 * Functionality	- User Interface to Create Directory operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_mkdir()
{
	char dirName[FILE_NAME_LENGTH];
	mode_t mode;
		
	printTerminalf("Enter the DirName and Permissions (Value & ~umask):\n ST_FS_mkdir >"); 		
	scanTerminalf("%s", dirName);
	scanTerminalf("%d", &mode);
	if(ST_PASS == ST_DirCreate(dirName,mode))
		printTerminalf("ST_FS_mkdir, Directory Create Successful\n");
	else
		printTerminalf("ST_FS_mkdir, Directory Create Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_rmdir
 * Functionality	- User Interface to Remove Directory operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_rmdir()
{
	char dirName[FILE_NAME_LENGTH];
		
	printTerminalf("Enter the DirName\n ST_FS_rmdir >"); 		
	scanTerminalf("%s", dirName);
	
	if(ST_PASS == ST_DirRemove(dirName))
		printTerminalf("ST_FS_rmdir, Directory Delete Successful\n");
	else
		printTerminalf("ST_FS_rmdir, Directory Delete Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_chdir
 * Functionality	- User Interface to Change Directory operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_FS_chdir()
{
	char dirName[FILE_NAME_LENGTH];
		
	printTerminalf("Enter the DirPath to be changed to\n ST_FS_chdir >"); 		
	scanTerminalf("%s", dirName);
	
	if(ST_PASS == ST_DirChange(dirName))
		printTerminalf("ST_FS_chdir, Change Directory Successful\n");
	else
		printTerminalf("ST_FS_chdir, Change Directory Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_chmodeFile
 * Functionality	- User Interface to File Change mode operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
 void ST_FS_chmodeFile()
{
	char fileName[FILE_NAME_LENGTH];
	mode_t  mode = 0;
		
	printTerminalf("Enter the FileName and Permission Value(Ex:-777)\n ST_FS_fcompare >"); 		
	scanTerminalf("%s", fileName);
	scanTerminalf("%d", &mode);
	
	if(ST_PASS == ST_FileChangeMode(fileName, mode))
		printTerminalf("ST_FS_chmodeFile, Change File Mode Successful\n");
	else
		printTerminalf("ST_FS_chmodeFile, Change File Mode Failed\n");
}

/***************************************************************************
 * Function		- ST_FS_fremove
 * Functionality	- User Interface to File remove operation
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
 void ST_FS_fremove()
	{
	char fileName[FILE_NAME_LENGTH];
		
	printTerminalf("Enter the FileName\n ST_FS_fremove >"); 		
	scanTerminalf("%s", fileName);
	
	if(ST_PASS == ST_FileRemove(fileName))
		printTerminalf("ST_FS_fileRemove, Remove Successful\n");
	else
		printTerminalf("ST_FS_fileRemove, Remove Failed\n");

}



/***************************************************************************
 * Function		- ST_FileCopy
 * Functionality	- Copy the file 
 * Input Params		- Source FileName, Destination FileName
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- At present, the function doesnot handle any of the 
 *			  error conditions as part of filesystem API failures
 ****************************************************************************/
Int8
ST_FileCopy(char * srcfn, char * dstfn)
{
	FILE * sfptr = 0;
	FILE * dfptr = 0;
	Int8 retCode = ST_FAIL;
	Uint32 size = 0;
	Uint32 unit = ST_BuffSize;
	Uint32 numBlocks = 0;
	Uint32 remainder = 0;
	char * rB = 0;
	Uint32 cnt = 0;
	// File Status Information instance
	LF_STAT fstatusInst;
	
	if(ST_FAIL == ST_FileStatus(srcfn, &fstatusInst))
		return ST_FAIL;

	size = fstatusInst.st_size;
	numBlocks = size / unit;
	remainder = size % unit;
	
	if(ST_FAIL == ST_FileOpen(srcfn, "r",(Ptr *)&sfptr))
		return ST_FAIL;

	if(ST_FAIL == ST_FileOpen(dstfn, "w", (Ptr *)&dfptr))
	{
		ST_FileClose((Ptr *) &sfptr);
		return ST_FAIL;
	}
	
	rB=(Int8 *)malloc(ST_BuffSize);
	if(NULL==rB)
	{
		printTerminalf("ST_FileCopy, Mem Alloc of rB failed\n");
		return ST_FAIL;
	}
	
	if(0 == numBlocks)
	{
		if(ST_FAIL != ST_FileRead(sfptr, size, 1, rB))
		{
			if(ST_FAIL != ST_FileWrite(dfptr, size, 1, rB))
			{
				retCode = ST_PASS;
			}
		}
	}
	else
	{
		for(cnt = 0; cnt < numBlocks; cnt++)
		{
			if(ST_FAIL != ST_FileRead(sfptr, unit, 1, rB))
			{
				if(ST_FAIL != ST_FileWrite(dfptr, unit, 1, rB))
				{

				}
				else
				{
					break;
				}
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
				if(ST_FAIL != ST_FileRead(sfptr, remainder, 1, rB))
				{
					if(ST_FAIL != ST_FileWrite(dfptr, remainder, 1, rB))
					{	
						retCode = ST_PASS;
					}
				}
			}
			else
			{
				retCode = ST_PASS;
			}
		}
	}

	free(rB);
/*    if(ST_PASS != PAL_osMemFree(PAL_OSMEM_DEFAULT_SEGID,
	                              rB,
	                              ST_BuffSize))
	{
		printTerminalf("ST_FileCopy, Mem Free of rB failed\n");
    }*/

	if((ST_PASS == ST_FileClose((Ptr *) &sfptr)) && (ST_PASS ==  ST_FileClose((Ptr *) &dfptr)))
		return retCode;
	else
		return ST_FAIL;

}

/***************************************************************************
 * Function		- ST_FileCmp
 * Functionality	- Comapres the files 
 * Input Params		- Source FileName, Destination FileName
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- At present, the function doesnot handle any of the 
 *			  error conditions as part of filesystem API failures
 ****************************************************************************/
Int8
ST_FileCmp(char * srcfn, char * dstfn)
{
	FILE * sfptr = 0;
	FILE * dfptr = 0;
	Int8 retCode = ST_FAIL;
	Uint32 size = 0;
	Uint32 unit = ST_BuffSize;
	Uint32 numBlocks = 0;
	Uint32 remainder = 0;
	char * sRB = 0;
	char * dRB = 0;
	Uint32 cnt = 0;
	Uint32 srcSize = 0;
	Uint32 dstSize = 0;
	// File Status Information instance
	LF_STAT fstatusInst;

	if(ST_FAIL == ST_FileStatus(srcfn, &fstatusInst))
		return ST_FAIL;

	srcSize = fstatusInst.st_size;

	if(ST_FAIL == ST_FileStatus(dstfn, &fstatusInst))
		return ST_FAIL;

	dstSize = fstatusInst.st_size;
	
	if(srcSize != dstSize)
		return ST_NOT_IDENTICAL;
		
	size = fstatusInst.st_size;
	numBlocks = size / unit;
	remainder = size % unit;
	
	if(ST_FAIL ==  ST_FileOpen(srcfn, "r",(Ptr *)&sfptr))
		return ST_FAIL;
	
	if(ST_FAIL == ST_FileOpen(dstfn, "r",(Ptr *)&dfptr))
	{
		ST_FileClose((Ptr *) &sfptr);
		return ST_FAIL;
	}

	sRB=(Int8 *)malloc(ST_BuffSize);
	if(NULL==sRB)
	{
		printTerminalf("ST_FileCmp, Mem Alloc of sRB failed\n");
		return ST_FAIL;
	}

	dRB=(Int8 *)malloc(ST_BuffSize);
	if(NULL==dRB)
	{
		printTerminalf("ST_FileCmp, Mem Alloc of dRB failed\n");
		
		return ST_FAIL;
	}

	if(0 == numBlocks)
	{
		if(ST_FAIL != ST_FileRead(sfptr, size, 1, sRB))
		{
			if(ST_FAIL != ST_FileRead(dfptr, size, 1, dRB))
			{
				if(0 != memcmp(sRB, dRB, size))
				{
					retCode = ST_NOT_IDENTICAL;
				}
				else
				{
					retCode = ST_IDENTICAL;
				}
			}
		}	
	}
	else
	{
		for(cnt = 0; cnt < numBlocks; cnt++)
		{
			if(ST_FAIL != ST_FileRead(sfptr, unit, 1, sRB))
			{
				if(ST_FAIL != ST_FileRead(dfptr, unit, 1, dRB))
				{
					if(0 != memcmp(sRB, dRB, unit))
					{
						retCode = ST_NOT_IDENTICAL;
						break;
					}
				}
				else
				{
					break;
				}
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
				if(ST_FAIL != ST_FileRead(sfptr, remainder, 1, sRB))
				{
					if(ST_FAIL != ST_FileRead(dfptr, remainder, 1, dRB))
					{
						if(0 != memcmp(sRB, dRB, remainder))
						{
							retCode = ST_NOT_IDENTICAL;
						}
						else
						{
							retCode = ST_IDENTICAL;
						}
					}	
				}
			}
			else
			{
				retCode = ST_IDENTICAL;
			}
		}
	}



	free(sRB);
	free(dRB);
if((ST_PASS == ST_FileClose((Ptr *) &sfptr)) && (ST_PASS ==  ST_FileClose((Ptr *) &dfptr)))
		return retCode;
	else
		return ST_FAIL;
}

/***************************************************************************
 * Function		- ST_ReadFromFile
 * Functionality	- Read a file and send buffer
 * Input Params		- fileName
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_ReadFromFile(char * srcfn)
{
	FILE * sfptr = 0;
	Int8 retCode = ST_FAIL;
	Uint32 size = 0;
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
	
	if(ST_FAIL == ST_FileStatus(srcfn, &fstatusInst))
		return ST_FAIL;

	size = fstatusInst.st_size;
	numBlocks = size / unit;
	remainder = size % unit;
	
	if(ST_FAIL == ST_FileOpen(srcfn, "r",(Ptr *)&sfptr))
		return ST_FAIL;
		rB=(Int8 *)malloc(ST_BuffSize);
	if(NULL== rB)
	{
		printTerminalf("ST_ReadFromFile, Mem Alloc of rB failed\n");
		ST_FileClose((Ptr *) &sfptr);
		return ST_FAIL;
	}
	
	if(0 == numBlocks)
	{


		if(ST_FAIL != ST_FileRead(sfptr, size, 1, rB))
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
			if(ST_FAIL != ST_FileRead(sfptr, unit, 1, rB))
			{
#if ENABLE_SUCCESS_PRINTS
				if(!ST_LogFlag)			
					printTerminalf("count=%d\t",cnt);
#endif

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

				if(ST_FAIL != ST_FileRead(sfptr, remainder, 1, rB))
				{
					retCode = ST_PASS;
				}
			}
			else
				retCode = ST_PASS;
		}
	}


	
	
	if(ST_FAIL == ST_FileClose((Ptr *)&sfptr))
	return ST_FAIL;
	
#ifdef PERFROMANCE

	
	sync(); //SYNCING

	gettimeofday(&time,NULL); 
	End_Time=time.tv_sec;
	End_UTime=time.tv_usec;

	if(!ST_LogFlag)
	{
		printf("Buffer Size =%d\n",ST_BuffSize);
		printf("File   Size =%d\n",size);
		printf("Start Time  (Secs) =%ld\n",Start_Time);
		printf("End   Time  (Secs) =%ld\n",End_Time);
		printf("Start Time  (USecs)=%ld\n",Start_UTime);
		printf("End   Time  (USecs)=%ld\n",End_UTime);
	}


	Elapsed_Time=End_Time-Start_Time;
	Elapsed_UTime=(End_UTime-Start_UTime)/1000000.0;
	Elapsed_UTime=(double)(End_Time-Start_Time)+ Elapsed_UTime;
	printf("Read Performance = %lfMBPS\n",((double)size/((Elapsed_UTime)*1048576)));
#endif	

	free(rB);
	return retCode;
}

/***************************************************************************
 * Function		- ST_WriteToFile
 * Functionality	- Writes/Appends a file
 * Input Params		- fileName, number of bytes, flag to indicate write or append
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_WriteToFile(char * fileName, Uint32 size, Uint32 writeFlag)
{
	Int8 retCode = ST_FAIL;
	Int8 openRetCode = ST_FAIL;
	unsigned char fillChar = 0x00;
	unsigned char *	wB = 0;
	Uint32 numBlocks = 0;
	Uint32 remainder = 0;
	Uint32 numTimes;	
	Uint32 MB_Size = ST_BuffSize;
	struct timeval time;
	long Start_Time=0;
	long End_Time=0;
	long Start_UTime=0;
	long End_UTime=0;
	unsigned int i=0;
	//double End_UTime=0.000000;
	//double End_UTime=0.000000;
	double Elapsed_UTime=0.000000;	
	
	FILE * filePtr;


	if(fillChar == 'Z')
		fillChar = 'A';
	fillChar = '9';
	
	if(writeFlag == ST_APPEND)
		openRetCode = ST_FileOpen(fileName, "a",(Ptr *)&filePtr);
	else
		openRetCode = ST_FileOpen(fileName, "w",(Ptr*)&filePtr);
		
		
	if(ST_FAIL == openRetCode)
		return ST_FAIL;
	wB=(Int8 *)malloc(ST_BuffSize);
	if(NULL==wB)
	{
		printTerminalf("ST_WriteToFile, Mem Alloc of wB failed\n");
		ST_FileClose((Ptr *)&filePtr);
		return ST_FAIL;
	}



	//	memset(wB, fillChar,MB_Size); // want to populate data with the same value..

#if 1
	for(i=0;i<ST_BuffSize;i++)
	{
		 if(fillChar<0x100)// 256 max for char data 
	  	//	*(wB+i)=fillChar++;
			*(wB+i) = fillChar;
		else
			fillChar=0x00;//Reset the Data to be filled			
	}
#endif 

	if( size <= MB_Size)
	{	
  				
 			if(ST_FAIL != ST_FileWrite(filePtr, size, gNum_Blk, wB))
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
			Start_Time=(long)time.tv_sec;
			Start_UTime=(long)time.tv_usec;
		}
		else
		     perror("gettimeofday"); 			
#endif
		  for(numTimes = 0;numTimes < numBlocks; numTimes++)
		  {

				if(ST_FAIL != ST_FileWrite(filePtr, MB_Size, 1, wB))
				{
#if ENABLE_SUCCESS_PRINTS
					if(!ST_LogFlag)
				           	printTerminalf("count=%d\t",numTimes);
#endif

					retCode = ST_PASS;

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

					if(ST_FAIL != ST_FileWrite(filePtr, remainder, 1, wB))
					{
						retCode = ST_PASS;
					}
					
				}
		  }

	}
	     


	if(ST_FAIL == ST_FileClose((Ptr *)&filePtr))
	return ST_FAIL;

	sync(); //SYNCING Buffer to block device

	
#ifdef PERFROMANCE


	
	gettimeofday(&time,NULL); 
	End_Time=time.tv_sec;
	End_UTime=time.tv_usec;
	
	if(!ST_LogFlag)
	{
		printf("\nBuffer Size =%d\n",ST_BuffSize);
		printf("File   Size =%d\n",size);
		printf("Start Time  (Secs) =%ld\n",Start_Time);
		printf("End   Time  (Secs) =%ld\n",End_Time);
		printf("Start Time  (USecs)=%ld\n",Start_UTime);
		printf("End   Time  (USecs)=%ld\n",End_UTime);
	}

//Calculations Perfromed
	Elapsed_Time=End_Time-Start_Time;
	Elapsed_UTime=((double)(End_UTime-Start_UTime))/1000000.0;
	Elapsed_UTime=(double)(End_Time-Start_Time)+ Elapsed_UTime;

	printf("Write Perfromance = %lfMBPS\n",((double)size/((Elapsed_UTime)*1048576)));
#endif	

	free(wB);
	return retCode;
}

