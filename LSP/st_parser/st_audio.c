/*******************************************************************************
 **+--------------------------------------------------------------------------+**
 **|                            ****                                          |**
 **|                            ****                                          |**
 **|                            ******o***                                    |**
 **|                      ********_///_****                                   |**
 **|                      ***** /_//_/ ****                                   |**
 **|                       ** ** (__/ ****                                    |**
 **|                           *********                                      |**
 **|                            ****                                          |**
 **|                            ***                                           |**
 **|                                                                          |**
 **|         Copyright (c) 1998-2005 Texas Instruments Incorporated           |**
 **|                        ALL RIGHTS RESERVED                               |**
 **|                                                                          |**
 **| Permission is hereby granted to licensees of Texas Instruments           |**
 **| Incorporated (TI) products to use this computer program for the sole     |**
 **| purpose of implementing a licensee product based on TI products.         |**
 **| No other rights to reproduce, use, or disseminate this computer          |**
 **| program, whether in part or in whole, are granted.                       |**
 **|                                                                          |**
 **| TI makes no representation or warranties with respect to the             |**
 **| performance of this computer program, and specifically disclaims         |**
 **| any responsibility for any damages, special or consequential,            |**
 **| connected with the use of this program.                                  |**
 **|                                                                          |**
 **+--------------------------------------------------------------------------+**
 *******************************************************************************/

/** \file   ST_Audio.c
    \brief  DaVinci ARM Linux PSP System Audio Tests

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created - Linux Audio Test Code 
    @author     Anand Patil
    @version    0.2 - Added  - Newly Supported IOCTLS
                
 */


#include "st_audio.h"
#include <linux/soundcard.h>
#include <sys/time.h>
#include <sys/poll.h>
//#include <asm-arm/poll.h>

Int32 fd_audio = AUDIO_FAILURE;

Int32 st_audio_instance = 0;

Uint32 st_audio_driver[PSP_AUDIO_NUM_INSTANCES];

static Uint32 instflag[PSP_AUDIO_NUM_INSTANCES] = {0, };

Int32 fd_mixer = AUDIO_FAILURE;

Uint32 st_audio_mix_instance = 0;

Uint32 st_audio_mixer[PSP_MIXER_NUM_INSTANCES];

Uint32 mixinstflag[PSP_MIXER_NUM_INSTANCES] = {0, };


void audio_parser(void)
{
	char cmd[50]; 
	int i =0;	
	char cmdlist[][40] = {
		"update",
		"gen_open",
		"open",
		"open_mixer",
		"close",
		"close_mixer",
		"stability",
		"ioctl",
		"io",
		"mic_rec",
		"line_rec",
		"neg",
		"poll",
		"help"
	};

	while(1)
	{
		i = 0;
		printTerminalf("AUDIO>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting AUDIO mode to Main Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_update();
		} 
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_general_open();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_open();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_open_mixer();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_close();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_close_mixer();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_stability();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			audio_ioctl_parser();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			audio_io_parser();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_mic_recplay();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_line_in_recplay();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_NULL_Instance();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
        {
            //test_audio_driver_poll();
        }
		else
		{
			int j=0;
			printTerminalf("Invalid Function\n");
			printTerminalf("Available Functions:\n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf(" %s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	} /* while */

	return;
} /* End of audio_parser() */



void test_audio_driver_update(void)
{
	char cmd [CMD_LENGTH];
	char cmdlist[][40] = {
		"instance",
		"exit",
		"help"
	};
	while(1)
	{
		printTerminalf("Enter Update Parameter\naudio::update> ");
		scanTerminalf("%s", cmd);

		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting AUDIO IO mode to AUDIO Parser:\n");
			break;
		}
		if(0 == strcmp("instance", cmd)) 
		{
			test_audio_update_driver_instance();
			break;
		} 	
		else 
		{
			int j=0;
			printTerminalf("Invalid Function\n");
			printTerminalf("Available Functions:\n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf(" %s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		//	return;
		}
	}

	printTerminalf("Update Successful\n");
	return;
}



/* Need to add Loopback after investigation*/

void audio_ioctl_parser(void)
{
	char cmd[50]; 
	int i =0;	
	char cmdlist[][40] = {
		"get_ver",
		"get_bufsize",
		"get_capab",
		"set_frag",
		"get_trig",
		"set_trig",
		"get_dataplayed",
		"get_datarecorded",
		"get_ofrag",
		"get_ifrag",
		"set_nonblock",
		"set_format",
		"set_chan",
		"set_sr",
		"set_sync",
		"set_pcm_sync",
		"set_reset",
		"set_post",
		"get_sr",
		"get_format",
		"get_rate",
		"get_chan",
		"get_bits",
		"set_duplex",
		"mix_info",
		"set_mix_vol",
		"set_mix_linein",
		"set_mix_mic",
		"get_mix_vol",
		"get_mix_linein",
		"get_mix_mic",
		"set_bass",
		"set_treble",
		"get_bass",
		"get_treble",
		"set_recsrc",
		"get_recsrc",
		"get_recmask",
		"get_devmask",
		"get_caps",
		"get_stereodevs",
		"set_get_vol",
		"set_igain",
		"set_ogain",
		"get_igain",
		"get_ogain",
		"set_MicBiasVolt",
		"exit",
		"help"
	};

	while(1)
	{
		i = 0;
		printTerminalf("AUDIO::IOCtl>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting IOCtl mode to AUDIO Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_version();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_bufsize();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_capabilities();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_fragment();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_trigger();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_trigger();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_dataplayed();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_datarecorded();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_ofragbuf();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_ifragbuf();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_nonblock();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_format();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_channnels();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_sampling_rate();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_dsp_sync();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_pcm_sync();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_reset();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_post();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_sr();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_format();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_rate();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_channels();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_bits();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_duplex();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_mix_info();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_mix_vol();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_mix_linein_vol();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_mix_mic_vol();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_vol();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_linein_vol();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_mic_vol();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_mix_bass();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_mix_treble();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_bass();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_treble();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_mix_recsrc();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_recsrc();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_recmask();
		}	
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_devmask();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_caps();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_get_mix_stereodevs();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_set_get_vol();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
        	{
			test_audio_driver_set_igain();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
        	{
		        test_audio_driver_set_ogain();
        	}
		else if(0 == strcmp(cmd, cmdlist[i++]))
        	{
			test_audio_driver_get_igain();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
        	{
		        test_audio_driver_get_ogain();
        	}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
		 	test_audio_driver_set_mic_bias_volt();
		}
		else
		{
			int j=0;
			printTerminalf("Invalid Function\n");
			printTerminalf("Available Functions:\n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf(" %s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	} /* while */

	return;
} /* End of audio_ioctl_parser() */


void audio_io_parser(void)
{
	char cmd[50]; 
	int i =0;	
	char cmdlist[][40] = {	
		"record",
		"playback",
		"rec_and_play_sync",
		"sync_stress",
		"sync_len_stress",
		"async_stress",
		"async_len_stress",
		"stability",
		"sync_perf",
		"async_perf",
		"play_perf",
		"rec_perf",
		"multi_process",
		"multi_thread",
		"Long_playback",		
		"help"
	};

	while(1)
	{
		i = 0;
		printTerminalf("AUDIO::IO>> ");
		scanTerminalf("%s",cmd);
		if(0 == strcmp(cmd, "exit")) 
		{
			printTerminalf("Exiting AUDIO IO mode to AUDIO Parser:\n");
			break;
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_record();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_playback();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_record_sync_and_playback_sync();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_sync_stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_len_in_sync_stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_async_stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_len_in_async_stress();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_stability();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_sync_performance();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			test_audio_driver_async_performance();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{		
			test_audio_driver_perf_play();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{		
			test_audio_driver_perf_record();
		}
		
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_Audio_MultiProcess_parser();
		} 
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_Audio_MultiThread_parser();
		}
		else if(0 == strcmp(cmd, cmdlist[i++]))
		{
			ST_test_audio_long_playback();
		}
		else 
		{
			int j=0;
			printTerminalf("Invalid Function\n");
			printTerminalf("Available Functions:\n");
			while(strcmp("help", cmdlist[j]))
			{
				printTerminalf(" %s\n", cmdlist[j]);
				j++;
			}
			printTerminalf("\n");
		}
	} /* while */

	return;
} /* End of audio_io_parser() */



void test_audio_update_driver_instance(void)
{
	Uint8 local_instance = 0;
	

	printTerminalf("test_audio_update_driver_instance: Enter the Interface Number (0,1, 2)\naudio::update> ");
	scanTerminalf("%d", &local_instance);
	
	if(st_audio_instance < PSP_AUDIO_NUM_INSTANCES)
	{
		st_audio_instance = local_instance;
		printTerminalf("test_audio_update_driver_instance: Setting st_audio_instance to %d\n", st_audio_instance);
	}
	else 
	{
		printTerminalf("test_audio_update_driver_instance: Invalid Instance Number");
	}
}



void test_audio_driver_general_open(void)
{
	Int32 attr = 1;
	char dev_name[100] = {0, };	/* Device Name */
	Int8 status = AUDIO_FAILURE;

	printTerminalf("test_audio_driver_general_open: Enter the device to open (/dev/dsp)\n");
	scanTerminalf("%s", &dev_name);

	printTerminalf("test_audio_driver_general_open: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
	scanTerminalf("%d", &attr);
	
	if (0 == st_audio_instance)
	{
		/* Check device open */

		if (0 == instflag[st_audio_instance])
		{
			status = ST_Open(dev_name, attr |~O_NONBLOCK, &fd_audio);
			instflag[st_audio_instance] =1;
		}
		else
			fd_audio = AUDIO_FAIL;
	}
		
	else
	{
		printTerminalf("test_audio_driver_general_open: Invalid instance\n");
	}

	if( fd_audio > AUDIO_SUCCESS)
	{
		st_audio_driver[st_audio_instance] = fd_audio;
		printTerminalf("test_audio_driver_general_open: Success:: Device = %s, fd=%d\n", dev_name,fd_audio);
	}
	else
	{
		printTerminalf("test_audio_driver_general_open: Failed:: Device = %s, fd=%d, status=%d\n", dev_name, fd_audio, status);
	}
}





void test_audio_driver_open(void)
{
	Int32 attr = 1;
	Int32 attr_val = 0;
	Int32 attr1 = O_NONBLOCK;
	Int8 status = AUDIO_FAILURE;

	printTerminalf("test_audio_driver_open: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
	scanTerminalf("%d", &attr);
	
	printTerminalf("test_audio_driver_open: Enter the attribute for open:: 0-Non-Blocking call, 1-Blocking call\n");
	scanTerminalf("%d", &attr_val);
	
	if (1 == attr_val)
		attr1 = O_SYNC;
	
	if (0 == st_audio_instance)
	{
		/* Check device open */

		if (0 == instflag[st_audio_instance])
		{
			status = ST_Open(INSTANCE, attr | attr1, &fd_audio);
		}
		else
			fd_audio = AUDIO_FAIL;
	

	}
		
	else
	{
		printTerminalf("test_audio_driver_open: Invalid instance\n");
	}

	if( fd_audio > AUDIO_SUCCESS)
	{
		st_audio_driver[st_audio_instance] = fd_audio;
		printTerminalf("test_audio_driver_open: Success:: Open: fd=%d\n",fd_audio);
	
		instflag[st_audio_instance] = 1;
	}
	else
	{
	
		instflag[st_audio_instance] = 0;	
		fd_audio = AUDIO_FAIL;
		st_audio_driver[st_audio_instance] = fd_audio;
		printTerminalf("test_audio_driver_open: Failed:: Open: fd=%d, status=%d\n", fd_audio, status);
	}
}



void test_audio_driver_open_mixer(void)
{
	Int32 attr = 1;
	Int8 status = AUDIO_FAILURE;

	printTerminalf("test_audio_driver_open_mixer: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
	scanTerminalf("%d", &attr);
	
	if (0 == st_audio_mix_instance)
	{
		/* Check device open */

		if (0 == mixinstflag[st_audio_mix_instance])
		{
			status = ST_Open(MIX_INSTANCE, attr, &fd_mixer);
		}
		else
			fd_mixer = AUDIO_FAIL;
	}
		
	else
	{
		printTerminalf("test_audio_driver_open_mixer: Invalid instance\n");
	}

	if( fd_mixer > AUDIO_SUCCESS)
	{
		st_audio_mixer[st_audio_mix_instance] = fd_mixer;
		printTerminalf("test_audio_driver_open_mixer: Success:: Open: fd=%d\n",fd_mixer);
		mixinstflag[st_audio_mix_instance] = 0;
	}
	else
	{	
		mixinstflag[st_audio_mix_instance] = 0;
		fd_mixer = AUDIO_FAIL;
		st_audio_mixer[st_audio_mix_instance] = fd_mixer;
		printTerminalf("test_audio_driver_open_mixer: Failed:: Open: fd=%d, status=%d\n", fd_mixer, status);
	}
}




void test_audio_driver_close(void)
{
	Int8 status = AUDIO_FAILURE;
	
	//printTerminalf("test_audio_driver_close:  AUDIO Instance:%d\n", st_audio_driver[st_audio_instance]);
	status = ST_Close(st_audio_driver[st_audio_instance]);
			
	if(status != AUDIO_SUCCESS) 
	{
		st_audio_driver[st_audio_instance] = AUDIO_FAIL;
		instflag[st_audio_instance] = 0;
		printTerminalf("test_audio_driver_close: Failed:: AUDIO Instance:%d Errno:%d\n", st_audio_driver[st_audio_instance], status);
	}
	else
	{
		printTerminalf("test_audio_driver_close: Success:: AUDIO Instance:%d\n",st_audio_driver[ st_audio_instance]);	
	}

}

void ST_test_audio_long_playback()
{
	
	Int32 Audio_fd,test_fd;
	char *Audio_buf=NULL;
	char  filename[100];
	LF_STAT fstatInst;
	struct timeval time;
	Uint32 Start_Time=0;
	Uint32 End_Time=0;	
	Uint32 Timeout=0;	

	
	printTerminalf("ST_test_audio_long_playback:Enter the file name:\n");
	scanTerminalf("%s",filename);
	printTerminalf("ST_test_audio_long_playback:Enter the timeout:\n");
	scanTerminalf("%s",&Timeout);
	
	ST_Open("/dev/dsp",2|O_SYNC,&Audio_fd);
	
	ST_Open(filename,0|O_SYNC,&test_fd);
	
	ST_Status(test_fd,&fstatInst);
	
	Audio_buf=(char *)malloc(fstatInst.st_size);	
	if(NULL!=Audio_buf)				
	{
		ST_Read(test_fd,Audio_buf,fstatInst.st_size);
	
//		alarm(timeout);
		if(-1!=gettimeofday(&time,NULL)) 
		Start_Time=time.tv_sec;
		else
		perror("gettimeofday"); 			
		
		do
		{
			ST_Write(Audio_fd,Audio_buf,fstatInst.st_size);
		
			if(-1!=gettimeofday(&time,NULL)) 
			End_Time=time.tv_sec;
			else
			perror("gettimeofday"); 			

		}
		while((End_Time-Start_Time)<Timeout);

		free(Audio_buf);
	}

	else
	{
		printTerminalf("ST_test_audio_long_playback Malloc failed\n");
	}
	
	ST_Close(test_fd);
	ST_Close(Audio_fd);
		
}	


void test_audio_driver_close_mixer(void)
{
	Int8 status = AUDIO_FAILURE;
	
	status = ST_Close(st_audio_mixer[st_audio_mix_instance]);
			
	if(status != AUDIO_SUCCESS) 
	{
		st_audio_mixer[st_audio_mix_instance] = AUDIO_FAIL;
		mixinstflag[st_audio_mix_instance] = 0;
		printTerminalf("test_audio_driver_close_mixer: Failed:: Mixer Instance:%d Errno:%d\n", st_audio_mixer[st_audio_mix_instance], status);
	}
	else
	{
		printTerminalf("test_audio_driver_close_mixer: Success:: Mixer Instance:%d\n", st_audio_mixer[st_audio_mix_instance]);	
	}

}


#if 0
void test_audio_driver_poll(void)
{
	Int8 new_type = POLLIN;		
	int status = AUDIO_FAILURE;
	int time_out = -1;
	pollfd poll_struct;
	
	printTerminalf("Enter the poll type: 1 - Read, 2 - Read now, 3 - Default, 4 - Write\naudio::audio poll> ");
	scanTerminalf("%d", &new_type);
	printTerminalf("Enter the time-out value: \naudio::audio poll> ");
	scanTerminalf("%d", &time_out);
	
	if (3 == new_type)
		new_type = POLLIN;

	poll_struct.fd = st_audio_driver[st_audio_instance];
	poll_struct.events = new_type;
	poll_struct.revents = NULL;
	
	/* Get the audio version */
	status = poll(poll_struct, 1, time_out);

	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_poll: Failed:: Status = %d, Revent = %d\n", status, poll_struct.revents);
	}
	else
		printTerminalf("test_audio_driver_poll: Success:: Revent = %d\n", poll_struct.revents);

}

#endif

void test_audio_driver_get_version(void)
{
	Uint32 new_version = AUDIO_NULL;		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio version> ");
	
	/* Get the audio version */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], OSS_GETVERSION, &new_version);

	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_version: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_version: Success:: Version number is %d\n", new_version);

}



void test_audio_driver_get_bufsize(void)
{
	Uint32 new_buffsize = AUDIO_NULL;		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio buffer size> ");
	
	/* Get the audio buffer size */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETBLKSIZE, &new_buffsize);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_bufsize: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_bufsize: Success:: Buffer Size is %d\n", new_buffsize);

}



void test_audio_driver_get_capabilities(void)
{
	Uint32 new_cap = AUDIO_NULL;		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio capabilities> ");
	
	/* Get the audio capabilities */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETCAPS, &new_cap);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_capabilities: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_capabilities: Success:: Capabilities are %xh\n", new_cap);

}



void test_audio_driver_set_fragment(void)
{
	Uint32 new_frag = 2;		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("Enter number of fragments in the buffer \naudio::audio fragment> ");
	scanTerminalf("%d", &new_frag);

	new_frag = (new_frag & 0x0000FFFF);
	
	/* Set the audio buffer frament size */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SETFRAGMENT, &new_frag);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_fragment: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_set_fragment: Success:: Fragment is %d\n", new_frag);
		printTerminalf("test_audio_driver_set_fragment: Success:: Fragment is %d\n", (new_frag & 0x0000FFFF));
	}
}



void test_audio_driver_get_trigger(void)
{
	Uint32 new_trig = AUDIO_NULL;		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio trigger value> ");
	
	/* Get the audio trigger value */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETTRIGGER, &new_trig);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_trigger: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_trigger: Success:: Trigger value is %d\n", new_trig);

}



