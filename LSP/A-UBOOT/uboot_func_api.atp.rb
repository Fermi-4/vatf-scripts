class Uboot_func_apiTestPlan < TestPlan
 
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
                        #'microType' => ['lld', 'rtt', 'server']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
                        # DEBUG-- Remove these after debugging & uncomment above line
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
        'Platform'  => [],
        'os'        => [],
        'target'    => [],
        'custom'    => ['default'],
        
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
    }
    
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\A-UBOOT\uboot.rb',
      'ext'         => false,
      'bestFinal'   => false,
      'basic'       => false,
      'bft'         => false,
      'reg'         => false,
      'auto'        => true,
    }


    tc = [
        {
            'description'  =>  "Verify that the DUT boots up and console port is available with the network cable connected",
            'testcaseID'   => 'uboot_func_api_0001',                                               #Test ID 2
            'paramsChan'  => common_paramsChan.merge({
             'cmd' => "version`++(U-Boot|login)--(command not found)`",
            }),
        },
        {
            'description'  =>  "Verify that UBoot displays the version properly",                  #Test ID 3
            'testcaseID'   => 'uboot_func_api_0002',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "version`++(U-Boot|login)--(command not found)`",
            }),
            'auto'            => true,
        },
        {
            'description'  =>  "Verify that UBoot can read its environment variables correctly",   #Test ID 4
            'testcaseID'   => 'uboot_func_api_0003',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "setenv uboot_api test_read ; printenv`++(uboot_api\s+=test_read)`",
            }),
        },
        {
            'description'  =>  "Verify that messages are displayed correctly on the console and the printenv command works.", #Test ID5
            'testcaseID'   => 'uboot_func_api_0004',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "printenv`++(Environment|#)`",
            }),
        },
        {
            'description'  =>  "Verify the setenv bootloader command",                             #Test ID 6
            'testcaseID'   => 'uboot_func_api_0005',
            'paramsChan'  => common_paramsChan.merge({
              #'cmd' => "setenv uboot_api test_set`++(uboot_api\\=test_set)`",
              'cmd' => "setenv uboot_api test_set ; printenv`++(uboot_api\\=test_set)`",
            }),
        },
        {
            'description'  =>  "Verify the saveenv bootloader commands work.",                     # Test ID 7
            'testcaseID'   => 'uboot_func_api_0006',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "setenv uboot_api test_save ; saveenv ; reset`++(any key)` ; [stop_boot] ; printenv`++(uboot_api\\=test_save)`",
            }),
            'auto'            => true,
        },
        {
            'description'  =>  "Verify the askenv bootloader command",                             # Test ID 8
            'testcaseID'   => 'uboot_func_api_0007',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "askenv uboot_api real_test_ask ; printenv`++(uboot_api\\=real_test_ask)`",
              #'cmd' => "setenv uboot_api test_ask;printenv`++(uboot_api\\=test_ask)`",
              #'cmd' => "setenv uboot_api test_ask;printenv`++(uboot_api\\=test_ask)`; askenv uboot_api`++\'uboot_api\':` ; real_test_ask ; printenv`++(uboot_api\\=real_test_ask)`",    #added 12/17/2008
            }),
            'auto'            => false,
        },
        {
            'description'  =>  "Verify the run bootloader command",                                #Test ID 9
            'testcaseID'   => 'uboot_func_api_0008',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "setenv uboot_api printenv ; run uboot_api`++(Environment)`",
            }),
        },
        {
            'description'  =>  "Verify the bootd bootloader command",                              #Test ID 10
            'testcaseID'   => 'uboot_func_api_0009',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "bootd`++(MAC:|BOOTP)`",
            }),
        },
        {
            'description'  =>  "Verify the autoscr bootloader command is present.",                #Test ID 11
            'testcaseID'   => 'uboot_func_api_0010',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "autoscr`++(Wrong Image Format ; Bad magic)`",
            }),
        },
        {
            'description'  =>  "Verify the bootm bootloader command is present.",                  #Test ID 12
            'testcaseID'   => 'uboot_func_api_0011',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "bootm`++(Wrong Image Format)`",
            }),
        },
        {
            'description'  =>  "Verify the go bootloader command.",                                #Test ID13
            'testcaseID'   => 'uboot_func_api_0012',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "go`++(start application)`",
            }),
        },
        {
            'description'  =>  "Verify the bootp bootloader command.",                             #Test ID 14
            'testcaseID'   => 'uboot_func_api_0013',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "bootp`++(done)`",
            }),
        },
        {
            'description'  =>  "Verify the boot bootloader command",                               #Test ID 15
            'testcaseID'   => 'uboot_func_api_0014',
            'paramsChan'  => common_paramsChan.merge({
              #'cmd' => "boot`++(loading:)`",
              'cmd' => "boot`++(MAC:|BOOTP)`",
            }),
        },
        {
            'description'  =>  "Verify the dhcp bootloader command.",                              #Test ID 16
            'testcaseID'   => 'uboot_func_api_0015',
            'paramsChan'  => common_paramsChan.merge({
              #'cmd' => "dhcp`++(done) ; boot`",
              'cmd' => "dhcp`++(MAC:|BOOTP)`",
            }),
        },
        {
            'description'  =>  "Verify the base bootloader command is present.",                   #Test ID 17
            'testcaseID'   => 'uboot_func_api_0016',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "base`++(Base Address:)`",
            }),
        },
        {
            'description'  =>  "Verify the crc32 memory bootloader command is present.",           #Test ID 18
            'testcaseID'   => 'uboot_func_api_0017',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "crc32`++(checksum)`",
            }),
        },
        {
            'description'  =>  "Verify the cp memory bootloader command is present.",              #Test ID 19
            'testcaseID'   => 'uboot_func_api_0018',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "cp`++(memory copy)`",
            }),
        },
        {
            'description'  =>  "Verify the cmp memory bootloader command is present.",             #Test ID 20
            'testcaseID'   => 'uboot_func_api_0019',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "cmp`++(memory compare)`",
            }),
        },
        {
            'description'  =>  "Verify the md memory bootloader command is present.",              #Test ID 21
            'testcaseID'   => 'uboot_func_api_0020',                            # changed search value from 00000000: to 000000f0: - unit would hang during boot-up with old value - 01-07-2009
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "md 0`++(000000f0:)`",
            }),
        },
        {
            'description'  =>  "Verify the mm memory bootloader command is present.",              #Test ID 22
            'testcaseID'   => 'uboot_func_api_0021',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "mm`++(memory modify)`",
            }),
        },
