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

/** \file   ST_PrFile_Parser.c
    \brief  Hibari ARM PSP System Testing Functionalities related to PrFile System.

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Pradeep K
    @version    0.1 - Created	-
                                
 */

#include "st_common.h"
#include "st_automation_io.h"
#include "st_fstests.h"
#include "st_linuxdevio.h"

extern Uint32 ST_BuffSize;
//void ST_Drive_buffer();
void ST_Set_FSOperation_BuffSize();

void fs_parser(void)
{
	int i=0;
	char cmd[CMD_LENGTH];
	char cmdlist[][CMD_LENGTH] = {
							"create",
							"open",
							"close",
							"read",
							"write",
							"seek",
							"fopen",
							"fclose",
							"fread",
							"fwrite",
							"getfstat",
							"mkdir",
							"rmdir",
							"chdir",
							"frename",
							"fseek",
							"fchmod",
							"fremove",
							"fcopy",
							"fappend",
							"fcompare",
							"buffsize",
							"ftruncate",
							"help"
	};
		
	while(1)
	{
		i = 0;
		printTerminalf("fsapi> ");
		scanTerminalf("%s", cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting FSFile Parser\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_create();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_open();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_close();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_read();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_write();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_seek();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fopen();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fclose();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fread();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fwrite();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_getfstat();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_mkdir();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_rmdir();
		}	
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_chdir();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_frename();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fseek();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_chmodeFile();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fremove();
		}	
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fcopy();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fappend();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fcompare();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_Set_FSOperation_BuffSize();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_ftruncate();
		}
		else
		{
			int j=0;
			printTerminalf("Available Functions: \n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf("%s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	} /* while */

	printTerminalf("");

	return;
}





void ST_Set_FSOperation_BuffSize()
{
	Uint32 buffSize = 0;
	
	scanTerminalf("%d", &buffSize);
	
	ST_BuffSize = buffSize;
}


/*


void ST_Drive_buffer()
{
	char drv[2];
	int buffer,option;
        	scanTerminalf("%s", drv);
        	scanTerminalf("%d", &buffer);
			if(buffer)
			{
				option = NWRTSOON;
			}
			else
			{
				option = WRTSOON;
			}

			if(ST_PASS == ST_DriveBuffering(drv[0], option))
			{
				printTerminalf("atahdd_parser, Driver Buffering disable Successful\n");
			}
			else
			{
				printTerminalf("atahdd_parser, Drive Buffering disable Failed\n");
			}




}

*/
