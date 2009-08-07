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

/** \file   ST_LinuxFile.h
    \brief  System Test wrappers for LinuxFile APIs

    This file contains the declarations for LinuxFile APIs

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Anand PAtil 
    @version    0.1
                
**/

#ifndef _ST_LinuxFILE_
#define _ST_LinuxFILE_

#include "st_common.h"
#include "st_types.h"
#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/mount.h>
#include <fcntl.h>

#ifndef _LF_STAT_
#define  _LF_STAT_
typedef  struct stat LF_STAT;
#endif 

Int8 ST_FileOpen(char * fileName, char * mode, Ptr * filePtr);
Int8 ST_FileClose(Ptr * filePtr);
Int8 ST_FileRead(Ptr filePtr, Uint32 bytes, Uint32 numBlocks, Ptr buffer);
Int8 ST_FileWrite(Ptr filePtr, Uint32 bytes, Uint32 numBlocks, Ptr buffer);
Int8 ST_FileStatus(char * fileName, LF_STAT * fstatInst);
Int8 ST_FileErrnum(Ptr fp);
Int8 ST_FileSeek(Ptr filePtr, Uint32 offset, Uint32 origin);
Int8 ST_FileRemove(char * fileName);
Int8 ST_FileRename(char * oldfileName, char * newfileName);
Int8 ST_DirCreate(char * dirName,mode_t mode);
Int8 ST_DirRemove(char * dirName);
Int8 ST_DirChange(char * dirName);
Int8 ST_DirChangeMode(char * dirName, Int32 mode);
Int8 ST_FileChangeMode(char * fileName, mode_t mode);
Int32 ST_FileEOF(Ptr filePtr);
Int8 ST_Drvmount(const char *source, const char *target, const char *filesystemtype, Uint32 mountflags, Ptr data);
Int8 ST_Drvumount(const char *target);	
#if 0
Int8 ST_DriveBuffering(char drive, int mode);
Int8 ST_DevInfo(char drive, DEV_INF * devInfo);
Int8 ST_DrvMount(DRV_TBL ** drvTbl);
Int8 ST_SetVol(char drive, char * volName);
Int8 ST_RemoveVol(char drive);
Int8 ST_GetVol(char drive, VOLTAB* voltbl);
#endif
#endif

