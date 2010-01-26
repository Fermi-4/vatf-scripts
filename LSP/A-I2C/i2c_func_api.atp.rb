class I2c_func_apiTestPlan < TestPlan
 
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
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_file' => 'i2c_func_api.cmd'
      'target_sources'  => 'LSP\st_parser',
      'ensure'  => ''
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\default_test_script.rb',
      'auto'        => true,
    }
    tc = [
      {
        'description'  =>  "Verify Open() with mode R/W",
        'testcaseID'   => 'i2c_func_api_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c update iomode 2 open exit exit`++(?i:Open Success)--(?i:fail)|(?i:not\\s+found)`' 
        }),
      },
      {
        'description'  =>  "Verify Open() with mode Write only",
        'testcaseID'   => 'i2c_func_api_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c update iomode 1 open exit exit`++(?i:Open Success)--(?i:fail)|(?i:not\\s+found)`' 
        }),
      },
      {
        'description'  =>  "Verify Open() with mode Read only",
        'testcaseID'   => 'i2c_func_api_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c update iomode 0 open exit exit`++(?i:Open Success)--(?i:fail)|(?i:not\\s+found)`' 
        }),
      },
      {
        'description'  =>  "Verify IOCTL: I2C_SLAVE",
        'testcaseID'   => 'i2c_func_api_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c open ioctl 1 exit exit`--(?i:fail)|(?i:not\\s+found)`'
        }),
      },
      {
        'description'  =>  "Verify IOCTL: I2C_TENBIT",
        'testcaseID'   => 'i2c_func_api_0005',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c open ioctl 0 exit exit`--(?i:fail)|(?i:not\\s+found)`'
        }),
      },        
      {
        'description'  =>  "Verify IOCTL: I2C_TIMEOUT",
        'testcaseID'   => 'i2c_func_api_0006',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c open ioctl 2 exit exit`--(?i:fail)|(?i:not\\s+found)`'
        }),
      },
      {
        'description'  =>  "Verify IOCTL: I2C_FUNCS",
        'testcaseID'   => 'i2c_func_api_0007',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c open ioctl 3 exit exit`--(?i:fail)|(?i:not\\s+found)`'
        }),
      },
      {
        'description'  =>  "Verify IOCTL: I2C_RETRIES",
        'testcaseID'   => 'i2c_func_api_0008',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c open ioctl 4 exit exit`--(?i:fail)|(?i:not\\s+found)`'
        }),
      },       
      {
        'description'  =>  "Verify IOCTL: I2C_RDWR",
        'testcaseID'   => 'i2c_func_api_0009',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c open update config 3 ioctl 1 codec_oneshot exit exit`--(?i:fail)|(?i:not\\s+found)`'
        }),
      },
      {
        'description'  =>  "Verify Write() works",
        'testcaseID'   => 'i2c_func_api_0010',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => '[dut_timeout\=60];st_parser i2c open update config 2 ioctl 1 led exit exit`--(?i:fail)|(?i:not\\s+found)`'
        }),
      },
      {
        'description'  =>  "Verify Read() works",
        'testcaseID'   => 'i2c_func_api_0011',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => '[dut_timeout\=60];st_parser i2c open update config 2 ioctl 1 led exit exit`--(?i:fail)|(?i:not\\s+found)`'
        }),
      },
      {
        'description'  =>  "Verify Close() works",
        'testcaseID'   => 'i2c_func_api_0012',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'st_parser i2c open close exit exit`--(?i:fail)|(?i:not\\s+found)`'
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
