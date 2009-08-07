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


/** \file   ST_ATA_Parser.c
    \brief  ATA Test Definitions for DaVinci
    \Platform Linux 2.6 (MVL)

    (C) Copyright 2006, Texas Instruments, Inc

    @author     Anand Patil
                
 */
#include "st_ata_parser.h"
void ST_IOCTLS(void);

void atahdd_parser(void)
{
	int i=0;
	char cmd[CMD_LENGTH];
	char cmdlist[][CMD_LENGTH] = {			
							"read",
							"write",	
							"fread",
							"fwrite",
							"fappend",
							"fcopy",
							"fcompare",
							"getstat",
							"SetAddressMode",
							"GetAddressMode",
							"setbuffsize",
							"Multi_Process",
							"ata_stress",
							"Multi_thread",
							"Performance",
							"hdparm_opmode",
							"ioctls",
							"help"
	};

		printTerminalf("\n USAGE NOTE BELOW \n");
		printTerminalf("Basic File Operations are in fsapi parser\n");
		printTerminalf("read and write -->  Raw Read And Write Operations\n");
		printTerminalf("fread and fwrite --> File Read And Write Operations\n\n");
	do
	{
		i = 0;
		printTerminalf("atahdd>");
		scanTerminalf("%s", cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting ATA HDD Parser\n");
			break;
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
			ST_FS_fread();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_FS_fwrite();
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
			ST_FS_getfstat();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_ATA_SetAdressing();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_ATA_GetAdressing();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_Set_FSOperation_BuffSize();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{	
			 ST_BLK_MultiProcess_parser();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{	
			 ST_ATA_stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{	
			 ST_BLK_MultiThread_parser();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{	
			 ST_BLK_Linuxfile_Pfmnce();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{	
			 ST_ATA_Opmode();
		}		
        else if(0 == strcmp(cmd, cmdlist[i++]))
        {
             ST_IOCTLS();
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
	}while(1);  /* while */

	printTerminalf("");

	return;
}

void ST_IOCTLS(void)
{

int op = 0, fdes = 0, bus_state=0,ch=0, st_ret = 0,args[3];
char dev[30];
long nice_stat=0;
struct hd_geometry disk_geo;
struct hd_driveid dis_iden;
unsigned char snd_cmd_args[4]= {0x0,0x0,0x0,0x0};



printTerminalf ("Enter device file along with path:\n");
scanTerminalf("%s",dev);

printTerminalf ("\nEnter open mode..1->Read Write 2->Read Only\n");
scanTerminalf("%d",&ch);

if(ch==1)
st_ret= ST_Open(dev,O_RDWR,&fdes);
else if(ch==2)
st_ret= ST_Open(dev,O_RDONLY,&fdes);
else
{
printTerminalf("\nIncorrect option\n");
return;
}

if(st_ret!=ST_FAIL)
{

    printTerminalf("\n1. HDIO_GETGEO.\n");
    printTerminalf("\n2. HDIO_GET_IDENTITY.\n");
    printTerminalf("\n3. HDIO_GET_NICE.\n");
    printTerminalf("\n4. HDIO_DRIVE_TASKFILE.(Not yet implemented)\n");
    printTerminalf("\n5. HDIO_DRIVE_CMD.\n");
    printTerminalf("\n6. HDIO_DRIVE_TASK.(Not yet implemented)\n");
    printTerminalf("\n7. HDIO_SCAN_HWIF.\n");
    printTerminalf("\n8. HDIO_UNREGISTER_HWIF.\n");
    printTerminalf("\n9. HDIO_SET_NICE.\n");
    printTerminalf("\n10. HDIO_DRIVE_RESET.\n");
    printTerminalf("\n11. HDIO_GET_BUSSTATE.\n");
    printTerminalf("\n12. HDIO_SET_BUSSTATE.\n");

    printTerminalf("\nEnter option:\n");
    scanTerminalf("%d",&op);

    switch (op)
        {

            case 1:
            {
                if(-1!= ioctl(fdes, HDIO_GETGEO, &disk_geo))
                        {
                            printTerminalf("\nNo of Heads: %d\n",disk_geo.heads);
                            printTerminalf("\nNo of sectors: %d\n",disk_geo.sectors);
                            printTerminalf("\nNo of cylinders: %d\n",disk_geo.cylinders);
                            printTerminalf("\nStart sector: %d\n",disk_geo.start);

                        }
                else
                    {
                    printTerminalf("\nIOCTL FAILED\n");
                    ST_Close(fdes);
                    return;
                    }
            break;
            }

            case 2:
            {
                if(-1!= ioctl(fdes, HDIO_GET_IDENTITY, &dis_iden))
                        {
                            printTerminalf("\nIDENTIFY DEVICE PASSED\n");
                        }
                else
                    {
                    printTerminalf("\nIOCTL FAILED\n");
                    ST_Close(fdes);
                    return;
                    }
            break;
            }

            case 3:
            {
                if(-1!= ioctl(fdes, HDIO_GET_NICE, &nice_stat))
                        {
                            if(nice_stat == 1)
                            printTerminalf("\nNICE status = IDE_NICE_DSC_OVERLAP\n");
                            else if (nice_stat == 2)
                            printTerminalf("\nNICE status = IDE_NICE_ATAPI_OVERLAP\n");
                            else if (nice_stat ==4)
                            printTerminalf("\nNICE status = IDE_NICE_0\n");
                            else if (nice_stat ==8)
                            printTerminalf("\nNICE status = IDE_NICE_1\n");
                            else if (nice_stat ==16)
                            printTerminalf("\nNICE status = IDE_NICE_2\n");

                        }


                else
                    {
                    printTerminalf("\nIOCTL FAILED\n");
                    ST_Close(fdes);
                    return;
                    }

            break;
            }

            case 4:
            {

            break;

            }

            case 5:
            {
                printTerminalf("\n1.Flush Cache\n");
                printTerminalf("\n2.Execute Device diagnostic\n");
                printTerminalf("\n3.Check Power mode\n");
                printTerminalf("\n4.Set to Idle (immediate)\n");
                printTerminalf("\n5.Set to Standby (immediate)\n");
                printTerminalf("\n6.Set to sleep\n");
                printTerminalf("\nEnter option:\n");
                scanTerminalf("%d",&op);

                    if (op == 1)
                        {
                        snd_cmd_args[0] = 0xE7;
                        if(-1!= ioctl(fdes, HDIO_DRIVE_CMD, snd_cmd_args))
                            printTerminalf("\nFlush success\n");                              
                        else
                            {
                            printTerminalf("\nError in flush\n");
                            ST_Close(fdes);
                            return;
                            }
                        }
                    else if (op == 2)
                        {
                        snd_cmd_args[0] = 0x90;
                        if(-1!= ioctl(fdes, HDIO_DRIVE_CMD, snd_cmd_args))
                            {
                            printTerminalf("\nIf the code is in Device 0 Error register,\n");
                            printTerminalf("\n0x01->Dev 0 passed, Dev 1 passed or not present.");
                            printTerminalf("\n0x00, 0x02-0x7F->Dev 0 failed, Dev 1 passed or not present.");
                            printTerminalf("\n0x81->Dev 0 passed, Dev 1 failed");
                            printTerminalf("\n0x80, 0x82-0xFF,->Dev 0 failed, Dev 1 failed.\n");
                            printTerminalf("\nIf the code is in Device 1 Error register,\n");
                            printTerminalf("\n0x01->Dev 1 passed.");
                            printTerminalf("\n0x00, 0x02-0x7F->Dev 1 failed.");
                            printTerminalf("\nIOCTL success: Diagnostic code = %x\n", snd_cmd_args[1]);
                            }
                        else
                            {
                            printTerminalf("\nError in Device Diagnostic\n");                 
                            ST_Close(fdes);
                            return;
                            }
                        }
                    else if (op == 3)
                        {
                        snd_cmd_args[0] = 0xE5;
                        if(-1!= ioctl(fdes, HDIO_DRIVE_CMD, snd_cmd_args))
                            {
                            printTerminalf("\n0x00->Standby mode\n0x80-> Sleep mode\n 0xFF->device in Active or Idle mode\n");
                            printTerminalf("\nIOCTL success: Power mode = %x\n", snd_cmd_args[2]);
                            }
                        else
                            {
                            printTerminalf("\nError in get power mode\n");
                            ST_Close(fdes);
                            return;
                            }
                        }

                    else if (op == 4)
                        {
                        snd_cmd_args[0] = 0xE1;
                        if(-1!= ioctl(fdes, HDIO_DRIVE_CMD, snd_cmd_args))
                            printTerminalf("\nSet to idle mode success\n");                   
                        else
                            {
                            printTerminalf("\nError in Set to idle mode\n");
                            ST_Close(fdes);
                            return;
                            }
                        }

                    else if  (op == 5)
                        {
                        snd_cmd_args[0] = 0xE0;
                        if(-1!= ioctl(fdes, HDIO_DRIVE_CMD, snd_cmd_args))
                            printTerminalf("\nSet to standby mode success\n");                
                        else
                            {
                            printTerminalf("\nError in Set to standby mode\n");
                            ST_Close(fdes);
                            return;
                            }
                        }
                    else if (op ==6)
                        {
                        snd_cmd_args[0] = 0xE6;
                        if(-1!= ioctl(fdes, HDIO_DRIVE_CMD, snd_cmd_args))
                            printTerminalf("\nSet to sleep mode success\n");                  
                        else
                            {
                            printTerminalf("\nError in Set to sleep mode\n");
                            ST_Close(fdes);
                            return;
                            }
                        }
                    break;
                }

                case 6:
                {
                    break;
                }

                case 7:
                {

                args[0] = 0x1f0;
                args[1] = 0;
                args[2] = 14;

                     if(-1!= ioctl(fdes, HDIO_SCAN_HWIF,args))
                            printTerminalf("\nScan HWIF success\n");                          
                        else
                            {
                            printTerminalf("\nError in scan HWIF\n");
                            ST_Close(fdes);
                            return;
                            }
                    break;
                }

                case 8:
                {
                     if(-1!= ioctl(fdes, HDIO_UNREGISTER_HWIF, 0))
                            printTerminalf("\nUnregister HWIF success\n");                    
                        else
                            {
                            printTerminalf("\nError in unregister HWIF\n");                   
                            ST_Close(fdes);
                            return;
                            }
                    break;
                }

                case 9:
                {

                    printTerminalf("\nEnter 1 for IDE_NICE_DSC_OVERLAP 2 for IDE_NICE_1\n");
                    scanTerminalf("%d",&op);

                        if (op ==1 )
                        {
                         if(-1!= ioctl(fdes, HDIO_SET_NICE, 1))
                            printTerminalf("\nHDIO_SET_NICE to IDE_NICE_DSC_OVERLAP success\n");
                        else
                            {
                            printTerminalf("\nHDIO_SET_NICE to IDE_NICE_DSC_OVERLAP failed\n");
                            ST_Close(fdes);
                            return;
                            }
                        }

                        if (op==2)
                        {
                        if(-1!= ioctl(fdes, HDIO_SET_NICE,8))
                            printTerminalf("\nHDIO_SET_NICE to IDE_NICE_1 success\n");        
                        else
                            {
                            printTerminalf("\nHDIO_SET_NICE to IDE_NICE_1 failed\n");
                            ST_Close(fdes);
                            return;
                            }

                        }
                    break;

                }

                case 10:
                {
                if(-1!= ioctl(fdes, HDIO_DRIVE_RESET, NULL))
                        {
                            printTerminalf("\nReset Device success\n");
                        }
                else
                    {
                    printTerminalf("\nIOCTL FAILED\n");
                    ST_Close(fdes);
                    return;
                    }
                break;

                }

                case 11:
                {
                if(-1!= ioctl(fdes, HDIO_GET_BUSSTATE, &bus_state))
                        {
                    printTerminalf("\n1-> BUSSTATE_OFF, 2-> BUSSTATE_ON, 3-> BUSSTATE_TRISATE\n");

                            printTerminalf("\nIOCTL success:bus state = %d\n", bus_state);
                        }
                else
                    {
                    printTerminalf("\nIOCTL FAILED\n");
                    ST_Close(fdes);
                    return;
                    }
                break;

                }

                case 12:
                {
                    printTerminalf("\n Enter 1 for BUSSTATE_OFF, 2 for BUSSTATE_ON, 3 for BUSSTATE_TRISATE\n");
                    scanTerminalf("%d",bus_state);
                if(-1!= ioctl(fdes, HDIO_SET_BUSSTATE, bus_state))
                        {
                            printTerminalf("\nIOCTL success:bus state = %d\n", bus_state);
                        }
                else
                    {
                    printTerminalf("\nIOCTL FAILED\n");
                    ST_Close(fdes);
                    return;
                    }
                break;

                }
        }

    }
else
    {
    printTerminalf("\nOpen failed\n");
    return;
    }

ST_Close(fdes);
return;
}



void ST_ATA_stress()
{
	long long do_hdd;
	long long do_hdd_bytes;
	long long do_timeout;
	long long do_io;
	int RetVal;
	char Mnt_point[20];
		
	printTerminalf("Enter:\n 1.No.Of Processes\n 2. Size of File in Bytes\n 3.Timeout in Secs\n 4.No.of Sync Processes\n 5.Mount Point(Absoulte Path)\n ST_ATA_stress >");
	scanTerminalf("%d %d %d %d %s\n",&do_hdd,&do_hdd_bytes,&do_timeout,&do_io, &Mnt_point);
//	RetVal=ST_Davinci_ATA_stress(do_hdd,do_hdd_bytes,do_timeout,do_io);
	RetVal=ST_Davinci_stress(do_hdd,do_hdd_bytes,do_timeout,do_io,Mnt_point);
	if(RetVal!=0)
	printTerminalf("Stress Test Failed\n");
	else
	printTerminalf("Stress Test Successful\n");				
		
}


void ST_ATA_SetAdressing()
{
	int AddrMode;
	
	printTerminalf(" Set LBA Addresing Mode:\n 0->28 Bit LBA \n 1-> 48 Bit LBA \n 2->48 bit capable of 28 Bit also\n ST_ATA_SetAdressing >");
	scanTerminalf("%d", &AddrMode);
		
	if(ST_PASS == ST_ATA_IOCTL(HDIO_SET_ADDRESS,(int *)AddrMode))
		printTerminalf("ST_ATA_SetAdressing, Set Addresing Mode Successful\n");
	else
		printTerminalf("ST_ATA_SetAdressing, Set Addresing Mode Failed\n");
}




void ST_ATA_GetAdressing()
{
	int AddrMode=-1;
	
	//scanTerminalf("%d", &AddrMode);
		
	if(ST_PASS == ST_ATA_IOCTL(HDIO_GET_ADDRESS,(int *)&AddrMode))
	{
		printTerminalf("ST_ATA_SetAdressing, Get Addresing Mode Successful\n AddressingMode= %d\n",AddrMode);\
		switch(AddrMode)
		{
			case 0:
				printTerminalf("AddressingMode Set is 28 Bit LBA\n");
				break;
			case 1:
				printTerminalf("AddressingMode Set is 48 Bit LBA\n");
				break;
			case 2:
				printTerminalf("AddressingMode Set is 48 Bit LBA Capable of 28 Bit LBA\n");
				break;
		}
	}
	else
		printTerminalf("ST_ATA_SetAdressing, Get Addresing Mode Failed\n");
}



void ST_ATA_Opmode(void)
{
	int opmode;
	char hdparm_strng[50]="hdparm -X32 /dev/hda";
	int ret_val=0;
	
	printTerminalf("Enter the OpMode:\nPIO 0..4->8..12 \nDMA 0..2 -> 32..34\nUDMA 0..3->64..67 \n");
	scanTerminalf("%d", &opmode);

	//modify the opmode value at the 9th  place in the string
	itoa(opmode,&hdparm_strng[9]);

	ret_val=ST_System(hdparm_strng);
	
	if(ST_FAIL !=ret_val )
	{
		printTerminalf("ST_ATA_Opmode, Failed\n");
	}
	else
	;
}



int ST_ATA_IOCTL(int req,Ptr arg)
{
	Int32 devfd;
	char drvNm[30];
	
	
	printTerminalf("Enter the Device Name :Ex:- For HardDisk -> /dev/hda\n ST_ATA_IOCTL >");
	scanTerminalf("%s", drvNm);

	if(ST_FAIL!=ST_Open(drvNm,O_RDWR,&devfd))
	{
		if(ST_FAIL!=ST_Ioctl(devfd,req,arg))
		{
			ST_Close(devfd);
			return ST_PASS;
		}
		else
		{
			ST_Close(devfd);
			return ST_FAIL;
		}
		  	
	}	
	else
		return ST_FAIL;
	
		
}


