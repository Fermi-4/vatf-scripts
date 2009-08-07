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

/** \file   ST_UART.c
    \brief  DaVinci ARM Linux PSP System UART Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created - Linux UART Test Code Integration
					- Incorporated the review comments - 20/09/2005
                
 */

#include <errno.h>
#include "st_uart.h"
#include "sys/time.h"
#include <signal.h>

int fd_uart = -1;

struct termios uart_options;

/* Need to take care for Instance 2 after sysinit file is updated */

#if PSP_CONSOLE_UART_NUMBER
	Uint32 st_uart_instance = 1; /* PSP_CONSOLE_UART_NUMBER is set to 0*/
#else
	Uint32 st_uart_instance = 0; /* PSP_CONSOLE_UART_NUMBER UART is 1 */
#endif


//extern Uint32 st_uart_automation_instance;
Uint32 st_uart_automation_instance;
//extern PSP_Handle st_uart_driver[PSP_UART_NUM_INSTANCES];
Uint32 st_uart_driver[PSP_UART_NUM_INSTANCES];

Uint32 instflag[PSP_UART_NUM_INSTANCES] = {0, };

Int32 st_uart_driver_timeout = 0;


Uint32 st_uart_io_reporting = ST_UART_PRINT_IO_REPORTING;

//extern Uint32 davinci_gettimeoffset(void);

char io_status_buffer[100];

void Hand(int s)	{
	printf("This is the Signal Handler and SIGNO is:\t%d\n",s);
}


void uart_parser(void)
{
	char cmd[50] = {0}; 
	int i =0;	
	char cmdlist[][40] = {
		"update",
		"open",
		"gen_open",
		"close",	
		"stability",
		"ioctl",
		"io",
		"help"
	};

	while(1)
	{
		ioctl(st_uart_driver[st_uart_instance], TCGETS, &uart_options);
		i = 0;
		printTerminalf("UART>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting UART mode to Main Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_update();
		} 
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_open();
		}
		else if (0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_general_open();
		}		
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_close();
		}		
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_stability();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			uart_ioctl_parser();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			uart_io_parser();
		}
		else
		{
			int j=0;
		printTerminalf("Invalid Function\n");
			printTerminalf("Available Functions:\n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf(" %s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	} /* while */

	return;
} /* End of uart_parser() */


/* Need to add Loopback after investigation*/

