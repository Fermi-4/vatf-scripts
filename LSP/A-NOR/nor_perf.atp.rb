class Nor_perfTestPlan < TestPlan
 
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
          'custom'    => ['nor'],
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['lld']	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	},
	{
          'custom'    => ['nor'],
          'dsp'	      => ['static'],	# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
          'micro'     => ['default'],	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
          'microType' => ['rtt']	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
	},
	{
          'custom'    => ['nor'],
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
      'filesystem'   => ['jffs2'],
      'buffer_size'  => ['102400 262144 524288 1048576 5242880'],
      'file_size'    => ['10485760'], # Should use bigger value. Using small one for testing purposes
      'dev_node'     => ['/dev/mtdblock3'],
      'mount_point'  => ['/mount/nor'],
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
        'description'  => "#{params['dev_node']} Performance test for #{params['filesystem']} file system",
        'iter'         => 1,
        'bft'          => false,
        'basic'        => true,
        'ext'          => false,
        'reg'          => true,
        'auto'         => true,
        'bestFinal'    => true,
        'configID'     => '..\Config\lsp_generic.ini',
        'script'       => 'LSP\default_perf_fs_script.rb',
        'paramsChan'   => {
            'init_cmds'      => 'mount;'+
                                '[vars[0] \= @equipment["dut1"].response];'+
                                "[vars[1] \\= \"#{params['dev_node']} on #{params['mount_point']} type (\\\\w+) \"];"+
                                '[vars[2] \= Regexp.new(vars[1]).match(vars[0].to_s)];'+
                                '[(vars[2]\=\=nil) ? (vars[3]\="") : (vars[3]\= vars[2][1])];'+
                                "[return 0 if vars[3].to_s.strip \\=\\=  \"#{params['filesystem']}\".strip];"+
                                "[dut_timeout\\=180];flash_eraseall #{params['dev_node'].delete('block')};"+
                                "mount -t #{params['filesystem']} -o sync #{params['dev_node']} #{params['mount_point']};"+
                                'mount;'+
                                '[vars[0] \= @equipment["dut1"].response];'+
                                "[vars[1] \\= \"#{params['dev_node']} on #{params['mount_point']} type (\\\\w+) \"];"+
                                '[vars[2] \= Regexp.new(vars[1]).match(vars[0].to_s)];'+
                                '[(vars[2]\=\=nil) ? (vars[3]\="") : (vars[3]\= vars[2][1])];'+
                                "[return 0 if vars[3].to_s.strip \\=\\=  \"#{params['filesystem']}\".strip];"+
                                "umount #{params['mount_point']};"+
                                '[dut_timeout\=720];'+
                                "/usr/sbin/flash_eraseall -j #{params['dev_node'].sub('block','')};"+
                                '[dut_timeout\=30];'+
                                "mkdir -p #{params['mount_point']};"+
                                "mount -t #{params['filesystem']} -o sync #{params['dev_node']} #{params['mount_point']}`--(?i:wrong)|(?i:Error)|(?i:bad)|(?i:busy)`;"+
                                "mount`++#{params['dev_node']} on #{params['mount_point']} type #{params['filesystem']}`",
            #'ensure'         => "umount #{params['mount_point']}",
            'filesystem'     => "#{params['filesystem']}",
            'mount_point'    => "#{params['mount_point']}",
            'buffer_size'    => "#{params['buffer_size']}",
            'file_size'      => "#{params['file_size']}",
            'dev_node'       => "#{params['dev_node']}",
            'target_sources' => 'LSP\Common\psp_test_bench',
            },
        'paramsEquip'  => {},
        'paramsControl'=> {},
    }
  end
  # END_USR_CFG get_outputs
  
end
