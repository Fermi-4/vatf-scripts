class Spi_func_premTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
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
        'dsp'       => ['static'], # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'], # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld'] # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
     },
     {
        'custom'    => ['default'],
        'dsp'       => ['static'], # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'], # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['rtt'] # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
     },
     {
        'custom'    => ['default'],
        'dsp'       => ['static'], # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'], # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['server'] # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
     }
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
    test_string3 = 'z'*8190 # fill up the whole memory. I did not put this one in paramChan since it is may too big for TC display. I do not need to modify it anyway.
    fd = File.open('C:\test_string.txt', "w+")
    fd.puts test_string3
    fd.close
    common_paramsChan = {
      #'target_sources'  => 'LSP\st_parser',
      'dev_node'  => '/dev/mtdblock5',
      'test_string1' => 'abc'*10, # generate some string here.
      'test_string2' => 'efgh'*10,
      'eeprom'       => 'spi_eeprom',
      #'test_string3' => 'z'*8190, # fill up whole eeprom
      'ensure'  => ''
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
        'description'  => "Verify that Write/Read test pass. ",
        'testcaseID'   => 'spi_func_0001',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd'   => "cat /proc/mtd`++{eeprom}`" +
                    ";echo {test_string1} > {dev_node};strings {dev_node}`++{test_string1}`" +
                    ";echo {test_string2} > {dev_node};strings {dev_node}`++{test_string2}`" +
                    ";strings {dev_node} > spi_test.txt",
                    #";cat test_string.txt > {dev_node};cat {dev_node}`++#{test_string3}`",
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
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

end
