class Uart_stabilityTestPlan < TestPlan
 
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
        'description'  =>  "Stability: Verify uart stability create open deleate close 1000 times ",
        'testcaseID'   => 'uart_stability',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => './psp_test_bench FnTest UART`++exit`;uart_stability_interrupt `++(?i:UART_CREATE_OPEN_DELETE_CLOSE_PASS)--(?i:fail)`' 
        }),
      },
      {
        'description'  =>  "Stress: Verify read data",
        'testcaseID'   => 'uart_func_write_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => './psp_test_bench FnTest UART`++exit`;uart_stress_read_interrupt `++(?i:UART_STRESS_READ_PASS)--(?i:fail)`' 
        }),
      },
      {
        'description'  =>  "Stress: Verify write data from 1-1048576 bytes",
        'testcaseID'   => 'uart_write_stress',
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => './psp_test_bench FnTest UART `++exit`;uart_stress_write_interrupt `++(?i:UART_STRESS_WRITE_PASS)--(?i:fail)`' 
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
