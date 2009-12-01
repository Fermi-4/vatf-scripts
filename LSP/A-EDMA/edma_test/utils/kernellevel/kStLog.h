/*
 * kStfLog.h
 *
 * Common header file for kernel level logging
 *
 * Copyright (C) 2009 Texas Instruments Incorporated - http://www.ti.com/
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as 
 * published by the Free Software Foundation version 2.
 *
 * This program is distributed “as is” WITHOUT ANY WARRANTY of any
 * kind, whether express or implied; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#ifndef _KSTLOG_H_
#define _KSTLOG_H_


/*----------------------------------------------------------------------------
  Include Files
  ----------------------------------------------------------------------------*/

#include <asm/io.h>


#define PERFLOG(...) printk("%s:%s:%d:", __FILE__, __FUNCTION__, __LINE__); \
                     printk(__VA_ARGS__)


/* to enable START, END, TEST RESULT, WARNING and ERROR MACROS */
#define ST_ENABLE_PRINT

/* this is not enabled by default - uncomment this to enable TRC0 */

#define ST_ENABLE_TRC0


/*----------------------------------------------------------------------------
  Define Macros
  ----------------------------------------------------------------------------*/

/* This is mandatory and is always enabled */
#define DBG_PRINT_TRC(x) printk x ;\
	                     printk ("\n"); 
	                    
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
 * eg:  #define LINUXI2C0250 "LINUXI2C0250|Configure for  TV out display|"
 * */


#define DBG_PRINT_TST_START(x) printk ("\n\n|TEST START| "); \
	                        printk x; \
	                        printk ("|"); \
	                        printk ("\n");

/* Enable the warning logs */
#define DBG_PRINT_WRG(x) printk ("\n\n|WARNING| "); \
                         printk("Warning Line: %d, File: %s - ", \
                                __LINE__, __FILE__); \
                         printk x ; \
	                     printk ("|"); \
	                     printk ("\n");                          

/* Enable the error logs */	                        
#define DBG_PRINT_ERR(x) printk ("\n\n|ERROR| "); \
                         printk("*ERROR* Line: %d, File: %s - ", \
	                            __LINE__, __FILE__); \
	                     printk x ; \
	                     printk ("|"); \
	                     printk ("\n");

/* Used to represent the PASS result of the test case. The parameter to this
 * function call will be a macro representing the testcase description and test
 * result.  The use of separate macros to represent pass and fail criteria
 * improves the readability and eliminates the requirement of passing the result
 * a parameter.
 * For eg: DBG_PRINT_TST_RESULT_PASS((LINUXI2C0250)) ; 
 * The test case id LINUXI2C0250 is a macro.
 * */	                     
#define DBG_PRINT_TST_RESULT_PASS(x) printk ("|TEST RESULT|PASS| "); \
                                     printk x ; \
	                                 printk ("|"); \
	                        		 printk ("\n");


/* Used to represent the FAIL result of the test case. The parameter to this
 * function call will be a macro representing the testcase description and test
 * result. The use of separate macros to represent pass and fail criteria
 * improves the readability and eliminates the requirement of passing the result
 * a parameter.
 * For eg: DBG_PRINT_TST_RESULT_FAIL((LINUXI2C0250)) ; 
 * The test case id LINUXI2C0250 is a macro.
 * */
#define DBG_PRINT_TST_RESULT_FAIL(x) printk ("|TEST RESULT|FAIL| "); \
                                     printk x ; \
	                                 printk ("|"); \
	                        		 printk ("\n");


/* Used to represent the end of the test case. The parameter to this
 * function call will be a macro representing the testcase description.
 * For eg: DBG_PRINT_TST_END((LINUXI2C0250)) ; 
 * The test case id LINUXI2C0250 is a macro which can be defined as follows:
 * #define LINUXI2C0250 "LINUXI2C0250|" 
 * Since the id is defined as a macro, in future we can also create a way to
 * generate meaningful description corresponding to the id automatically from
 * the test matrix
 * eg:  #define LINUXI2C0250 "LINUXI2C0250|Configure display driver for TV Out|"
 * */                                                                                     
#define DBG_PRINT_TST_END(x) printk ("|TEST END| "); \
	                        printk x; \
	                        printk ("|"); \
	                        printk ("\n");                                     	                       


/* Trace without additional prints */
#define DBG_PRINT_TRC_NEOL(x) printk x;
#endif /*ST_ENABLE_PRINT*/        


#ifdef ST_ENABLE_TRC0
#define DBG_PRINT_TRC0(x) printk ("| TRACE LOG| "); \
                         printk x ;\
	                     printk ("|"); \
	                     printk ("\n"); 
#else
#define DBG_PRINT_TRC0(x) 
#endif /*ST_ENABLE_TRC0*/


#endif  /*_KSTLOG_H_ */


/* vim: set ts=4 sw=4 tw=80 et:*/
