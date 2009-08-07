class Edma_funcTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['test_loop', 'chan_type', 'features', 'transfer_type', 'event_q']
    @sort_by = ['test_loop', 'chan_type', 'features', 'transfer_type', 'event_q']
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
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'transfer_type' => ['async', 'absync'],
      'addr_mode'     => ['fifo', 'incr (10)'],
      'chan_type'     => ['dma (10)', 'qdma'],
      'features'      => ['single (10)', 'linking+unlinking', 'chaining'],
      'test_switch'   => [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12],
      'data_size'     => [1, 256, 51200, 102400, 65536], # in bytes # in lsp210, possible to test larger size like 1M?
      'test_loop'     => ['1 (10)', '1000'],
      'event_q'       => [0, 1, 2, 3],
      'module_name'   => ['edma_test.ko'],
      'is_max_txfer'  => ['yes', 'no'], # if we test setting Ccnt or Bcnt*Ccnt to maximum number.
    }
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
      '{ transfer_type, addr_mode, chan_type, features, test_switch, data_size } @ 3',
      'IF [test_switch] in {11, 12} THEN [test_loop] = 1000 ELSE [test_loop] = 1;',
      'IF [test_switch] in {0} THEN [chan_type] = "dma" AND [transfer_type] = "absync" AND [addr_mode] = "incr" AND [features] = "single";',
      'IF [test_switch] in {1} THEN [chan_type] = "dma" AND [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "single";',
      'IF [test_switch] in {2} THEN [chan_type] = "dma" AND [transfer_type] = "absync" AND [addr_mode] = "fifo" AND [features] = "single";',
      'IF [test_switch] in {3} THEN [chan_type] = "dma" AND [transfer_type] = "async" AND [addr_mode] = "fifo" AND [features] = "single";',
      'IF [test_switch] in {4} THEN [chan_type] = "dma" AND [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "linking+unlinking";',
      'IF [test_switch] in {5} THEN [chan_type] = "dma" AND [transfer_type] = "absync" AND [addr_mode] = "incr" AND [features] = "linking+unlinking";',
      'IF [test_switch] in {6} THEN [chan_type] = "dma" AND [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "chaining";',
      'IF [test_switch] in {7} THEN [chan_type] = "dma" AND [transfer_type] = "absync" AND [addr_mode] = "incr" AND [features] = "chaining";',
      'IF [test_switch] in {8} THEN [chan_type] = "qdma" AND [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "linking+unlinking";',
      'IF [test_switch] in {10} THEN [chan_type] = "qdma" AND [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "single";',
      'IF [test_switch] in {11} THEN [chan_type] = "dma" AND [transfer_type] = "async" AND [addr_mode] = "incr" AND [features] = "single";',
      'IF [test_switch] in {12} THEN [chan_type] = "dma" AND [transfer_type] = "absync" AND [addr_mode] = "incr" AND [features] = "single";',
      'IF [data_size] in {65536} THEN [is_max_txfer] = "yes" ELSE [is_max_txfer] = "no";',
      'IF [data_size] in {65536} THEN [test_loop] = 1;',
    ]
  end
  # END_USR_CFG get_constraints