=begin  -- DEBUG this command currently hangs the DUT
        {
            'description'  =>  "Verify the mtest bootloader command is present.",                  #Test ID 23
            'testcaseID'   => 'uboot_func_api_0022',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "mtest`++()`",
            }),
        },
=end
=begin
        {
            'description'  =>  "Verify the mwc memory write cyclic command",                       #Test ID 24
            'testcaseID'   => 'uboot_func_api_0023',                            # changed search value from 00000000: to 000000f0: - unit would hang during boot-up with old value - 01-07-2009
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "mwc`++(memory write)`",
            }),
        },
=end
        {
            'description'  =>  "Verify the mw memory write cyclic command is present.",            #Test ID 25
            'testcaseID'   => 'uboot_func_api_0024',                            # changed search value from 00000000: to 000000f0: - unit would hang during boot-up with old value - 01-07-2009
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "mw`++(memory write)`",
            }),
        },
        {
            'description'  =>  "Verify the nm memory bootloader command is present.",              #Test ID 26
            'testcaseID'   => 'uboot_func_api_0025',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "nm`++(constant address)`",
            }),
        },
        {
            'description'  =>  "Verify the loop bootloader command is present.",                   #Test ID 27
            'testcaseID'   => 'uboot_func_api_0026',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "loop`++(infinite loop)`",
            }),
        },
