#require '../media_filer_utils'

#include MediaFilerUtils


require '../../TestPlans/LSP/Common/ioctl_api.atp.rb'
class Nand_func_ioctlTestPlan < Ioctl_apiTestPlan
  
  # BEG_USR_CFG get_params
  def get_params()
    {
      'fs_type' => ['jffs2', 'yaffs2'],
      'fs_api'  => ['mtd_info', 'set_oob','get_badblk', 'region_info'],
                   
      'mnt_point' => ['/mnt/nand'],
      'device_node' => ['/dev/mtdblock3'],
      'mount_device' => ['/dev/mtd3'],
    }
  end
  # END_USR_CFG get_params
   
end #END_CLASS