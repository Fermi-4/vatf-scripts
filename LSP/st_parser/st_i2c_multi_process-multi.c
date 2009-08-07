/*************************************************************************
**+--------------------------------------------------------------------+**
**|                                   ****                             |**
**|                                   ****                             |**
**|                                   ******o***                       |**
**|                             ********_///_****                      |**
**|                             ***** /_//_/ ****                      |**
**|                             ** ** (__/ ****                        |**
**|                             *********                              |**
**|                             ****                                   |**
**|                             ***                                    |**
**|                                                                    |**
**| Copyright (c) 1998-2005 Texas Instruments Incorporated             |**
**| ALL RIGHTS RESERVED                                                |**
**|                                                                    |**
**| Permission is hereby granted to licensees of Texas Instruments     |**
**| Incorporated (TI) products to use this computer program for sole   |**
**| purpose of implementing a licensee product based on TI products.   |**
**| No other rights to reproduce, use, or disseminate this computer    |**
**| program, whether in part or in whole, are granted.                 |**
**|                                                                    |**
**| TI makes no representation or warranties with respect to the       |**
**| performance of this computer program, and specifically disclaims   |**
**| any responsibility for any damages, special or consequential,      |**
**| connected with the use of this program.                            |**
**|                                                                    |**
**+--------------------------------------------------------------------+**
* FILE:   	ST_I2C_Multi_Process.c - Extracted from ST_Multi_Process.c
*
* Brief:  	Generic multi-Processing routine.
*
* Platform: Generic
*
* Author: 	Aniruddha S Herekar
*
* History: 	Ver 0.1: Created 	- Aniruddha. S. Herekar.
* 			Ver 0.2:			- Aniruddha. S. Herekar.
* 								  Modified as per review comments.
			Ver 0.3:			- Shiva B Pujar modified the codes for I2C.
			Ver 0.4:			- Shiva B Pujar included the POSIX Thread codes.
*
*Comments:	Integrity of data is applications responsibility.
*			Modify the printfs, scanfs and function calls as per required
*			Change Process creation call as per OS (made as per LINUX)
*			For viewing this file use tab = 4 (se ts =4)
*
********************************************************************************/

/* Include required header files */
#include <pthread.h>
//#include <linux/spinlock.h>

#include "st_common.h"
#include "st_i2c.h"
#include "st_linuxdevio.h"
#define WRITEMODE                               0
#define READMODE                                1
#define WRITEREADMODE                           2
#define DEFAULT_MODE                            2

/* Data size defines */
#define WRITEREADDATA                           450
#define DEFAULT_PROCESS_NUM                     5                       /* Process number */
#define CHANNELNO                               2
#define DATASIZE_MAX                            10240
#define RAND_SLEEPMAX                           5



static void writetest(void);
static void readtest(void);
static void writereadtest(void);
static void ST_Multi_ProcThread_parser(void);

static Int32 processnum = DEFAULT_PROCESS_NUM;
static Int32 mode = DEFAULT_MODE;
static Int32 size = WRITEREADDATA;				/* Data size */
static Int32 g_led = 0x55;
static Int32 Thread_usage = 0;

void ST_Multi_ProcThread_parser(void)
{
	printTerminalf("MultiProcess: I2C:: Enter the Write (0), Read (1) or Write and Read (2) mode, Quit (3)\n");
    scanTerminalf("%d", &mode);

	if (3 == mode)
	{
		return;
	}

	printTerminalf("MultiProcess: I2C:: Enter number of bytes to Write / Read/ Write & Read\n");
    scanTerminalf("%d", &size);


	printTerminalf("MultiProcess: I2C:: Enter Led value to Write & Read\n");
    scanTerminalf("%d", &g_led);

	printTerminalf("MultiProcess: I2C:: Enter number of write processes to execute\n");
   	scanTerminalf("%d", &processnum);
	
}

/* MultiProcess routine for Write and Read */

