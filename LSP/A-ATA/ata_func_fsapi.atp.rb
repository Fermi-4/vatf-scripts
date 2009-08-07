require '../../TestPlans/LSP/Common/fs_api.atp.rb'
class Ata_func_fsapiTestPlan < Fs_apiTestPlan
  # BEG_USR_CFG get_params
  def get_params()
    {
      'fs_type' => ['ext2', 'ext3', 'vfat', 'iso9660'],
      'fs_api'  => ['fopen', 'fclose', 'fread', 'fwrite', 'fstat', 'fseek', 'remove', 'rename', 'mkdir'] +
                   ['rmdir', 'chdir', 'chmod', 'mount', 'umount'],
      'mnt_point' => ['/mnt/ata'],
      'device_node' => ['/dev/hda1', '/dev/hdc'],
    }
  end
  # END_USR_CFG get_params
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
      'IF [fs_type] IN {"iso9660"} THEN [device_node] IN {"/dev/hdc"} ELSE [device_node] IN {"/dev/hda1"};'
    ]
  end
  # END_USR_CFG get_constraints
 
end #END_CLASS
