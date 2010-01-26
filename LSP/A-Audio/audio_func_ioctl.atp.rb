class Audio_func_ioctlTestPlan < TestPlan
 
  #  BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    

  # BEG_USR_CFG setup
  def setup()
    
  end
  # END_USR_CFG setup
 
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
 
  # BEG_USR_CFG get_params
  def get_params()
    {
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_file' => 'i2c_func_api.cmd'
      'target_sources'  => 'LSP\st_parser'
      #'ensure'  => ''
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\default_test_script.rb',
    }
    tc = [
      {
        'description'  =>  "Verify the function of Ioctl OSS_GETVERSION",
        'testcaseID'   => 'audio_func_ioctl_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_ver`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_GETBLKSIZE",
        'testcaseID'   => 'audio_func_gen_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_bufsize`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_GETCAPS",
        'testcaseID'   => 'audio_func_ioctl_0003',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_capab`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_SETFRAGMENT",
        'testcaseID'   => 'audio_func_ioctl_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_frag 1024`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_SYNC",
        'testcaseID'   => 'audio_func_ioctl_0005',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_sync`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_SETDUPLEX",
        'testcaseID'   => 'audio_func_ioctl_0006',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_duplex`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_POST",
        'testcaseID'   => 'audio_func_ioctl_0007',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_post`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl GETTRIGGER",
        'testcaseID'   => 'audio_func_ioctl_0008',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_trig`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_SETTRIGGER",
        'testcaseID'   => 'audio_func_ioctl_0009',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_trig 2`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_GETOPTR",
        'testcaseID'   => 'audio_func_ioctl_0010',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_dataplayed`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_GETIPTR",
        'testcaseID'   => 'audio_func_ioctl_0011',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_datarecorded`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_GETOSPACE",
        'testcaseID'   => 'audio_func_ioctl_0012',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_ofrag`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_GETISPACE",
        'testcaseID'   => 'audio_func_ioctl_0013',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_ifrag`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_NONBLOCK",
        'testcaseID'   => 'audio_func_ioctl_0014',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_nonblock`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_RESET",
        'testcaseID'   => 'audio_func_ioctl_0015',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_reset`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_GETFMTS",
        'testcaseID'   => 'audio_func_ioctl_0016',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_format`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_CHANNELS",
        'testcaseID'   => 'audio_func_ioctl_0017',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_chan 1`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_PCM_READ_CHANNELS",
        'testcaseID'   => 'audio_func_ioctl_0018',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_chan`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_SPEED",
        'testcaseID'   => 'audio_func_ioctl_0019',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_sr 44100`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_PCM_READ_RATE",
        'testcaseID'   => 'audio_func_ioctl_0020',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_sr`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SNDCTL_DSP_SETFMT",
        'testcaseID'   => 'audio_func_ioctl_0021',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_format 16`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_PCM_READ_BITS",
        'testcaseID'   => 'audio_func_ioctl_0022',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_bits`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_WRITE_VOLUME",
        'testcaseID'   => 'audio_func_ioctl_0023',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_mix_vol 60`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_VOLUME",
        'testcaseID'   => 'audio_func_ioctl_0024',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_mix_vol`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_WRITE_LINE",
        'testcaseID'   => 'audio_func_ioctl_0025',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_mix_linein 50`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_LINE",
        'testcaseID'   => 'audio_func_ioctl_0026',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_mix_linein`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_WRITE_MIC",
        'testcaseID'   => 'audio_func_ioctl_0027',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_mix_mic 70`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_MIC",
        'testcaseID'   => 'audio_func_ioctl_0028',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_mix_mic`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_WRITE_BASS",
        'testcaseID'   => 'audio_func_ioctl_0029',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_bass 40`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_BASS",
        'testcaseID'   => 'audio_func_ioctl_0030',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_bass`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_WRITE_TREBLE",
        'testcaseID'   => 'audio_func_ioctl_0031',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_treble 80`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_TREBLE",
        'testcaseID'   => 'audio_func_ioctl_0032',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_treble`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_WRITE_IGAIN",
        'testcaseID'   => 'audio_func_ioctl_0033',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_igain 30`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_IGAIN",
        'testcaseID'   => 'audio_func_ioctl_0034',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_igain`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_WRITE_OGAIN",
        'testcaseID'   => 'audio_func_ioctl_0035',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_ogain 40`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_OGAIN",
        'testcaseID'   => 'audio_func_ioctl_0036',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_ogain`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_PRIVATE1",
        'testcaseID'   => 'audio_func_ioctl_0037',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_MicBiasVolt 2`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_WRITE_RECSRC",
        'testcaseID'   => 'audio_func_ioctl_0038',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl set_recsrc 40h`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_RECSRC",
        'testcaseID'   => 'audio_func_ioctl_0039',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_recsrc`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_DEVMASK",
        'testcaseID'   => 'audio_func_ioctl_0040',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_devmask`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_CAPS",
        'testcaseID'   => 'audio_func_ioctl_0041',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_caps`++Success::--Failed::`' 
        }),
      },
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_STEREODEVS",
        'testcaseID'   => 'audio_func_ioctl_0042',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_stereodevs`++Success::--Failed::`' 
        }),
      }
=begin
      {
        'description'  =>  "Verify the Multi-Process functionalities of Audio Driver",
        'testcaseID'   => 'audio_func_multi_process_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 0 io `++Success::--Failed::`' 
        }),
      }
      {
        'description'  =>  "Verify the function of Ioctl SOUND_MIXER_READ_STEREODEVS",
        'testcaseID'   => 'audio_func_ioctl_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser audio open 2 1 ioctl get_stereodevs`++Success::--Failed::`' 
        }),
      }
=end
    ]
    # merge the common varaibles to the individule test cases and the value in individule test cases will overwrite the common ones.
    tc_new = []
    tc.each{|val|
      #val.merge!(common_vars)
      tc_new << common_vars.merge(val)
    }
    return tc_new
  end
  
  # END_USR_CFG get_manual
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
    }
  end
  # END_USR_CFG get_outputs
end