void ST_I2C_MultiProcess_parser(void)
{
	Int32 loop = 0, Pid;

	ST_Multi_ProcThread_parser();
	
	for(loop = 0; loop<processnum; loop++)
	{	
			
		switch(fork())
		{
			case 0: // Child Process
			{
				switch (mode)	{
					case 0:	printTerminalf("\nWrite Test\n");
							writetest();
							exit(0);
					case 1: printTerminalf("\nRead Test\n");
							readtest();
							exit(0);
					case 2: printTerminalf("\nWrite & Read Test\n");
							writereadtest();
							exit(0);
				}//End of Inner switch.		
			} //End of Case 0 
			break;
			
			case -1: // Child process creation Failed
			{
					printTerminalf("I2C:: multiProcess_parser: Error creating Process\r\n");
    		}
			break;										/* Break if process fails */	

			default: // Parent process	
				if(g_led >= 256)
			    		g_led = 0;
			    	else
					g_led += 1;		
			    		
				Pid = wait(NULL);
				printTerminalf("\n\nCOMPLETED::I2C:: multiProcess_parser: Write Process %d COMPLETED\n\n", Pid);
			break;
		} // end of Switch
	} // End of For
	
	return;
}

/* Multi-Thread routine for Write and Read */

void ST_I2C_MultiThread_parser(void)
{
	Int32 loop = 0;
	pthread_t Thread[20] = {0, };
	int *Thrd_retPtr;
	int Failiure_Flg=0;

	ST_Multi_ProcThread_parser();

	Thread_usage = 1;
	for(loop = 0; loop<processnum; loop++)
	{	
			
		switch (mode)	{
				case 0:	printTerminalf("\nWrite Test\n");
						if( 0 < pthread_create(&Thread[loop], NULL, (void *) writetest, NULL))
							printTerminalf("Creating the writetest Thread failed\n");
						break;

				case 1: printTerminalf("\nRead Test\n");
						if( 0 < pthread_create(&Thread[loop], NULL, (void *) readtest, NULL))
							printTerminalf("Creating the readtest Thread failed\n");
						break;
			
				case 2: printTerminalf("\nWrite & Read Test\n");
						if( 0 < pthread_create(&Thread[loop], NULL, (void *) writereadtest, NULL))
							printTerminalf("Creating the writetest Thread failed\n");
						break;

		}//End of switch.		
		
//		if(g_led >= 256)
//			g_led = 0;
//		else
//        		g_led += 1;
	
	} // End of For

/* Waiting for all the Spawned Threads to complete */
	
	for(loop = 0; loop<processnum; loop++)	
	{	
		printTerminalf("I am in Parent Thread Waiting for Thread ID=%d\n",Thread[loop]);		
		if(pthread_join(Thread[loop], (void **)&Thrd_retPtr))
		{	
			printTerminalf("Pthread_join Failed \n");			
		}
		else
		{
			printTerminalf("Thread ID=%d ,returned=%d\n",Thread[loop],*(Thrd_retPtr));
			if ((*(Thrd_retPtr))==ST_FAIL)
			{
				Failiure_Flg=1;
				printTerminalf("Thread ID=%d Failed\n",Thread[loop]);
			}
		}
	}

	// Reset the Thread Usage Flag
	Thread_usage=0;

	if(Failiure_Flg)
		printTerminalf("ST_BLK_MultiThread_parser:Completed with Failiure\n");
	else
		printTerminalf("ST_BLK_MultiThread_parser:Completed Successfully\n");		

//	pthread_join(Thread, NULL); // Used for Sync - similar to wait() call.
	printTerminalf("COMPLETED::I2C:: Multi-Thread_parser\n");
		
	return;
}

