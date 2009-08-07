require '../../TestPlans/LSP/Common/atp_helper.rb'
class Nand_func_yaffs_dynaTestPlan < TestPlan
  #include Nor_common
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
      #  'target'    => ['210_lsp'],
      #  'platform'  => ['dm6446'],
        'os'        => ['linux'],
        'custom'    => ['default'],
        'dsp'       => ['dynamic'], # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],     # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']      # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
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
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    [
    ]
  end
  # END_USR_CFG get_constraints

  # BEG_USR_CFG get_manual
  def get_manual()
    module_name = 'davinci-nand.ko'   # File.basename(module_name, '.ko') will return 'davinci_nor'.
    #reg_module_name = File.basename(module_name, '.ko')
    reg_module_name = 'davinci_nand'
    mnt_point = '/mnt/nand'
    device_node = '/dev/mtdblock3'
    fs_type = 'yaffs2'
    
    common_paramsChan = {
      #'target_sources'  => 'LSP\st_parser',
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
=begin    
      {
        'description'  => "Verify driver can be built as modules.", 
        'testcaseID'   => 'nand_func_dyn_0001',
        'auto'        => true,
        'paramsChan'  => common_paramsChan.merge({
          'cmd' => "ls #{module_name}`++#{module_name}`",
        }),
      },
      {
        'description'  => "Verify that the module can be inserted and IO can be performed.", 
        'testcaseID'   => 'nand_func_dyn_0002',
        'paramsChan'  => common_paramsChan.merge({
          # may use fwrite/fread to do IO.
          'cmd'   => "insmod #{module_name}`--cannot\s+insert`;lsmod`++#{reg_module_name}`;cat /proc/mtd`++mtd3`" +
                      ";mkdir #{mnt_point};mount -t #{fs_type} #{device_node} #{mnt_point};mount`++#{mnt_point}`" +
                      ";echo abc > #{mnt_point}/test_file;grep abc #{mnt_point}/test_file`++abc`" +
                      ";cat #{mnt_point}/test_file`++abc`",
          'ensure'  => "rm #{mnt_point}/test_file",
        }),
      },
=end      
      {
        'description'  => "Verify that the module can be inserted and IO can be performed using fwrite/read.", 
        'testcaseID'   => 'nand_func_dyn_0002',
        'paramsChan'  => common_paramsChan.merge({
          'target_sources'  => 'LSP\st_parser',
          # may use fwrite/fread to do IO.
          'cmd'   => "insmod #{module_name};lsmod`++#{reg_module_name}`;cat /proc/mtd`++mtd3`" +
                      ";mkdir #{mnt_point}"+
                      ";[dut_timeout\\=120];flash_eraseall /dev/mtd3" +
                      ";mount -t #{fs_type} #{device_node} #{mnt_point};mount`++#{mnt_point}`" +
                      ";\./st_parser fsapi fwrite #{mnt_point}/test_file 1024 fread #{mnt_point}/test_file`--(?i:fail)`",
          'ensure'  => "rm #{mnt_point}/test_file;umount #{device_node}",
        }),
      },
      #TODO:
      {
        'description'  => "Verify that the module can not be removed when it is in use.", 
        'testcaseID'   => 'nand_func_dyn_0003',
        'auto'  => false,
        'paramsChan'  => common_paramsChan.merge({
          'cmd'    => "insmod #{module_name};lsmod`++#{reg_module_name}`" +
                      ";dd if\\=/dev/zero of\\=#{mnt_point}/bigfile bs\\=1M count=100 &" +
                      ";rmmod #{reg_module_name}`++(?i:not)`",
          'ensure'  => "rm #{mnt_point}/test_file;umount #{device_node}",
        }),
      },
      {
        'description'  => "Verify that the module status is displayed correctly.", 
        'testcaseID'   => 'nand_func_dyn_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'   => "insmod #{module_name};lsmod`++#{reg_module_name}`;cat /proc/mtd`++mtd3`" +
                      ";cat /proc/modules`++#{reg_module_name}`;ls /dev/mtd*`++mtd3`" +
                      ";rmmod #{module_name};lsmod`--(#{reg_module_name}|fault)`" +
                      ";cat /proc/modules`--#{reg_module_name}`;cat /proc/mtd`--mtd3`",
        }),
      },
      {
        'description'  => "Verify that the module can be inserted and removed multiple times.", 
        'testcaseID'   => 'nand_func_dyn_0005',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'   => get_repeat_cmd(5, "insmod #{module_name};lsmod`++#{reg_module_name}`;cat /proc/mtd`++mtd3`" +
                      ";cat /proc/modules`++#{reg_module_name}`;ls /dev/mtd*`++mtd3`" +
                      ";rmmod #{module_name};lsmod`--(#{reg_module_name}|fault)`" +
                      ";cat /proc/modules`--#{reg_module_name}`;cat /proc/mtd`--mtd3`"),
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
