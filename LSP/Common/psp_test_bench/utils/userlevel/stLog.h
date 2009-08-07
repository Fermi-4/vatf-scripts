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
 *  \file   stLog.h
 *
 *  \brief      This file implements functions to parse through the 
 *              command line arguments
 *
 *  (C) Copyright 2007, Texas Instruments, Inc
 *
 *  \note       
 *              
 *  \history    0.1     Siddharth Heroor   Created
 */

#ifndef _ST_LOG_H_
#define _ST_LOG_H_

#include <stdio.h>
#include <stDefines.h>

#define PERFLOG(...) printf("%s:%s:%d:", __FILE__, __FUNCTION__, __LINE__); \
                     printf(__VA_ARGS__)


/* to enable START, END, TEST RESULT, WARNING and ERROR MACROS */
#define ST_ENABLE_PRINT

/* this is not enabled by default - uncomment this to enable TRC0 */

#define ST_ENABLE_TRC0


/*----------------------------------------------------------------------------
  Define Macros
  ----------------------------------------------------------------------------*/

/* This is mandatory and is always enabled */
#define DBG_PRINT_TRC(x) printf x ;\
	                     printf ("\n"); 
	                    
/****************** DBG Prints enabled by default ************/
#ifdef ST_ENABLE_PRINT

/* Used to represent the beginning of the test case. The parameter to this
 * function call will be a macro representing the testcase description.
 * For eg: DBG_PRINT_TST_START((LINUXI2C0250)) ; 
 * The test case id LINUXI2C0250 is a macro which can be defined as follows:
 * #define LINUXI2C0250 |LINUXI2C0250|" 
 * Since the id is defined as a macro, in future we can also create a way to
 * generate meaningful description corresponding to the id automatically from
 * the test matrix
 * eg:  #define LINUXI2C0250 "LINUXI2C0250|Configure I2C driver in: Polled mode|"
 * */


#define DBG_PRINT_TST_START(x) printf ("\n\n|TEST START| "); \
	                        printf x; \
	                        printf ("\n");

/* Enable the warning logs */
#define DBG_PRINT_WRG(x) printf("Warning Line: %d, File: %s - ", \
                                __LINE__, __FILE__); \
                         printf x ; \
	                     printf ("\n");                          

/* Enable the error logs */	                        
#define DBG_PRINT_ERR(x) printf("*ERROR* Line: %d, File: %s - ", \
	                            __LINE__, __FILE__); \
	                     printf x ; \
	                     printf ("\n");

/* Used to represent the PASS result of the test case. The parameter to this
 * function call will be a macro representing the testcase description and test
 * result.  The use of separate macros to represent pass and fail criteria
 * improves the readability and eliminates the requirement of passing the result
 * a parameter.
 * For eg: DBG_PRINT_TST_RESULT_PASS((LINUXI2C0250)) ; 
 * The test case id LINUXI2C0250 is a macro.
 * */	                     
#define DBG_PRINT_TST_RESULT_PASS(x) printf ("|TEST RESULT|PASS| "); \
                                     printf x ; \
	                        		 printf ("\n");


/* Used to represent the FAIL result of the test case. The parameter to this
 * function call will be a macro representing the testcase description and test
 * result. The use of separate macros to represent pass and fail criteria
 * improves the readability and eliminates the requirement of passing the result
 * a parameter.
 * For eg: DBG_PRINT_TST_RESULT_FAIL((LINUXI2C0250)) ; 
 * The test case id LINUXI2C0250 is a macro.
 * */
#define DBG_PRINT_TST_RESULT_FAIL(x) printf ("|TEST RESULT|FAIL| "); \
                                     printf x ; \
	                        		 printf ("\n");


/* Used to represent the end of the test case. The parameter to this
 * function call will be a macro representing the testcase description.
 * For eg: DBG_PRINT_TST_END((LINUXI2C0250)) ; 
 * The test case id LINUXI2C0250 is a macro which can be defined as follows:
 * #define LINUXI2C0250 "LINUXI2C0250|" 
 * Since the id is defined as a macro, in future we can also create a way to
 * generate meaningful description corresponding to the id automatically from
 * the test matrix
 * eg:  #define LINUXI2C0250 "LINUXI2C0250|Configure I2C driver in: Polled mode|"
 * */                                                                                     
#define DBG_PRINT_TST_END(x) printf ("|TEST END| "); \
	                        printf x; \
	                        printf ("\n\n");                                     	                       


/* Trace without additional prints */
#define DBG_PRINT_TRC_NEOL(x) printf x;
#endif /*ST_ENABLE_PRINT*/        


#ifdef ST_ENABLE_TRC0
#define DBG_PRINT_TRC0(x) printf x ;\
	                     printf ("\n"); 
#else
#define DBG_PRINT_TRC0(x) 
#endif /*ST_ENABLE_TRC0*/


#endif /* _ST_LOG_H_ */

/* vim: set ts=4 sw=4 tw=80 et:*/

