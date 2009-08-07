require '../../TestPlans/LSP/A-EDMA/edma_func.atp.rb'
class Edma_func_premTestPlan < Edma_funcTestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['microType', 'test_loop', 'chan_type', 'features', 'transfer_type']
    @sort_by = ['microType', 'test_loop', 'chan_type', 'features', 'transfer_type']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'target'    => ['210_lsp'],
        'platform'  => ['dm365'],
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
      'transfer_type' => ['async', 'absync'],
      'addr_mode'     => ['incr'],
      'chan_type'     => ['dma'],
      'features'      => ['single', 'linking+unlinking'],
      'test_switch'   => [0, 1, 4, 5],
      'data_size'     => [1, 102400], # in bytes
      'test_loop'     => ['1 (10)'],
      'module_name'   => ['edma_test.ko'],
      'is_max_txfer'  => ['no'],
      'event_q'       => [0, 1, 2, 3],
    }
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
      '{ transfer_type, addr_mode, chan_type, features, test_switch, data_size } @ 3',
      #'IF [test_switch] in {11, 12} THEN [test_loop] = 1000 ELSE [test_loop] = 1;',
      'IF [test_switch] in {0} THEN [transfer_type] = "absync" AND [addr_mode] = "incr" AND [features] = "single";',
      'IF [test_switch] in {1} THEN [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "single";',
      #'IF [test_switch] in {2} THEN [transfer_type] = "absync" AND [addr_mode] = "fifo" AND [features] = "single";',
      #'IF [test_switch] in {3} THEN [transfer_type] = "async" AND [addr_mode] = "fifo" AND [features] = "single";',
      'IF [test_switch] in {4} THEN [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "linking+unlinking";',
      'IF [test_switch] in {5} THEN [transfer_type] = "absync" AND [addr_mode] = "incr" AND [features] = "linking+unlinking";',
      #'IF [test_switch] in {6} THEN [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "chaining";',
      'IF [test_switch] in {11} THEN [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "single";',
      'IF [test_switch] in {12} THEN [transfer_type] = "absync" AND [addr_mode] = "incr" AND [features] = "single";',
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    super
  end
  # END_USR_CFG get_outputs

end #END_CLASS
