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
 *  \file   stMain.c
 *
 *  \brief  This file is the entry point for the tests
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     K.R.Baalaaji     Created
 */


#include <stdio.h>
#include <stDefines.h>
#include <stTokenizer.h>
#include <stTimer.h>

static int printPspUsage (int numArgs, const char ** argv);
static int printHashValue(int numArgs, const char ** argv);
#ifdef USE_TP 
extern int handleThroughputTest(int, const char **);
#endif

#ifdef USE_TP
extern int handleCpuLoadTest(int, const char **);
#endif

#ifdef USE_FN
extern int handleFnTest(int, const char **);
#endif

#define                             ThruPut     0x00001d56
#define                              FnTest     0x00000d86
#define                             CpuLoad     0x00001aea
#define                                hash     0x0000024a
#define                                help     0x0000027c
#define                                exit     0x0000026e

static pspTestType pspTestArray[] = {
#ifdef USE_TP
    { ThruPut, "ThruPut", handleThroughputTest },
#endif
#ifdef USE_TP
    { CpuLoad, "CpuLoad", handleCpuLoadTest },
#endif
#ifdef USE_FN
    { FnTest, "FnTest", handleFnTest },
#endif
    { hash, "hash", printHashValue }, /* Enables user to get the command's
                                         hashvalue */
    { help, "help", printPspUsage } /* NOTE: "help" should be the last command */
};

static int printPspUsage (int numArgs, const char ** argv)
{
    int counter = 0;

    printf("\nperfTest version %s - command list: \n", perfTestVersion);
    while (help != pspTestArray[counter].cmdHashValue)
    {
        printf("%d %s\n\r", counter + 1, pspTestArray[counter].cmdString);
        counter ++;
    }
    printf("%d %s\n\r", counter + 1, pspTestArray[counter].cmdString);

    return 0;
}


static int printHashValue(int numArgs, const char ** argv)
{
    char cmdString[MAX_CMD_LENGTH];
    unsigned int cmdHashValue = 0;
    getNextTokenString (&numArgs, argv, cmdString);
    cmdHashValue = getHashValue (cmdString);
    printf("#define %35s \t0x%08x\n", cmdString, cmdHashValue);

    return 0;
}


int main(int numArgs, const char *pArgs[])
{
    int counter = 0;
    char cmdString[MAX_CMD_LENGTH];
    unsigned int cmdHashValue = 0;
    int validCommand = FALSE;

    /* Initialize Timer module */
    initTimerModule();

    /* TODO: What if getToken returns error? */
    getNextTokenString (&numArgs, pArgs, cmdString);
    getNextTokenString (&numArgs, pArgs, cmdString);

    /* Get the hash value of the command passed */
    cmdHashValue = getHashValue (cmdString);

    /* Iterate through the pspTestArray and calls the function */
    while (help != pspTestArray[counter].cmdHashValue)
    {
        if(cmdHashValue == pspTestArray[counter].cmdHashValue)
        {
            /* found a valid command */
            validCommand = TRUE;

            /* Call the function and break out */
            pspTestArray[counter].fxn (numArgs, pArgs);

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
        printPspUsage (numArgs, pArgs);
    }

    return 0;
}	

/* vim: set ts=4 sw=4 tw=80 et:*/
