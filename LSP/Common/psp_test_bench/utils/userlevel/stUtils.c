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
 **|         Copyright (c) 1998-2008 Texas Instruments Incorporated           |**
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
 *  \file   stUtils.c
 *
 *  \brief  This file implements the utilities used in pspTestBench
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \history    0.1     Asha     Created
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#include <stUtils.h>

void itoa(int n, Int8 * s)
{
    int i = 0, j = 0, c;
    int is_negative;

    if(n<0)
    {
        is_negative = 1;
        n=abs(n);
    }
    else is_negative = 0;

    do
    {
        s[i++] = n % 10 + '0';
    } while ((n /= 10) > 0);

    if(is_negative)
        s[i++] = '-';

    s[i] = 0;

    for (i = 0, j = strlen((const char *)s) - 1; i < j; i++, j--) 
    {
        c = s[i];
        s[i] = s[j];
        s[j] = c;
    }
    return;
}

/* vim: set ts=4 sw=4 tw=80 et:*/

