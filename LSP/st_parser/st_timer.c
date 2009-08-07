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

/** \file   st_timer.c
    \brief  DaVinci ARM Linux PSP System Timer Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created - Linux Timer Test Code 
                
 */



#include "st_timer.h"
#include <sys/time.h>
#include <time.h>
#include <linux/types.h>

void timer_parser(void)
{
	char cmd[50]; 
	int i =0;	
	char cmdlist[][40] = {
		"get_time",
		"get_sec",
		"set_time",
        "set_sec",
        "get_clock",
		"stress",
		"stress_sec",
		"1mloop",
		"stress_1m",
		"exit",
		"help"
	};

	while(1)
	{
		i = 0;
		printTerminalf("Timer>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting Timer Parser to Main Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_timer_gettime();
		} 
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_timer_gettime_sec();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
        {
            test_timer_settime();
        }
        else if(0 == strcmp(cmd, cmdlist[i++]))
        {
            test_timer_settime_sec();
        }
        else if(0 == strcmp(cmd, cmdlist[i++]))
        {
            test_timer_get_clock_sec();
        }
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_timer_stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_timer_stress_sec();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_timer_loop_1min();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
        {
        	test_timer_loop_1min_stress();
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
} /* End of timer_parser() */



void test_timer_gettime(void)
{
	struct timeval time;

	gettimeofday(&time,NULL);

	printTerminalf("test_timer_gettime:: Time =%dus\n", time.tv_usec);
}

void test_timer_get_clock_sec(void)
{
    clock_t rtn_clock;

    rtn_clock = clock();
    
    if (rtn_clock != (clock_t)-1) {
        printTerminalf("test_timer_get_clock_sec:: tick = %ds\n", rtn_clock);
        printf("test_timer_get_clock_sec:: Time = %fs\n", (float)rtn_clock/CLOCKS_PER_SEC);    
    //    printf("test_timer_get_clock_sec:: Time = %fs\n", 0.5);    
    }
    else{
        printTerminalf("test_timer_get_clock_sec:: can not get return value from clock()");
    }
    sleep(5);

    rtn_clock = clock();

    if (rtn_clock != (clock_t)-1) {
        printTerminalf("test_timer_get_clock_sec:: after sleep 5s, tick = %ds\n", rtn_clock);
    }
    else{
        printTerminalf("test_timer_get_clock_sec:: can not get return value from clock()");
    }

}


void test_timer_gettime_sec(void)
{
	struct timeval time;

	gettimeofday(&time,NULL);

	printTerminalf("test_timer_gettime_sec:: Time =%ds\n", time.tv_sec);
}



void test_timer_settime(void)
{
	//struct timeval time_old;
    struct timeval time;
    Uint32 time_val = 0;
    int status = TIMER_FAIL;


    gettimeofday(&time,NULL);

	printTerminalf("Enter the time in micro-seconds\nTime set>");
    scanTerminalf("%d",&time_val);

    time.tv_usec = time_val;

    status = settimeofday(&time,NULL);

    if (TIMER_SUCCESS == status)
    {
        printTerminalf("test_timer_settime:: Time =%dus\n", time.tv_usec);
    }
    else
    {
		 printTerminalf("test_timer_settime:: Can not set microsecond");
	}
	test_timer_gettime();
}



void test_timer_settime_sec(void)
{
    struct timeval time_old;
	struct timeval time;
	Uint32 time_val = 0;
	int status = TIMER_FAIL;

    gettimeofday(&time_old,NULL);

	printTerminalf("Enter the time in seconds\nTime set>");
	scanTerminalf("%d",&time_val);

	time.tv_sec = time_val;

	status = settimeofday(&time,NULL);
	
	if (TIMER_SUCCESS == status)
	{
		printTerminalf("test_timer_settime_sec:: Time =%ds\n", time.tv_sec);
	}
	else
	{
	    printTerminalf("test_timer_settime_sec:: can not set second");
	}
	test_timer_gettime_sec();
}









void test_timer_stress(void)
{
	Uint32 i = 0;
	Uint32 loopcount = 1;
	struct timeval time;

	printTerminalf("Timer>> Enter the loop count value: \nTimer>>");
	scanTerminalf("%d",&loopcount);

	for(i=0; i<loopcount; i++)
	{
		gettimeofday(&time,NULL);

		printTerminalf("test_timer_stress:: Time =%dus\n", time.tv_usec);
	}
}



void test_timer_stress_sec(void)
{
	Uint32 i = 0;
	Uint32 loopcount = 1;
	struct timeval time;

	printTerminalf("Timer>> Enter the loop count value: \nTimer>>");
	scanTerminalf("%d",&loopcount);

	for(i=0; i<loopcount; i++)
	{
		sleep(1);
		gettimeofday(&time,NULL);

		printTerminalf("test_timer_stress_sec:: Time =%ds\n", time.tv_sec);
	}
}





void test_timer_loop_1min(void)
{
    struct timeval time;
	Uint32 total_time = 0;
	Uint32 init_time = 0;

	gettimeofday(&time,NULL);
	init_time = time.tv_sec;

	while(1)
	{
    	printTerminalf("test_timer_loop_1min:: Time =%ds\n", time.tv_sec);
	
		gettimeofday(&time,NULL);
		
		total_time = + time.tv_sec;

		if (60 <= (total_time - init_time))
			break;
	}

	printTerminalf("test_timer_loop_1min:: Total Time = %ds, Initial Time = %ds, Time =%ds\n", total_time, init_time, time.tv_sec);
}



void test_timer_loop_1min_stress(void)
{
    struct timeval time;
    Uint32 total_time = 0;
    Uint32 init_time = 0;
	Uint32 loopcount =1;
	Uint32 i =0;

	printTerminalf("Enter the loopcount\nLoop count>");
    scanTerminalf("%d",&loopcount);

	for(i=0; i<loopcount; i++)
	{
	    gettimeofday(&time,NULL);
    	init_time = time.tv_sec;

    	while(1)
    	{
        	printTerminalf("test_timer_loop_1min_stress:: Time =%ds\n", time.tv_sec);

        	gettimeofday(&time,NULL);

        	total_time = + time.tv_sec;

        	if (60 <= (total_time - init_time))
            	break;
    	}

    	printTerminalf("test_timer_loop_1min_stress:: Total Time = %ds, Initial Time = %ds, Time =%ds, Loop = %d\n", total_time, init_time, time.tv_sec, i);

	}

}



