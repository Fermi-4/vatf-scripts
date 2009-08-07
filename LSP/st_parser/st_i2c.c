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

/** \file   ST_I2C.c
    \brief  System Test wrappers for Linux I2C tests

    This file contains the implementation of I2C System Test Interfaces.

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Shivanand Pujar 
    @version    0.1 	09-Aug-2005	- Created
    			0.2		14-Sep-2005	- Added/Modifed the I2C Functionality test codes.
			0.3		17-Oct-2005	- Added MSP Slave device details.                
**/

#include "st_common.h"
#include "st_i2c.h"
#include "st_linuxdevio.h"
#include <signal.h>
#include "sys/time.h"

int read_IR_data_count(void);

//Slave address to be used in Multi-Processing Tasks.
#if defined(DM355) || defined(DM365)
Int32 SlaveAddress = 0x25;
#elif defined(DM644X)
Int32 SlaveAddress = 0x23;
#else
Int32 SlaveAddress = 0x23;
#endif

static Int32 IOmode = 2, Stability = 1, Retries = 2;
static Int32 DataSize = 10, AddrFmt = 0, timeout = -1;

//File descriptor of the I2C dev entry
Int32 ST_I2C_Fd;

//Signal Handler for SIGINT interrupt (linux)
void Handle(int sig)
{
	printf("\n\nThe Signal %d was sent to the Process\n\n", sig);
}

