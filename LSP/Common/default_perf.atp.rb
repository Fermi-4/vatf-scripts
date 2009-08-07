class Default_perfTestPlan < TestPlan
   # BEG_CLASS_INIT
  def initialize()
		@@is_config_step_required = false
    super
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
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['lld'],	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
          'custom'    => ['default']
	},
	{
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['rtt'],	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
          'custom'    => ['default']
	},
	{
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['server'],	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
          'custom'    => ['default']
	}
     ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'test_type'	  => []
    }
  end
  # END_USR_CFG get_params
  
   # BEG_USR_CFG get_constraints

  def get_constraints()
    [
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
        'description'  => "#{params['test_type']} Performance test",
        'testcaseID'   => "#{params['test_type']}_perf_" + "%04d" % "#{@current_id}",
        'iter'         => 1,
        'bft'          => true,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => '',
        'paramsChan'   => {},
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
  
end
