#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>	
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

struct buffer
{
  	void *start;
	int index;
  	size_t length;
} *cap_buffers, *disp_buffers;