//menu driven program for the features supported by the I2C
//the inputs are received over the UART interface
void i2c_parser(void)
{
	int i=0;
	char cmd[40];
	char cmdlist[][40] = {
				"update",
				"init",
				"term",
				"open",
				"scan",
				"ack",
				"close",
				"ioctl",
				"write",
				"read",
				"readwrite",
				"led",
				"rtc_w",
				"rtc_r",
				"ir_r",
				"ir_a",
				"s_out",
				"g_in",
				"g_eve",
				"loop",	
				"stability",
				"stress",
				"perf",
				"m_fd",
				"m_client",	
				"m_proc",
				"m_thread",
				"one_shot",
				"codec",
				"codec_read",
				"codec_oneshot",
        "test_mxp430",
				"help"
	};

	signal(SIGINT, Handle);
	while(1)
	{
		i = 0;
		printTerminalf("\ni2c> ");
		scanTerminalf("%s", cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting I2C mode to Main Parser: \n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_i2c_driver_update();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Init();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Terminate();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Open();
		} 
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Scan_Test();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Ack_Test();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Close();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Ioctl();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_EEPROM_Write();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_EEPROM_Read();
		}	
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_EEPROM_WriteRead();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_LED_WriteRead();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_MSP_RTC_Write(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{		
			ST_I2C_MSP_RTC_Read();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_MSP_IR_ReadRecent(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{		
			ST_I2C_MSP_IR_ReadAll();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_MSP_IR_SetOutputStatus(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{		
			ST_I2C_MSP_IR_GetInputStatus();
		}		
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_MSP_IR_GetEventStatus(); 
		}		
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_LoopBack(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{		
			ST_I2C_Stability();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Performance(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{		
			ST_I2C_Max_Fd();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_MultipleSlave_Test(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_MultiProcess_parser(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_MultiThread_parser(); 
		}	
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_OneStop_Test(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Codec_WriteRead(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Codec_Read(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_I2C_Codec_One_Shot(); 
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_Test_MXP430(); 
		}
		else 
		{
			int j=0;
			printTerminalf("Available I2C Functions: \n");
//			printTerminalf("cmdlist[%d] is : %s\n", j, cmdlist[j]);
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf("%s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	} // while 

	printTerminalf("");

	return;
}


//Global variables that will used across the modules.
//menu driven for setting the appropriate values.

void test_i2c_driver_update(void)
{
	Int32 j=0;
	char cmd[40];
	char cmdlist[][40] = {
				"iomode",
				"config",
				"datasize",
				"stability",
				"addrfmt",
				"timeout",
				"retry",				
				"help"
	};
	
//	while(1)
	{
		printTerminalf("Enter Update Parameter\ni2c::update> ");
		scanTerminalf("%s", cmd);
	
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting Update Parser: \n");
			//break; 
			return;
		}
		else if(0 == strcmp(cmd, cmdlist[j++])) 
		{
			test_i2c_update_Init_Opmode();
		}
		else if(0 == strcmp(cmd, cmdlist[j++])) 
		{
			test_i2c_update_Channel_Config();
		} 
		else if(0 == strcmp(cmd, cmdlist[j++])) 
		{
			test_i2c_update_ReadWrite_DataSize();
		}
		else if(0 == strcmp(cmd, cmdlist[j++]))
		{
			test_i2c_update_Stability();
		}
		else if(0 == strcmp(cmd, cmdlist[j++]))
		{
			test_i2c_update_AddressFormat();
		}
		else if(0 == strcmp(cmd, cmdlist[j++]))
		{
			test_i2c_update_Timeout();
		}
		else if(0 == strcmp(cmd, cmdlist[j++]))
		{
			test_i2c_update_Retry();
		}
		else 
		{
			Int32 i=0;
			printTerminalf("Available I2C Functions: \n");
			while(strcmp("help", cmdlist[i]))
			{
				printTerminalf("%s\n", cmdlist[i]);
				i++;
			}
			printTerminalf("\n");
		}
	}// End of while
	return;
}

//The "mode" of the file that will be accessed from the User-space application.
void test_i2c_update_Init_Opmode(void)
{
	printTerminalf("Enter the Opmode [0=RDONLY  1=WRONLY  2=RDWR ].\nI2C>>");
	scanTerminalf("%d", &IOmode);
	printTerminalf("Update Successful\n");
	return;
}

//Channel Configuration settings - Slave devices on the Bus.
void test_i2c_update_Channel_Config(void)
{
	Int32 Address;
	printTerminalf("Enter the Slave address[ 0=Loopback 1=EEPROM 2=LED 3=AIC23 4=IR 5=RTC 6=Set Out-Stat 7=Get IN-Stat 8=Get Event] :\t");
	scanTerminalf("%d", &Address);
	switch(Address)
	{
		case 0:
				SlaveAddress = I2C_OWN_ADDRESS ;
			break;
		case 1:
				SlaveAddress = I2C_EEPROM;
			break;
		case 2:
				SlaveAddress = I2C_MSP_ADDR;
			break;
		case 3:
				SlaveAddress = I2C_CODEC ;
			break;
		case 4:
		case 5:
		case 6:
		case 7:
				SlaveAddress = I2C_MSP_ADDR;
			break;				
		default:
				SlaveAddress = I2C_MSP_ADDR;
			break;				
	}
			
	printTerminalf("Update Successful. Slave Address is set to %x\n", SlaveAddress);
	return;	
}

//The Data size for IO transaction.
void test_i2c_update_ReadWrite_DataSize(void)
{
	printTerminalf("Enter the Size of data to be Written and read:\t");
	scanTerminalf("%d", &DataSize);
	printf("Datasize is %d\n", DataSize);
	if( DataSize > MAX_I2C_DATASIZE )
	{
		printTerminalf("Please enter the datasize less than %d\n", MAX_I2C_DATASIZE);
		DataSize = 1;
	}
	printTerminalf("Update Successful\n");
}

//The stability count - the loop count. The stability tests would be run for 'loop' number of times
void test_i2c_update_Stability(void)
{
	printTerminalf("Enter the Count value: ");
	scanTerminalf("%d", &Stability);	
	printTerminalf("Update Successful\n");
}

//The Slave devices Address format.
//May NOT be applicable in Linux context.
void test_i2c_update_AddressFormat(void)
{
	Int32 Fmt;
	printTerminalf("Enter the option [ 0 = 7-bit / 1 = 10-bit Address Format]:\t");
	scanTerminalf("%d", &Fmt);
	
	if( 0 == Fmt)
		AddrFmt = 0;
	else if( 1 == Fmt)
		AddrFmt = 1;
	else
		AddrFmt = 0;	
		
	printTerminalf("Update Successful\n");		
}

//Timeout configuration for the IO operations.
void test_i2c_update_Timeout(void)
{
	printTerminalf("Enter the option -[ -1 = WAIT_FOREVER\t 0 = NO_WAIT\t >0 Timeout Value]:\t");
	scanTerminalf("%d", &timeout);

	printTerminalf("Update Successful\n");	
}

//Retry configuration for the IO operations.
void test_i2c_update_Retry(void)
{
	printTerminalf("Enter the Count of Retry:\t");
	scanTerminalf("%d", &Retries);

	printTerminalf("Update Successful\n");	
}


//The Node creation - for Process to access the Device Driver.
//major number - 89, minor number 0, character device,
//adapter 0
void ST_I2C_Init(void)
{
//	char *cmd;
	//sprintf(cmd, "mknod %s c 89 0", I2C_DEV);
	//printTerminalf("cmd to mknod is %s", cmd);
	if( -1 == system("mknod /dev/i2c/0 c 89 0"))
//	if( -1 == system(cmd))
		perror("Already created: ");
	else
		printTerminalf("Success: ST_Init: Created the Node.\n");		
	return;
}

//Deleting the Node from the /dev branch.
void ST_I2C_Terminate(void)
{
	if( -1 == system("rm /dev/i2c/0"))
		perror("Issusing the command failed: ");
	else
		printTerminalf("Success: ST_Terminate: Deleted the Node.\n");		
	return;
}

//Opening the file
void ST_I2C_Open(void)
{
	int rtn;
	rtn = ST_Open(I2C_DEV, IOmode, &ST_I2C_Fd);
	if(rtn != ST_PASS)
		printTerminalf("ST_Open: Open Failed\n");
	else
		printTerminalf("Success: ST_Open: Open Success\n");
	return;
}

//Closing the file
void ST_I2C_Close(void)
{
	if(ST_PASS != ST_Close(ST_I2C_Fd))
		printTerminalf("Failed: ST_Close, Close Failed\n");
	else
		printTerminalf("Success: ST_Close: Close Success\n");		

	return;
}

//Scan The devices on the Adapter
void ST_I2C_Scan_Test(void)
{
	Int32 Addr, Found=0, status=0;
	MSG_SET msgset;
	MSG msg;
	
	for(Addr=2; Addr < 128; Addr++)	{
		msg.addr = Addr;	
		msg.flags =0;
		msg.buf = 0;
		msg.len = 0;
		
		msgset.msgs = &msg;
		msgset.nmsgs = 1;
		
		status = ioctl(ST_I2C_Fd, I2C_RDWR, &msgset);
		if( status == 0)	{
			printTerminalf("Found Device at address:\t%d\n", Addr);
			Found++;
		}
		else
			printTerminalf("Device NOT found at location:\t%d and Status is:\t%d\n", Addr, status);
	} //End of for
	
	if( Found > 0)
		printTerminalf("ST_I2C_Scan_Test: Found %d Devices on the adapter\n", Found);
	else
		printTerminalf("No Devices Found\n");
	return;
}

#define I2C_ACK_TEST 0x0710 

//Scan The devices on the Adapter - Using I2C_ACK_TEST 
void ST_I2C_Ack_Test(void)
{
	Int32 Addr, Found=0, status=0;
	
	for(Addr=2; Addr < 128; Addr++)	{
		status = ioctl(ST_I2C_Fd, I2C_ACK_TEST, Addr);
		if( status == 0)	{
			printTerminalf("Found Device at address:\t%d\n", Addr);
			Found++;
		}
		else
			printTerminalf("Device NOT found at location:\t%d and Status is:\t%d\n", Addr, status);
	} //End of for
	
	if( Found > 0)
		printTerminalf("ST_I2C_Scan_Test: Found %d Devices on the adapter\n", Found);
	else
		printTerminalf("No Devices Found\n");
	return;
}

//Reading Data from the Slave devices.
void ST_I2C_EEPROM_Read(void)
{
	char buff[2] = {0x0, 0x0};
	char rBuff[ MAX_I2C_DATASIZE ] = {0x0, };
	int i=0;
//	int startAddr = -1;
	signal(SIGINT, Handle);
	printf("DataSize for read is %d\n", DataSize);	
//	buff[0] = (char)(((++startAddr) & 0xFF00) >> 8);
//	buff[1] = (char)(startAddr & 0xFF);
	printf("DEBUG: ST_I2C_EEPROM_Read\n");
	switch(SlaveAddress)
	{
		case I2C_EEPROM:
		#if 1
			if(ST_PASS != ST_Write(ST_I2C_Fd, buff, 2))
				printTerminalf("ST_Write, Write Failed\n");	
			else
				printTerminalf("ST_Write, Write Passed.\n");	
		#endif
			if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, DataSize))
				printTerminalf("ST_Read, Read EEPROM Failed\n");
			else
				printTerminalf("ST_I2C_EEPROM_Read: EEPROM: Data Read is:\t%s\n", rBuff);
				
		break;	
		
		case I2C_OWN_ADDRESS:
			if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, DataSize))
				printTerminalf("ST_Read, Read Loopback Failed\n");
			else
				printTerminalf("ST_I2C_EEPROM_Read: Loopback: Data Read is:\t%s\n", rBuff);					
		break;	
	} //End of Switch.
#if 1
	printTerminalf("The Data Read is:\t");
	for(i=0; i< DataSize; i++)
		printf("%c",rBuff[i]);	
#endif
	for(i=0; i< DataSize; i++)
		rBuff[i] = 0x0;	
	
	printTerminalf("ST_I2C_EEPROM_Read: Done: Success\n");
	printTerminalf("DEBUG: just before read funciton return\n");
//	return;
}

//Writing Data to the Slave devices on the Bus.
void ST_I2C_EEPROM_Write(void)
{
	char wBuf[ MAX_I2C_DATASIZE ] = {0x0, };
	int i=0;
	signal(SIGINT, Handle);
	printf("DataSize for write is %d\n", DataSize);

//	buff[0] = (char)(((++startAddr) & 0xFF00) >> 8);
//	buff[1] = (char)(startAddr & 0xFF);	
	
	switch(SlaveAddress)
	{
		case I2C_EEPROM:
			for(i= 0; i< DataSize; i++)			
				wBuf[2+i] = 'a'+ (i %26);
			#if 0	
			if(ST_PASS != ST_Write(ST_I2C_Fd, buff, 2))
				printTerminalf("ST_Write, Write Failed\n");			
			else
				printTerminalf("ST_Write: Success: Data Wrote is:\t%d Bytes\n", 2);
			#endif
			
			if(ST_PASS != ST_Write(ST_I2C_Fd, wBuf, DataSize+2))
				printTerminalf("ST_Write, Write Failed\n");			
			else
				printTerminalf("ST_I2C_EEPROM_Write: Success.\n");
		break;
			
		case I2C_OWN_ADDRESS:
			for(i= 0; i< DataSize; i++)
				wBuf[i] = 'A'+ (i %26);
						
			if(ST_PASS != ST_Write(ST_I2C_Fd, wBuf, DataSize))
				printTerminalf("ST_Write, Write Failed\n");				
			else
			{
				printTerminalf("ST_I2C_EEPROM_Write: Success: Loopback: Data Wrote is:\t");
				for(i= 2; i< DataSize+2; i++)
					printf("%c",wBuf[i] );
			}
			printTerminalf("\n");
		break;
	}
	for(i=0; i< DataSize+2; i++)
		wBuf[i] = 0x0;	
	printTerminalf("ST_I2C_EEPROM_Write: Done\n");
	return;
}

//Write-Read test for EEPROM.
void ST_I2C_EEPROM_WriteRead(void)
{
	char wBuf[] = {0x0, 0x0, 'D', 'A', 'V', 'I', 'N', 'C', 'I', 'I', '2', 'C'};
	char rBuf[10] = {0x0, };	
	int i =0;
	char buff[2] = {0x0, 0x0};
	
	if( ioctl( ST_I2C_Fd, I2C_SLAVE, I2C_EEPROM) < 0)
		perror("EEPROM: Ioctl Failed: ");
	else
		printTerminalf("EEPROM: IOCTL Success\n");	

	if( ioctl( ST_I2C_Fd, I2C_TENBIT, 0) < 0)
		perror("Ioctl Failed: ");
	else
		printTerminalf("The Slave address is in 7 bit address format\n");

//	ST_Write(ST_I2C_Fd, buff, 2);						
	
	if(ST_PASS != ST_Write(ST_I2C_Fd, wBuf, sizeof(wBuf)))
		printTerminalf("ST_Write, Write Failed\n");	

	if(ST_PASS == ST_Write(ST_I2C_Fd, buff, 2))
		printTerminalf("ST_Write, Write Successful\n");
	else
		printTerminalf("ST_Write, Write Failed\n");	
	
	if(ST_PASS != ST_Read(ST_I2C_Fd, rBuf, 10))	
		printTerminalf("ST_Read, Read Failed\n");
	else
	{
		printTerminalf("Success: Data Read is:\t");
		for( i=0; i< sizeof(rBuf); i++)
				printf("%c", rBuf[i]);
	}	
	printTerminalf("ST_I2C_EEPROM_WriteRead: Success\n");
	for(i=0; i< sizeof(rBuf); i++)
		rBuf[i] = 0x0;				
			
}

#define Codec_LOOP_COUNT 1 
void 	ST_I2C_Codec_Read(void)
{
	char rData[1] = {0x00};
	char wBuff[2] = {0x00, };
	Int i=0, j=0;
	int aic_slave_addr = I2C_CODEC; //0x1B;
	int reg_num=0, reg_value=0;

    	printTerminalf("Enter the audio codec register number:\n");
	scanTerminalf("%d", &reg_num);

	if(ST_PASS != ioctl(ST_I2C_Fd, I2C_SLAVE, aic_slave_addr))
	{
		printTerminalf("Slave address IOCtl Failed:\n");
		return;
	    }
	else
		printTerminalf("Slave Address set to: %x\n", aic_slave_addr);

	
	for(i=0; i<Codec_LOOP_COUNT; i++)
	{
		wBuff[0] = reg_num;
		if(ST_PASS != ST_Write(ST_I2C_Fd, &wBuff, 1))
		{
			printTerminalf("ST_I2C_Codec_Write: Failed\n");
			break;
		}
		if(ST_PASS != ST_Read(ST_I2C_Fd, &rData, 1))
		{
			printTerminalf("ST_I2C_Codec_Read: Failed\n");
			break;
		}
		else
			printTerminalf("The Codec Read: \t%x\n", rData[0]);

		sleep(1);
	} // End of Inner For
	printTerminalf("ST_I2C_Codec_Read: Done\n");
	return;
}


void 	ST_I2C_Codec_WriteRead(void)
{
	char rData[1] = {0x00};
	char wBuff[2] = {0x00, };
	Int i=0, j=0;
	int aic_slave_addr = I2C_CODEC; //0x1B;
	int reg_num=0, reg_value=0;

    	printTerminalf("Enter the audio codec register number:\n");
	scanTerminalf("%d", &reg_num);
	printTerminalf("Enter the value for the audio codec register:\n");
	scanTerminalf("%d", &reg_value);

	if(ST_PASS != ioctl(ST_I2C_Fd, I2C_SLAVE, aic_slave_addr))
	{
		printTerminalf("Slave address IOCtl Failed:\n");
		return;
	    }
	else
		printTerminalf("Slave Address set to: %x\n", aic_slave_addr);

	
	for(j=0; j< 1; j++)
	{
		for(i=0; i<Codec_LOOP_COUNT; i++)
		{
			wBuff[0] = reg_num & 0xFF; //AIC33 register addr 
			wBuff[1] = reg_value & 0xFF; //AIC33 register value
			if(ST_PASS != ST_Write(ST_I2C_Fd, &wBuff, 2))
			{
				printTerminalf("ST_I2C_Codec_Write: Failed\n");
				break;
			}
			else
			{
				printTerminalf("ST_I2C_Codec_Write: \t%x\n", wBuff[1]);
			}
			
			sleep(1);

			wBuff[0] = reg_num;
			if(ST_PASS != ST_Write(ST_I2C_Fd, &wBuff, 1))
			{
				printTerminalf("ST_I2C_Codec_Write: Failed\n");
				break;
			}
			sleep(1);
			if(ST_PASS != ST_Read(ST_I2C_Fd, &rData, 1))
			{
				printTerminalf("ST_I2C_Codec_Read: Failed\n");
				break;
			}
			else
				printTerminalf("The Codec Read: \t%x\n", rData[0]);

			sleep(1);
		} // End of Inner For
	}// End of Outer For
	printTerminalf("ST_I2C_Codec_WriteRead: Done\n");
	return;
}

void ST_I2C_Codec_One_Shot(void)
{
    char wdata[3] = {0, };
    char rdata[3] = {0, };
	int status = -1;
    Uint32 wrdata[3] = {0, };

	int rlen = 0;
	int wlen = 0;
	int addr = I2C_CODEC; //0x1B;
	Uint32 rd_wr = 0;
	
	MSG_SET OS;
    MSG Msg[2];

	Uint32 i = 0, loopcount = 1;

    struct timeval time;
    Uint32 Start_Time = 0;
    Uint32 Start_sec = 0;

    time.tv_sec = 0;
    time.tv_usec = 0;

    settimeofday(&time,NULL);


    //wargs.nmsgs = 1;
    //rwargs.nmsgs = 1;
    
#if 0
	wargs.msgs = (struct i2c_msg *) malloc(sizeof(struct i2c_msg));
    rargs.msgs = (struct i2c_msg *) malloc(sizeof(struct i2c_msg));

    if ((wargs.msgs || rargs.msgs) == NULL )
    {
        printTerminalf("Malloc failed:\n");
        return;
    }
#endif

//    printTerminalf("Enter the audio codec address:\n");
//    scanTerminalf("%d", &addr);

	if(ST_PASS != ioctl(ST_I2C_Fd, I2C_SLAVE, addr))
	{
		printTerminalf("Slave address IOCtl Failed:\n");
		return;
	    }
	else
		printTerminalf("Slave Address set to: %x\n", addr);

	printTerminalf("Enter 0 to read and 1 to write:\n");
    scanTerminalf("%d", &rd_wr);

#if 0	
	if ((rd_wr != 0) || (rd_wr != 1))
	{
		rd_wr = 0;
	}		
#endif

	Msg[0].addr = (Uint16) addr;
	//Msg[1].addr = Msg[0].addr;

	printTerminalf("Enter the audio codec register number:\n");
    scanTerminalf("%d", &wrdata[0]);
	
	wdata[0] = (char) wrdata[0];

	if (1 == rd_wr)
	{
    	printTerminalf("Enter the value for the audio codec register:\n");
    	scanTerminalf("%d", &wrdata[1]);

		wdata[1] = (char) wrdata[1];
		OS.nmsgs = 1;

	}
    printTerminalf("Enter the bytes length for writing data:\n");
    scanTerminalf("%d", &wlen);
	
	Msg[0].len = (Uint16)wlen;

	if (0 == rd_wr)
	{	
    	printTerminalf("Enter the bytes length for reading data:\n");
    	scanTerminalf("%d", &rlen);

		Msg[1].len = (Uint16) rlen;
		Msg[1].addr = Msg[0].addr;
		OS.nmsgs = 2;
		Msg[1].flags = I2C_M_RD;
		Msg[1].buf = (Uint8 *)rdata;

	}
    Msg[0].flags = 0;
	//    Msg[1].flags = I2C_M_RD;
  //  Msg[0].len = 2;
    Msg[0].buf = (Uint8 *)wdata;
   // Msg[1].len = 2;
    //Msg[1].buf = (Uint8 *)rdata;

	OS.msgs = Msg;

//	printTerminalf("Enter the loop count:");
  //  scanTerminalf("%d", &loopcount);

    /* Enable timer to be added */

    gettimeofday(&time,NULL);

    Start_Time = time.tv_usec;
    Start_sec = time.tv_sec;

    for(i =0; i< loopcount; i++)
    {

		status = ioctl(ST_I2C_Fd, I2C_RDWR , &OS);
		if(0 > status)
    		break;
	}
	/* Disable timer to be added */

    gettimeofday(&time,NULL);


    if(0 > status)
    {
        printf("ST_I2C_Codec_One_Shot: One shot operation Failed, Status = %d\n", status);
		printf("wdata[0]=%x, wdata[1]=%x \n",wdata[0], wdata[1]);
		printf("rdata[0]=%x, rdata[1]=%x \n",rdata[0], rdata[1]);
    }
    else
	{
        printf("ST_I2C_Codec_One_Shot: One shot operation is successful\n");
		printf("wdata[0]=%x, wdata[1]=%x \n",wdata[0], wdata[1]);
		printf("rdata[0]=%x, rdata[1]=%x \n",rdata[0], rdata[1]);
		printTerminalf("ST_I2C_Write:: Timer value for %d bytes - Status = %d: Start time = %dus, End time = %dus\nStart = %ds, End = %ds\n", (4 * loopcount), status, Start_Time, time.tv_usec, Start_sec, time.tv_sec);
        printf("Total secs = %lds, Total usecs = %ldus\n", (time.tv_sec - Start_sec),(time.tv_usec - Start_Time));

	}
    
  printf("This test is done\n");  
  return;

}

//For LED Slave.
#define LED_LOOP_COUNT 10 
void 	ST_I2C_LED_WriteRead(void)
{
#if defined(DM355) || defined(DM365)
	char rData[8] = {0x00, };
	char wBuff[2] = {0x00, };
	Int i=0, j=0;
	for(j=0; j< 1; j++)
	{
		for(i=0; i<LED_LOOP_COUNT; i++)
		{
			wBuff[0] = 0x03;
			wBuff[1] = i;
			if(ST_PASS != ST_Write(ST_I2C_Fd, &wBuff, 2))
			{
				printTerminalf("ST_I2C_LED_Write: Failed\n");
				break;
			}
			
			wBuff[0] = 0x03;
			if(ST_PASS != ST_Write(ST_I2C_Fd, &wBuff, 1))
			{
				printTerminalf("ST_I2C_LED_Write: Failed\n");
				break;
			}
			if(ST_PASS != ST_Read(ST_I2C_Fd, &rData[i], 1))
			{
				printTerminalf("ST_I2C_LED_Read: Failed\n");
				break;
			}
			else
				printf("The LED Read:\t%x\n", rData[i]);

			sleep(1);
		} // End of Inner For
	}// End of Outer For
	printTerminalf("ST_I2C_LED_WriteRead: Done\n");
	return;
#endif
#ifdef DM644X
    char testData[8] = {0x00, };
    char rData[8] = {0x00, };
    Int i=0, j=0;

    for(j=0; j< 1; j++)
    {
        for(i=0; i<sizeof(testData); i++)
        {
            testData[i] = i;
            if(ST_PASS != ST_Write(ST_I2C_Fd, &testData[i], 1))
            {
                printTerminalf("ST_I2C_LED_Write: Failed\n");
                break;
            }
            if(ST_PASS != ST_Read(ST_I2C_Fd, &rData[i], 1))
            {
                printTerminalf("ST_I2C_LED_Read: Failed\n");
                break;
            }
            else
                printf("The LED Read:\t%x\n", rData[i]);

            sleep(1);
        } // End of Inner For
    }// End of Outer For
    printTerminalf("ST_I2C_LED_WriteRead: Done\n");
    return;

#endif
}

//MSP - RTC Read; 
void	ST_I2C_MSP_RTC_Read(void)
{
#if defined(DM355) || defined(DM365)
  	Int i=0, loop=0, tic;
	Uint8 r_buf[1] = {0x0};
	Uint8 buf[1] = {0x0};
	Int r_tic[4] = {0, };

        for(loop=1;loop<5;loop++) {
		buf[0] = 0x12;
		for(i=0; i<4; i++) {

			if(ST_PASS != ST_Write(ST_I2C_Fd, buf, 1))
			{
				printTerminalf("ST_I2C_MSP_RTC_Read: Failed\n");
				return;
			}
			sleep(1);

			//Reading the Actual Data from the Registers.
			if(ST_PASS != ST_Read(ST_I2C_Fd, r_buf, 1))
			{
				printTerminalf("ST_I2C_MSP_RTC_Read: Failed\n");
				return;
			}

			printf("read value from location 0x%x is: %d \n", buf[0], r_buf[0]);
			r_tic[i] = r_buf[0];
		//        sleep(1);

			buf[0]++;
		}

		tic = r_tic[0] | r_tic[1] << 8 | r_tic[2] << 16 | r_tic[3] << 24;
		//sleep(1);
		printf(" the whole tic value is: %d \n", tic);
	}
  printf("This test is done. \n");

	return;

#endif
#ifdef DM644X
    Int i=0;
    Uint8 rBuff[9] = {0x0, };

    Uint8 Buff[2] = {0x0, };
    Uint8 Str[][24] = {
            "Data Length",
            "Command Index",
            "Year - LSB",
            "Year - MSB",
            "Month",
            "Day",
            "Hour",
            "Min",
            "Seconds"
        };

    //Writing the Command to the MSP- RTC
    // Length of Message.
    Buff[0] = 2;
       // Command Index.
    Buff[1] = 1;
    if(ST_PASS != ST_Write(ST_I2C_Fd, Buff, sizeof(Buff)))
    {
        printTerminalf("ST_I2C_MSP_RTC_Read: Failed\n");
        return;
    }
    else
        printTerminalf("Success: ST_I2C_MSP_RTC_Read: Write\n");

    //Reading the Actual Data from the Registers.
    if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, sizeof(rBuff)))
    {
        printTerminalf("ST_I2C_MSP_RTC_Read: Failed\n");
        return;
    }
    else
        printTerminalf("Success: ST_I2C_MSP_RTC_Read: Read\n");

    for(i=0; i< 9; i++)
        printTerminalf("The MSP-RTC Read:\t %s is:\t%d\n", Str[i], rBuff[i]);
    
    printf(" the test is done. \n");
    return;

#endif
}

//MSP - RTC Write
void	ST_I2C_MSP_RTC_Write(void)
{
#if defined(DM355) || defined(DM365)
	Uint8 buf[2];
	Uint8 w_buf[4];
	int i, w_tic=100;

	printTerminalf("\nEnter the tic value:");
	scanTerminalf("%d", &w_tic);

        w_buf[0] = w_tic & 0xff;
	w_buf[1] = (w_tic & 0xff00) >> 8;
	w_buf[2] = (w_tic & 0xff0000) >> 16;
	w_buf[3] = (w_tic & 0xff000000) >> 24;

	buf[0] = 0x12;
	for(i=0;i<4; i++) {
		buf[1] = w_buf[i];
		printf("now write %d to MSP430 with offset 0x%x\n", buf[1], buf[0]);

		if(ST_PASS != ST_Write(ST_I2C_Fd, buf, 2))
		{
			printTerminalf("ST_I2C_MSP_RTC_Write: Failed\n");
			return;
		}
//		sleep(1);
		buf[0]++;
	}
  printf(" the test is done. \n");

#endif
#ifdef DM644X
    Uint8 wBuff[9] = {0x0, };
    Int i=0, Info =0x0;
    Uint8 Str[][14] = {
                "Year - LSB",
            "Year - MSB",
            "Month",
            "Day",
            "Hour",
            "Min",
            "Seconds"
            };
    //Setting the Pre-defined Values to the registers.
    // Message length
    wBuff[0] = 9;
    // Command Index.
    wBuff[1] = 0;

    for(i=0; i<7; i++)
    {
        printTerminalf("\nEnter the ");
        printTerminalf("%s :\t", Str[i]);
        scanTerminalf("%d", &Info);

        wBuff[2 + i] = (char)Info;
    }

    if(ST_PASS != ST_Write(ST_I2C_Fd, wBuff, sizeof(wBuff)))
    {
        printTerminalf("ST_I2C_MSP_RTC_Write: Failed\n");
        return;
    }
    else
        printTerminalf("Success: ST_I2C_MSP_RTC_Write\n");
    
    printf(" the test is done. \n");
    return;
#endif
}

//MSP - Infra-Red Device
//This is a variable length read. Get entire infrared buffer.

int read_IR_data_count(void)
{
	Uint8 rBuff[1] = {0x0}; 
	Uint8 wBuff[1] = {0x0};

#if defined(DM355)
	//Writing the Command to the MSP- IR
	wBuff[0] = 0x16;
#elif defined(DM365)
  wBuff[0] = 0x03;
#endif

	if(ST_PASS != ST_Write(ST_I2C_Fd, wBuff, sizeof(wBuff)))
	{
		printTerminalf("read_IR_data_cont(): Write: Failed\n");
		return ST_FAIL;
	}
//	else
//		printTerminalf("Success: read_data_cont(): Write\n");

	//Reading the Data Count from the Registers.
	if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, 1))
	{
		printTerminalf("read_ir_data_count(): Read: Failed\n");
		return ST_FAIL;
	}
//	else
//		printTerminalf("Success: read_data_cont(): Read\n");
	printTerminalf("The Data Count is: %d\n", rBuff[0]);

	return rBuff[0];
}


#define MSP_IR_READALL 32	
// read all data until DEAD (empty).
void	ST_I2C_MSP_IR_ReadAll(void)
{
#if defined(DM355) || defined(DM365)
  	Int i=0;
	Int dataCnt=0;
	dataCnt = read_IR_data_count();
	for(i=0; i<=dataCnt; i++)
	{
//		sleep(1);
		ST_I2C_MSP_IR_ReadRecent();
//		sleep(1);
	}
  printf(" the test is done. \n");

#endif
#ifdef DM644X
    Int i=0;
    Uint8 rBuff[ MSP_IR_READALL ] = {0x0, }; // Variable length.

    Uint8 Buff[2] = {0x0, };

    //Writing the Command to the MSP- IR
    // Message length
    Buff[0] = 2;
    // Command Index.
    Buff[1] = 2;

    if(ST_PASS != ST_Write(ST_I2C_Fd, Buff, sizeof(Buff)))
    {
        printTerminalf("ST_I2C_MSP_IR_ReadAll: Write: Failed\n");
        return;
    }
    else
        printTerminalf("Success: ST_I2C_MSP_IR_ReadAll: Write\n");

    //Reading the Actual Data from the Registers.
    if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, sizeof(rBuff)))
    {
        printTerminalf("ST_I2C_MSP_IR_ReadAll: Failed\n");
        return;
    }
    else
        printTerminalf("Success: ST_I2C_MSP_IR_ReadAll: Read\n");

    for(i=0; i< sizeof(rBuff); i++)
        printTerminalf("The MSP-IR Read ALL:\t%d\n", rBuff[i]);
  
    printf(" the test is done. \n");
    return;

#endif
}

void ST_Test_MXP430(void)
{
#if defined(DM365)
  Int i=0;
	Uint8 rBuff[1] = {0x0};
	Uint8 wBuff[1] = {0x0};
	Uint8 code[2] = {0x0, };

	//this register should return 0x43       4			The constant 0x43. (for testing purposes)
	wBuff[0] = 0x04;
  
  if(ST_PASS != ST_Write(ST_I2C_Fd, wBuff, sizeof(wBuff)))
    {
    printTerminalf("ST_Test_MXP430: Write: Failed\n");
    return;
  }

//sleep(1);
		//Reading the codes from the Registers.
  if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, 1))
  {
    printTerminalf("ST_Test_MXP430: Failed\n");
    return;
  }

  if (rBuff[0] != 0x43)
  {
    printTerminalf("The read back value from register 4 is not 0x43; MXP430 Test failed\n");
  }
  printf(" The value read from register 4 is %x\n; The test is done. \n", rBuff[0]);

	return;
#endif

}