void test_audio_driver_set_trigger(void)
{
	Uint32 new_trig = 2;		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("Supported Trigger values are 1 - input enable, 2 - output enable \n");
	printTerminalf("Enter trigger value \naudio::audio trigger value> ");
	scanTerminalf("%d", &new_trig);
	
	/* Set the audio trigger value */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SETTRIGGER, &new_trig);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_trigger: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_trigger: Success:: Trigger value is %d\n", new_trig);

}



void test_audio_driver_get_dataplayed(void)
{
	//Uint32 new_val = AUDIO_NULL;		
	count_info new_val;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio data played> ");

	/* Get the number of audio data played */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETOPTR, &new_val);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_dataplayed: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_get_dataplayed: Data bytes = %d\n", new_val.bytes);
		printTerminalf("test_audio_driver_get_dataplayed: Data blocks = %d\n", new_val.blocks);
		printTerminalf("test_audio_driver_get_dataplayed: Success:: Pointer of data played = %d\n", new_val.ptr);

	}
}


void test_audio_driver_get_datarecorded(void)
{
	//Uint32 new_val = AUDIO_NULL;		
	count_info new_val;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio data recorded> ");

	/* Get the number of audio data recorded */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETIPTR, &new_val);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_datarecorded: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_get_datarecorded: Data bytes = %d\n", new_val.bytes);
		printTerminalf("test_audio_driver_get_datarecorded: Data blocks = %d\n", new_val.blocks);
		printTerminalf("test_audio_driver_get_datarecorded: Success:: Pointer of data recorded = %d\n", new_val.ptr);

	}
}



#if 0

void test_audio_driver_get_datarecorded(void)
{
	Uint32 new_val = AUDIO_NULL;		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio data recorded> ");

	/* Get the number of audio data recorded */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETIPTR, &new_val);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_datarecorded: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_datarecorded: Success:: Number of data recored is %d\n", new_val);
}

#endif

void test_audio_driver_get_ofragbuf(void)
{
	audio_buf_info oinf = { 0, };		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio output buffer> ");

	/* Get the output buffer info */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETOSPACE, &oinf);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_ofragbuf: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_get_ofragbuf: Number of full fragments are %d\n", oinf.fragments);
		printTerminalf("test_audio_driver_get_ofragbuf: Number of allocated fragments for buffering are %d\n", oinf.fragstotal);
		printTerminalf("test_audio_driver_get_ofragbuf: Number of fragments in bytes are %d\n", oinf.fragsize);
		printTerminalf("test_audio_driver_get_ofragbuf: Number of bytes that can be written without blocking are %d\n", oinf.bytes);
		printTerminalf("test_audio_driver_get_ofragbuf: Success:: Output fragment is received\n");
	}

}



void test_audio_driver_get_ifragbuf(void)
{
	audio_buf_info iinf = { 0, };		
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio input buffer> ");

	/* Get the input buffer info */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETISPACE, &iinf);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_ifragbuf: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_get_ifragbuf: Number of full fragments are %d\n", iinf.fragments);
		printTerminalf("test_audio_driver_get_ifragbuf: Number of allocated fragments for buffering are %d\n", iinf.fragstotal);
		printTerminalf("test_audio_driver_get_ifragbuf: Number of fragments in bytes are %d\n", iinf.fragsize);
		printTerminalf("test_audio_driver_get_ifragbuf: Number of bytes that can be read without blocking are %d\n", iinf.bytes);
		printTerminalf("test_audio_driver_get_ifragbuf: Success:: Input fragment is received\n");
	}

}


void test_audio_driver_set_nonblock(void)
{
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::Non-block> ");
	
	/* Make Non-blocking calls */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_NONBLOCK, NULL);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_nonblock: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_nonblock: Success:: Non-blocking setting Passed\n");
}


#if 0
	AFMT_QUERY		0x00000000	/* Return current fmt */
#	define AFMT_MU_LAW		0x00000001
#	define AFMT_A_LAW		0x00000002
#	define AFMT_IMA_ADPCM		0x00000004
#	define AFMT_U8			0x00000008
#	define AFMT_S16_LE		0x00000010	/* Little endian signed 16*/
#	define AFMT_S16_BE		0x00000020	/* Big endian signed 16 */
#	define AFMT_S8			0x00000040
#	define AFMT_U16_LE		0x00000080	/* Little endian U16 */
#	define AFMT_U16_BE		0x00000100	/* Big endian U16 */
#	define AFMT_MPEG		0x00000200	/* MPEG (2) audio */
#	define AFMT_AC3		0x00000400

#endif

