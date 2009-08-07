# This one is also for stress test plan. Just change 'test_loop'.
class Gpio_stressTestPlan < Gpio_func_irqTestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    super
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'target'    => ['210_lsp'],
        'platform'  => ['dm355'],
        'os'        => ['linux'],
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
      # ??? how to input different gpio_num for dm644x???
      'gpio_bank'   => [*(0..6)],   #[*(0..4)] for dm644x
      #'gpio_num'  => [*(0..103)], #[*(0..73)] for dm644x
      'gpio_num'  => [6, 7, 25, 26, 32, 54, 67, 81],  # dm355: for bank 6, no test pin is found in HW.
      #'gpio_num'  => [5, 6, 32, 38, 54],  # dm644x: for bank 1, no test pin is found in HW.
      'dir'       => [0, 1],
      'irq_trig_edge' => [0, 1],
                 
      'test_loop'     => [1000],
      'module_name'   => ['gpio_test.ko'],
      'is_test_irq'   => [1],
    }
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    super
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    super
  end
  # END_USR_CFG get_outputs


    
end #END_CLASS
