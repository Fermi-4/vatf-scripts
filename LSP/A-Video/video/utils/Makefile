# Make file for FBDEV utilities
CROSS_COMPILE = arm_v5t_le-
#LINUXKERNEL_INSTALL_DIR = /vobs/data_asppsp_linux/montavista_linux/release/linux-2.6.18_pro500
#CFLAGS = -Wall -I $(LINUXKERNEL_INSTALL_DIR)/include

CC = $(CROSS_COMPILE)gcc

all: blend blank rgbwrite mmapvid setposx setposy setzoom endisattrwin getstd getblinkint setcursor setblinkint setbkgcolor endiswin sbmpwramclut fbdev_io

blend: blend.o
	$(CC) -o ../blend $^

blank: blank.o
	$(CC) -o ../blank $^

rgbwrite: rgbwrite.o
	$(CC) -o ../rgbwrite $^

mmapvid: mmapvid.o
	$(CC) -o ../mmapvid $^

setposx: setposx.o
	$(CC) -o ../setposx $^

setposy: setposy.o
	$(CC) -o ../setposy $^

setzoom: setzoom.o
	$(CC) -o ../setzoom $^

endisattrwin: endisattrwin.o
	$(CC) -o ../endisattrwin $^

endiswin: endiswin.o
	$(CC) -o ../endiswin $^

getstd: getstd.o
	$(CC) -o ../getstd $^

getblinkint: getblinkint.o
	$(CC) -o ../getblinkint $^

setblinkint: setblinkint.o
	$(CC) -o ../setblinkint $^

getbkgcolor: getbkgcolor.o
	$(CC) -o ../getbkgcolor $^

setcursor: setcursor.o
	$(CC) -o ../setcursor $^

sbmpwramclut: sbmpwramclut.o
	$(CC) -o ../sbmpwramclut $^

fbdev: fbdev_io.o
	$(CC) -o ../fbdev_io $^

%.o:%.c
	$(CC) $(CFLAGS) -c $^

clean:
	rm -f *.o *~ blend blank rgbwrite mmapvid setposx setposy setzoom endisattrwin getstd getblinkint setblinkint setbkgcolor setcursor endiswin sbmpwramclut
