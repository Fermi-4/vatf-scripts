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
#  \brief  Toplevel Makefile
#
#  (C) Copyright 2007, Texas Instruments, Inc
#
#  \version	0.1     Siddharth Heroor   	Created
#		0.2	Siddharth Heroor	Updated to use PSP_TEST_HOME for all
#						include paths
#

-include $(PSP_TEST_HOME)/DIRS
-include $(PSP_TEST_HOME)/SCRIPTDIRS
-include $(PSP_TEST_HOME)/GENDEFS
include $(PSP_TEST_HOME)/config/CURRENTCFG.MK

all:
	for dir in $(DIRS); do \
		$(MAKE) -C $$dir; \
	done
	if [ $(USE_TP_USER) -eq 1 ] || [ $(USE_FN_USER) -eq 1 ]; then \
	$(CC) -o $(BIN)/$(PROG) $(LDFLAGS) $(BIN)/*.o -lm; \
	fi;
	$(RM) -f $(BIN)/*.o

clean:
	for dir in $(DIRS); do \
		$(MAKE) clean -C $$dir; \
	done
	$(RM) -f $(BIN)/*.o $(BIN)/*.ko $(BIN)/$(PROG) 
	$(RM) -rf $(INSTALL_DIR)/$(INSTALL_TARGET_DIR) 

install: all
	mkdir -p $(INSTALL_DIR)/$(INSTALL_TARGET_DIR)
	mkdir -p $(INSTALL_DIR)/$(INSTALL_TARGET_DIR)/bin
	mkdir -p $(INSTALL_DIR)/$(INSTALL_TARGET_DIR)/scripts
	$(CP) $(BIN)/pspTest $(INSTALL_DIR)/$(INSTALL_TARGET_DIR)/bin
ifneq ($(PLATFORM),OMAP35x)
	$(CP) $(BIN)/*.ko $(INSTALL_DIR)/$(INSTALL_TARGET_DIR)/bin
endif
	for dir in $(SCRIPTDIRS); do \
                $(MAKE) install -C $$dir; \
        done
	chmod -R +x $(INSTALL_DIR)/$(INSTALL_TARGET_DIR)/scripts
	dos2unix $(INSTALL_DIR)/$(INSTALL_TARGET_DIR)/scripts/*/*.sh
	$(CP) -R $(PATH_FOR_YUV)/ $(INSTALL_DIR)/$(INSTALL_TARGET_DIR)