=begin
        {
            'description'  =>  "Verify the flinfo bootloader command is present.",                 #Test ID 28
            'testcaseID'   => 'uboot_func_api_0027',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "flinfo 1`++(Bank)`",
            }),
        },
        {
            'description'  =>  "Verify the erase bootloader command is present.",                  #Test ID 29
            'testcaseID'   => 'uboot_func_api_0028',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "erase`++(done)`",
            }),
        },
        {
            'description'  =>  "Verify the protect bootloader command is present.",                #Test ID 30
            'testcaseID'   => 'uboot_func_api_0029',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "protect`++(active partition)`",
            }),
        },
        {
            'description'  =>  "Verify the protect bootloader command is present.",                #Test ID 31
            'testcaseID'   => 'uboot_func_api_0030',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "protect`++(protect FLASH)`",
            }),
        },
        {
            'description'  =>  "Verify the mtdparts bootloader command is present.",               #Test ID 32
            'testcaseID'   => 'uboot_func_api_0031',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "mtdparts`++(active partition:)`",
            }),
        },
=end
        {
            'description'  =>  "Verify the iprobe bootloader command is present.",                 #Test ID 33
            'testcaseID'   => 'uboot_func_api_0032',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "iprobe`++(Valid chip addresses)`",
            }),
        },
        {
            'description'  =>  "Verify the icrc32 memory bootloader command is present.",          #Test ID 34
            'testcaseID'   => 'uboot_func_api_0033',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "icrc32`++(checksum)`",
            }),
        },
        {
            'description'  =>  "Verify the imw memory bootloader command is present.",             #Test ID 35
            'testcaseID'   => 'uboot_func_api_0034',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "imw`++(memory write)`",
            }),
        },
        {
            'description'  =>  "Verify the inm memory bootloader command is present.",             #Test ID 36
            'testcaseID'   => 'uboot_func_api_0035',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "inm`++(memory modify)`",
            }),
        },
        {
            'description'  =>  "Verify the imm memory bootloader command is present.",             #Test ID 37
            'testcaseID'   => 'uboot_func_api_0036',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "imm`++(i2c memory modify)`",
            }),
        },
        {
            'description'  =>  "Verify the imd memory bootloader command is present.",             #Test ID 38
            'testcaseID'   => 'uboot_func_api_0037',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "imd`++(i2c memory display)`",
            }),
        },
        {
            'description'  =>  "Verify the iloop memory bootloader command is present.",           #Test ID 39
            'testcaseID'   => 'uboot_func_api_0038',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "iloop`++(infinite loop)`",
            }),
        },
=begin
        {
            'description'  =>  "Verify the bdinfo bootloader command is present.",                 #test ID 40
            'testcaseID'   => 'uboot_func_api_0039',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "bdinfo`++(start|size|addr)`",
            }),
        },
