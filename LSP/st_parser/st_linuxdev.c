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

/** \file   ST_LinuxDev.c
    \brief  System Test Wrappers for LinuxDev APIs

    This file contains the wrappers for the basic System call APIs.
    
    NOTE: THIS FILE DOES NOT CURRENTLY COVER ALL THE APIs.

    (C) Copyright 2005, Texas Instruments, Inc

    @author      Anand Patil
    @version    0.1 - Created
 */

#include "st_linuxdev.h"

/***************************************************************************
 * Function		- ST_Create
 * Functionality	- Wrapper for creat
 * Input Params		- fileName, mode
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
			- File Descriptor
 * Note			- None
 ****************************************************************************/

Int8
ST_Create(char *fileName, mode_t mode, Int32 *fd) 
{
	(*fd)= creat(fileName, mode);
	
	if((*fd)<0)
	{
		STLog("ST_Create, File %s creation failed\n", fileName);
		ST_LinuxDevErrnum("ST_Create");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_Create, File %s created\n", fileName);
		return ST_PASS;
	}
}
 
/***************************************************************************
 * Function		- ST_Open
 * Functionality	- Wrapper for open
 * Input Params		- fileName, mode
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
			- File Descriptor
 * Note			- None
 ****************************************************************************/
Int8
ST_Open(char * fileName, Int32 flag, Int32 * fd)
{	
 	(*fd) = open(fileName,flag);
		
	if((*fd)<0)
	{
		STLog("ST_Open, File %s open failed\n", fileName);
		ST_LinuxDevErrnum("ST_Open");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_Open, File %s opened with fd= %d\n", fileName, (*fd));
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_Close
 * Functionality	- Wrapper for close
 * Input Params		- File Descriptor
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8
ST_Close(Int32 fd) 
{
	Uint32 retVal = -1;

	retVal = close(fd);

	if(0 != retVal)
	{
		STLog("ST_Close, File close failed for fd=%d Return_Val=%d\n",fd,retVal);
		ST_LinuxDevErrnum("ST_Close");
		return ST_FAIL; 
	}
	else
	{
		STLog("ST_Close, File closed\n");
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_Sync
 * Functionality	- Wrapper for close
 * Input Params		- File Descriptor
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8
ST_Sync(Int32 fd) 
{
	Uint32 retVal = -1;

	retVal = fsync(fd);

	if(0 != retVal)
	{
		STLog("ST_fsync, fsync failed for fd=%d Return_Val=%d\n",fd,retVal);
		ST_LinuxDevErrnum("ST_fsync");
		return ST_FAIL; 
	}
	else
	{
		STLog("ST_fsync, File Synced\n");
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_Read
 * Functionality	- Wrapper fo read
 * Input Params		-  File Descriptor, bytes, num blocks, buffer
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 ST_Read(Int32 fd, Ptr buf, Uint32 count)
{
	Uint32 retVal = -1;
	//char * tempBuff = (char *) (buffer);

	retVal =read(fd,buf,count);
		
	if(count != retVal)
	{
		STLog("ST_Read, File read failed, Num Blocks Read = %x\n", retVal);
		ST_LinuxDevErrnum("ST_Read");
		return ST_FAIL;
	}
	else
	{
//		STLog("ST_Read, Read %d bytes from file\n", retVal);
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_Write
 * Functionality	- Wrapper for write
 * Input Params		-  File Descriptor, bytes, num blocks, buffer
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_Write(Int32 fd, Ptr buf, Uint32 count)
{
	Uint32 retVal = -1;
	
	retVal =write(fd,buf,count);
		
	if(count != retVal)
	{
		
		STLog("ST_Write, File write failed, Num Bytes Written  %d\n", retVal);
		ST_LinuxDevErrnum("ST_Write");
		return ST_FAIL;
	}
	else
	{
		//STLog("ST_Write, Written %d bytes to file\n", retVal);
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_Seek
 * Functionality	- Wrapper for lseek
 * Input Params		-  File Descriptor, offset and seek start position
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_Seek(Int32 fd, Uint32 offset, Uint32 origin) 
{
	Uint32 retVal = -1;
		
	retVal = lseek(fd, offset, origin);
		
	if(0 != retVal)
	{
		STLog("ST_Seek, File seek failed fd=%d Retval=%d\n",fd,retVal);
		ST_LinuxDevErrnum("ST_Seek");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_Seek, File seek done\n");
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_Status
 * Functionality	- Wrapper for stat
 * Input Params		- fileName
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 *  			- file status
 * Note			- None
 ****************************************************************************/
Int8
ST_Status(Int32 fd, LF_STAT * fstatInst)
{
	Uint32 retVal = -1;
       
	retVal = fstat(fd, fstatInst);

	if (0 != retVal)
	{
		STLog("ST_Status, Get File Status for fd=%d failed Retrun_Val=%d\n",fd,retVal);
		ST_LinuxDevErrnum("ST_Status");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_Status, Device : %x\n", fstatInst->st_dev);
		STLog("ST_Status, Inode : %x\n", fstatInst->st_ino);
		STLog("ST_Status, mode  : %x\n", fstatInst->st_mode);
		STLog("ST_Status, number of hard links : %x\n", fstatInst->st_nlink);
		STLog("ST_Status, user ID of owner : %x\n", fstatInst->st_uid);
		STLog("ST_Status, group ID of owner : %x\n", fstatInst->st_gid);
		STLog("ST_Status, device type  : %x\n", fstatInst->st_rdev);		
		STLog("ST_Status, total Size in Bytes : %x\n", fstatInst->st_size);
		STLog("ST_Status,blocksize for filesystem I/O  : %x\n", fstatInst->st_blksize);
		STLog("ST_Status,  number of blocks allocated : %x\n", fstatInst->st_blocks);
		
		return ST_PASS;
	}
}




Int8 ST_Ioctl(Int32 fd, int req, Ptr arg)
{
	Int32 retVal = -1;
       
	retVal = ioctl(fd, req, arg);
	
	if (0 != retVal)
	{
		STLog("ST_Ioctl, Ioctl Status for fd=%d failed, Return_Val=%d\n",fd,retVal);
		ST_LinuxDevErrnum("ST_Ioctl");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_Ioctl, Successfull\n");
		return ST_PASS;
	}
}

