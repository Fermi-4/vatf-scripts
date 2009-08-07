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
******************************************************************************
 \file   ST_Nor_Parser.c
    \brief  System Test Definitions for NOR driver Davinci Platform .

  @Platform  Linux 
  
    NOTE: THIS FILE IS PROVIDED FOR INITIAL DEMO RELEASE AND MAY BE
          REMOVED AFTER THE DEMO OR THE CONTENTS OF THIS FILE ARE SUBJECT 
          TO CHANGE. 

    (C) Copyright 2006, Texas Instruments, Inc

    @author    Anand Patil
    @version    0.1 - Created	18/Oct/2006
    @history    Pulled from ST_Nand_Parser.c
******************************************************************************/

#include "st_nor_parser.h"




/***************************************************************************
 * Function		- nor_parser
 * Functionality	- NAND test functionality Parser
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void nor_parser(void)
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
									"nor_stress",
									"pfmnce",
									"system_call",
									"mount_format",
									"nor_ioctl",
									"help"
  					};
	




	
	printTerminalf("\n USAGE NOTE BELOW \n");
	printTerminalf("Basic File Operations are in fsapi parser\n");
	printTerminalf("read and write -->  Raw Read And Write Operations\n");
	printTerminalf("fread and fwrite --> File Read And Write Operations\n\n");

	while(1)
	{

	i=0;

        printTerminalf("nor> ");
        scanTerminalf("%s", cmd);

        if(0 == strcmp(cmd, "exit")) 
        {
            printTerminalf("Exiting NOR mode to Main Parser: \n");
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
		ST_NOR_stress();
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
		ST_NOR_MountFormat();
	}
	else if(0 == strcmp(cmd, cmdlist[i++]))
	{
		ST_NOR_Ioctl();
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
 * Function		- ST_NOR_MountFormat
 * Functionality	- A fast step function to  format with ext2 fs and mount on /mmc for 
 				  mmc cards ( used for automation purpose)
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
	void ST_NOR_MountFormat(void)
	{
		if (ST_PASS==ST_System("flash_eraseall  /dev/mtd0"))
		{
			if(ST_PASS==ST_System("mount -t jffs2 /dev/mtdblock0  /nor/"))
				printTerminalf("ST_NOR_MountFormat: Completed successfully\n");
			else
				printTerminalf("ST_NOR_MountFormat: Failed\n");
		}
		else
			printTerminalf("ST_NOR_MountFormat: Failed\n");			
	}


/***************************************************************************
 * Function		- ST_NOR_Ioctl
 * Functionality	- NOR IOCTL Test user Interface functionality  
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void  ST_NOR_Ioctl(void)
{

	 int status=0;
	 int i=0;
	 int j=0;
	 char fileName[40],cmd[40];
	 int Dev_fd;
	 unsigned int bad_blk;
	 struct hd_geometry geom;
	 struct region_info_user reginf; 
	 struct mtd_info_user mtdinf; 
	 struct nand_oobinfo setoob; 
	  


	printTerminalf("Enter the Device File name and the Command\n");	
	printTerminalf("Command:			Usage\n");
	printTerminalf("dev_geometry:			Gets the Devie CHS Info\n");
	printTerminalf("region_info:			Gets the No.of Blocks, Erase Size..of the MTD Device -> currently Davinci does not support region based Flash\n");		
	printTerminalf("mtd_info:				Gets the Erase Size and OOB Info\n");			
	printTerminalf("get_badblk:			Gets the Bad Blocks Info\n");			
	printTerminalf("\nnand_ioctl> ");	
	scanTerminalf("%s",fileName);	
	scanTerminalf("%s", &cmd);
	

	if(ST_PASS == ST_Open(fileName,O_RDWR, &Dev_fd))
		printTerminalf("ST_open, Device File Open Successful\n");
	else
		{
			printTerminalf("ST_open, Device File Open Failed\n");		
			return 1;
		}


	if(ST_PASS == strcmp(cmd, "dev_geometry")) 
	{
		 if(ST_PASS== ST_Ioctl(Dev_fd,HDIO_GETGEO,&geom))
		{
			printTerminalf("Get Device Geometry Success\n");
			printTerminalf("Device Geometry :- Heads=%d\n Sectors=%d\n Cylinders=%d\n Start_Sect=%d\n ",
				geom.heads ,geom.sectors, geom.cylinders, geom.start);
		}
		else 
			printTerminalf("Get block size Failed %d \n",status);
	}
	else if(ST_PASS == strcmp(cmd, "region_info")) 
	{
		 if(ST_PASS== ST_Ioctl(Dev_fd,MEMGETREGIONINFO,&reginf))
		{
			printTerminalf("Get Region Information Success\n");
			printTerminalf("Region Information :- Region location from the beginning of the MTD=%d\n Erase size for this region=%d\n No.of blocks in this region =%d\n Region Index=%d\n ",reginf.offset ,reginf.erasesize, reginf.numblocks, reginf.regionindex);
		}
		else 
			printTerminalf("Get Region Information Failed %d \n",status);
	}
	else if(ST_PASS == strcmp(cmd, "mtd_info")) 
	{
		 if(ST_PASS== ST_Ioctl(Dev_fd,MEMGETINFO,&mtdinf))


		{
			printTerminalf("Get MTD Information Success\n");
			printTerminalf("MTD Information :- Total size of the MTD=%d\n Erase size =%d\n Amount of OOB data per block=%d\n ",mtdinf.size ,mtdinf.erasesize, mtdinf.oobsize);
		}
		else 
			printTerminalf("Get MTD Information Failed %d \n",status);
	}
	else if(ST_PASS == strcmp(cmd, "set_oob")) 
	{
		 if(ST_PASS== ST_Ioctl(Dev_fd,MEMSETOOBSEL,&setoob))
		{
			printTerminalf("Set OOB Success\n");
			printTerminalf("ECC bytes=%d\n", setoob.eccbytes);
			printTerminalf("Free OOB\n");
			
			for (i=0; i<=15;i++)
			{
				for (j=0;j<=15;j++)
				{
		        	printTerminalf("%d\n",setoob.oobfree[i][j]);
				}	

			}

		}
		else 
			printTerminalf("Set OOB Failed %d \n",status);
	}
        else if(ST_PASS == strcmp(cmd, "get_badblk")) 
	{
		 if(ST_PASS== ST_Ioctl(Dev_fd,MEMGETBADBLOCK,(Uint32*)&bad_blk))
		
			printTerminalf("Get Bad Block information Success %d\n",bad_blk);
		 else 
			printTerminalf("Get Bad Block Information Failed %d \n",status);
	}		 
	else
	{
		printTerminalf("Invalid Function\n");
		
	}
		if(ST_PASS == ST_Close(Dev_fd))
		printTerminalf("ST_Close, Device File Close Successful\n");
		else
		printTerminalf("ST_FS_open, Device File Close Failed\n");


}


/***************************************************************************
 * Function		- ST_NOR_stress
 * Functionality	- NOR stress Test user Interface functionality  
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_NOR_stress(void)
{
	long long do_hdd;
	long long do_hdd_bytes;
	long long do_timeout;
	long long do_io;
	int RetVal;
	char Mnt_point[20];
		
	printTerminalf("Enter:\n 1.No.Of Processes\n 2. Size of File in Bytes\n 3.Timeout in Secs\n 4.No.of Sync Processes\n 5.Mount Point(Absoulte Path)\n ST_NOR_stress >");
	scanTerminalf("%d %d %d %d %s\n",&do_hdd,&do_hdd_bytes,&do_timeout,&do_io, &Mnt_point);
	RetVal=ST_Davinci_stress(do_hdd,do_hdd_bytes,do_timeout,do_io,Mnt_point);
	if(RetVal!=0)
	printTerminalf("Stress Test Failed\n");
	else
	printTerminalf("Stress Test Successful\n");				
		
}



