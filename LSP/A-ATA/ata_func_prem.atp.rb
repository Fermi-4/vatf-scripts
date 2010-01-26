require '../../TestPlans/LSP/A-ATA/ata_common'
class Ata_func_premTestPlan < TestPlan
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
    @group_by = ['device_type', 'lba_mode', 'microType', 'op_mode', 'test_type']
    @sort_by = ['device_type', 'lba_mode', 'microType', 'op_mode', 'test_type']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['default'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld', 'rtt', 'server']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
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
      'fs_type'     => ['ext3'],
      'mnt_point'   => ['/mnt/ata'],
      'device_node' => ['/dev/hda1'],
      'test_file'   => ['/mnt/ata/test_file'], # how to read cdrom file and do I know the filename?
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
        'test_file'       => params['test_file'],
        'fs_type'         => params['fs_type'],
        'mnt_point'       => params['mnt_point'],
        'device_node'     => params['device_node'],
        # after sleep mode, the dut need reboot.
        'cmd'     => "#{get_power_mode_cmd(params['power_mode'])};[dut_timeout\\=30]" +
                  ";#{set_opmode(params['op_mode'])};[dut_timeout\\=30]" +
                  ";#{get_cmd(params)}" +
                  ";st_parser fsapi fremove #{params['test_file']}`--(?i:fail)`",
        'ensure'  => "[dut_timeout\\=30];rm #{params['test_file']}"
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'     => "Verify that the media driver can handle File Creation, Deletion and I/O of #{params['file_size']} sized Files for operation mode #{params['op_mode']}.",
      'testcaseID'      => "ata_func_prem_" + "%04d" % "#{@current_id}",
      'script'          => 'LSP\A-ATA\ata.rb',
      
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
    test_file = params['test_file']
    rtn = case test_type
      when 'write-read':  "st_parser fsapi buffsize #{buffer_size} fwrite #{test_file} #{file_size}`--(?i:fail|fatal)`" +
                          ";st_parser fsapi fread #{test_file}`--(?i:fail|fatal)`"
      when 'read':  "st_parser fsapi fread #{test_file}`--(?i:fail|fatal)`"
      else  "echo no cmd for #{test_type}`--no\\s+cmd`"
    end
  end
    
end #END_CLASS
