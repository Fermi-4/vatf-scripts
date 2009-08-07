class Usbhosthid_func_mouse_basicTestPlan < TestPlan
  
   # BEG_CLASS_INIT
   def initialize()
     super
     #@import_only = true
   end
   # END__CLASS_INIT    
   
   # BEG_USR_CFG setup
   def setup()
     @group_by = ['op_mode']
     @sort_by =  ['op_mode']
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
     },
       ]
   end
   # END_USR_CFG get_keys
   
   # BEG_USR_CFG get_params
   def get_params()
       @mouse_op=['mouse movement','right click','left click','midle button click'] + 
                 ['wheel Forward Movement','wheel Backward Movement']
            
     {
     	'usb_device' => ['mouse'],
     	'op_mode' => ['RAW'],
     	'mouse_op' => @mouse_op,
     }
   end
   # END_USR_CFG get_params
 
   # BEG_USR_CFG get_constraints
   def get_constraints()
     [
     ]
   end
   # END_USR_CFG get_constraints
 
   # BEG_USR_CFG get_outputs
   def get_outputs(params)
     {
          'ext'            => false,
          'bestFinal'      => true,
          'basic'          => true,
          'bft'            => true,
          'reg'            => true,
          'auto'           => true,
      	  'description'     => " #{params['op_mode']}: Verify the #{params['usb_device']} #{params['mouse_op']} operation mode",
          'testcaseID'      => "usb_hid_mouse_func_" + "%04d" % "#{@current_id}",
          'script'          => 'LSP\A-USB_HID\default_usb_basic.rb',
      	  'configID'        => '..\Config\lsp_generic.ini',
          'iter'            => "1",
          'paramsChan'     => {
              'usb_device'  => params['usb_device'],
              'op_mode'     => params['op_mode'],
              'mouse_op'    => params['mouse_op'],
          }
     } 	      
   end
   # END_USR_CFG get_outputs
 
 end