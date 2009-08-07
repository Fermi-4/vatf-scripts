-include GENDEFS
obj-m := edma_test.o 

PWD := $(shell pwd)
KERNEL_DIR := $(patsubst -I,, $(patsubst %/include,%,$(KERNEL_INC)) )
#KERNEL_DIR	:= /view/210_lsp_dm355/vobs/data_asppsp_linux/montavista_linux/Linux
BIN = bin

all:
#	$(MAKE) -C $(KERNEL_DIR) $(CPPFLAGS) M=$(PWD) modules
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules
	cp *.ko $(BIN)
clean:
	rm -rf *.o *.ko *.mod.c .*.cmd .tmp_versions
