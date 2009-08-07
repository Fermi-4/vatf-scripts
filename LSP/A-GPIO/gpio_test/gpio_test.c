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
**|         Copyright (c) 1998-2007 Texas Instruments Incorporated           |**
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
/** \file   gpio_test.c
    \brief  Test Code for GPIO's 

    (C) Copyright 2007, Texas Instruments, Inc

    @author     Yan Liu
    @version    0.1 
    @date 	12/03/2007
                                
*/
/*
1) if is_test_irq = 0, all params related to irq is no effect.
2) if dir = 0 (output), gpio_src is no effect.
3) if gpio_num > 9, irq_num is no effect.
*/

#include "gpio_test.h"

/* Populated the variables with Default values */
static int gpio_num = 7;
static int dir = 0;		// 0: out; 1: in
static int irq_num = 51;	// for dm355
static int irq_trig_edge = 0;
static int test_loop = 2;	
static int gpio_src = 6;	// output pin for testing input gpio
static int is_test_irq = 0;
static int is_disable_irq = 0;	// irq is not disable by default

module_param(gpio_num, int, 666 );
module_param(dir, int, 666);
module_param(irq_num, int, 666);
module_param(irq_trig_edge, int, 666 );
module_param(test_loop, int, 666);
module_param(gpio_src, int, 666 );
module_param(is_test_irq, int, 666);
module_param(is_disable_irq, int, 666);

/***************************************************************************
 * Function             - gpio_irq_handler
 * Functionality        - Interrupt Handler for TX GPIO's
 * Input Params - ST_GPIOAttrs *
 * Return Value - None
 * Note                 - None
 ****************************************************************************/

static irqreturn_t gpio_irq_handler(int irq, void *dev_id, struct pt_regs *regs)
{
        printk("<1> gpio_irq_handler : IRQ=%d \n",irq);
        return IRQ_HANDLED;
}

/***************************************************************************
 * Function             - gpio_request_irq
 * Functionality        - Registers Handlers to the IRQ's of GPIO's by request_irq
 * Input Params - 
 * Return Value - None
 * Note                 - None
 ****************************************************************************/
void gpio_request_irq(int irq_num)
{
        int status=0;

        status = request_irq(irq_num, gpio_irq_handler,
                                  SA_INTERRUPT, "gpio_test", NULL );
        if (status < 0)
        {
                printk("<1> gpio_request_irq : Failed to Register IRQ %d  \n",irq_num);
                printk("<1> gpio_request_irq : return status is %d  \n",status);
        }

}

/***************************************************************************
 * Function             - gpio_unrequest_irq
 * Functionality        - Free Handlers o the IRQ's of GPIO's
 * Input Params - 
 * Return Value - None
 * Note                 - None
 ****************************************************************************/
void gpio_unrequest_irq(int irq_num)
{
        //int status=0;
        //int irq_flags=0;

        free_irq(irq_num, NULL);
        printk("<1> gpio_unrequest_irq :  Freeing IRQ %d  \n",irq_num);

}

/***************************************************************************
 * Function             - gpio_write
 * Functionality        - toggel gpio output
 * Input Params - 
 * Return Value - None
 * Note                 - None
 ****************************************************************************/
void gpio_write(void)
{
	int i, j;
	int toggle = 0;
	int gpio;
	
	gpio = (dir == GPIO_DIR_IN) ? gpio_src : gpio_num;

	printk("<1> \n");	
	printk("<1> Toggle gpio %d \n", gpio);

	// toggle output values to trigger irq
	for (i = 0; i < test_loop; i++)
	{
		toggle = !(toggle); //toggle the data
		printk("<1>   set %d to gpio \n", toggle);
		gpio_set_value(gpio, toggle);
		//__gpio_set(gpio, toggle);

		// wait for sometime
		// 1x10+9 <=> 4.6 seconds for 216MHz
		for(j = 0; j < 1000000; j++)
			asm("NOP");

	}
}

