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

/** \file   ST_Audio.h
    \brief  DaVinci ARM Linux PSP System Audio Tests Header

    (C) Copyright 2005, Texas Instruments, Inc

    @author     Aniruddha Herekar
    @version    0.1 - Created -  Linux Audio Test Code Header file 
                
 **/ 
#ifndef __ST_Audio__H
#define __ST_Audio__H

#include "st_common.h"
#include "st_automation_io.h"
#include "st_linuxdev.h"
#include <linux/soundcard.h>
#include <sys/stat.h>

#define SOUND_MIXER_MICBIAS	99


#define PSP_AUDIO_NUM_INSTANCES 1
#define PSP_MIXER_NUM_INSTANCES 1

#define INSTANCE		"/dev/dsp"
#define MIX_INSTANCE	"/dev/mixer"

#define AUDIORDWR	O_RDWR							/* Read and Write */
#define AUDIOMODE	AUDIORDWR

#define MIN_RD_CHAR		1

#define AUDIO_SUCCESS 	0
#define AUDIO_FAILURE 	1

#define AUDIO_NULL 		0
#define AUDIO_FAIL 		-1


#define txbuflen 1000000
#define rxbuflen 1000000
#define AUDIO_CACHE_LINE_SIZE_IN_BYTES	32 /* cache line size in bytes */
#define AUDIO_STRESS_LOOP 				10000


#define AUDIO_PLAY		0
#define AUDIO_RECORD	1
#define AUDIO_PLAY_REC	2



/***************************************************************************
 * Function			- audio_parser
 * Functionality	- Entry for audio tests.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void audio_parser(void);


/***************************************************************************
 * Function			- audio_io_parser
 * Functionality	- Entry for audio IO tests.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void audio_io_parser(void);


/***************************************************************************
 * Function			- audio_ioctl_parser
 * Functionality	- Entry for audio IOCtl tests.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void audio_ioctl_parser(void);


/***************************************************************************
 * Function			- test_audio_driver_update
 * Functionality	- Entry for updation.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_update(void);


/***************************************************************************
 * Function			- test_audio_update_driver_instance
 * Functionality	- To update the audio instance.
 * Input Params		- None
 * Return Value		- None
 * Note				- It supports only one instance.
 ***************************************************************************
 */

void test_audio_update_driver_instance(void);






/***************************************************************************
 * Function			- test_audio_driver_general_open
 * Functionality	- To open the device.
 * Input Params		- None
 * Return Value		- None
 * Note				- Asks for device name
 ***************************************************************************
 */

void test_audio_driver_general_open(void);


/***************************************************************************
 * Function			- test_audio_driver_open
 * Functionality	- To open the audio device.
 * Input Params		- None
 * Return Value		- None
 * Note				- Doesn't asks for device name
 ***************************************************************************
 */

void test_audio_driver_open(void);


/***************************************************************************
 * Function			- test_audio_driver_open_mixer
 * Functionality	- To open the mixer device.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_open_mixer(void);



/***************************************************************************
 * Function			- test_audio_driver_close
 * Functionality	- To close the audio device.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_close(void);


/***************************************************************************
 * Function			- test_audio_driver_close_mixer
 * Functionality	- To close the mixer device.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_close_mixer(void);


/***************************************************************************
 * Function         - test_audio_driver_poll
 * Functionality    - To call poll API.
 * Input Params     - None
 * Return Value     - None
 * Note             - None
 ***************************************************************************
 */

void test_audio_driver_poll(void);





/***************************************************************************
 * Function			- test_audio_driver_get_version
 * Functionality	- To get the version of the audio driver.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_version(void);


/***************************************************************************
 * Function			- test_audio_driver_get_bufsize
 * Functionality	- To get the size of a buffer.
 * Input Params		- None
 * Return Value		- None
 * Note				- Default size is 8K in driver.
 ***************************************************************************
 */

void test_audio_driver_get_bufsize(void);


