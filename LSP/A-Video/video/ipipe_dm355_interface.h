/* This file contains the DM355 Specific APIs,Constants and Global Variables used for the initialization, Configuration and usage of IPIPE modules provided in the Linux Support package version 2.10

			Author	: 	Arun Vijay Mani
			Date	:	06/12/2008
			Version	:	0.1
***************************************************************************************************************************/
#include <media/davinci/imp_common.h>
#include <media/davinci/imp_previewer.h>
#include <media/davinci/imp_resizer.h>
#include <media/davinci/dm355_ipipe.h>


// Constants
#define DEV_PREV 0
#define DEV_RSZ 1
#define DEV_PREV_NAME "/dev/davinci_previewer"
#define DEV_RSZ_NAME "/dev/davinci_resize"
// General APIs

int Imp_Open(int device_id, int mode);
int Prev_Init(int ,int , struct prev_channel_config *, int, int, int);
int Set_Prev_Config(int, struct prev_channel_config *);
int Init_Prev_Param(int);
int Init_Prev_Buffer(int, int, struct buffer *, int ,int);
int Set_Prev_buf(int, struct imp_convert *, struct imp_buffer *, struct imp_buffer *);