int gpio_get_settings(int gpio, unsigned long reg_val, char *reg_type)
{
        // Verify if the bit is set right or not
        int mask = 0, set_value = 0;
        //unsigned long reg_val = 0;
        //reg_val = *reg;
        mask = 1 << (gpio % 32);
        set_value = (reg_val & mask) >> (gpio % 32);
        printk("<1> The value was set to %d for gpio %d in %s register.\n\n", set_value, gpio, reg_type);
	
	return set_value;
}

/***************************************************************************
 * Function		- gpio_get_dir_reg_info
 * Functionality	- Consoles the Direction Regs of the GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void gpio_get_dir_reg_info(int gio)
{
	volatile unsigned long *reg;
	int blank = (gio >> 5) & 0x3;
	int offset = 0;

	offset = 0x10 + blank*0x28;
  //printk("<1> gpio_get_dir_reg_info: offset is %x\n",offset);

	// io.h and hardware.h
	// #define IO_ADDRESS(x) io_p2v(x)
	reg = (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE + offset);

	if (cpu_is_davinci_dm355())
	{
    printk("<1> >>>>>I am in cpu_is_davinci_dm355\n");
		switch(offset)
		{
			default:
			case (0x10) : 
				printk("<1> GPIO DIR bank 0 and 1:\t 0x%lx\n", *reg);
				break;					
			case (0x38):
				printk("<1> GPIO DIR bank 2 and 3:\t 0x%lx\n", *reg);
				break;					
			case (0x60) :
				printk("<1> GPIO DIR bank 4 and 5:\t 0x%lx\n", *reg);
				break;
			case (0x88) :
				printk("<1> GPIO DIR bank 6:\t 0x%lx\n", *reg);
				break;				
		}
	}
	else if (cpu_is_davinci_dm644x() || cpu_is_davinci_dm6467())
	{
		switch(offset)
		{
			default:
			case (0x10) : 
				printk("<1> GPIO DIR bank 0 and 1:\t 0x%lx\n", *reg);
				break;					
			case (0x38):
				printk("<1> GPIO DIR bank 2 and 3:\t 0x%lx\n", *reg);
				break;					
			case (0x60) :
				printk("<1> GPIO DIR bank 4 and 5:\t 0x%lx\n", *reg);
				break;	
		}
	}
		
	// Verify if the bit is set right or not
	if(dir == 0)
	{
		if(gpio_get_settings(gio, *reg, "DIR") != 0)
			printk("<1> Failure: DIR register is not set to 0 for gpio %d\n", gio);
	}
	else
	{
                if(gpio_get_settings(gio, *reg, "DIR") != 1)
                        printk("<1> Failure: DIR register is not set to 1 for gpio %d\n", gio);

	}
}


/***************************************************************************
 * Function		- gpio_get_out_data_reg_info
 * Functionality	- Consoles the Output state Regs of GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void gpio_get_out_data_reg_info(int gio)
{
	volatile unsigned long *reg;
	int blank = (gio >> 5) & 0x3;
	int offset = 0;

	offset = 0x14 + blank*0x28;
	
	// io.h and hardware.h
	// #define IO_ADDRESS(x) io_p2v(x)
	reg = (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE + offset);

	if (cpu_is_davinci_dm355())
	{
		switch(offset)
		{
			default:
			case (0x14) : 
				printk("<1> GPIO OUT_DATA bank 0 and 1:\t 0x%lx\n", *reg);
				break;					
			case (0x3C):
				printk("<1> GPIO OUT_DATA bank 2 and 3:\t 0x%lx\n", *reg);
				break;					
			case (0x64) :
				printk("<1> GPIO OUT_DATA bank 4 and 5:\t 0x%lx\n", *reg);
				break;
			case (0x8C) :
				printk("<1> GPIO OUT_DATA bank 6:\t 0x%lx\n", *reg);
				break;				
		}
	}
	else if (cpu_is_davinci_dm644x() || cpu_is_davinci_dm6467())
	{
		switch(offset)
		{
			default:
			case (0x14) : 
				printk("<1> GPIO OUT_DATA bank 0 and 1:\t 0x%lx\n", *reg);
				break;					
			case (0x3C):
				printk("<1> GPIO OUT_DATA bank 2 and 3:\t 0x%lx\n", *reg);
				break;					
			case (0x64) :
				printk("<1> GPIO OUT_DATA bank 4 and 5:\t 0x%lx\n", *reg);
				break;
		}
	}

        // Verify if the bit is set right or not
	// only check when dir is output
	if(dir == 0)
	{
		if(test_loop % 2 == 0)	//if test_loop is even, the value is set to 0.
		{
			if(gpio_get_settings(gio, *reg, "OUT_DATA") != 0)
				printk("<1> Failure: OUT_DATA register is not set to 0 for gpio %d\n", gio);
		}
		else
		{
			if(gpio_get_settings(gio, *reg, "OUT_DATA") != 1)
				printk("<1> Failure: OUT_DATA register is not set to 1 for gpio %d\n", gio);

		}
	}	
}


/***************************************************************************
 * Function		- gpio_get_in_data_reg_info
 * Functionality	- Consoles the Input state Regs of GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void gpio_get_in_data_reg_info(int gio)
{
	volatile unsigned long *reg;
	int blank = (gio >> 5) & 0x3;
	int offset = 0;

	offset = 0x20 + blank*0x28;
	
	// io.h and hardware.h
	// #define IO_ADDRESS(x) io_p2v(x)
	reg = (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE + offset);

	if (cpu_is_davinci_dm355())
	{
		switch(offset)
		{
			default:
			case (0x20) : 
				printk("<1> GPIO IN_DATA bank 0 and 1:\t 0x%lx\n", *reg);
				break;					
			case (0x48):
				printk("<1> GPIO IN_DATA bank 2 and 3:\t 0x%lx\n", *reg);
				break;					
			case (0x70) :
				printk("<1> GPIO IN_DATA bank 4 and 5:\t 0x%lx\n", *reg);
				break;
			case (0x98) :
				printk("<1> GPIO IN_DATA bank 6:\t 0x%lx\n", *reg);
				break;				
		}
	}
	else if (cpu_is_davinci_dm644x() || cpu_is_davinci_dm6467())
	{
		switch(offset)
		{
			default:
			case (0x20) : 
				printk("<1> GPIO IN_DATA bank 0 and 1:\t 0x%lx\n", *reg);
				break;					
			case (0x48):
				printk("<1> GPIO IN_DATA bank 2 and 3:\t 0x%lx\n", *reg);
				break;					
			case (0x70) :
				printk("<1> GPIO IN_DATA bank 4 and 5:\t 0x%lx\n", *reg);
				break;
		}
	}

	gpio_get_settings(gio, *reg, "IN_DATA");
}


/***************************************************************************
 * Function             - gpio_get_set_ris_reg_info
 * Functionality        - Consoles the SET_RIS_TRIG Regs of the GPIO's
 * Input Params - None
 * Return Value - None
 * Note                 - None
 ****************************************************************************/

