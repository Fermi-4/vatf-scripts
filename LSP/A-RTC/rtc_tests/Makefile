# Modification  Date	:: 22/11/2006    

-include GENDEFS

CFLAGS		= -g -Wall -O1 -fomit-frame-pointer 
LDFLAGS		= -static 
#KERNEL_INC	= -I /view/121_lsp_dm6446/vobs/data_asppsp_linux/montavista_linux/Linux/include  
BIN		= bin
#PLATFORM	= DM6446
SRCS		= rtc_test.o
OUTPUT		= rtc_test

all : $(SRCS)
	$(CC) $(LDFLAGS) -o $(BIN)/$(OUTPUT) $^ -lpthread

%.o : %.c
	$(CC) $(CFLAGS) -I$(KERNEL_INC) -D$(PLATFORM_NAME) -c  $^

install:
#	cp -f $(OUTPUT) $(NFS_ROOT)/yan/dm355/$(OUTPUT)
#	ln -f $(OUTPUT) ../bin/$(OUTPUT)

clean: 
	rm -f $(BIN)/$(OUTPUT) *.o core