//MSP - Infra-Red Device
//Get last IR value.
// get last value from register.
void ST_I2C_MSP_IR_ReadRecent(void)
{
#if defined(DM355)
  	Int i=0;
	Uint8 rBuff[1] = {0x0};
	Uint8 wBuff[1] = {0x0};
	Uint8 code[2] = {0x0, };

	read_IR_data_count();
//sleep(1);

	//Reading the code which comes from 2 registers--32bits
	wBuff[0] = 0x17;
	for(i=0; i<2; i++)
	{
		if(ST_PASS != ST_Write(ST_I2C_Fd, wBuff, sizeof(wBuff)))
			{
			printTerminalf("ST_I2C_MSP_IR_ReadRecent: Write: Failed\n");
			return;
		}

//sleep(1);
		//Reading the codes from the Registers.
		if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, 1))
		{
			printTerminalf("ST_I2C_MSP_IR_ReadRecent: Failed\n");
			return;
		}
		code[i] = rBuff[0];
		wBuff[0] += 1;
		//add sleep to try
//		sleep(1);
	}

	//print the codes
	printf("code[0]=%x\n", code[0]);
	printf("code[1]=%x\n", code[1]);
	if (code[0] != 0xDE) code[0] &= ~(1 << 3); //software debounce??
	printTerminalf("The MSP-IR Read Recent: the code is: \t%x\n", (code[1] | code[0] << 8));

	//read datacount again, it should decrement 1
	read_IR_data_count();
  //printf(" the test is done. \n");

	return;
