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
* FILE:   		ST_BLK_Dev.h
*
* Brief:  		Declaration of Block Device refrence functions
*
* Platform: 	Linux 2.6
*
* Author: 	Anand Patil
*
*
*Comments:	Integrity of data is applications responsibility.
*			Modify the printfs, scanfs and function calls as per required
*			Change Process creation call as per OS (made as per LINUX)
*			For viewing this file use tab = 4 (se ts =4)
*
********************************************************************************/

/* Include required header files */

void ST_BLK_MultiThread_parser(void);
void ST_BLK_MultiProcess_parser(void);
void ST_BLK_Linuxfile_Pfmnce(void);
int ST_Davinci_stress(long long do_hdd, long long do_hdd_bytes, long long do_timeout, long long do_io, char * mnt_point);
void ST_Set_FSOperation_BuffSize(void);