/***************************************************************************
 * Function			- test_audio_driver_get_capabilities
 * Functionality	- To get the capabilities of the audio driver.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_capabilities(void);


/***************************************************************************
 * Function			- test_audio_driver_set_fragment
 * Functionality	- To set the fragment size for the buffer.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_fragment(void);


/***************************************************************************
 * Function			- test_audio_driver_get_trigger
 * Functionality	- To get the trigger value.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_trigger(void);


/***************************************************************************
 * Function			- test_audio_driver_set_trigger
 * Functionality	- To trigger playback/recording with precise timing.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_trigger(void);


/***************************************************************************
 * Function			- test_audio_driver_get_dataplayed
 * Functionality	- To get number of data played.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_dataplayed(void);


/***************************************************************************
 * Function			- test_audio_driver_get_datarecorded
 * Functionality	- To get number of data recorded.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_datarecorded(void);


/***************************************************************************
 * Function			- test_audio_driver_get_ofragbuf
 * Functionality	- To get output fragment buffer size.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_ofragbuf(void);


/***************************************************************************
 * Function			- test_audio_driver_get_ifragbuf
 * Functionality	- To get input fragment buffer size.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_ifragbuf(void);


/***************************************************************************
 * Function			- test_audio_driver_set_nonblock
 * Functionality	- To set the calls as non-blocking.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_nonblock(void);


/***************************************************************************
 * Function			- test_audio_driver_set_format
 * Functionality	- To set audio format.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_format(void);


/***************************************************************************
 * Function			- test_audio_driver_set_channnels
 * Functionality	- To set the number of audio channels.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_channnels(void);


/***************************************************************************
 * Function			- test_audio_driver_set_sampling_rate
 * Functionality	- To set the sampling rate.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_sampling_rate(void);


/***************************************************************************
 * Function			- test_audio_driver_set_dsp_sync
 * Functionality	- To set wait till last byte is played.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_dsp_sync(void);



/***************************************************************************
 * Function			- test_audio_driver_set_pcm_sync
 * Functionality	- To set wait till last byte is played.
 * Input Params		- None
 * Return Value		- None
 * Note				- PCM command used
 ***************************************************************************
 */

void test_audio_driver_set_pcm_sync(void);


/***************************************************************************
 * Function			- test_audio_driver_set_reset
 * Functionality	- To reset the audio device.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_reset(void);


/***************************************************************************
 * Function			- test_audio_driver_set_post
 * Functionality	- To tell the driver that output will likely have pauses.
 * Input Params		- None
 * Return Value		- None
 * Note				- Not implemented.
 ***************************************************************************
 */

void test_audio_driver_set_post(void);


/***************************************************************************
 * Function			- test_audio_driver_get_sr
 * Functionality	- To get the audio sampling rate.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_sr(void);\



/***************************************************************************
 * Function			- test_audio_driver_get_format
 * Functionality	- To get the audio format.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_format(void);



/***************************************************************************
 * Function			- test_audio_driver_get_rate
 * Functionality	- To get the audio sampling rate.
 * Input Params		- None
 * Return Value		- None
 * Note				- PCM command is used
 ***************************************************************************
 */

void test_audio_driver_get_rate(void);



/***************************************************************************
 * Function			- test_audio_driver_get_channels
 * Functionality	- To get the audio channels.
 * Input Params		- None
 * Return Value		- None
 * Note				- PCM command is used
 ***************************************************************************
 */

void test_audio_driver_get_channels(void);



/***************************************************************************
 * Function			- test_audio_driver_get_bits
 * Functionality	- To get the audio bits.
 * Input Params		- None
 * Return Value		- None
 * Note				- PCM command is used
 ***************************************************************************
 */

void test_audio_driver_get_bits(void);





