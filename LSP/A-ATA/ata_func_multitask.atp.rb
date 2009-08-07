require '../../TestPlans/LSP/A-ATA/ata_common'
class Ata_func_multitaskTestPlan < Ata_func_premTestPlan
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
    @group_by = ['device_type', 'lba_mode', 'test_type', 'op_mode']
    @sort_by = ['device_type', 'lba_mode', 'test_type', 'op_mode']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['default'],
        'dsp'       => ['static'],            # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],            # 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['lld']    # 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
      
  # BEG_USR_CFG get_params
  def get_params()
    append_params = 
    {
    }
    super().merge(append_params)
  end
  # END_USR_CFG get_params
 
  # BEG_USR_CFG get_constraints
  def get_constraints()
    super
  end
  # END_USR_CFG get_constraints
  
  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    this_outputs = 
    {    
      'script'        => 'LSP\default_fs_api_script.rb',
      'description'   => "Multithread/process Test: Verify that the driver can simultaneously perform File IO of #{params['file_size']} with buffer size" +
                        " #{params['buffer_size']}.",      
    }
    super(params).merge(this_outputs)

    # some of the above should be inherited from a common base
  end
  # END_USR_CFG get_outputs

  private  
  def get_cmd(params)
    buffer_size = params['buffer_size']
    mnt_point = params['mnt_point']
    file_size = params['file_size']
    rtn = "\./st_parser atahdd setbuffsize #{buffer_size} Multi_Process 2 #{file_size} 5 #{mnt_point}`++(?i:success)--(?i:fail)`" +
          ";\./st_parser atahdd Multi_thread 2 #{file_size} 5 #{mnt_point}`++(?i:success)--(?i:fail)|(?i:corruption)`"
  end
    
end #END_CLASS