void test_audio_driver_set_format(void)
{
	Uint32 new_format = 16;		/* AFMT_S16_LE format */
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Supported Audio formats 0-AFMT_QUERY, 1-AFMT_MU_LAW, 2-AFMT_A_LAW, 4-AFMT_IMA_ADPCM, ");
	printTerminalf("8-AFMT_U8, 16-AFMT_S16_LE, 32-AFMT_S16_BE, 64-AFMT_S8, 128-AFMT_U16_LE, 256-AFMT_U16_BE, ");
	printTerminalf("512-AFMT_MPEG, 1024-AFMT_AC3, ");
	printTerminalf("Enter New Audio Format \naudio::audio format> ");
	scanTerminalf("%d", &new_format);
	
	/* Set the audio format */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SETFMT, &new_format);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_format: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_format: Success:: Setting audio format to %d\n", new_format);
}



void test_audio_driver_set_channnels(void)
{
	Uint32 new_chan = 2;		/* 2- stereo */
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Supported channels 1-mono, 2-stereo ");
	printTerminalf("Enter number of audio channels \naudio::audio chan> ");
	scanTerminalf("%d", &new_chan);
	
	/* Set the number of channels */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_CHANNELS, &new_chan);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_channnels: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_channnels: Success:: Setting number of channels to %d\n", new_chan);
	
}


void test_audio_driver_set_sampling_rate(void)
{
	Uint32 new_sr = 24000;		/* 24 KHz */
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Supported sampling rates : 8000, 11025, 12000, 16000, 22005, 24000, 32000, 44100, 48000, 88200, 96000 \n");
	printTerminalf("Enter the new sampling rate \naudio::audio sampling rate> ");
	scanTerminalf("%d", &new_sr);
	
	/* Set the sampling rate */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SPEED, &new_sr);

	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_sampling_rate: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_sampling_rate: Success:: Setting the sampling rate to %d\n", new_sr);

}


void test_audio_driver_set_dsp_sync(void)
{
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::DSP Sync> ");
	
	/* Set Wait for ever */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SYNC, NULL);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_dsp_sync: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_dsp_sync: Success:: Setting Passed\n");
	
}



void test_audio_driver_set_pcm_sync(void)
{
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::PCM Sync> ");
	
	/* Set Wait for ever */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_PCM_SYNC, NULL);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_pcm_sync: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_pcm_sync: Success:: Setting Passed\n");
	
}




void test_audio_driver_set_reset(void)
{
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::Reset> ");
	
	/* Reset the device */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_RESET, NULL);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_reset: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_reset: Success:: Setting Passed\n");

}



void test_audio_driver_set_post(void)
{
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::Pause> ");
	
	/* Pause while playing the audio */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_POST, NULL);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_post: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_post: Success:: Setting Passed\n");
	
}


void test_audio_driver_get_sr(void)
{
	Uint32 sr = AUDIO_NULL;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::Reset> ");
	
	/* Get the sampling rate */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_PCM_READ_RATE, &sr);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_sr: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_sr: Success:: Sampling rate is %d\n", sr);

}



void test_audio_driver_get_format(void)
{
	Uint32 format = AUDIO_NULL;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio format> ");
	
	/* Get the sampling rate */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETFMTS, &format);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_format: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_format: Success:: Audio format is %d\n", format);
}



void test_audio_driver_get_rate(void)
{
	Uint32 rate = AUDIO_NULL;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio Rate> ");
	
	/* Get the sampling rate */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_PCM_READ_RATE, &rate);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_rate: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_rate: Success:: Audio rate = %d\n", rate);
}




void test_audio_driver_get_channels(void)
{
	Uint32 chan = AUDIO_NULL;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio Channnels> ");
	
	/* Get the sampling rate */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_PCM_READ_CHANNELS, &chan);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_channels: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_channels: Success:: Audio channels = %d\n", chan);
}



void test_audio_driver_get_bits(void)
{
	Uint32 bits = AUDIO_NULL;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("audio::audio Bits> ");
	
	/* Get the sampling rate */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_PCM_READ_BITS, &bits);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_bits: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_bits: Success:: Audio bits = %d\n", bits);
}


void test_audio_driver_set_duplex(void)
{
        Uint32 new_val = AUDIO_NULL;
        Int8 status = AUDIO_FAILURE;

        /* Set the full duplex */
        status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SETDUPLEX, &new_val);

        if (status != AUDIO_SUCCESS)
        {
                printTerminalf("test_audio_driver_set_duplex: Failed:: Status = %d\n", status);
        }
        else
                printTerminalf("test_audio_driver_set_duplex: Success:: Setting the full duplex, Val= %d\n", new_val);

}



/* Mixer Info */

void test_audio_driver_mix_info(void)
{
	Int8 status = AUDIO_FAILURE;
	struct mixer_info m_info;

	
	/* Set the volume */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_INFO, &m_info);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_mix_info: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_mix_info: Success \n Mixer Info \n ID = %s\n Name =%s\n Mod Count=%d\n", m_info.id, m_info.name,m_info.modify_counter);

}






/* Mixer Volume settings */



void test_audio_driver_set_mix_vol(void)
{
	Uint32 new_vol = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Enter the volume between 0-100 \naudio::mixer mix volume> ");
	scanTerminalf("%d", &new_vol);
	
	/* Set the volume */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_VOLUME, &new_vol);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_mix_vol: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_mix_vol: Success:: Setting the Mixer volume to %d\n", new_vol);

}




void test_audio_driver_set_mix_linein_vol(void)
{
	Uint32 new_vol = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Enter the volume for Line-in between 0-100 \naudio::mixer line-in volume> ");
	scanTerminalf("%d", &new_vol);
	
	/* Set the line-in volume */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_LINE, &new_vol);
	    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_mix_linein_vol: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_mix_linein_vol: Success:: Setting the mixer volume for line-in to %d\n", new_vol);

}



void test_audio_driver_set_mix_mic_vol(void)
{
	Uint32 new_vol = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Enter the volume for Mic between 0-100 \naudio::mixer mic volume> ");
	scanTerminalf("%d", &new_vol);
	
	/* Set the Mic volume */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_MIC, &new_vol);

	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_mix_mic_vol: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_mix_mic_vol: Success:: Setting the mixer volume for mic to %d\n", new_vol);

}


void test_audio_driver_set_mic_bias_volt(void)
{
	Uint32 new_vol = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Enter the volume for Mic Bias Volatage 0=OFF, 1=2.0V ,2=2.5V,3=VDD \n audio::mixer mic volume> ");
	scanTerminalf("%d", &new_vol);
	
	/* Set the Mic volume */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_PRIVATE1, &new_vol);

	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_mic_bias_volt: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_mic_bias_volt: Success:: Setting the mixer volume for mic to %d\n", status);

}


void test_audio_driver_get_mix_vol(void)
{
	Uint32 vol = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get the volume */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_VOLUME, &vol);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_vol: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_vol: Success:: Mixer volume = %d\n", vol);

}




void test_audio_driver_get_mix_linein_vol(void)
{
	Uint32 vol = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get the line-in volume */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_LINE, &vol);
	    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_linein_vol: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_linein_vol: Success:: Mixer Line-in volume = %d\n", vol);

}




void test_audio_driver_get_mix_mic_vol(void)
{
	Uint32 vol = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	
	/* Get the Mic volume */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_MIC, &vol);

	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_mix_mic_vol: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_mix_mic_vol: Success:: Mixer Mic volume = %d\n", vol);

}


/* More Mixer Volume settings */


void test_audio_driver_set_mix_bass(void)
{
	Uint32 new_bass = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Enter the bass value between 0-100 \naudio::mixer bass> ");
	scanTerminalf("%d", &new_bass);
	
	/* Set the bass */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_BASS, &new_bass);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_mix_bass: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_mix_bass: Success:: Setting the bass to %d\n", new_bass);

}



void test_audio_driver_set_mix_treble(void)
{
	Uint32 new_treble = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Enter the treble value between 0-100 \naudio::mixer treble> ");
	scanTerminalf("%d", &new_treble);
	
	/* Set the treble */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_TREBLE, &new_treble);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_mix_treble: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_mix_treble: Success:: Setting the treble to %d\n", new_treble);

}




void test_audio_driver_get_mix_bass(void)
{
	Uint32 bass = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get the bass */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_BASS, &bass);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_bass: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_bass: Success:: Bass = %d\n", bass);

}



void test_audio_driver_get_mix_treble(void)
{
	Uint32 treble = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get the treble */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_TREBLE, &treble);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_treble: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_treble: Success:: Treble = %d\n", treble);

}







/* Mixer capabilities */


void test_audio_driver_set_mix_recsrc(void)
{
	Uint32 act_record = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Enter the new active recording source \naudio::mixer recsrc> ");
	scanTerminalf("%d", &act_record);

	/* Set active recording source */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_RECSRC, &act_record);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_set_mix_recsrc: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_set_mix_recsrc: Success:: Active recording source set to %xh\n", act_record);

}




void test_audio_driver_get_mix_recsrc(void)
{
	Uint32 act_record = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get currently active recording source */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_RECSRC, &act_record);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_recsrc: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_recsrc: Success:: Currently active recording source  = %xh\n", act_record);

}



void test_audio_driver_get_mix_recmask(void)
{
	Uint32 chan = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get the Recording channel number */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_RECMASK, &chan);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_recmask: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_recmask: Success:: Recording channels = %xh\n", chan);

}



void test_audio_driver_get_mix_devmask(void)
{
	Uint32 mix_chan = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get the mixer channels */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_DEVMASK, &mix_chan);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_devmask: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_devmask: Success:: Mixer channels = %xh\n", mix_chan);

}



void test_audio_driver_get_mix_caps(void)
{
	Uint32 mix_cap = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get the mixer capabilities */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_CAPS, &mix_cap);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_caps: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_caps: Success:: Mixer capabilities = %xh\n", mix_cap);

}



void test_audio_driver_get_mix_stereodevs(void)
{
	Uint32 st_chan = AUDIO_NULL;	
	Int8 status = AUDIO_FAILURE;

	/* Get the information of channel (stereo = 1 or mono) */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_STEREODEVS, &st_chan);
    	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_get_mix_stereodevs: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_get_mix_stereodevs: Success:: Channel Info = %xh\n", st_chan);

}



void test_audio_driver_set_igain(void)
{
    Uint32 igain = 1;
    Int8 status = AUDIO_FAILURE;

    printTerminalf("Enter the new input gain \naudio::input gain> ");
    scanTerminalf("%d", &igain);

    /* Set input gain */
    status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_IGAIN, &igain);

    if (status != AUDIO_SUCCESS)
    {
        printTerminalf("test_audio_driver_set_igain: Failed:: Status = %d\n", status);
    }
    else
        printTerminalf("test_audio_driver_set_igain: Success:: Input gain set to %d\n", igain);

}



void test_audio_driver_set_ogain(void)
{
    Uint32 ogain = 1;
    Int8 status = AUDIO_FAILURE;

    printTerminalf("Enter the new output gain \naudio::output gain> ");
    scanTerminalf("%d", &ogain);

    /* Set output gain */
    status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_OGAIN, &ogain);

    if (status != AUDIO_SUCCESS)
    {
        printTerminalf("test_audio_driver_set_ogain: Failed:: Status = %d\n", status);
    }
    else
        printTerminalf("test_audio_driver_set_ogain: Success:: Output gain set to %d\n", ogain);

}




void test_audio_driver_get_ogain(void)
{
    Uint32 ogain = -1;
    Int8 status = AUDIO_FAILURE;


    /* Set output gain */
    status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_OGAIN, &ogain);

    if (status != AUDIO_SUCCESS)
    {
        printTerminalf("test_audio_driver_get_ogain: Failed:: Status = %d\n", status);
    }
    else
        printTerminalf("test_audio_driver_get_ogain: Success:: Output gain set to %d\n", ogain);

}


void test_audio_driver_get_igain(void)
{
    Uint32 ogain = -1;
    Int8 status = AUDIO_FAILURE;


    /* Set output gain */
    status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_IGAIN, &ogain);

    if (status != AUDIO_SUCCESS)
    {
        printTerminalf("test_audio_driver_get_igain: Failed:: Status = %d\n", status);
    }
    else
        printTerminalf("test_audio_driver_get_igain: Success:: Output gain set to %d\n", ogain);

}
















