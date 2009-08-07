# Initialize DIRS variable with sub-directories to be built
$(shell ln -s -f $(PLATFORM_NAME)_config.h config/config.h)
$(shell ln -s -f $(PLATFORM_NAME)_CURRENTCFG.MK config/CURRENTCFG.MK)
#$(shell export PSP_TEST_HOME=$APP_HOME)
export PSP_TEST_HOME=$APP_HOME

# Make sure 'Make' points to the right toolchain
$(shell PATH="/opt/mv_pro_5.0/montavista/pro/devkit/arm/v5t_le/bin:/opt/mv_pro_5.0/montavista/pro/bin:/opt/mv_pro_5.0/montavista/common/bin:/usr/atria/bin:/usr/bin:/usr/kerberos/bin:/apps/cscope/current/bin:/apps/ame/bin:/apps/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/X11R6/bin:/opt/rational/clearcase/bin:/apps/local/lsf/bin:/usr/local/bin")

PSP_TEST_HOME = $(APP_HOME)

all:
	$(MAKE) -C $(PSP_TEST_HOME)/make/target/

clean:
	$(MAKE) clean -C $(PSP_TEST_HOME)/make/target/

install: 
	$(MAKE) install -C  $(PSP_TEST_HOME)/make/target/


