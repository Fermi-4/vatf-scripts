# MakeFile function	:: MakeFile for System Test of Davinci Monta Vista Linux
# Creation  Date	:: 01/16/2008
# Author		:: Arun Mani  	
# Modification Details  :: Modified for proper depednecy check
#			   Excluding the Video Module TesrCode due to change in drivwr code		
# Modification  Date	:: 12/22/2008    


RELEASE	 	= MVL5.0
TOOL_PREFIX	= arm_v5t_le-
CC		= $(TOOL_PREFIX)gcc
CFLAGS		= -g -Wall -O1 -fomit-frame-pointer 
LDFLAGS		= -static 
#KERNEL_INC	= -I /view/a0270733_LSP210_Release_int/vobs/data_asppsp_linux/montavista_linux/release/linux-2.6.18_pro500/include  
BIN		= bin
#SRCS_SD		= v4l2_display.o v4l2_capture.o v4l2_loop.o
#OUTPUT_IO	= v4l2_loop_sd


all : V4L2_OTF V4L2_SS 

V4L2_OTF : otf_yuv.o
	$(CC) $(LDFLAGS) -o $(BIN)/otf_yuv $^ -lpthread

V4L2_SS : ss_yuv.o
	$(CC) $(LDFLAGS) -o $(BIN)/ss_yuv $^ -lpthread
	
%.o : %.c
	$(CC) $(CFLAGS) -I $(KERNEL_INC) -c  $^

install:
#	cp -f $(OUTPUT) $(NFS_ROOT)/yan/dm355/$(OUTPUT)
#	ln -f $(OUTPUT) ../bin/$(OUTPUT)

clean: 
	rm -f $(BIN)/$(OUTPUT) *.o core
	cd utils; $(MAKE)/clean
