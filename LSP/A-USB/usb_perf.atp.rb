require '../../TestPlans/LSP/Common/fs_perf.atp.rb'

class Usb_perfTestPlan < Fs_perfTestPlan
    
  # BEG_USR_CFG get_params
  def get_params()
    {
      'filesystem'   => ['vfat', 'ext2', 'ext3'],
      #'buffer_size'  => ['4096 65536 131072 262144 524288 1048576'],
      'buffer_size'  => ['102400 262144 524288 1048576 5242880'],
      #'file_size'    => ['268435456'], # Should use bigger value. Using small one for testing purposes
      'file_size'    => ['104857600'], # Should use bigger value. Using small one for testing purposes
      'dev_node'     => ['/dev/sda1'],
      'mount_point'  => ['/mnt/usb'],
    }
  end
  # END_USR_CFG get_params
  
end
