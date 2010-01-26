# this one can be used for functionality test recipe.
class Nor_funcTestPlan < TestPlan
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
    @group_by = ['microType']
    @sort_by = ['microType']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['nor'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    @fs_type = ['jffs2']
    @device_node = ['/dev/mtdblock3']
    @mnt_point = ['/mnt/nor']
    # the following ioctls are getting from 210-PRD
    @ioctls = ['MEMGETREGIONCOUNT', 'MEMGETINFO', 'MEMERASE', 'MEMWRITEOOB'] +
              ['MEMREADOOB', 'MEMLOCK', 'MEMUNLOCK', 'MEMGETOOBSEL']
    {
      'ioctls'  => @ioctls,
      'device_node'  => ['/dev/mtd3'],
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
  def get_manual()
    common_paramsChan = {
      #'ensure'  => "rmmod {module_name}`--(?i:fail|error)`",
    }
    common_vars = {
      'configID'        => '..\Config\lsp_generic.ini', 
      'script'          => 'LSP\default_test_script.rb',
      'ext'             => false,
      'bestFinal'       => false,
      'basic'           => false,
      'bft'             => false,
      'reg'             => false,
      'auto'            => true,
      'paramsControl'   => {
      },
      'paramsEquip'     => {
      },

    }
    tc = [
      {
        'description'  => "Verify that that the NOR flash partitions are displayed while booting.", 
        'testcaseID'   => 'nor_func_man_0001',
        'paramsChan'  => common_paramsChan.merge({
        }),
        'auto'  => false,
      },
      {
        'description'  => "Create multiple mount points for the JFFS2 Filesystem.", 
        'testcaseID'   => 'nor_func_man_0001',
        'paramsChan'  => common_paramsChan.merge({
          'device_node' => @device_node[0],
          'fs_type'   => @fs_type[0],
          'cmd'       => "mkdir /mnt/nor1;umount /mnt/nor1;mount -t {fs_type} {device_node} /mnt/nor1;mount`++/mnt/nor1`" +
                        ";mkdir /mnt/nor2;umount /mnt/nor2;mount -t {fs_type} {device_node} /mnt/nor2;mount`++/mnt/nor2`",
        }),
      },
      {
        'description'  => "Verify that the partition information of NOR device is dispayed.", 
        'testcaseID'   => 'nor_func_man_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'cat /proc/mtd`++(?i:mtd3)`',
        }),
      },
      {
        'description'  => "!!!Verify that the partition is erased completely.", 
        'testcaseID'   => 'nor_func_man_0001',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'       => 'flash_eraseall -j /dev/mtd3`--(?i:error|fail)`',
        }),
      },
      {
        'description'  => "Verify that mount information is displayed .", 
        'testcaseID'   => 'nor_func_man_0001',
        'paramsChan'  => common_paramsChan.merge({
          'device_node' => @device_node[0],
          'fs_type'   => @fs_type[0],
          'cmd'       => 'mkdir /mnt/nor;umount /mnt/nor;mount -t {fs_type} {device_node} /mnt/nor;df -h`++{device_node}`'
        }),
      },
    ]
        
    # merge the common varaibles to the individule test cases and the value in individule test cases will overwrite the common ones.
    tc_new = []
    tc.each{|val|
      #val.merge!(common_vars)
      tc_new << common_vars.merge(val)
    }
    
    return tc_new
  end
  # END_USR_CFG get_manual

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
      'paramsChan'     => {
        'target_sources' => 'LSP\st_parser',
        # 'file_size'   => params['file_size'],
        # 'buffer_size' => params['buffer_size'],
        # 'test_type'   => params['test_type'],
        # 'test_file'   => params['test_file'],
        # 'mnt_point'   => params['mnt_point'],
        'device_node' => params['device_node'],
        'cmd'   => get_ioctl_test_cmd(params),
      },
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      
      'description'     => "Verify that the IOCTL command #{params['ioctls']} works correctly.",
      'testcaseID'      => "nor_func_ioctl_#{@current_id}",
      'script'          => 'LSP\default_test_script.rb',
      'configID'        => '..\Config\lsp_generic.ini',
      'iter'            => "1",
    }
  end
  # END_USR_CFG get_outputs
  
end #END_CLASS

private
def get_ioctl_test_cmd(params)
  # @ioctls = ['MEMGETREGIONCOUNT', 'MEMGETINFO', 'MEMERASE', 'MEMWRITEOOB'] +
              # ['MEMREADOOB', 'MEMLOCK', 'MEMUNLOCK', 'MEMGETOOBSEL']
  rtn = case params['ioctls']
    when 'MEMGETINFO': "st_parser nor nor_ioctl #{params['device_node']} mtd_info`--(?i:fail)`"
    else               "echo fail (not supported yet)`--(?i:fail)`"
  end
end
    