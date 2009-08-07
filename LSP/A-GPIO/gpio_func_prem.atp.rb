require '../../TestPlans/LSP/A-GPIO/gpio_common'
class Gpio_func_premTestPlan < TestPlan
  include Gpio_common
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['microType']
    @sort_by = ['microType']
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
        'microType' => ['lld', 'rtt', 'server']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      # for preemption test, only choose a few pins.
      # ??? how to input different gpio_num for dm644x???
      'gpio_bank'   => [*(0..6)],   #[*(0..4)] for dm644x
      #'gpio_num'  => [*(0..103)], #[*(0..73)] for dm644x
      'gpio_num'  => [6, 32, 54],  # dm355: for bank 6, no test pin is found in HW.
      #'gpio_num'  => [5, 6, 32, 38, 54],  # dm644x: for bank 1, no test pin is found in HW.
      'dir'       => [0],
      'irq_trig_edge' => [0, 1],
    }
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
      #'IF [platform] = "dm644x" THEN [gpio_bank] <= 4;',
      'IF [gpio_bank] = 0 THEN [gpio_num] <= 15;',
      'IF [gpio_bank] = 1 THEN [gpio_num] <= 31 AND [gpio_num] >= 16;',
      'IF [gpio_bank] = 2 THEN [gpio_num] <= 47 AND [gpio_num] >= 32;',
      'IF [gpio_bank] = 3 THEN [gpio_num] <= 63 AND [gpio_num] >= 48;',
      'IF [gpio_bank] = 4 THEN [gpio_num] <= 79 AND [gpio_num] >= 64;',
      'IF [gpio_bank] = 5 THEN [gpio_num] <= 95 AND [gpio_num] >= 80;',
      'IF [gpio_bank] = 6 THEN [gpio_num] <= 103 AND [gpio_num] >= 96;',
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
      'paramsChan'     => {
        'target_sources' => 'LSP\A-GPIO\gpio_test',
        'module_name'   => 'gpio_test.ko',
        'gpio_bank'     => params['gpio_bank'],
        'gpio_num'      => params['gpio_num'],
        'dir'           => params['dir'],
        'irq_trig_edge' => params['irq_trig_edge'],
        'irq_num'       => get_irq_num(params['gpio_num'], params['platform']),
        'is_test_irq'   => 1,
        'cmd'   => "rmmod {module_name};insmod {module_name} gpio_num\\=#{params['gpio_num']} dir\\=#{params['dir']}" +
                  " irq_num\\={irq_num} irq_trig_edge\\=#{params['irq_trig_edge']}" +
                  " test_loop\\=3 gpio_src\\=6 is_test_irq\\={is_test_irq}`--(?i:fail|error)`",
        'ensure'  => "lsmod`++gpio_test`;rmmod {module_name}",
      },
      
      'paramsControl'       => {
        'is_manual_check' => 0,
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'    => "Verify for GPIO #{params['gpio_num']}:" +
                          " Direction can be set to: #{get_dir(params['dir'])} and #{get_trig_edge(params['irq_trig_edge'])} can be Set/Clear." +
                          " Verify interrupt is raised when GPIO state is been changed.",

      'testcaseID'      => "gpio_fun_#{@current_id}",
      'script'          => 'LSP\default_test_script.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private
end #END_CLASS