#endif
#if defined(DM365)
  	Int i=0;
	Uint8 rBuff[1] = {0x0};
	Uint8 wBuff[1] = {0x0};
	Uint8 code[2] = {0x0, };

	read_IR_data_count();
//sleep(1);

	//Reading the code which comes from 2 registers--32bits
	wBuff[0] = 0x02;
	for(i=0; i<2; i++)
	{
		if(ST_PASS != ST_Write(ST_I2C_Fd, wBuff, sizeof(wBuff)))
			{
			printTerminalf("ST_I2C_MSP_IR_ReadRecent: Write: Failed\n");
			return;
		}

//sleep(1);
		//Reading the codes from the Registers.
		if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, 1))
		{
			printTerminalf("ST_I2C_MSP_IR_ReadRecent: Failed\n");
			return;
		}
		code[i] = rBuff[0];
		wBuff[0] -= 1;
		//add sleep to try
//		sleep(1);
	}

	//print the codes. code[0] is high byte.
	printf("code[0]=%x\n", code[0]);
	printf("code[1]=%x\n", code[1]);
  
	//if (code[0] != 0xDE) code[0] &= ~(1 << 3); //software debounce??
	if (code[0] != 0x00) code[0] &= ~(1 << 3); //software debounce??
	printTerminalf("The MSP-IR Read Recent: the code is: \t%x\n", (code[1] | code[0] << 8));

	//read datacount again, it should decrement 1
	read_IR_data_count();
  printf(" the test is done. \n");

	return;
