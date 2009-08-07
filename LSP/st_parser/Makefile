# MakeFile function	:: MakeFile for System Test of Davinci Monta Vista Linux
# Creation  Date	:: 18/09/2006
# Author		:: Anand Patil  	
# Modification Details  :: Modified for proper depednecy check
#			   Excluding the Video Module TesrCode due to change in drivwr code		
# Modification  Date	:: 22/11/2006    

-include GENDEFS

CFLAGS		= -g -Wall -O1 -fomit-frame-pointer 
LDFLAGS		= -static 
#KERNEL_INC	= -I /view/lsp120_yl_cm014/vobs/data_asppsp_linux/montavista_linux/Linux/include  
BIN		= bin
SRCS		= st_process.o st_automation_io.o st_common.o st_ata_parser.o st_audio.o st_audio_multiprocess.o st_blk_multitask.o\
		  st_blk_pfmnce.o st_blk_stress.o st_fstests.o st_linuxdev.o st_linuxdevio.o st_linuxfile.o st_linuxfile_parser.o\
		  st_i2c.o st_i2c_multi_process.o st_mmcsd_parser.o st_nand_parser.o st_nor_parser.o st_system_tests.o st_timer.o\
		  st_uart.o st_uart_multiprocess.o st_wdt_parser.o #st_pwm.o
OUTPUT		= st_parser

all : $(SRCS)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT) $^ -lpthread

%.o : %.c
	$(CC) $(CFLAGS) -I$(KERNEL_INC) -D$(PLATFORM_NAME) -c  $^

install:
#	cp -f $(OUTPUT) $(NFS_ROOT)/yan/dm355/$(OUTPUT)
#	ln -f $(OUTPUT) ../bin/$(OUTPUT)

clean: 
	rm -f $(BIN)/$(OUTPUT) *.o core
