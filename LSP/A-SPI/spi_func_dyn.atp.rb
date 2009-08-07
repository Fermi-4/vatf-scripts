require '../../TestPlans/LSP/Common/atp_helper.rb'
class Spi_func_dynTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true # Bypass autogeneration and instead call get_manual
  end
  # END__CLASS_INIT
  
  # BEG_USR_CFG setup
  def setup()
	@group_by = ['dsp']
	@sort_by = ['dsp']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['default'],
        'dsp'       => ['dynamic'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
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
    test_string3 = 'z'*8190 # fill up the whole memory. I did not put this one in paramChan since it is may too big for TC display. I do not need to modify it anyway.
    insert_modules = "insmod spi_bitbang.ko`--(?i:error)`;insmod davinci_spi_master.ko`--(?i:error)`;insmod at25xxA_eeprom.ko`--(?i:error)`"
    remove_modules = "rmmod at25xxA_eeprom;rmmod davinci_spi_master;rmmod spi_bitbang;rmmod at25xxA_eeprom"
    common_paramsChan = {
      #'target_sources'  => 'LSP\st_parser',
      'dev_node'  => '/dev/mtdblock0',  # be careful, the node here really depends insmod nand first or spi-eeprom first.
      'eeprom'    => 'spi_eeprom',
      'test_string1' => 'abc'*20, # generate some string here.
      'test_string2' => 'efgh'*10,
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
        'description'  => "Verify that the module insertion works fine.", 
        'testcaseID'   => 'spi_func_dyn_0001',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{insert_modules};cat /proc/mtd`++{eeprom}`;lsmod",
        }),
      },
      {
        'description'  => "Verify that the module cannot be removed when it is currently in use.", 
        'testcaseID'   => 'spi_func_dyn_0002',
        'paramsChan'  => common_paramsChan.merge({ 
        }),
        'auto' => false,
      },
      {
        'description'  => "Verify that the module cannot be inserted when already statically built.", 
        'testcaseID'   => 'spi_func_dyn_0003',
        'paramsChan'  => common_paramsChan.merge({ 
        }),
        'auto' => false,
      },
      {
        'description'  => "Verify insertion and removal of the module/s multiple times without IO.", 
        'testcaseID'   => 'spi_func_dyn_0004',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{remove_modules};" + get_repeat_cmd(10, "#{insert_modules};cat /proc/mtd`++{eeprom}`;lsmod;#{remove_modules};lsmod;cat /proc/mtd`--{eeprom}`"),
        }),
      },
      {
        'description'  => "!Stress: Verify insertion and removal of the module/s multiple times with IO.", 
        'testcaseID'   => 'spi_func_dyn_0005',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd' => "#{remove_modules};" + get_repeat_cmd(5, "#{insert_modules};cat /proc/mtd`++{eeprom}`;lsmod" +
                  ";echo {test_string1} > {dev_node};strings {dev_node}`++{test_string1}`" +
                  ";#{remove_modules};lsmod;cat /proc/mtd`--{eeprom}`"),
        }),
      },
      {
        'description'  => "Verify that Write/Read test pass when dynamic module. ",
        'testcaseID'   => 'spi_func_0001',
        'paramsChan'  => common_paramsChan.merge({ 
          'cmd'   => "#{remove_modules};#{insert_modules};cat /proc/mtd`++{eeprom}`;lsmod" +
                    ";echo {test_string1} > {dev_node};strings {dev_node}`++{test_string1}`" +
                    ";echo {test_string2} > {dev_node};strings {dev_node}`++{test_string2}`" +
                    ";strings {dev_node} > spi_test.txt" +
                    ";#{remove_modules};lsmod;cat /proc/mtd`--{eeprom}`",
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
  end
  # END_USR_CFG get_outputs
  
end
