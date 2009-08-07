struct buffer
{
  	void *start;
	int index;
  	size_t length;
};

struct buffer *cap_buffers; //= NULL;
struct buffer *disp_buff_info;// = NULL;
//struct buffer *buff_info;
int display_image_size;
static int glob_index = 0;

#define CLEAR(x) memset (&(x), 0, sizeof (x))
