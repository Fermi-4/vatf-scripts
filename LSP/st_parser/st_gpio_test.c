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

/** \file   ST_GPIO_Test.c
    \brief  Test Definitions for GPIO's 

    (C) Copyright 2006, Texas Instruments, Inc

    @author     Anand Patil
    @version    0.1 
    @date 		19/10/2006
                                
 */

#include "st_gpio_test.h"

			
/***********************************************************
 *    MUXING INFORMATION OF FEW GPIO'S LISTED
 *
 *
 *a)GPIO Pins Muxed and available on DC2 Connector of Davinci EVM
 *   MUX Info     :-  GIO_V33_[0...16]  muxed with EMAC and IEEE1394
 *   DEMUX Info :-  IEEE394=0 & EMAC=0 => 31 and 30 bits of PINMUX0 
 *   Pin Info       :-  Pin [3...23]=>GIO_V33_[0...16] on DC2 
 *
 *b)GPIO Pins Muxed and available on DC3 Connector of Davinci EVM
 *   MUX Info     :-  GIO_V18_[29...34]  muxed with McBSP Pins
 *   DEMUX Info :-  McBSP=0  => Bit 10 of PINMUX1
 *   Pin Info       :-  Pin [9,10]=>GIO_V18_[34,33] ,Pin [11,12]=>GIO_V18_[30,29]
 * 				 Pin [13,14]=>GIO_V18_[32,31]on DC3
 *
 *c) MUX Info     :-  GIO_V18_[42]  muxed with SPI_EN1/ATADIR
 *   DEMUX Info :-  ATAEN=0 & HDIREN=0 SPIEN =0  
 *				 => Bit 17 and 16 of PINMUX0  and Bit 8 of PINMUX 1
 *   Pin Info       :-  Pin [1]=>GIO_V18_[42] on DC3
 *
 *
 *
 ************************************************************/



 

/* Populated the variables with Default values */

//static int gio_tx=GIO_V18_42;//Mux information -> SPI/ATADIR/GPIO -> DEMUX -> [SPI (0) & ATAEN (0)  &  HDIREN (0) ] available on DC3 pin 1
static int gio_tx=0;//Mux information -> SPI/ATADIR/GPIO -> DEMUX -> [SPI (0) & ATAEN (0)  &  HDIREN (0) ] available on DC3 pin 1
static int opmode1=1;
static int trig1=1; //If it is polled mode Trigger is not configured 
static int dir1=0;
static int irq_num1=57;
//static int gio_rx=GIO_V18_29; //Mux information -> CLKX /GPIO -> DEMUX -> [McBSP (0) ] available on DC3 pin 12
static int gio_rx=1; //Mux information -> CLKX /GPIO -> DEMUX -> [McBSP (0) ] available on DC3 pin 12
static int opmode2=1;
static int trig2=0; //If it is polled mode Trigger is not configured 
static int dir2 =1;
static int irq_num2=58;
static int enble_loopbck=1;
static int data_cnt=10;

module_param(gio_tx,int,666 );
module_param(opmode1,int,666 );
module_param(trig1,int,666 );
module_param(dir1,int,666 );
module_param(irq_num1,int,666 );
module_param(gio_rx,int,666 );
module_param(opmode2,int,666 );
module_param(trig2,int,666 );
module_param(dir2,int,666 );
module_param(irq_num2,int,666 );
module_param(enble_loopbck,int,666 );
module_param(data_cnt,int,666 );




/* Global Variables */
struct ST_GPIOAttrs 	gST_GPIOObj[10];

int gST_GPIO_TxBuff[100];
int  gST_GPIO_RxBuff[100];



/***************************************************************************
 * Function		- ST_GPIO_LoopbackFunc
 * Functionality	- Perfroms external loop back operation ( writing 1 byte to gio_tx and reading from gio_rx)
 * Input Params	- ST_GPIOAttrs* gio_tx ,ST_GPIOAttrs* gio_rx, int count
 * Return Value	-  -1 on Failiure else 0
 * Note			- None
 ****************************************************************************/

