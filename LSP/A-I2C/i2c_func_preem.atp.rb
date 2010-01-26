class I2c_func_preemTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType', 'micro', 'dsp']
    @sort_by = ['microType', 'micro', 'dsp']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        # 'target'    => ['210_lsp'],
        # 'platform'  => ['dm355'],
        # 'os'        => ['linux'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
		'custom'	=> ['default'],
        'microType' => ['lld', 'rtt', 'server']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
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
      'target_sources'  => 'LSP\st_parser',
      'ensure'  => ''
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\default_test_script.rb',
      
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
        'description'  => "Verify that the I2C Driver can write/read the desired number of bytes to/from specified Slave device: MSP430-LED using IOCTL commands.", 
        'testcaseID'   => 'i2c_func_led',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => '[dut_timeout\=60];st_parser i2c update config 2 open ioctl 1 led exit exit`++(?i:done)--(?i:fail)|(?i:not\\s+found)`'
        }),
      },
=begin
      {
        'description'  => "Verify that the I2C Driver can write/read the desired number of bytes to/from specified Slave device: MSP430-RTC using IOCTL commands.", 
        'testcaseID'   => 'i2c_func_0002',
        'paramsChan'  => common_paramsChan.merge({
          'slave_device' => 'rtc'
        }),
      },
      {
        'description'  => "Verify that the I2C Driver can write/read the desired number of bytes to/from specified Slave device: MSP430-IR using IOCTL commands.", 
        'testcaseID'   => 'i2c_func_0003',
        'paramsChan'  => common_paramsChan.merge({
          'slave_device' => 'ir'
        }),
      },
      {
        'description'  => "Verify that the I2C Driver can write/read the desired number of bytes to/from specified Slave device: AICxx using IOCTL commands.", 
        'testcaseID'   => 'i2c_func_0004',
        'paramsChan'  => common_paramsChan.merge({
          'slave_device' => 'aicxx'
        }),
      },
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
        'testcaseID'   => 'i2c_api_ioctl_000#{id+1}',
        'paramsChan'  => {
          'target_file' => 'i2c_test.cmd'
        }
      }
    end
    return ioctl_a
  end
=end  
end
