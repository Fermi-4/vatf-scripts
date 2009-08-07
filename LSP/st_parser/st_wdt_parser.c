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

/** \file   ST_WDT_Parser.c
    \brief  Watch Dog Timer Test Functionalities  for DaVinci on Linux

    (C) Copyright 2006, Texas Instruments, Inc

    @author     Anand Patil
    @version    0.1 
    @date 		10/12/2006
                                
 */

#include "st_wdt_parser.h"

/* Global Variables */

int  				gST_WDT_Handle=-1; //Handle for WDT
unsigned int 		gST_WDT_Timeout=DEFAULT_TIMEOUT; //TimeoutCount
int				gPingTask_usage=0;//Switch to suppress prints when Pinging Task uses the functionality

void WDT_parser(void);

/***************************************************************************
 * Function		- WDT_parser
 * Functionality	- Parser for the Test functionalities supported
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void WDT_parser(void)
{
	int i=0;
	char cmd[CMD_LENGTH];
	char cmdlist[][CMD_LENGTH] = {
							"open",
							"close",
							"seek",
							"WDT_Features",
							"Set_Timeout",
							"Get_Timeout",
							"WDT_Alive",
							"ping_WDT",
							"exit",
							"help"
	};
		
	while(1)
	{
		i = 0;
		printTerminalf("WDT> ");
		scanTerminalf("%s", cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting WDT Parser\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_WDT_Open();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_WDT_Close();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_WDT_Seek();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_WDT_Features();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_WDT_SetTimeout();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_WDT_GetTimeout();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_WDT_Alive_test();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_WDT_PingTask();
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
 * Function		- ST_WDT_Open
 * Functionality	- To Open the WDT Device and get the Handle for it
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_WDT_Open(void)
{
	int attr = O_WRONLY;
	int attr_val = 0;
	int attr1 = O_NONBLOCK;
	char Device_Name[20]="/dev/watchdog";


	printTerminalf("ST_WDT_open: Enter the Device Name\n");
	scanTerminalf("%s", Device_Name);

	printTerminalf("ST_WDT_open: Enter the attribute for open:-  \n0->RDONLY\n1->WRONLY\n2->RDWR\n");
	scanTerminalf("%d", &attr);
	
	printTerminalf("ST_WDT_open: Enter the attribute for open:-\n0->Non-Blocking call\n1->Blocking call\n");
	scanTerminalf("%d", &attr_val);

	switch(attr)
	{
		default:
		case 1 : attr=O_WRONLY;
				break;
		case 0 : attr=O_RDONLY;
				break;
		case 2 :attr=O_RDWR;
				break;
	}
				
	
	if (1 == attr_val)
		attr1 = O_SYNC;
		
	if (ST_PASS!= ST_Open(Device_Name, attr | attr1, &gST_WDT_Handle))
		
		printTerminalf("ST_WDT_open: Failed\n");
	else
		
		printTerminalf("ST_WDT_open:Successfull\n");	
	
}



/***************************************************************************
 * Function		- ST_WDT_Close
 * Functionality	- To Close the WDT Device Handle
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_WDT_Close(void)
{
			
	if(ST_PASS!=ST_Close(gST_WDT_Handle)) 

		printTerminalf("ST_WDT_close: Failed\n");

	else

		printTerminalf("ST_WDT_close:Success\n");	


}


/***************************************************************************
 * Function		- ST_WDT_Features
 * Functionality	- To perform the "WDIOC_GETSUPPORT" get IOCTL supported
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_WDT_Features(void)
{
	struct watchdog_info WDT_info;
	
	if (ST_PASS!=ST_Ioctl(gST_WDT_Handle, WDIOC_GETSUPPORT, &WDT_info))
		
		printTerminalf("ST_WDT_features: Failed\n");
	
	else
		printTerminalf("ST_WDT_features: follow \n WDT Options=%d\n  Firmware =%d\n Identity=%d\n ", WDT_info.options,WDT_info.firmware_version,WDT_info.identity);

}

/***************************************************************************
 * Function		- ST_WDT_SetTimeout
 * Functionality	- To perform the "WDIOC_SETTIMEOUT" set IOCTL supported
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_WDT_SetTimeout(void)
{
	
	printTerminalf("ST_WDT_SetTimeout:Enter the Timeout Value to be set\n ");
	scanTerminalf("%d", &gST_WDT_Timeout);	
	
	if (ST_PASS!=ST_Ioctl(gST_WDT_Handle,WDIOC_SETTIMEOUT, &gST_WDT_Timeout))
		
		printTerminalf("ST_WDT_SetTimeout: Failed\n");
	
	else
		printTerminalf("ST_WDT_SetTimeout:\n Success\n");
	

}

/***************************************************************************
 * Function		- ST_WDT_GetTimeout
 * Functionality	- To perform the "WDIOC_GETTIMEOUT" get IOCTL supported
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_WDT_GetTimeout(void)
{
	unsigned int timeout =0;

	if (ST_PASS!=ST_Ioctl(gST_WDT_Handle,WDIOC_GETTIMEOUT, &timeout))
		
		printTerminalf("ST_WDT_GetTimeout: Failed\n");
	
	else
		printTerminalf("ST_WDT_GetTimeout:Set Timeout value= %d\n", timeout);
	

}

int ST_WDT_Alive_test(void)
{
  int timecount;
  
	printTerminalf("ST_WDT_Alive_test:Enter the Difference Value from Timeout to Ping\nEx:- If value=1 Delay to Ping = Timeout-1\n");
	scanTerminalf("%d", &timecount);
  
  printTerminalf("ST_WDT_Alive_test: sleep %d seconds before pinging WDT.\n", (gST_WDT_Timeout-timecount));
  sleep(gST_WDT_Timeout-timecount);
  if (ST_PASS!=ST_WDT_Alive())
    printTerminalf("ST_WDT_Alive_test: Failed\n");
}

/***************************************************************************
 * Function		- ST_WDT_Alive
 * Functionality	- To perform the "WDIOC_KEEPALIVE" set IOCTL supported
 * Input Params	- None
 * Return Value	- int ST_FAIL or ST_PASS
 * Note			- None
 ****************************************************************************/