void uart_ioctl_parser(void)
{
	char cmd[50] = {0}; 
	int i =0;	
	char cmdlist[][40] = {
		"set_baud",
		"set_stopbit",
		"set_parity",
		"set_data",
		"set_flowctl",		
		"get_config",
		"exit",
		"help"
	};

	while(1)
	{
		i = 0;
		printTerminalf("UART::IOCtl>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting IOCtl mode to UART Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_set_baud();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_set_stopbit();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_set_parity();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_set_data();
		}	
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_set_flowCtrl();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_get_config();
		}
		else
		{
			int j=0;
			printTerminalf("Invalid Function\n");
			printTerminalf("Available Functions:\n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf(" %s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	} /* while */

	return;
} /* End of uart_ioctl_parser() */

void uart_io_parser(void)
{
	char cmd[50] = {0}; 
	int i =0;	
	char cmdlist[][40] = {
		"print_status",
		"read",
		"write_sync",
		"read_and_write_sync",
		"sync_stress",
		"sync_len_in_stress",
		"sync_stability",
		"perfr115",
		"perf115200",
		"sync_perf9600",
		"sync_perf",
		"sync_variable_write",
		"multi_process",
		"multi_thread",
		"exit",
		"help"
	};

	while(1)
	{
		i = 0;
		signal(SIGINT, Hand);
		printTerminalf("UART::IO>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting UART IO mode to UART Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_io_status();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_read();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_write_sync();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_read_sync_and_write_sync();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_sync_stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_len_in_stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_stability();
		}
	
	
		else if(0 == strcmp(cmd,cmdlist[i++]))
		{
			test_uart_driver_sync_performance_read_115200();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_sync_performance_115200();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
        {
			test_uart_driver_sync_performance_9600();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_sync_performance();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_uart_driver_sync_variable_write();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_Uart_MultiProcess_parser();
		} 
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_Uart_MultiThread_parser();
		}
		else 
		{
			int j=0;
			printTerminalf("Invalid Function\n");
			printTerminalf("Available Functions:\n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf(" %s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	} /* while */

	return;
} /* End of uart_io_parser() */

void test_uart_driver_update(void)
{
	char cmd [CMD_LENGTH];
	char cmdlist[][40] = {
		"instance",
		"ioreporting",
		"automation",
		"timeout",
		"exit",
		"help"
	};
	while(1)
	{
		printTerminalf("Enter Update Parameter\nuart::update> ");
		scanTerminalf("%s", cmd);

		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting UART IO mode to UART Parser:\n");
			break;
		}
		if(0 == strcmp("instance", cmd)) 
		{
			test_uart_update_driver_instance();
			break;
		} 
		else if(0 == strcmp("ioreporting", cmd)) 
		{
			test_uart_update_io_reporting();
			break;
		}
		else if(0 == strcmp("automation", cmd)) 
		{
			test_uart_update_automation_instance();
			break;
		}
		else if(0 == strcmp("timeout", cmd)) 
		{
			test_uart_update_driver_timeout();
			break;
		}
		else 
		{
			int j=0;
			printTerminalf("Invalid Function\n");
			printTerminalf("Available Functions:\n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf(" %s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		//	return;
		}
	}

	printTerminalf("Update Successful\n");
	return;
}




void test_uart_driver_general_open(void)
{
        Int32 attr = 1;
        char dev_name[100] = {0, };     /* Device Name */
        Int8 status = UART_FAILURE;

        printTerminalf("test_uart_driver_general_open: Enter the device to open (/dev/ttyS0)\n");
        scanTerminalf("%s", &dev_name);

        printTerminalf("test_uart_driver_general_open: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
        scanTerminalf("%d", &attr);

        //if (0 == st_uart_instance)
        //{
                /* Check device open */

          //      if (0 == instflag[st_uart_instance])
          //      {
                        fd_uart = open(dev_name, attr | O_NOCTTY);
                        instflag[st_uart_instance] =1;
          //      }
          //      else
          //      	fd_uart = UART_NULL;
        //}

        //else
        //{
        //        printTerminalf("test_uart_driver_general_open: Invalid instance\n");
        //}

        if( fd_uart >= UART_SUCCESS)
        {
                st_uart_driver[st_uart_instance] = fd_uart;
                printTerminalf("test_uart_driver_general_open: Success:: Device = %s, fd=%d\n", dev_name,fd_uart);
        }
        else
        {
                printTerminalf("test_uart_driver_general_open: Failed:: Device = %s, fd=-%d, status=%d\n", dev_name, errno, status);
        }
}



void test_uart_update_driver_instance(void)
{
	Int32 local_instance = 0;
	

	printTerminalf("test_uart_update_driver_instance: Enter the Interface Number (0,1, 2)\nuart::update> ");
	scanTerminalf("%d", &local_instance);
	
	if(st_uart_instance < PSP_UART_NUM_INSTANCES)
	{
		st_uart_instance = local_instance;
		printTerminalf("test_uart_update_driver_instance: Setting st_uart_instance to %d\n", st_uart_instance);
	}
	else 
	{
		printTerminalf("test_uart_update_driver_instance: Invalid Instance Number");
	}

	return;
}

void test_uart_update_io_reporting()
{
	char type[10];

	printTerminalf("test_uart_update_io_reporting: Enter the Reporting Type(print/store)\nuart::update> ");
	scanTerminalf("%s", type);

	if(0 == strcmp(type, "print"))
	{
		st_uart_io_reporting = ST_UART_PRINT_IO_REPORTING;
		printTerminalf("test_uart_update_io_reporting: Setting st_uart_io_reporting to ST_UART_PRINT_IO_REPORTING\n");
	}
	else 
	{
		st_uart_io_reporting = ST_UART_STORE_IO_REPORTING;
		printTerminalf("test_uart_update_io_reporting: Setting st_uart_io_reporting to ST_UART_STORE_IO_REPORTING\n");
	}

	return;
}

void test_uart_driver_io_status(void)
{
	printTerminalf("%s\n", io_status_buffer);
}

void test_uart_update_automation_instance(void)
{
	Int32 local_autoinstance;

	printTerminalf("test_uart_update_automation_instance: Enter the Interface Number (0,1)\nuart::update> ");
	scanTerminalf("%d", &local_autoinstance);
	
	if(local_autoinstance < PSP_UART_NUM_INSTANCES)
	{
		st_uart_automation_instance = local_autoinstance;
		printTerminalf("test_uart_update_automation_instance: Setting st_uart_automation_instance to %d\n", st_uart_automation_instance);
	}
	else 
	{
		printTerminalf("test_uart_update_automation_instance: Invalid Instance Number %d\n", local_autoinstance);
	}

	return;
}

void test_uart_update_driver_timeout(void)
{
	char input[10];
	int status = -1;
	struct termios old_uart_options;
	
	printTerminalf("test_uart_update_driver_timeout: Enter the timeout \nuart::update> ");
	scanTerminalf("%s", input);
	
	st_uart_driver_timeout = st_atoi(input);

	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

	uart_options.c_cc[VTIME] = st_uart_driver_timeout;

	/* Set new options for the port TCSETSW - Wait until data is transmitted*/
	status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_update_driver_timeout: Setting Failed\n");
		return;
	}
	else
		printTerminalf("test_uart_update_driver_timeout: Setting st_uart_driver_interface to %s\n", input);
	
	return;
}



void test_uart_driver_open(void)
{
	Int32 attr = UARTRDWR, can_input = 0, attr_timeout = O_NDELAY;
	struct termios old_uart_options;
	int status = -1;
	
	printTerminalf("test_uart_driver_open: Enter the 0- Canonical 1- Non-canonical\n");
	scanTerminalf("%d", &can_input);

	printTerminalf("test_uart_driver_open: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
	scanTerminalf("%d", &attr);
	
	printTerminalf("test_uart_driver_open: Enter the attribute for open (delay):: 0-No timeout forever, 1-Timeout forever\n");
	scanTerminalf("%d", &attr_timeout);
	
	if (0 == st_uart_instance)
	{
		if (0 == instflag[st_uart_instance])
		{
			if (1 == attr_timeout)
			{
				fd_uart = open(INSTANCE0, attr | O_NOCTTY );
			}
			else
			{
				fd_uart = open(INSTANCE0, attr | O_NOCTTY | O_NDELAY);
			}
			instflag[st_uart_instance] =1;
		}
		else
			fd_uart = UART_NULL;
	}
		
	else if (1 == st_uart_instance)
	{
		if (0 == instflag[st_uart_instance])
		{
			if (1 == attr_timeout)
			{
				fd_uart = open(INSTANCE1, attr | O_NOCTTY );
			}
			else
			{
				fd_uart = open(INSTANCE1, attr | O_NOCTTY | O_NDELAY);
			}
			instflag[st_uart_instance] =1;
		}
		else
			fd_uart = UART_NULL;
	}
	
	else if (2 == st_uart_instance)
	{
		if (0 == instflag[st_uart_instance])
		{
			if (1 == attr_timeout)
			{
				fd_uart = open(INSTANCE2, attr | O_NOCTTY );
			}
			else
			{
				fd_uart = open(INSTANCE2, attr | O_NOCTTY | O_NDELAY);
			}
			instflag[st_uart_instance] =1;
		}
		else
			fd_uart = UART_NULL;
	}
	
	else
	{
		printTerminalf("test_uart_driver_open: Invalid instance\n");
		return;
	}

	if( fd_uart >= UART_SUCCESS)
	{
		st_uart_driver[st_uart_instance] = fd_uart;

/* Set canonical/ non-canonical input */
		
		/* Get current options of the port */
		ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

		if (0 == can_input)
				uart_options.c_lflag |= (ICANON | ECHO | ECHOE);
		else if (1 == can_input)
				uart_options.c_lflag |= ~(ICANON | ECHO | ECHOE);
		else
				uart_options.c_lflag = old_uart_options.c_lflag;


		/* Set minimum characters to read */
		uart_options.c_cc[VMIN] = MIN_RD_CHAR;

		/* Set new options for the port TCSETSW - Wait until data is transmitted*/
		status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

		if (status < UART_SUCCESS)
		{
			ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
			printTerminalf("test_uart_driver_open: Default Setting Failed\n");
			return;
		}
		else
			printTerminalf("test_uart_driver_open:  Default Setting Passed\n");
	

		printTerminalf("test_uart_driver_open: Success UART Instance:%d, fd = %d\n", st_uart_instance, fd_uart);
	}
	else
   	{
		fd_uart = UART_NULL;
		st_uart_driver[st_uart_instance] = fd_uart;
		instflag[st_uart_instance] = 0;
		printTerminalf("test_uart_driver_open: Failed UART Instance:%d, fd:-%d\n", st_uart_instance, errno);
	}
	
	return;
}

void test_uart_driver_close(void)
{
	int status = -1;
	
	status = close(st_uart_driver[st_uart_instance]);
			
	if(status < UART_SUCCESS) 
	{
		printTerminalf("test_uart_driver_close: Failed UART Instance:%d Errno:%d\n", st_uart_instance, status);
	}
   	else
   	{
		st_uart_driver[st_uart_instance] = UART_NULL;
		instflag[st_uart_instance] = 0;
		printTerminalf("test_uart_driver_close: Success UART Instance:%d\n", st_uart_instance);
	}

	return;
}




void test_uart_driver_set_baud(void)
{
	int new_baud = 15;		/* 9600 Baud */
	//int old_baud = 0;
	int status = -1;
	struct termios old_uart_options;

	printTerminalf("Supported Baud 0, 50, 75, 110, 134, 150, 200, 300, 600, ");
	printTerminalf("1200, 1800, 2400, 4800, 9600, 19200, 38400, ");
	printTerminalf("57600, 115200, 230400, 460800, 500000, 576000, ");
	printTerminalf("921600, 1000000, 1152000, 1500000, 2000000, 2500000, ");
	printTerminalf("3000000, 3500000, 4000000 \nuart::baud> ");
	printTerminalf("Enter New Baud \nuart::baud> ");
	scanTerminalf("%d", &new_baud);
	
	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);	

	uart_options.c_cflag &= ~CBAUD;

	switch (new_baud)
	{
		case 0: 
				uart_options.c_cflag |= B0;
				break;
		case 50: 
				uart_options.c_cflag |= B50;
				break;
		case 75: 
				uart_options.c_cflag |= B75;
				break;
		case 110: 
				uart_options.c_cflag |= B110;
				break;
		case 134: 
				uart_options.c_cflag |= B134;
				break;
		case 150: 
				uart_options.c_cflag |= B150;
				break;
		case 200: 
				uart_options.c_cflag |= B200;
				break;
		case 300: 
				uart_options.c_cflag |= B300;
				break;
		case 600: 
				uart_options.c_cflag |= B600;
				break;
		case 1200: 
				uart_options.c_cflag |= B1200;
				break;
		case 1800: 
				uart_options.c_cflag |= B1800;
				break;
		case 2400: 
				uart_options.c_cflag |= B2400;
				break;
		case 4800: 
				uart_options.c_cflag |= B4800;
				break;
		case 9600: 
				uart_options.c_cflag |= B9600;
				break;
		case 19200: 
				uart_options.c_cflag |= B19200;
				break;
		case 38400: 
				uart_options.c_cflag |= B38400;
				break;
		case 57600: 
				uart_options.c_cflag |= B57600;
				break;
		case 115200: 
				uart_options.c_cflag |= B115200;
				break;
		case 230400: 
				uart_options.c_cflag |= B230400;
				break;
		case 46800: 
				uart_options.c_cflag |= B460800;
				break;
		case 500000: 
				uart_options.c_cflag |= B500000;
				break;
		case 576000: 
				uart_options.c_cflag |= B576000;
				break;
		case 921600: 
				uart_options.c_cflag |= B921600;
				break;
		case 1000000: 
				uart_options.c_cflag |= B1000000;
				break;
		case 1152000: 
				uart_options.c_cflag |= B1152000;
				break;
		case 1500000: 
				uart_options.c_cflag |= B1500000;
				break;
		case 2000000: 
				uart_options.c_cflag |= B2000000;
				break;
		case 2500000: 
				uart_options.c_cflag |= B2500000;
				break;
		case 3000000: 
				uart_options.c_cflag |= B3000000;
				break;
		case 3500000: 
				uart_options.c_cflag |= B3500000;
				break;
		case 4000000: 
				uart_options.c_cflag |= B4000000;
				break;
		default:
				uart_options.c_cflag |= DEFAULT_BAUD; 
				break;
	}
			
	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);

	/* Set new options for the port */
	status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_set_baud: Setting Failed\n");
		return;
	}
	else
		printTerminalf("test_uart_driver_set_baud: Setting st_uart_driver_interface to %d\n", new_baud);
	
	return;
}


void test_uart_driver_set_stopbit(void)
{
	Int32 new_stopbit = 0;
	int status = -1;
	struct termios old_uart_options;

	printTerminalf("Enter New stop bits (1=one, 2=two)\nuart::stopbit> ");
	scanTerminalf("%d", &new_stopbit);
	
	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);	

	uart_options.c_cflag &= ~CSTOPB;

	if (2 == new_stopbit)
		uart_options.c_cflag |= CSTOPB;

	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);

	/* Set new options for the port TCSETSW - Wait until data is transmitted*/
	status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	
	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_set_stopbit: Setting Failed\n");
		return;
	}
	else
		printTerminalf("test_uart_driver_set_stopbit: Setting st_uart_driver_interface to %d\n", new_stopbit);
	
	return;
}

