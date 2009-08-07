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

/**
 *  \file   FunctionalTestEngine.c
 *
 *  \brief  This file implements the function that calls the appropriate test
 *  case
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     K.R.Baalaaji     Created
 */

#include <stdio.h>
#include <string.h>
#include <stDefines.h>
#include <stTokenizer.h>

/* Test functions defined */
void i2c_parser(void);
void spi_parser(void);
void oss_parser(void);
void alsa_parser(void);
extern void uart_parser(void);
void fbdev_parser(void);
static int printFnTestUsage (int numArgs, const char ** argv);

/* Command name hash values */
#define                                ALSA     0x000003df
#define                                 ATA     0x000001ed
#define                                  FS     0x000000df
#define                                GPIO     0x000003a5
#define                                 I2C     0x00000103
#define                                 MMC     0x000001ed
#define                                NAND     0x000003ac
#define                                 NOR     0x000001f4
#define                                 OSS     0x000001c9
#define                                 PWM     0x000001a3
#define                                 RTC     0x000001a3
#define                                SATA     0x00000375
#define                                 SPI     0x000001a5
#define                                UART     0x0000035c
#define                                VDCE     0x00000363
#define                                V4L2     0x000002ca
#define                               FBDEV     0x000007bc
#define                                UART     0x0000035c
#define                                help     0x0000027c
#define                                exit     0x0000026e

static pspTestType fnTestArray[] = {
#ifdef USE_FN_I2C
    { I2C, "I2C", i2c_parser },
#endif
#ifdef USE_FN_SPI
    { SPI, "SPI", spi_parser },
#endif
#ifdef USE_FN_OSS
    { OSS, "OSS", oss_parser },
#endif
#ifdef USE_FN_ALSA
    { ALSA, "ALSA", alsa_parser },
#endif
#ifdef USE_FN_UART
    { UART, "UART", uart_parser },
#endif
#ifdef USE_FN_FBDEV
    { FBDEV, "FBDEV", fbdev_parser },
#endif

    { help, "help", printFnTestUsage }, 
    { exit, "exit", printFnTestUsage } /* NOTE: "exit" should be the last command */
};

static int printFnTestUsage (int numArgs, const char ** argv)
{
    int counter = 0;

    printf("\nperfTest version %s - command list: \n", perfTestVersion);
    while (help != fnTestArray[counter].cmdHashValue)
    {
        printf("%d %s\n\r", counter + 1, fnTestArray[counter].cmdString);
        counter ++;
    }
    printf("%d %s\n\r", counter + 1, fnTestArray[counter].cmdString);

    return 0;
}
    

/* Get the test type and call the respective funtion */
void handleFnTest(IN int numArgs, IN const char *pArgs[])
{
    int counter = 0;
    char cmdString[MAX_CMD_LENGTH];
    unsigned int cmdHashValue = 0;
    int validCommand = FALSE;

    /* TODO: What if getToken returns error? */
    getNextTokenString (&numArgs, pArgs, cmdString);
    
    /* Get the hash value of the command passed */
    cmdHashValue = getHashValue (cmdString);

    /* Iterate through the fnTestArray and calls the function */
    while (help != fnTestArray[counter].cmdHashValue)
    {
        if(cmdHashValue == fnTestArray[counter].cmdHashValue)
        {
            /* found a valid command */
            validCommand = TRUE;

            /* Call the function and break out */
            fnTestArray[counter].fxn (numArgs, pArgs);

            /* we can quit now */
            break;
        } 
        /* Function does not match, increment the index */
        counter++;
    }

    if (validCommand != TRUE)
    {
        if (help != cmdHashValue)
        {
            printf("\nInvalid Command. Enter the command again..\n");
        }
        printFnTestUsage (numArgs, pArgs);
    }

    return;
}	

/* vim: set ts=4 sw=4 tw=80 et:*/