/* Extra features */



void test_audio_driver_set_get_vol(void)
{

	printTerminalf("test_audio_driver_set_get_vol: Under investigation.\n");
#if 0
	Uint32 dev_chan = AUDIO_NULL;
	Uint32 new_vol = AUDIO_NULL;
	Uint32 vol = AUDIO_NULL;
	Int8 status = AUDIO_FAILURE;

	printTerminalf("Enter the channel: 0 - Speaker, 1 - Line-In, 2 - MIC\naudio::mixer> ");
	scanTerminalf("%d", &dev_chan);

	printTerminalf("Enter the volume value between 0-100 \naudio::mixer %d> ", dev_chan);
	scanTerminalf("%d", &new_vol);

	switch(dev_chan)
	{
		case 0:
			{
			/* Set the Speaker volume */
				status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE(SOUND_MIXER_SPEAKER), &new_vol);

				if (status != AUDIO_SUCCESS)
				{
					printTerminalf("test_audio_driver_set_get_vol: Failed:: Status = %d\n", status);
				}
				else
					printTerminalf("test_audio_driver_set_get_vol: Success:: Speaker Volume set to %xh\n", new_vol);

			/* Get the Speaker volume */
				status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ(SOUND_MIXER_SPEAKER), &vol);
	
				if (status != AUDIO_SUCCESS)
				{
					printTerminalf("test_audio_driver_set_get_vol: Failed:: Status = %d\n", status);
				}
				else
					printTerminalf("test_audio_driver_set_get_vol: Success:: Speaker Volume = %xh\n", vol);

				break;
			}

		case 1:
			{
			/* Set the Line-in volume */
				status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE(SOUND_MIXER_LINE), &new_vol);

				if (status != AUDIO_SUCCESS)
				{
					printTerminalf("test_audio_driver_set_get_vol: Failed:: Status = %d\n", status);
				}
				else
					printTerminalf("test_audio_driver_set_get_vol: Success:: Line-in Volume set to %xh\n", new_vol);

			/* Get the Line-in volume */
				status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ(SOUND_MIXER_LINE), &vol);
	
				if (status != AUDIO_SUCCESS)
				{
					printTerminalf("test_audio_driver_set_get_vol: Failed:: Status = %d\n", status);
				}
				else
					printTerminalf("test_audio_driver_set_get_vol: Success:: Line-in Volume = %xh\n", vol);

				break;
			}

		case 2:
			{
			/* Set the Mic volume */
				status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE(SOUND_MIXER_MIC), &new_vol);

				if (status != AUDIO_SUCCESS)
				{
					printTerminalf("test_audio_driver_set_get_mic_vol: Failed:: Status = %d\n", status);
				}
				else
					printTerminalf("test_audio_driver_set_get_mic_vol: Success:: Mic Volume set to %xh\n", new_vol);

	

			/* Get the Mic volume */
				status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ(SOUND_MIXER_MIC), &vol);
	
				if (status != AUDIO_SUCCESS)
				{
					printTerminalf("test_audio_driver_set_get_vol: Failed:: Status = %d\n", status);
				}
				else
					printTerminalf("test_audio_driver_set_get_vol: Success:: Mic Volume = %xh\n", vol);
				
				break;
			}

		default: 
				printTerminalf("test_audio_driver_set_get_vol: Invalid choice!\n");

	}
#endif
}	













/* Record and play through MIC */


void test_audio_driver_mic_recplay(void)
{

	Uint32 old_act_record = AUDIO_NULL;
	Uint32 act_record = 128;		/* Activate MIC */	
	Int8 status = AUDIO_FAILURE;
	Uint32 rxLen = 1024*8;
	Uint32 txLen = 1024*8;
	Uint32 new_frag = 65535;
	audio_buf_info iinf = { 0, };
	Uint8 *Buf = NULL;


	/* Get currently active recording source */
	
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_RECSRC, &old_act_record);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_mic_recplay_get_recsrc: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_mic_recplay_get_recsrc: Success:: Currently active recording source  = %xh\n", old_act_record);

	status = AUDIO_FAILURE;
	
	
	/* Set active recording source to MIC */
	
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_RECSRC, &act_record);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_mic_recplay_set_recsrc: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_mic_recplay_set_recsrc: Success:: Active recording source set to %xh\n", act_record);

	status = AUDIO_FAILURE;
	
	
	/* Set fragment size to maximum */

	new_frag = (new_frag & 0x0000FFFF);
	
	/* Set the audio buffer frament size */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SETFRAGMENT, &new_frag);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_mic_recplay_set_frag: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_mic_recplay_set_frag: Success:: Fragment is %d\n", new_frag);
		printTerminalf("test_audio_driver_mic_recplay_set_frag: Success:: Fragment is %d\n", (new_frag & 0x0000FFFF));
	}

	status = AUDIO_FAILURE;



	/* Get the input buffer info */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETISPACE, &iinf);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_mic_recplay_get_ifragbuf: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_mic_recplay_get_ifragbuf: Number of full fragments are %d\n", iinf.fragments);
		printTerminalf("test_audio_driver_mic_recplay_get_ifragbuf: Number of allocated fragments for buffering are %d\n", iinf.fragstotal);
		printTerminalf("test_audio_driver_mic_recplay_get_ifragbuf: Number of fragments in bytes are %d\n", iinf.fragsize);
		printTerminalf("test_audio_driver_mic_recplay_get_ifragbuf: Number of bytes that can be read without blocking are %d\n", iinf.bytes);
		printTerminalf("test_audio_driver_mic_recplay_get_ifragbuf: Success:: Input fragment is received\n");

		rxLen = iinf.bytes*200;
		txLen = iinf.bytes*200;
	}

	 
	status = AUDIO_FAILURE;

	Buf = (Uint8 *)malloc(rxLen);

	if (NULL != Buf)
	{		
	
		printTerminalf("test_audio_driver_mic_recplay_record: Starting Test, RxLen = %d\n", rxLen);


		status = ST_Read(st_audio_driver[st_audio_instance], Buf, rxLen);
	
		if (status != AUDIO_SUCCESS)
		{
			printTerminalf("test_audio_driver_mic_recplay_record: Failed:: Status = %d\n", status);
		} 
		else 
		{
			printTerminalf("test_audio_driver_mic_recplay_record: Success:: Status = %d\n", status);	

		}
				
		status = AUDIO_FAILURE;
	
		printTerminalf("test_audio_driver_mic_recplay_playback: Starting Test, TxLen = %d\n", txLen);


		status = ST_Write(st_audio_driver[st_audio_instance], Buf, txLen);
		
		if (status != AUDIO_SUCCESS)
		{
			printTerminalf("test_audio_driver_mic_recplay_playback: Failed:: Status = %d\n", status);
		} 
		else 
		{
			printTerminalf("test_audio_driver_mic_recplay_playback: Success:: Status = %d\n", status);	
		}

		free(Buf);
	
	}
	else
	{
		printTerminalf("test_audio_driver_mic_recplay_malloc: Failed:: Buf = %d\n", Buf);
	}
}





void test_audio_driver_line_in_recplay(void)
{

	Uint32 old_act_record = AUDIO_NULL;
	Uint32 act_record = 64;		/* Activate line-in */	
	Int8 status = AUDIO_FAILURE;
	Uint32 rxLen = 1024*8;
	Uint32 txLen = 1024*8;
	Uint32 new_frag = 65535;
	audio_buf_info iinf = { 0, };
	Uint8 *Buf = NULL;


	/* Get currently active recording source */
	
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_READ_RECSRC, &old_act_record);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_line_in_recplay_get_recsrc: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_line_in_recplay_get_recsrc: Success:: Currently active recording source  = %xh\n", old_act_record);

	status = AUDIO_FAILURE;
	
	
	/* Set active recording source to MIC */
	
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SOUND_MIXER_WRITE_RECSRC, &act_record);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_line_in_recplay_set_recsrc: Failed:: Status = %d\n", status);
	}
	else
		printTerminalf("test_audio_driver_line_in_recplay_set_recsrc: Success:: Active recording source set to %xh\n", act_record);

	status = AUDIO_FAILURE;
	
	
	/* Set fragment size to maximum */

	new_frag = (new_frag & 0x0000FFFF);
	
	/* Set the audio buffer frament size */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SETFRAGMENT, &new_frag);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_line_in_recplay_set_frag: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_line_in_recplay_set_frag: Success:: Fragment is %d\n", new_frag);
		printTerminalf("test_audio_driver_line_in_recplay_set_frag: Success:: Fragment is %d\n", (new_frag & 0x0000FFFF));
	}

	status = AUDIO_FAILURE;



	/* Get the input buffer info */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_GETISPACE, &iinf);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_line_in_recplay_get_ifragbuf: Failed:: Status = %d\n", status);
	}
	else
	{
		printTerminalf("test_audio_driver_line_in_recplay_get_ifragbuf: Number of full fragments are %d\n", iinf.fragments);
		printTerminalf("test_audio_driver_line_in_recplay_get_ifragbuf: Number of allocated fragments for buffering are %d\n", iinf.fragstotal);
		printTerminalf("test_audio_driver_line_in_recplay_get_ifragbuf: Number of fragments in bytes are %d\n", iinf.fragsize);
		printTerminalf("test_audio_driver_line_in_recplay_get_ifragbuf: Number of bytes that can be read without blocking are %d\n", iinf.bytes);
		printTerminalf("test_audio_driver_line_in_recplay_get_ifragbuf: Success:: Input fragment is received\n");

		rxLen = iinf.bytes*100;
		txLen = iinf.bytes*100;
	}

	 
	status = AUDIO_FAILURE;

	Buf = (Uint8 *)malloc(rxLen);

	if (NULL != Buf)
	{		
	
		printTerminalf("test_audio_driver_line_in_recplay_record: Starting Test, RxLen = %d\n", rxLen);

	
		status = ST_Read(st_audio_driver[st_audio_instance], Buf, rxLen);
	
		if (status != AUDIO_SUCCESS)
		{
			printTerminalf("test_audio_driver_line_in_recplay_record: Failed:: Status = %d\n", status);
		} 
		else 
		{
			printTerminalf("test_audio_driver_line_in_recplay_record: Success:: Status = %d\n", status);	
		}


		status = AUDIO_FAILURE;
	
		printTerminalf("test_audio_driver_line_in_recplay_playback: Starting Test, TxLen = %d\n", txLen);

		status = ST_Write(st_audio_driver[st_audio_instance], Buf, txLen);
		
		if (status != AUDIO_SUCCESS)
		{
			printTerminalf("test_audio_driver_line_in_recplay_playback: Failed:: Status = %d\n", status);
		} 
		else 
		{
			printTerminalf("test_audio_driver_line_in_recplay_playback: Success:: Status = %d\n", status);	
		}

		free(Buf);
	
	}
	else
	{
		printTerminalf("test_audio_driver_line_in_recplay_malloc: Failed:: Buf = %d\n", Buf);
	}
}











#if 0

//Working
void test_audio_driver_record(void)
{
	Uint32 rxLen=0;
	//Uint32 actualLen = 0;
	Int8 status = AUDIO_FAILURE;
	Uint8*	rxBuf = 0;
#ifdef Cache_enable
	Uint8* srcArray= 0;
#endif

	printTerminalf("test_audio_driver_record: Enter Size \naudio::Record> ");
	scanTerminalf("%d", &rxLen);

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(rxLen+32);
	rxBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));

#else
	rxBuf = (Uint8 *)malloc(rxLen);
