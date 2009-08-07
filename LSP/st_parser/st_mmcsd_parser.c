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
**|         Copyright (c) 1998-2006 Texas Instruments Incorporated           |**
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
/********************************************************************************

   \file   ST_Mmcsd_Parser.c

   \brief  Davinic ARM PSP System Testing Functionalities related to MMC/SD driver
    for Linux OS Support.

 

 \Platform Linux 2.6(MVL)
   

    NOTE: THIS FILE IS PROVIDED FOR INITIAL DEMO RELEASE AND MAY BE

          REMOVED AFTER THE DEMO OR THE CONTENTS OF THIS FILE ARE SUBJECT 

          TO CHANGE. 

 

    (C) Copyright 2005, Texas Instruments, Inc

 

    @author     Anand Patil

    @version    0.1 - Created        03/10/2005

******************************************************************************/





#include "st_mmcsd_parser.h"


/***************************************************************************
 * Function		- mmcsd_parser
 * Functionality	- MMC test functionality Parser
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void mmcsd_parser(void)
{
	int i=0;
	char cmd[CMD_LENGTH];
	char string[CMD_LENGTH]; 	
	char cmdlist[][CMD_LENGTH] = {
									"write", 
									"read",
									"fremove",
									"Set_BufferSize",
									"fwrite",
									"fread",
									"fappend",
									"fcopy",
									"fcompare",
									"Multi_Thread",
									"Multi_Process",
									"mmc_stress",
									"pfmnce",
									"system_call",
									"mount_format",
									"help"
  					};
	




	
	printTerminalf("\n USAGE NOTE BELOW \n");
	printTerminalf("Basic File Operations are in fsapi parser\n");
	printTerminalf("read and write -->  Raw Read And Write Operations\n");
	printTerminalf("fread and fwrite --> File Read And Write Operations\n\n");

	while(1)
	{

	i=0;

        printTerminalf("mmcsd> ");
        scanTerminalf("%s", cmd);

        if(0 == strcmp(cmd, "exit")) 
        {
            printTerminalf("Exiting MMCSD mode to Main Parser: \n");
            break;
        }
	else if(0 == strcmp(cmd, cmdlist[i++]))        
        {
           	 ST_FS_write();
        }
	else if(0 == strcmp(cmd, cmdlist[i++]))        
        {
           	 ST_FS_read();
        }
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
	 	  ST_FS_fremove();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_Set_FSOperation_BuffSize();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_FS_fwrite();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_FS_fread();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_FS_fappend();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_FS_fcopy();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_FS_fcompare();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_BLK_MultiThread_parser();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_BLK_MultiProcess_parser();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_MMC_stress();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_BLK_Linuxfile_Pfmnce();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		printTerminalf("Enter the string for system call\n");
		scanTerminalf("%s",&string);
		printTerminalf("Entered string is  the string for system call\n");		
		ST_System(string);
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_MMC_MountFormat();
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

}


/***************************************************************************
 * Function		- ST_MMC_MountFormat
 * Functionality	- A fast step function to  format with ext2 fs and mount on /mmc for 
 				  mmc cards ( used for automation purpose)
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
	void ST_MMC_MountFormat(void)
	{
#if 0
	
		if (ST_PASS==ST_System("mke2fs /dev/mmcblk0"))
		{
			if(ST_PASS==ST_System("mount /dev/mmcblk0 /mmc/"))
				printTerminalf("ST_MMC_MountFormat: Completed successfully\n");
			else
				printTerminalf("ST_MMC_MountFormat: Failed\n");
		}
		else
			printTerminalf("ST_MMC_MountFormat: Failed\n");			


#endif

#if 1
		char c;

		printTerminalf("ST_MMC_MountFormat:Enter the char to be tested\n");		
		scanTerminalf("%c\n",&c );

		switch (c)
		{
			case 'a' : 		
					printTerminalf("CASE 'A' HIT\n");	
					break;
			case 'b' :
					printTerminalf("CASE 'B' HIT\n");
					break;
			default	:	
					printTerminalf("CASE 'DEFAULT' HIT\n");	
		}

#endif 		
	}
	

/***************************************************************************
 * Function		- ST_MMC_stress
 * Functionality	- MMC Stress test Interface functionality
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
	void ST_MMC_stress(void)
	{
		long long do_hdd;
		long long do_hdd_bytes;
		long long do_timeout;
		long long do_io;
		int RetVal;
		char Mnt_point[20];
			
			printTerminalf("Enter:\n 1.No.Of Processes\n 2. Size of File in Bytes\n 3.Timeout in Secs\n 4.No.of Sync Processes\n 5.Mount Point(Absoulte Path)\n ST_MMC_stress >");
			scanTerminalf("%d %d %d %d %s\n",&do_hdd,&do_hdd_bytes,&do_timeout,&do_io, &Mnt_point);
		//	RetVal=ST_Davinci_ATA_stress(do_hdd,do_hdd_bytes,do_timeout,do_io);
			RetVal=ST_Davinci_stress(do_hdd,do_hdd_bytes,do_timeout,do_io,Mnt_point);
			if(RetVal!=0)
			printTerminalf("Stress Test Failed\n");
			else
			printTerminalf("Stress Test Successful\n");				
		
	}

