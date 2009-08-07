# MakeFile function	:: MakeFile for System Test of Davinci Monta Vista Linux
# Creation  Date	:: 01/13/2009
# Author		:: Arun Mani  	
# Modification Details  :: Modified for proper depednecy check
#			   Excluding the Video Module TesrCode due to change in drivwr code		
# Modification  Date	:: 01/13/2009    


RELEASE	 	= MVL5.0
TOOL_PREFIX	= arm_v5t_le-
CC		= $(TOOL_PREFIX)gcc
CFLAGS		= -g -Wall -O1 -fomit-frame-pointer 
LDFLAGS		= -static 
#KERNEL_INC	= -I /view/a0270733_LSP210_Release_int/vobs/data_asppsp_linux/montavista_linux/release/linux-2.6.18_pro500/include  
BIN		= bin
SRCS_HD		= v4l2_display.o v4l2_capture.o v4l2_loop.o
#OUTPUT_OSS	= audiolb_oss
OUTPUT_HD	= v4l2_loop_hd
#OUTOUT_ALSA	= psp_test_bench 


all : VIDEO_HD 

VIDEO_HD : v4l2_display.o v4l2_capture.o v4l2_loop.o
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_HD) $^ -lpthread

#AUDIO_ALSA : psp_test_bench.o
#	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_ALSA) $^ -lpthread
%.o : %.c
	$(CC) $(CFLAGS) -I $(KERNEL_INC) -c  $^

install:
#	cp -f $(OUTPUT) $(NFS_ROOT)/yan/dm355/$(OUTPUT)
#	ln -f $(OUTPUT) ../bin/$(OUTPUT)

clean: 
	rm -f $(BIN)/$(OUTPUT_HD) *.o core
	cd utils; $(MAKE)/clean
