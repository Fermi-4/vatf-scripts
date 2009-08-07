class Eth_basic_func_apiTestPlan < TestPlan
 
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
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld', 'rtt', 'server'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
        'custom'    => ['default'],
        'os'        => ['linux'],
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
    common_paramsChan = {
      # 'ensure' => "",
    }
    
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\A-ETH\eth_basic.rb',
      'auto' => true,
    }
    
    tc = [
        {
            'description'  =>  "Verify the driver can ping itself",
            'testcaseID'   => 'eth_basic_func_api_0001',
            'paramsChan'  => common_paramsChan.merge({
             'cmd' => "[ping_self]",
            }),
        },
        {
            'description'  =>  "Verify the driver can ping the loopback address",
            'testcaseID'   => 'eth_basic_func_api_0002',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => 'ifconfig lo up ; ping -c 2 127.0.0.1`++(2 packets transmitted\\, 2 received)`',
              }),
        },
        {
            'description'  =>  "Verify the drivers loopback can be taken up and down",
            'testcaseID'   => 'eth_basic_func_api_0003',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "[dut_timeout\\=20] ; ifconfig lo up ; ping -c 2 127.0.0.1`++(2 packets transmitted\\, 2 received)` ; ifconfig lo down ; ping -c 2 127\.0\.0\.1`++(2 packets transmitted\\, 0 received)` ; ifconfig lo up",
              'ensure' => 'ifconfig lo up'
            }),
        },
        {
            'description'  =>  "Verify the driver supports promiscuous mode",
            'testcaseID'   => 'eth_basic_func_api_0004',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => 'ifconfig eth0 promisc ; ifconfig eth0`++(RUNNING PROMISC)` ; ifconfig eth0 -promisc ; ifconfig eth0`--(RUNNING PROMISC)`',
            }),
        },
        {
            'description'  =>  "Verify the driver supports multicast ",
            'testcaseID'   => 'eth_basic_func_api_0005',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => 'ifconfig eth0 allmulti ; ifconfig eth0`++(RUNNING ALLMULTI)` ; ifconfig eth0 -allmulti ; ifconfig eth0`--(RUNNING ALLMULTI)`',
            }),
        },
        {
            'description'  =>  "Verify all supported speeds are advertised using the ethtool command",
            'testcaseID'   => 'eth_basic_func_api_0006',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => 'ethtool eth0`++(10baseT/Half\s+10baseT/Full\s+100baseT/Half\s+100baseT/Full)`',
            }),
        },
    ]
    tc_new = []
    tc.each{|val|
      tc_new << common_vars.merge(val)
    }
    return tc_new
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
    {
    }
  end
  # END_USR_CFG get_outputs

end