#endif
	
	if(NULL == rxBuf)
	{
		printTerminalf("test_audio_driver_record:: Mem Alloc of rxBuf failed\n");
		return;
	}
	


	status = ST_Read(st_audio_driver[st_audio_instance], rxBuf, rxLen);
	
	if (status != AUDIO_SUCCESS) 
	{
		printTerminalf("test_audio_driver_record: Failed:: Status = %d\n", status);
	}
   	else
   	{
		printTerminalf("test_audio_driver_record: Success:: Status = %d\n", status);
	}
}

#endif



void test_audio_driver_record(void)
{
	Uint32 rxLen = 1024*8;	
	Int8 status = AUDIO_FAILURE;
	Uint32 loopcount = 1, i=0;

	printTerminalf("test_audio_driver_record: Enter Size \naudio::Record> ");
	scanTerminalf("%d", &rxLen);


	printTerminalf("test_audio_driver_record: Enter Number of loop times\naudio::record> ");
	scanTerminalf("%d", &loopcount);

	printTerminalf("test_audio_driver_record: Starting Test\n");

	for(i=0; i<loopcount;i++)
	{
		#define NOIOCTL
		status = test_audio_driver_play_rec(44100, 16, rxLen, AUDIO_RECORD);
	
		if (status != AUDIO_SUCCESS)
		{
			printTerminalf("test_audio_driver_record: Failed:: Status = %d\n", status);
			break;
		} 
		else 
		{
			printTerminalf("test_audio_driver_record: Success:: Status = %d\n", status);	
		}
	}
}



#if 0

//Working
void test_audio_driver_playback(void)
{
	Uint32 txLen = 1024*8;
	Uint32 txBuf[1024*8] = {'a', };
	Int8 status = AUDIO_FAILURE;
	Uint32 loopcount = 1, i=0;

	printTerminalf("test_audio_driver_playback: Enter Number of loop times\naudio::playback> ");
	scanTerminalf("%d", &loopcount);

	printTerminalf("test_audio_driver_playback: Starting Test\n");

	for(i=0; i<loopcount;i++)
	{
	
		status = ST_Write(st_audio_driver[st_audio_instance], txBuf, txLen);
	
		if (status != AUDIO_SUCCESS)
		{
			printTerminalf("test_audio_driver_playback: Failed:: Status = %d\n", status);
			break;
		} 
		else 
		{
			printTerminalf("test_audio_driver_playback: Success:: Status = %d\n", status);	
		}
	}
}

#endif


void test_audio_driver_playback(void)
{
	Uint32 txLen = 1024*8;	
	Int8 status = AUDIO_FAILURE;
	Uint32 loopcount = 1, i=0;

	printTerminalf("test_audio_driver_playback: Enter Size \naudio::Playback> ");
	scanTerminalf("%d", &txLen);


	printTerminalf("test_audio_driver_playback: Enter Number of loop times\naudio::playback> ");
	scanTerminalf("%d", &loopcount);

	printTerminalf("test_audio_driver_playback: Starting Test\n");

	for(i=0; i<loopcount;i++)
	{
		#define NOIOCTL
		status = test_audio_driver_play_rec(44100, 16, txLen, AUDIO_PLAY);
	
		if (status != AUDIO_SUCCESS)
		{
			printTerminalf("test_audio_driver_playback: Failed:: Status = %d\n", status);
			break;
		} 
		else 
		{
			printTerminalf("test_audio_driver_playback: Success:: Status = %d\n", status);	
		}
	}
}


#if 0

void test_audio_driver_playback(void)
{
	Uint32 txLen=8194;
	//Uint32 actualLen = 0;
	Uint32 txBuf[1024*8];
	Int8 status = AUDIO_FAILURE;
	//Uint8 * txBuf;
	//
#ifdef Cache_enable
	Uint8* srcArray= 0;
#endif

	//printTerminalf("test_audio_driver_playback: Enter Size \naudio::Playback> ");
	//scanTerminalf("%d", &txLen);

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txLen+32);
	txBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));

#else
	//txBuf = (Uint8 *)malloc(txLen);
	Uint32 txBuf[txLen];
#endif
	
	int i;
	/* Start the Loop from 1 and NOT 0 */
	for(i=0; i < txbuflen; i++)
	{
		if(0 == i%26)
		{
			txBuf[i] = 'a';
		} 
		else 
		{
			txBuf[i] = 'b'; 
		}
	}


	//printTerminalf("test_audio_driver_playback: Enter the Size \naudio::playback_sync> ");
	//scanTerminalf("%d", &txLen);

	printTerminalf("test_audio_driver_playback: Starting Test\n");
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, txLen);
	
	if (status != AUDIO_SUCCESS)
	{
		printTerminalf("test_audio_driver_playback: Failed:: Status = %d\n", status);
	} 
	else 
	{
		printTerminalf("test_audio_driver_playback: Success:: Status = %d\n", status);	
	}
}

#endif

void test_audio_driver_record_sync_and_playback_sync(void)
{
	Uint32 txLen=0;
	//Uint32 actualLen = 0;
	Int8 status = AUDIO_FAILURE;
	Uint8 * txBuf;
	Uint8 * rxBuf;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

	printTerminalf("test_audio_driver_record_sync_and_playback_sync: Enter Size \naudio::record and playback> ");
	scanTerminalf("%d", &txLen);

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txLen+32);
	txBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
	dstArray = (Uint8 *)malloc(txLen+32);
	rxBuf = (Uint8*)((Uint32)(dstArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
	txBuf = (Uint8 *)malloc(txLen);
	rxBuf = (Uint8 *)malloc(txLen);
#endif

	printTerminalf("test_audio_driver_record_sync_and_playback_sync: Starting Test\n");

	if(NULL != rxBuf)
	{
		
		status = ST_Read(st_audio_driver[st_audio_instance], rxBuf, txLen);
	
		if (status != AUDIO_SUCCESS) 
		{
			printTerminalf("test_audio_driver_record_sync_and_playback_sync: Failed:: Record Status = %d\n", status);
		}
   		else
   		{
			printTerminalf("test_audio_driver_record_sync_and_playback_sync: Success:: Record Status = %d\n", status);
		}
		free(rxBuf);
	}
	else
	{
		printf("test_audio_driver_record_sync_and_playback_sync: Rx Malloc failed");
	}
	
	if(NULL != txBuf)
	{
		status = ST_Write(st_audio_driver[st_audio_instance], txBuf, txLen);
	
		if (status != AUDIO_SUCCESS)
		{
			printTerminalf("test_audio_driver_record_sync_and_playback_sync: Failed:: Playback Status = %d\n", status);		
		}
   		else
   		{
			printTerminalf("test_audio_driver_record_sync_and_playback_sync: Success:: Playback Status = %d\n", status);
		}
		free(txBuf);
	}
	else
	{
		printf("test_audio_driver_record_sync_and_playback_sync: Tx Malloc failed");
	}
	
}



void test_audio_driver_sync_stress(void)
{
	Uint32 counter = 0, i = 0;
	Int8 status = AUDIO_FAILURE;

	printTerminalf("test_audio_driver_sync_stress: Enter Number of loop times\naudio::sync::stress> ");
	scanTerminalf("%d", &counter);
	
/*
  	printTerminalf("Supported Audio formats 0-AFMT_QUERY, 1-AFMT_MU_LAW, 2-AFMT_A_LAW, 4-AFMT_IMA_ADPCM, ");
	printTerminalf("8-AFMT_U8, 16-AFMT_S16_LE, 32-AFMT_S16_BE, 64-AFMT_S8, 128-AFMT_U16_LE, 256-AFMT_U16_BE, ");
	printTerminalf("512-AFMT_MPEG, 1024-AFMT_AC3, ");

	*/


	printTerminalf("test_audio_driver_sync_stress: Starting Test\n");

	for(i = 0; i < counter; i++)
	{
		status = test_audio_driver_play_rec(44100, 16, 10000, AUDIO_PLAY);
		//status = test_audio_driver_play_rec(44100, 16, 8192, AUDIO_PLAY);

		status = test_audio_driver_play_rec(44100, 16, 100, AUDIO_PLAY);

	
		status = test_audio_driver_play_rec(48000, 16, 10000, AUDIO_PLAY);
		//status = test_audio_driver_play_rec(48000, 16, 8192, AUDIO_PLAY);

		status = test_audio_driver_play_rec(48000, 16, 100, AUDIO_PLAY);


		
		status = test_audio_driver_play_rec(44100, 16, 10000, AUDIO_RECORD);
		//status = test_audio_driver_play_rec(44100, 16, 8192, AUDIO_RECORD);

		status = test_audio_driver_play_rec(44100, 16, 100, AUDIO_RECORD);

	
		status = test_audio_driver_play_rec(48000, 16, 10000, AUDIO_RECORD);
		//status = test_audio_driver_play_rec(48000, 16, 8192, AUDIO_RECORD);

		status = test_audio_driver_play_rec(48000, 16, 100, AUDIO_RECORD);


		
		status = test_audio_driver_play_rec(44100, 16, 10000, AUDIO_PLAY_REC);
		//status = test_audio_driver_play_rec(44100, 16, 8192, AUDIO_PLAY_REC);

		status = test_audio_driver_play_rec(44100, 16, 100, AUDIO_PLAY_REC);

	
		status = test_audio_driver_play_rec(48000, 16, 10000, AUDIO_PLAY_REC);
		//status = test_audio_driver_play_rec(48000, 16, 8192, AUDIO_PLAY_REC);

		status = test_audio_driver_play_rec(48000, 16, 100, AUDIO_PLAY_REC);
		

	}
	
	printTerminalf("test_audio_driver_sync_stress: Success:: Test is Over\n");
	
}



void test_audio_driver_len_in_sync_stress(void)
{
	Uint32 counter = 0, i = 0;
	Uint32 Len=0;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("test_audio_driver_len_in_sync_stress: Enter Size \naudio::sync_stress> ");
	scanTerminalf("%d", &Len);
	
	printTerminalf("test_audio_driver_len_in_sync_stress: Enter Number of loop times\naudio::sync::stress> ");
	scanTerminalf("%d", &counter);
	
/*
  	printTerminalf("Supported Audio formats 0-AFMT_QUERY, 1-AFMT_MU_LAW, 2-AFMT_A_LAW, 4-AFMT_IMA_ADPCM, ");
	printTerminalf("8-AFMT_U8, 16-AFMT_S16_LE, 32-AFMT_S16_BE, 64-AFMT_S8, 128-AFMT_U16_LE, 256-AFMT_U16_BE, ");
	printTerminalf("512-AFMT_MPEG, 1024-AFMT_AC3, ");

	*/


	printTerminalf("test_audio_driver_len_in_sync_stress: Starting Test\n");

	for(i = 0; i < counter; i++)
	{
		status = test_audio_driver_play_rec(44100, 16, Len, AUDIO_PLAY);
	
		status = test_audio_driver_play_rec(48000, 16, Len, AUDIO_PLAY);

		
		
		status = test_audio_driver_play_rec(44100, 16, Len, AUDIO_RECORD);

	
		status = test_audio_driver_play_rec(48000, 16, Len, AUDIO_RECORD);

		

		status = test_audio_driver_play_rec(44100, 16, Len, AUDIO_PLAY_REC);

	
		status = test_audio_driver_play_rec(48000, 16, Len, AUDIO_PLAY_REC);
	}
	
	printTerminalf("test_audio_driver_len_in_sync_stress: Success:: Test is Over\n");
	
}


void test_audio_driver_async_stress(void)
{
	Uint32 counter = 0, i = 0;
	Int8 status = AUDIO_FAILURE;

	printTerminalf("test_audio_driver_async_stress: Enter Number of loop times\naudio::async::stress> ");
	scanTerminalf("%d", &counter);
	
/*
  	printTerminalf("Supported Audio formats 0-AFMT_QUERY, 1-AFMT_MU_LAW, 2-AFMT_A_LAW, 4-AFMT_IMA_ADPCM, ");
	printTerminalf("8-AFMT_U8, 16-AFMT_S16_LE, 32-AFMT_S16_BE, 64-AFMT_S8, 128-AFMT_U16_LE, 256-AFMT_U16_BE, ");
	printTerminalf("512-AFMT_MPEG, 1024-AFMT_AC3, ");

	*/

	
	/* Make the call as asynchronous (non-blocking) call */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_NONBLOCK, NULL);

	printTerminalf("test_audio_driver_async_stress: Starting Test\n");

	for(i = 0; i < counter; i++)
	{
		status = test_audio_driver_play_rec(44100, 16, 10000, AUDIO_PLAY);

		status = test_audio_driver_play_rec(44100, 16, 100, AUDIO_PLAY);

	
		status = test_audio_driver_play_rec(48000, 16, 10000, AUDIO_PLAY);

		status = test_audio_driver_play_rec(48000, 16, 100, AUDIO_PLAY);


		
		status = test_audio_driver_play_rec(44100, 16, 10000, AUDIO_RECORD);

		status = test_audio_driver_play_rec(44100, 16, 100, AUDIO_RECORD);

	
		status = test_audio_driver_play_rec(48000, 16, 10000, AUDIO_RECORD);

		status = test_audio_driver_play_rec(48000, 16, 100, AUDIO_RECORD);


		
		status = test_audio_driver_play_rec(44100, 16, 10000, AUDIO_PLAY_REC);

		status = test_audio_driver_play_rec(44100, 16, 100, AUDIO_PLAY_REC);

	
		status = test_audio_driver_play_rec(48000, 16, 10000, AUDIO_PLAY_REC);

		status = test_audio_driver_play_rec(48000, 16, 100, AUDIO_PLAY_REC);
		

	}
	
	printTerminalf("test_audio_driver_async_stress: Success:: Test is Over\n");
	
}



