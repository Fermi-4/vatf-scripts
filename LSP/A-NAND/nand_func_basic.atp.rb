class Nand_func_basicTestPlan < TestPlan
  
   # BEG_CLASS_INIT
   def initialize()
     super
     #@import_only = true
   end
   # END__CLASS_INIT    
   
   # BEG_USR_CFG setup
   def setup()
     @group_by = ['nand_chip', 'fs_type']
     @sort_by = ['nand_chip','fs_type']
   end
   # END_USR_CFG setup
   
   # BEG_USR_CFG get_keys
   def get_keys()
     keys = [
     {
         'dsp'       => ['static'],   # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
         'micro'     => ['default'],      # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
         'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server        
         'custom'    => ['default'],
         # DEBUG-- Remove these after debugging & uncomment above line -- 'microType' => ['lld'],    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
          # 'platform' => ['dm355'],
          # 'os' => ['linux'],
          # 'target' => ['210_lsp'],
     },
       ]
   end
   # END_USR_CFG get_keys
   
   # BEG_USR_CFG get_params
   def get_params()  
     @fs_type = ['']   
     {
     }
   end
   # END_USR_CFG get_params
 
   # BEG_USR_CFG get_manual
   def get_manual()
     # nand_chip =['slc', 'mlc']
     nand_chip =['slc']
     device_node   = ['/dev/mtdblock3', '/dev/mtdblock4']
     # file_size =['256','512','2048','4096','16k','32k','64k','128k','256k']
     file_size =['256','2048','4096','256k']
     file_size_fixbuf = ['100','500','1024','1400']
     file_c ='/mnt/nand/nand_testfile'
     make_file     = "echo Davinci > /mnt/nand/nand_testfile;" # nand is mounted in setup function in script.
     delete_file   =  'rm -f /mnt/nand/nand_testfile;'
     delete_dir    = 'rm -rf /mnt/nand/nand_testdir;'
     mnt_point  = '/mnt/nand'
     common_paramsChan = {
       'mnt_point'   => "#{mnt_point}",
     }
     
     common_vars = {
       'configID'    => '..\Config\lsp_generic.ini', 
       'script'      => 'LSP\default_fs_basic_script.rb',
       'auto'	=> true,      
     }
     
     tc = []

     nand_chip.each{|chip|
      tc += [
         {
             'description'  =>  "#{chip}: Verify mtdutils: flash_eraseall, nandwrite, nanddump",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0019',
             'auto'         => false,
             'paramsChan'  => common_paramsChan.merge({
             }),
         },
      ]
        @fs_type.each{|fs|
          device_node.each{|device_node|
            tc+=[
=begin
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the NAND partitions are display during the boot up",
             'testcaseID'   => 'nand_func_basic_0001',
             'auto' => false,
             'paramsChan'  => common_paramsChan.merge({
             }),
                 
         },  
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the driver can be accessed in 8 bit mode",
             'testcaseID'   => 'nand_func_basic_0002',
             'paramsChan'  => common_paramsChan.merge({
                'fs_type' => fs, # Cuz this var is used in the script
                'cmd' => "df `++\s*#{device_node}`",
                'ensure' => "umount /mnt/nand",
                'device_node' => "#{device_node}",
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the driver can be configured in Polled mode",
             'testcaseID'   => 'nand_func_basic_0003',
             'paramsChan'  => common_paramsChan.merge({
               'fs_type' => fs, # Cuz this var is used in the script                                        
               'cmd' => "#{make_file}" +
                        "cat /mnt/nand/nand_testfile `++\s*Davinci`",
                'device_node' => "#{device_node}",
                'ensure' => "umount /mnt/nand",
             }),
         },
=end
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the driver can operate on block of data using the file system: Write",
             'testcaseID'   => 'nand_func_basic_0004',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
              'fs_type' => fs, # Cuz this var is used in the script                                        
              'cmd' => "#{make_file}" +
                "cat /mnt/nand/nand_testfile `++\s*Davinci`",                 
                'ensure' => "[dut_timeout\\=60];umount /mnt/nand",   
                 
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the driver can operate on block of data using the file system: Read",
             'testcaseID'   => 'nand_func_basic_0005',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'cmd' => "#{make_file}" +
               "cat /mnt/nand/nand_testfile `++\s*Davinci`",      
               'ensure' => "umount /mnt/nand",                  
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the driver can operate on block of data using the file syst: Erase",
             'testcaseID'   => 'nand_func_basic_0006',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'cmd' => "#{make_file}" +
                "echo ""> /mnt/nand/nand_testfile" +
                ";cat /mnt/nand/nand_testfile `++\s*`",  
                'ensure' => "umount /mnt/nand",        
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify that a character device entry can be created",
             'testcaseID'   => 'nand_func_basic_0007',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'cmd' => " mknod /dev/mtd10 c 90 0; ls /dev/mtd10`++\s*/dev/mtd10`",
               'ensure' => "rm /dev/mtd10",
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify that a block device entry can be created",
             'configID'     => '..\Config\lsp_generic.ini', 
             #'script'       => 'LSP\A-MMC\mmc.rb',
             'testcaseID'   => 'nand_func_basic_0008',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
              'fs_type' => fs, # Cuz this var is used in the script                                        
               'cmd' => " mknod /dev/mtdblock10 b 31 0; ls /dev/mtdblock10`++\s*/dev/mtdblock10`",
               'ensure' => "rm /dev/mtdblock10"
                 
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the filesystem can be mounted on multiple mount points",
             'configID'     => '..\Config\lsp_generic.ini', 
             #'script'       => 'LSP\A-MMC\mmc.rb',
             'testcaseID'   => 'nand_func_basic_0009',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'cmd' => "#{make_file}" +
                 "mkdir -p /mnt/nand1;mkdir -p /mnt/nand" +
                 ";[dut_timeout\\=30];mount -t #{fs} #{device_node} /mnt/nand1;mount`++/mnt/nand1`" +
                 ";[dut_timeout\\=30];mount -t #{fs} #{device_node} /mnt/nand;mount`++/mnt/nand`",
               'ensure' => "umount /mnt/nand1;umount /mnt/nand"
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the same file can be accessed through both mount points",
             'configID'     => '..\Config\lsp_generic.ini', 
             #'script'       => 'LSP\A-MMC\mmc.rb',
             'testcaseID'   => 'nand_func_basic_0010',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script
               'cmd' => "#{make_file}" +
                  " mkdir -p /mnt/nand1" +
                  ";mount -t #{fs} #{device_node} /mnt/nand1;ls /mnt/nand1/nand_testfile`++\s*nand_testfile`" +
                  ";ls /mnt/nand`++\s*nand_testfile`",
               'ensure' => 'umount /mnt/nand1;umount /mnt/nand'
               }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify that the partition information of the NAND device can be displayed",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0011',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'cmd' => "cat /proc/mtd`++\s*mtd3`",
               
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify that the mount information can be displayed",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0012',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'cmd' => " df `++\s*#{device_node}`",
                         
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify that a given number of bytes can be dumped into flash",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0013',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                                 
               #'cmd' => "mount -t #{fs} /dev/mtdblock3 /mnt/nand; #{make_file}" +
                 'cmd' => " nanddump -l 100 #{device_node.delete('block')}`++\s*0x00000000\s*and\s*ending\s*at\s*0x00000064`",
               }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify that a block on a NAND partition can be erased",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0014',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'cmd' => "flash_erase #{device_node.delete('block')}`++\s*Erase\s*Total\s*1\s*Units`",
               }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify a NAND partition can be erase completely",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0015',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               #'cmd' => "[dut_timeout\\=180];flash_eraseall #{device_node.delete('block')}`++\s*99\s*%\s*complete`",
               'cmd' => "[dut_timeout\\=180];flash_eraseall #{get_flash_eraseall_option(fs)} #{device_node.delete('block')}`++\s*99\s*%\s*complete`",
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify NAND as root filesystem",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0016',
             #'auto'         => false,
             'script'       => 'LSP\default_mtd_as_rootfs_test.rb',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'is_do_erase' => 1,
               'target_reduced_fs' => 'LSP\target-reduced-dm365.tar',
               'bootargs_mtd' => "console\\=ttyS0\\,115200n8 ip\\=dhcp root\\=#{device_node} rw rootfstype\\=#{fs} mem\\=116M",               
               'cmd_flasheraseall' => "[dut_timeout\\=180];flash_eraseall #{get_flash_eraseall_option(fs)} #{device_node.delete('block')}",
               'cmd_mount' => "[dut_timeout\\=120];mkdir #{mnt_point};mount -t #{fs} #{device_node} #{mnt_point}`--(?i:fail)`" +
                              ";mount`++#{mnt_point}`",
               'cmd_umount' => "[dut_timeout\\=60];umount #{mnt_point}",
               'cmd_write' => "[dut_timeout\\=60];dd if\\=/dev/zero of\\=#{mnt_point}/testfile bs\\=1M count\\=1`--(?i:error)|(?i:fail)`" +
                              ";ls #{mnt_point}/testfile -lh`++1\.0M--(?i:No\\s+such\\s+file)`",
               'cmd_read' => "[dut_timeout\\=60];dd if\\=#{mnt_point}/testfile of\\=/mnt/testfile bs\\=1M count\\=1`--(?i:error)|(?i:fail)`" +
                              ";ls /mnt/testfile -lh`++1\.0M--(?i:No\\s+such\\s+file)`",
               'cmd_rm_testfile_mp' => "[dut_timeout\\=20];rm #{mnt_point}/testfile`--(?i:error)|(?i:fail)`",
               'cmd_rm_testfile' => "[dut_timeout\\=20];rm /mnt/testfile`--(?i:error)|(?i:fail)`", 
               'times_to_reboot' => 5,
               'is_soft_reboot' => 1,
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify soft boot is ok when NAND as root filesystem",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0017',
             'script'       => 'LSP\default_mtd_as_rootfs_test.rb',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'is_do_erase' => 1,
               'target_reduced_fs' => 'LSP\target-reduced-dm365.tar',
               'bootargs_mtd' => "console\\=ttyS0\\,115200n8 ip\\=dhcp root\\=#{device_node} rw rootfstype\\=#{fs} mem\\=116M",               
               'cmd_flasheraseall' => "[dut_timeout\\=180];flash_eraseall #{get_flash_eraseall_option(fs)} #{device_node.delete('block')}",
               'cmd_mount' => "[dut_timeout\\=120];mkdir #{mnt_point};mount -t #{fs} #{device_node} #{mnt_point}`--(?i:fail)`" +
                              ";mount`++#{mnt_point}`",
               'cmd_umount' => "[dut_timeout\\=60];umount #{mnt_point}",
               'cmd_write' => "[dut_timeout\\=60];dd if\\=/dev/zero of\\=#{mnt_point}/testfile bs\\=1M count\\=1`--(?i:error)|(?i:fail)`" +
                              ";ls #{mnt_point}/testfile -lh`++1\.0M--(?i:No\\s+such\\s+file)`",
               'cmd_read' => "[dut_timeout\\=60];dd if\\=#{mnt_point}/testfile of\\=/mnt/testfile bs\\=1M count\\=1`--(?i:error)|(?i:fail)`" +
                              ";ls /mnt/testfile -lh`++1\.0M--(?i:No\\s+such\\s+file)`",
               'cmd_rm_testfile_mp' => "[dut_timeout\\=20];rm #{mnt_point}/testfile`--(?i:error)|(?i:fail)`",
               'cmd_rm_testfile' => "[dut_timeout\\=20];rm /mnt/testfile`--(?i:error)|(?i:fail)`", 
               'times_to_reboot' => 1,
               'is_soft_reboot' => 1,
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify hardware boot is ok when NAND as root filesystem",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0018',
             'script'       => 'LSP\default_mtd_as_rootfs_test.rb',
             'paramsChan'  => common_paramsChan.merge({
                'device_node' => "#{device_node}",
               'fs_type' => fs, # Cuz this var is used in the script                                       
               'is_do_erase' => 1,
               'target_reduced_fs' => 'LSP\target-reduced-dm365.tar',
               'bootargs_mtd' => "console\\=ttyS0\\,115200n8 ip\\=dhcp root\\=#{device_node} rw rootfstype\\=#{fs} mem\\=116M",               
               'cmd_flasheraseall' => "[dut_timeout\\=180];flash_eraseall #{get_flash_eraseall_option(fs)} #{device_node.delete('block')}",
               'cmd_mount' => "[dut_timeout\\=120];mkdir #{mnt_point};mount -t #{fs} #{device_node} #{mnt_point}`--(?i:fail)`" +
                              ";mount`++#{mnt_point}`",
               'cmd_umount' => "[dut_timeout\\=60];umount #{mnt_point}",
               'cmd_write' => "[dut_timeout\\=60];dd if\\=/dev/zero of\\=#{mnt_point}/testfile bs\\=1M count\\=1`--(?i:error)|(?i:fail)`" +
                              ";ls #{mnt_point}/testfile -lh`++1\.0M--(?i:No\\s+such\\s+file)`",
               'cmd_read' => "[dut_timeout\\=60];dd if\\=#{mnt_point}/testfile of\\=/mnt/testfile bs\\=1M count\\=1`--(?i:error)|(?i:fail)`" +
                              ";ls /mnt/testfile -lh`++1\.0M--(?i:No\\s+such\\s+file)`",
               'cmd_rm_testfile_mp' => "[dut_timeout\\=20];rm #{mnt_point}/testfile`--(?i:error)|(?i:fail)`",
               'cmd_rm_testfile' => "[dut_timeout\\=20];rm /mnt/testfile`--(?i:error)|(?i:fail)`", 
               'times_to_reboot' => 1,
               'is_soft_reboot' => 0,
             }),
         },
         {
             'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify dut can boot from NAND and nand erase and nand write utils",
             'configID'     => '..\Config\lsp_generic.ini', 
             'testcaseID'   => 'nand_func_basic_0019',
             'auto'         => false,
             'paramsChan'  => common_paramsChan.merge({
             }),
         },
       ]    
     }
    }
  }
   tc_config = []
   nand_chip.each {|chip|
   @fs_type.each {|fs| 
   device_node.each {|device_node|
   file_size.each { |size|
      tc_config +=[
        {     
        'description'  => "#{chip}, #{fs}, #{device_node}:Verify that the driver can write a file size of #{size} for #{fs} filesystem", 
        'testcaseID'   => "nand_write_size_#{size}",
        'paramsChan'  => common_paramsChan.merge({
          'device_node' => "#{device_node}",
          'file_size' => size,
          'fs_type' => fs,
          'cmd' => "dd if\\=/dev/zero of\\=/mnt/nand/#{size} bs\\=#{size} count\\=1" +
                   ";ls -lh /mnt/nand/#{size}`++#{size}`",
        }),
        },
        {
        'description'  => "#{chip}, #{fs}, #{device_node}:Verify that the driver can read a file size of #{size} for #{fs} filesystem", 
        'testcaseID'   => "nand_read_size_#{size}",
        'paramsChan'  => common_paramsChan.merge({
          'device_node' => "#{device_node}",
          'file_size' => size,
          'fs_type' => fs,
          'cmd' => "dd if\\=/mnt/nand/#{size} of\\=/mnt/nand/#{size}_read " +
                   ";ls -lh /mnt/nand/#{size}_read`++#{size}`",
                   'ensure' => "rm /mnt/nand/#{size} /mnt/nand/#{size}_read",
        }),    
                   
      }
      ]
    }
   }
  }
 }    
  tc = tc + tc_config

