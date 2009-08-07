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

/** \file   st_pwm.c
    \brief  DM350/ DaVinci ARM Linux PSP System PWM Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created - Linux PWM Test Code Integration
                
 */


#include "st_pwm.h"
#include "sys/time.h"
#include <signal.h>

#define PSP_PWM_NUM_INSTANCES PWM_MINORS
#define DELAY_CNT 10000

int fd_pwm = -1;


Uint32 st_pwm_instance = 0; /* PSP_CONSOLE_PWM_NUMBER PWM is 1 */

Uint32 st_pwm_driver[PSP_PWM_NUM_INSTANCES];

static Uint32 instflag[PSP_PWM_NUM_INSTANCES] = {0, };


static void test_pwm_driver_ioctl(int cmd, Uint32 data);

//extern Uint32 davinci_gettimeoffset(void);


void PWM_Hand(int s)	{
	printf("This is the Signal Handler and SIGNO is:\t%d\n",s);
}


void pwm_parser(void)
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
		"help"
	};

	while(1)
	{
		i = 0;
		printTerminalf("PWM>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting PWM mode to Main Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_update();
		} 
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_open();
		}
		else if (0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_general_open();
		}		
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_close();
		}		
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_stability();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_ioctl_parser();
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
} /* End of pwm_parser() */


/* Need to add Loopback after investigation*/

void test_pwm_ioctl_parser(void)
{
	char cmd[50] = {0}; 
	int i =0;	
	char cmdlist[][40] = {
		"set_mode",
		"set_period",
		"set_pw",
		"set_rpt_cnt",
                "start",		
		"stop",
                "set_idle",
                "set_1phase",
                "exit",
                "help"
	};

	while(1)
	{
		i = 0;
		printTerminalf("PWM::IOCtl>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting IOCtl mode to PWM Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_set_mode();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_set_period();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_set_pulse_width();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_set_repeat_count();
		}	
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_start();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_pwm_driver_stop();
		}
                else if(0 == strcmp(cmd, cmdlist[i++]))
                {
                        test_pwm_driver_set_idle();
                }
                else if(0 == strcmp(cmd, cmdlist[i++]))
                {
                        test_pwm_driver_set_first_phase();
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
} /* End of pwm_ioctl_parser() */


void test_pwm_driver_update(void)
{
	char cmd [CMD_LENGTH];
	char cmdlist[][40] = {
		"instance",
		"exit",
		"help"
	};
	while(1)
	{
		printTerminalf("Enter Update Parameter\npwm::update> ");
		scanTerminalf("%s", cmd);

		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting PWM IO mode to PWM Parser:\n");
			break;
		}
		if(0 == strcmp("instance", cmd)) 
		{
			test_pwm_update_driver_instance();
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
		}
	}

	//printTerminalf("Update Successful\n");
	return;
}