/***************************************************************************
 * Function		- ST_getTask_id
 * Functionality	- Gets the task ID dependingon whether a thread or a Prcess respectively 
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
static unsigned int ST_getTask_id(int Thread_usage)
{
	return((Thread_usage==1)?pthread_self():getpid());
}


/* Write Process */
static void writetest(void)
{
	Int32 ST_I2C_Fd;
	Uint8 buff[2] = {0x0, 0x0};
	Uint8 wBuf[MAX_I2C_DATASIZE] ;
	Int32 i=0;

	extern Int32 SlaveAddress;
	Int32 AddrFmt =0;
	SlaveAddress = I2C_MSP_ADDR;
	
	for(i= 0; i< MAX_I2C_DATASIZE; i++)			
				wBuf[i] = 'a'+ (i %26);
	
	
	if(ST_PASS != ST_Open(I2C_DEV, WRITEREADMODE, &ST_I2C_Fd))
		printTerminalf("ST_Open: writetest: Open Failed\n");
	else
		printTerminalf("Success: ST_Open: writetest: Open Success\n");

	if( ioctl( ST_I2C_Fd, I2C_TENBIT, AddrFmt) < 0)
		perror("Ioctl I2C_TENBIT Failed: ");
	else
		printf("Success: ST_Ioctl: The Slave address is in %s bit address format\n",((AddrFmt == 0)?"SEVEN" : "TEN"));

	if( ioctl( ST_I2C_Fd, I2C_SLAVE, SlaveAddress) < 0)
		perror("ST_Ioctl: I2C_SLAVE: Ioctl Failed: ");
	else
		printTerminalf("Success: ST_Ioctl: Slave address is:\t%d\n", SlaveAddress);					
		
	buff[0] = 0x03; //msp-led
	buff[1] = g_led;		
	if(ST_PASS != ST_Write(ST_I2C_Fd, buff, 2))	{
		printTerminalf("ST_Write, Write LED Failed\n");
		if(ST_PASS != ST_Close(ST_I2C_Fd))
				printTerminalf("Failed: writetest Success: ST_Close, Close Failed\n");
		else
			printTerminalf("Success: writetest Success: ST_Close: Close Success\n");
	
	}
	else
		printTerminalf("ST_Write, Write LED %d Success PID %d\n", g_led, ST_getTask_id(Thread_usage));	
	
	g_led += 8;

	if(ST_PASS != ST_Close(ST_I2C_Fd))
		printTerminalf("Failed: writetest Success: ST_Close, Close Failed\n");
	else
		printTerminalf("Success: writetest Success: ST_Close: Close Success\n");

	return;	
}


/* Read Process */

static void readtest(void)
{
	Int32 ST_I2C_Fd;
	Uint8 rBuff[1] = {0x0};
	Uint8 buff[2] = {0, };
	//Int32 i=0;

	extern Int32 SlaveAddress;
	Int32 AddrFmt =0;
	SlaveAddress = I2C_MSP_ADDR;
			
	if(ST_PASS != ST_Open(I2C_DEV, WRITEREADMODE, &ST_I2C_Fd))
		printTerminalf("ST_Open: readtest: Open Failed\n");
	else
		printTerminalf("Success: ST_Open: readtest: Open Success\n");

	if( ioctl( ST_I2C_Fd, I2C_TENBIT, AddrFmt) < 0)
		perror("Ioctl I2C_TENBIT Failed: ");
	else
		printf("Success: ST_Ioctl: The Slave address is in %s bit address format\n",((AddrFmt == 0)?"SEVEN" : "TEN"));

	if( ioctl( ST_I2C_Fd, I2C_SLAVE, SlaveAddress) < 0)
		perror("ST_Ioctl: I2C_SLAVE: Ioctl Failed: ");
	else
		printTerminalf("Success: ST_Ioctl: Slave address is:\t%d\n", SlaveAddress);			
		

	buff[0] = 0x03; //msp-led
	if(ST_PASS != ST_Write(ST_I2C_Fd, buff, 1))	{
		printTerminalf("ST_Write, Write LED Failed\n");
		if(ST_PASS != ST_Close(ST_I2C_Fd))
			printTerminalf("Failed: readtest Success: ST_Close, Close Failed\n");
		else
			printTerminalf("Success: readtest Success: ST_Close: Close Success\n");
	}	
	if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, 1))	{
			printTerminalf("ST_Read, Read LED Failed\n");
			if(ST_PASS != ST_Close(ST_I2C_Fd))
				printTerminalf("Failed: readtest Success: ST_Close, Close Failed\n");
			else
				printTerminalf("Success: readtest Success: ST_Close: Close Success\n");
	}
	else
	{
		printTerminalf("I2C: Read: LED Success PID %d\n", ST_getTask_id(Thread_usage));
		printf("\n");
		printTerminalf("LED: Data Read is :\t%d\n", rBuff[0]);
	}		
	
	if(ST_PASS != ST_Close(ST_I2C_Fd))
		printTerminalf("Failed: readtest Success: ST_Close, Close Failed\n");
	else
		printTerminalf("Success: readtest Success: ST_Close: Close Success\n");

	return;	
}