#endif

#ifdef DM644X
    Int i=0;
    Uint8 rBuff[4] = {0x0, };

    Uint8 Buff[2] = {0x0, };

    //Writing the Command to the MSP- IR
    // Length of Message.
    Buff[0] = 2;
    // Command Index.
    Buff[1] = 3;

    if(ST_PASS != ST_Write(ST_I2C_Fd, Buff, sizeof(Buff)))
    {
        printTerminalf("ST_I2C_MSP_IR_ReadRecent: Write: Failed\n");
        return;
    }
    else
        printTerminalf("Success: ST_I2C_MSP_IR_ReadRecent: Write\n");

    //Reading the Actual Data from the Registers.
    if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, sizeof(rBuff)))
    {
        printTerminalf("ST_I2C_MSP_IR_ReadRecent: Failed\n");
        return;
    }
    else
        printTerminalf("Success: ST_I2C_MSP_IR_ReadRecent: Read\n");

    for(i=0; i< sizeof(rBuff); i++)
        printTerminalf("The MSP-IR Read Recent:\t%d\n", rBuff[i]);
  
    printf(" the test is done. \n");
    return;

#endif
}


//MSP - Get Port-2 and Port-3 input State.
void	ST_I2C_MSP_IR_GetInputStatus(void)
{
	Uint8 wBuff[9] = {0x0, }, rBuff[4] = {0x0, };
  	Int i=0;

	//Setting the Pre-defined Values to the registers.
	// Length of Message.
	wBuff[0] = 2; 
	// Command index
	wBuff[1] = 2; 

	if(ST_PASS != ST_Write(ST_I2C_Fd, wBuff, sizeof(wBuff)))
	{
		printTerminalf("ST_I2C_MSP_IR_GetInputStatus: Write: Failed\n");
		return;
	}
	else
		printTerminalf("Success: ST_I2C_MSP_IR_GetInputStatus: Write\n");
	
	//Actual - Get operation
	if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, sizeof(rBuff)))
	{
		printTerminalf("ST_I2C_MSP_IR_GetInputStatus: Failed\n");
		return;
	}
	else
		printTerminalf("Success: ST_I2C_MSP_IR_GetInputStatus: Read\n");

	for(i=0; i< sizeof(rBuff); i++)
		printTerminalf("The MSP-Get-Status PORT-2 and PORT-3 Read Recent:\t%d\n", rBuff[i]);

	return;
}

