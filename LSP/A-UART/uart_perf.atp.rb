class Uart_perfTestPlan < TestPlan
 
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
    common_paramsChan = {
  #    'target_sources'  => 'LSP\st_parser',
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
        'description'  =>  "Verify read performance is upto mark for 104856 bytes",
        'testcaseID'   => 'uart_perofrmance_read',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'psp_test_bench FnTest UART`++exit`;uart_read_perf_interrupt `++(?i:PASS Performance value is in acceptable range)--(?i:fail)`' 
        }),
      },
      {
        'description'  =>  "Verify write performance is upto mark for 104856 bytes",
        'testcaseID'   => 'uart_perofrmance_write',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => 'psp_test_bench FnTest UART`++exit`;uart_write_perf_interrupt `++(?i:PASS Performance value is in acceptable range)--(?i:fail)`' 
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
    }
  end
  # END_USR_CFG get_outputs
end