void test_uart_driver_get_config(void)
{
	int curr_baud=-1, curr_size = -1, curr_stopb =-1, curr_evenpar = -1, curr_oddpar = -1, curr_fctrl = -1;
	
	printTerminalf("test_uart_driver_get_config: Starting Test\n");
	strcpy(io_status_buffer, "test_uart_driver_get_config: Starting Test");

	ioctl(st_uart_driver[st_uart_instance],TCGETS, &uart_options);

	/* Need to investigate */

	printTerminalf("The Current UART settings are: %d\n", uart_options.c_cflag);

	curr_baud = uart_options.c_cflag & CBAUD;	
	printTerminalf("The Current Baud setting is: %d\n", curr_baud);

	curr_size = uart_options.c_cflag & CSIZE;
	printTerminalf("The Current Data bits size setting is: %d\n", curr_size);

	curr_stopb = uart_options.c_cflag & CSTOPB;
	printTerminalf("The Current Stop bits size setting is: %d\n", curr_stopb);

	curr_evenpar = uart_options.c_cflag & PARENB;
	printTerminalf("The Current Even parity bit setting is: %d\n", curr_evenpar);

	curr_oddpar = uart_options.c_cflag & PARODD;
	printTerminalf("The Current Odd parity bit setting is: %d\n", curr_oddpar);

	curr_fctrl = uart_options.c_cflag & CRTSCTS;
	printTerminalf("The Current flow control setting is: %d\n", curr_fctrl);
			
	printTerminalf("test_uart_driver_get_config: Test is over\n");
	
	return;
}

void test_uart_driver_set_parity(void)
{
	Int32 new_parity = 0;
	int status = -1;
	struct termios old_uart_options;
	
	printTerminalf("Enter New Parity 0 - None, 1 - Even, 2 - Odd, 3 - space\nuart::parity> ");
	scanTerminalf("%d", &new_parity);

	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

	if (0 == new_parity)
		uart_options.c_cflag &= ~PARENB;
	
	else if (1 == new_parity)
	{
		uart_options.c_cflag |= PARENB;
		uart_options.c_cflag &= ~PARODD;

	}

	else if (2 == new_parity)
	{
		uart_options.c_cflag |= PARENB;
		uart_options.c_cflag |= PARODD;

	}

	else if (3 == new_parity)
	{
		/* To be done */
	}

	else
	{
		printTerminalf("test_uart_driver_set_parity: Invalid number \n");
		return;
	}

	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);
	
	/* Set new options for the port TCSETSW - Wait until data is transmitted*/
	status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_set_parity: Setting Failed\n");
		return;
	}
	else
		printTerminalf("test_uart_driver_set_parity: Setting st_uart_driver_interface to %d\n", new_parity);
	
	return;
}

void test_uart_driver_set_data(void)
{
	Int32 new_databits = 3;
	int status = -1;
	struct termios old_uart_options;

	printTerminalf("Enter New Data Bits 5 bits, 6 bits, 7 bits, 8 bits \nuart::data> ");
	scanTerminalf("%d", &new_databits);

	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

	if (5 == new_databits)
	{
		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS5;
	}
	
	else if (6 == new_databits)
	{
		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS6;

	}

	else if (7 == new_databits)
	{
		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS7;

	}

	else if (8 == new_databits)
	{
		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS8;
	}

	else
	{
		printTerminalf("test_uart_driver_set_data: Invalid number \n");
		return;
	}

	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);
	
	/* Set new options for the port TCSETSW - Wait until data is transmitted*/
	status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_set_data: Setting Failed\n");
		return;
	}
	else
		printTerminalf("test_uart_driver_set_data: Setting st_uart_driver_interface to %d\n", new_databits);
	
	return;
}



void test_uart_driver_set_flowCtrl(void)
{
	Int32 new_fcType = 0;
	int status = -1;
	struct termios old_uart_options;
	
	printTerminalf("Enter New Flow Control Type option (0 for None, 1 for software fc, 2 for hardware fc)\nuart::flowcontrol> ");
	scanTerminalf("%d", &new_fcType);

	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

	if (0 == new_fcType)
		uart_options.c_cflag &= ~CRTSCTS; 	/* CNEW_RTSCTS */
	
	else if( 1 == new_fcType)
	{
		printTerminalf("Not supported\nuart::flowcontrol> ");
		//scanTerminalf("%d", &new_fcParam);
	}
	else if( 2 == new_fcType)
	{
		uart_options.c_cflag |= CRTSCTS;		/* CNEW_RTSCTS */

	}
	else
	{
		printTerminalf("Invalid number \nuart::flowcontrol> ");
		return;
	}
	
	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);
	
	/* Set new options for the port TCSETSW - Wait until data is transmitted*/
	status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_set_flowCtrl: test_uart_driver_set_stopbit: Setting Failed\n");
		return;
	}
	else
		printTerminalf("test_uart_driver_set_flowCtrl: Setting st_uart_driver_interface to %d\n", new_fcType);
	
	return;
}










void test_uart_driver_read(void)
{
	Uint8 * rxBuf = 0;

	Int32 rxLen=0;
        Int32 actualLen = 0;

        printTerminalf("test_uart_driver_read: Enter Size \nuart::read> ");
        scanTerminalf("%d", &rxLen);

#ifdef Cache_enable
	//Uint8 srcArray[1024 + UART_CACHE_LINE_SIZE_IN_BYTES] = {0,};

//	Uint8 *srcArray = 0;
	Uint8 *srcArray = (Uint8 *)malloc(rxLen+32);
   /* aligning srcBuf on CACHE line size boundary */

	rxBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));

#else
	//char rxBuf[1024] = {0,};
	rxBuf = (Uint8 *)malloc(rxLen);
#endif
	if (NULL != rxBuf)
    	{

		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_read: starting Test\n");
		} 
		else	
		{
			strcpy(io_status_buffer, "test_uart_driver_read: Starting test_uart_driver_read Test");
		}

		while (actualLen != rxLen)
				actualLen = read(st_uart_driver[st_uart_instance], rxBuf, rxLen);

		if(actualLen == rxLen) 
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_read::Read Success: Length = %d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_read::Read Success");
			}
		}
   		else
   		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_read::Read Failed: Length = %d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_read::Read Failed");
			}
		}
	free(rxBuf);
	}
	else
	{
		printTerminalf("test_uart_driver_read: Malloc Failed:%d\n");
	}
	return;
}