=end
        {
            'description'  =>  "Verify the iminfo bootloader command is present.",                 #test ID 41
            'testcaseID'   => 'uboot_func_api_0040',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "iminfo`++(Verifying Checksum|Unknown image)`",
            }),
        },
        {
            'description'  =>  "Verify the imi bootloader command is present.",                    #test ID 42
            'testcaseID'   => 'uboot_func_api_0041',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "imi`++(Verifying Checksum|Unknown image)`",
            }),
        },
        {
            'description'  =>  "Verify the coninfo bootloader command is present.",                #test ID 43
            'testcaseID'   => 'uboot_func_api_0042',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "coninfo`++(serial|stdin|stdout)`",
            }),
        },
        {
            'description'  =>  "Verify the help bootloader command is present.",                   #Test ID44
            'testcaseID'   => 'uboot_func_api_0043',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "help`++(print monitor)`",
            }),
        },
        {
            'description'  =>  "Verify the echo bootloader command is present.",                   #Test ID 45
            'testcaseID'   => 'uboot_func_api_0044',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "echo The Quick Brown Fox Test`++(Unknown)|(:>)|(Brown Fox)`",
            }),
        },
        {
            'description'  =>  "Verify the reset bootloader command is present.",                  #test ID 46
            'testcaseID'   => 'uboot_func_api_0045',
            'paramsChan'  => common_paramsChan.merge({
              #'cmd' => "setenv uboot_api test_reset ; printenv`++(uboot_api\\=test_reset)` ; reset ; [stop_boot] ; printenv`++(uboot_api\\=test_reset)`",
              'cmd' => "setenv uboot_api test_reset ; printenv`++(uboot_api\\=test_reset)` ; reset`++(any key)` ; [stop_boot] ; printenv`++(uboot_api\\=test_save)`",
            }),
            'auto'            => true,
        },
        {
            'description'  =>  "Verify the sleep bootloader command is present.",                  #Test ID 47
            'testcaseID'   => 'uboot_func_api_0046',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "sleep`++(delay)`",
            }),
        },
        {
            'description'  =>  "Verify the version bootloader command is present.",                #Test ID 48
            'testcaseID'   => 'uboot_func_api_0047',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "version`++(U-Boot)`",
            }),
        },
        {
            'description'  =>  "Verify the ? bootloader command is present.",                      #Test ID 49
            'testcaseID'   => 'uboot_func_api_0048',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "\\?`++(print monitor)`",
            }),
            'auto'            => true,
        },
        {
            'description'  =>  "Verify the date bootloader command",                               #Test ID 50
            'testcaseID'   => 'uboot_func_api_0049',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "date`++(Unknown)`",
            }),
        },
        {
            'description'  =>  "Verify the ping bootloader command is functional.",                #Test ID 51
            'testcaseID'   => 'uboot_func_api_0050',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "dhcp`++(:>|#)`;ping\s10.218.103.13`++(is\s*alive)`; boot",
            }),
        },
        {
            'description'  =>  "Verify the base bootloader command is present.",                   #Test ID 52
            'testcaseID'   => 'uboot_func_api_0051',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "base`++(Base Address)`",
            }),
        },
=begin
        {
            'description'  =>  "Verify the mwc memory write cyclic command",                       #Test ID 53
            'testcaseID'   => 'uboot_func_api_0052',                            # changed search value from 00000000: to 000000f0: - unit would hang during boot-up with old value - 01-07-2009
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "mwc`++(memory write)`",
            }),
        },
=end
=begin                        # These routines need to be validated as to their correct operation
        {
            'description'  =>  "Verify the DUTs soft reset command works. This test is repeated 10 times.",  #Test ID 33
            'testcaseID'   => 'uboot_func_api_0034',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "setenv uboot_api test_reset ; printenv`++(uboot_api\\=test_reset)` ; reset`++(any key)` ; [stop_boot] ; printenv`++(uboot_api\\=test_save)`",
            }),
        },
        {
            'description'  =>  "Verify the DUT can be rebooted with the uImage. This test is repeated 50 times.",  #Test ID 34
            'testcaseID'   => 'uboot_func_api_0034',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "setenv uboot_api test_reset ; printenv`++(uboot_api\\=test_reset)` ; reset`++(any key)` ; [stop_boot] ; printenv`++(uboot_api\\=test_save)`",
            }),
        },
        {
            'description'  =>  "Verify the DUT can be rebooted with the uImage and login to the DUT. This test is repeated 10 times.",  #Test ID 35
            'testcaseID'   => 'uboot_func_api_0034',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "setenv uboot_api test_reset ; printenv`++(uboot_api\\=test_reset)` ; reset`++(any key)` ; [stop_boot] ; printenv`++(uboot_api\\=test_save)`",
            }),
        },

=end
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