=begin
  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      'module_name'     => 'edma_test.ko',
      'target_sources'  => 'LSP\A-EDMA\edma_test',
      'ensure'  => "rmmod {module_name}`--(?i:fail|error)`",
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
        'description'  => "Verify Data Transfer with ASYNC+INCR as Addressing Mode With Maximum values of Acnt, BCnt, or CCnt", 
        'testcaseID'   => 'edma_func_max_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'   => "[dut_timeout\\=28800];insmod {module_name} Trnsfr_sw\\=1 ACnt\\=1 BCnt\\=1 CCnt\\=65535 test_loop\\=1}`--(?i:fail|error)`",
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
=end 
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
      'paramsChan'     => {
        'target_sources' => 'LSP\A-EDMA\edma_test',
        'module_name'    => params['module_name'],
        'test_loop'      => params['test_loop'],
        'event_q'        => params['event_q'],
        #insmod st_edma_test.ko Trnsfr_sw=4 ACnt1=12800 BCnt1=4 CCnt1=2 ACnt2=12800 BCnt2=2 CCnt2=4
        'cmd'   => "[dut_timeout\\=#{get_dut_timeout(params['test_loop'], params['is_max_txfer'])}];insmod #{params['module_name']} Trnsfr_sw\\=#{params['test_switch']} #{get_abc_cnt(params['test_switch'], params['data_size'])} test_loop\\=#{params['test_loop']} event_q\\={event_q}`--(?i:fail|error)`",
        'ensure'  => "rmmod #{params['module_name']}`--(?i:fail|error)`",
        'transfer_type' => params['transfer_type'],
        'addr_mode'     => params['addr_mode'],
        'chan_type'     => params['chan_type'],
        'features'      => params['features'],
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      #'description'    => "Verify for #{get_switch_desc(params['test_switch'])}, data with size #{params['data_size']} bytes transfer sucessfully",
      'description'    => get_desc("Verify for #{params['chan_type'].upcase} channel with #{params['transfer_type'].upcase}" +
                          " + #{params['addr_mode'].upcase} + #{params['features'].upcase}, data with size #{params['data_size']} bytes transfer sucessfully in #{params['microType']} mode", params['test_switch']),

      'testcaseID'      => "edma_func_#{@current_id}",
      'script'          => 'LSP\default_test_script.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private
  
  def get_dut_timeout(test_loop, is_max_txfer)
    if is_max_txfer == 'yes' then 
      return 28800 
    end
    rtn = case test_loop.to_i
      when 1..10: 30
      when 11..100: 300
      else          28800   # 8 hours
    end
    rtn
  end
  
  def get_desc(desc, switch)
    rtn = case switch
      when "11", "12": "Stress Test: " + desc
      else
        desc
    end
    rtn
  end
  
=begin
  def get_switch_desc(switch)
    rtn = case switch
      when '0': 'DMA channel with ABSYNC + INCR mode'
      when '1': 'DMA channel with ASYNC + INCR mode'
      when '2': 'DMA channel with ABSYNC + FIFO mode'
      when '3': 'DMA channel with ASYNC + FIFO mode'
      when '4': 'DMA channel with ASYNC + INCR mode + LINKING'
      when '5': 'DMA channel with ABSYNC + INCR mode + LINKING'
      when '6': 'DMA channel with ASYNC + INCR mode + CHAINING'
      when '11': 'Stress test, DMA channel with ASYNC + INCR mode'
      when '12': 'Stress test, DMA channel with ABSYNC + INCR mode'
    end
  end
=end
  #'data_size'     => [1, 256, 51200, 102400], # in bytes
  # may use 'features' instead of 'switch'.
  def get_abc_cnt(switch, data_size)
    rtn = case switch
      when '0', '1', '2', '3', '10', '11', '12': get_1abccnt(data_size)
      when '4', '5', '6', '7', '8': get_2abccnt(data_size)
    end
  end
  def get_1abccnt(data_size)
    rtn = case data_size
      when '1':     'ACnt\=1 BCnt\=1 CCnt\=1'
      when '256':   'ACnt\=32 BCnt\=4 CCnt\=2'
      when '51200': 'ACnt\=3200 BCnt\=4 CCnt\=4'
      when '65536': 'ACnt\=2 BCnt\=1 CCnt\=32767' # overnight testing
      #when '65536': 'ACnt\=8192 BCnt\=1 CCnt\=8' 
      when '102400':  'ACnt\=12800 BCnt\=2 CCnt\=4'
    end
  end
  def get_2abccnt(data_size)
    rtn = case data_size
      when '1':     'ACnt1\=1 BCnt1\=1 CCnt1\=1 ACnt2\=1 BCnt2\=1 CCnt2\=1'
      when '256':   'ACnt1\=32 BCnt1\=4 CCnt1\=2 ACnt2\=64 BCnt2\=2 CCnt2\=2'
      when '51200': 'ACnt1\=3200 BCnt1\=4 CCnt1\=4 ACnt2\=6400 BCnt2\=8 CCnt2\=1'
      when '65536': 'ACnt1\=2 BCnt1\=1 CCnt1\=32767 ACnt2\=1 BCnt2\=2 CCnt2\=32767' # overnight testing
      #when '65536': 'ACnt1\=16384 BCnt1\=1 CCnt1\=4 ACnt2\=16384 BCnt2\=1 CCnt2\=4' # overnight testing
      when '102400':  'ACnt1\=12800 BCnt1\=2 CCnt1\=4 ACnt2\=25600 BCnt2\=1 CCnt2\=4'
    end
  end
  
end #END_CLASS
