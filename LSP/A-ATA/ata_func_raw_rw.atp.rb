require '../../TestPlans/LSP/A-ATA/ata_common'
class Ata_func_raw_rwTestPlan < TestPlan
  include Ata_common
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['device_type', 'lba_mode', 'test_type', 'op_mode']
    @sort_by = ['device_type', 'lba_mode', 'test_type', 'op_mode']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['default'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
      
  # BEG_USR_CFG get_params
  def get_params()
    {
      # operational mode
      'op_mode'     => ['pio4', 'mdma2', 'udma4'],
      'power_mode'  => ['active'],
      'device_type' => ['ata_device'],  # for testing ATA or ATAPI
      'lba_mode'    => ['28bits', '48bits'],
      'file_size'   => [50*1024*1024],
      'buffer_size' => [1*1024*1024],
      'test_type'   => ['write-read'],
      'device_node' => ['/dev/hda1'],
    }
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
      'IF [device_type] = "atapi_device" THEN [test_type] = "read" ELSE [test_type] <> "read";',
    ]
  end
  # END_USR_CFG get_constraints
  
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
      'paramsChan'     => {
        'target_sources'  => 'LSP\st_parser',
        'op_mode'         => params['op_mode'],
        'power_mode'      => params['power_mode'],
        'lba_mode'        => params['lba_mode'],
        'file_size'       => params['file_size'],
        'buffer_size'     => params['buffer_size'],
        'test_type'       => params['test_type'],
        'device_node'     => params['device_node'],
        # after sleep mode, the dut need reboot.
        'cmd'     => "#{get_power_mode_cmd(params['power_mode'])};[dut_timeout\\=30]" +
                  ";#{set_opmode(params['op_mode'])};[dut_timeout\\=30]" +
                  ";#{get_cmd(params)}",
        'ensure'  => "",
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'     => "Verify that the media driver can handle raw file read/write of #{params['file_size']} sized Files for operation mode #{params['op_mode']}.",
      'testcaseID'      => "ata_func_raw_rw_" + "%04d" % "#{@current_id}",
      'script'          => 'LSP\default_test_script.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private  
  def get_cmd(params)
    test_type = params['test_type']
    file_size = params['file_size']
    buffer_size = params['buffer_size']
    rtn = case test_type
      when 'write-read':  "Not Implemented Yet"
      when 'read':  "Not Implemented Yet"
      else  "echo no cmd for #{test_type}`--no\\s+cmd`"
    end
  end
    
end #END_CLASS