//MSP - Set Port-2 and Port-3 State.
//wBuff[2] = P2 state    ; All bits are ignored
//wBuff[3] = P3 state    ; Bit 0 = SM_CE, Bit 3 = CF_PWR_ON

void	ST_I2C_MSP_IR_SetOutputStatus(void)
{
	Uint8 wBuff[4] = {0x0, };
  	Int i=0;

	//Setting the Pre-defined Values to the registers.
	// Message length
	wBuff[0] = 4; 
	// Command index
	wBuff[1] = 6; 

	if(ST_PASS != ST_Write(ST_I2C_Fd, wBuff, sizeof(wBuff)))
	{
		printTerminalf("ST_I2C_MSP_IR_SetOutputStatus: Write: Failed\n");
		return;
	}
	else
		printTerminalf("Success: ST_I2C_MSP_IR_SetOutputStatus: Write\n");
	
	for(i=0; i< sizeof(wBuff); i++)
		printTerminalf("The MSP-SetOutput Status PORT-2 and PORT-3 wBuff[ %d ] is :\t%d\n", i, wBuff[i]);

	return;
}

// MSP - Get Get outstanding events
void ST_I2C_MSP_IR_GetEventStatus(void)
{
	Uint8 wBuff[9] = {0x0, }, rBuff[4] = {0x0, };
  	Int i=0;

	//Setting the Pre-defined Values to the registers.
	// Message length
	wBuff[0] = 2;
	// Command index
    	wBuff[1] = 5; 

	if(ST_PASS != ST_Write(ST_I2C_Fd, wBuff, sizeof(wBuff)))
	{
		printTerminalf("ST_I2C_MSP_IR_GetEventStatus: Write: Failed\n");
		return;
	}
	else
		printTerminalf("Success: ST_I2C_MSP_IR_GetEventStatus: Write\n");
	
	//Actual - Get operation
	if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, sizeof(rBuff)))
	{
		printTerminalf("ST_I2C_MSP_IR_GetEventStatus: Failed\n");
		return;
	}
	else
		printTerminalf("Success: ST_I2C_MSP_IR_GetEventStatus: Read\n");

	for(i=0; i< sizeof(rBuff); i++)
		printTerminalf("The MSP-Get-Event:\t%d\n", rBuff[i]);

	return;
}


