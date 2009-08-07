-include GENDEFS

#CC = arm_v5t_le-gcc
VERSION_STRING = "1.00"

TARGETS	= clock_test itimer_test
FLAGS	= -O0 -g3 -Wall -Wno-nonnull
LIBS 	= -lpthread -lrt
#LIBS	= -lpthread -lposixtime
#DESTDIR	= /usr/local
#INSTDIR = $(DESTDIR)/bin
BIN	= bin

all: $(TARGETS)

clock_test: src/clock_test/clock_test.c
	$(CC) $(FLAGS) -D VERSION_STRING=$(VERSION_STRING) $^ -o $(BIN)/$@ $(LIBS)

itimer_test: src/itimer_test/itimer_test.c
	$(CC) $(FLAGS) -D VERSION_STRING=$(VERSION_STRING) $^ -o $(BIN)/$@ $(LIBS)

CLEANUP = $(TARGETS) *.o

clean:
	for F in $(CLEANUP); do find -type f -iname $$F | xargs rm -f; done

distclean: clean

#install: all
#	cp $(BIN)/$(TARGETS) $(DESTDIR)/bin

