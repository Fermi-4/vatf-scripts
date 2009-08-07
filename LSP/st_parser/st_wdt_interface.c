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
**|         Copyright (c) 1998-2004 Texas Instruments Incorporated           |**
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

/** \file   ST_WDT_Interface.c
    \brief  Watch Dog Timer API Wrapper   


  
    (C) Copyright 2006, Texas Instruments, Inc

    @author      Anand Patil
    @version    0.1 - Created
    @date 		10/12/2006
                
 */

#include "st_linuxfile.h"


/***************************************************************************
 * Function		- ST_FileErrnum
 * Functionality	- Wrapper for ferror
 * Input Params		- None
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8
ST_FileErrnum(Ptr fp)
{       
	Int32 errVal = 0;

	errVal = ferror((FILE *)fp); 

	if(-1 == errVal)
	{
		STLog("ST_FileErrnum, Failed\n");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileErrnum, Error No : %x\n", errVal);
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_FileOpen
 * Functionality	- Wrapper for pf_fopen
 * Input Params		- fileName, mode
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
			- file pointer
 * Note			- None
 ****************************************************************************/
Int8
ST_FileOpen(char * fileName, char * mode, Ptr * filePtr) 
{
	(*filePtr) = fopen(fileName,mode);
		
	if(0 == *filePtr)
	{
		STLog("ST_FileOpen, File %s open failed\n", fileName);
		ST_LinuxDevErrnum("ST_FileOpen");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileOpen, File %s opened\n", fileName);
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_FileClose
 * Functionality	- Wrapper for pf_fclose
 * Input Params		- file pointer
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8
ST_FileClose(Ptr * filePtr) 
{
	Uint32 retVal = 0;

	retVal = fclose(*filePtr);

	if(0 != retVal)
	{
		STLog("ST_FileClose, File close failed\n");
		ST_FileErrnum(filePtr);
		ST_LinuxDevErrnum("ST_FileClose");		
		return ST_FAIL; 
	}
	else
	{
		STLog("ST_FileClose, File closed\n");
		return ST_PASS;
	}
}



/***************************************************************************
 * Function		- ST_FileRead
 * Functionality	- Wrapper for pf_fread
 * Input Params		- file pointer, bytes, num blocks, buffer
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8
ST_FileRead(Ptr filePtr, Uint32 bytes, Uint32 numBlocks, Ptr buffer) 
{
	Uint32 retVal = 0;
	char * tempBuff = (char *) (buffer);

	retVal = fread(tempBuff, bytes, numBlocks, filePtr);
		
	if(numBlocks != retVal)
	{
		STLog("ST_FileRead, File read failed, Num Blocks Read = %x\n", retVal);
		ST_FileErrnum(filePtr);
		ST_LinuxDevErrnum("ST_FileRead");		
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileRead, Read %x bytes from file\n", bytes * numBlocks);
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_FileWrite
 * Functionality	- Wrapper for pf_fwrite
 * Input Params		- File Pointer, bytes, num blocks, buffer
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_FileWrite(Ptr filePtr, Uint32 bytes, Uint32 numBlocks, Ptr buffer) 
{
	Uint32 retVal = 0;
	char * tempBuff = (char *) (buffer);
	
	retVal = fwrite(tempBuff, bytes, numBlocks, filePtr);
		
	if(numBlocks != retVal)
	{
		STLog("ST_FileWrite, File write failed, Num Blocks Written = %x\n", retVal);
		ST_FileErrnum(filePtr);
		ST_LinuxDevErrnum("ST_FileWrite");
		
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileWrite, Written %x bytes to file\n", bytes * numBlocks);
		return ST_PASS;
	}
}


/***************************************************************************
 * Function		- ST_FileStatus
 * Functionality	- Wrapper for pf_fstat
 * Input Params		- fileName
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 *  			- file status
 * Note			- None
 ****************************************************************************/
Int8
ST_FileStatus(char * fileName, LF_STAT * fstatInst)
{
	Uint32 retVal = 0;
       
	retVal = stat(fileName, fstatInst);

	if (0 != retVal)
	{
		STLog("ST_FileStatus, Get File Status for %s failed\n", fileName);
		ST_LinuxDevErrnum("ST_FileStatus");
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

/***************************************************************************
 * Function		- ST_FileSeek
 * Functionality	- Wrapper for fseek
 * Input Params		- filePtr, offset and seek start position
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_FileSeek(Ptr filePtr, Uint32 offset, Uint32 origin) 
{
	Uint32 retVal = 0;
		
	retVal = fseek(filePtr, offset, origin);
		
	if(0 != retVal)
	{
		STLog("ST_FileSeek, File seek failed\n");
		ST_FileErrnum(filePtr);
		ST_LinuxDevErrnum("ST_FileSeek");
		
		
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileSeek, File seek done\n");
		return ST_PASS;
	}
}


/***************************************************************************
 * Function		- ST_FileRemove
 * Functionality	- Wrapper for remove
 * Input Params		- fileName
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8
ST_FileRemove(char * fileName)
{
	Uint32 retVal = 0;
       
	retVal = remove(fileName);

	if (0 != retVal)
	{
		STLog("ST_FileRemove, File Remove failed\n");
		ST_LinuxDevErrnum("ST_FileRemove");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileRemove, File Removed\n");
		return ST_PASS;
	}
}


/***************************************************************************
 * Function		- ST_FileRename
 * Functionality	- Wrapper for rename
 * Input Params		- new name, old name
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_FileRename(char * oldfileName, char * newfileName)
{
	Uint32 retVal = 0;
	
	retVal = rename(oldfileName, newfileName);
		
	if(0 != retVal)
	{
		STLog("ST_FileRename, File rename failed\n");
		ST_LinuxDevErrnum("ST_FileRename");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileRename, File renamed\n");
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_DirCreate
 * Functionality	- Wrapper for pf_mkdir
 * Input Params		- directory name
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_DirCreate(char * dirName , mode_t mode)
{
	Uint32 retVal = 0;
	
	retVal = mkdir(dirName, mode);
		
	if(0 != retVal)
	{
		STLog("ST_DirCreate, Directory create failed\n");
		ST_LinuxDevErrnum("ST_DirCreate");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_DirCreate, Directory created\n");
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_DirRemove
 * Functionality	- Wrapper for rmdir
 * Input Params		- directory name
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_DirRemove(char * dirName)
{
	Uint32 retVal = 0;
	
	retVal = rmdir(dirName);
		
	if(0 != retVal)
	{
		STLog("ST_DirRemove, Directory remove failed\n");
		ST_LinuxDevErrnum("ST_DirRemove");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_DirRemove, Directory removed\n");
		return ST_PASS;
	}
}


/***************************************************************************
 * Function		- ST_DirChange
 * Functionality	- Wrapper for chdir
 * Input Params		- directory name
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_DirChange(char * dirName)
{
	Uint32 retVal = 0;
	
	retVal = chdir(dirName);
		
	if(0 != retVal)
	{
		STLog("ST_DirChange, Directory change failed\n");
		ST_LinuxDevErrnum("ST_DirChange");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_DirChange, Directory changed\n");
		return ST_PASS;
	}
}


/***************************************************************************
 * Function		- ST_FileChangeMode
 * Functionality	- Wrapper for chmod
 * Input Params		- directory name, mode
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_FileChangeMode(char * fileName, mode_t mode)
{
	Uint32 retVal = 0;

	
	STLog("ST_FileChangeMode, Mode=%d\r\n",mode);	
	
	retVal = chmod(fileName, mode);
		
	if(0 != retVal)
	{
		STLog("ST_FileChangeMode, File change mode failed\n");
		ST_LinuxDevErrnum("ST_FileChangeMode");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileChangeMode, File mode changed\n");
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_FileEOF
 * Functionality	- Wrapper for feof
 * Input Params		- file pointer
 * Return Value		- Int32, 
 * Note			- None
 ****************************************************************************/
Int32
ST_FileEOF(Ptr filePtr)
{
	Int32 retVal = 0;
	
	retVal = feof(filePtr);

 	return retVal;
}



/***************************************************************************
 * Function		- ST_DrvMount
 * Functionality	- Wrapper for pf_mount
 * Input Params		- DRV_TBL **
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/

Int8
ST_Drvmount(const char *source, const char *target, const char *filesystemtype, Uint32 mountflags, Ptr data)
{
	Uint32 retVal = 0;
       
	retVal =mount(source, target, filesystemtype, mountflags, data);

	if (0 != retVal)
	{
		STLog("ST_DrvMount, Drive mount failed\n");
		ST_LinuxDevErrnum("ST_DrvMount");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_DrvMount, Drive mounted\n");
		return ST_PASS;
	}
}


/***************************************************************************
 * Function		- ST_DrvMount
 * Functionality	- Wrapper for pf_mount
 * Input Params		- DRV_TBL **
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/

Int8 ST_Drvumount(const char *target)
{
	Uint32 retVal = 0;
       
	retVal =umount(target);

	if (0 != retVal)
	{
		STLog("ST_DrvuMount, Drive unmount failed\n");
		ST_LinuxDevErrnum("ST_DrvuMount");
		return ST_FAIL;
	}
	else
	{
		STLog("ST_DrvuMount, Drive unmounted\n");
		return ST_PASS;
	}
}

/***************************************************************************
 * Function		- ST_DriveBuffering
 * Functionality	- Wrapper for pf_buffering
 * Input Params		- Drive, buffering mode
 * Return Value		- Int32
 * Note			- None
 ****************************************************************************/
/*Int8
ST_DriveBuffering(char drive, int mode)
{
	Int32 retVal = 0;
	
	retVal = pf_buffering(drive, mode);

	if(0 != retVal)
	{
		STLog("ST_DriveBuffering, Drive buffering mode set failed\n");
		ST_LinuxDevErrnum();
		return ST_FAIL;
	}
	else
	{
		STLog("ST_DriveBuffering, Drive buffering mode set\n");
		return ST_PASS;
	}
}
*/

/***************************************************************************
 * Function		- ST_DevInfo
 * Functionality	- Wrapper for pf_getdev
 * Input Params		- drv, DEV_INF *
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 *  			- device info
 * Note			- None
 ****************************************************************************/
/*
Int8
ST_DevInfo(char drive, DEV_INF * devInfo)
{
	Uint32 retVal = 0;
       
	retVal = pf_getdev(drive, devInfo);

	if (0 != retVal)
	{
		STLog("ST_DevInfo, Get Device Info failed\n");
		ST_LinuxDevErrnum();
		return ST_FAIL;
	}
	else
	{
		STLog("ST_DevInfo, Got Device Info\n");
		return ST_PASS;
	}
}

*/
/***************************************************************************
 * Function		- ST_DrvMount
 * Functionality	- Wrapper for pf_mount
 * Input Params		- DRV_TBL **
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
/*
Int8
ST_DrvMount(DRV_TBL ** drvTbl)
{
	Uint32 retVal = 0;
       
	retVal = pf_mount(drvTbl);

	if (0 != retVal)
	{
		STLog("ST_DrvMount, Drive mount failed\n");
		ST_LinuxDevErrnum();
		return ST_FAIL;
	}
	else
	{
		STLog("ST_DrvMount, Drive mounted\n");
		return ST_PASS;
	}
}
*/

/***************************************************************************
 * Function		- ST_SetVol
 * Functionality	- Wrapper for pf_setvol
 * Input Params		- drive, volume name
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
/*
Int8
ST_SetVol(char drive, char * volName)
{
	Uint32 retVal = 0;
       
	retVal = pf_setvol(drive, volName);

	if (0 != retVal)
	{
		STLog("ST_SetVol, Set volume failed\n");
		ST_LinuxDevErrnum();
		return ST_FAIL;
	}
	else
	{
		STLog("ST_SetVol, Volume name set\n");
		return ST_PASS;
	}
}
*/

/***************************************************************************
 * Function		- ST_RemoveVol
 * Functionality	- Wrapper for pf_rmvvol
 * Input Params		- drive
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
/*
Int8
ST_RemoveVol(char drive)
{
	Uint32 retVal = 0;
       
	retVal = pf_rmvvol(drive);

	if (0 != retVal)
	{
		STLog("ST_RemoveVol, Remove volume failed\n");
		ST_LinuxDevErrnum();
		return ST_FAIL;
	}
	else
	{
		STLog("ST_RemoveVol, Volume Removed\n");
		return ST_PASS;
	}
}

*/
/***************************************************************************
 * Function		- ST_GetVol
 * Functionality	- Wrapper for pf_getvol
 * Input Params		- drive, VOLTAB* 
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
/*Int8
ST_GetVol(char drive, VOLTAB* voltbl)
{
	Uint32 retVal = 0;
       
	retVal = pf_getvol(drive, voltbl);

	if (0 != retVal)
	{
		STLog("ST_GetVol, Get volume failed\n");
		ST_LinuxDevErrnum();
		return ST_FAIL;
	}
	else
	{
		STLog("ST_GetVol, Volume Information obtained\n");
		return ST_PASS;
	}
}
*/





/***************************************************************************
 * Function		- ST_FileConcat
 * Functionality	- Wrapper for pf_concat
 * Input Params		- source file name, destination file name
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None

****************************************************************************/
/*
Int8 
ST_FileConcat(char * srcfileName, char * dstfileName)
{
	Uint32 retVal = 0;
	
	retVal = pf_fconcat(srcfileName, dstfileName);
		
	if(0 != retVal)
	{
		STLog("ST_FileConcat, File concat failed\n");
		ST_LinuxDevErrnum();
		return ST_FAIL;
	}
	else
	{
		STLog("ST_FileConcat, File concated\n");
		return ST_PASS;
	}
}
*/

