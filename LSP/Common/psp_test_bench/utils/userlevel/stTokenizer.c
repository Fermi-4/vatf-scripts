/******************************************************************************
**+-------------------------------------------------------------------------+**
**|                            ****                                         |**
**|                            ****                                         |**
**|                            ******o***                                   |**
**|                      ********_///_****                                  |**
**|                      ***** /_//_/ ****                                  |**
**|                       ** ** (__/ ****                                   |**
**|                           *********                                     |**
**|                            ****                                         |**
**|                            ***                                          |**
**|                                                                         |**
**|         Copyright (c) 1998-2004 Texas Instruments Incorporated          |**
**|                        ALL RIGHTS RESERVED                              |**
**|                                                                         |**
**| Permission is hereby granted to licensees of Texas Instruments          |**
**| Incorporated (TI) products to use this computer program for the sole    |**
**| purpose of implementing a licensee product based on TI products.        |**
**| No other rights to reproduce, use, or disseminate this computer         |**
**| program, whether in part or in whole, are granted.                      |**
**|                                                                         |**
**| TI makes no representation or warranties with respect to the            |**
**| performance of this computer program, and specifically disclaims        |**
**| any responsibility for any damages, special or consequential,           |**
**| connected with the use of this program.                                 |**
**|                                                                         |**
**+-------------------------------------------------------------------------+**
******************************************************************************/

/**
 *  \file   stTokenizer.c
 *
 *  \brief  This file implements functions to parse 
 *          command line arguments
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     K.R.Baalaaji    Created
 *              0.2     Siddharth       Added wrapper functions to extract
 *                                      strings and integers
 */

#include <string.h>
#include <stdlib.h>
#include <stDefines.h>
#include <stTokenizer.h>

/* This function returns the next token on the top and decrements numArgs */
/* TODO update the pArgs array for the actual position and return it */

void getNextToken(IN OUT int * numArgs, IN OUT const char ** pArgs, OUT char * token)
{
   static int numArgsConsumed = 0;

   strcpy(token, pArgs[numArgsConsumed++]);
   (*numArgs)--;

   return;
}	

void getNextTokenString(IN OUT int * numArgs, IN OUT const char ** pArgs, 
    OUT char * token)
{
    getNextToken(numArgs, pArgs,token);
    
    return;
}

void getNextTokenInt(IN OUT int * numArgs, IN OUT const char ** pArgs, 
    OUT int * token)
{
    char tmpToken[100];

    getNextToken(numArgs, pArgs, tmpToken);

    *token = atoi(tmpToken);
    
    return;
}

/**
 *  \brief   hash
 *
 *  This function returns a 32-bit hash value for the given input string
 *
 *  \param  command [IN]      string containing the command *
 *  \return 32-bit hash value
 */
unsigned int getHashValue (char * command)
{
    unsigned int hashval = 0;
    char *p = command;

    while (*p)
    {
        hashval = hashval << 1;
        hashval = hashval ^ *p;
        p++;
    }
    return hashval;
}

/* vim: set ts=4 sw=4 tw=80 et:*/
