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
 *  \file   throughputEngine.c
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

#ifdef USE_TP_FS 
extern int throughputFSWrite(int, const char **);
extern int throughputFSRead(int, const char **);
extern int throughputMTDBlkWrite(int, const char **);
#endif

#ifdef USE_TP_ALSA
extern int throughputAudioAlsaWrite(int, const char **);
extern int throughputAudioAlsaRead(int, const char **);
extern int throughputAudioAlsaWriteFromFile(int, const char **);
extern int throughputAudioAlsaReadToFile(int, const char **);
extern int throughputAudioAlsaLoopback(int, const char **);
#endif

#ifdef USE_TP_OSS
extern int throughputAudioWrite(int, const char **);
extern int throughputAudioRead(int, const char **);
extern int throughputAudioWriteFromFile(int, const char **);
extern int throughputAudioReadToFile(int, const char **);
extern int throughputAudioLoopback(int, const char **);
#endif

#ifdef USE_TP_I2C
extern int throughputI2cWrite(int,const char **);
extern int throughputI2cRead(int,const char **); 
#endif

#ifdef USE_TP_SPI
extern int throughputSpiWrite(int,const char **);
extern int throughputSpiRead(int,const char **);
#endif

#ifdef USE_TP_V4L2 
extern int v4l2capture_perf(int numargs,const char **argv); 
extern int v4l2display_perf(int numargs,const char **argv); 
#endif

#ifdef USE_TP_FBDEV 
extern int fbdevdisplay_perf(int numargs,const char **argv); 
#endif

#ifdef USE_TP_VDCE
extern int vdce_resize(int numargs,const char **argv);
extern int vdce_ccv422_420(int numargs,const char **argv);
extern int vdce_ccv420_422(int numargs,const char **argv);
extern int vdce_blending(int numargs,const char **argv);
extern int vdce_rmap(int numargs,const char **argv);
extern int vdce_epad(int numargs,const char **argv);
#endif

#ifdef USE_TP_USBVIDEO
extern int usbisovideo_perf(int numargs,const char **argv);
#endif

static int printThroughputUsage (int numArgs, const char ** argv);
void handlePerfRequest(IN int numArgs, IN const char *pArgs[]);
void handleCpuLoadTest(IN int numArgs, IN const char *pArgs[]);
void handleThroughputTest(IN int numArgs, IN const char *pArgs[]);



/* Command name hash values */
#define                           TPfswrite     0x00006e29
#define                            TPfsread     0x00003752
#define                     FRaudioalsaread     0x001f7452
#define                    FRaudioalsawrite     0x003ee829
#define                         FRaudioread     0x0001f7f2
#define                        FRaudiowrite     0x0003ef69
#define                       FRv4l2capture     0x00072415 
#define                       FRv4l2display     0x0007249b 
#define                      FRfbdevdisplay     0x000fdf9b 
#define               FRaudioalsareadtofile     0x07dd1ed9
#define            FRaudioalsawritefromfile     0x3ee80f99
#define                   FRaudioreadtofile     0x007df6d9
#define                FRaudiowritefromfile     0x03ef4f99
#define                FRusbisovideocapture     0x03c04f95
#define                            FRResize     0x0000393d
#define                          FRBlending     0x0000ec7f
#define                       FRCCV422to420     0x0007387c
#define                       FRCCV420to422     0x0007383e
#define                              FRRmap     0x00000e76
#define                              FRepad     0x00000fae
#define                            I2cWrite     0x000023a9
#define                             I2cRead     0x00001192
#define                            SpiWrite     0x00003f69
#define                             SpiRead     0x00001ff2
#define                         MTDBlkWrite     0x0001e8a9
#define                          MTDBlkRead     0x0000f412
#define               FRusbisoaudioalsaread     0x07811452
#define              FRusbisoaudioalsawrite     0x0f022829
#define                   FRusbisoaudioread     0x007811f2
#define                  FRusbisoaudiowrite     0x00f02369
#define                                help     0x0000027c