void test_uart_driver_write_sync(void)
{
	Int32 txLen=0;
    Int32 actualLen = 0;
	int i =0;

	printTerminalf("test_uart_driver_write_sync: Enter the Size \nuart::write_sync> ");
    scanTerminalf("%d", &txLen);

#ifdef Cache_enable
//	Uint8 srcArray[txLen + UART_CACHE_LINE_SIZE_IN_BYTES] = {'a',};
	
	Uint8 *srcArray = (Uint8 *)malloc(txLen+32);	

	/* aligning srcBuf on CACHE line size boundary */

	Uint8 *txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));

#else
	//char txBuf[4096] = {'a',};
	Uint8 *txBuf = (Uint8 *)malloc(txLen);
#endif
	if (NULL != txBuf)	
	{
 
		/* Start the Loop from 1 and NOT 0 */
		for(i=0; i < txLen; i++)
		{
			//if(0 == i%26)
		//	{
				*(txBuf + i) = 'a' + (i%26);
				//txBuf[i] = 'a';
		//	} else {
		//		*(txBuf + i) = *(txBuf + (i - 1)) + 1; /* 'a' will result in 'b' */
				//txBuf[i] = txBuf[i - 1] + 1; /* 'a' will result in 'b' */
		//	}
		}

		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_write_sync: Starting Test\n");
		} 
		else	
		{
			strcpy(io_status_buffer, "test_uart_driver_write_sync: Starting Test");
		}
printTerminalf("uart instance is: %d and fd for it is: %d\n", st_uart_instance, st_uart_driver[st_uart_instance]);
		actualLen = write(st_uart_driver[st_uart_instance], txBuf, txLen);
	
		if(actualLen < 0)
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_write_sync::Write Failed: Length = %d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_write_sync::Write Failed");
			}
		} 
		else 
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_write_sync::Write Success: Length = %d\n", actualLen);	
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_write_sync::Write Success");
			}
		}
		free(txBuf);
	}
	else
	{
		printTerminalf("test_uart_driver_write_sync::Write Malloc Failed");
	}
	return;
}



void test_uart_driver_read_sync_and_write_sync(void)
{
	Int32 txLen=0;
	Int32 actualLen = 0;

	printTerminalf("test_uart_driver_read_sync_and_write_sync: Enter Size \nuart::read_write_sync> ");
	scanTerminalf("%d", &txLen);

#ifdef Cache_enable
	//Uint8 srcArray[1024 + UART_CACHE_LINE_SIZE_IN_BYTES] = {'a',};
	//Uint8 dstArray[1024 + UART_CACHE_LINE_SIZE_IN_BYTES] = {0,};

	Uint8 *srcArray = (Uint8 *)malloc(txLen+32);	
	Uint8 *dstArray = (Uint8 *)malloc(txLen+32);	

   /* aligning srcBuf & dstBuf on CACHE line size boundary */

	Uint8 *txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
	Uint8 *rxBuf = (Uint8*)((Uint32)(dstArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));

#else
	Uint8 *txBuf = NULL;
    Uint8 *rxBuf = NULL;

//	char txBuf[1024] = {'a',};
//	char rxBuf[1024] = {'0',};
#endif

	if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
	{
		printTerminalf("test_uart_driver_read_sync_and_write_sync::Starting Test\n");
	} 
	else	
	{
		strcpy(io_status_buffer, "test_uart_driver_read_sync_and_write_sync::Starting Test");
	}
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, txLen);
	
	if(actualLen == txLen) 
	{
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_read_sync_and_write_sync::Read Success: Length = %d\n", actualLen);
		} 
		else 
		{
			strcpy(io_status_buffer, "test_uart_driver_read_sync_and_write_sync::Read Success");
		}
	}
   	else
   	{
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_read_sync_and_write_sync::Read Failed: Length = %d\n", actualLen);
		} 
		else 
		{
			strcpy(io_status_buffer, "test_uart_driver_read_sync_and_write_sync::Read Failed");
		}
	}
	actualLen = 0;
	actualLen = write(st_uart_driver[st_uart_instance], txBuf, txLen);
	
	if(actualLen == txLen) 
	{
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_read_sync_and_write_sync::Write Success: Length = %d\n", actualLen);	
		} 
		else 
		{
			strcpy(io_status_buffer, "test_uart_driver_read_sync_and_write_sync::Write Success");
		}
	}
   	else
   	{
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
				printTerminalf("test_uart_driver_read_sync_and_write_sync::Write Failed: Length = %d\n", actualLen);			
		} 
		else 
		{
			strcpy(io_status_buffer, "test_uart_driver_read_sync_and_write_sync::Write Failed");
		}
	}

	return;
}

void test_uart_driver_sync_stress(void)
{

	Int32 counter = 0, i = 0;
	Int32 status = UART_FAILURE;

	printTerminalf("test_uart_driver_sync_stress: Enter loop counter count\nuart::sync::stress> ");
	scanTerminalf("%d", &counter);

	for(i = 0; i < counter; i++)
	{
	
		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 10000, UART_TX);
		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 100, UART_TX);

		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, 10000, UART_TX);
		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, 100, UART_TX);


		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 10000, UART_RX);
		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 100, UART_RX);

		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, 10000, UART_RX);
		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, 100, UART_RX);


		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 10000, UART_TX_RX);
		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 100, UART_TX_RX);

		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, 10000, UART_TX_RX);
		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, 100, UART_TX_RX);
		
		
	}

	printTerminalf("test_uart_driver_sync_stress: Success:: Test is Over ");
	
}



void test_uart_driver_len_in_stress(void)
{

	Int32 counter = 0, i = 0;
	Int32 Len=0;
	Int32 status = UART_FAILURE;
	
	
	printTerminalf("test_uart_driver_len_in_stress: Enter Size \nuart::sync_stress> ");
	scanTerminalf("%d", &Len);
	
	printTerminalf("test_uart_driver_len_in_stress: Enter Number of times\nuart::sync::stress> ");
	scanTerminalf("%d", &counter);


	for(i = 0; i < counter; i++)
	{
	
		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, Len, UART_TX);
		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, Len, UART_TX);

		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, Len, UART_RX);
		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, Len, UART_RX);

		status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, Len, UART_TX_RX);
		status =  test_uart_driver_tx_rx_int(15, CS8, 0, 0, 0, Len, UART_TX_RX);
	
		
	}

	printTerminalf("test_uart_driver_sync_stress: Success:: Test is Over ");
	
}





void test_uart_driver_sync_variable_write(void)
{
#ifdef Cache_enable
	Uint8 srcheaderArray[2 + UART_CACHE_LINE_SIZE_IN_BYTES] = {'a',};
	Uint8 srcArray[26 + UART_CACHE_LINE_SIZE_IN_BYTES] = {0,};

	Uint8 * txHeader;
	Uint8 * txBuf;

   /* aligning srcBuf on CACHE line size boundary */

	txHeader = (Uint8*)((Uint32)(srcheaderArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
	txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));

#else
	char * txBuf[26];
	char * txHeader [2];
#endif
	Int32 txLen=0;
	Int32 actualLen = 0;
	Uint32 i = 0;

	txBuf[0] = "abcdefghijklmnopqrstuvwxyz";
	
	if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
	{
		printTerminalf("test_uart_driver_sync_variable_write: Starting Test\n");
	} 
	else	
	{
		strcpy(io_status_buffer, "test_uart_driver_sync_variable_write: Starting Test");
	}

	/* Start from 1 and not 0 */
	for(i = 1; i < 26; i++)
	{
		txBuf[i] = txBuf[0];
	}

	txHeader[0] = "\r\n";

	for(i = 0; i < 26; i++)
	{
		write(st_uart_driver[st_uart_instance], txHeader[0], 1);
		write(st_uart_driver[st_uart_instance], txHeader[1], 1);
				
		txLen = i+1;
		actualLen = write(st_uart_driver[st_uart_instance], txBuf[i], txLen);
		
		if(actualLen != txLen) 
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_sync_variable_write: UART (PSP i/f)::Write Variable sync Failed:%d\n", actualLen);				
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_sync_variable_write: UART (PSP i/f) Write Variable sync Failed\n");
			}
		}
		else
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				write(st_uart_driver[st_uart_instance], txHeader[0], 1);
				write(st_uart_driver[st_uart_instance], txHeader[1], 1);
				
				printTerminalf("test_uart_driver_sync_variable_write: UART (PSP i/f)::Write Variable Sync Success:%d\n", actualLen);				
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_sync_variable_write: UART (PSP i/f)::Write Variable Sync Success\n");
			}
		}
	}
	return;
}