void gpio_get_set_ris_reg_info(int gio)
{
        volatile unsigned long *reg;
        int blank = (gio >> 5) & 0x3;
        int offset = 0;

        offset = 0x24 + blank*0x28;

        // io.h and hardware.h
        // #define IO_ADDRESS(x) io_p2v(x)
        reg = (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE + offset);

        if (cpu_is_davinci_dm355())
        {
                switch(offset)
                {
                        default:
                        case (0x24) :
                                printk("<1> GPIO SET_RIS_TRIG bank 0 and 1:\t 0x%lx\n", *reg);
                                break;
                        case (0x4C):
                                printk("<1> GPIO SET_RIS_TRIG bank 2 and 3:\t 0x%lx\n", *reg);
                                break;
                        case (0x74) :
                                printk("<1> GPIO SET_RIS_TRIG bank 4 and 5:\t 0x%lx\n", *reg);
                                break;
                        case (0x9C) :
                                printk("<1> GPIO SET_RIS_TRIG bank 6:\t 0x%lx\n", *reg);
                                break;
                }
        }
        else if (cpu_is_davinci_dm644x() || cpu_is_davinci_dm6467())
        {
                switch(offset)
                {
                        default:
                        case (0x24) :
                                printk("<1> GPIO SET_RIS_TRIG bank 0 and 1:\t 0x%lx\n", *reg);
                                break;
                        case (0x4C):
                                printk("<1> GPIO SET_RIS_TRIG bank 2 and 3:\t 0x%lx\n", *reg);
                                break;
                        case (0x74) :
                                printk("<1> GPIO SET_RIS_TRIG bank 4 and 5:\t 0x%lx\n", *reg);
                                break;

                }
        }

        // Verify if the bit is set right or not
        if(irq_trig_edge == 0)
        {
                if(gpio_get_settings(gio, *reg, "SET_RIS_TRIG") != 1)
                        printk("<1> Failure: SET_RIS_TRIG register is not set to 1 for gpio %d\n", gio);
        }
	else	//not check the setting if falling-edge
		gpio_get_settings(gio, *reg, "SET_RIS_TRIG");
}