/* Write and Read Process */

static void writereadtest(void)
{
	Int32 ST_I2C_Fd;
	Uint8 rBuff[1] = {0x0};
	Uint8 buff[2] = {0x0, 0x0};
	Uint8 wBuf[MAX_I2C_DATASIZE] ;
	Int32 i=0;
	Int32 spin_lock_rtn=0;
	//pthread_spinlock_t lock;
//spinlock_t lock;

	extern Int32 SlaveAddress;
	Int32 AddrFmt =0;
	SlaveAddress = I2C_MSP_ADDR;
		
	if(ST_PASS != ST_Open(I2C_DEV, WRITEREADMODE, &ST_I2C_Fd))
		printTerminalf("ST_Open: writereadtest: Open Failed\n");
	else
		printTerminalf("Success: ST_Open: writereadtest: Open Success\n");

	if( ioctl( ST_I2C_Fd, I2C_TENBIT, AddrFmt) < 0)
		perror("Ioctl I2C_TENBIT Failed: ");
	else
		printf("Success: ST_Ioctl: The Slave address is in %s bit address format\n",((AddrFmt == 0)?"SEVEN" : "TEN"));

	if( ioctl( ST_I2C_Fd, I2C_SLAVE, SlaveAddress) < 0)
		perror("ST_Ioctl: I2C_SLAVE: Ioctl Failed: ");
	else
		printTerminalf("Success: ST_Ioctl: Slave address is:\t%d\n", SlaveAddress);				
//sleep(5);			
#if 0
//lock the folling write and read opereation so that the read value reflect the written value
spin_lock_rtn = spin_lock_init(&lock);
if (spin_lock_rtn != 0) perror("spin init failed. ");

spin_lock_rtn = spin_lock(&lock);
if (spin_lock_rtn != 0) perror("spin lock failed. ");
#endif

	g_led += 8;
        buff[0] = 0x03; //msp-led
        buff[1] = g_led;
        if(ST_PASS != ST_Write(ST_I2C_Fd, buff, 2))     {
                printTerminalf("ST_Write, Write LED Failed\n");
                if(ST_PASS != ST_Close(ST_I2C_Fd))
                                printTerminalf("Failed: writetest Success: ST_Close, Close Failed\n");
                else
                        printTerminalf("Success: writetest Success: ST_Close: Close Success\n");

        }
        else
                printTerminalf("ST_Write, Write LED %d Success PID %d\n", g_led, ST_getTask_id(Thread_usage));

//usleep(1);
		
        buff[0] = 0x03; //msp-led
        if(ST_PASS != ST_Write(ST_I2C_Fd, buff, 1))     {
                printTerminalf("ST_Write, Write LED Failed\n");
                if(ST_PASS != ST_Close(ST_I2C_Fd))
                        printTerminalf("Failed: readtest Success: ST_Close, Close Failed\n");
                else
                        printTerminalf("Success: readtest Success: ST_Close: Close Success\n");
        }
//sleep(1);
        if(ST_PASS != ST_Read(ST_I2C_Fd, rBuff, 1))     {
                        printTerminalf("ST_Read, Read LED Failed\n");
                        if(ST_PASS != ST_Close(ST_I2C_Fd))
                                printTerminalf("Failed: readtest Success: ST_Close, Close Failed\n");
                        else
                                printTerminalf("Success: readtest Success: ST_Close: Close Success\n");
        }
        else
        {
                printTerminalf("I2C: Read: LED Success PID %d\n", ST_getTask_id(Thread_usage));
        //        printf("\n");
                printTerminalf("LED: Data Read is :\t%d\n", rBuff[0]);
        }

#if 0
spin_lock_rtn = spin_unlock(&lock);
if (spin_lock_rtn != 0) perror("spin unlock failed. ");

//spin_lock_rtn = pthread_spin_destroy(&lock);
//if (spin_lock_rtn != 0) perror("spin destroy failed. ");
#endif
//	g_led += 8;


//sleep(5);
	if(ST_PASS != ST_Close(ST_I2C_Fd))
		printTerminalf("Failed: writereadtest Success: ST_Close, Close Failed\n");
	else
		printTerminalf("Success: writereadtest Success: ST_Close: Close Success\n");


	return;		
}
