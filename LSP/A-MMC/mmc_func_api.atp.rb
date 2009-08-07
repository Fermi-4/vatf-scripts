class Mmc_func_apiTestPlan < TestPlan
 
  # BEG_CLASS_INIT
  def initialize()
    super
    #@import_only = true
  end
  # END__CLASS_INIT    
  
  # BEG_USR_CFG setup
  def setup()
    @group_by = ['microType', 'micro', 'dsp']
    @sort_by = ['microType', 'micro', 'dsp']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
    {
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
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
    {
    }
  end
  # END_USR_CFG get_params

  # BEG_USR_CFG get_manual
  def get_manual()
    mount_drive = 'mount -t vfat {mount_device} /mnt/mmc;'
    make_file     = 'echo api_test_info > /mnt/mmc/api_testfile;'
    delete_file   =  'rm -f /mnt/mmc/api_testfile;'
    delete_dir    = 'rm -rf /mnt/mmc/api_testdir;'
    mnt_dev      = '/dev/mmcblk0'
    common_paramsChan = {
      'mount_device' => "#{mnt_dev}",
      'ensure' => "#{delete_file}",
    }
    
    common_vars = {
      'configID'    => '..\Config\lsp_generic.ini', 
      'script'      => 'LSP\A-MMC\mmc.rb',
      'auto'     => true,  # Added by PD to correct Manual mode
    }
    
    tc = [
        {
            'description'  =>  "Verify fopen filesystem API for VFAT",
            'testcaseID'   => 'mmc_func_api_0001',
            'paramsChan'  => common_paramsChan.merge({
             'cmd' => "#{mount_drive} #{make_file}" \
              'st_parser fsapi fopen /mnt/mmc/api_testfile rw`++(Open Successful)--(Open Failed)`',
            }),
        },
        {
            'description'  =>  "Verify fclose filesystem API for VFAT",
            'testcaseID'   => 'mmc_func_api_0002',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{make_file}" \
                'st_parser fsapi fopen /mnt/mmc/api_testfile rw fclose`++(Close Successful)--(Open Failed|Close Failed)`',
            }),
        },
        {
            'description'  =>  "Verify fread filesystem API for VFAT",
            'testcaseID'   => 'mmc_func_api_0003',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{make_file}" \
                'st_parser fsapi fread /mnt/mmc/api_testfile`++(Read Successful)--(Read Failed)`',
            }),
        },
        {
            'description'  =>  "Verify fwrite filesystem API for VFAT",
            'testcaseID'   => 'mmc_func_api_0004',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive}" \
                'st_parser fsapi fwrite /mnt/mmc/api_testfile 64`++(Write Successful)--(Write Failed)`',
            }),
        },
        {
            'description'  =>  "Verify fstat filesystem API for VFAT",
            'testcaseID'   => 'mmc_func_api_0005',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{make_file}" \
                'st_parser fsapi getfstat /mnt/mmc/api_testfile`++(Get File Statue Successful)--(Get File Statue Failed)`',
            }),
        },
        {
            'description'  =>  "Verify fseek filesystem API for VFAT",
            'testcaseID'   => 'mmc_func_api_0006',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{make_file}" \
                'st_parser fsapi fopen /mnt/mmc/api_testfile rw fseek 0 1`++(Seek Successful)--(Open Failed|Seek Failed)`',
            }),
        },
        {
            'description'  =>  "Verify remove filesystem API for VFAT",
            'configID'     => '..\Config\lsp_generic.ini', 
            'script'       => 'LSP\A-MMC\mmc.rb',
            'testcaseID'   => 'mmc_func_api_0007',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{make_file}" \
                'st_parser fsapi fremove /mnt/mmc/api_testfile`++(Remove Successful)--(Remove Failed)`',
            }),
        },
        {
            'description'  =>  "Verify rename filesystem API for VFAT",
            'configID'     => '..\Config\lsp_generic.ini', 
            'script'       => 'LSP\A-MMC\mmc.rb',
            'testcaseID'   => 'mmc_func_api_0008',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{make_file}" \
                'st_parser fsapi frename /mnt/mmc/api_testfile /mnt/mmc/api_testfile_renamed`++(Rename Successful)--(Rename Failed)`',
              'ensure' => 'rm -f /mnt/mmc/api_testfile_renamed'
            }),
        },
        {
            'description'  =>  "Verify mkdir filesystem API for VFAT",
            'configID'     => '..\Config\lsp_generic.ini', 
            'script'       => 'LSP\A-MMC\mmc.rb',
            'testcaseID'   => 'mmc_func_api_0009',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{delete_dir}" \
                'st_parser fsapi mkdir /mnt/mmc/api_testdir 555`++(Directory Create Successful)--(Directory Create Failed)`',
              'ensure' => "#{delete_dir}"
            }),
        },
        {
            'description'  =>  "Verify rmdir filesystem API for VFAT",
            'configID'     => '..\Config\lsp_generic.ini', 
            'script'       => 'LSP\A-MMC\mmc.rb',
            'testcaseID'   => 'mmc_func_api_0010',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{delete_dir}" \
                'st_parser fsapi mkdir /mnt/mmc/api_testdir 555 rmdir /mnt/mmc/api_testdir`++(Directory Delete Successful)--(Directory Delete Failed)`',
              'ensure' => "#{delete_dir}"
            }),
        },
        {
            'description'  =>  "Verify chdir filesystem API for VFAT",
            'configID'     => '..\Config\lsp_generic.ini', 
            'script'       => 'LSP\A-MMC\mmc.rb',
            'testcaseID'   => 'mmc_func_api_0011',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{delete_dir}" \
                'st_parser fsapi mkdir /mnt/mmc/api_testdir 555 chdir /mnt/mmc/api_testdir`++(Change Directory Successful)--(Change Directory Failed)`',
              'ensure' => "#{delete_dir}"
            }),
        },
        {
            'description'  =>  "Verify chmod filesystem API for VFAT",
            'configID'     => '..\Config\lsp_generic.ini', 
            'script'       => 'LSP\A-MMC\mmc.rb',
            'testcaseID'   => 'mmc_func_api_0012',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} #{make_file}" \
                'st_parser fsapi fchmod /mnt/mmc/api_testfile 444`++(Change File Mode Successful)--(Change File Mode Failed)`',
              }),
        },
        {
            'description'  =>  "Verify mount filesystem API for VFAT",
            'configID'     => '..\Config\lsp_generic.ini', 
            'script'       => 'LSP\A-MMC\mmc.rb',
            'testcaseID'   => 'mmc_func_api_0013',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} mount | grep {mount_device} || echo MNT_FAIL`++#{mnt_dev}--MNT_FAIL`",
              }),
        },
        {
            'description'  =>  "Verify umount filesystem API for VFAT",
            'configID'     => '..\Config\lsp_generic.ini', 
            'script'       => 'LSP\A-MMC\mmc.rb',
            'testcaseID'   => 'mmc_func_api_0014',
            'paramsChan'  => common_paramsChan.merge({
              'cmd' => "#{mount_drive} umount {mount_device} ; mount | grep {mount_device} && echo UMNT_FAIL || echo UMNT_PASS`++UMNT_PASS--UMNT_FAIL`",
            }),
        },
    ]
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

end