int ST_GPIO_LoopbackFunc(struct ST_GPIOAttrs* gio_tx ,struct ST_GPIOAttrs* gio_rx, int count)
{
	int i=0;
	int toggle=0;
	int status=0;

/* Initalize TxBuffer */	
	for(i=0;i<count;i++)
	{
		gST_GPIO_TxBuff[i]=toggle;
		toggle=!(toggle);	
	}
/* Initalize RxBuffer */	
	for(i=0;i<count;i++)
		gST_GPIO_RxBuff[i]=0;




	
	for(i=0;i<count;i++)
	{


	/*Trigger Write Operation*/
		if(gST_GPIO_TxBuff[i]!=ST_GPIO_WriteData(gio_tx,gST_GPIO_TxBuff[i]))
		{
			printk("<1> ST_GPIO_LoopbackFunc:ST_GPIO_WriteData Operation failed at  %d\n", i);
			break;
		}
		
	/*Trigger Read Operation*/
		status= ST_GPIO_ReadData(gio_rx);

		if(status==ST_IN_PROGRESS)
			//whil(0){};	//wait(0);
			do {} while(0);
		else	
			gST_GPIO_RxBuff[i]=status;
			
	}


/*Data Integrity check */
	for(i=0;i<count;i++)
	{
		if(gST_GPIO_TxBuff[i]!=gST_GPIO_RxBuff[i])
		{
			printk("<1> ST_GPIO_LoopbackFunc: Data Mismatch at %d\n", i);
			return -1;
		}
	
	}

	return 0;		
}

/***************************************************************************
 * Function		- ST_GPIO_WriteData
 * Functionality	- Performs gio_set_gio operation
 * Input Params	- ST_GPIOAttrs* gio_tx ,int data
 * Return Value	- Output state
 * Note			- None
 ****************************************************************************/
int ST_GPIO_WriteData(struct ST_GPIOAttrs* gio_tx ,int data)
{
	gio_set_gio(gio_tx->gpio_num, data);

	return(gio_get_out(gio_tx->gpio_num));
	

}

/***************************************************************************
 * Function		- ST_GPIO_WriteData
 * Functionality	- Performs gio_get_in operation
 * Input Params	- ST_GPIOAttrs* gio_rx
 * Return Value	- Input state
 * Note			- None
 ****************************************************************************/
int ST_GPIO_ReadData(struct ST_GPIOAttrs* gio_rx)
{
	if(gio_rx->opmode==ST_POLLED)
	{
		return (gio_get_in(gio_rx->gpio_num));
	}	
	else
		return ST_IN_PROGRESS;

}



/***************************************************************************
 * Function		- ST_GPIO_Init
 * Functionality	- Initializes the TX and RX GPIO Objects with the Input parameters,
 				   Configures the GPIO's	
 				   Registers the IRQ's for both the GPIO's
 				   Triggers  External Loopback Operation for the GPIO's OR Continuous Toggle Output
 				    				   
 * Input Params	- int gio_tx,int opmode1,int trig1,int dir1, int irq_num1,int gio_rx,int opmode2,int trig2,int dir2 ,int irq_num2, int enble_loopbck, int data_cnt
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_GPIO_Init(int gio_tx,int opmode1,int trig1,int dir1, int irq_num1,int gio_rx,int opmode2,int trig2,int dir2 ,int irq_num2, int enble_loopbck, int data_cnt)
{
	int count=ST_GPIO_OBJECTS;
	int i=0;
	
	/*Configure Attributes for Object1*/
	gST_GPIOObj[0].gpio_num=gio_tx;
	gST_GPIOObj[0].opmode=opmode1;
	gST_GPIOObj[0].trig_edge=trig1;
	gST_GPIOObj[0].direction=dir1;
	gST_GPIOObj[0].irq_num=irq_num1;
	
	/*Configure Attributes for Object2*/
	gST_GPIOObj[1].gpio_num=gio_rx;
	gST_GPIOObj[1].opmode=opmode2;
	gST_GPIOObj[1].trig_edge=trig2;
	gST_GPIOObj[1].direction=dir2;
	gST_GPIOObj[1].irq_num=irq_num2;


	

