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
 *  \file   vdceCommon.c
 *
 *  \brief  This file contains the common functions 
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \history    0.1     Prathap MS     Created
 */

/* Standard Header files includes */
#include <stdio.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>

/* Function Declaration */
void read_frame_from_file(unsigned char *addr,char *filename,int size);
void write_frame_to_file(unsigned char *addr, char *filename, int size); 

/*
 *=====================read_frame_from_file===========================
 It will take the data from YUV file and fill in vdce buffer 
 */
void read_frame_from_file(unsigned char *addr,char *filename,int size)
{
    FILE *fp;
    fp = fopen(filename, "rb");
    if(fp == NULL) {
        printf("Cannot open file \n");
        return;
    }
    if(0==fread(addr,size,1,fp)) {
         printf("fread() failed\n");
         return;
    }
    if(fclose(fp)!=0) {
         printf("fclose() failed\n");
         return;
    }
}
/*
 *=====================write_frame_to_file===========================
 It will take the output data and dump into YUV file 
 */

void write_frame_to_file(unsigned char *addr, char *filename, int size)
{
    FILE *fp;
    fp = fopen(filename, "wb");
    if(fp == NULL) {
        printf("Cannot open file = %s\n",filename);
        return ;
    }
    if(0==fwrite(addr,size,1,fp)) {
        printf("fread() failed \n");
          return;
    }
    if(fclose(fp)!=0) {
        printf("fclose() failed\n");
        return;
    }
}
/* vim: set ts=4 sw=4 tw=80 et:*/

