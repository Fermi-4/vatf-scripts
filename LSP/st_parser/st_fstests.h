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

/** \file   ST_FSTests.h
    \brief  Hibari ARM PSP System Testing File System Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Anand Patil
    @version    0.1 - Created 
 */



#ifndef _ST_FSTESTS_H
#define _ST_FSTESTS_H

#include "st_linuxfile.h"
#include "st_linuxdev.h"
#include <sys/time.h>

#define FILE_NAME_LENGTH 200

#define BuffSize       512*50


void ST_FS_create();
void ST_FS_open();
void ST_FS_close();
void ST_FS_read();
void ST_FS_write();
void ST_FS_fopen();
void ST_FS_fclose();
void ST_FS_fread();
void ST_FS_fwrite();
void ST_FS_fcopy();
void ST_FS_fappend();
void ST_FS_fcompare();
void ST_FS_getfstat();
void ST_FS_frename();
void ST_FS_mkdir();
void ST_FS_rmdir();
void ST_FS_chdir();
void ST_FS_chmodeDir();
void ST_FS_chmodeFile();
void ST_FS_fconcat();
void ST_FS_fremove();
void ST_FS_FileEOF();
void ST_FS_FileErrnum();
void ST_FS_ftruncate();
void ST_FS_fseek();
Int8 ST_FileCmp(char * srcfn, char * dstfn);
Int8 ST_FileCopy(char * srcfn, char * dstfn);
Int8 ST_WriteToFile(char * fileName, Uint32 size, Uint32 writeFlag);
Int8 ST_ReadFromFile(char * fileName);
/*
void ST_FS_SetVol();
void ST_FS_RemoveVol();
void ST_FS_GetVol();
void ST_FS_DevInfo();*/


#endif