void test_audio_driver_len_in_async_stress(void)
{
	Uint32 counter = 0, i = 0;
	Uint32 Len=0;
	Int8 status = AUDIO_FAILURE;
	
	printTerminalf("test_audio_driver_len_in_async_stress: Enter Size \naudio::async_stress> ");
	scanTerminalf("%d", &Len);
	
	printTerminalf("test_audio_driver_len_in_async_stress: Enter Number of loop times\naudio::async::stress> ");
	scanTerminalf("%d", &counter);
	
/*
  	printTerminalf("Supported Audio formats 0-AFMT_QUERY, 1-AFMT_MU_LAW, 2-AFMT_A_LAW, 4-AFMT_IMA_ADPCM, ");
	printTerminalf("8-AFMT_U8, 16-AFMT_S16_LE, 32-AFMT_S16_BE, 64-AFMT_S8, 128-AFMT_U16_LE, 256-AFMT_U16_BE, ");
	printTerminalf("512-AFMT_MPEG, 1024-AFMT_AC3, ");

	*/

	
	/* Make the call as asynchronous (non-blocking) call */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_NONBLOCK, NULL);

	printTerminalf("test_audio_driver_len_in_async_stress: Starting Test\n");

	for(i = 0; i < counter; i++)
	{
		status = test_audio_driver_play_rec(44100, 16, Len, AUDIO_PLAY);
	
		status = test_audio_driver_play_rec(48000, 16, Len, AUDIO_PLAY);

		
		
		status = test_audio_driver_play_rec(44100, 16, Len, AUDIO_RECORD);

	
		status = test_audio_driver_play_rec(48000, 16, Len, AUDIO_RECORD);

		

		status = test_audio_driver_play_rec(44100, 16, Len, AUDIO_PLAY_REC);

	
		status = test_audio_driver_play_rec(48000, 16, Len, AUDIO_PLAY_REC);
	}
	
	printTerminalf("test_audio_driver_len_in_async_stress: Success:: Test is Over\n");
	
}



void test_audio_driver_stability(void)
{	
	Uint32 loop_counter=0;
	Uint32 i = 0;
	Uint32 attr = O_RDWR;
	//Int8 status = AUDIO_FAILURE;

	printTerminalf("test_audio_driver_stability: Enter loop counter value\naudio::stability> ");
	scanTerminalf("%d", &loop_counter);

	printTerminalf("test_audio_driver_stability: Enter the attribute for open:: 0-RONLY, 1-WONLY, 2-RDWR\n");
	scanTerminalf("%d", &attr);
	

/* Enable/ Disable test */
	
	printTerminalf("Starting test_audio_driver_stability\n");


	if (0 == instflag[st_audio_instance])
	{
		test_audio_driver_open();
		instflag[st_audio_instance] =1;
	}
	
	
	for(i = 0; i < loop_counter; i++)
	{


		test_audio_driver_close();

		test_audio_driver_open();
#if 0
		status = ST_Close(st_audio_driver[st_audio_instance]);
		
		if (status != AUDIO_SUCCESS) 
		{
			printTerminalf("test_audio_driver_stability:: AUDIO Close Instance:%d Failed:%d\n", 0, status);
		}
		else
		{
			st_audio_driver[st_audio_instance] = AUDIO_FAIL;
		}

		status = ST_Open(INSTANCE, attr, &fd_audio);
		//fd_audio = open(INSTANCE, attr);

		if( fd_audio < AUDIO_SUCCESS)
		{
			st_audio_driver[st_audio_instance] = fd_audio;
			printTerminalf("test_audio_driver_stability:: Success AUDIO Instance:%d\n", st_audio_instance);
		}
		else
   		{
			printTerminalf("test_audio_driver_stability:: Failed AUDIO Instance:%d Errno:%d\n", st_audio_instance, fd_audio);
		}
#endif
	}



/*
  	printTerminalf("Supported Audio formats 0-AFMT_QUERY, 1-AFMT_MU_LAW, 2-AFMT_A_LAW, 4-AFMT_IMA_ADPCM, ");
	printTerminalf("8-AFMT_U8, 16-AFMT_S16_LE, 32-AFMT_S16_BE, 64-AFMT_S8, 128-AFMT_U16_LE, 256-AFMT_U16_BE, ");
	printTerminalf("512-AFMT_MPEG, 1024-AFMT_AC3, ");

	*/



/* Note: Need to remove #if 0 after getting information */
	
/* Data playback and record test */
#if 0
	status = test_audio_driver_play_rec(48000, 16, 1000, AUDIO_PLAY);
	status = test_audio_driver_play_rec(11025, 24, 0, AUDIO_PLAY);
	status = test_audio_driver_play_rec(24000, 20, 5000, AUDIO_PLAY);
	status = test_audio_driver_play_rec(88200, 32, 1, AUDIO_PLAY);
	status = test_audio_driver_play_rec(8000, 20, 5000, AUDIO_PLAY);
#endif	

#if 0
	status = test_audio_driver_play_rec(44100, 20, 1000, AUDIO_RECORD);
	status = test_audio_driver_play_rec(48000, 16, 0, AUDIO_RECORD);
	status = test_audio_driver_play_rec(22050, 24, 5000, AUDIO_RECORD);
	status = test_audio_driver_play_rec(96000, 20, 1, AUDIO_RECORD);
	status = test_audio_driver_play_rec(12000, 20, 5000, AUDIO_RECORD);
#endif	

#if 0
	status = test_audio_driver_play_rec(48000, 32, 1000, AUDIO_PLAY_REC);
	status = test_audio_driver_play_rec(16000, 16, 0, AUDIO_PLAY_REC);
	status = test_audio_driver_play_rec(8000, 16, 5000, AUDIO_PLAY_REC);
	status = test_audio_driver_play_rec(88200, 24, 1, AUDIO_PLAY_REC);
	status = test_audio_driver_play_rec(24000, 20, 5000, AUDIO_PLAY_REC);
#endif	
	printTerminalf("test_audio_driver_stability: Success:: Test is Over\n");
	
}



