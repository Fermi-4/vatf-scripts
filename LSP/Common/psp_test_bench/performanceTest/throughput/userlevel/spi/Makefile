###############################################################################
##+-------------------------------------------------------------------------+##
##|                            ####                                         |##
##|                            ####                                         |##
##|                            ######o###                                   |##
##|                      ########_///_####                                  |##
##|                      ##### /_//_/ ####                                  |##
##|                       ## ## (__/ ####                                   |##
##|                           #########                                     |##
##|                            ####                                         |##
##|                            ###                                          |##
##|                                                                         |##
##|         Copyright (c) 1998-2004 Texas Instruments Incorporated          |##
##|                        ALL RIGHTS RESERVED                              |##
##|                                                                         |##
##| Permission is hereby granted to licensees of Texas Instruments          |##
##| Incorporated (TI) products to use this computer program for the sole    |##
##| purpose of implementing a licensee product based on TI products.        |##
##| No other rights to reproduce, use, or disseminate this computer         |##
##| program, whether in part or in whole, are granted.                      |##
##|                                                                         |##
##| TI makes no representation or warranties with respect to the            |##
##| performance of this computer program, and specifically disclaims        |##
##| any responsibility for any damages, special or consequential,           |##
##| connected with the use of this program.                                 |##
##|                                                                         |##
##+-------------------------------------------------------------------------+##
###############################################################################

#
#  \file   Makefile 
#
#  \brief  Makefile for utils
#
#  (C) Copyright 2007, Texas Instruments, Inc
#
#  \version	0.1     Siddharth Heroor   	Created
#

-include DIRS
-include $(PSP_TEST_HOME)/GENDEFS

all:
	for dir in $(DIRS); do \
		$(MAKE) -C $$dir; \
	done

clean:
	for dir in $(DIRS); do \
		$(MAKE) clean -C $$dir; \
	done
	

