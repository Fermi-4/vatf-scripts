class Uboot_func_api_manTestPlan < TestPlan
 
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
                        #'micro'     => ['pio'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
                        #'microType' => ['lld', 'rtt', 'server'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
        'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
                        # DEBUG-- Remove these after debugging & uncomment above line
                        #'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
        #'Platform'  => ['da8xx'],
        'Platform'  => ['dm355'],
        'os'        => ['linux'],
        'target'    => ['210_lsp'],
        #'target'    => ['primus'],
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
    tc = [
        {
            'description'  =>  "Verify that the DUT boots up and console port is available with the network cable disconnected",
            'testcaseID'   => 'uboot_func_api_man_0001',
            'passCrit' => 'Console port works properly on reboot',
        },
        {
            'description'  =>  "Tftp write 3 different 5 Megabyte files after adding a new 2GB flash chip to socket",
            'testcaseID'   => 'uboot_func_api_man_0002',
            'passCrit' => 'Able to successfully write 3 files to a second flash chip',
        },
        {
            'description'  =>  "Read files after adding a new 2GB flash chip to socket ",
            'testcaseID'   => 'uboot_func_api_man_0003',
            'passCrit' => 'Able to successfully read any created files using the nand read command',
        },
        {
            'description'  =>  "Verify the loads bootloader command",
            'testcaseID'   => 'uboot_func_api_man_0004',
            'passCrit' => 'Load S-Record file over serial line',
        },
        {
            'description'  =>  "Verify the loadb bootloader command",
            'testcaseID'   => 'uboot_func_api_man_0005',
            'passCrit' => 'Load binary file over serial line in kermit mode',
        },
        {
            'description'  =>  "Verify the loady bootloader command",
            'testcaseID'   => 'uboot_func_api_man_0006',
            'passCrit' => 'Load binary file over serial line in ymodem mode',
        },
        {
            'description'  =>  "Verify the info nand flash bootloader command",
            'testcaseID'   => 'uboot_func_api_man_0007',
            'passCrit' => 'Verify the info nand flash bootloader command',
        },
        {
            'description'  =>  "Verify the device nand flash bootloader command",
            'testcaseID'   => 'uboot_func_api_man_0008',
            'passCrit' => 'Verify the device nand flash bootloader command',
        },
        {
            'description'  =>  "Verify the erase nand flash bootloader command",
            'testcaseID'   => 'uboot_func_api_man_0009',
            'passCrit' => 'Verify the erase nand flash bootloader command',
        },
        {
            'description'  =>  "Verify the bad blocks nand flash bootloader command",
            'testcaseID'   => 'uboot_func_api_man_00010',
            'passCrit' => 'Verify the bad blocks nand flash bootloader command',
        },
        {
            'description'  =>  "Verify the write nand flash bootloader command",
            'testcaseID'   => 'uboot_func_api_man_0011',
            'passCrit' => 'Verify the write nand flash bootloader command',
        },
        {
            'description'  =>  "Verify the read nand flash bootloader command",
            'testcaseID'   => 'uboot_func_api_man_0012',
            'passCrit' => 'Verify the read nand flash bootloader command',
        },
        {
            'description'  =>  "Verify you can boot from a USB flash drive",
            'testcaseID'   => 'uboot_func_api_man_0013',
            'passCrit' => 'Boot using usb flash drive',
        },
        {
            'description'  =>  "Verify you can boot from a MMC/SD card",
            'testcaseID'   => 'uboot_func_api_man_0014',
            'passCrit' => 'Boot using a mmc/sd card',
        },
        {
            'description'  =>  "Verify you can boot from NAND",
            'testcaseID'   => 'uboot_func_api_man_0015',
            'passCrit' => 'Boot using NAND',
        },
        {
            'description'  =>  "Verify you can boot from NOR",
            'testcaseID'   => 'uboot_func_api_man_0016',
            'passCrit' => 'Boot using NOR',
        },
    ]
    return tc
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
