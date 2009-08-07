/* Linux include files */
#include <stdio.h>
#include <sys/ioctl.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <fcntl.h>
//#include <string.h>
#include <asm/arch/davinci_previewer.h>
#include <sys/mman.h>

/* header file containing bayer image */
#include "bayerimage.h"


/* image size */
#define HEIGHT  480
#define WIDTH   640

#define OUTPUT_FILE_NAME    "out.YUV"

/* structure buffer used for storing mapped buffer's addresses 
   and their size */

struct buffer {
	void *addr;		/* mapped address of the buffer */
	int length;		/* size of the buffer */
};


#define R_PHASE \
0,   0,    0, 0, \
0,   64,   0, 0, \
0,   0,    0, 0, \
0,   0,    0, 0, \
\
0,   16,   0, 0, \
16,   0,   16,0, \
\
16,   0,   16,0,  \
0,    0,   0, 0, \
16,   0,   16,0, \
0,    0,   0, 0, \
\
0,    16,  0, 0,  \
0,    0,   0, 0, \
\
0,   0,    0, 0,  \
0,   64,   0, 0, \
0,   0,    0, 0, \
0,   0,    0, 0, \
\
0,   0,    0, 0, \
32,  0,   32, 0, \
\
16,-26,   16, 0,  \
26, 0,    26, 0, \
16,-26,   16, 0, \
0,  0,    0,  0, \
\
0,  0,    0,  0, \
0,  0,    0,  0,\
\
0,  0,    0,  0,  \
0, 64,    0,  0,  \
0,  0,    0,  0, \
0,  0,    0,  0, \
\
0, 32,    0,  0, \
0,  0,    0,  0, \
\
16, 26,   16, 0, \
-26, 0,  -26, 0, \
16, 26,   16, 0, \
0,   0,    0, 0, \
\
0,  32,    0, 0, \
0,  0,     0, 0,

#define GR_PHASE \
-8,  0,   -8, 0,  \
32, 32,   32, 0, \
-8,  0,   -8, 0, \
0,   0,    0, 0, \
\
0,   0,    0, 0, \
0,  64,    0, 0, \
\
-10,32,  -10, 0,  \
0,  40,    0, 0, \
-10,32,  -10, 0, \
0,   0,    0, 0, \
\
0,   0,    0, 0, \
0,   0,    0, 0, \
\
0,   0,    0, 0, \
32,  0,   32, 0, \
0,   0,    0, 0, \
0,   0,    0, 0, \
\
0,   0,    0, 0, \
0,  64,    0, 0, \
\
-13,32,  -13, 0,  \
0,  52,    0, 0,\
-13,32,  -13, 0, \
0,   0,    0, 0, \
\
0,   0,    0, 0, \
0,   0,    0, 0, \
\
-16, 0,  -16, 0,\
 32, 64,  32, 0, \
-16, 0,  -16, 0, \
0,   0,    0, 0, \
\
0,   0,    0, 0, \
0,  64,    0, 0, \
\
0,  32,    0, 0,  \
0,  0,     0, 0, \
0,  32,    0, 0, \
0,  0,     0, 0, \
\
0,  0,     0, 0,\
0,  0,     0, 0,

#define GB_PHASE \
-8, 32, -8, 0,  \
0,  32,  0, 0, \
-8, 32, -8, 0, \
0,   0,  0, 0, \
\
0,   0,  0, 0, \
0,  64,  0, 0, \
\
-8,  0, -8, 0, \
32, 32, 32, 0, \
-8, 0,  -8, 0, \
0,  0,   0, 0, \
\
0,  0,   0, 0, \
0,  0,   0, 0, \
\
-16,32,  -16, 0,  \
0,  64,  0,   0, \
-16,32, -16,  0, \
0,  0,   0,   0, \
\
0,  0,   0,   0, \
0, 64,   0,   0, \
\
0,  0,   0,   0, \
29, 6,  29,   0,  \
0,  0,   0,   0, \
0,  0,   0,   0, \
\
0,  0,   0,   0, \
0,  0,   0,   0, \
\
0, 32,   0,   0,  \
0,  0,   0,   0,  \
0, 32,   0,   0, \
0,  0,   0,   0, \
\
0,  0,   0,   0, \
0, 64,   0,   0, \
\
-13,0,  -13,  0, \
32, 52, 32,   0, \
-13, 0,-13,   0, \
0,   0, 0,    0,  \
\
0,   0, 0,    0, \
0,   0,  0, 0,

