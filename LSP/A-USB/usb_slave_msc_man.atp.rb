
class Usb_slave_msc_manTestPlan < TestPlan

  def initialize
	super
	@base_bootargs = Hash.new
	@import_only = true
  end
  
  # BEG_USR_CFG setup
  def setup()
 #   @order = 2
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        #'platform'  => ['dm355'],							#Enter the platform used here (string) i.e. 'dm6446'
        #'os'        => [''],					#Operating system used in the target
        'custom'    => ['usbslave'],				#This defines the usb mode to be slave, do not change
        'dsp'       => ['static'],       # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['dma'],           	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        'microType' => ['rtt']    	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    {}
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
    result = Array.new
    common_params = {
			'ext'            	=> false,
      'bestFinal'      	=> false,
      'basic'          	=> false,
      'bft'            	=> false,
      'reg'            	=> false,
      'auto'           	=> false,
      'script'          => 'a manual test case',
      'configID'        => 'a manual test case',
      'iter'            => '1',
	  'paramsChan'				=> {'host_os' => 'win_xp', 'usb_devices' => 'HD;MMC'},
	  'paramsControl'   	=> {},
      'paramsEquip'   	=> {},
	  }
	desc_array = ["Verify that the module cannot be removed when it is currently in use:\r\n\t1.Load the module\r\n\t2.Perform and IO operation\r\n\t3.When IO is in progress remove the module using rmmod",
				  "Verify that the module cannot be inserted when already statically built:\r\n\t1.Build the driver statically and also as a module\r\n\t2.Boot the dut with the statically built image\r\n\t3.Load the module",
				  #"Verify that the driver is compliant with USB-IF USBCV Tests (Chapter 9 and OTG) when configured in DMA mode:\r\n\t1.Connect the DUT to a PC through USB 2.0 Hub\r\n\t2.Initialize the driver and connect it to the Win XP PC.",
				  #"Verify that the driver is compliant with WHQL USB Tests on Win XP (HCT 12.1). Use DMA mode:\r\n\t1.Initialize the driver and connect the DUT to the Win XP PC\r\n\t2.Run the HCT 12.1 USB Tests",
				  "Verify that the DUT is stable after removal of the cable during an IO operation:\r\n\t1.Initialize the DUT\r\n\t2.Connect the DUT to the host\r\n\t3.Read/Write data to the DUT from the host\r\n\t4.Remove the cable during the IO",
				  "Verify the driver software version:\r\n\t1.Build and load the driver and note down the version",
				  "Verify the following documentation for its availability and its content:\r\n\t1.Driver release notes\r\n\t2.Driver User guide\r\n\t3.Driver Programmer guide",
				  "Verify the driver can be built with the debug mode enabled:\r\n\t1.Build the driver with the gcc option -g",
				  "Verify that the creation of a file on a media that is full fails:\r\n\t1.Initialize the DUT\r\n\t2.Connect the DUT to host\r\n\t3.Perform the a write operation on a media that is full", 
				 ]
	
	desc_array.each_index do |idx|
		result << common_params.merge({'description' => desc_array[idx],
									   'testcaseID'      => "usb_msc_slave_manual_#{idx}",})
	end
	result
  end
  # END_USR_CFG get_manual

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
    }
 end
  # END_USR_CFG get_outputs
  
end #END_CLASS