void test_uart_driver_stability(void)
{
	int status = -1;
	Uint32 loop_counter=0;
	Uint32 i = 0;
	Uint32 attr = O_RDWR;
	Int32 attr_val = 0;
	 char dev_name[100] = {0, };     /* Device Name */
	Int32 attr1 = O_NDELAY;
	struct termios old_uart_options;
	Int32 can_input = 0;
//	Int32 attr_timeout = O_NDELAY;


    //printTerminalf("test_uart_driver_open: Enter the attribute for open (delay):: 0-No timeout forever, 1-Timeout forever\n");
    //scanTerminalf("%d", &attr_timeout);

	signal(SIGINT, Hand);

	printTerminalf("test_uart_driver_stability: Enter loop counter value\nuart::stability> ");
	scanTerminalf("%d", &loop_counter);

	printTerminalf("test_uart_driver_stability: Enter the device to open (/dev/console)\n");
    scanTerminalf("%s", &dev_name);

	printTerminalf("test_uart_driver_stability: Enter the 0- Canonical 1- Non-canonical\n");
    scanTerminalf("%d", &can_input);

	
	printTerminalf("test_uart_driver_stability: Enter the attribute for open:: 0-Non-Blocking call, 1-Blocking call\n");
    scanTerminalf("%d", &attr_val);

    if (1 == attr_val)
    	attr1 = O_SYNC;


	printTerminalf("test_uart_driver_stability: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
	scanTerminalf("%d", &attr);
	
	
	if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
	{
		printTerminalf("test_uart_driver_stability: Starting stability test\n");
	} 
	else	
	{
		strcpy(io_status_buffer, "test_uart_driver_stability: Starting stability test");
	}
	
	for(i = 0; i < loop_counter; i++)
	{
		status = close(st_uart_driver[st_uart_instance]);
		
		if(status < UART_SUCCESS) 
		{
			printTerminalf("test_uart_driver_stability: UART Close Instance:%d Failed:%d\n", 0, status);
		}
		else
		{
			st_uart_driver[st_uart_instance] = UART_NULL;
		}

		fd_uart = open(dev_name, attr | O_NOCTTY | attr1);

	//	fd_uart = open(INSTANCE0, attr | O_NOCTTY );
		if( fd_uart >= UART_SUCCESS)
		{
			st_uart_driver[st_uart_instance] = fd_uart;
			
			/* Get current options of the port */
			ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

			//uart_options.c_lflag &= ~(ICANON);
			if (0 == can_input)
            	uart_options.c_lflag |= (ICANON | ECHO | ECHOE);
            else if (1 == can_input)
            	uart_options.c_lflag |= ~(ICANON | ECHO | ECHOE);
            else
            	uart_options.c_lflag = old_uart_options.c_lflag;

			/* Set new options for the port TCSETSW - Wait until data is transmitted*/
			status = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

			printTerminalf("test_uart_driver_stability: Success UART Instance:%d, fd = %d\n", st_uart_instance, fd_uart);
		}
		else
   		{
			perror("Stability error: ");
			printTerminalf("test_uart_driver_stability: Failed UART Instance:%d fd = %d\n", st_uart_instance, fd_uart);
		}
	}


	/* 
	 * Baud 0-0, 1-50, 2-75, 3-110, 4-134, 5-150, 6-200, 7-300, 10-600, 11-1200, 12-1800, 13-2400, 14-4800, 15-9600, 16-19200, 17-38400,
	 * 10001-57600, 10002-115200, 10003-230400, 10004-460800, 10005-500000, 10006-576000, 10007-921600, 10010-1000000, 10011-1152000, 
	 * 10012-1500000, 10013-2000000, 10014-2500000, 10015-3000000, 10016-3500000, 10017-4000000
	 * stop bits (0=one, 1=one-half, 2=two)
	 * Parity 0 - None, 1 - Even, 2 - Odd, 3 - space
	 * Flow Control Type option (0 for None, 1 for software fc, 2 for hardware fc)
	 */

#if 0	
	status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 1000, UART_TX);
	status =  test_uart_driver_tx_rx_int(15, CS7, 2, 2, 0, 0, UART_TX);
	status =  test_uart_driver_tx_rx_int(10006, CS8, 1, 0, 0, 5000, UART_TX);
	status =  test_uart_driver_tx_rx_int(17, CS6, 0, 0, 1, 1, UART_TX);
	status =  test_uart_driver_tx_rx_int(10002, CS5, 0, 0, 0, 5000, UART_TX);

	status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 1000, UART_RX);
	status =  test_uart_driver_tx_rx_int(15, CS7, 2, 2, 0, 0, UART_RX);
	status =  test_uart_driver_tx_rx_int(10006, CS8, 1, 0, 0, 5000, UART_RX);
	status =  test_uart_driver_tx_rx_int(17, CS6, 0, 0, 1, 1, UART_RX);
	status =  test_uart_driver_tx_rx_int(10002, CS5, 0, 0, 0, 5000, UART_RX);

	status =  test_uart_driver_tx_rx_int(10002, CS8, 0, 0, 0, 1000, UART_TX_RX);
	status =  test_uart_driver_tx_rx_int(15, CS7, 2, 2, 0, 0, UART_TX_RX);
	status =  test_uart_driver_tx_rx_int(10006, CS8, 1, 0, 0, 5000, UART_TX_RX);
	status =  test_uart_driver_tx_rx_int(17, CS6, 0, 0, 1, 1, UART_TX_RX);
	status =  test_uart_driver_tx_rx_int(10002, CS5, 0, 0, 0, 5000, UART_TX_RX);
#endif	
	printTerminalf("test_uart_driver_stability: Success:: Test is over\n");
}



void test_uart_driver_sync_performance_read_115200(void)
{
	Uint32  loopcount = 1;	
	Uint8 * rxBuf = NULL;
	Uint32 actualLen = 0, rxLen = 0, Len = 0;
	//struct termios old_uart_options;
	struct timeval time;
	Uint32 Start_Time = 0, Start_sec = 0;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

	printTerminalf("Enter the number of bytes to read: \nread count>");
	scanTerminalf("%d", &Len);


#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(Len + UART_CACHE_LINE_SIZE_IN_BYTES);
	rxBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
#else

	rxBuf = (Uint8 *)malloc(Len);
#endif
	
	if (NULL != rxBuf)
	{	
		
		//printTerminalf("Enter the loop count: \nloop count>");
		//scanTerminalf("%d", &loopcount);

/* Baud - 115200 bps */
	
		/* Enable timer to be added */

		gettimeofday(&time,NULL); 

		Start_sec = time.tv_sec;
    	Start_Time = time.tv_usec;

//		for(i=0; i<loopcount; i++)
//		{
	 		actualLen = read(st_uart_driver[st_uart_instance], rxBuf, Len);
			rxLen = rxLen + actualLen;
//		}
		/* Disable timer and get timer value to be added */

		gettimeofday(&time,NULL); 

    	printTerminalf("test_uart_driver_sync_performance_read_115200: Timer value for (1024*%d) data transmit size (115.2Kbps),txLen = %d \nStart = %dus, End = %dus \nStart = %ds, End = %ds\n",loopcount, rxLen, Start_Time, time.tv_usec, Start_sec, time.tv_sec);

		free(rxBuf);
	}
	else
	{
    	printTerminalf("test_uart_driver_sync_performance_115200: Malloc Failed\n");
	}
}




void test_uart_driver_sync_performance_115200(void)
{
	Int32 status = UART_FAILURE;
	Uint32 i = 0, loopcount = 1;	
	Uint8 * txBuf = NULL;
	Uint32 actualLen = 0, txLen = 0;
	struct termios old_uart_options;
	struct timeval time;
	Uint32 Start_Time = 0, Start_sec = 0;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txbuflen + UART_CACHE_LINE_SIZE_IN_BYTES);
	txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
#else

	txBuf = (Uint8 *)malloc(1024);