/***************************************************************************
 * Function			- test_audio_driver_set_duplex
 * Functionality	- To set the audio for full duplex.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_duplex(void);






/***************************************************************************
 * Function			- test_audio_driver_set_mix_vol
 * Functionality	- To set the audio volume level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_mix_vol(void);


/***************************************************************************
 * Function			- test_audio_driver_set_mix_linein_vol
 * Functionality	- To set the audio line-in volume level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_mix_linein_vol(void);


/***************************************************************************
 * Function			- test_audio_driver_set_mix_mic_vol
 * Functionality	- To set the audio mic volume level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_mix_mic_vol(void);


/***************************************************************************
 * Function			- test_audio_driver_get_mix_volume
 * Functionality	- To get the audio volume level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_vol(void);


/***************************************************************************
 * Function			- test_audio_driver_get_mix_linein_vol
 * Functionality	- To get the audio line-in volume level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_linein_vol(void);


/***************************************************************************
 * Function			- test_audio_driver_get_mix_mic_vol
 * Functionality	- To get the audio mic volume level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_mic_vol(void);






/***************************************************************************
 * Function			- test_audio_driver_set_mix_bass
 * Functionality	- To set the audio mixer bass level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_mix_bass(void);



/***************************************************************************
 * Function			- test_audio_driver_set_mix_treble
 * Functionality	- To set the audio treble level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_mix_treble(void);


/***************************************************************************
 * Function			- test_audio_driver_get_mix_bass
 * Functionality	- To get the audio mixer bass level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_bass(void);



/***************************************************************************
 * Function			- test_audio_driver_get_mix_treble
 * Functionality	- To get the audio treble level.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_treble(void);









/***************************************************************************
 * Function			- test_audio_driver_set_mix_recsrc
 * Functionality	- To set the active recording source.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_set_mix_recsrc(void);




/***************************************************************************
 * Function			- test_audio_driver_get_mix_recsrc
 * Functionality	- To get the currently active recording source.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_recsrc(void);






/***************************************************************************
 * Function			- test_audio_driver_get_mix_recmask
 * Functionality	- To set the audio supported recording channels.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_recmask(void);



/***************************************************************************
 * Function			- test_audio_driver_get_mix_devmask
 * Functionality	- To get the supported mixer channels.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_devmask(void);



/***************************************************************************
 * Function			- test_audio_driver_get_mix_caps
 * Functionality	- To get the mixer capabilities.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_caps(void);



/***************************************************************************
 * Function			- test_audio_driver_get_mix_stereodevs
 * Functionality	- To get the audio mixer channels supporting stereo.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_get_mix_stereodevs(void);







/***************************************************************************
 * Function			- test_audio_driver_set_get_vol
 * Functionality	- To set and get the mixer channel volume.
 * Input Params		- None
 * Return Value		- None
 * Note				- Supported channels - speaker, line-in and mic
 ***************************************************************************
 */

void test_audio_driver_set_get_vol(void);




/***************************************************************************
 * Function			- test_audio_driver_set_mic_bias_volt
 * Functionality	- To set and get the mixer channel volume.
 * Input Params		- None
 * Return Value		- None
 * Note				- Supported channels - speaker, line-in and mic
 ***************************************************************************
 */

void test_audio_driver_set_mic_bias_volt(void);








/***************************************************************************
 * Function			- test_audio_driver_mic_recplay
 * Functionality	- To record through MIC and play the audio data.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_mic_recplay(void);



/***************************************************************************
 * Function         - test_audio_driver_set_igain
 * Functionality    - To set the input gain.
 * Input Params     - None
 * Return Value     - None
 * Note             - None
 ***************************************************************************
 */

void test_audio_driver_set_igain(void);


/***************************************************************************
 * Function         - test_audio_driver_set_ogain
 * Functionality    - To set the output gain.
 * Input Params     - None
 * Return Value     - None
 * Note             - None
 ***************************************************************************
 */

void test_audio_driver_set_ogain(void);
     


/***************************************************************************
 * Function			- test_audio_driver_line_in_recplay
 * Functionality	- To record through Line-in and play the audio data.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_line_in_recplay(void);



/***************************************************************************
 * Function			- test_audio_driver_record
 * Functionality	- To record the audio data.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_record(void);


/***************************************************************************
 * Function			- test_audio_driver_playback
 * Functionality	- To play the audio data synchronously.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_playback(void);


/***************************************************************************
 * Function			- test_audio_driver_playback_async
 * Functionality	- To play the audio data asynchronously.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_playback_async(void);


/***************************************************************************
 * Function			- test_audio_driver_record_sync_and_playback_sync
 * Functionality	- To record and play the audio data synchronously.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_record_sync_and_playback_sync(void);


/***************************************************************************
 * Function			- test_audio_driver_record_async_and_playback_async
 * Functionality	- To record and play the audio data asynchronously.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_record_async_and_playback_async(void);


/***************************************************************************
 * Function			- test_audio_driver_sync_stress
 * Functionality	- To perform synchronous stress for audio data.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_sync_stress(void);


/***************************************************************************
 * Function			- test_audio_driver_len_in_sync_stress
 * Functionality	- To perform synchronous stress for audio data, 
 * 					- takes size as input.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_len_in_sync_stress(void);


/***************************************************************************
 * Function			- test_audio_driver_async_stress
 * Functionality	- To perform asynchronous stress for audio data.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_async_stress(void);


/***************************************************************************
 * Function			- test_audio_driver_len_in_async_stress
 * Functionality	- To perform asynchronous stress for audio data, 
 * 					- takes size as input.
 * Input Params		- None
 * Return Value		- None
 * Note				- None
 ***************************************************************************
 */