int  ST_WDT_Alive(void)
{
	
	if (ST_PASS!=ST_Ioctl(gST_WDT_Handle,WDIOC_KEEPALIVE, NULL))
	{
		printTerminalf("ST_WDT_Alive: Failed\n");
		return ST_FAIL;		
	}
	else
	{
		if(gPingTask_usage==0)
		printTerminalf("ST_WDT_Alive:Success\n");
		return ST_PASS;
	}

}


/***************************************************************************
 * Function		- ST_WDT_Write
 * Functionality	- To perform the Write Operation on the open WDT Device
 * Input Params	- None
 * Return Value	- int ST_FAIL or ST_PASS
 * Note			- None
 ****************************************************************************/

int  ST_WDT_Write(void)
{
	int buf=1;
	
	if (ST_PASS!=ST_Write(gST_WDT_Handle,(Ptr)buf, 1))
	{
		printTerminalf("ST_WDT_Write: Failed\n");
		return ST_FAIL;
	}
	else
	{
		if(gPingTask_usage==0)
		printTerminalf("ST_WDT_Write:Success\n");
		return ST_PASS;
	}

}

/***************************************************************************
 * Function		- ST_WDT_Seek
 * Functionality	- To perform the Write Operation on the open WDT Device
 * Input Params	- None
 * Return Value	- int ST_FAIL or ST_PASS
 * Note			- None
 ****************************************************************************/

int  ST_WDT_Seek(void)
{
	int buf=1;
	
	if (ST_PASS!=ST_Seek(gST_WDT_Handle,(Ptr)0, 0))
	{
		printTerminalf("ST_WDT_Seek: Failed\n");
		return ST_FAIL;
	}
	else
	{
		if(gPingTask_usage==0)
		printTerminalf("ST_WDT_Seek:Success\n");
		return ST_PASS;
	}

}


/***************************************************************************
 * Function		- ST_WDT_PingTask
 * Functionality	- To spawn a Task which performs the WDT pinging activity.
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_WDT_PingTask(void)
{
	int swtch=0;
	unsigned int timecount=0;

	printTerminalf("ST_WDT_PingTask:Enter the \nPing using IOCTL ->0\nPing using Write ->1\n");
	scanTerminalf("%d", &swtch);
	
	printTerminalf("ST_WDT_PingTask:Enter the Difference Value from Timeout to Ping\nEx:- If value=1 Delay to Ping = Timeout-1\n");
	scanTerminalf("%d", &timecount);

		switch(fork())
		{
			case 0 :
					printTerminalf("Task ID %d pings WDT after every %d Seconds\n", getpid(),(gST_WDT_Timeout-timecount));
					Ping_on_WDT(swtch,timecount);
					exit(0);
					break;

			case -1 :
					printTerminalf("ST_WDT_PingTask:Creation Failed\n");
					break;

			default :
					printTerminalf("\n");					
					
		}	

}


/***************************************************************************
 * Function		- Ping_on_WDT
 * Functionality	- To ping WDT ( using Write Operation OR IOCTL) after  the defined interval of time
 * Input Params	-int  swtch,unsigned  count 
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void Ping_on_WDT( int swtch, unsigned int count)
{

	//Switch the Flag to suppress the "success" prints from the functions used.
	gPingTask_usage=0;
	
	switch(swtch)
	{
		default :

		case 0 :
		
				while(1)
				{
			  		sleep(gST_WDT_Timeout-count);
					if (ST_PASS!=ST_WDT_Alive())
						break;
				}
				break;

		case 1 :
				
				while(1)
				{
			  		sleep(gST_WDT_Timeout-count);
					if(ST_PASS!=ST_WDT_Write())
						break;
				}
				break;

	}

}


