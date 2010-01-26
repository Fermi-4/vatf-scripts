class Video_disp_fbdev_basicTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    #@import_only = true
  end
  # END__CLASS_INIT    
  # BEG_USR_CFG setup
  def setup()
    #@group_by = ['frate']
    #@sort_by = ['frate']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['dma'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
        'platform' => ['dm355'],
        'target' => ['210_lsp'],
        'os' => ['linux'],
        'custom' => ['default']
      },
    ]
  end
  # END_USR_CFG get_keys
   # BEG_USR_CFG get_params
  def get_params()
    {
    #'frate'  => ['8', '16', '32', '44.1', '48', '96'], #in kbps
    #'fsize'     => ['16', '64', '256', '1024', '4096', '8192']    # in bytes
    }
  end
  # END_USR_CFG get_params
  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_file' => 'i2c_func_api.cmd'
      'target_sources'  => 'LSP\A-Video\video'
      #'ensure'  => ''
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\A-Video\video_fbdev.rb',
      'auto' => true,
    }
    tc = [
      {
        'description'  =>  "Verify that an image can be displayed in VID0 plane. Also this test verifies that" +
                                      " the fbset command can be used to resize the VID0 window. Also Ioctls FBIOGET_FSCREENINFO," +
                                      " FBIOGET_VSCREENINFO,FBIOPAN_DISPLAY, FBIO_WAITFORSYNC. ",
        'testcaseID'   => 'video_disp_fbdev_basic_0001',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "fbset -fb /dev/fb/0 -xres 0;fbset -fb /dev/fb/2 -xres 0;fbset -fb /dev/fb/3 -xres 0;" +
                      "fbset -fb /dev/fb/1 -xres 360 -yres 240 -vxres 360 -vyres 736 -depth 16 -laced 1;" +
                      "mmapvid VID0 encode_ntsc.yuv 10" ,
        }),
      },
      {
        'description'  =>  "Verify that an image can be move using the ioctl FBIO_SETPOSX.(Contiue from video_disp_fbdev_basic_0001)",
        'testcaseID'   => 'video_disp_fbdev_basic_0002',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "setposx VID0 100" ,
        }),
      },
      {
        'description'  =>  "Verify that an image can be move using the ioctl FBIO_SETPOSY.(Contiue from video_disp_fbdev_basic_0001)",
        'testcaseID'   => 'video_disp_fbdev_basic_0003',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "setposy VID0 100" ,
        }),
      },
      {
        'description'  =>  "Verify that an image can be zoomed using the ioctl FBIO_SETZOOM.(Contiue from video_disp_fbdev_basic_0001)",
        'testcaseID'   => 'video_disp_fbdev_basic_0004',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "setzoom VID0 2 2" ,
        }),
      },
      {
        'description'  =>  "Verify that OSD0 can be set to RGB and a RGB image can be displayed",
        'testcaseID'   => 'video_disp_fbdev_basic_0005',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "fbset -fb /dev/fb/0 -xres 360 -yres 240 -vxres 360 -vyres 480 -depth 16 -laced 1;" +
                      "rgbwrite OSD0",
        }),
      },
      {
        'description'  =>  "Verify that OSD1 can be set to attribute mode",
        'testcaseID'   => 'video_disp_fbdev_basic_0006',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "fbset -fb /dev/fb/2 -xres 360 -yres 240 -vxres 360 -vyres 480 -depth 8 -nonstd 1 -laced 1",
        }),
      },
      {
        'description'  =>  "Verify that OSD1 in attribute mode can set the blend to 1",
        'testcaseID'   => 'video_disp_fbdev_basic_0007',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "blend 1",
        }),
      },
      {
        'description'  =>  "Verify that OSD1 in attribute mode can set the blend to 2",
        'testcaseID'   => 'video_disp_fbdev_basic_0008',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "blend 2",
        }),
      },
      {
        'description'  =>  "Verify that OSD1 in attribute mode can set the blend to 3",
        'testcaseID'   => 'video_disp_fbdev_basic_0009',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "blend 3",
        }),
      },
      {
        'description'  =>  "Verify that OSD1 in attribute mode can set the blend to 4",
        'testcaseID'   => 'video_disp_fbdev_basic_0010',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "blend 4",
        }),
      },
      {
        'description'  =>  "Verify that OSD1 in attribute mode can set the blend to 5",
        'testcaseID'   => 'video_disp_fbdev_basic_0011',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "blend 5",
        }),
      },
      {
        'description'  =>  "Verify that OSD1 in attribute mode can set the blend to 6",
        'testcaseID'   => 'video_disp_fbdev_basic_0012',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "blend 6",
        }),
      },
      {
        'description'  =>  "Verify that OSD1 in attribute mode can set the blend to 7",
        'testcaseID'   => 'video_disp_fbdev_basic_0013',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "blend 7",
        }),
      },
      {
        'description'  =>  "Verify that an image cannot be moved using the ioctl FBIO_SETPOSX with invalid value.(Contiue from video_disp_fbdev_basic_0001)",
        'testcaseID'   => 'video_disp_fbdev_basic_00014',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "setposx VID0 1000",#`++Sucess\\s+Negative\\s+Test\\s+Passed--Failed\\s+Negative\\s+Test\\s+Failed`" ,
        }),
      },
      {
        'description'  =>  "Verify that an image cannot be moved using the ioctl FBIO_SETPOSY with invalid value.(Contiue from video_disp_fbdev_basic_0001)",
        'testcaseID'   => 'video_disp_fbdev_basic_00015',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "setposy VID0 1000`",#++Sucess\\s+Negative\\s+Test\\s+Passed--Failed\\s+Negative\\s+Test\\s+Failed`" ,
        }),
      },
      {
        'description'  =>  "Verify that OSD1 in attribute mode cannot set the blend to invalid value",
        'testcaseID'   => 'video_disp_fbdev_basic_0016',
        'paramsChan'  => common_paramsChan.merge({
        'cmd' => "blend 8",#`++Sucess\\s+Negative\\s+Test\\s+Passed--Failed\\s+Negative\\s+Test\\s+Failed`",
        }),
      }
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
=begin
      'paramsChan'     => {
        'frate'    => params['frate'],
        'fsize'    => params['fsize'],
        #'bootargs_ext'    => "i2c-davinci\.i2c_davinci_busFreq\\=#{params['bus_speed']}",
        #'cmd'             => "audiolb -s #{params['frate']} -f #{params['fsize']} -b",
        #'target_sources'  => 'LSP\A-Audio\audiolb'
        #'ensure'  => ''
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'    => "Verify that the Audio OSS driver can operate as expected in #{params['frate']} kbps and fragment size of #{params['fsize']} Bytes.",
      'testcaseID'      => "audio_func_000#{@current_id}",
      #'testcaseID'      => "i2c_func_#{params['microtype']}",
      'script'          => 'LSP\A-Audio\audio.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
=end
    }
  end
  # END_USR_CFG get_outputs
=begin
  private
  ioctls = ['I2C_SLAVE', 'I2C_TENBIT']
  def get_ioctl_tc()
    ioctl_a = []
    id = 0
    ioctls.each do |ioctl| 
      ioctl_a <<
      {
        'description'  =>  "Verify IOCTL: #{ioctl}",
        'testcaseID'   => 'i2c_func_api_ioctl_000#{id+1}',
        'paramsChan'  => {
          'target_file' => 'i2c_test.cmd'
        }
      }
    end
    return ioctl_a
  end
=end  
end
