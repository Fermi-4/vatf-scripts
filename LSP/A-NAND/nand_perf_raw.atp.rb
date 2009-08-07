class Nand_perf_rawTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
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
          'custom'    => ['nand']
	},
	{
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['rtt'],	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
          'custom'    => ['nand']
	},
	{
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['server'],	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
          'custom'    => ['nand']
	}
     ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'buffer_size'  => ['102400 262144 524288 1048576 5242880'],
      'file_size'    => ['104857600'], # Should use bigger value. Using small one for testing purposes
      'dev_node'     => ['/dev/mtdblock3', '/dev/mtdblock4'],
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
        'description'  => "#{params['dev_node']} Performance raw read write test with #{params['microType']}",
        'iter'         => 1,
        'bft'          => false,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => 'LSP\default_perf_raw_script.rb',
        'paramsChan'   => {
            'buffer_size'    => "#{params['buffer_size']}",
            'file_size'      => "#{params['file_size']}",
            'dev_node'       => "#{params['dev_node']}", 
            'target_sources' => 'dsppsp-validation\psp_test_bench',
            },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
  
end