void test_audio_driver_perf_play(void)
{
	Int8 status = AUDIO_FAILURE;
    struct timeval time;
	Uint32 Start_Time = 0;
    Uint32 Start_sec = 0;

	Uint32 new_sr = 48000;
	Uint32 txLen = 1024;
	Uint32 i = 0, loopcount = 1;
	Uint8 *txBuf;
	Uint8 Buf[1026] = {0x00,0x00,0x00,0x00,0xAC,0xF3,0x84,0xFC,0x30,0xF1,0x92,0xF9,0xDC,0xED,0x13,0xF6,0xB2,0xE9,0xA1,0xF2,0x6B,0xE5,0x03,0xEF,0xF8,0xE0,0xC0,0xEB,0xEC,0xDC,0x61,0xE8,0xED,0xD8,0xF4,0xE5,0x05,0xD6,0x71,0xE4,0x64,0xD4,0xB0,0xE3,0x7F,0xD3,0xC6,0xE3,0xB1,0xD3,0x96,0xE4,0xD6,0xD4,0xD1,0xE5,0x5E,0xD6,0x0D,0xE7,0xEB,0xD7,0xE8,0xE7,0x09,0xD9,0x3B,0xE8,0xAA,0xD9,0x40,0xE8,0xAC,0xD9,0x64,0xE7,0xCE,0xD,0x81,0x0E,0x63,0x8D,0x73,0xDE,0x4E,0xBD,0x43,0xEE,0x28,0x9D,0x29,0x5E,0x05,0x0D,0x0D,0x0D,0xE6,0x7C,0xE7,0x9,0xDD,0xF7,0xCC,0xF8,0xDC,0x3E,0xCC,0x5D,0xDD,0xA3,0xCC,0x2D,0xDE,0x8B,0xCD,0xED,0xDE,0xDD,0xCE,0x62,0xE0,0xD2,0xD0,0x2C,0xE2,0x0C,0xD3,0xFC,0xE3,0x79,0xD5,0xEB,0xE5,0xDD,0xD7,0x73,0xE7,0xC7,0xD9,0x16,0xE9,0xE0,0xDB,0xC1,0xEA,0xD3,0xDD,0xEE,0xEB,0x39,0xDF,0xE8,0xEC,0x9E,0xE0,0xFC,0xED,0x1E,0xE2,0xD7,0xEE,0x1B,0xE3,0xC4,0xEF,0xF3,0xE3,0xBA,0xF0,0xF3,0xE4,0x2D,0xF1,0xCA,0xE5,0x2C,0xF2,0x13,0xE7,0x17,0xF3,0x22,0xE8,0x2D,0xF4,0x63,0xE9,0xC4,0xF5,0x5C,0xEB,0x62,0xF7,0x4D,0xED,0x2D,0xF9,0x68,0xEF,0xF4,0xFA,0xB5,0xF1,0xC3,0xFC,0xE4,0xF3,0x17,0xFE,0x9E,0xF5,0x3C,0xFF,0xF8,0xF6,0x42,0x00,0x0E,0xF8,0xED,0x00,0xD4,0xF8,0x24,0x01,0xFF,0xF8,0xAB,0x00,0x8C,0xF8,0x75,0x00,0x40,0xF8,0x62,0x00,0x29,0xF8,0x73,0x00,0x76,0xF8,0x0D,0x01,0x34,0xF9,0x17,0x02,0x27,0xFA,0x8A,0x03,0x07,0xFC,0x53,0x05,0x34,0xFE,0x33,0x07,0x59,0x00,0x2C,0x09,0xA8,0x02,0xDA,0x0A,0x9A,0x04,0x1F,0x0C,0x41,0x06,0x1A,0x0D,0x65,0x07,0x8D,0x0D,0xF5,0x07,0x80,0x0D,0x13,0x08,0x4A,0x0D,0xA7,0x07,0xF7,0x0C,0x21,0x07,0x99,0x0C,0xD4,0x06,0x5D,0x0C,0x57,0x06,0x1D,0x0C,0xE7,0x05,0x3F,0x0C,0xF9,0x05,0xA2,0x0C,0x74,0x06,0x19,0x0D,0x0D,0x07,0xDA,0x0D,0x1D,0x08,0xB4,0x0E,0x41,0x09,0x82,0x0F,0x22,0x0A,0x54,0x10,0x1B,0x0B,0xDE,0x10,0xE2,0x0B,0x77,0x11,0x61,0x0C,0xE8,0x11,0xBB,0x0C,0x53,0x12,0x50,0x0D,0x98,0x12,0xBA,0x0D,0xC1,0x12,0xF0,0x0D,0x36,0x13,0x3C,0x0E,0x6B,0x13,0xA0,0x0E,0x99,0x13,0xF5,0x0E,0x17,0x14,0x80,0x0F,0xCE,0x14,0x28,0x10,0x6F,0x15,0xEE,0x10,0x26,0x16,0xF6,0x11,0x12,0x17,0x0D,0x13,0x1C,0x18,0x33,0x14,0x51,0x19,0x9C,0x15,0x76,0x1A,0x24,0x17,0xBA,0x1B,0xAA,0x18,0xD7,0x1C,0x29,0x1A,0x32,0x1E,0xBC,0x1B,0x8F,0x1F,0x49,0x1D,0xD8,0x20,0xC4,0x1E,0x12,0x22,0x42,0x20,0x05,0x23,0x6B,0x21,0x18,0x24,0x99,0x22,0xFC,0x24,0xB5,0x23,0xB1,0x25,0x7E,0x24,0x6D,0x26,0x53,0x25,0x00,0x27,0x15,0x26,0x63,0x27,0x8D,0x26,0xC8,0x27,0x01,0x27,0x3A,0x28,0x62,0x27,0xBC,0x28,0xFD,0x27,0x79,0x29,0xBA,0x28,0x2E,0x2A,0x9F,0x29,0xB1,0x2A,0x61,0x2A,0x5E,0x2B,0x1C,0x2B,0x7C,0x2C,0x92,0x2C,0xB6,0x2D,0x0B,0x2E,0x1A,0x2F,0xCA,0x2F,0xBA,0x30,0xAC,0x31,0x4D,0x32,0x8A,0x33,0xA5,0x33,0x26,0x35,0xA6,0x34,0x4F,0x36,0x18,0x35,0x0A,0x37,0xEF,0x34,0xC3,0x36,0x5D,0x34,0xF5,0x35,0x22,0x33,0x52,0x34,0x5A,0x31,0xEF,0x31,0x3E,0x2F,0x7E,0x2F,0x35,0x2D,0x09,0x2D,0x61,0x2B,0x9C,0x2A,0xBA,0x29,0xB9,0x28,0xDC,0x28,0x95,0x27,0x81,0x28,0xF7,0x26,0x99,0x28,0x14,0x27,0x1C,0x29,0x93,0x27,0x98,0x29,0x52,0x28,0xE3,0x29,0xCB,0x28,0xFE,0x29,0xE4,0x28,0x4A,0x29,0x3B,0x28,0x1E,0x28,0xA8,0x26,0x6B,0x26,0x72,0x24,0xD0,0x23,0x3E,0x21,0xCB,0x20,0x70,0x1D,0x87,0x1D,0x69,0x19,0x4C,0x1A,0x68,0x15,0x5A,0x17,0xEF,0x11,0xBE,0x14,0xA2,0x0E,0x8D,0x12,0xF2,0x0B,0xEC,0x10,0xE4,0x09,0x89,0x0F,0x4D,0x08,0x60,0x0E,0xD7,0x06,0x2E,0x0D,0x6F,0x05,0xF8,0x0B,0x0A,0x04,0x78,0x0A,0xF4,0x01,0x55,0x08,0x93,0xFF,0x10,0x06,0xD4,0xFC,0x5E,0x03,0x84,0xF9,0x68,0x00,0xF7,0xF5,0x74,0xFD,0x5F,0xF2,0x81,0xFA,0xC2,0xEE,0xA6,0xF7,0x3B,0xEB,0xFF,0xF4,0x0C,0xE8,0xAA,0xF2,0x61,0xE5,0x84,0xF0,0xD8,0xE2,0x86,0xEE,0x78,0xE0,0xD2,0xEC,0x7F,0xDE,0x4F,0xEB,0xD0,0xDC,0x03,0xEA,0x18,0xDB,0xAE,0xE8,0x2A,0xD9,0x0A,0xE7,0x7D,0xD7,0xDD,0xE5,0x55,0xD6,0xBC,0xE4,0xF4,0xD4,0xBA,0xE3,0xDD,0xD3,0x21,0xE3,0x2C,0xD3,0xB8,0xE2,0xA0,0xD2,0x4F,0xE2,0x42,0xD2,0xB4,0xE1,0x17,0xD2,0x72,0xE1,0x90,0xD1,0x02,0xE1,0xE6,0xD0,0x36,0xE0,0x0F,0xD0,0x3A,0xDF,0xD2,0xCE,0x12,0xDE,0x85,0xCD,0xE4,0xDC,0x31,0xCC,0xC3,0xDB,0x02,0xCB,0xCE,0xDA,0xEA,0xC9,0x52,0xDA,0x4B,0xC9,0x03,0xDA,0xFA,0xC8,0x3B,0xDA,0x60,0xC9,0x15,0xDB,0x60,0xCA,0x5A,0xDC,0xFD,0xCB,0x06,0xDE,0x15,0xCE,0xBA,0xDF,0x29,0xD0,0x90,0xE1,0x96,0xD2,0x38,0xE3,0xA5,0xD4,0xAA,0xE4,0x93,0xD6,0xFC,0xE5,0x47,0xD8,0xFF,0xE6,0x63,0xD9,0xC6,0xE7,0x76,0xDA,0x8D,0xE8,0x39,0xDB,0x52,0xE9,0x16,0xDC,0xE8,0xE9,0x0B,0xDD,0xB4,0xEA,0x2D,0xDE,0xE8,0xEB,0x8D,0xDF,0x92,0xED,0xA4,0xE1,0x51,0xEF,0xDE,0xE3,0x5A,0xF1,0x2B,0xE6,0x6B,0xF3,0xB1,0xE8,0x16,0xF5,0xEC,0xEA,0x8A,0xF6,0x9E,0xEC,0x84,0xF7,0xBE,0xED,0x05,0xF8,0x4D,0xEE,0xE5,0xF7,0x28,0xEE,0x69,0xF7,0x91,0xED,0xE2,0xF6,0x9C,0xEC,0x2D,0xF6,0xD6,0xEB,0xFC,0xF5,0x76,0xEB,0x50,0xF6,0xC2,0xEB,0x36,0xF7,0x12,0xED,0x11,0xF9,0x82,0xEF,0xC3,0xFB,0xB9,0xF2,0xEA,0xFE,0x91,0xF6,0x51,0x02,0xB5,0xFA,0xC3,0x05,0xFB,0xFE,0xC5,0x08,0x86,0x02,0x10,0x0B,0x45,0x05,0xAA,0x0C,0x47,0x07,0x58,0x0D,0x13,0x08,0x38,0x0D,0xD8,0x07,0x5D,0x0C,0xAF,0x06,0x2A,0x0B,0x3E,0x05,0xCF,0x09,0x6E,0x03,0xD2,0x08,0x18,0x02,0x5F,0x08,0x38,0x01,0x2C,0x08,0x05,0x01,0x90,0x08,0x9C,0x01,0xEF,0x09,0x2D,0x03,0xA8,0x0B,0x3E,0x05,0x60,0x0D,0xAC,0x07,0x8D,0x0F,0x36,0x0A,0xC8,0x11,0xDB,0x0C,0xF1,0x13,0x84,0x0F,0xA0,0x15,0x78,0x11,0x56,0x16,0xA7,0x12,0xF3,0x16,0x5F,0x13,0x44,0x17,0x9F,0x13,0x3F,0x17,0x9C,0x13,0x4E,0x17,0x6F,0x13,0xE4,0x16,0xE7,0x12,0x34,0x16,0x14,0x12,0xAE,0x15,0x4B,0x11,0x3A,0x15,0xA4};	
#ifdef Cache_enable
	Uint8* srcArray= 0;
#endif

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txLen+32);
	txBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
	txBuf = (Uint8 *)malloc(txLen);
#endif
	
	if (NULL != txBuf)
	{

		printTerminalf("Enter the sampling rate: \naudio::sr:");
		scanTerminalf("%d", &new_sr);

		status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SPEED, &new_sr);

		if (status != AUDIO_SUCCESS)
		{	
			new_sr = 48000;
			status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SPEED, &new_sr);
		}
				
		printTerminalf("Enter the loop count \naudio::count:");
		scanTerminalf("%d", &loopcount);
	
		printTerminalf("test_audio_driver_perf_play: Starting Test\n");
	
		/* Enable timer to be added */
	
		gettimeofday(&time,NULL);

    	Start_Time = time.tv_usec;
		Start_sec = time.tv_sec;

		for(i =0; i< loopcount; i++)
		{
				//status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, txLen);
				status = ST_Write(st_audio_driver[st_audio_instance], Buf, txLen);
		}
				
		/* Disable timer and get timer value to be added */

		gettimeofday(&time,NULL);
	
		printTerminalf("test_audio_driver_perf_play:: Timer value for (1024*%d) data playback size - Status = %d: Start time = %dus, End time = %dus\nStart = %ds, End = %ds\n", loopcount, status, Start_Time, time.tv_usec, Start_sec, time.tv_sec);

	}
}




void test_audio_driver_perf_record(void)
{
	Int8 status = AUDIO_FAILURE;
	struct timeval time;
	Uint32 Start_Time = 0;
    Uint32 Start_sec = 0;

	Uint32 new_sr = 48000;
	Uint32 rxLen = 1024;
	Uint32 i = 0, loopcount = 1;

	Uint8 * rxBuf;
	
#ifdef Cache_enable
	Uint8* srcArray= 0;
#endif

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(rxLen+32);
	rxBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
	rxBuf = (Uint8 *)malloc(rxLen);
#endif
	if (NULL != rxBuf)
	{

		printTerminalf("Enter the sampling rate: \naudio::sr:");
		scanTerminalf("%d", &new_sr);

		status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SPEED, &new_sr);

		if (status != AUDIO_SUCCESS)
		{	
			new_sr = 48000;
			status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SPEED, &new_sr);
		}
				
		printTerminalf("Enter the loop count: \naudio::count:");
		scanTerminalf("%d", &loopcount);
	
		printTerminalf("test_audio_driver_perf_record: Starting Test\n");
	
		/* Enable timer to be added */
	
		gettimeofday(&time,NULL);

    	Start_Time = time.tv_usec;
		Start_sec = time.tv_sec;

		for(i =0; i< loopcount; i++)
		{
				status = ST_Write(st_audio_driver[st_audio_instance], &rxBuf, rxLen);
		}
				
		/* Disable timer and get timer value to be added */

		gettimeofday(&time,NULL);
	
		printTerminalf("test_audio_driver_perf_record:: Timer value for (1024*%d) data playback size - Status = %d: Start time = %dus, End time = %dus\nStart = %ds, End = %ds\n", loopcount, status, Start_Time, time.tv_usec, Start_sec, time.tv_sec);

	}
}







/* Need to add simultaneous playback and record after more investigation */

