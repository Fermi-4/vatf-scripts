class Ioctl_apiTestPlan < TestPlan
  # BEG_CLASS_INIT
  def initialize()
    super
    @import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @order = 2
    @group_by = ['fs_type']
    @sort_by = ['fs_type', 'fs_api']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['default'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled | default
         #'micro'     => ['pio'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'fs_type' => [],
      'fs_api'  => ['fopen', 'fclose', 'fread', 'fwrite', 'fstat', 'fseek', 'remove', 'rename', 'mkdir'] +
                   ['rmdir', 'chdir', 'chmod', 'mount', 'umount'],
      'mnt_point' => [],
      'device_node' => [],
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
      'paramsChan'     => {
        'target_sources' => 'LSP\st_parser',
        'cmd'     => get_cmd(params['fs_api'], params['mnt_point'], params['device_node'], params['fs_type']),
        #'ensure'  => get_ensure(params['fs_api'], params['mnt_point']),
        'fs_type' => params['fs_type'],
        'fs_api'  => params['fs_api'],
        'mnt_point' => params['mnt_point'],
        'device_node' => params['device_node'],
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'    => "Verify NAND IOCTL -- #{params['fs_api']} for #{params['fs_type'].upcase}",

      'testcaseID'      => "ioctl_func_api_#{@current_id}",
      'script'          => 'LSP\default_fs_api_script.rb',
      
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  def get_cmd(fs_api, mnt_point, device_node, fs_type)
    #'fs_api'  => ['fopen', 'fclose', 'fread', 'fwrite', 'fstat', 'fseek', 'remove', 'rename', 'mkdir',] 
    #             ['rmdir', 'chdir', 'chmod', 'feof', 'mount', 'umount'],
    # I did not do mount here since I don't want do mount every time
    # then do mount in script so I can check if it already mount.
    # testfile = "#{mnt_point}/api_testfile"
    # make_file = "echo api_test_info > #{testfile}"
    rtn = case fs_api
=begin     
     when 'fopen': "#{make_file};\./st_parser fsapi fopen #{testfile} rw`++(?i:success)--(?i:fail)`"
      when 'fclose': "#{make_file};\./st_parser fsapi fopen #{testfile} rw fclose`--(?i:fail)`"
      when 'fread': "#{make_file};\./st_parser fsapi fread #{testfile}`++(?i:success)--(?i:fail)`"
      when 'fwrite': "\./st_parser fsapi fwrite #{mnt_point}/api_newtestfile 1024`++(?i:success)--(?i:fail)`"
      when 'fstat': "#{make_file};\./st_parser fsapi getfstat #{testfile}`++(?i:success)--(?i:fail)`"
      when 'fseek': "#{make_file};\./st_parser fsapi fopen #{testfile} rw fseek 2 0`++(?i:success)--(?i:fail)`"
      when 'remove': "#{make_file};\./st_parser fsapi fremove #{testfile}`++(?i:success)--(?i:fail)`"
      when 'rename': "#{make_file};\./st_parser fsapi frename #{testfile} #{mnt_point}/rename_testfile`++(?i:success)--(?i:fail)`"
      when 'mkdir': "\./st_parser fsapi mkdir -p #{mnt_point}/test_dir 777`++(?i:success)--(?i:fail)`"
      when 'rmdir': "mkdir -p #{mnt_point}/test_dir;\./st_parser fsapi rmdir #{mnt_point}/test_dir`++(?i:success)--(?i:fail)`"
      when 'chdir': "mkdir -p #{mnt_point}/test_dir;\./st_parser fsapi chdir #{mnt_point}/test_dir`++(?i:success)--(?i:fail)`"
      when 'chmod': "#{make_file};\./st_parser fsapi fchmod #{testfile} 444`++(?i:success)--(?i:fail)`;ls #{testfile} -l"
      #when 'feof': # no implementation yet
=end
      when 'mtd_info': "./st_parser nand nand_ioctl #{device_node.delete("block")} mtd_info `++Get\s*MTD\s*Information\s*Success--Get\s*MTD\s*Information\s*Failed`" 
      when 'set_oob': "./st_parser nand nand_ioctl #{device_node.delete("block")} set_oob `++Set\s*OOB\s*Success--Set\s*OOB\s*Failed`"  
      when 'get_badblk': "./st_parser nand nand_ioctl #{device_node.delete("block")} get_badblk `++Get\s*Bad\s*block\s*information\s*Success--Get\s*Bad\s*Block\s*Information\s*Failed`"  
      when 'region_info': "./st_parser nand nand_ioctl #{device_node.delete("block")} region_info `++Get\s*Bad\s*block\s*information\s*Success--Get\s*Bad\s*Block\s*Information\s*Failed`"  

      #when 'mount': "cd #{mnt_point};mkdir -p #{mnt_point}/mnt/sub;mount -t #{fs_type} #{device_node} #{mnt_point}/mnt/sub;mount`++#{mnt_point}/mnt/sub`"
      #when 'umount': "cd #{mnt_point};mkdir -p #{mnt_point}/mnt/sub;mount -t #{fs_type} #{device_node} #{mnt_point}/mnt/sub;mount`++#{mnt_point}/mnt/sub`" +
      #               ";umount #{mnt_point}/mnt/sub;mount`--#{mnt_point}/mnt/sub`"
      else          "echo fail`--(?i:fail)`"
    end
  end
  

=begin  
   def get_ensure(fs_api, mnt_point)
    #'fs_api'  => ['fopen', 'fclose', 'fread', 'fwrite', 'fstat', 'fseek', 'remove', 'rename', 'mkdir',] 
    #             ['rmdir', 'chdir', 'chmod', 'feof', 'mount', 'umount'],
    # I did not do mount here since I don't want do mount every time
    # then do mount in script so I can check if it already mount.
    testfile = "#{mnt_point}/api_testfile"
    rtn = case fs_api
      when 'fwrite': "rm #{mnt_point}/api_newtestfile"
      when 'mkdir': "rmdir #{mnt_point}/test_dir"
      when 'rmdir': ""
      when 'chdir': "rmdir #{mnt_point}/test_dir"
      #when 'feof': # no implementation yet
      when 'mount': "umount #{mnt_point}/mnt/sub"
      when 'umount': ""
      else          "rm #{testfile}"
    end

  end
=end
  
end #END_CLASS