/***************************************************************************
 * Function             - gpio_get_set_fal_reg_info
 * Functionality        - Consoles the SET_FAL_TRIG Regs of the GPIO's
 * Input Params - None
 * Return Value - None
 * Note                 - None
 ****************************************************************************/

void gpio_get_set_fal_reg_info(int gio)
{
        volatile unsigned long *reg;
        int blank = (gio >> 5) & 0x3;
        int offset = 0;

        offset = 0x2C + blank*0x28;

        // io.h and hardware.h
        // #define IO_ADDRESS(x) io_p2v(x)
        reg = (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE + offset);

        if (cpu_is_davinci_dm355())
        {
                switch(offset)
                {
                        default:
                        case (0x2C) :
                                printk("<1> GPIO SET_FAL_TRIG bank 0 and 1:\t 0x%lx\n", *reg);
                                break;
                        case (0x54):
                                printk("<1> GPIO SET_FAL_TRIG bank 2 and 3:\t 0x%lx\n", *reg);
                                break;
                        case (0x7C) :
                                printk("<1> GPIO SET_FAL_TRIG bank 4 and 5:\t 0x%lx\n", *reg);
                                break;
                        case (0xA4) :
                                printk("<1> GPIO SET_FAL_TRIG bank 6:\t 0x%lx\n", *reg);
                                break;
                }
        }
        else if (cpu_is_davinci_dm644x() || cpu_is_davinci_dm6467())
        {
                switch(offset)
                {
                        default:
                        case (0x2C) :
                                printk("<1> GPIO SET_FAL_TRIG 0 and 1:\t 0x%lx\n", *reg);
                                break;
                        case (0x54):
                                printk("<1> GPIO SET_FAL_TRIG 2 and 3:\t 0x%lx\n", *reg);
                                break;
                        case (0x7C) :
                                printk("<1> GPIO SET_FAL_TRIG 4 and 5:\t 0x%lx\n", *reg);
                                break;

                }
        }

        // Verify if the bit is set right or not
        if(irq_trig_edge == 1)
        {
                if(gpio_get_settings(gio, *reg, "SET_FAL_TRIG") != 1)
                        printk("<1> Failure: SET_FAL_TRIG register is not set to 1 for gpio %d\n", gio);
        }
	else
		gpio_get_settings(gio, *reg, "SET_FAL_TRIG");
}

