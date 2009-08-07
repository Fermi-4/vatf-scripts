class Usbhosthid_func_basic_MiscTestPlan < TestPlan
  
   # BEG_CLASS_INIT
   def initialize()
     super
     #@import_only = true
   end
   # END__CLASS_INIT    
   
   # BEG_USR_CFG setup
   def setup()
     @group_by = ['usb_device','op_mode']
     @sort_by =  ['usb_device', 'op_mode']
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
       #@usb_device = ['mouse','keyboard', 'Hub']
       @usb_device = ['mouse', 'keyboard']
       @op_mode =['RAW', 'GUI']
       @hid_device=['USB keyboard', 'mouse', 'USB hub']
       @mouse_op=['cursor mouvement','right click','left click','midle button click','wheel movement']
             
     {
     
     }
   end
   # END_USR_CFG get_params
 
   # BEG_USR_CFG get_manual
   def get_manual()
            
     common_vars = {
       'configID'    => '..\Config\lsp_generic.ini', 
       'script'      => 'LSP\default_test_script.rb',
       'ext'            => false,
       'bestFinal'      => false,
       'basic'          => false,
       'bft'            => false,
       'reg'            => false,
       'auto'	=> true,
       
     }
     
     tc = [
      {
        'description'  => "GUI MODE: Verify the cursor is displayed in any opned editor", 
        'testcaseID'   => 'usbhosthod_func_basic_0003',
        'auto' => false,
        'passCrit' => 'You Keyboard must be inserted into your USB port'
      },
      {
        'description'  => "GUI MODE: Verify that any character typed on the keyboard is displayed correctly", 
        'testcaseID'   => 'usbhosthod_func_basic_0004',
        'auto' => false,
        'passCrit' => 'You Keyboard must be inserted into your USB port'
      },
      {
        'description'  => "GUI MODE: Verify the keyboard editing function work properly", 
        'testcaseID'   => 'usbhosthod_func_basic_0005',
        'auto' => false,
        'passCrit' => 'You Keyboard must be inserted into your USB port'
      },
      
      {
        'description'  => "Verify that the driver is stable after continuously clicking any key of the mouse 100 times.",	

        'testcaseID'   => 'usbhosthod_func_basic_0006',
        'auto' => false,
        'passCrit' => 'Your the USB mouse must be connected to target'
      },
      {
        'description'  => "Verify that the driver is stable after continuously keeping any key of the mouse pressed for (10 mins).",	

        'testcaseID'   => 'usbhosthod_func_basic_0007',
        'auto' => false,
        'passCrit' => 'Your must must be inserted into your USB port'
      },
      {
        'description'  => "Verify that the driver is stable after continuously keeping any key/keys of the keyboard pressed for 10 mins.",	

        'testcaseID'   => 'usbhosthod_func_basic_0007',
        'auto' => false,
        'passCrit' => 'Your Keyboard must be inserted into your USB port'
      },
      {
        'description'  => "Verify that the DUT is able to perform IO operations after multiple device removal/insertions of keyboard",	
		'testcaseID'   => 'usbhosthod_func_basic_0007',
        'auto' => false,
        'passCrit' => 'Insert and remove the the keyboard multiple times'
      },
      
      {
         'description'  =>  "Verify that the the mouse is detected as a Host HID class devices.",
         'testcaseID'   => "usbhosthid_func_basic_Mouse_detection00",
         'passCrit' => 'Your USB Mouse must connect to the target',
         'paramsChan'  => {
         'cmd' => "dmesg | tail `++\s*Mouse`",
         },
      }, 
       {
         'description'  =>  "Verify that the the keyboard is detected as a Host HID class devices.",
         'testcaseID'   => "usbhosthid_func_basic_Keybrd_detection00",
         'passCrit' => 'Your USB Keyboard must connect to the target',
         'paramsChan'  => {
         'cmd' => "dmesg | tail `++\s*Keyboard`",
         },
      }, 
       {
         'description'  =>  "Verify that the the hub is detected as a Host HID class devices.",
         'testcaseID'   => "usbhosthid_func_basic_Mouse_detection00",
         'passCrit' => 'Your USB Mouse must connect to the target',
         'paramsChan'  => {
         'cmd' => "dmesg | tail `++\s*hub`",
         },
      }, 
       {
         'description'  =>  "Verify that the the mouse & a keyboard are detected as a Host HID class devices, when connected through a HUB.",
         'testcaseID'   => "usbhosthid_func_basic_MouseKeybrd_detection00",
         'passCrit' => 'Your USB Mouse must connect to the target',
         'paramsChan'  => {
         'cmd' => "dmesg | tail `++\s*hub`" +
                  ";dmesg | tail `++\s*Mouse" +
                  ";dmesg | tail `++\s*Keyboard"
         },
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