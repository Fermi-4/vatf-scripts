class Usb_cdc_iperf_perfTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
  end
  # END__CLASS_INIT	
  
  # BEG_USR_CFG setup
  def setup()
      @group_by = ['microType','comm_mode']
      @sort_by = ['microType','comm_mode']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
      keys = [
	{
          'dsp'	      => ['static'],  	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],		# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['lld'],     	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	},
	{
          'dsp'	      => ['static'],  	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],		# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['rtt'],	      # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	},
=begin
	{
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['dma'],		# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['server']		# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	}
=end  
     ]
  end
  # END_USR_CFG get_keys
 
  # BEG_USR_CFG get_params
  def get_params()
    {
      'window_size' 	=> ['16 32 64 128 212'], 	# window size in kilobytes
      'protocol'   		=> ['tcp','udp','mlti'],
      'duration'    	=> ['60'], 								# change to 60 second duration, 5 second for testing purposes
      'interface' 		=> ['usb0'],  						#are we testing an ethernet or usb rndis/cdc interface
      'comm_mode' 		=> ['cdc','rndis'],
			'bw_size' 			=> ['1 2 5 10 15 20'], 		# default bandwidth size in megabits
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
        'description'  => "USB performance test using #{params['protocol']} for window sizes #{params['window_size']} Kilobits, run for #{params['duration']} seconds.",
        'iter'         => 1,
        'bft'          => false,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => get_config(params),
        'script'       => 'LSP\A-USB_CDC\usb_cdc_perf_iperf_script.rb',
        'paramsChan'   => {
            'window_size'     => "#{params['window_size']}",
            'protocol'        => "#{params['protocol']}",
            'duration'        => "#{params['duration']}",
            'interface'       => "#{params['interface']}",
						'comm_mode'       => "#{params['comm_mode']}",
						'bw_size'     	  => "#{params['bw_size']}",
            },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
 
  private
  def get_config(params)
#    if params['comm_mode'] == 'cdc' then
				return '..\Config\lsp_iperf.ini'
#		else
#				return '..\Config\lsp_iperf_rndis.ini'
#		end
  end
end
