class Rtc_func_premTestPlan < TestPlan
#class Rtc_func_premTestPlan < Rtc_funcTestPlan 
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
    fail_string = "Cannot|fault|error|Invalid"
    common_paramsChan = {
      'ensure'  => "hwclock --set --date \"09/18/2008 12:30:00\"`--(#{fail_string})`",
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
        'description'  => "Verify the device node is created.", 
        'testcaseID'   => 'rtc_func_0001',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "ls /dev/rtc`++/dev/rtc`",
        }),
      },
      {
        'description'  => "Verify that clock can be set and read correctly.", 
        'testcaseID'   => 'rtc_func_0002',
        'paramsChan'  => common_paramsChan.merge({  
          #'is_set_time' => 1,
          'cmd' => "hwclock --set --date \"7/31/2008 05:40:00\"`--(#{fail_string})`;hwclock`++Jul 31 05:40:\\d+ 2008`",
        }),
      },     
      {
        'description'  => "Verify the alarm can be set correctly. ",
        'testcaseID'   => 'timer_func_0004',
        'paramsChan'  => common_paramsChan.merge({ 
          'is_set_time' => 1,
          'test_loop' => 3,
        }),
      },
      {
        'description'  => "Verify the alarm can be read correctly. ",
        'testcaseID'   => 'timer_func_0005',
        'paramsChan'  => common_paramsChan.merge({ 
        }),
        'auto'        => false,
      },
      {
        'description'  => "Verify the system Time and RTC Tests are in sync . ",
        'testcaseID'   => 'timer_func_0006',
        'paramsChan'  => common_paramsChan.merge({ 
        }),
        'auto'        => false,
      },
    ]
    # merge the common varaibles to the individule test cases and the value in individule test cases will overwrite the common ones.
    tc_new = []
    tc.each{|val|
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
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

end
