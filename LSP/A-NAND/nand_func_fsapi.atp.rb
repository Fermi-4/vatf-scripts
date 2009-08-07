require '../../TestPlans/LSP/Common/fs_api.atp.rb'
class Nand_func_fsapiTestPlan < Fs_apiTestPlan
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'fs_type' => ['jffs2', 'yaffs2'],
      'fs_api'  => ['fopen', 'fclose', 'fread', 'fwrite', 'fstat', 'fseek', 'remove', 'rename', 'mkdir'] +
                   ['rmdir', 'chdir', 'chmod', 'mount', 'umount'],
      'mnt_point' => ['/mnt/nand'],
      'device_node' => ['/dev/mtdblock3'],
    }
  end
  # END_USR_CFG get_params
   
end #END_CLASS
