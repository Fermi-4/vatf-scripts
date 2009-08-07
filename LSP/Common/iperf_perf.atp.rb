class Iperf_perfTestPlan < TestPlan
 
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
        'custom'    => ['default'],
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['lld']	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	},
	{
        'custom'    => ['default'],
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['rtt']	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	},
	{
        'custom'    => ['default'],
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['server']	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	}
     ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'window_size'  => ['16 32 64 128 212'], # window size in kilobytes
      'protocol'   => ['tcp', 'udp'],
      'duration'    => ['10'], # change to 60 second duration, 5 second for testing purposes
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
        'description'  => "Ethernet performance test using #{params['protocol']} for window sizes #{params['window_size']} Kilobits, run for #{params['duration']} seconds.",
        'iter'         => 1,
        'bft'          => false,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_iperf.ini',
        'script'       => 'LSP\default_perf_iperf_script.rb',
        'paramsChan'   => {
            #'init_cmds'      => "",
            #'ensure'         => "umount #{params['mount_point']}",
            'window_size'     => "#{params['window_size']}",
            'protocol'    => "#{params['protocol']}",
            'duration'    => "#{params['duration']}",
            'target_sources' => 'LSP\Common\iperf',
            },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
  
end