#ifdef ST_SIMPLE	
	/*Configure  gio_tx*/
	gio_set_dir(gio_tx, dir1);
	
	if(opmode1!=ST_POLLED)
	{
		if(trig1==ST_RISING_EDGE)
			{	
				gio_set_rising_edge(gio_tx,1);
				printk("<1>  ST_GPIO_Config :Setting Rising Edge for GPIO : %d\n",gio_tx);

			}
		else
			{
				gio_set_falling_edge(gio_tx,1);
				printk("<1>  ST_GPIO_Config :Setting Falling Edge for GPIO : %d\n",gio_tx);
				
			}
	}
	

	/*Configure  gio_rx*/
	gio_set_dir(gio_rx, dir2);
	
	if(opmode1!=ST_POLLED)
	{
		if(trig1==ST_RISING_EDGE)
			{
				gio_set_rising_edge(gio_rx,1);
				printk("<1>  ST_GPIO_Config :Setting Rising Edge for GPIO : %d\n",gio_rx);
			}
		else
			{
				gio_set_falling_edge(gio_rx,1);
				printk("<1>  ST_GPIO_Config :Setting Falling Edge for GPIO : %d\n",gio_tx);
			}
	}

#endif 	


	/* MUXING OPERATION FOR BOTH TX AND RX TO BE INCORPORATED HERE */

	/* Muxing for GIO_V18_[42] */

	//ATAEN=0 & HDIREN=0 SPIEN =0 =>Reset  Bit 17 and 16 of PINMUX0  and Bit 8 of PINMUX 1
	PINMUX0&=(~((1<<16)|(1<<17)));	
	PINMUX1&=(~(1<<8));
	
	/* Muxing for GIO_V18_[29] */
	//McBSP=0  =>Reset  Bit 10 of PINMUX1
	PINMUX1&=(~(1<<10));


	
	for(i=0;i<count;i++)
	{
		ST_GPIO_Config(&gST_GPIOObj[i]);
		ST_GPIO_regIRQ(&gST_GPIOObj[i]);
	}


	

	if(enble_loopbck)
	{
		if((ST_GPIO_LoopbackFunc(&gST_GPIOObj[0],&gST_GPIOObj[1],data_cnt))<0)
			 printk("<1> ST_GPIO_Init : Data Mismatch\n");
		else
			printk("<1>  ST_GPIO_Init : Data Transfered Successfully\n");
			
	}
	else
	{
		ST_GPIO_ToggleOutput(&gST_GPIOObj[0]);
	}	

	for(i=0;i<count;i++)
	{
		ST_GPIO_GetDirRegInfo(gST_GPIOObj[i].gpio_num);
		ST_GPIO_GetOutDataRegInfo(gST_GPIOObj[i].gpio_num);
		ST_GPIO_GetInputDataRegInfo(gST_GPIOObj[i].gpio_num);
	}
	
	
}

/***************************************************************************
 * Function		- ST_GPIO_IRQ_RxHdlr
 * Functionality	- Interrupt Handler for RX GPIO's  
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

static irqreturn_t ST_GPIO_IRQ_RxHdlr(int irq, void *dev_id, struct pt_regs *regs)
{
	static int  count=0;
	unsigned long flags=0;

	#ifdef ST_GPIO_DEBUG
		printk("<1>  ST_GPIO_IRQ_RxHdlr : IRQ=%d \n",irq);
	#endif

// Temporary code , yet to be modified
/* 1. Process Interrupt and then clear it in INSTAT */
	
	if(gio_get_event(gST_GPIOObj[1].gpio_num))
	{
		int blank = 0;
		unsigned long *reg=NULL;
		unsigned long bit=0;

		//Process Interrupt , writing the data to the Rx Buffer
		gST_GPIO_RxBuff[count++]=gio_get_in(gST_GPIOObj[1].gpio_num);


		//Clear the Interrupt Status by Setting  the INTSTAT bit
		
		blank = (gST_GPIOObj[1].gpio_num >> 5) & 0x3;
		bit	= 1 << (gST_GPIOObj[1].gpio_num & 0x1F);

		reg = (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE+0x34+blank*0x28);
	
		local_irq_save(flags);
		*reg |= bit;
		local_irq_restore(flags);

	
	}
	else
		printk("<1>  ST_GPIO_IRQ_RxHdlr : No event raised for GPIO=%d \n", gST_GPIOObj[1].gpio_num);

	
	
}