/***************************************************************************
 * Function		- gpio_get_intstat_reg_info
 * Functionality	- Consoles the Interrupt state Regs of GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void gpio_get_intstat_reg_info(int gio)
{
	volatile unsigned long *reg;
	int blank = (gio >> 5) & 0x3;
	int offset = 0;

	offset = 0x34 + blank*0x28;
	
	// io.h and hardware.h
	// #define IO_ADDRESS(x) io_p2v(x)
	reg = (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE + offset);

	if (cpu_is_davinci_dm355())
	{
		switch(offset)
		{
			default:
			case (0x34) : 
				printk("<1> GPIO INSTAT bank 0 and 1:\t 0x%lx\n", *reg);
				break;					
			case (0x5C):
				printk("<1> GPIO INSTAT bank 2 and 3:\t 0x%lx\n", *reg);
				break;					
			case (0x84) :
				printk("<1> GPIO INSTAT bank 4 and 5:\t 0x%lx\n", *reg);
				break;
			case (0xAC) :
				printk("<1> GPIO INSTAT bank 6:\t 0x%lx\n", *reg);
				break;				
		}
	}
	else if (cpu_is_davinci_dm644x() || cpu_is_davinci_dm6467())
	{
		switch(offset)
		{
			default:
			case (0x34) : 
				printk("<1> GPIO INSTAT bank 0 and 1:\t 0x%lx\n", *reg);
				break;					
			case (0x5C):
				printk("<1> GPIO INSTAT bank 2 and 3:\t 0x%lx\n", *reg);
				break;					
			case (0x84) :
				printk("<1> GPIO INSTAT bank 4 and 5:\t 0x%lx\n", *reg);
				break;		
		}
	}
		
	gpio_get_settings(gio, *reg, "INSTAT");
}


/***************************************************************************
 * Function		- gpio_get_binten_reg_info
 * Functionality	- Consoles the BINTEN of GPIO's
 * Input Params	- None
 * Return Value	- None
 * Note			- None
 ****************************************************************************/

void gpio_get_binten_reg_info(void)
{
	volatile unsigned long *reg;
	int offset = 0;

	offset = 0x08;
	
	// io.h and hardware.h
	// #define IO_ADDRESS(x) io_p2v(x)
	reg = (unsigned long *)IO_ADDRESS(DAVINCI_GPIO_BASE + offset);
	printk("<1> GPIO BINTEN:\t 0x%lx\n", *reg);
}


void gpio_demux_pins(void)
{
	// PINMUX address is same between dm355 and dm6446?
	if (cpu_is_davinci_dm355())
	{	
		/* Besides the dedicated GPIO pins */
	        /* Demux pins to GPIO pins which can be accessed from DC5 */
	        REG_PINMUX1 |= (1<<17);		 // gio71
	        REG_PINMUX1 &= ~((1<<19)|(1<<18)); // gio70
	        REG_PINMUX1 &= ~((1<<0)|(1<<1)); // gio81
	        REG_PINMUX1 &= ~((1<<2)|(1<<3)); // gio80
	        REG_PINMUX1 &= ~((1<<4)|(1<<5)); // gio79
	        REG_PINMUX1 &= ~((1<<6)|(1<<7)); // gio78

		REG_PINMUX3 &= ~(1<<28);	// gio07
#if 0
		/* Demux the following pins for DC7 in new dm355 board */
		/* gpio 58 to 65, no pin mux is available */
	        REG_PINMUX2 |= (1<<10); // gio32 Enable EM_AVD
	        REG_PINMUX4 |= (1<<1); 	// gio32 Enable SPIO_SDI
		REG_PINMUX2 &= ~(1<<2); // gio54
		REG_PINMUX2 |= (1<<3); 	// gio54
		// comment out the following because it causes 'etho transmit timeout'
		//REG_PINMUX2 |= (1<<1);	// gio55:56
		REG_PINMUX2 |= (1<<0); 	// gio57:67

		/* Demux pins to GPIO pins which can be accessed from DC3 */
	        REG_PINMUX3 &= ~(1<<0); // gio30
	        REG_PINMUX3 &= ~(1<<1); // gio29
	        REG_PINMUX3 &= ~(1<<2); // gio28
	        REG_PINMUX3 &= ~(1<<3); // gio27
	        REG_PINMUX3 &= ~(1<<4); // gio26
	        REG_PINMUX3 &= ~(1<<5); // gio25
#endif
	}
	else if (cpu_is_davinci_dm644x() || cpu_is_davinci_dm6467())
	{
		//after do the de-pinmux EMAC, network will go down. UUT need reboot	
		//in order to test gpio54 and up, uncomment the following.
		//REG_PINMUX0 &= ~(1<<31);	// gpio3v[0:16]
	}	      
	  
}