#endif
	
	if (NULL != txBuf)
	{	
		
		printTerminalf("Enter the loop count: \nloop count>");
		scanTerminalf("%d", &loopcount);

		for(i=0; i < 1024; i++)
		{
			txBuf[i] = i;
		}

		/* Get current options of the port */
		ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);
	
		/* Enable receiver and set local mode */
		uart_options.c_cflag |= (CLOCAL | CREAD);

		/* Set the baud rate */
		cfsetispeed(&uart_options, 10002);
   		cfsetospeed(&uart_options, 10002);

		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS8;
		uart_options.c_cflag |= 0;
		uart_options.c_cflag &= ~PARENB;
		uart_options.c_cflag &= ~CRTSCTS; 	/* No CNEW_RTSCTS */

		/* Set new options for the port */
		status  = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

		if (status < UART_SUCCESS)
		{
			ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
			printTerminalf("test_uart_driver_sync_performance_115200: Setting Failed\n");
		}
		else
			printTerminalf("test_uart_driver_sync_performance_115200: Setting Success\n");
	
		printTerminalf("test_uart_driver_sync_performance_115200: Starting Test\n");

/* Baud - 115200 bps */
	
		/* Enable timer to be added */

		gettimeofday(&time,NULL); 

		Start_sec = time.tv_sec;
    	Start_Time = time.tv_usec;

		for(i=0; i<loopcount; i++)
		{
	 		actualLen = write(st_uart_driver[st_uart_instance], txBuf, 1024);
			txLen = txLen + actualLen;
		}
		/* Disable timer and get timer value to be added */

		gettimeofday(&time,NULL); 

    	printTerminalf("test_uart_driver_sync_performance_115200: Timer value for (1024*%d) data transmit size (115.2Kbps),txLen = %d \nStart = %dus, End = %dus \nStart = %ds, End = %ds\n",loopcount, txLen, Start_Time, time.tv_usec, Start_sec, time.tv_sec);

		free(txBuf);
	}
	else
	{
    	printTerminalf("test_uart_driver_sync_performance_115200: Malloc Failed\n");
	}


}





void test_uart_driver_sync_performance_9600(void)
{
	Uint32 i = 0, loopcount = 1;	
	Uint8 * txBuf = NULL;
	Uint32 actualLen = 0, txLen = 0;
	//struct termios old_uart_options;
	struct timeval time;
	Uint32 Start_Time = 0, Start_sec = 0;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txbuflen + UART_CACHE_LINE_SIZE_IN_BYTES);
	txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
#else

	txBuf = (Uint8 *)malloc(1024);
#endif
	
	if (NULL != txBuf)
	{	
		
		printTerminalf("Enter the loop count: \nloop count>");
		scanTerminalf("%d", &loopcount);

		for(i=0; i < 1024; i++)
		{
			txBuf[i] = i;
		}
#if 0
		/* Get current options of the port */
		ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);
	
		/* Enable receiver and set local mode */
		uart_options.c_cflag |= (CLOCAL | CREAD);

		/* Set the baud rate */
		cfsetispeed(&uart_options, 15);
   		cfsetospeed(&uart_options, 15);

		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS8;
		uart_options.c_cflag |= 0;
		uart_options.c_cflag &= ~PARENB;
		uart_options.c_cflag &= ~CRTSCTS; 	/* No CNEW_RTSCTS */


		/* Set new options for the port */
		status  = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

		if (status < UART_SUCCESS)
		{
			ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
			printTerminalf("test_uart_driver_sync_performance_9600: Setting Failed\n");
		}
		else
			printTerminalf("test_uart_driver_sync_performance_9600: Setting Success\n");
	
		printTerminalf("test_uart_driver_sync_performance_9600: Starting Test\n");
#endif
/* Baud - 9600 bps */
	
		/* Enable timer to be added */

		gettimeofday(&time,NULL); 

		Start_sec = time.tv_sec;
    	Start_Time = time.tv_usec;

		for(i=0; i<loopcount; i++)
		{
	 		actualLen = write(st_uart_driver[st_uart_instance], txBuf, 1024);
			txLen = txLen + actualLen;
		}
		/* Disable timer and get timer value to be added */

		gettimeofday(&time,NULL); 
#if 0
		 /* Get current options of the port */
         ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

	     /* Enable receiver and set local mode */
         uart_options.c_cflag |= (CLOCAL | CREAD);

         /* Set the baud rate */
         cfsetispeed(&uart_options, 10002);
         cfsetospeed(&uart_options, 10002);

         uart_options.c_cflag &= ~CSIZE;         /* Mask the characters size bits */
         uart_options.c_cflag |= CS8;
         uart_options.c_cflag |= 0;
         uart_options.c_cflag &= ~PARENB;
         uart_options.c_cflag &= ~CRTSCTS;       /* No CNEW_RTSCTS */


         /* Set new options for the port */
         status  = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

         if (status < UART_SUCCESS)
         {
         	ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
            printTerminalf("test_uart_driver_sync_performance_9600: Setting Failed\n");
         }
         else
          	printTerminalf("test_uart_driver_sync_performance_9600: Setting Success\n");
#endif
   		printTerminalf("test_uart_driver_sync_performance_9600: Timer value for (1024*%d) data transmit size (9.6Kbps),txLen = %d \nStart = %dus, End = %dus \nStart = %ds, End = %ds\n",loopcount, txLen, Start_Time, time.tv_usec, Start_sec, time.tv_sec);

		free(txBuf);
	}
	else
	{
    	printTerminalf("test_uart_driver_sync_performance_9600: Malloc Failed\n");
	}


}





#if 0

void test_uart_driver_sync_performance_9600(void)
{
	Int32 status = UART_FAILURE;
	//Uint32 timer_val = 0;
	Uint32 i =0;	
	Uint8 * txBuf = NULL;
	Uint32 actualLen = 0;
	struct termios old_uart_options;
	struct timeval time;
	Uint32 Start_Time = 0;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txbuflen + UART_CACHE_LINE_SIZE_IN_BYTES);
	txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
	txBuf = (Uint8 *)malloc(1000000);
#endif
	
	for(i=0; i < 1000000; i++)
	{
		txBuf[i] = i;
	}

	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);
	

	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);

	/* Set the baud rate */
	cfsetispeed(&uart_options, 15);
   	cfsetospeed(&uart_options, 15);

	uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
	uart_options.c_cflag |= CS8;
	
	uart_options.c_cflag |= 0;

	uart_options.c_cflag &= ~PARENB;

	uart_options.c_cflag &= ~CRTSCTS; 	/* No CNEW_RTSCTS */


	/* Set new options for the port */
	status  = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_sync_performance_9600: Setting Failed\n");
	}
	else
		printTerminalf("test_uart_driver_sync_performance_9600: Setting Success\n");
	

	
	printTerminalf("test_uart_driver_sync_performance_9600: Starting Test\n");
	

/* Baud - 9600 bps */
	
	/* Enable timer to be added */

	gettimeofday(&time,NULL); 

    Start_Time=time.tv_usec;

 	actualLen = write(st_uart_driver[st_uart_instance], txBuf, 100);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 

    printTerminalf("test_uart_driver_sync_performance_9600: Timer value for 100 data transmit size (9.6Kbps) Start = %ds, End = %ds\n",Start_Time, time.tv_usec);


	/* Enable timer to be added */

	gettimeofday(&time,NULL); 

    Start_Time=time.tv_usec;
	
	actualLen = write(st_uart_driver[st_uart_instance], txBuf, 1000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 
    
	printTerminalf("test_uart_driver_sync_performance_9600: Timer value for 1000 data transmit size (9.6Kbps) Start = %ds, End = %ds\n",Start_Time, time.tv_usec);


	/* Enable timer to be added */

	gettimeofday(&time,NULL); 

    Start_Time=time.tv_usec;
	
	actualLen = write(st_uart_driver[st_uart_instance], txBuf, 10000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 

	printTerminalf("test_uart_driver_sync_performance_9600: Timer value for 10000 data transmit size (9.6Kbps) Start = %ds, End = %ds\n",Start_Time, time.tv_usec);


	/* Enable timer to be added */
	
	gettimeofday(&time,NULL); 

    Start_Time=time.tv_usec;
	
	actualLen = write(st_uart_driver[st_uart_instance], txBuf, 1000000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 

	printTerminalf("test_uart_driver_sync_performance_9600: Timer value for 1000000 data transmit size (9.6Kbps) Start = %ds, End = %ds\n",Start_Time, time.tv_usec);


	printTerminalf("test_uart_driver_sync_performance_9600: Success:: Test is Over\n");

	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);

	/* Set the baud rate back to 115200 bps*/
	cfsetispeed(&uart_options, 10002);
   	cfsetospeed(&uart_options, 10002);

	uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
	uart_options.c_cflag |= CS8;
	
	uart_options.c_cflag |= 0;

	uart_options.c_cflag &= ~PARENB;

	uart_options.c_cflag &= ~CRTSCTS; 	/* No CNEW_RTSCTS */

	/* Set new options for the port */
	status  = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_sync_performance_9600: Setting Failed\n");
	}
	else
		printTerminalf("test_uart_driver_sync_performance_9600: Setting Success\n");

	printTerminalf("test_uart_driver_sync_performance_9600: testing is Over\n");
}

