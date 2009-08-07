class Usbhosthid_func_kybrd_basicTestPlan < TestPlan
  
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
       @key_op  =['a','b','c','d', 'e','f','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z']+
                 ['1','2','3','4','5','6','7','8','9','Backspace','Minus', 'Equal']+
                 [ 'Esc','F1','F2','F3','F4','F5','F6','F7','F8','F9','F10','F11','F12']+
                 ['Insert','Home','SingleQuote','Semicolon','Enter']
                
     {
     	'usb_device' => ['keyboard'],
     	'op_mode' => ['RAW'],
     	'key_op'   => @key_op,
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
      	  'description'     => " #{params['op_mode']}: Verify the #{params['usb_device']} #{params['key_op']} key operation mode.",
          'testcaseID'      => "usb_hid_kybrd_func_" + "%04d" % "#{@current_id}",
          'script'          => 'LSP\A-USB_HID\default_usb_basic.rb',
      	  'configID'        => '..\Config\lsp_generic.ini',
          'iter'            => "1",
          'paramsChan'     => {
              'usb_device'  => params['usb_device'],
              'op_mode'     => params['op_mode'],
              'key_op'      => params['key_op'],
          }
     } 	      
   end
   # END_USR_CFG get_outputs
 
 end