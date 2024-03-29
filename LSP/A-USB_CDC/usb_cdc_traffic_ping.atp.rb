class Usb_cdc_traffic_pingTestPlan < TestPlan
 
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
          'micro'     => ['default'], 	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['lld']	      # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
		},
		{
          'dsp'	      => ['static'],  	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'], 	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['rtt'],	      # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
		},
=begin
	{
          'dsp'	      => ['static'],  	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['dma'],     	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['server']   	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	}
=end
     ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'window_size'					=> ['64 128 256 512 1024 1518 6144 8192 16384 32768 65500'], # window size in bytes
      'protocol'   					=> ['tcp'],
      'direction' 					=> ['client', 'server'],
      'packets_to_send'			=> ['10'], 						# number of times to ping, flood pings will do ten times this amount
      'interface' 					=> ['usb0'],  					# are we testing an ethernet or usb rndis/cdc interface
      'comm_mode' 					=> ['cdc','rndis'],
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
        'description'  => "USB traffic using the ping tool going from #{params['direction']} to #{params['direction'] == 'client' ? 'server' : 'client'} using: #{params['window_size']} byte packets",
        'iter'         => 1,
        'bft'          => false,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_iperf.ini',
        'script'       => 'LSP\A-USB_CDC\usb_cdc_traffic_ping.rb',
        'paramsChan'   => {
            'window_size'          	=> "#{params['window_size']}",
            'protocol'              => "#{params['protocol']}",
            'packets_to_send'    		=> "#{params['packets_to_send']}",
            'direction'             => "#{params['direction']}",
						'comm_mode'             => "#{params['comm_mode']}",
            },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs

  private
  def get_config(params)
    if params['comm_mode'] == 'cdc' then
			return '..\Config\lsp_iperf.ini'
		else
			return '..\Config\lsp_iperf_rndis.ini'
		end
	end
end