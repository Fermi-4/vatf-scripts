class I2c_funcTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType', 'bus_speed']
    @sort_by = ['microType', 'bus_speed']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
		'custom'	=> ['default'],
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'slave_device'  => ['led', 'rtc', 'ir', 'aicxx', 'eeprom', 'mxp430'],
      'bus_speed'     => ['20', '100', '200', '400']    # in kHz
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_sources'  => 'LSP\st_parser',
      'ensure'  => ''
    }
    common_vars = {
      'configID'        => '..\Config\lsp_generic.ini', 
      'script'          => 'LSP\default_test_script.rb',
      'ext'             => false,
      'bestFinal'       => false,
      'basic'           => false,
      'bft'             => false,
      'reg'             => false,
      'auto'            => true,
      'paramsControl'   => {
      },
      'paramsEquip'     => {
      },

    }
    tc = [
      {
        'description'  => "Verify that the modules (static) are loaded.", 
        'testcaseID'   => 'i2c_basic_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'cat /proc/devices`++(?i:i2c)`'
        }),
      },
      {
        'description'  => "Verify that the interrupt and the interrupt service routines are registered correctly.",
        'testcaseID'   => 'i2c_basic_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'cat /proc/interrupts`++(?i:i2c)`'
        }),
      },
      {
        'description'  => "Verify that the memory regions are reserved.",
        'testcaseID'   => 'i2c_basic_0003',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'cat /proc/iomem`++(?i:i2c)`'
        }),
      },
      {
        'description'  =>  "Verify that the /dev entry is available for the module loaded.",
        'testcaseID'   => 'i2c_basic_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'ls /dev/i*`++(?i:i2c)`'
        }),
      },
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
      'paramsChan'     => {
        'slave_device'    => params['slave_device'],
        #'bootargs'    => get_bootargs(params['bus_speed']), 
        'cmd'             => get_cmd("#{params['slave_device']}"),
        'target_sources'  => 'LSP\st_parser',
        'ensure'  => ''
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'    => "Verify that the I2C Driver can write/read the desired number of bytes to/from Slave device: #{params['slave_device']} using IOCTL commands at speed #{params['bus_speed']}KHz.",

      #'testcaseID'      => "i2c_fun_000#{@current_id}",
      'testcaseID'      => "i2c_func_#{params['slave_device']}",
      'script'          => 'LSP\default_test_script.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private
  def get_cmd(slave_device)
  # 'slave_device'  => ['led', 'rtc', 'ir', 'aicxx'],
    pass_string = '(?i:done)'
    fail_string = '(?i:fail)|(?i:not\\s+found)'
    cmd = case slave_device
    when 'led' then "[dut_timeout\\=60];\./st_parser i2c update config 2 open ioctl 1 led exit exit`++#{pass_string}--(?i:fail)|(?i:not\\s+found)`"
    when 'ir' then "[dut_timeout\\=60];\./st_parser i2c update config 4 open ioctl 1 ir_a exit exit `++#{pass_string}--(?i:fail)|(?i:not\\s+found)`"
    when 'rtc' then "[dut_timeout\\=60];\./st_parser i2c update config 5 open ioctl 1 rtc_w 08 20 11 20 03 50 00 rtc_r exit exit`++#{pass_string}--(?i:fail)|(?i:not\\s+found)`"
    #cmd = './st_parser i2c update config 3 open ioctl 1 codec_oneshot 1 <codec_reg_num> <value> 2 1 codec_oneshot 0 <codec_reg_num> 1 1 1 exit exit' when 'aicxx'
    when 'aicxx' then "[dut_timeout\\=60];\./st_parser i2c update config 3 open ioctl 1 codec_oneshot 1 2 19 2 1 codec_oneshot 0 2 1 1 1 exit exit`++#{pass_string}--(?i:fail)|(?i:not\\s+found)`" 
    when 'eeprom' then "[dut_timeout\\=60];\./st_parser i2c update config 1 open ioctl 1 write exit exit `++#{pass_string}--(?i:fail)|(?i:not\\s+found)`;\./st_parser i2c update config 1 open ioctl 1 read exit exit `++#{pass_string}--(?i:fail)|(?i:not\\s+found)`"
    when 'mxp430' then "[dut_timeout\\=60];\./st_parser i2c update config 4 open ioctl 1 test_mxp430 exit exit`++(?i:done)--(?i:fail)|(?i:not\s+found)`"
    end
    return cmd
  end

  private
  def get_bootargs(bus_freq)
    rtn = 'console\=ttyS0\,115200n8 noinitrd ip\=dhcp root\=/dev/nfs rw nfsroot\=${nfs_root_path}\,nolock mem\=116M' + " i2c-davinci\.i2c_davinci_busFreq\\=#{bus_freq}"
    return rtn
  end
  
end
