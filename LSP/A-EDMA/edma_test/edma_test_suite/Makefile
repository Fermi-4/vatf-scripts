# MakeFile function     :: MakeFile for compiling edma test suite 

#Tool chain path. Change based on your toolchain installation.
TOOL_PREFIX = arm-none-linux-gnueabi-

#Path of Kernel directory- Change based on the target kernel installation.
#KERNEL_DIR = /opt/kernel/davinci-git-0623/git
KERNEL_DIR := $(patsubst -I,, $(patsubst %/include,%,$(KERNEL_INC)) )
BIN = bin
PRODUCT = LSP-3.00

PWD := $(shell pwd)

#Installation directory - Change based on desired path for placing test suite executable
INSTDIR         = ../bin

#Path of header files to be included
EXTRA_CFLAGS := -I$(src)/../utils/kernellevel
EXTRA_CFLAGS += -I$(src)/src/interface/common
EXTRA_CFLAGS += -I$(src)/src/interface/$(PRODUCT)
#List of source files- Update this on adding a new C file
SOURCES := \
        src/testcases/kSt_edma.o \
        src/testcases/kSt_edma_chain.o \
        src/testcases/kSt_edma_qdma.o \
        src/testcases/kSt_edma_link.o \
        src/parser/kSt_edma_parser.o \
        src/interface/$(PRODUCT)/kSt_edma_interface.o 

obj-m += edma_test.o ../utils/kernellevel/kStTimer.o
edma_test-objs := $(SOURCES)

#Rule to build
all:
	$(MAKE) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(TOOL_PREFIX) M=$(PWD) 
	mv -f edma_test.ko ../utils/kernellevel/kStTimer.ko $(INSTDIR)

#Rule to clean
clean:
	rm -f  *.o
	rm -f  *.order
	rm -f  *.c
	rm -f  *.symvers
	rm -f  ./bin/*.ko
	rm -f  ./src/testcases/*.o*
	rm -f  ./src/parser/*.o*
	rm -f  ./src/interface/$(PRODUCT)/*.o*