static pspTestType throughputTestArray[] = {
#ifdef USE_TP_FS 
    { TPfswrite, "TPfswrite", throughputFSWrite },
    { TPfsread, "TPfsread", throughputFSRead },
    { MTDBlkWrite, "MTDBlkWrite", throughputMTDBlkWrite },
    { MTDBlkRead, "MTDBlkRead", throughputFSRead },
#endif
#ifdef USE_TP_ALSA
    { FRaudioalsaread, "FRaudioalsaread", throughputAudioAlsaRead },
    { FRaudioalsawrite, "FRaudioalsawrite", throughputAudioAlsaWrite },
    { FRusbisoaudioalsaread, "FRusbisoaudioalsaread", throughputAudioAlsaRead },
    { FRusbisoaudioalsawrite, "FRusbisoaudioalsawrite", throughputAudioAlsaWrite },
    { FRaudioalsareadtofile, "FRaudioalsareadtofile", throughputAudioAlsaReadToFile },
    { FRaudioalsawritefromfile, "FRaudioalsawritefromfile", throughputAudioAlsaWriteFromFile },
#endif
#ifdef USE_TP_OSS
    { FRaudioread, "FRaudioread", throughputAudioRead },
    { FRaudiowrite, "FRaudiowrite", throughputAudioWrite },
    { FRusbisoaudioread, "FRusbisoaudioread", throughputAudioRead },
    { FRusbisoaudiowrite, "FRusbisoaudiowrite", throughputAudioWrite },
    { FRaudioreadtofile, "FRaudioreadtofile", throughputAudioReadToFile },
    { FRaudiowritefromfile, "FRaudiowritefromfile", throughputAudioWriteFromFile },
#endif
#ifdef USE_TP_V4L2
    { FRv4l2capture, "FRv4l2capture", v4l2capture_perf },
    { FRv4l2display, "FRv4l2display", v4l2display_perf },
#endif
#ifdef USE_TP_USBVIDEO
    { FRusbisovideocapture, "FRusbisovideocapture", usbisovideo_perf },
#endif
#ifdef USE_TP_FBDEV
    { FRfbdevdisplay, "FRfbdevdisplay", fbdevdisplay_perf },
#endif
#ifdef USE_TP_VDCE
    { FRResize, "FRResize", vdce_resize },
    { FRBlending, "FRBlending", vdce_blending },
    { FRCCV422to420, "FRCCV422to420", vdce_ccv422_420 },
    { FRCCV420to422, "FRCCV420to422", vdce_ccv420_422 },
    { FRRmap, "FRRmap", vdce_rmap },
    { FRepad, "FRepad", vdce_epad },
#endif
#ifdef USE_TP_I2C
    { I2cWrite, "I2cWrite", throughputI2cWrite },
    { I2cRead, "I2cRead", throughputI2cRead },
#endif
#ifdef USE_TP_SPI
    { SpiWrite, "SpiWrite", throughputSpiWrite },
    { SpiRead, "SpiRead", throughputSpiRead },
#endif
    { help, "help", printThroughputUsage } /* NOTE: "help" should be the last command */
};

static int printThroughputUsage (int numArgs, const char ** argv)
{
    int counter = 0;

    printf("\nperfTest version %s - command list: \n", perfTestVersion);
    while (help != throughputTestArray[counter].cmdHashValue)
    {
        printf("%d %s\n\r", counter + 1, throughputTestArray[counter].cmdString);
        counter ++;
    }
    printf("%d %s\n\r", counter + 1, throughputTestArray[counter].cmdString);

    return 0;
}
    

/* Get the test type and call the respective funtion */
void handlePerfRequest(IN int numArgs, IN const char *pArgs[])
{
    int counter = 0;
    char cmdString[MAX_CMD_LENGTH];
    unsigned int cmdHashValue = 0;
    int validCommand = FALSE;

    /* TODO: What if getToken returns error? */
    getNextTokenString (&numArgs, pArgs, cmdString);
    
    /* Get the hash value of the command passed */
    cmdHashValue = getHashValue (cmdString);

    /* Iterate through the throughputTestArray and calls the function */
    while (help != throughputTestArray[counter].cmdHashValue)
    {
        if(cmdHashValue == throughputTestArray[counter].cmdHashValue)
        {
            /* found a valid command */
            validCommand = TRUE;

            /* Call the function and break out */
            throughputTestArray[counter].fxn (numArgs, pArgs);

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
        printThroughputUsage (numArgs, pArgs);
    }

    return;
}	


void handleThroughputTest(IN int numArgs, IN const char ** argv)
{
    extern int enableCpuLoad;

#if 1
    enableCpuLoad = TRUE; /* CPU Load calculation is enabled by default in ThruPut test also */
#else    
    enableCpuLoad = FALSE; /* CPU Load calculation is not enabled */ 
#endif
    handlePerfRequest(numArgs, argv);
}

void handleCpuLoadTest(IN int numArgs, IN const char ** argv)
{
    extern int enableCpuLoad;

    enableCpuLoad = TRUE; /*CPU Load calculation is enabled */ 
    handlePerfRequest(numArgs, argv);
}


/* vim: set ts=4 sw=4 tw=80 et:*/

