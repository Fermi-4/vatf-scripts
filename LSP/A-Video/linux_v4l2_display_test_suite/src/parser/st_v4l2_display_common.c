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
 **|         Copyright (c) 1998-2008 Texas Instruments Incorporated          |**
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
 *  \file   stCommon.c
 *
 *  \brief  This file implements common functions that may be used by several
 *  test case files
 *        
 *
 *  (C) Copyright 2008, Texas Instruments, Inc
 *
 *  \history    0.1     Prathap.M.S    Created
 */



#include <st_v4l2_display_common.h>
#include <stLog.h>


//Fill the color pattern
static short ycbcr[8] = {
    (0x1F << 11) | (0x3F << 5) | (0x1F),
    (0x00 << 11) | (0x00 << 5) | (0x00),
    (0x1F << 11) | (0x00 << 5) | (0x00),
    (0x00 << 11) | (0x3F << 5) | (0x00),
    (0x00 << 11) | (0x00 << 5) | (0x1F),
    (0x1F << 11) | (0x3F << 5) | (0x00),
    (0x1F << 11) | (0x00 << 5) | (0x1F),
    (0x00 << 11) | (0x3F << 5) | (0x1F),
};

/****************************************************************************
 * Function             - colorbar_generate
 * Functionality        - This function generates the color bars
 * Input Params         - device number
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/
void colorbar_generate(unsigned char *addr, int width, int height, int order)
{
    unsigned short *ptr = ((unsigned short *)addr) + order*width;
    int i, j, k;

    for(i = 0 ; i < 8 ; i ++) {
        for(j = 0 ; j < height / 8 ; j ++) {
            for(k = 0 ; k < width / 2 ; k ++, ptr++)
                *ptr = ycbcr[i];
            if((unsigned int)ptr > (unsigned int)addr +
                    width*height)
                ptr = (unsigned short *)addr;
        }
    }
}


/****************************************************************************
 * Function             - fill_lines(),color_bar()
 * Functionality        - This function generates the color bars
 * Input Params         - addr,pitch,height,size for color_bar and width for
 *                        fill_lines()
 * Return Value         - 0: SUCCESS, -1: FAILURE
 * Note                 - None
 ****************************************************************************/

unsigned char lines[4][2][1920];


void fill_lines(int width)
{
    unsigned char CVal[4][2] = {{0x5A, 0xF0},{0x36, 0x22},
        {0xF0, 0x6E},{0x10, 0x92}};
    int i, j ,k;
    /* Copy Y data for all 4 colors in the array */
    memset(lines[0][0], 0x51, width);
    memset(lines[1][0], 0x91, width);
    memset(lines[2][0], 0x29, width);
    memset(lines[3][0], 0xD2, width);
    /* Copy C data for all 4 Colors in the array */
    for(i = 0 ; i < 4 ; i ++) {
        for(j = 0 ; j < 2 ; j ++){
            for(k = 0 + j ; k < width ; k+=2)
                lines[i][1][k] = CVal[i][j];
        }
    }
}

void color_bar(unsigned char *addr, int pitch, int h, int size, int order)
{
    unsigned char *ptrY = addr;
    unsigned char *ptrC = addr + pitch*(size/(pitch*2));
    unsigned char *tempY, *tempC;
    int i, j, k;

    /* Calculate the starting offset from where Y and C data should
     * should start. */
    tempY = ptrY + pitch * 10 + pitch + order*pitch;
    tempC = ptrC + pitch * 10 + pitch + order*pitch;
    /* Fill all the colors in the buffer */
    for(j = 0; j < 4 ; j ++) {
        for(i = 0; i < (h/4) ; i ++) {
            memcpy(tempY, lines[j][0], pitch);
            memcpy(tempC, lines[j][1], pitch);
            tempY += pitch;
            tempC += pitch;
            if(tempY > (ptrY + pitch * (h*2) + pitch + pitch)) {
                tempY = ptrY + pitch * h + pitch;
                tempC = ptrC + pitch * h + pitch;
            }
        }
    }

}

/****************************************************************************
 * Function             - fill_line_centre(),color_bar_centre()
 * Functionality        - This function generates the color bars at the centre
 *                        of screen(optional function)
 * Input Params         - addr,pitch,height,size for color_bar and width for
 *                        fill_lines()
 * Return Value         - None
 * Note                 - None
 ****************************************************************************/
unsigned char line[4][2][1920];

void fill_line_centre(int width)
{
    unsigned char CVal[4][2] = {{0x5A, 0xF0},{0x36, 0x22},
        {0xF0, 0x6E},{0x10, 0x92}};
    int i, j ,k;
    /* Copy Y data for all 4 colors in the array */
    memset(line[0][0], 0x51, width/3);
    memset(line[1][0], 0x91, width/3);
    memset(line[2][0], 0x29, width/3);
    memset(line[3][0], 0xD2, width/3);
    /* Copy C data for all 4 Colors in the array */
    for(i = 0 ; i < 4 ; i ++) {
        for(j = 0 ; j < 2 ; j ++){
            for(k = 0 + j ; k < (width/3) ; k+=2)
                lines[i][1][k] = CVal[i][j];
        }
    }
}

void color_bar_centre(unsigned char *addr, int pitch, int h, int size, int order)
{
    unsigned char *ptrY = addr;
    unsigned char *ptrC = addr + pitch*(size/(pitch*2));
    unsigned char *tempY, *tempC;
    int i, j, k;

    /* Calculate the starting offset from where Y and C data should
     * should start. */
    tempY = ptrY + pitch * (h/3) + (pitch/3) + order*pitch;
    tempC = ptrC + pitch * (h/3) + (pitch/3) + order*pitch;
    /* Fill all the colors in the buffer */
    for(j = 0; j < 4 ; j ++) {
        for(i = 0; i < 40 ; i ++) {
            memcpy(tempY, lines[j][0],(pitch/3));
            memcpy(tempC, lines[j][1], (pitch/3));
            tempY += pitch;
            tempC += pitch;
            if(tempY > (ptrY + pitch * ((h/3)*2) + (pitch/3) + pitch)) {
                tempY = ptrY + pitch * h + (pitch/3);
                tempC = ptrC + pitch * h + (pitch/3);
            }
        }
    }

}


/* vim: set ts=4 sw=4 tw=80 et:*/
