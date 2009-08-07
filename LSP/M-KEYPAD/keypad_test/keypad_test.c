#include <stdio.h>
#include <fcntl.h>
/*
 * to run this program we have to choose Event interface under 
 * Input device support when  make menuconfig
 *
*/

int main(void)
{
	struct input_event {
		struct timeval time;
		unsigned short type;
		unsigned short code;
		unsigned int value;
	} keyinfo;
	int bytes;
	int fd = open("/dev/input/event0", O_RDONLY);

	if (fd > 0) {
		while (1) {
			bytes = read(fd, &keyinfo, sizeof(struct input_event));
			if (bytes && keyinfo.type == 0x01) {
				printf
				    ("time=%ld sec %ld microsec,code=%d,value=%d\n",
				     keyinfo.time.tv_sec, keyinfo.time.tv_usec,
				     keyinfo.code, keyinfo.value);
				fflush(stdout);     
			}
		}
	}

	return 0;
}