/***************************************************************************
 * Function		- ST_GPIO_IRQ_TxHdlr
 * Functionality	- Interrupt Handler for TX GPIO's  
 * Input Params	- ST_GPIOAttrs *
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

static irqreturn_t ST_GPIO_IRQ_TxHdlr(int irq, void *dev_id, struct pt_regs *regs)
{
	#ifdef ST_GPIO_DEBUG
		printk("<1>  ST_GPIO_IRQ_TxHdlr : IRQ=%d \n",irq);
	#endif 
}




/***************************************************************************
 * Function		- ST_GPIO_regIRQ
 * Functionality	- Registers Handlers to the IRQ's of GPIO's by request_irq
 * Input Params	- ST_GPIOAttrs *
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_GPIO_regIRQ(struct ST_GPIOAttrs *gio)
{
	int status=0;
	int irq_flags=0;

	if(gio->direction)
	{
		status = request_irq(gio->irq_num, ST_GPIO_IRQ_RxHdlr,
				  irq_flags, "GPIO", 0);
		if (status < 0)
			printk("<1>  ST_GPIO_regIRQ : Failed to Register IRQ %d  \n",gio->irq_num);
	}

	else
	{
		status = request_irq(gio->irq_num, ST_GPIO_IRQ_TxHdlr,
				  irq_flags, "GPIO", 0);
		if (status < 0)
			printk("<1>  ST_GPIO_regIRQ : Failed to Register IRQ %d \n",gio->irq_num);
	}
		
		
}

/***************************************************************************
 * Function		- ST_GPIO_unregIRQ
 * Functionality	- Free Handlers o the IRQ's of GPIO's 
 * Input Params	- ST_GPIOAttrs *
 * Return Value	- None
 * Note			- None
 ****************************************************************************/
void ST_GPIO_unregIRQ(struct ST_GPIOAttrs *gio)
{
	int status=0;
	int irq_flags=0;

	if(gio->direction)
	{
		 free_irq(gio->irq_num, NULL);
			printk("<1>  ST_GPIO_regIRQ :  Freeing IRQ %d  \n",gio->irq_num);
	}

	else
	{
		free_irq(gio->irq_num, NULL);
			printk("<1>  ST_GPIO_regIRQ : Freeing  IRQ %d \n",gio->irq_num);
	}
		
		
}

/***************************************************************************
 * Function		- ST_GPIO_Config
 * Functionality	- Configures/Sets  the GPIO Attributes (Direction, Trigger Edge)  
 * Input Params	- ST_GPIOAttrs *
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_GPIO_Config(struct ST_GPIOAttrs *gio)
{
	
	gio_set_dir(gio->gpio_num,gio->direction);
	
	if(gio->opmode!=ST_POLLED)
	{
		if(gio->trig_edge==ST_RISING_EDGE)
			{
				gio_set_rising_edge(gio->gpio_num,1);
				printk("<1>  ST_GPIO_Config :Setting Rising Edge for GPIO : %d\n",gio->gpio_num);
			}
		else
			{
				gio_set_falling_edge(gio->gpio_num,1);
				printk("<1>  ST_GPIO_Config :Setting Falling Edge for GPIO : %d\n",gio->gpio_num);
			}
	}

}


/***************************************************************************
 * Function		- ST_GPIO_ToggleOutput
 * Functionality	- Perfroms Continous Write Operation with Data Toggled
 * Input Params	- ST_GPIOAttrs* gio_tx 
 * Return Value	- None 
 * Note			- None
 ****************************************************************************/

int ST_GPIO_ToggleOutput(struct ST_GPIOAttrs* gio_tx )
{
	int i=0;
	int toggle=0;
	int status=0;

	while(1)
	{


	/*Trigger Write Operation*/
		if(toggle!=ST_GPIO_WriteData(gio_tx,toggle))
		{
			printk("<1> ST_GPIO_LoopbackFunc:ST_GPIO_WriteData Operation failed at  %d\n", i);
			break;
		}

		toggle=!(toggle); //Toggle the Data
	}
	
}