//The Standard IOCTL commands that are supported by I2C.
void ST_I2C_Ioctl(void)
{
	Int32 Option =0;
	
	printTerminalf("Enter the option [ 0 =AddrFmt 1 =Slave Address  2 =Timeout 3 =GetFunctionality 4 =Retries]:\t");
	scanTerminalf("%d", &Option);
	
	printTerminalf("SlaveAddr=%x\n", SlaveAddress);
	switch(Option)
	{
		//Setting Address Format
		case 0: 
				if( ioctl( ST_I2C_Fd, I2C_TENBIT, AddrFmt) < 0)
					perror("Ioctl I2C_TENBIT Failed: ");
				else
					printTerminalf("Success: ST_Ioctl: The Slave address is in %s bit address format\n",((AddrFmt == 0)?"SEVEN":"TEN"));
		break;

		//Setting Slave address.
		case 1:
				if( ioctl( ST_I2C_Fd, I2C_SLAVE, SlaveAddress) < 0)
					perror("ST_Ioctl: I2C_SLAVE: Ioctl Failed: ");
				else
			 		printTerminalf("Success: ST_Ioctl: Slave address is:\t%d\n", SlaveAddress);			
		break;

		//Set timeout - call with int	
		case 2: 
					
				if( ioctl( ST_I2C_Fd, I2C_TIMEOUT, timeout) < 0)
					perror("ST_Ioctl: I2C_TIMEOUT Failed: ");
				else
					printTerminalf("Success: ST_Ioctl: The I2C_TIMEOUT is set to:\t%d\n", timeout);			
		break;
	
		//Get the adapter functionality 	
		case 3:
			{
				Uint32	Funct;
				if( ioctl( ST_I2C_Fd, I2C_FUNCS, &Funct) < 0)
					perror("ST_Ioctl: I2C_FUNCS Failed: ");
				else	{
					printTerminalf("Success: ST_Ioctl: The Functionality is:\t%x\n", Funct);
				}
			}
			
		break;
	
		//Set the Re-Tries count
		case 4:
			{
				if( ioctl( ST_I2C_Fd, I2C_RETRIES, Retries) < 0)
					perror("ST_Ioctl: I2C_RETRIES Failed: ");
				else	{
					printTerminalf("Success: ST_Ioctl: The I2C_RETRIES is:\t%d\n", Retries);
				}
			}
			
		break;		
		default:
				printTerminalf("Supported are:\t AddrFmt\tGetFunctionality\tTimeout\n");
				break;
	}// End of Switch
	
	return;
}

//Driver Loopback mode <PEND>
void ST_I2C_LoopBack(void)
{
	Int32	i=0, j=0;
	Uint8 	bufWrite[] = "t", bufRead[32]={0x0, };
	// Writing Data.
	
	printTerminalf("This is LoopBack Test\n");
	
	for( i=0; i< sizeof(bufWrite); i++)	{
		if(ST_PASS != ST_Write(ST_I2C_Fd,(Ptr)&bufWrite[i], 1))
		{
			printTerminalf("ST_I2C_LoopBack: Write: Failed\n");
		}
		else
			printTerminalf("Success: ST_I2C_LoopBack: Write\n");
		
		for(j=0; j< 500; j++)
			asm("NOP");
		
		if(ST_PASS != ST_Read(ST_I2C_Fd, (Ptr)&bufRead[i], 1))
		{
			printTerminalf("ST_I2C_LoopBack: Read: Failed\n");
		}
		else
			printTerminalf("Success: ST_I2C_LoopBack: Read\n");
		
		for(j=0; j<500; j++)
			asm("NOP");
	} // End of for loop

	printTerminalf("ST_I2C_LoopBack: The Data read is:\t%s\n", bufRead);

	return;
}

//The Driver stability - API and the Data
void ST_I2C_Stability(void)
{
	Uint32 Count =0;
	Uint32 option = 1;
	
	printTerminalf("Enter the Option [ 0 = API Stability; 1 = Data Stability ]:\t");
	scanTerminalf("%d", &option);
	
	switch(option)	{
		//API Stability
		case 0: 
			for(Count =0; Count < Stability; Count++)	{
				if( ioctl( ST_I2C_Fd, I2C_TENBIT, AddrFmt) < 0)
					perror("Ioctl I2C_TENBIT Failed: ");
				else
					printTerminalf("Success: ST_Ioctl: The Slave address is in %s bit address format\n",((AddrFmt == 0)?"SEVEN" : "TEN"));
				if( ioctl( ST_I2C_Fd, I2C_SLAVE, SlaveAddress) < 0)
					perror("ST_Ioctl: I2C_SLAVE: Ioctl Failed: ");
				else
			 		printTerminalf("Success: ST_Ioctl: Slave address is:\t%d\n", SlaveAddress);			
				
				ST_I2C_EEPROM_Write();
				ST_I2C_EEPROM_Read();			
				ST_I2C_Close();
				ST_I2C_Open();
						
				if( DataSize >= MAX_I2C_DATASIZE)
			    		DataSize = 1;
			    	else	
			    		DataSize += INCDATA;
			} 
		break; 
	
		//Data Stability	
		case 1:
		default:
			if( DataSize >= 63 ) //MAX_I2C_DATASIZE
		    		DataSize = 1;
		    	else
		    		DataSize += INCDATA;
		    	ST_I2C_EEPROM_Write();
    			ST_I2C_EEPROM_Read();			    			
		break;
		
	} //End of Switch.
						
	printTerminalf("Stability: Completed\n");
	return;
}

//The Stress test. This will be changed to accept the "time" - 24 Hrs
void ST_I2C_Stress(void)
{
	static int  local_Cnt = 0;
	int Stress_Count = 6000; // Five 9's
	Uint32 i = 0;
	signal(SIGINT, Handle);
	//DataSize = 8;
#if 0
	// Commented this because have issue in executing the Automation.
	// need to invoke the "test_i2c_update_Init_Opmode" Funtion.
	printTerminalf("Enter the IO mode [0 = Read; 1 = Write; 2 = Write-Read]:\t");
	scanTerminalf("%d", &io);
#endif	
	printTerminalf("total count is %d\n", Stress_Count);
	for( i=0; i< Stress_Count; i++)	{
		printTerminalf("Stress_Count=%d\n", i);
		sleep(3);
		DataSize += INCDATA;
		if( DataSize >= MAX_I2C_DATASIZE) //MAX_I2C_DATASIZE
    			DataSize = 1;
		
	    	switch(IOmode)	{
			//Read
	    		case 0:
			       	switch(SlaveAddress)
				{	
					case I2C_EEPROM: ST_I2C_EEPROM_Read(); break;
					case I2C_MSP_ADDR: default: ST_I2C_LED_WriteRead(); break;
				}
					
			    	break;
		    	//Write
	    		case 1:
				switch(SlaveAddress)
				{
					case I2C_EEPROM: ST_I2C_EEPROM_Write(); break;
					case I2C_MSP_ADDR: default: ST_I2C_LED_WriteRead(); break;
				}			       
			    	break;
	    	    	// Write-Read
		    	default:
				switch(SlaveAddress)
				{
					case I2C_EEPROM: 
						{
						int i=0;
						printTerminalf("\n\n\n*************************************************\n\n\n");
						ST_I2C_EEPROM_Write();
						sleep(3);
			    		ST_I2C_EEPROM_Read();
						printTerminalf("\n\n\n*************************************************\n\n\n");

						for(i=0; i< 999999; i++)
							asm("NOP");	
						}
					break;

					case I2C_MSP_ADDR:
						ST_I2C_LED_WriteRead();
						//if( local_Cnt == 0)
						//	ST_I2C_MSP_RTC_Write();
//						local_Cnt ++;
//						ST_I2C_MSP_RTC_Read();
						sleep(1);
					break;

//					case I2C_LED:
					default: 
						ST_I2C_LED_WriteRead();
					break;
				}
	    	} // end of switch					
	} // End of For loop.
	
	printTerminalf("Stress: Completed\n");
	return;	
}			

