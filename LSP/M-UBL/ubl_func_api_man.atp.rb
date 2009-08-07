class Ubl_func_apiManTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    #@import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType', 'micro', 'dsp']
    @sort_by = ['microType', 'micro', 'dsp']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
    {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        #'micro'     => ['pio'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld', 'rt', 'server']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
        # DEBUG-- Remove these after debugging & uncomment above line
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
        'Platform' => ['dm355', 'dm6446', 'dm360'], # UBL supports DM644x/DM6467x/DM355/DM360 EVM's through CCS (SR-4.3.2.2)
        'os' => ['linux'],
        'target' => ['210_lsp'],        
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
    tc = [
        {
            'description'  =>  "Verify that UBL is available in source format and supoprts NAND boot loading",
            'testcaseID'   => 'flashwriter_func_api_man_0001',
            'criteria' => 'Source is available with NAND support',
        },
        {
            'description'  =>  "Power sequencing works properly",
            'testcaseID'   => 'flashwriter_func_api_man_0002',
            'criteria' => 'Enable power sequencing and verify it\'s functionality',
        },
        {
            'description'  =>  "ADC power control feature works properly",
            'testcaseID'   => 'flashwriter_func_api_man_0002',
            'criteria' => 'Verify ADC power control works properly',
        },
        {
            'description'  =>  "RTC mode support",
            'testcaseID'   => 'flashwriter_func_api_man_0002',
            'criteria' => 'Verify RTC mode is supported',
        },
    ]
    return tc
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
    {+
    }
  end
  # END_USR_CFG get_outputs

end
