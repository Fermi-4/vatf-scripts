class Keypad_func_dynTestPlan < TestPlan
#class Rtc_funcTestPlan < Rtc_func_premTestPlan 
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
    }
  end
  # END_USR_CFG get_params


  # BEG_USR_CFG get_manual
  def get_manual()
    insmod = "insmod dm365_keypad.ko;lsmod`++keypad`"
    rmmod = "rmmod dm365_keypad;lsmod`--keypad`"
    
    common_paramsChan = {
      'ensure'  => "",
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
        'description'  => "Verify insmod of module works fine.", 
        'testcaseID'   => 'keypad_func_0001',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod}",
        }),
      },
      {
        'description'  => "Verify rmmod of module works fine.", 
        'testcaseID'   => 'keypad_func_0002',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => "#{rmmod}",
        }),
      },
      {
        'description'  => "Verify multiple insmod and rmmod of module works fine.", 
        'testcaseID'   => 'keypad_func_0003',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insmod};#{rmmod};#{insmod};#{rmmod};#{insmod};#{rmmod}",
        }),
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
