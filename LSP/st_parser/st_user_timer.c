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

/** \file   user_timer.c
    \brief To verify the   ( Timer64 used as a unchained 32 bit Dual Timer of which 
    	TIM12 Programmed is used for Linux OS Ticks )

    This file contains OS Timer Test  code (User Level).

    NOTE: THIS FILE IS PROVIDED ONLY FOR INITIAL DEMO RELEASE AND MAY BE
          REMOVED AFTER THE DEMO OR THE CONTENTS OF THIS FILE ARE SUBJECT
          TO CHANGE.

    (C) Copyright 2004, Texas Instruments, Inc

    @author     	Anand Patil
    @version    0.1 -
    			Created on 28/09/05 
                Assumption: Channel and ParamEntry has 1 to 1 mapping
 */

#include<stdio.h>
#include <sys/time.h>
#include <time.h>
#include <linux/Times.h>

/* gettimeofday uses the timer->offset()  function to get the "usec" data */
/* settimeofday sets the "jiffies" */





main()
{


	struct timeval time;
	struct timezone time_zone;
	struct tms tim_buf;	
	struct tm mktim;
	int err,i,count;
	unsigned long previous_sec;
	time_t time_sec;


/* verify the times() which returns the current  process time  "at the begining" */

	printf("verify the times() which returns the current  process time at the begining\n");
	err= times(&tim_buf);
	if(err==-1)
	{
			printf("\"times()\" failed\n");
			perror("times");
			exit(1);
	}


	printf("\"times() \" Returns= %u\n", err);
	printf(" \"times()\"  User Time in OS Ticks=%u\t  System Time in  OS Ticks=%u\n", tim_buf.tms_utime,tim_buf.tms_stime);
	printf(" \"times()\" Child User Time in OS Ticks=%ums\t  Child System Time in OS Ticks=%ums\n", tim_buf.tms_cutime,tim_buf.tms_cstime);

/* verify the times() ends */

	
/* TC # 1 verify initial secs returned by gettimeofday() -------starts */


/* initially  verify gettimeofday()  */
	
	printf(" initially  verify gettimeofday()\n");
	err=gettimeofday( &time, &time_zone);
	if(err!=0)
	{
		printf("gettimeofday failed\n");
		exit(1);
	}

	printf("Time in Seconds=%us\t Time in Microseconds=%us\n", time.tv_sec,time.tv_usec);
	printf("type of dst correction=%us\t Minutes west of Greenwich =%us\n", time_zone.tz_dsttime,time_zone.tz_minuteswest);


/*  gettimeofday() ends */



/* "just verify  - no .of clock ticks using "clock" */
	printf("just verify  - no .of clock ticks using clock()\n");
	printf(" \"clock() \"  %u\n",	 clock());

	
/* just verify "clock"  ends */


/* TC # 1 verify initial secs returned by gettimeofday() -------ends */



/* TC # 2 verify settimeofday -------starts */
	
/* set timeof day to verify "setting" */ 
	printf(" settimeofday to verify setting\n");	
	
	printf("Enter the settimeofday value\n");
	scanf("%d",&time.tv_sec);	
	printf("Setting Time Value=%d\n",time.tv_sec);	
	time.tv_usec=0;
	previous_sec=time.tv_sec;
	time_zone.tz_dsttime=0;
	time_zone.tz_minuteswest=0;
	
	err=settimeofday(&time,&time_zone);
	if(err!=0)
	{
			printf("settimeofday failed\n");
			perror("settimeofday");
			exit(1);
	}

/* set timeof day ends  */ 


	err=gettimeofday(&time,&time_zone);
	if(err!=0)
	{
			printf("gettimeofday failed\n");
			perror("gettimeofday");
			exit(1);
	}

	printf("Verify SetTime Value\n");		
	printf("Time in Seconds=%us\t Time in Microseconds=%us\n", time.tv_sec,time.tv_usec);
	printf("type of dst correction=%u\t Minutes west of Greenwich =%u\n", time_zone.tz_dsttime,time_zone.tz_minuteswest);



	
/* TC # 2 verify settimeofday -------ends  */



/* TC # 3 verify Clock sync with windows hosts clock -------starts */

	printf("verify Clock sync with windows hosts clock -------starts\n");
	printf("Enter The Timer count (in secs)\n");
	scanf("%d",&count);

	for (i=0;time.tv_sec<count;i++)
	{
			
/* verify gettimofday() values returned  for our os ticks */
		err=gettimeofday(&time,&time_zone);
		if(err!=0)
		{
				printf("gettimeofday failed\n");
				perror("gettimeofday");
				exit(1);
		}

		if(time.tv_sec!=previous_sec)
		{
			printf(" \"gettimeofday()\"Time in Seconds=%u\t Time in Microseconds=%u\n", time.tv_sec,time.tv_usec);
			printf("\"gettimeofday()\" type of dst correction=%u\t Minutes west of Greenwich =%u\n", time_zone.tz_dsttime,time_zone.tz_minuteswest);
		}
/* verify gettimofday() ends */


#if 0
	
/* verify time()  retruned elapsed secs  */
			err=time(&time_sec);
			if(err!=0)
		{
				printf("\"time()\" failed\n");
				perror("time");
				exit(1);
		}

		printf("  \"time()\" Time in Seconds=%u\n", time_sec);
		
/* verify time() ends */
#endif		
	
		previous_sec=time.tv_sec;

	}

/* TC # 3 verify Clock sync with windows hosts clock -------ends */


/* TC # 4 verify  times()  , Clock Ticks -------starts */


 /* Clock Ticks  verify ---- */
	printf("Verify Clock Tick Sync\n");
 	printf("Current Clock Ticks =%u\n",clock());
	printf("Enter The ClockTick count  \n");
	scanf("%d",&count);

	previous_sec=clock();
	
	for (i=0;err<count;i++)
	{
		err= clock();
		if(err==-1)
		{	
				printf("\"clock()\" failed\n");
				perror("clock");
				exit(1);
		}

		if(err!=previous_sec)
		printf("\"clock() \" Clock Ticks = %u\n", err);
		
		previous_sec=err;	
	}

/*Clock Ticks end -- */ 



/* "just verify "clock_t"  - no .of clock ticks */

	printf (" \"clock()\" %d\n", clock());
/* "just verify "clock_t"  ends */
	

/* verify the times() ends */


/*verify the mktime() , calendar time function */

                           mktim.tm_sec =0;         /* seconds */
                           mktim.tm_min=0;         /* minutes */
                           mktim.tm_hour=0;        /* hours */
                          mktim.tm_mday=1;        /* day of the month */
                          mktim.tm_mon=1;         /* month */
                           mktim.tm_year=2005;        /* year */
                           mktim.tm_wday=1;        /* day of the week */
                           mktim.tm_yday=1;        /* day in the year */
                          mktim.tm_isdst=0;       /* daylight saving time */




	mktime(&mktim);

		err=gettimeofday(&time,&time_zone);
		if(err!=0)
		{
				printf("gettimeofday failed\n");
				perror("gettimeofday");
				exit(1);
		}

		printf(" \"gettimeofday()\"Time in Seconds=%u\t Time in Microseconds=%u\n", time.tv_sec,time.tv_usec);
		printf("\"gettimeofday()\" type of dst correction=%u\t Minutes west of Greenwich =%u\n", time_zone.tz_dsttime,time_zone.tz_minuteswest);



/* TC # 4 verify  times()   -------ends */

/* verify the times() which returns the current  process time  "at the End" */

	printf("verify the times() which returns the current  process time at the Ends\n");
		
	err= times(&tim_buf);
	if(err==-1)
	{
			printf("\"times()\" failed\n");
			perror("times");
			exit(1);
	}


	printf("\"times() \" Returns= %u\n", err);
	printf(" \"times()\"  User Time in OS Ticks=%u\t  System Time in  OS Ticks=%u\n", tim_buf.tms_utime,tim_buf.tms_stime);
	printf(" \"times()\" Child User Time in OS Ticks=%ums\t  Child System Time in OS Ticks=%ums\n", tim_buf.tms_cutime,tim_buf.tms_cstime);

/* verify the times() ends */

		


}


	





