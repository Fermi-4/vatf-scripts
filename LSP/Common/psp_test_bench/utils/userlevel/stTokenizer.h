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
 *  \file   stTokenizer.h
 *
 *  \brief  This file exports functions that parse
 *          command line arguments
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     K.R.Baalaaji    Created
 *              0.2     Siddharth       Added wrapper functions to extract
 *                                      strings and integers
 */

#ifndef _ST_TOKENIZER_H_
#define _ST_TOKENIZER_H_

#include <stDefines.h>

/* Maximum Command Length */
#define MAX_CMD_LENGTH 100u

/* Pointer to a function which is the prototype for the performance test */
typedef int (*pspTest)(int, const char **);

/* Structure to specify the performance test function and name */
typedef struct 
{
    unsigned int cmdHashValue;
    char * cmdString;
    pspTest fxn;
} pspTestType;

/* This function returns the next token on the top and decrements numArgs */
void getNextToken(IN OUT int * numArgs, IN OUT const char ** pArgs, 
    OUT char * token);
void getNextTokenString(IN OUT int * numArgs, IN OUT const char ** pArgs, 
    OUT char * token);
void getNextTokenInt(IN OUT int * numArgs, IN OUT const char ** pArgs, 
    OUT int * token);
unsigned int getHashValue (char * command);


#endif /* _ST_TOKENIZER_H_ */

/* vim: set ts=4 sw=4 tw=80 et:*/

