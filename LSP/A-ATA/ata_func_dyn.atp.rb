require '../../TestPlans/LSP/A-ATA/ata_common'
require '../../TestPlans/LSP/Common/atp_helper'
class Ata_func_dynTestPlan < TestPlan
  include Ata_common
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
        'custom'    => ['default'],
        'dsp'       => ['dynamic'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    @op_mode =  ['udma4']
    @power_mode = ['active']
    @fs_type = ['ext3']
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
    module_name = 'palm_bk3710.ko'   # File.basename(module_name, '.ko') will return 'davinci_nor'.
    module_basename = File.basename(module_name, '.ko')
    mnt_point = '/mnt/ata'
    device_node = '/dev/hda1'
    #fs_type = 'ext3'
    
    common_paramsChan = {
      'module_name'   => module_name,
      'mnt_point'     => mnt_point,
      'device_node'   => device_node,
      'fs_type'       => @fs_type,
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
      {
        'description'  => "Verify driver can be built as modules.", 
        'testcaseID'   => 'ata_func_dyn_0001',
        'auto'        => false,
        'paramsChan'  => common_paramsChan.merge({
        }),
      },
      {
        'description'  => "Verify that the module can be inserted and IO can be performed.", 
        'testcaseID'   => 'ata_func_dyn_0002',
        'paramsChan'  => common_paramsChan.merge({
          # may use fwrite/fread to do IO.
          'cmd'   => 'insmod {module_name}`--cannot\s+insert`;ls /dev/h*`++hda1`;lsmod`++palm`' +
                      ';mkdir {mnt_point};mount {device_node} {mnt_point};mount`++{mnt_point}`' +
                      ';echo abc > /mnt/ata/test_file;grep abc /mnt/ata/test_file`++abc`' +
                      ';cat /mnt/ata/test_file`++abc`',
        }),
      },
      #TODO:
      {
        'description'  => "Verify that the module can not be removed when it is in use.", 
        'testcaseID'   => 'ata_func_dyn_0003',
        'paramsChan'  => common_paramsChan.merge({
          'auto'    => false,
        }),
      },
      {
        'description'  => "Verify that the module status is displayed correctly.", 
        'testcaseID'   => 'ata_func_dyn_0004',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'   => 'insmod {module_name}`--cannot\s+insert`;ls /dev/h*`++hda1`;lsmod`++palm`' +
                      ';cat /proc/modules`++palm`' +
                      ';rmmod {module_name};lsmod`--(palm|fault)`;cat /proc/modules`--palm`;ls /dev/h*`--hda1`',
        }),
      },
      {
        'description'  => "Stress: Verify that the module can be inserted and removed multiple times.", 
        'testcaseID'   => 'ata_func_dyn_0005',
        'paramsChan'  => common_paramsChan.merge({
          'cmd'   => get_repeat_cmd(5, "insmod #{module_name};lsmod`++#{module_basename}`" +
                      ";cat /proc/modules`++#{module_basename}`;ls /dev/mtd*`++mtd3`" +
                      ";rmmod #{module_name};lsmod`--(#{module_basename}|fault)`" +
                      ";cat /proc/modules`--#{module_basename}`;cat /proc/mtd`--mtd3`"),
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