#define B_PHASE  \
16,-6,    16, 0, \
6,  0,     6, 0, \
16, -6,   16, 0, \
0,   0,    0, 0, \
\
0,   16,   0, 0,\
16,   0,  16, 0, \
\
0,    0,   0, 0, \
0,   64,   0, 0,  \
0,    0,   0, 0, \
0,    0,   0, 0, \
\
0,   16,   0, 0, \
0,    0,   0, 0, \
\
16, -32,  16, 0, \
32,   0,  32, 0, \
16, -32,  16, 0, \
0,    0,   0, 0, \
\
0,    0,   0, 0, \
32,   0,  32, 0, \
\
0,    0,   0, 0, \
0,   64,   0, 0,  \
0,    0,   0, 0, \
0,    0,   0, 0, \
\
0,    0,   0, 0, \
0,    0,   0, 0, \
\
16, 26,   16, 0,\
-26, 0,  -26, 0, \
16, 26,   16, 0, \
0,   0,    0, 0, \
\
0,  32,    0, 0, \
0,   0,    0, 0, \
\
0,   0,    0, 0, \
0,  64,    0, 0, \
0,   0,    0, 0, \
0,   0,    0, 0, \
\
0,  32,    0, 0, \
0, 0,  0, 0,

static const char cfa_coef[] = {
	R_PHASE GR_PHASE GB_PHASE B_PHASE
};

