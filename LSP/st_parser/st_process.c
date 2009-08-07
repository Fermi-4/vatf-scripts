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
                                                   
/** \file   ST_Process.c
    \brief  System Test Process

    This file contains the process entry point for system test

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Shivanand Pujar, Aniruddha, Anand, Baalaaji
    @version    0.1 	01-Aug-2005	- Created
                
**/
#include <stdio.h>

extern int ST_Parser(void);
extern void ST_Open_UART(void);
char **opts;     /* string array for arguments */

int main(int argc, char **argv)
{
	int i;
	opts = argv;
	for(i=1; i<argc; i++)
	{
		//printf("The arguments passed from main is %s\t", argv[i]);
	}	
	ST_Open_UART(); 
	ST_Parser();

	return 0;
}
