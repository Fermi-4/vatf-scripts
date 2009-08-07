/*Application too do downsampling by 10 x*/
/* Header files */
#include <stdio.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <asm/arch/davinci_resizer.h>
#define QMUL  (0x100)
#define COEF(nr, dr)   ( (short)( ((nr)*(int)QMUL)/(dr) ) )/* coeff = nr/dr*/
#define RDRV_RESZ_SPEC__MAX_FILTER_COEFF 32
#define IN_HEIGHT						64
#define IN_WIDTH						64
#define IN_PITCH						64*2
#define OUT_HEIGHT						192
#define OUT_WIDTH						192
#define OUT_PITCH						192*2
#define IMAGE_WIDTH						636
#define IMAGE_HEIGHT						476
#define FINAL_HEIGHT						640
#define FINAL_WIDTH						640
#define FINAL_PITCH						640*2

short gRDRV_reszFilter4TapHighQuality[RDRV_RESZ_SPEC__MAX_FILTER_COEFF] = {
	0, 256, 0, 0, -6, 246, 16, 0, -7, 219, 44, 0, -5, 179, 83, -1, -3,
	130, 132, -3, -1, 83, 179, -5, 0, 44, 219, -7, 0, 16, 246, -6
};

short gRDRV_reszFilter7TapHighQuality[RDRV_RESZ_SPEC__MAX_FILTER_COEFF] = {
	-1, 19, 108, 112, 19, -1, 0, 0, 0, 6, 88, 126, 37, -1, 0, 0,
	0, 0, 61, 134, 61, 0, 0, 0, 0, -1, 37, 126, 88, 6, 0, 0
};

/*
short gRDRV_reszFilter4TapHighQuality[RDRV_RESZ_SPEC__MAX_FILTER_COEFF] = {
 COEF(1, 4), COEF(1, 4), COEF(1, 4), COEF(1, 4),
  COEF(1, 4), COEF(1, 4), COEF(1, 4), COEF(1, 4),

  COEF(1, 4), COEF(1, 4), COEF(1, 4), COEF(1, 4),
  COEF(1, 4), COEF(1, 4), COEF(1, 4), COEF(1, 4),

  COEF(1, 4), COEF(1, 4), COEF(1, 4), COEF(1, 4),
  COEF(1, 4), COEF(1, 4), COEF(1, 4), COEF(1, 4),

  COEF(1, 4), COEF(1, 4), COEF(1, 4), COEF(1, 4),
  COEF(1, 4), COEF(1, 4), COEF(1, 4), COEF(1, 4)
};

short gRDRV_reszFilter7TapHighQuality[RDRV_RESZ_SPEC__MAX_FILTER_COEFF] = {
  COEF(1, 7), COEF(1, 7), COEF(1, 7), COEF(1, 7),
  COEF(1, 7), COEF(1, 7), COEF(1, 7),0,

  COEF(1, 7), COEF(1, 7), COEF(1, 7), COEF(1, 7),
  COEF(1, 7), COEF(1, 7), COEF(1, 7), 0,

  COEF(1, 7), COEF(1, 7), COEF(1, 7), COEF(1, 7),
  COEF(1, 7), COEF(1, 7), COEF(1, 7), 0,

  COEF(1, 7), COEF(1, 7), COEF(1, 7), COEF(1, 7),
  COEF(1, 7), COEF(1, 7), COEF(1, 7), 0,
};*/