void test_pwm_driver_general_open(void)
{
        Int32 attr = 1;
        char dev_name[100] = {0, };     /* Device Name */
        Int8 status = PWM_FAILURE;

        printTerminalf("test_pwm_driver_general_open: Enter the device to open (/dev/pwm)\n");
        scanTerminalf("%s", &dev_name);

        printTerminalf("test_pwm_driver_general_open: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
        scanTerminalf("%d", &attr);

        if (0 == st_pwm_instance)
        {
                /* Check device open */

                if (0 == instflag[st_pwm_instance])
                {
                        fd_pwm = open(dev_name, attr | O_NOCTTY);
                        instflag[st_pwm_instance] =1;
                }
                else
                	fd_pwm = PWM_NULL;
        }

        else
        {
                printTerminalf("test_pwm_driver_general_open: Invalid instance\n");
        }

        if( fd_pwm > PWM_SUCCESS)
        {
                st_pwm_driver[st_pwm_instance] = fd_pwm;
                printTerminalf("test_pwm_driver_general_open: Success:: Device = %s, fd=%d\n", dev_name,fd_pwm);
        }
        else
        {
                printTerminalf("test_pwm_driver_general_open: Failed:: Device = %s, fd=%d, status=%d\n", dev_name, fd_pwm, status);
        }
}



void test_pwm_update_driver_instance(void)
{
	Int32 local_instance = 0;
	Int32 previous_instance = st_pwm_instance;
	

	printTerminalf("test_pwm_update_driver_instance: Enter the Interface Number (0,1, 2)\npwm::update> ");
	scanTerminalf("%d", &local_instance);
	
	if(local_instance < PSP_PWM_NUM_INSTANCES)
	{
		st_pwm_instance = local_instance;
		printTerminalf("test_pwm_update_driver_instance: Setting st_pwm_instance to %d\n", st_pwm_instance);
	}
	else 
	{
		printTerminalf("test_pwm_update_driver_instance: Invalid Instance Number = %d\n", local_instance);
		printTerminalf("test_pwm_update_driver_instance: Maximum instances = %d (0 to %d)\n", PSP_PWM_NUM_INSTANCES, PSP_PWM_NUM_INSTANCES);
		printTerminalf("test_pwm_update_driver_instance: Setting the instance to previous instance %d\n", previous_instance);
		st_pwm_instance = previous_instance;
	}

	return;
}



void test_pwm_driver_open(void)
{
	Int32 attr = PWMRDWR;
	//int status = -1;
	char device_name [100];// = INSTANCE0;
    strcpy(device_name,"/dev/davinci_pwm0");	

	printTerminalf("test_pwm_driver_open: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
	scanTerminalf("%d", &attr);
	
	if (0 == st_pwm_instance)
	{
		if (1 != instflag[st_pwm_instance])
		{
			strcpy(device_name,"/dev/davinci_pwm0");
			//device_name[0] = "";//INSTANCE0;
			instflag[st_pwm_instance] =1;
		}
		else
		{
			strcpy(device_name,"/dev/davinci_pwm0");
			printTerminalf("test_pwm_driver_open: Device Instance already open. PWM Instance:%d, Device name = %s, fd = %d\n", st_pwm_instance, device_name, fd_pwm);
			return;
		}
	}
		
	else if (1 == st_pwm_instance)
	{
		if (2 != instflag[st_pwm_instance])
		{
			strcpy(device_name,"/dev/davinci_pwm1");
			//device_name[0] = INSTANCE1;
			instflag[st_pwm_instance] =2;
		}
		else
		{
			strcpy(device_name,"/dev/davinci_pwm1");
			printTerminalf("test_pwm_driver_open: Device Instance already open. PWM Instance:%d, Device name = %s, fd = %d\n", st_pwm_instance, device_name, fd_pwm);
			return;
		}
	}
	
	else if (2 == st_pwm_instance)
	{
		if (3 != instflag[st_pwm_instance])
		{
			strcpy(device_name,"/dev/davinci_pwm2");
			//device_name[0] = INSTANCE2;
			instflag[st_pwm_instance] =3;
		}
		else
		{
			strcpy(device_name,"/dev/davinci_pwm2");
			printTerminalf("test_pwm_driver_open: Device Instance already open. PWM Instance:%d, Device name = %s, fd = %d\n", st_pwm_instance, device_name, fd_pwm);
			return;
		}
	}

	else if (3 == st_pwm_instance)
	{
		if (4 != instflag[st_pwm_instance])
		{
			strcpy(device_name,"/dev/davinci_pwm3");
			//device_name[0] = INSTANCE3;
			instflag[st_pwm_instance] =4;
		}
		else
		{
			strcpy(device_name,"/dev/davinci_pwm3");
			printTerminalf("test_pwm_driver_open: Device Instance already open. PWM Instance:%d, Device name = %s, fd = %d\n", st_pwm_instance, device_name, fd_pwm);
			return;
		}
	}
	
	else
	{
		printTerminalf("test_pwm_driver_open: Invalid instance\n");
		return;
	}

	fd_pwm = open(device_name, attr);
	

	if( fd_pwm > 0)
	{
		st_pwm_driver[st_pwm_instance] = fd_pwm;
		printTerminalf("test_pwm_driver_open: Success PWM Instance:%d, Device name = %s, fd = %d\n", st_pwm_instance, device_name, fd_pwm);
	}
	else
   	{
		printTerminalf("test_pwm_driver_open: Failed PWM Instance:%d, Device name = %s, fd:%d\n", st_pwm_instance, device_name, fd_pwm);
		fd_pwm = PWM_NULL;
        st_pwm_driver[st_pwm_instance] = fd_pwm;
        instflag[st_pwm_instance] = 0;
	}
	
	return;
}


void test_pwm_driver_close(void)
{
	int status = -1;
	
	status = close(st_pwm_driver[st_pwm_instance]);
			
	if(status < PWM_SUCCESS) 
	{
		printTerminalf("test_pwm_driver_close: Failed PWM Instance:%d, fd = %d,  Errno:%d\n", st_pwm_instance, st_pwm_driver[st_pwm_instance], status);
	}
   	else
   	{
		printTerminalf("test_pwm_driver_close: Success PWM Instance:%d, fd = %d\n", st_pwm_instance, st_pwm_driver[st_pwm_instance]);
		st_pwm_driver[st_pwm_instance] = PWM_NULL;
                instflag[st_pwm_instance] = 0;

	}

	return;
}

void test_pwm_driver_set_mode(void)
{
	Uint32 new_mode = PWM_ONESHOT_MODE;
	int cmd = PWMIOC_SET_MODE;
	
	printTerminalf("Enter New pwm mode (0=one shot, 1=continuous)\npwm::mode> ");
	scanTerminalf("%d", &new_mode);

	test_pwm_driver_ioctl(cmd, new_mode);

	return;
}
// New functions added to support Idle_State_Output & First_Phase_value on 8/15/07

void test_pwm_driver_set_idle(void)
{
        Uint32 new_mode = 0;
        int cmd =  PWMIOC_SET_INACT_OUT_STATE;

        printTerminalf("Enter New Idle State Level (0=Low, 1=High)\npwm::idle> ");
        scanTerminalf("%d", &new_mode);

        test_pwm_driver_ioctl(cmd, new_mode);

        return;
}

void test_pwm_driver_set_first_phase(void)
{
        Uint32 new_mode = 0;
        int cmd =  PWMIOC_SET_FIRST_PHASE_STATE;

        printTerminalf("Enter First Phase  Level (0=Low, 1=High)\npwm::1phase> ");
        scanTerminalf("%d", &new_mode);

        test_pwm_driver_ioctl(cmd, new_mode);

        return;
}


// End of new functions added on 8/15/07
void test_pwm_driver_set_period(void)
{
	Uint32 new_period = 1;
	int cmd = PWMIOC_SET_PERIOD;
	
	printTerminalf("Enter New pwm period count (between 0 to 31)\npwm::period> ");
	scanTerminalf("%d", &new_period);

	test_pwm_driver_ioctl(cmd, new_period);

	return;
}


void test_pwm_driver_set_pulse_width(void)
{
	Uint32 new_width = 1;
	int cmd = PWMIOC_SET_DURATION;
	
	printTerminalf("Enter New pwm width count (between 0 to 31)\npwm::pulse width> ");
	scanTerminalf("%d", &new_width);

	test_pwm_driver_ioctl(cmd, new_width);

	return;
}


void test_pwm_driver_set_repeat_count(void)
{
	Uint32 new_count = 1;
	int cmd = PWMIOC_SET_RPT_VAL;
	
	printTerminalf("Enter New pwm pulse repeat count (between 0 to 31)\npwm::pulse repeat count> ");
	scanTerminalf("%d", &new_count);

	test_pwm_driver_ioctl(cmd, new_count);

	return;
}


void test_pwm_driver_start(void)
{
	Uint32 dummy = 0;
	int cmd = PWMIOC_START;

	test_pwm_driver_ioctl(cmd, dummy);

	return;
}


void test_pwm_driver_stop(void)
{
	Uint32 dummy = 0;
	int cmd = PWMIOC_STOP;

	test_pwm_driver_ioctl(cmd, dummy);

	return;
}



static void test_pwm_driver_ioctl(int cmd, Uint32 data)
{
	int status = -1;

	status = ioctl(st_pwm_driver[st_pwm_instance], cmd, &data);
	
	if (status < PWM_SUCCESS)
	{
		printTerminalf("test_pwm_driver_pwm_ioctl: Setting Failed. Status = %d\n", status);
	}
	else
		printTerminalf("test_pwm_driver_pwm_ioctl: IOCtl data value= %d\n", data);
	
	return;
}


static void test_pwm_driver_stability_loop(Uint32 period_counter, Uint32 value_counter)
{
	Uint32 i = 0;
	Uint32 j = 0;
	Uint32 k = 0;
	Uint32 l = 0;

	while (k < 2)
	{
		printTerminalf("test_pwm_driver_stability_loop: Setting mode = %d\n", k);

		test_pwm_driver_ioctl(PWMIOC_SET_MODE, k);
		for(j = 1; j <= period_counter; j++)
		{
			printTerminalf("test_pwm_driver_stability_loop: Setting period = %d\n", j);
			test_pwm_driver_ioctl(PWMIOC_SET_PERIOD, j);

			for(i = 1; i <= value_counter; i++)
			{
				for(l = 0; l < DELAY_CNT; l++)
				{
					
				}
				test_pwm_driver_ioctl(PWMIOC_STOP, 0);
				test_pwm_driver_ioctl(PWMIOC_SET_DURATION, i);
				test_pwm_driver_ioctl(PWMIOC_SET_RPT_VAL, i);
				test_pwm_driver_ioctl(PWMIOC_START, 0);			
			}
		}
		k++;
		
	}

}



void test_pwm_driver_stability(void)
{
	int status = -1;
	Uint32 loop_counter = 1;
	Uint32 period_counter = 32;
	Uint32 value_counter = 32;
	
	Uint32 attr = O_RDWR;
	char dev_name[100] = {0, };     /* Device Name */ 

	signal(SIGINT, PWM_Hand);


	test_pwm_driver_stability_loop(period_counter, value_counter);

	printTerminalf("test_pwm_driver_stability: Success:: Test is over\n");
}








void test_pwm_driver_performance(void)
{
	Uint32  loopcount = 1;
	Uint32 i = 0;	
	struct timeval time;
	Uint32 Start_Time = 0, Start_sec = 0;

	/* Enable timer to be added */

	gettimeofday(&time,NULL); 

	Start_sec = time.tv_sec;
    Start_Time = time.tv_usec;

	for(i=0; i<loopcount; i++)
	{
	 		
	}
		/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL); 

    printTerminalf("test_pwm_driver_performance: Timer value \nStart = %dus, End = %dus \nStart = %ds, End = %ds\n",Start_Time, time.tv_usec, Start_sec, time.tv_sec);

}