void test_audio_driver_sync_performance(void)
{
	Int8 status = AUDIO_FAILURE;
	struct timeval time;
    Uint32 Start_Time = 0;
    Uint32 Start_sec = 0;

	Uint32 new_sr = 44100;
	Uint8 * txBuf;
	Uint8 * rxBuf;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txbuflen+32);
	txBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
	dstArray = (Uint8 *)malloc(rxbuflen+32);
	rxBuf = (Uint8*)((Uint32)(dstArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
	txBuf = (Uint8 *)malloc(txbuflen);
	rxBuf = (Uint8 *)malloc(rxbuflen);
#endif
	if ((NULL != txBuf) && (NULL != rxBuf))
	{
/*
  	printTerminalf("Supported Audio formats 0-AFMT_QUERY, 1-AFMT_MU_LAW, 2-AFMT_A_LAW, 4-AFMT_IMA_ADPCM, ");
	printTerminalf("8-AFMT_U8, 16-AFMT_S16_LE, 32-AFMT_S16_BE, 64-AFMT_S8, 128-AFMT_U16_LE, 256-AFMT_U16_BE, ");
	printTerminalf("512-AFMT_MPEG, 1024-AFMT_AC3, ");

	*/


	printTerminalf("test_audio_driver_sync_performance: Starting Test\n");
	
	

	/* Enable timer to be added */
	
	gettimeofday(&time,NULL);

    Start_Time = time.tv_usec;
	Start_sec = time.tv_sec;

	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 100);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);
	
	printTerminalf("test_audio_driver_sync_performance:: Timer value for 100 data playback size: Start time = %dus, End time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */

	gettimeofday(&time,NULL);
	Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;

	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 1000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 1000 data playback size: Start time = %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 10000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 10000 data playback size: Start time = %dus, End time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */
	
	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;

	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 1000000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 1000000 data playback size: Start Time = %dus, End Time =%dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);







	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 100);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 100 data record size: Start Time = %dus, End time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 1000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 1000 data record size: Start Time = %dus, End time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 10000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);	

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 10000 data record size: Start Time =  %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */
	
	 gettimeofday(&time,NULL);
  	 Start_Time=time.tv_usec;
	 Start_sec = time.tv_sec;

	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 1000000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);		

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 1000000 data record size: Start Time = %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);


	


	
	


	new_sr = 44000;

	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SPEED, &new_sr);

	
	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 100);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 100 data playback size: Start Time = %dus, end Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);




	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 1000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 1000 data playback size: Start Time = %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 10000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 10000 data playback size: Start Time = %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);




	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 1000000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 1000000 data playback size: Start Time = %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);


		



	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 100);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);
	
	printTerminalf("test_audio_driver_sync_performance:: Timer value for 100 data record size: Start Time = %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);




	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 1000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 1000 data record size: Start Time = %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 10000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 10000 data record size: Start Time = %dus , End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);



	/* Enable timer to be added */

	gettimeofday(&time,NULL);
    Start_Time=time.tv_usec;
	Start_sec = time.tv_sec;
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 1000000);

	/* Disable timer and get timer value to be added */

	gettimeofday(&time,NULL);

	printTerminalf("test_audio_driver_sync_performance:: Timer value for 1000000 data record size: Start time = %dus, End Time = %dus\nStart = %ds, End = %ds\n", Start_Time, time.tv_usec, Start_sec, time.tv_sec);


	free(txBuf);
	free(rxBuf);
	
	printTerminalf("test_audio_driver_sync_performance: Success:: Test is Over\n");

	}
	else
	{
		printf("test_audio_driver_sync_performance: Malloc Failed");
	}
	
}










/* Need to add simultaneous playback and record after more investigation */

void test_audio_driver_async_performance(void)
{
	Int8 status = AUDIO_FAILURE;
	Uint32 timer_val = 0;
	Uint32 new_sr = 44100;
	Uint8 * txBuf;
	Uint8 * rxBuf;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif

#ifdef Cache_enable
	srcArray = (Uint8 *)malloc(txbuflen+32);
	txBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
	dstArray = (Uint8 *)malloc(rxbuflen+32);
	rxBuf = (Uint8*)((Uint32)(dstArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
	txBuf = (Uint8 *)malloc(txbuflen);
	rxBuf = (Uint8 *)malloc(rxbuflen);
#endif
	
	if ((NULL != txBuf) && (NULL != rxBuf))
	{
	
/*
  	printTerminalf("Supported Audio formats 0-AFMT_QUERY, 1-AFMT_MU_LAW, 2-AFMT_A_LAW, 4-AFMT_IMA_ADPCM, ");
	printTerminalf("8-AFMT_U8, 16-AFMT_S16_LE, 32-AFMT_S16_BE, 64-AFMT_S8, 128-AFMT_U16_LE, 256-AFMT_U16_BE, ");
	printTerminalf("512-AFMT_MPEG, 1024-AFMT_AC3, ");

	*/

	
	/* Make the call as asynchronous (non-blocking) call */
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_NONBLOCK, NULL);

	printTerminalf("test_audio_driver_async_performance: Starting Test\n");
	
	

	/* Enable timer to be added */
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 100);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 100 data playback size is %d\n", timer_val);

	timer_val = 0;



	/* Enable timer to be added */
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 1000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 1000 data playback size is %d\n", timer_val);

	timer_val = 0;


	/* Enable timer to be added */
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 10000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 10000 data playback size is %d\n", timer_val);

	timer_val = 0;



	/* Enable timer to be added */
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 1000000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 1000000 data playback size is %d\n", timer_val);

	timer_val = 0;






	/* Enable timer to be added */
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 100);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 100 data record size is %d\n", timer_val);

	timer_val = 0;



	/* Enable timer to be added */
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 1000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 1000 data record size is %d\n", timer_val);

	timer_val = 0;


	/* Enable timer to be added */
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 10000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 10000 data record size is %d\n", timer_val);

	timer_val = 0;



	/* Enable timer to be added */
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 1000000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 1000000 data record size is %d\n", timer_val);

	timer_val = 0;








	
	


	new_sr = 44000;

	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SPEED, &new_sr);

	
	/* Enable timer to be added */
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 100);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 100 data playback size is %d\n", timer_val);

	timer_val = 0;



	/* Enable timer to be added */
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 1000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 1000 data playback size is %d\n", timer_val);

	timer_val = 0;


	/* Enable timer to be added */
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 10000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 10000 data playback size is %d\n", timer_val);

	timer_val = 0;



	/* Enable timer to be added */
	
	status = ST_Write(st_audio_driver[st_audio_instance], &txBuf, 1000000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 1000000 data playback size is %d\n", timer_val);

	timer_val = 0;





	/* Enable timer to be added */
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 100);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 100 data record size is %d\n", timer_val);

	timer_val = 0;



	/* Enable timer to be added */
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 1000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 1000 data record size is %d\n", timer_val);

	timer_val = 0;


	/* Enable timer to be added */
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 10000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 10000 data record size is %d\n", timer_val);

	timer_val = 0;


	/* Enable timer to be added */
	
	status = ST_Read(st_audio_driver[st_audio_instance], &rxBuf, 1000000);

	/* Disable timer and get timer value to be added */

	printTerminalf("test_audio_driver_async_performance: Timer value for 1000000 data record size is %d\n", timer_val);

	timer_val = 0;

	
	free(txBuf);
	free(rxBuf);
	printTerminalf("test_audio_driver_async_performance: Success:: Test is Over\n");
	}
	else
	{
		printf("test_audio_driver_async_performance: Malloc Failed");
	}


	
	
}





/* Negative Test cases - NULL Test Case */
void test_audio_driver_NULL_Instance(void)
{
#ifdef Cache_enable
	Uint8 srcArray[6 + AUDIO_CACHE_LINE_SIZE_IN_BYTES] = "Hello";

	Uint8 * txBuf;

   /* aligning srcBuf on CACHE line size boundary */

	txBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));

#else
	char txBuf[] = "Hello";
#endif
	Int8 status = AUDIO_FAILURE;
	
	Uint32 txLen= strlen(txBuf);
	
	status = ST_Write(AUDIO_FAIL, &txBuf, txLen);
	
	if (status != AUDIO_SUCCESS) 
	{
		printTerminalf("test_audio_driver_NULL_Instance: Success:: Playback Status = %d\n", status);
	}
   	else
   	{
		printTerminalf("test_audio_driver_NULL_Instance: Failed:: Playback Status = %d\n", status);
	}

	status = ST_Read(AUDIO_FAIL, &txBuf, txLen);
	
	if (status != AUDIO_SUCCESS) 
	{
		printTerminalf("test_audio_driver_NULL_Instance: Success:: Record Status = %d\n", status);
	}
   	else
   	{
		printTerminalf("test_audio_driver_NULL_Instance: Failed:: Record Status = %d\n", status);
	}
}










/* Internal functions */

Int8 test_audio_driver_play_rec(Uint32 sr, Uint8 datalen, Uint32 size, Uint8 play_rec)
{
	Int8 status = AUDIO_FAILURE;
	Uint8 * txBuf;
	Uint8 * rxBuf;
#ifdef Cache_enable
	Uint8* srcArray= 0;
	Uint8* dstArray= 0;
#endif
	
#ifndef NOIOCTL
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SPEED, &sr);
	status = ST_Ioctl(st_audio_driver[st_audio_instance], SNDCTL_DSP_SETFMT, &datalen);
#endif
#ifdef NOIOCTL
	#undef NOIOCTL
#endif


	if (AUDIO_PLAY == play_rec)
	{
#ifdef Cache_enable
		srcArray = (Uint8 *)malloc(size+32);
		txBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
		txBuf = (Uint8 *)malloc(size);
#endif
		if( NULL != txBuf)
		{
			status = ST_Write(st_audio_driver[st_audio_instance], txBuf, size);
		
			if (status != AUDIO_SUCCESS) 
			{
				printTerminalf("test_audio_driver_play_rec:: Playback Failed\n");	
			}

			else
			{
				printTerminalf("test_audio_driver_play_rec:: Playback Success\n");
			}
		
			free(txBuf);
		}
		else
		{
			printTerminalf("test_audio_driver_play_rec:: Tx Malloc Failed\n");
		}
	}

	else if (AUDIO_RECORD == play_rec)
	{
#ifdef Cache_enable
		dstArray = (Uint8 *)malloc(size+32);
		rxBuf = (Uint8*)((Uint32)(dstArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
		rxBuf = (Uint8 *)malloc(size);
#endif
		if( NULL != rxBuf)
		{
			status = ST_Read(st_audio_driver[st_audio_instance], rxBuf, size);
		
			if (status != AUDIO_SUCCESS) 
			{
				printTerminalf("test_audio_driver_play_rec:: Record Failed\n");
			}

			else
			{
				printTerminalf("test_audio_driver_play_rec:: Record Success\n");
			}

			free(rxBuf);
		}
		else
		{
			printTerminalf("test_audio_driver_play_rec:: Rx Malloc Failed\n");
		}
	}

	else if (AUDIO_PLAY_REC == play_rec)
	{

#ifdef Cache_enable
		srcArray = (Uint8 *)malloc(size+32);
		txBuf = (Uint8*)((Uint32)(srcArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
		dstArray = (Uint8 *)malloc(size+32);
		rxBuf = (Uint8*)((Uint32)(dstArray + AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1) & ~(AUDIO_CACHE_LINE_SIZE_IN_BYTES - 1));
#else
		txBuf = (Uint8 *)malloc(size);
		
		rxBuf = (Uint8 *)malloc(size);
#endif
		if( NULL != txBuf)
		{
			status = ST_Write(st_audio_driver[st_audio_instance], txBuf, size);
		
			if (status != AUDIO_SUCCESS) 
			{
				printTerminalf("test_audio_driver_play_rec:: Playback Failed\n");
			}

			else
			{
				printTerminalf("test_audio_driver_play_rec:: Playback Success\n");
			}
			free(txBuf);
		}
		else
		{
			printTerminalf("test_audio_driver_play_rec:: Tx - TxRx Malloc Failed\n");
		}
		
		if( NULL != rxBuf)
		{
			status = ST_Read(st_audio_driver[st_audio_instance], rxBuf, size);
		
			if (status != AUDIO_SUCCESS) 
			{
				printTerminalf("test_audio_driver_play_rec:: Record Failed\n");
			}

			else
			{
				printTerminalf("test_audio_driver_play_rec:: Record Success\n");
			}
			free(rxBuf);
		}
		else
		{
			printTerminalf("test_audio_driver_play_rec:: Rx- TxRx Malloc Failed\n");	
		}
	}

	return (status);
}