/* resize test case of line size above 10x down sampling*/
int main()
{
	rsz_params_t ch1_params, ch1_params1;
	rsz_buffer_t ch1_bufd;
	rsz_reqbufs_t ch1_req_outbufs, ch1_req_inbufs;
	rsz_resize_t ch1_resize;
	int j;

	char *ch1_inBuf = 0;
	char *ch1_outBuf = 0;
	char *ch1_map_ptr_dest = 0, *ch1_map_ptr_src = 0;
	int ch1_fd;

	/* Channel 2 variable*/
	rsz_params_t ch2_params, ch2_params1;
	rsz_buffer_t ch2_bufd;
	rsz_reqbufs_t ch2_req_outbufs, ch2_req_inbufs;
	rsz_resize_t ch2_resize;
/*      int j;*/

	char *ch2_inBuf = 0;
	char *ch2_outBuf = 0;
	char *ch2_map_ptr_dest = 0, *ch2_map_ptr_src = 0;
	int ch2_fd;


	FILE *ydata;
	FILE *cbdata;
	FILE *crdata;

	FILE *ydataoutput;
	FILE *cbdataoutput;
	FILE *crdataoutput;

	FILE *outputimage;
	int k;

	char *ycharoutput;
	char *cbcharoutput;
	char *crcharoutput;



	ycharoutput =
	    (char *) malloc(sizeof(char) * (FINAL_HEIGHT * FINAL_WIDTH));
	cbcharoutput =
	    (char *) malloc(sizeof(char) *
			    ((FINAL_HEIGHT * (FINAL_WIDTH) / 2)));
	crcharoutput =
	    (char *) malloc(sizeof(char) *
			    ((FINAL_HEIGHT * (FINAL_WIDTH) / 2)));
	/*      fp=fopen("output.txt","w");*/
	/*      fp1=fopen("otherdata.txt","w");*/

	ydata = fopen("yfinaldeci_yuv.bin", "rb");
	cbdata = fopen("cbfinaldeci_yuv.bin", "rb");
	crdata = fopen("crfinaldeci_yuv.bin", "rb");


	ydataoutput = fopen("yfinaloutput_yuv.YUV", "wb");
	cbdataoutput = fopen("cbfinaloutput_yuv.YUV", "wb");
	crdataoutput = fopen("crfinaloutput_yuv.YUV", "wb");




	outputimage = fopen("10x_finaloutput_yuv.YUV", "wb");

/*      ydataoutput=fopen("TC5_7yfinaloutput.YUV","wb");*/

	int i;
/*Channel 1*/
	ch1_fd = open("/dev/davinci_resizer", O_RDWR);
	/*fd1=open("/dev/davinci_resizer",O_RDWR);*/
	if (ch1_fd < 0) {
		printf("\n Resizer device open  failed");
		printf("\n Failed Resizer \n");
		return 1;
	}

	ch1_req_inbufs.buf_type = RSZ_BUF_IN;
	ch1_req_inbufs.size = IN_HEIGHT * IN_WIDTH * 2;
	ch1_req_inbufs.count = 1;

	printf("starting memory allocation \n");

	if (ioctl(ch1_fd, RSZ_REQBUF, &ch1_req_inbufs) == -1) {
		printf("buffer allocation error.\n");
		printf("\n Failed Resizer \n");
		close(ch1_fd);
		exit(-1);
	}

	ch1_req_outbufs.buf_type = RSZ_BUF_OUT;
	ch1_req_outbufs.size = OUT_HEIGHT * OUT_WIDTH * 2;
	ch1_req_outbufs.count = 1;

	if (ioctl(ch1_fd, RSZ_REQBUF, &ch1_req_outbufs) == -1) {
		printf("buffer allocation error");
		printf("\n Failed Resizer \n");
		close(ch1_fd);
		exit(-1);
	}

	ch1_bufd.buf_type = RSZ_BUF_IN;
	ch1_bufd.index = 0;
	if (ioctl(ch1_fd, RSZ_QUERYBUF, &ch1_bufd) == -1) {
		printf("query buffer failed \n");
		printf("\n Failed Resizer \n");
		close(ch1_fd);
		exit(-1);
	}
	ch1_resize.in_buf.offset = ch1_bufd.offset;

	ch1_inBuf = ch1_map_ptr_src =
	    (char *) mmap(0, IN_HEIGHT * IN_WIDTH * 2,
			  PROT_READ | PROT_WRITE, MAP_SHARED, ch1_fd,
			  ch1_bufd.offset);
	if (ch1_inBuf == MAP_FAILED) {
		printf("\n error in mmaping input buffer");
		printf("\n Failed Resizer \n");
		close(ch1_fd);
		exit(1);
	}
	printf("the inbuf after returning offset is %x \n", ch1_inBuf);
	printf("mmap done  \n");

	/* map the output buffers to user space */
	ch1_bufd.buf_type = RSZ_BUF_OUT;
	ch1_bufd.index = 0;
	if (ioctl(ch1_fd, RSZ_QUERYBUF, &ch1_bufd) == -1) {
		printf(" query buffer failed \n");
		printf("\n Failed Resizer \n");
		close(ch1_fd);
		exit(-1);
	}
	ch1_resize.out_buf.offset = ch1_bufd.offset;
	ch1_outBuf = ch1_map_ptr_dest =
	    (char *) mmap(0, OUT_HEIGHT * OUT_WIDTH * 2,
			  PROT_READ | PROT_WRITE, MAP_SHARED, ch1_fd,
			  ch1_bufd.offset);
	if (ch1_outBuf == MAP_FAILED) {
		printf("\nerror in mmaping output buffer");
		printf("\n Failed Resizer \n");
		close(ch1_fd);
		exit(1);
	}
	printf("the  outbuf offset after retutning is %x \n", ch1_outBuf);

	printf("mmap  \n");
	printf("\n Configuartion of parameters \n");

	ch1_params.in_hsize = IN_WIDTH;
	ch1_params.in_vsize = IN_HEIGHT;	/* only 1 filed of NTSC image */
	ch1_params.in_pitch = IN_PITCH;
	ch1_params.cbilin = 0;	/* filter with luma for low pass */
	ch1_params.pix_fmt = RSZ_PIX_FMT_YUYV;
	ch1_params.out_hsize = OUT_WIDTH;
	ch1_params.out_vsize = OUT_HEIGHT;
	ch1_params.out_pitch = OUT_PITCH;
	ch1_params.vert_starting_pixel = 0;
	ch1_params.horz_starting_pixel = 0;
	ch1_params.inptyp = RSZ_INTYPE_YCBCR422_16BIT;
	ch1_params.hstph = 0;
	ch1_params.vstph = 0;
	ch1_params.yenh_params.type = RSZ_YENH_DISABLE;


	/* If the resize ration is less between 1/2x to 4x use these coefficients*/
	/* else use  gRDRV_reszFilter7TapHighQuality*/
	for (i = 0; i < 32; i++)
		ch1_params.hfilt_coeffs[i] =
		    gRDRV_reszFilter4TapHighQuality[i];

	for (i = 0; i < 32; i++)
		ch1_params.vfilt_coeffs[i] =
		    gRDRV_reszFilter4TapHighQuality[i];

	if (ioctl(ch1_fd, RSZ_S_PARAM, &ch1_params) == -1) {
		printf(" Setting parameters failed \n");
		printf("\n Failed Resizer \n");
		close(ch1_fd);
		exit(-1);
	}


	for (i = 0; i < IN_HEIGHT; i++) {
		for (j = 0; j < (IN_WIDTH / 2); j++) {

			fread(ch1_inBuf, 1, 1, cbdata);
			ch1_inBuf++;


			fread(ch1_inBuf, 1, 1, ydata);
			ch1_inBuf++;


			fread(ch1_inBuf, 1, 1, crdata);
			ch1_inBuf++;
			fread(ch1_inBuf, 1, 1, ydata);
			ch1_inBuf++;

		}
		fseek(ydata, (IMAGE_WIDTH - IN_WIDTH), SEEK_CUR);
		fseek(cbdata, ((IMAGE_WIDTH / 2) - (IN_WIDTH / 2)),
		      SEEK_CUR);
		fseek(crdata, ((IMAGE_WIDTH / 2) - (IN_WIDTH / 2)),
		      SEEK_CUR);
	}


	/*Channel 2 configuration*/
	ch2_fd = open("/dev/davinci_resizer", O_RDWR);
	if (ch2_fd < 0) {
		printf("\n Resizer device open  failed");
		printf("\n Failed Resizer \n");
		return 1;
	}

	ch2_req_inbufs.buf_type = RSZ_BUF_IN;
	ch2_req_inbufs.size = OUT_HEIGHT * OUT_WIDTH * 2;
	ch2_req_inbufs.count = 1;

	printf("starting memory allocation \n");

	if (ioctl(ch2_fd, RSZ_REQBUF, &ch2_req_inbufs) == -1) {
		printf("buffer allocation error.\n");
		printf("\n Failed Resizer \n");
		close(ch2_fd);
		exit(-1);
	}

	ch2_req_outbufs.buf_type = RSZ_BUF_OUT;
	ch2_req_outbufs.size = FINAL_HEIGHT * FINAL_WIDTH * 2;
	ch2_req_outbufs.count = 1;

	if (ioctl(ch2_fd, RSZ_REQBUF, &ch2_req_outbufs) == -1) {
		printf("buffer allocation error");
		printf("\n Failed Resizer \n");
		close(ch2_fd);
		exit(-1);
	}

	ch2_bufd.buf_type = RSZ_BUF_IN;
	ch2_bufd.index = 0;
	if (ioctl(ch2_fd, RSZ_QUERYBUF, &ch2_bufd) == -1) {
		printf("query buffer failed \n");
		printf("\n Failed Resizer \n");
		close(ch2_fd);
		exit(-1);
	}
	ch2_resize.in_buf.offset = ch2_bufd.offset;

	ch2_inBuf = ch2_map_ptr_src =
	    (char *) mmap(0, OUT_HEIGHT * OUT_WIDTH * 2,
			  PROT_READ | PROT_WRITE, MAP_SHARED, ch2_fd,
			  ch2_bufd.offset);
	if (ch2_inBuf == MAP_FAILED) {
		printf("\n error in mmaping input buffer");
		printf("\n Failed Resizer \n");
		close(ch2_fd);
		exit(1);
	}
	printf("the inbuf after returning offset is %x \n", ch2_inBuf);
	printf("mmap done  \n");

	/* map the output buffers to user space */
	ch2_bufd.buf_type = RSZ_BUF_OUT;
	ch2_bufd.index = 0;
	if (ioctl(ch2_fd, RSZ_QUERYBUF, &ch2_bufd) == -1) {
		printf(" query buffer failed \n");
		printf("\n Failed Resizer \n");
		close(ch2_fd);
		exit(-1);
	}
	ch2_resize.out_buf.offset = ch2_bufd.offset;
	ch2_outBuf = ch2_map_ptr_dest =
	    (char *) mmap(0, FINAL_HEIGHT * FINAL_WIDTH * 2,
			  PROT_READ | PROT_WRITE, MAP_SHARED, ch2_fd,
			  ch2_bufd.offset);
	if (ch2_outBuf == MAP_FAILED) {
		printf("\nerror in mmaping output buffer");
		printf("\n Failed Resizer \n");
		close(ch2_fd);
		exit(1);
	}
	printf("the  outbuf offset after retutning is %x \n", ch2_outBuf);

	printf("mmap  \n");
	printf("\n Configuartion of parameters \n");

	ch2_params.in_hsize = OUT_WIDTH;
	ch2_params.in_vsize = OUT_HEIGHT;	/* only 1 filed of NTSC image */
	ch2_params.in_pitch = OUT_PITCH;
	ch2_params.cbilin = 0;	/* filter with luma for low pass */
	/*ch2_params.pix_fmt = RSZ_PIX_FMT_PLANAR;*/
	ch2_params.pix_fmt = RSZ_PIX_FMT_YUYV;
	ch2_params.out_hsize = FINAL_WIDTH;
	ch2_params.out_vsize = FINAL_HEIGHT;
	ch2_params.out_pitch = FINAL_PITCH;
	ch2_params.vert_starting_pixel = 0;
	ch2_params.horz_starting_pixel = 0;
/*      ch2_params.inptyp = RSZ_INTYPE_PLANAR_8BIT;*/
	ch2_params.inptyp = RSZ_INTYPE_YCBCR422_16BIT;
	ch2_params.hstph = 0;
	ch2_params.vstph = 0;
	ch2_params.yenh_params.type = RSZ_YENH_DISABLE;


	/* If the resize ration is less between 1/2x to 4x use these coefficients*/
	/* else use  gRDRV_reszFilter7TapHighQuality*/
	for (i = 0; i < 32; i++)
		ch2_params.hfilt_coeffs[i] =
		    gRDRV_reszFilter4TapHighQuality[i];

	for (i = 0; i < 32; i++)
		ch2_params.vfilt_coeffs[i] =
		    gRDRV_reszFilter4TapHighQuality[i];

	if (ioctl(ch2_fd, RSZ_S_PARAM, &ch2_params) == -1) {
		printf(" Setting parameters failed \n");
		printf("\n Failed Resizer \n");
		close(ch2_fd);
		exit(-1);
	}
	/* channel 1 resizing*/


	ch1_resize.in_buf.index = -1;
	ch1_resize.out_buf.index = -1;
	ch1_resize.in_buf.size = IN_HEIGHT * IN_WIDTH * 2;
	ch1_resize.out_buf.size = OUT_HEIGHT * OUT_WIDTH * 2;

	printf("\nresize in offset = %x, resize out offset = %x\n",
	       ch1_resize.in_buf.offset, ch1_resize.out_buf.offset);

	if (ioctl(ch1_fd, RSZ_RESIZE, &ch1_resize) == -1) {
		printf(" Resize failed \n");
		printf("\n Failed Resizer \n");
		close(ch1_fd);
		exit(-1);
	}


	memcpy(ch2_inBuf, ch1_outBuf, OUT_HEIGHT * OUT_WIDTH * 2);
	printf("mem copy finished \n");



	ch2_resize.in_buf.index = -1;
	ch2_resize.out_buf.index = -1;
	ch2_resize.in_buf.size = OUT_HEIGHT * OUT_WIDTH * 2;
	ch2_resize.out_buf.size = FINAL_HEIGHT * FINAL_WIDTH * 2;

	printf("\nresize in offset = %x, resize out offset = %x\n",
	       ch2_resize.in_buf.offset, ch2_resize.out_buf.offset);

	if (ioctl(ch2_fd, RSZ_RESIZE, &ch2_resize) == -1) {
		printf(" Resize failed \n");
		printf("\n Failed Resizer \n");
		close(ch2_fd);
		exit(-1);
	}

	printf("Resizing finished \n");


	for (i = 0; i < (FINAL_HEIGHT * (FINAL_WIDTH / 2)); i++) {

		fwrite((void *) ch2_outBuf, 1, 1, cbdataoutput);
		ch2_outBuf++;

		fwrite((void *) ch2_outBuf, 1, 1, ydataoutput);
		ch2_outBuf++;


		fwrite((void *) ch2_outBuf, 1, 1, crdataoutput);
		ch2_outBuf++;

		fwrite((void *) ch2_outBuf, 1, 1, ydataoutput);
		ch2_outBuf++;





	}

	fclose(ydataoutput);
	fclose(cbdataoutput);
	fclose(crdataoutput);

	printf(" output copied \n");

	ydataoutput = fopen("yfinaloutput_yuv.YUV", "rb");
	cbdataoutput = fopen("cbfinaloutput_yuv.YUV", "rb");
	crdataoutput = fopen("crfinaloutput_yuv.YUV", "rb");

	fread((void *) ycharoutput, 1, (FINAL_HEIGHT * FINAL_WIDTH),
	      ydataoutput);
	fread((void *) cbcharoutput, 1, (FINAL_HEIGHT * (FINAL_WIDTH / 2)),
	      cbdataoutput);
	fread((void *) crcharoutput, 1, (FINAL_HEIGHT * (FINAL_WIDTH / 2)),
	      crdataoutput);

	fwrite((void *) ycharoutput, 1, (FINAL_HEIGHT * FINAL_WIDTH),
	       outputimage);
	fwrite((void *) cbcharoutput, 1,
	       (FINAL_HEIGHT * (FINAL_WIDTH / 2)), outputimage);
	fwrite((void *) crcharoutput, 1,
	       (FINAL_HEIGHT * (FINAL_WIDTH / 2)), outputimage);

	printf("resize completed \n");
	printf("\n Passed Resizer \n");

	close(ch1_fd);
	close(ch2_fd);

	free(ycharoutput);
	free(cbcharoutput);
	free(crcharoutput);

	fclose(ydata);
	fclose(cbdata);

	fclose(crdata);
	fclose(ydataoutput);
	fclose(cbdataoutput);
	fclose(crdataoutput);
	fclose(outputimage);

}