/***************************************************************************
 * Function		- ST_GPIO_GetDirRegInfo
 * Functionality	- Consoles the Direction Regs of the GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_GPIO_GetDirRegInfo(int gio)
{
	volatile unsigned long *reg;
	int blank = (gio >> 5) & 0x3;
	int val =0;

	val=0x10+blank*0x28;

	
	reg= (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE+0x10+blank*0x28);

	switch(val)
	{
		default:
		case (0x10) : 
				printk("<1> GPIO direction 0 and 1 Banks:\t 0x%x\n", *reg);
				break;
				
		case (0x38):
				printk("<1> GPIO direction 2 and 3 Banks:\t 0x%x\n", *reg);
				break;
				
		case (0x60) :
				printk("<1> GPIO direction 4 and 5 Banks:\t 0x%x\n", *reg);
				break;
	}
				
		
}


/***************************************************************************
 * Function		- ST_GPIO_GetOutDataRegInfo
 * Functionality	- Consoles the Output state Regs of GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_GPIO_GetOutDataRegInfo(int gio)
{
	volatile unsigned long *reg;
	int blank = (gio >> 5) & 0x3;
	int val =0;

	val=0x14+blank*0x28;

	
	reg= (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE+0x14+blank*0x28);

	switch(val)
	{
		default:
		case (0x14) : 
				printk("<1> GPIO OutData 0 and 1 Banks:\t 0x%x\n", *reg);
				break;
				
		case (0x3C):
				printk("<1> GPIO OutData 2 and 3 Banks:\t 0x%x\n", *reg);
				break;
				
		case (0x64) :
				printk("<1> GPIO OutData  4 and 5 Banks:\t 0x%x\n", *reg);
				break;
	}
				
		
}


/***************************************************************************
 * Function		- ST_GPIO_GetInputDataRegInfo
 * Functionality	- Consoles the Input state Regs of GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_GPIO_GetInputDataRegInfo(int gio)
{
	volatile unsigned long *reg;
	int blank = (gio >> 5) & 0x3;
	int val =0;

	val=0x20+blank*0x28;


	
	reg= (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE+0x20+blank*0x28);

	switch(val)
	{
		default:
		case (0x20) : 
				printk("<1> GPIO InputData 0 and 1 Banks:\t 0x%x\n", *reg);
				break;
				
		case (0x48):
				printk("<1> GPIO InputData 2 and 3 Banks:\t 0x%x\n", *reg);
				break;
				
		case (0x70) :
				printk("<1> GPIO InputData 4 and 5 Banks:\t 0x%x\n", *reg);
				break;
	}
				
		
}




/***************************************************************************
 * Function		- ST_GPIO_GetInterruptStatusRegInfo
 * Functionality	- Consoles the Interrupt state Regs of GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void ST_GPIO_GetInterruptStatusRegInfo(int gio)
{
	volatile unsigned long *reg;
	int blank = (gio >> 5) & 0x3;
	int val =0;

	val=0x34+blank*0x28;


	
	reg= (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE+0x34+blank*0x28);

	switch(val)
	{
		default:
		case (0x34+DAVINCI_GPIO_BASE) : 
				printk("<1> GPIO Interrupt Status 0 and 1 Banks:\t 0x%x\n", *reg);
				break;
				
		case (0x5C+ DAVINCI_GPIO_BASE):
				printk("<1> GPIO Interrupt Status 2 and 3 Banks:\t 0x%x\n", *reg);
				break;
				
		case (0x84+DAVINCI_GPIO_BASE) :
				printk("<1> GPIO Interrupt Status 4 and 5 Banks:\t 0x%x\n", *reg);
				break;
	}
				
		
}


int  gpio_test_init(void)
{
	printk("<1> GPIO Test Begins\n");

	ST_GPIO_Init(gio_tx,opmode1,trig1,dir1, irq_num1,gio_rx, opmode2, trig2,dir2 , irq_num2, enble_loopbck, data_cnt);
	
	return 0;
	
		
}


int  gpio_test_exit(void)
{
	int count=ST_GPIO_OBJECTS;
	int i=0;
	printk("<1> Exiting GPIO Test\n");

	for(i=0;i<count;i++)
	{
		ST_GPIO_unregIRQ(&gST_GPIOObj[i]);
	}
			
	
}

module_init(gpio_test_init);
module_exit(gpio_test_exit);


