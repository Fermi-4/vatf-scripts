-include $(PSP_TEST_HOME)/GENDEFS
LDFLAGS=
INC=.

obj-m := kStTimer.o  

PWD := $(shell pwd)

all:
	$(MAKE) -C  $(KERNEL_DIR) -I $(KERNEL_INC) -I $(KERN_UTIL_INC) -I $(INC) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE_OPTION) M=$(PWD) modules ; \
	$(CP) *.ko $(BIN)
clean:
	rm -rf *.o *.ko *.mod.c .*.cmd .tmp_versions