// gpio0-9 has direct interrupt number corresponding to them for dm355.
int get_gpio_num_direct_irq(void)
{
	int rtn = 0;

	if(cpu_is_davinci_dm355())
		rtn = 10;
	else if(cpu_is_davinci_dm644x() || cpu_is_davinci_dm6467())
		rtn = 8;
	return rtn;
}


int gpio_test_init(void)
{
	int gpio_num_with_direct_irq = 10;

	printk("<1> GPIO Test Begins\n");
	
	// Demux pins to test GPIOs
	if(is_test_irq == 1)
	{
		gpio_demux_pins();
	}

	// set direction
	if(dir == GPIO_DIR_IN)
	{
		gpio_direction_input(gpio_num);
		
		//if direction is input, setup another tx gpio so that
		//loopback data back to input gpio.
		gpio_direction_output(gpio_src, 0);
	}
	else
	{
		gpio_direction_output(gpio_num, 0);
	}

#if 1	
	// set edge type
	if(irq_trig_edge == IRQ_RISING_EDGE)
	{
		set_irq_type(gpio_to_irq(gpio_num), IRQT_RISING);
	}
	else if(irq_trig_edge == IRQ_FALLING_EDGE) 
	{
		set_irq_type(gpio_to_irq(gpio_num), IRQT_FALLING);	
	}	
	else if(irq_trig_edge == IRQ_BOTH_EDGE) 
	{
		set_irq_type(gpio_to_irq(gpio_num), IRQT_BOTHEDGE);	
	}
#endif			
	// request irq
	if(is_test_irq == 1)
	{
		// return value from function gpio_to_irq(gio) is for band irq 
		gpio_num_with_direct_irq = get_gpio_num_direct_irq();
	//	printk("<1> irq number is: %d \n", gpio_to_irq(gpio_num));
		if(gpio_num > gpio_num_with_direct_irq - 1)
			gpio_request_irq(gpio_to_irq(gpio_num));
		else
			gpio_request_irq(irq_num);
	}
	
	// toggle gpio output
	gpio_write();

	// get register values
	printk("<1> \n");
	gpio_get_dir_reg_info(gpio_num);
	gpio_get_out_data_reg_info(gpio_num);
	gpio_get_in_data_reg_info(gpio_num);
	gpio_get_set_ris_reg_info(gpio_num);
	gpio_get_set_fal_reg_info(gpio_num);
	gpio_get_intstat_reg_info(gpio_num);
	gpio_get_binten_reg_info();
	
	if(is_disable_irq)
	{
		// test disable irq 
		if(gpio_num > gpio_num_with_direct_irq - 1)
		{
			printk("<1> Disable IRQ - %d\n", gpio_to_irq(gpio_num));
			disable_irq(gpio_to_irq(gpio_num));
		}
		else
		{
			printk("<1> Disable IRQ - %d\n", irq_num);
			disable_irq(irq_num);
		}
		gpio_write();

		// get register values
		gpio_get_dir_reg_info(gpio_num);
		gpio_get_out_data_reg_info(gpio_num);
		gpio_get_in_data_reg_info(gpio_num);
		gpio_get_set_ris_reg_info(gpio_num);
		gpio_get_set_fal_reg_info(gpio_num);
		gpio_get_intstat_reg_info(gpio_num);
		gpio_get_binten_reg_info();
	}

	return 0;
}


void gpio_test_exit(void)
{
	int gpio_num_with_direct_irq = 0;
 
	printk("<1> Exiting GPIO Test\n");

	if(is_test_irq)
	{
		gpio_num_with_direct_irq = get_gpio_num_direct_irq();
	//	printk("<1> irq number is: %d \n", gpio_to_irq(gpio_num));
		if(gpio_num > gpio_num_with_direct_irq - 1)
			gpio_unrequest_irq(gpio_to_irq(gpio_num));
		else
			gpio_unrequest_irq(irq_num);
	}
	// disable interrupt ??
	//return 0;
}

module_init(gpio_test_init);
module_exit(gpio_test_exit);



