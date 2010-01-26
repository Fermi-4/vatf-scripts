class Wdt_func_apiTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType']
    @sort_by = ['microType']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['default'],
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
    expect_string = "++(?i:booting)--(?i:Fail)"
    common_paramsChan = {
      'device_node' => '/dev/watchdog',
      'wdt_timeout' => 60,
      'target_sources' => 'LSP\st_parser'
    }
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\A-WDT\wdt_tests.rb',
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
        'description'  =>  "Verify Open(), UUT will reset after default timeout period.",
        'testcaseID'   => 'wdt_func_api_0001',
        'script'      => 'LSP\A-WDT\wdt_tests.rb',
        'paramsChan'  => common_paramsChan.merge({
          'wdt_alive_period'  => common_paramsChan['wdt_timeout'].to_i,
          'cmd'   => "[dut_timeout\\=#{common_paramsChan['wdt_timeout'].to_i+10}];st_parser WDT open #{common_paramsChan['device_node']} 2 1 exit exit`#{expect_string}`",
        }),
      },
      {
        'description'  =>  "Verify IOCTL: WDIOC_GETSUPPORT; WDT Features are logged on the console",
        'testcaseID'   => 'wdt_func_api_0004',
        'script'      => 'LSP\A-WDT\wdt_tests.rb',
        'paramsChan'  => common_paramsChan.merge({
          'wdt_alive_period'  => common_paramsChan['wdt_timeout'].to_i,
          'cmd'   => "[dut_timeout\\=#{common_paramsChan['wdt_timeout'].to_i+10}];st_parser WDT open #{common_paramsChan['device_node']} 2 1 WDT_Features exit exit`#{expect_string}`",
        }),
      },
      {
        'description'  =>  "Verify IOCTL: WDIOC_KEEPALIVE; System remains alive",
        'testcaseID'   => 'wdt_func_api_0005',
        'script'      => 'LSP\A-WDT\wdt_tests.rb',
        'paramsChan'  => common_paramsChan.merge({
          'wdt_alive_period'  => 2*common_paramsChan['wdt_timeout'].to_i-30,
          'cmd'   => "[dut_timeout\\=100];st_parser WDT open #{common_paramsChan['device_node']} 2 1 WDT_Alive 30 exit exit`#{expect_string}`",
        }),
      },        
      {
        # this test is not supported in 120_lsp
        'description'  =>  "Verify IOCTL: WDIOC_GETTIMEOUT; timeout values is logged. Should check the returned value.",
        'testcaseID'   => 'wdt_func_api_0006',
        'script'      => 'LSP\A-WDT\wdt_tests.rb',
        'paramsChan'  => common_paramsChan.merge({
          'wdt_alive_period'  => common_paramsChan['wdt_timeout'].to_i,
          'cmd'   => "[dut_timeout\\=#{common_paramsChan['wdt_timeout'].to_i+10}];st_parser WDT open #{common_paramsChan['device_node']} 2 1 Get_Timeout exit exit`#{expect_string}`",
        }),
      },
      {
        'description'  =>  "Verify Close() works; but, closing the driver should not disable WDT and H/W restart to be triggered after the  Default Timeout Value",
        'testcaseID'   => 'wdt_func_api_0012',
        'script'      => 'LSP\A-WDT\wdt_tests.rb',
        'paramsChan'  => common_paramsChan.merge({
          'wdt_alive_period'  => common_paramsChan['wdt_timeout'].to_i,
          'cmd'   => "[dut_timeout\\=#{common_paramsChan['wdt_timeout'].to_i+10}];st_parser WDT open #{common_paramsChan['device_node']} 2 1 close exit exit`#{expect_string}`",
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
end