//The Maximum file open test - Process context.
#define MAX_FD 10	
//#define MAX_FD	1024 * 1

void ST_I2C_Max_Fd(void)
{
	unsigned long int	FD[MAX_FD], i=0;
	Int32 Fd, Temp;
	
	Temp = ST_I2C_Fd;
	
	for(i=0; i< MAX_FD; i++)	{
		if(ST_PASS != ST_Open(I2C_DEV, IOmode, &Fd))	{
			printTerminalf("ST_Open, Open Failed\n");
			printTerminalf("The Count is:\t%d\n", i);
		}
		else	{
			DataSize = 1024;
			FD[i] = Fd;
			ST_I2C_Fd = FD[i];
			printTerminalf("ST_Open: Open Success\n");

				if( ioctl( ST_I2C_Fd, I2C_SLAVE, SlaveAddress) < 0)
					perror("ST_Ioctl: I2C_SLAVE: Ioctl Failed: ");
				else
			 		printTerminalf("Success: ST_Ioctl: Slave address is:\t%d\n", SlaveAddress);			
//			ST_I2C_LED_WriteRead();
			ST_I2C_EEPROM_Write();
			sleep(3);
			ST_I2C_EEPROM_Read();
		}
	}
	
	for(i=0; i< MAX_FD; i++)	
		if(ST_PASS != ST_Close(FD[i]))
			printTerminalf("ST_Close, Close Failed %d\n", FD[i]);
		else
			printTerminalf("ST_Close, Close Success %d\n", FD[i]);		

	printTerminalf("Max Fd completed.\n");
	ST_I2C_Fd = Temp; // Reassigning the Original Fd value.
	return;
}

//Yet to be developed.
void ST_I2C_MultipleSlave_Test(void)
{
	printTerminalf("ST_I2C_MultipleSlave_Test: Do LED and then Read RTC and then LED again\n");
	ST_I2C_LED_WriteRead();
	ST_I2C_MSP_RTC_Read();
	ST_I2C_LED_WriteRead();

	return;
}

//One stop test.
//START - WRITE(DATA) - STOP - START - WRITE(ADDRESS) - RESTART - READ(DATA) - STOP
void ST_I2C_OneStop_Test(void)
{
	char wBuff[MAX_I2C_DATASIZE] = {0x0, };
	char rBuff[MAX_I2C_DATASIZE] = {0x0, };
	int i=0, status = 0xFF;

	MSG_SET OS;
	MSG Msg[2];	
	
	//rBuff[0] = 0x55;
	
	wBuff[0] = 0x03;
	
	Msg[0].addr  = I2C_MSP_ADDR;
	Msg[0].flags = 0;
	Msg[0].len   = 1;
	Msg[0].buf   = wBuff;
	
	Msg[1].addr  = I2C_MSP_ADDR;
	Msg[1].flags = I2C_M_RD;
	Msg[1].len   = 1;
	Msg[1].buf   = rBuff;
	
	OS.msgs = Msg;
	OS.nmsgs = 2;
	
	// status is OS.nmsgs if it is >= 1.
	status = ioctl( ST_I2C_Fd, I2C_RDWR, &OS);
	if( status < 0)
		perror("Ioctl I2C_RDWR Failed: ");
	else
		printTerminalf("Success: ST_Ioctl: I2C_RDWR: Status is:\t%d\n", status);

//	printTerminalf("ST_I2C_OneStop_Test: The Data Read is:\t%c\n",rBuff);	
	for(i= 0; i< 1; i++)	
		printTerminalf("The Data Read is: %x\n", rBuff[i]);
		
	for(i = 0; i< 2; i++)	{
		wBuff[i] = 0x0;
		rBuff[i] = 0x0;	
	}	
	return;
}

//Performance testing for EEPROM.
void ST_I2C_Performance(void)
{
	struct timeval time;
	static Uint32 Counter = 0;
	static Int32 Option =0; 
	Int32 i=0 , j=0;
	char PerfWrite[ 64 + 2] = {0x00,};
	char bufAddr[2] = {0x0,0x0};
   	char PerfRead[64] = {0,};
	volatile Uint32 Strt_Time_ST = 0, End_Time_ST = 0 ;
   	Int32 DataSize [] = {4, 8, 16, 32, 64};
	static char IOmode[8]; // Read or Write

	PerfWrite[0] = 0x00; PerfWrite[1] = 0x00;
		for(i=0; i< 64; i++)
			PerfWrite[2 + i] = 'A'+(i % 26);

	printTerminalf("Enter the IOmode: [0 = Write/ 1 =Read]\nI2C>>\t");
	scanTerminalf("%d",&Option);

	
////////////////////////////////////////////

	if(0 == Option)
		strcpy(IOmode, "WRITE");
	else
		strcpy(IOmode, "READ");


	for(i=0; i< 5; i++)
	{
		switch(Option)
		{
			case 0:	// Write
					Counter = 0;
					gettimeofday(&time,NULL); 
					Strt_Time_ST = time.tv_sec;
					do
					{
						if(ST_PASS != ST_Write(ST_I2C_Fd, PerfWrite, DataSize[i]+2))	{
							printTerminalf("ST_I2C_Performance: ST_Write, Write Failed\n");			
							break;
						}
						Counter++;
						gettimeofday(&time,NULL);
						End_Time_ST = time.tv_sec;
					} 
					while((End_Time_ST - Strt_Time_ST) >= 60);
			break;
					
			case 1:	// Read		
					Counter = 0;	
					gettimeofday(&time,NULL); 
					Strt_Time_ST = time.tv_sec;
					do
					{
						if(ST_PASS != ST_Write(ST_I2C_Fd, bufAddr, 2))	{
							printTerminalf("ST_I2C_Performance: ST_I2C_EEPROM_Read: ST_Write, Write Failed\n");
							break;
						}
						if(ST_PASS != ST_Read(ST_I2C_Fd, PerfRead, DataSize[i]))	{
							printTerminalf("ST_I2C_Performance: ST_Read, Read EEPROM Failed\n");
							break;
						}
						Counter++;
						gettimeofday(&time,NULL);
						End_Time_ST = time.tv_sec;
					}				
					while((End_Time_ST - Strt_Time_ST) >= 60);					
			break;

			default:
				printTerminalf("NOT SUPPORTED IO MODE\n"); 
				break;
		} // End of switch

		printf("IOmode is:\t%s Datasize is:\t%d and Packets Transmitted is:\t%u Time Duration is:\t%u\n", IOmode, DataSize[i], Counter, (End_Time_ST - Strt_Time_ST));
		for(j=0; j< 64; j++)
			PerfRead[j] = 0x0;
	}


////////////////////////////////////////////


//	printf("Opmode is:\t%s. IOmode is:\t%s Datasize is:\t%d and Time is:\t%f\n", OPmode, IOmode, Kdata, BitRate);

	printTerminalf("ST_I2C_Performance: Completed\n");
	return;
}
