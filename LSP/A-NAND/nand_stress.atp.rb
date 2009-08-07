class Nand_stressTestPlan < TestPlan
  
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
         'platform' => ['dm365'],
         'os' => ['linux'],
         'target' => ['210_LSP'],
     },
       ]
   end
   # END_USR_CFG get_keys
   
   # BEG_USR_CFG get_params
   def get_params()  
     @fs_type = ['yaffs2']   
     {
     }
   end
   # END_USR_CFG get_params
 
   # BEG_USR_CFG get_manual
   def get_manual()
     # nand_chip =['slc', 'mlc']
     nand_chip =['slc']
     device_node   = ['/dev/mtdblock3', '/dev/mtdblock4']
     mnt_point  = '/mnt/nand'
     common_paramsChan = {
       'mnt_point'   => "#{mnt_point}",
       'device_name'  => "nand",
     }
     
     common_vars = {
       'configID'    => '..\Config\lsp_generic.ini', 
       'script'      => 'LSP\storage_device_stress.rb',
       'auto'	=> true,      
     }
     
     tc = []

    nand_chip.each{|chip|
      @fs_type.each{|fs|
        device_node.each{|device_node|
          tc+=[
            {
            'description'  =>  "#{chip}, #{fs}, #{device_node}: Verify the driver can read write delete continuously for a long time.",
            'testcaseID'   => 'nand_func_basic_0004',
            'paramsChan'  => common_paramsChan.merge({
              'device_node' => "#{device_node}",
              'fs_type' => fs,
              'test_duration' => 36000, # seconds
             }),
            },
          ]    
        }
      }
    }
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