void test_audio_driver_len_in_async_stress(void);


/***************************************************************************
 * Function		- test_audio_driver_stability
 * Functionality	- To perform stability tests for audio data.
 * Input Params		- None
 * Return Value		- None
 * Note			- None
 ***************************************************************************
 */

void test_audio_driver_stability(void);



/***************************************************************************
 * Function		- test_audio_driver_sync_performance
 * Functionality	- To perform synchronous performance tests for audio data.
 * Input Params		- None
 * Return Value		- None
 * Note			- None
 ***************************************************************************
 */

void test_audio_driver_sync_performance(void);


/***************************************************************************
 * Function		- test_audio_driver_async_performance
 * Functionality	- To perform asynchronous performance tests for audio data.
 * Input Params		- None
 * Return Value		- None
 * Note			- None
 ***************************************************************************
 */

void test_audio_driver_async_performance(void);



/***************************************************************************
 * Function             - test_audio_driver_perf_play
 * Functionality        - To perform performance playback tests for audio data.
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ***************************************************************************
 */
void test_audio_driver_perf_play(void);


/***************************************************************************
 * Function             - test_audio_driver_perf_record
 * Functionality        - To perform performance record tests for audio data.
 * Input Params         - None
 * Return Value         - None
 * Note                 - None
 ***************************************************************************
 */
void test_audio_driver_perf_record(void);




/***************************************************************************
 * Function		- test_audio_driver_NULL_Instance
 * Functionality	- To perform playback and record with invalid instance.
 * Input Params		- None
 * Return Value		- None
 * Note			- None
 ***************************************************************************
 */

void test_audio_driver_NULL_Instance(void);


/***************************************************************************
 * Function		- ST_Audio_MultiProcess_parser
 * Functionality	- To perform multi-process tests for audio data.
 * Input Params		- None
 * Return Value		- None
 * Note			- None
 ***************************************************************************
 */

void ST_Audio_MultiProcess_parser(void);


/***************************************************************************
 * Function		- ST_Audio_MultiThread_parser
 * Functionality	- To perform multi-threading tests for audio data.
 * Input Params		- None
 * Return Value		- None
 * Note			- None
 ***************************************************************************
 */

void ST_Audio_MultiThread_parser(void);


/*
 ***************************************************************************
 */




/* Internal Functions - Can be used outside if required */

/***************************************************************************
 * Function		- test_audio_driver_play_rec
 * Functionality	- To perform playback/record/both tests for audio data.
 * Input Params		- Sampling Rate (sr), Data bits (datalen), 
 * 			- Number of bytes to transfer (size), Operation - play_rec
 * 			- ( AUDIO_PLAY/ AUDIO_RECORD/ AUDIO_PLAY_REC )
 * Return Value		- AUDIO_SUCCESS/ AUDIO_FAILURE
 * Note				- None
 ***************************************************************************
 */

Int8 test_audio_driver_play_rec(Uint32 sr, Uint8 datalen, Uint32 size, Uint8 play_rec);


/* Internal Functions - Can be used outside if required */

/***************************************************************************
 * Function		- ST_test_audio_long_playback
 * Functionality	- To perform long duration playback
 * Input Params		- Timout  (sr), Raw Audio Filename/Path
 * Return Value		- AUDIO_SUCCESS/ AUDIO_FAILURE
 * Note			- None
 ***************************************************************************
 */

void ST_test_audio_long_playback();

/* Internal Functions - Can be used outside if required */

/***************************************************************************
 * Function		- test_audio_driver_get_igain()
 * Functionality	- To perform get Input Gain Value
 * Input Params		- None
 * Return Value		- Gain Set Value
 * Note			- None
 ***************************************************************************
 */



void test_audio_driver_get_igain(void);

/* Internal Functions - Can be used outside if required */

/***************************************************************************
 * Function		- test_audio_driver_get_ogain()
 * Functionality	- To perform get Output Gain Value
 * Input Params		- None
 * Return Value		- Gain Set Value
 * Note			- None
 ***************************************************************************
 */

void test_audio_driver_get_ogain(void);


/* Internal Functions - Can be used outside if required */

/***************************************************************************
 * Function		- test_audio_driver_mix_info()
 * Functionality	- To get Mixer Information
 * Input Params		- mixer_info Struct Ptr
 * Return Value		- PASS/FAIL
 * Note			- None
 ***************************************************************************
 */
void test_audio_driver_mix_info(void);
#endif  