=begin  
   tc_config = []
   nand_chip.each {|chip|
   @fs_type.each {|fs| 
   device_node.each {|device_node|
   file_size_fixbuf.each { |size|
      tc_config +=[
        {     
        'description'  => "#{chip}, #{fs}, #{device_node}:Verify that the driver is able to write large" + 
                          " or maximum data with buffer size 1MB and file #{size}MB for #{fs} filesystem", 
        'testcaseID'   => "nand_write_file_size_fixbuf#{size}",
        'paramsChan'  => common_paramsChan.merge({
          'device_node' => "#{device_node}",
          'file_size' => size,
          'fs_type' => fs,
          'cmd' => "[dut_timeout\\=600];dd if\\=/dev/zero of\\=/mnt/nand/#{size}MB bs\\=1M count\\=#{size}" +
                   ";ls -lh /mnt/nand/#{size}MB`++#{size}M`",
        }),
        },
        {
        'description'  => "#{chip}, #{fs}, #{device_node}:Verify that the driver is able to read large" + 
                          " or maximum data with buffer size 1MB and file #{size}MB for #{fs} filesystem", 
        'testcaseID'   => "nand_read_size_#{size}",
        'paramsChan'  => common_paramsChan.merge({
          'device_node' => "#{device_node}",
          'file_size' => size,
          'fs_type' => fs,
          'cmd' => "[dut_timeout\\=600];dd if\\=/mnt/nand/#{size}MB of\\=/mnt/nand/#{size}_read " +
                   ";ls -lh /mnt/nand/#{size}_read`++#{size}M`",
                   'ensure' => "rm /mnt/nand/#{size}MB /mnt/nand/#{size}_read",
        }),    
                   
      }
      ]
    }
   }
  }
 }    
  tc = tc + tc_config  
=end  
    tc_new = []
     tc.each{|val|
       tc_new << common_vars.merge(val)
     }
     return tc_new
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
 
  private
  def get_flash_eraseall_option(fs)
    option = ''
    option = '-j' if fs == 'jffs2'
    return option
  end
 end