/* main function */
int main(int argc, char *argv[])
{
	char shortoptions[] = "o:v:";
	struct prev_params params;
	struct prev_reqbufs reqbufs;
	struct prev_buffer t_buff;
	struct prev_convert convert;
	int prevfd, ret, i, j;
	char ay[HEIGHT * WIDTH], acb[HEIGHT * WIDTH / 2],
	    acr[HEIGHT * WIDTH / 2];
	int cy = 0, ccb = 0, ccr = 0,d, options, values;
	struct buffer buff[2];
	FILE *fp;
	int *addr = NULL;


	for (;;) 
	{
		d = getopt_long(argc, argv, shortoptions, (void *) NULL,
				&index);
		if (-1 == d)
			break;
		switch (d) {
			case 0:
				break;
			case 'o':
			case 'O':
				options = atoi(optarg);
				break;
			case 'v':
			case 'V':
				values = atoi(optarg);
				break;
			default:
				exit(1);
		}
	}


	/* Initialize parameters with zero */
	memset(&params, 0, sizeof(params));

	/* Set down sampling rate to 1 */
	params.sample_rate = 1;

	/* Set the input image size */
	params.size_params.hstart = 0;
	params.size_params.vstart = 0;
	params.size_params.hsize = WIDTH;
	params.size_params.vsize = HEIGHT;

	/* Set input image pixel size */
	params.size_params.pixsize = PREV_INWIDTH_8BIT;

	/* Set input buffer line offset */
	params.size_params.in_pitch = WIDTH;

	/* Set output buffer line offset  */
	params.size_params.out_pitch = WIDTH * 2;

	/* Set white balancing parameters */
	params.white_balance_params.wb_dgain = 0x100;
	params.white_balance_params.wb_gain[0] = 0x20;
	params.white_balance_params.wb_gain[1] = 0x20;
	params.white_balance_params.wb_gain[2] = 0x20;
	params.white_balance_params.wb_gain[3] = 0x20;
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
			params.white_balance_params.wb_coefmatrix[i][j] =
			    0x0;
		}
	}

	/* Set RGB2RGB blending coefficients */
	params.rgbblending_params.blending[0][0] = 0x100;
	params.rgbblending_params.blending[0][1] = 0;
	params.rgbblending_params.blending[0][2] = 0;
	params.rgbblending_params.blending[1][0] = 0;
	params.rgbblending_params.blending[1][1] = 0x100;
	params.rgbblending_params.blending[1][2] = 0;
	params.rgbblending_params.blending[2][0] = 0;
	params.rgbblending_params.blending[2][1] = 0;
	params.rgbblending_params.blending[2][2] = 0x100;

	/* Set RGB2RGB blending offsets */
	params.rgbblending_params.offset[0] = 0;
	params.rgbblending_params.offset[1] = 0;
	params.rgbblending_params.offset[2] = 0;

	/* Set RGB2YCbCr color conversion coefficients */
	params.rgb2ycbcr_params.coeff[0][0] = 0x4d;
	params.rgb2ycbcr_params.coeff[0][1] = 0x96;
	params.rgb2ycbcr_params.coeff[0][2] = 0x1D;
	params.rgb2ycbcr_params.coeff[1][0] = 0x3d4;
	params.rgb2ycbcr_params.coeff[1][1] = 0x3ac;
	params.rgb2ycbcr_params.coeff[1][2] = 0x80;
	params.rgb2ycbcr_params.coeff[2][0] = 0x80;
	params.rgb2ycbcr_params.coeff[2][1] = 0x395;
	params.rgb2ycbcr_params.coeff[2][2] = 0x3eb;

	/* Set RGB2YCbCr color conversion offsets */
	//if(options == 0)
	//{
	//	params.rgb2ycbcr_params.offset[0] = 0;
	//	params.rgb2ycbcr_params.offset[1] = 0;
	//	params.rgb2ycbcr_params.offset[2] = 0;
	//}
	
		params.rgb2ycbcr_params.offset[0] = 10;
		params.rgb2ycbcr_params.offset[1] = 10;
		params.rgb2ycbcr_params.offset[2] = 10;
		
	/* Set black adjustment parameters */
	//params.black_adjst_params.blueblkadj = 0;
	//params.black_adjst_params.redblkadj = 0;
	//params.black_adjst_params.greenblkadj = 0;
	params.black_adjst_params.blueblkadj = 10;
	params.black_adjst_params.redblkadj = 10;
	params.black_adjst_params.greenblkadj = 10;
	
		

	/* Set pixel output format */
	params.pix_fmt = PREV_PIXORDER_YCBYCR;	/* LSB Y0 CB0 Y1 CR0 MSB */

	/* set brightness and contrast */

	//params.brightness = 0;
	
	//if(options == 3)
	//{
		params.brightness = 10;
	//}
	//else if(options == 4)
	//{
	//	params.brightness = ;
	//}	
		

		
	params.contrast = 0x10;

	/* Enable CFA interpolation */
	params.features = PREV_CFA;

	/* Copy CFA coefficients in params */
	for (i = 0; i < CFA_COEFF_TABLE_SIZE; i++)
		params.cfa_coeffs.coeffs[i] = cfa_coef[i];

	/* Set CFA thresholds */
	params.cfa_coeffs.vthreshold = params.cfa_coeffs.hthreshold = 0x28;

	/* Open the previewer driver */
	prevfd = open("/dev/davinci_previewer", O_RDWR);

	/* return error if not opened and exit */
	if (prevfd < 0) {
		printf("\n Failed Preview \n");
		return -1;
	}

	/* Call PREV_SET_PARAM ioctl to do parameter setting */
	if(options == 0)
	{
	ret = ioctl(prevfd, PREV_SET_PARAM, &params);

	/* Return error if it returns error */
	if (ret < 0) {
		printf("\n Failed Preview \n");
		goto out;
	}
	}
	else if(options == 1)
	{
	ret = ioctl(prevfd, PREV_SET_PARAM, NULL);

	/* Return error if it returns error */
	if (ret < 0) {
		printf("\n Passed Negative Tests \n");
		goto out;
	}
	}
	
	/* request one input buffer of size height*width */
	reqbufs.buf_type = PREV_BUF_IN;
	reqbufs.size = HEIGHT * WIDTH;
	reqbufs.count = 1;

	/* Call PREV_REQBUF ioctl to allocate memory for input buffer */
	if(options == 0)
	{
	ret = ioctl(prevfd, PREV_REQBUF, &reqbufs);

	/* return error if it returns error */
	if (ret < 0) {
		printf("\n Failed Preview \n");
		goto out;
	}
	}
	else if(options == 2)
	{
	ret = ioctl(prevfd, PREV_REQBUF, NULL);

	/* return error if it returns error */
	if (ret < 0) {
		printf("\n Passed Negative Tests \n");
		goto out;
	}
	}
	
	/* request one output buffer of size height*width*2 */
	reqbufs.buf_type = PREV_BUF_OUT;
	reqbufs.size = HEIGHT * WIDTH * 2;
	reqbufs.count = 1;

	/* Call PREV_REQBUF ioctl to allocate memory for output buffer */
	ret = ioctl(prevfd, PREV_REQBUF, &reqbufs);

	/* return error if it returns error */
	if (ret < 0) {
		printf("\n Failed Preview \n");
		goto out;
	}

	/* Get the physical address of the input buffer */

	/* fill parameters in buffer */
	t_buff.index = 0;
	t_buff.buf_type = PREV_BUF_IN;

	/* Call PREV_QUERYBUF ioctl to get physical address of input buffer */
	if(options == 0)
	{
	
	ret = ioctl(prevfd, PREV_QUERYBUF, &t_buff);

	/* return error if it returns error */
	if (ret < 0) {
		printf("\n Failed Preview \n");
		goto out;
	}
	}
	else if(options == 3)
	{
	ret = ioctl(prevfd, PREV_QUERYBUF, NULL);

	/* return error if it returns error */
	if (ret < 0) {
		printf("\n Passed Negative Tests \n");
		goto out;
	}
	}


	/* mmap input buffer in user space */
	buff[0].length = t_buff.size;
	buff[0].addr =
	    mmap(NULL, t_buff.size, PROT_READ | PROT_WRITE, MAP_SHARED,
		 prevfd, t_buff.offset);

	/* if mmaping fails return error */
	if (buff[0].addr == MAP_FAILED) {
		printf("\n Failed Preview \n");
		goto out;
	}

	/* Get the physical address of the output buffer */

	/* fill parameters in buffer */
	t_buff.index = 0;
	t_buff.buf_type = PREV_BUF_OUT;

	/* Call PREV_QUERYBUF ioctl to get physical address of output buffer */
	ret = ioctl(prevfd, PREV_QUERYBUF, &t_buff);

	/* return error if it returns error */
	if (ret < 0) {
		printf("\n Failed Preview \n");
		goto out;
	}

	/* mmap output buffer in user space */
	buff[1].length = t_buff.size;
	buff[1].addr =
	    mmap(NULL, t_buff.size, PROT_READ | PROT_WRITE, MAP_SHARED,
		 prevfd, t_buff.offset);

	/* if mmaping fails return error */
	if (buff[1].addr == MAP_FAILED) {
		printf("\n Failed Preview \n");
		goto out;
	}

	/* store index of input buffer and output buffer in convert structer */
	convert.in_buff.index = convert.out_buff.index = 0;

	/* Copy input image in input buffer. */
	memcpy(buff[0].addr, bayerimage, HEIGHT * WIDTH);

	/* Call PREV_PREVIEW ioctl to do previewing */
	ret = ioctl(prevfd, PREV_PREVIEW, &convert);

	/* return error if it returns error */
	if (ret < 0) {
		printf("\n Failed Preview \n");
		goto out;
	}

	/* Open the output file */
	fp = fopen(OUTPUT_FILE_NAME, "w");

	addr = (int *) buff[1].addr;

	/* Separate Y,CB and CR component */
	for (i = 0; i < HEIGHT - 4; i++) {
		for (j = 0; j < (WIDTH / 2 - 2); j++) {
			ay[cy++] = (*addr) & 0xff;
			ay[cy++] = ((*addr) & 0xff0000) >> 16;
			acb[ccb++] = (((*addr) & 0xff00) >> 8);
			acr[ccr++] = ((*addr) & 0xff000000) >> 24;
			addr++;
		}
		addr += 2;
	}
	/* Write Y, CB and Cr in the output file */
	fwrite(ay, 1, cy, fp);
	fwrite(acb, 1, ccb, fp);
	fwrite(acr, 1, ccr, fp);

	/* close the output file */
	fclose(fp);
	printf("\n Passed Preview \n");

      out:
	/* unmap input/output buffers */
	munmap(buff[0].addr, buff[0].length);
	munmap(buff[1].addr, buff[1].length);

	/* Close previewer driver */
	close(prevfd);
	
	return 0;
}
