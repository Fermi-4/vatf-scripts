-include $(PSP_TEST_HOME)/GENDEFS


obj-m := vlynqCpuTransfer.o vlynqEdmaTransfer.o
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KERNEL_DIR) -I $(KERNEL_INC) -I $(KERN_UTIL_INC) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE_OPTION) M=$(PWD) modules
	$(CP) *.ko $(BIN)
clean:
	rm -rf *.o *.ko *.mod.c *.symvers .*.cmd .tmp_versions