#endif

void test_uart_driver_sync_performance(void)
{
	Int32 status = UART_FAILURE;
	Uint32 i =0;	
	Uint8 * txBuf = NULL;
	Uint8 * rxBuf = NULL;
	Uint32 actualLen = 0;
	struct termios old_uart_options;
	struct timeval time;
	Uint32 Start_Time = 0;
    Uint32 End_Time = 0;	
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txbuflen + UART_CACHE_LINE_SIZE_IN_BYTES);
	txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
	dstArray = (Uint8 *)malloc(rxbuflen + UART_CACHE_LINE_SIZE_IN_BYTES);
	rxBuf = (Uint8*)((Uint32)(dstArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
	txBuf = (Uint8 *)malloc(1000000);
	rxBuf = (Uint8 *)malloc(1000000);
#endif
	
	for(i=0; i < 1000000; i++)
	{
		rxBuf[i] = 0;
		txBuf[i] = i;
	}

	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);
	

	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);

	/* Set the baud rate */
	cfsetispeed(&uart_options, 10002);
   	cfsetospeed(&uart_options, 10002);

	uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
	uart_options.c_cflag |= CS8;
	
	uart_options.c_cflag |= 0;

	uart_options.c_cflag &= ~PARENB;

	uart_options.c_cflag &= ~CRTSCTS; 	/* No CNEW_RTSCTS */


	/* Set new options for the port */
	status  = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_sync_performance: Setting Failed\n");
	}
	else
		printTerminalf("test_uart_driver_sync_performance: Setting Success\n");
	

	
	printTerminalf("test_uart_driver_sync_performance: Starting Test\n");
	

/* Baud - 115200 bps */
	

	/* Enable timer to be added */

	gettimeofday(&time,NULL); 
	
//	timer_val = davinci_gettimeoffset();

    Start_Time=time.tv_usec;

 	actualLen = write(st_uart_driver[st_uart_instance], txBuf, 100);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 

    End_Time=time.tv_usec;
	
//	printTerminalf("test_uart_driver_sync_performance: Timer value for 100 data transmit size (115Kbps) Start = %ds, End = %ds\n", timer_val, davinci_gettimeoffset());

	printTerminalf("test_uart_driver_sync_performance: Timer value for 100 data transmit size (115Kbps) Start = %ds, End = %ds\n",Start_Time, End_Time);

	//timer_val = 0;


	/* Enable timer to be added */

	gettimeofday(&time,NULL); 
//	printTerminalf("test_uart_driver_sync_performance:  Clock = %d\n",clock());
    Start_Time = time.tv_usec;
	
	actualLen = write(st_uart_driver[st_uart_instance], txBuf, 1000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 

  //  printTerminalf("test_uart_driver_sync_performance:  Clock = %d\n",clock());

	printTerminalf("test_uart_driver_sync_performance: Timer value for 1000 data transmit size (115Kbps) Start = %ds, End = %ds\n",Start_Time, time.tv_usec);


	//timer_val = 0;


	/* Enable timer to be added */

	gettimeofday(&time,NULL); 

    Start_Time=time.tv_usec;
	
	actualLen = write(st_uart_driver[st_uart_instance], txBuf, 10000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 

	printTerminalf("test_uart_driver_sync_performance: Timer value for 10000 data transmit size (115Kbps) Start = %ds, End = %ds\n",Start_Time, time.tv_usec);


	//timer_val = 0;


	/* Enable timer to be added */
	
	gettimeofday(&time,NULL); 

    Start_Time=time.tv_usec;
	
	actualLen = write(st_uart_driver[st_uart_instance], txBuf, 1000000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 

	printTerminalf("test_uart_driver_sync_performance: Timer value for 1000000 data transmit size (115Kbps) Start = %ds, End = %ds\n",Start_Time, time.tv_usec);


	//timer_val = 0;

#if 0

	/* Enable timer to be added */
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, 100);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_uart_driver_sync_performance: Timer value for 100 data receive size is %d\n", timer_val);

	
	timer_val = 0;

	for(i=0; i < 100; i++)
	{
		rxBuf[i] = 0;
	}

	
	/* Enable timer to be added */
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, 1000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_uart_driver_sync_performance: Timer value for 1000 data receive size is %d\n", timer_val);

	
	timer_val = 0;
	
	for(i=0; i < 1000; i++)
	{
		rxBuf[i] = 0;
	}

	

	/* Enable timer to be added */
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, 10000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_uart_driver_sync_performance: Timer value for 10000 data receive size is %d\n", timer_val);

	
	timer_val = 0;

	for(i=0; i < 10000; i++)
	{
		rxBuf[i] = 0;
	}


	/* Enable timer to be added */
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, 1000000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_uart_driver_sync_performance: Timer value for 1000000 data receive size is %d\n", timer_val);

	
	timer_val = 0;
	
	for(i=0; i < 1000000; i++)
	{
		rxBuf[i] = 0;
	}




#endif



#if 0

	/* Enable timer to be added */
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, 100);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_uart_driver_sync_performance: Timer value for 100 data receive size is %d\n", timer_val);

	
	timer_val = 0;

	for(i=0; i < 100; i++)
	{
		rxBuf[i] = 0;
	}


	/* Enable timer to be added */
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, 1000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_uart_driver_sync_performance: Timer value for 1000 data receive size is %d\n", timer_val);

	
	timer_val = 0;

	for(i=0; i < 1000; i++)
	{
		rxBuf[i] = 0;
	}


	/* Enable timer to be added */
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, 10000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_uart_driver_sync_performance: Timer value for 10000 data receive size is %d\n", timer_val);

	
	timer_val = 0;

	for(i=0; i < 10000; i++)
	{
		rxBuf[i] = 0;
	}


	/* Enable timer to be added */
	
	actualLen = read(st_uart_driver[st_uart_instance], rxBuf, 1000000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_uart_driver_sync_performance: Timer value for 1000000 data receive size is %d\n", timer_val);

	
	timer_val = 0;

	for(i=0; i < 1000000; i++)
	{
		rxBuf[i] = 0;
	}



#endif

	printTerminalf("test_uart_driver_sync_performance: Success:: Test is Over\n");

	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);

	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);

	/* Set the baud rate */
	cfsetispeed(&uart_options, 10002);
   	cfsetospeed(&uart_options, 10002);

	uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
	uart_options.c_cflag |= CS8;
	
	uart_options.c_cflag |= 0;

	uart_options.c_cflag &= ~PARENB;

	uart_options.c_cflag &= ~CRTSCTS; 	/* No CNEW_RTSCTS */

	/* Set new options for the port */
	status  = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_sync_performance: Setting Failed\n");
	}
	else
		printTerminalf("test_uart_driver_sync_performance: Setting Success\n");

}






/* Negative Test cases - NULL Test Case */
void test_uart_driver_NULL_Instance(void)
{
#ifdef Cache_enable
	Uint8 srcArray[6 + UART_CACHE_LINE_SIZE_IN_BYTES] = "Hello";

	Uint8 * txBuf;

   /* aligning srcBuf on CACHE line size boundary */

	txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));

#else
	char txBuf[] = "Hello";
