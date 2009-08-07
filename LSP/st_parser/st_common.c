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
                                                   
/** \file   ST_Common.c
    \brief  System Test Common File

    This file contains the creation of system test process

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Shivanand Pujar, Aniruddha, Anand, Baalaaji
    @version    0.1 - Created
                
**/
#include "st_common.h"

int ST_main_parser(void)
{
	char buf[CMD_LENGTH];
	usage();
	while(1)
	{
		scanTerminalf("%s", buf);
		printTerminalf("the top input is: %s\n", buf);
		if(0 == strcmp(buf, "exit"))
		{
			printTerminalf("Leaving Validation Simulator\n");
			break;
		}
		else if(0 == strcmp(buf, "atahdd")) 
		{
			atahdd_parser();
			continue;
		}
		else if(0 == strcmp(buf, "uart")) 
		{
			uart_parser();
			continue;
		}
		else if(0 == strcmp(buf, "audio")) 
		{
			audio_parser();
			continue;
		}
		else if(0 == strcmp(buf, "i2c")) 
		{
			i2c_parser();
			continue;
		}
		else if(0 == strcmp(buf, "mmcsd")) 
		{
			mmcsd_parser();
			continue;
		}
		else if(0 == strcmp(buf, "nand")) 
		{
			nand_parser();
			continue;
		}
		else if(0 == strcmp(buf, "nor")) 
		{
			nor_parser();
			continue;
		}		
		else if(0 == strcmp(buf, "fsapi")) 
		{
			fs_parser();
			continue;
		}
		else if(0 == strcmp(buf, "vpfe")) 
		{
			//vpfe_parser();
			continue;
		}
		else if(0 == strcmp(buf, "vpbe")) 
		{
			//vpbe_parser();
			continue;
		}
		else if(0 == strcmp(buf, "system"))
                {
                        initTaskArray();
			ST_EntryPoint();
                        continue;
                }
		else if(0 == strcmp(buf, "WDT"))
                {
			  WDT_parser();
                        continue;
                }
		else if(0 == strcmp(buf, "timer"))
		{
			timer_parser();
			continue;
		}
		else if(0 == strcmp(buf, "pwm"))
                {
			  //pwm_parser();
                        continue;
                }
		else if(0 == strcmp(buf, "shcmd")) 
		{
			char flag =0, cmd[32]= {0x0, };
			char *temp[5], *ptr;
			int i=0, j=0;

			while( 1)
			{
				printTerminalf("sT_Shell #\n");
				gets(cmd);
	
				if( !strcmp(cmd, "exit"))
				{				 
					printTerminalf("Exiting Linux Shell\n");				
					break;
				}
				ptr = cmd;
				for(i=0, j=0, flag = 1; *ptr != '\0'; i++, ptr++)
				{
					if( *ptr == ' ')
					{
						*ptr = '\0';
						flag =1;
					}
					else if(flag ==1)
					{
						temp[ j++] = ptr;
						flag =0;
					}
				}// End of For loop
				temp[j] = NULL;
				switch(fork())
				{
				case 0: // Child Process
					execvp(temp[0], &temp[0]);
					perror("exec failed:\t");
					exit(0);
				default:
					wait(0);
				} // end of switch
			} // End of While
		
			continue;
		}
		else
		{
			usage();
		}
	} /* while */

	return 0;
}

void usage(void) 
{
	printTerminalf("Supported drivers atahdd, uart,audio, i2c, mmcsd, nand, nor,fsapi,WDT, shcmd, system, pwm\n");
	return;
}

// Forking to create the system test entry point
void ST_Parser(void)
{
	switch(fork())	{
	case 0:
		ST_main_parser();
		break;
	default:
		wait(0);
		ST_Close_UART();
		break;
	}
}



/***************************************************************************
 * Function		- ST_LinuxDevErrnum
 * Functionality	- Wrapper for perror
 * Input Params		- None
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/
Int8 
ST_LinuxDevErrnum(char * Fn)
{
	perror(Fn); 
	return ST_PASS;
}

/***************************************************************************
 * Function		- ST_mknod
 * Functionality	- Wrapper for mknod
 * Input Params		- const char *pathname, mode_t mode, dev_t dev
 * Return Value		- Int8, ST_PASS on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/

Int32 ST_mknod(const char *pathname, mode_t mode, dev_t dev)
{
	int ret_val;
	
		ret_val=mknod(pathname, mode,dev);

		if(ret_val<0)
		{
			ST_LinuxDevErrnum("ST_mknod");
			return ST_FAIL;	
		}
		else
			return ST_PASS;				

}


/***************************************************************************
 * Function		- ST_System
 * Functionality	- Wrapper for system
 * Input Params		- char *string
 * Return Value		- Int8, ret_val on success, ST_FAIL otherwise
 * Note			- None
 ****************************************************************************/

int ST_System(char *string)
{
	int ret_val;
	
		ret_val=system(string);

		if(ret_val<0)
		{
			ST_LinuxDevErrnum("ST_System");
			return ST_FAIL;	
		}
		else
			return ret_val;
	

}









//static int ST_fd;


