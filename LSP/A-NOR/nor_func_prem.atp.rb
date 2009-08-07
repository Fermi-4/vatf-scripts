# this one can be used for functionality test recipe.
class Nor_func_premTestPlan < TestPlan
  #include Ata_common
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['make_name', 'microType']
    @sort_by = ['make_name', 'microType']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['nor'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld', 'rtt', 'server']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    @fs_type = ['jffs2']
    @device_node = ['/dev/mtdblock3']
    @mnt_point = ['/mnt/nor']
    {
      'file_size'   => [5*1024*1024, 10*1024*1024],
      'buffer_size' => [500*1024, 1*1024*1024],
      'make_name'   => ['AMD', 'Intel'],
      'test_type'   => ['write-read'],
      'fs_type'     => @fs_type,
      'mnt_point'   => @mnt_point,
      'device_node' => @device_node,
      'test_file'   => ['/mnt/nor/test_file'],
    }
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_manual
  # END_USR_CFG get_manual

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
      'paramsChan'     => {
        'target_sources' => 'LSP\st_parser',
        'file_size'   => params['file_size'],
        'buffer_size' => params['buffer_size'],
        'test_type'   => params['test_type'],
        'test_file'   => params['test_file'],
        'mnt_point'   => params['mnt_point'],
        'device_node' => params['device_node'],
        # after sleep mode, the dut need reboot.
        'cmd'   => "mkdir #{params['mnt_point']};mount -t #{params['fs_type']} #{params['device_node']} #{params['mnt_point']}" +
                    ";mount`++#{params['mnt_point']}`;[dut_timeout\\=30]" +
                    ";#{get_cmd(params['test_type'], params['file_size'], params['buffer_size'], params['test_file'])}",
        #'ensure'  => "[dut_timeout\\=30];rm #{params['test_file']}"
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      # 'description'    => get_desc("Verify for #{params['chan_type'].upcase} channel with #{params['transfer_type'].upcase}" +
                          # " + #{params['addr_mode'].upcase} + #{params['features'].upcase}, data with size #{params['file_size']} bytes transfer sucessfully", params['test_switch']),
      'description'     => "Verify that the driver can handle File IO of #{params['file_size']} with buffer size" +
                          " #{params['buffer_size']} for preemption #{params['microType']} mode.",
      'testcaseID'      => "nor_func_prem_#{@current_id}",
      'script'          => 'LSP\default_test_script.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private 
  def get_cmd(test_type, file_size, buffer_size, test_file)
    rtn = case test_type
      when 'write-read':  "\./st_parser fsapi buffsize #{buffer_size} fwrite #{test_file} #{file_size}`--(?i:fail)`" +
                          ";\./st_parser fsapi fread {test_file}`--(?i:fail)`"
    end
  end
  
end #END_CLASS
