require '../../TestPlans/LSP/A-ATA/ata_common'
class Ata_stressTestPlan < Ata_func_premTestPlan
  include Ata_common
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['device_type', 'lba_mode', 'test_type', 'op_mode']
    @sort_by = ['device_type', 'lba_mode', 'test_type', 'op_mode']
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

  # BEG_USR_CFG get_manual
  def get_manual()
    common_paramsChan = {
      #'target_sources'  => 'LSP\A-EDMA\edma_test',
      #'ensure'  => "rmmod {module_name}`--(?i:fail|error)`",
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
        'description'  => "Verify the creation of the file onto the media when the device is 100% full.", 
        'testcaseID'   => 'ata_stress_man_0001',
        'paramsChan'  => common_paramsChan.merge({
        }),
        'auto'  => false,
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
  
  # BEG_USR_CFG get_params
  def get_params()
    super().merge('test_duration'=>[24])
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    super()
  end
  # END_USR_CFG get_constraints
  
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    this_outputs = 
    {   
      'paramsChan'  => super(params)['paramsChan'].merge('test_duration'=>params['test_duration']),
      'description' => "Stress Test: Verify that the media driver can handle repeated File Creation, Deletion and I/O of #{params['file_size']} sized Files for operation mode #{params['op_mode']} for #{params['test_duration']} hrs.",
    }
    super(params).merge(this_outputs)

    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

end #END_CLASS
