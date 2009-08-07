# MakeFile function	:: MakeFile for System Test of Davinci Monta Vista Linux
# Creation  Date	:: 07/17/2008
# Author		:: Anand Patil  	
# Modification Details  :: Modified for proper depednecy check
#			   Excluding the Video Module TesrCode due to change in drivwr code		
# Modification  Date	:: 22/11/2006    


RELEASE	 	= MVL1.0_P14
TOOL_PREFIX	= arm_v5t_le-
CC		= $(TOOL_PREFIX)gcc
CFLAGS		= -g -Wall -O1 -fomit-frame-pointer 
LDFLAGS		= -static 
#KERNEL_INC	= -I /view/lsp120_yl_cm014/vobs/data_asppsp_linux/montavista_linux/Linux/include  
#BIN		= bin
SRCS_IO		= vpfe_dm355_interface.o v4l2_cap_io.o
SRCS_IOCTL		= vpfe_dm355_interface.o v4l2_cap_ioctl.o
SRCS_AEW	= aew_test_app.o
SRCS_AF		= af_test_app.o
SRCS_PREV	= PreviewerExample.o
SRCS_RSZ_1	= PlanarResize.o
SRCS_RSZ_2	= YUVMultiPassResize.o
OUTPUT_IO	= v4l2_cap_io
OUTPUT_IOCTL	= v4l2_cap_ioctl
OUTPUT_AEW	= aew_test_app	
OUTPUT_AF	= af_test_app
OUTPUT_PREV	= PreviewerExample
OUTPUT_RSZ_1	= PlanarResize
OUTPUT_RSZ_2	= YUVMultiPassResize

all : FBDEV_IO #FBDEV_LCD1 FBDEV_LCD2 FBDEV_LCD3 FBDEV_PROG FBDEV_LOOP PREV_FUNC RSZ_FUNC1 RSZ_FUNC2 AF_FUNC AEW_FUNC v4l2_cap_ioctl V4l2_CAP_IO

V4L2_CAP_IO : $(SRCS_IO)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_IO) $^ -lpthread

v4l2_cap_ioctl : $(SRCS_IOCTL)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_IOCTL) $^ -lpthread
AEW_FUNC : $(SRCS_AEW)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_AEW) $^ -lpthread
AF_FUNC : $(SRCS_AF)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_AF) $^ -lpthread
PREV_FUNC : $(SRCS_PREV)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_PREV) $^ 
RSZ_FUNC1 : $(SRCS_RSZ_1)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_RSZ_1) $^ 
RSZ_FUNC2 : $(SRCS_RSZ_2)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT_RSZ_2) $^
FBDEV_LOOP : fbdev_loopback.o
	$(CC) $(LDFLAGS) -o $(BIN)/fbloop_comp $^
FBDEV_LCD1 : dlcd_example.o
	$(CC) $(LDFLAGS) -o $(BIN)/dlcd_example $^
FBDEV_LCD2 : dlcd_example_400.o
	$(CC) $(LDFLAGS) -o $(BIN)/dlcd_example_400 $^
FBDEV_LCD3 : dlcd_example_350.o
	$(CC) $(LDFLAGS) -o $(BIN)/dlcd_example_350 $^
FBDEV_PROG : progressive_example.o
	$(CC) $(LDFLAGS) -o $(BIN)/progressive_example $^
FBDEV_IO : fbdev_io.o
	$(CC) $(LDFLAGS) -o $(BIN)/fbdev_io $^

%.o : %.c
	$(CC) $(CFLAGS) $(KERNEL_INC) -D$(PLATFORM) -c  $^

install:
#	cp -f $(OUTPUT) $(NFS_ROOT)/yan/dm355/$(OUTPUT)
#	ln -f $(OUTPUT) ../bin/$(OUTPUT)

clean: 
	rm -f $(BIN)/$(OUTPUT) *.o core
	cd utils; $(MAKE)/clean
