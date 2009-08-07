ifeq ($(PLATFORM_NAME),DM644X)
	MAKEFILE_NAME=Makefile_dm644x 
endif
ifeq ($(PLATFORM_NAME),DM646X)
	MAKEFILE_NAME=Makefile_dm646x 
endif
ifeq ($(PLATFORM_NAME),OMAP35X)
	MAKEFILE_NAME=Makefile_omap35x 
endif

# Make sure 'Make' points to the right toolchain
#$(shell PATH="/opt/mv_pro_5.0/montavista/pro/devkit/arm/v5t_le/bin:/opt/mv_pro_5.0/montavista/pro/bin:/opt/mv_pro_5.0/montavista/common/bin:/usr/atria/bin:/usr/bin:/usr/kerberos/bin:/apps/cscope/current/bin:/apps/ame/bin:/apps/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/X11R6/bin:/opt/rational/clearcase/bin:/apps/local/lsf/bin:/usr/local/bin")

KERNEL_INCLUDE_DIR :=$(patsubst -I,, $(patsubst %/include,%,$(KERNEL_INC)) )

all:
	$(MAKE) all -C $(APP_HOME)/src/ -f $(MAKEFILE_NAME) TOOL_PREFIX=arm_v5t_le- KERNEL_INCLUDE_DIR=$(KERNEL_INCLUDE_DIR) PLATFORM_NAME=$(PLATFORM_NAME)

clean:
	$(MAKE) clean -C $(APP_HOME)/src/ -f $(MAKEFILE_NAME) PLATFORM_NAME=$(PLATFORM_NAME)