#endif
	Int32 txLen= strlen(txBuf);
	
	Uint32 actualLen = write(UART_NULL, txBuf, txLen);
	
	if(actualLen == txLen) 
	{
		printTerminalf("test_uart_driver_NULL_Instance: UART Write Success with Length:%d\n", actualLen);
	}
   	else
   	{
		printTerminalf("test_uart_driver_NULL_Instance: UART Write Failed:%d\n", actualLen);
	}

	actualLen = read(UART_NULL, txBuf, txLen);
	
	if(actualLen == txLen) 
	{
		printTerminalf("test_uart_driver_NULL_Instance: UART Read Success with Length:%d\n", actualLen);
	}
   	else
   	{
		printTerminalf("test_uart_driver_NULL_Instance: UART Read Failed:%d\n", actualLen);
	}
}



/* Internal functions */

Int32 test_uart_driver_tx_rx_int(Uint32 baud, Uint8 datalen, Uint8 stopbit, Uint8 parity, Uint8 flowctl, Uint32 size, Uint8 tx_rx)
{

	Uint8 * txBuf;
	Uint8 * rxBuf;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

	Uint32 actualLen = 0;

	Int32 status = UART_FAILURE;
	struct termios old_uart_options;
	int i = 0;


		
	/* Get current options of the port */
	ioctl(st_uart_driver[st_uart_instance], TCGETS, &old_uart_options);


	

	/* Enable receiver and set local mode */
	uart_options.c_cflag |= (CLOCAL | CREAD);

	/* Set the baud rate */
	cfsetispeed(&uart_options, baud);
    cfsetospeed(&uart_options, baud);

	if (0 == datalen)
	{
		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS5;
	}
	
	else if (1 == datalen)
	{
		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS6;

	}

	else if (2 == datalen)
	{
		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS7;

	}

	else if (3 == datalen)
	{
		uart_options.c_cflag &= ~CSIZE; 	/* Mask the characters size bits */
		uart_options.c_cflag |= CS8;
	}
	
	
	uart_options.c_cflag |= stopbit;


	if (0 == parity)
		uart_options.c_cflag &= ~PARENB;
	
	else if (1 == parity)
	{
		uart_options.c_cflag |= PARENB;
		uart_options.c_cflag &= ~PARODD;

	}

	else if (2 == parity)
	{
		uart_options.c_cflag |= PARENB;
		uart_options.c_cflag |= PARODD;

	}

	else if (3 == parity)
	{
		/* To be done */
	}



	if (0 == flowctl)
		uart_options.c_cflag &= ~CRTSCTS; 	/* No CNEW_RTSCTS */
	
	else if( 1 == flowctl)
	{
		printTerminalf("Not supported\nuart::flowcontrol> ");
	}
	else if( 2 == flowctl)
	{
		uart_options.c_cflag |= CRTSCTS;		/* CNEW_RTSCTS */

	}
	else
	{
		printTerminalf("Invalid number \nuart::flowcontrol> ");
		status = UART_FAILURE;
		return status;
	}




	
	/* Set new options for the port */
	status  = ioctl(st_uart_driver[st_uart_instance], TCSETSW, &uart_options);

	if (status < UART_SUCCESS)
	{
		ioctl(st_uart_driver[st_uart_instance], TCSETSW, &old_uart_options);
		printTerminalf("test_uart_driver_tx_rx_int: Setting Failed\n");
	}
	else
		printTerminalf("test_uart_driver_tx_rx_int: Setting baud rate to %d\n", baud);
	
	
	
	
	if (UART_TX == tx_rx)
	{
#ifdef Cache_enable
		srcArray = (Uint8 *)malloc(size + UART_CACHE_LINE_SIZE_IN_BYTES);
		if(NULL == srcArray)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Mem Alloc of srcArray failed\n");
			status = UART_FAILURE;
			return status;
		}
		txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
		txBuf = (Uint8 *)malloc(size);
		if(NULL == txBuf)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Mem Alloc of txBuf failed\n");
			status = UART_FAILURE;
			return status;
		}
#endif

		for(i=0; i < size; i++)
		{
			txBuf[i] = i;
		}
	
		
	
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Starting Test\n");
		} 
		else	
		{
			strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: Starting Test");
		}

		actualLen = write(st_uart_driver[st_uart_instance], txBuf, size);
	
		if(actualLen < 0)
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_tx_rx_int: Write Failed:%d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: Write Failed");
			}
		} 
		else 
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_tx_rx_int: Write Success:%d\n", actualLen);	
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: UART Write Success");
			}
		}
	}


	if (UART_RX == tx_rx)
	{

#ifdef Cache_enable
		dstArray = (Uint8 *)malloc(size + UART_CACHE_LINE_SIZE_IN_BYTES);
		if(NULL == dstArray)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Mem Alloc of dstArray failed\n");
			status = UART_FAILURE;
			return status;
		}
		
		rxBuf = (Uint8*)((Uint32)(dstArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
		rxBuf = (Uint8 *)malloc(size);
		if(NULL == rxBuf)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Mem Alloc of rxBuf failed\n");
			status = UART_FAILURE;
			return status;
		}
#endif

		for(i=0; i < size; i++)
		{
			rxBuf[i] = 0;
		}

		
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Starting Test\n");
		} 
		else	
		{
			strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: Starting test_uart_driver_read_sync_and_write_sync Test");
		}
	
		actualLen = read(st_uart_driver[st_uart_instance], rxBuf, size);
	
		if(actualLen == size) 
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_tx_rx_int: Read Success:%d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: UART Read Success");
			}
		}
   		else
   		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_tx_rx_int: Read Failed:%d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: UART Sync R&W Read Failed");
			}
		}
	}



	if (UART_TX_RX == tx_rx)
	{
		
#ifdef Cache_enable
		srcArray = (Uint8 *)malloc(size + UART_CACHE_LINE_SIZE_IN_BYTES);
		if(NULL == srcArray)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Mem Alloc of srcArray failed\n");
			status = UART_FAILURE;
			return status;
		}
		
		txBuf = (Uint8*)((Uint32)(srcArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
		
		dstArray = (Uint8 *)malloc(size + UART_CACHE_LINE_SIZE_IN_BYTES);
		if(NULL == dstArray)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Mem Alloc of dstArray failed\n");
			status = UART_FAILURE;
			return status;
		}
		
		rxBuf = (Uint8*)((Uint32)(dstArray + UART_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(UART_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
		txBuf = (Uint8 *)malloc(size);
		if(NULL == txBuf)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Mem Alloc of txBuf failed\n");
			status = UART_FAILURE;
			return status;
		}
		rxBuf = (Uint8 *)malloc(size);
		if(NULL == rxBuf)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Mem Alloc of rxBuf failed\n");
			status = UART_FAILURE;
			return status;
		}
#endif

		for(i=0; i < size; i++)
		{
			rxBuf[i] = 0;
			txBuf[i] = i;
		}
		
		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Starting Test\n");
		} 
		else	
		{
			strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: Starting test_uart_driver_read_sync_and_write_sync Test");
		}
	
		actualLen = read(st_uart_driver[st_uart_instance], rxBuf, size);
	
		if(actualLen == size) 
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_tx_rx_int: Read Success:%d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: UART Read Success");
			}
		}
   		else
   		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_tx_rx_int: Read Failed:%d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: UART Sync R&W Read Failed");
			}
		}

		if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
		{
			printTerminalf("test_uart_driver_tx_rx_int: Starting Test\n");
		} 
		else	
		{
			strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: Starting test_uart_driver_write_sync Test");
		}

		actualLen = write(st_uart_driver[st_uart_instance], txBuf, size);
	
		if(actualLen < 0)
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_tx_rx_int: Write Failed:%d\n", actualLen);
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: UART Write Failed");
			}
		} 
		else 
		{
			if(ST_UART_PRINT_IO_REPORTING == st_uart_io_reporting)
			{
				printTerminalf("test_uart_driver_tx_rx_int: Write Success:%d\n", actualLen);	
			} 
			else 
			{
				strcpy(io_status_buffer, "test_uart_driver_tx_rx_int: Write Success");
			}
		}
	}
	status = UART_SUCCESS;
	return (status);
}
