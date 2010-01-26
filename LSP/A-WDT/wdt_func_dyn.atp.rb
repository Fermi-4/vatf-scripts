class Wdt_func_dynTestPlan < TestPlan
 
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
        'dsp'       => ['dynamic'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      #'wdt_timeout' => [1, 64, 128, 159] # for 24MHz, the max=178; for 27MHz, max=159
      'wdt_timeout' => [1, 60, 128, 600] # for 24MHz, the max=178; for 27MHz, max=159
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_manual
  def get_manual()
    expect_string = "++(?i:booting)--(?i:Fail)"
    common_paramsChan = {
      'device_node' => '/dev/watchdog',
      'wdt_timeout' => 60,
      'target_sources' => 'LSP\st_parser',
      'module_name'    => 'davinci_wdt.ko',
    }
    common_vars = {
      'configID'        => '..\Config\lsp_generic.ini', 
      'script'          => 'LSP\A-WDT\wdt_tests.rb',
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
        'description'  => "Verify that the module can be loaded dynamically. Verify that the module can be unloaded dynamically after it is loaded.", 
        'testcaseID'   => 'wdt_dyn_0001',
        'script'    => 'LSP\default_test_script.rb',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'   => "insmod #{common_paramsChan['module_name']}`--(?i:fail)`" +
                      ";sleep 2" +
                      ";lsmod`++wdt--(?i:fail)`" +
                      ";rmmod #{common_paramsChan['module_name']}`--(?i:fail)`;lsmod`--wdt`"
       }),
      },
=begin      
      {
        'description'  => "Verify that the module can be unloaded dynamically after it is loaded.", 
        'testcaseID'   => 'wdt_dyn_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'   => "insmod #{common_paramsChan['module_name']}`--(?i:fail)`"
        }),
      },
=end
      {
        'description'  => "Verify our driver is listed under /proc/misc entry.",
        'testcaseID'   => 'wdt_dyn_0002',
        'script'    => 'LSP\default_test_script.rb',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'     => "insmod #{common_paramsChan['module_name']}`--(?i:fail)`" +
                        ';cat /proc/misc`++watchdog`',
        }),
      },
      {
        'description'  => "Verify the Hardware reset is postponed to the next Timout duration when the WDT is pinged.",
        'testcaseID'   => 'wdt_func_0003',
        'script'      => 'LSP\A-WDT\wdt_tests.rb',
        'paramsChan'  => common_paramsChan.merge({
          'wdt_alive_period'  => 2*common_paramsChan['wdt_timeout'].to_i-30,
          'cmd'   => "insmod {module_name} heartbeat\\={wdt_timeout}`--(?i:fail)`" +
                      ";[dut_timeout\\=100]" +
                      ";st_parser WDT open #{common_paramsChan['device_node']} 2 1 WDT_Alive 30 exit`#{expect_string}`",
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
        'device_node' => '/dev/watchdog',
        'wdt_timeout' => params['wdt_timeout'],
        'target_sources' => 'LSP\st_parser',
        'module_name'    => 'davinci_wdt.ko',
        'wdt_alive_period'  => params['wdt_timeout'], # keep this one because it may be different from timeout in some tests.
        'cmd'   => "rmmod {module_name};insmod {module_name} heartbeat\\={wdt_timeout}`--(?i:fail)`" +
                  ";[dut_timeout\\=#{params['wdt_timeout'].to_i+10}]" +
                  ";st_parser WDT open {device_node} 2 1 Get_Timeout exit exit`++(?i:booting)--(?i:Fail)`",
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'    => "Verify device can be configured to WDT Timeout: #{params['wdt_timeout']} and Verify H/W restart occurs after the Set timeout duration: #{params['wdt_timeout']} if WDT is not pinged wihtin the Timeout period.",

      #'testcaseID'      => "wdt_fun_000#{@current_id}",
      'testcaseID'      => "wdt_dyn_timeout_#{params['wdt_timeout']}",
      'script'          => 'LSP\A-WDT\wdt_tests.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private
  def get_testcaseID
  end
  
end
