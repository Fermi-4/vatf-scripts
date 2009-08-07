require '../../TestPlans/LSP/Common/fs_perf.atp.rb'

class Mmc_perfTestPlan < Fs_perfTestPlan
 
   # BEG_USR_CFG get_params
  def get_params()
    {
      'filesystem'   => ['vfat', 'ext2', 'ext3'],
      'buffer_size'  => ['102400 262144 524288 1048576 5242880'],
	  'file_size'    => ['104857600'],
	  'dev_node'     => ['/dev/mmcblk0'],
      'mount_point'  => ['/mnt/mmcsd'],
    }
  end
  # END_USR_CFG get_params

end
