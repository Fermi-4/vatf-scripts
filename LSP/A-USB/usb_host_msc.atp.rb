#---
#:section: General
# Test Area:: USB-HOST
# Test Type:: Functionality
# Test Owners:: ? (TII), Ken/Carlos (TIGT)
#---

#---
#:section: Overview
# This ATP exercises the USB HOST MSC (Mass Storage Class) functionality in the device under test.
# The application connects different type of USB MSC devices such as Hard drives and Flash drives to the
# DUT and then it checks for proper detection and enumeration. USB fields such as Device Speed, Class, Protocol,
# Release and Vendor are checked. This ATP also check several operations on the USB devices like write, read, delete, etc.
#---

#---
#:section: References
# USB Technology http://en.wikipedia.org/wiki/USB
#
# USB Standard http://www.usb.org/home
#---

#---
#:section: Required Hardware
# * Iomega USB Hard drive, Model: LDHD500-U, Capacity: 500GB
# * Maxtor USB Hard drive, Model: One Touch III, Capacity: 320GB
# * Sandisk USB Flash drive, Capacity: >= 1GB
# * Memorex USB Flash drive, Capacity: >= 1GB
#---

#---
#:section: Setup
# link:../ATP_LSP_Usb.jpg
#---

#---
#:section: Test Focus
# The focus is to check USB-Host driver's functionality on the following areas:
# 1. Basic Tests
#    * Device initialization and recognition. 
#    * Multiple device connects/disconnects.
#    * Filesystem Operations (create/open/read/write/seek/close/format)
# 2. Data Trasnfer Tests
#    * Read, Write, Read/Write
#    * Simultaneous Copy
# 3. Stress Tests
#    * Longevity
#    * Multiple Connects/Disconnects
#
# Some of these tests will be run using different configurations, such as:
# * Different device types, like hard drivers and flash drives.
# * Different mode of operations such as pio and dma.
# * Different Kernel pre-emption modes such as lld, rt and server
# * Different file sizes from 5 bytes to 1GB
#
# This ATP is written in a way that permits users to create new test cases on the fly
# by defining a new test_sequences value.
#
# The test_sequences parameter defines the actions taken by the host on the USB device.
#
# The syntax used is <action 1>+<action 2>+.....+<action n>[*<number of times to execute the sequence>];[<another test sequence>]
#
# The test_sequences shown below are provided by default, the user is free to add, delete and/or modify them:
#
# <b>'connect+disconnect*2'</b>
# <b>'connect+write+read/write+disconnect'</b>
# <b>'connect+write+disconnect+connect+filechk+disconnect'</b>
# <b>'connect+format+delete_all+mkdir+dirchk+write+filechk+read+delete_all+disconnect'</b>
# <b>'connect+mkdir+rmdir+write+rename+filechk+move+filechk+properties+delete+chkdsk+delete_all+disconnect'</b>
#
# The supported <action x> values are: connect, disconnect, delete_all, write, read, chkdsk, mkdir, delete, rmdir, dirchk, filechk,
# format, move, rename, read/write and properties. Care must be exercised when defining new test_sequences because not all combinations are valid, 
# in general the following constraints are applicable:
#
# 1. Action: connect
#	 * Predecessor: None
#	 * Tasks: connect USB device to Host
# 2. Action: disconnect
#	 * Predecessor: connect
#	 * Tasks: disconnect USB device from Host
# 3. Action: format
#	 * Predecessor: connect
#	 * Tasks: Format a partition by calling mkfs
# 4. Action: read
#	 * Predecessor: connect,write	
#	 * Tasks: Copy test file from Dev to Host and compare to Ref file.
# 5. Action: filechk
#	 * Predecessor: connect,write
#	 * Tasks: Check that Dev Test file matches Ref file at Host.
# 6. Action: write
#	 * Predecessor: connect
#	 * Tasks: Copy Ref file from Host as Test file at Dev
# 7. Action: read/write	
#	 * Predecessor: connect,write		
#	 * Tasks: Copy Test file between devices or between partitions (single device) and compare them
# 8. Action: mkdir	
#	 * Predecessor: connect
#	 * Tasks: Creates a Test directory
# 9. Action: dirchk	
#	 * Predecessor: connect,mkdir
#	 * Tasks: Check that Test directory exists in Dev
# 10. Action: rmdir	
# 	 * Predecessor: connect,mkdir
#	 * Tasks: Removes Test directory from Dev
# 11. Action: move
#	 * Predecessor: connect,write
#	 * Tasks: Move Test file from Test dir to new Test dir (testdir_new)
# 12. Action: rename
#	 * Predecessor: connect,write
#	 * Tasks: Rename Test file
# 13. Action: delete
#	 * Predecessor: connect,write
#	 * Tasks: Delete Test file
# 14. Action: chkdsk
# 	 * Predecessor: connect
#	 * Tasks: Verify disk integrity using e2fsck (ignore for vfat filesystems)
# 15. Action: properties
#	 * Predecessor: connect,write	
#	 * Tasks: Change file's mode property
# 16. Action: delete_all
#	 * Predecessor: connect
#	 * Tasks: Delete all files and directories inside the Dev mount point.
#---

#---
#:section: Tests not included/ Future Enhancements 
# * Add kernel testusb tests (drivers/usb/misc/usbtest.c) http://www.linux-usb.org/usbtest/
#---

#---
#:section: Test Parameters.
# See get_params() method at Usb_host_mscTestPlan class 
#---

class Usb_host_mscTestPlan < TestPlan

  def initialize
	super
	@base_bootargs = Hash.new
	@import_only = true
  end
  
  # BEG_USR_CFG setup
  def setup()
 #   @order = 2
    @group_by = ['microType', 'micro', 'test_sequences']
    @sort_by  = ['microType', 'micro', 'test_sequences']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'custom'    => ['default'],						# This defines the usb mode to be slave, do not change
        'dsp'       => ['static'],   			# 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'micro'     => ['default'],
        'microType' => ['lld', 'rtt']
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    #@usb_devices is a hash of hashes containing usb device information. Each usb device info hash is accessed by a usb_dev value and contains key-value pairs
    @usb_devices = {
        'hda1' =>  {
        'mount_point' => '/mnt/hd1', #target file system node where the device will be mounted if it has not been mounted
        'size' => 1000, #size of the device in units of 10M bytes 
        'fs'   => 'vfat',
        'description' => 'USB Hard Disk IOmega',
        'number_of_partitions' => 2,
        'usb_dev_speed'   => '2.00', 	 #bcdUSB 1.0=low, 1.1=full, 2.0=high
        'usb_dev_release' => '0.01', #bcdDevice two bytes, default = 0x0316
	      'usb_dev_product' => '0x007e', #idProduct two bytes, default = 0xa4a5
	      'usb_dev_vendor' => '0x059b',  #idVendor two bytes,  default = 0x0525
	      'usb_dev_class' => 'Mass Storage', #defines bInterfaceClass, default = Mass Storage 
	      'usb_dev_protocol' => 'SCSI', #defines bDeviceSubClass or bInterfaceSubClass, default = SCSI 
	      'usb_dev_transport' => 'BBB', #defines  bDeviceProtocol or bInterfaceProtocol, default = BBB
	   },
        'hda2' =>  {
        'mount_point' => '/mnt/hd2',
        'size' => 1000, #size of the device in units of 10M bytes 
        'fs'   => 'ext3',
        'description' => 'USB Hard Disk Maxtor',
        'number_of_partitions' => 2,
        'usb_dev_speed'   => '2.00', 	 #bcdUSB 1.0=low, 1.1=full, 2.0=high
        'usb_dev_release' => '0.00', #bcdDevice two bytes, default = 0x0316
	      'usb_dev_product' => '0x7212', #idProduct two bytes, default = 0xa4a5
	      'usb_dev_vendor' => '0x0d49',  #idVendor two bytes,  default = 0x0525
	      'usb_dev_class' => 'Mass Storage', #defines bInterfaceClass, default = Mass Storage 
	      'usb_dev_protocol' => 'SCSI', #defines bDeviceSubClass or bInterfaceSubClass, default = SCSI 
	      'usb_dev_transport' => 'BBB', #defines  bDeviceProtocol or bInterfaceProtocol, default = BBB
	   },
=begin
        'hda3' =>  {
        'mount_point' => '/mnt/hd3',
        'size' => 1000, #size of the device in units of 10M bytes 
        'fs'   => 'ext3',
        'description' => 'USB Hard Disk Western Digital',
        'number_of_partitions' => 2,
        'usb_dev_speed'   => '2.00', 	 #bcdUSB 1.0=low, 1.1=full, 2.0=high
        'usb_dev_release' => '0.00', #bcdDevice two bytes, default = 0x0316
	      'usb_dev_product' => '0x1000', #idProduct two bytes, default = 0xa4a5
	      'usb_dev_vendor' => '0x1058',  #idVendor two bytes,  default = 0x0525
	      'usb_dev_class' => 'Mass Storage', #defines bInterfaceClass, default = Mass Storage 
	      'usb_dev_protocol' => 'SCSI', #defines bDeviceSubClass or bInterfaceSubClass, default = SCSI 
	      'usb_dev_transport' => 'BBB', #defines  bDeviceProtocol or bInterfaceProtocol, default = BBB
	   },
=end
        'flash1' =>  {
        'mount_point' => '/mnt/fd1',
        'size' => 100, #size of the device in units of 10M bytes 
        'fs'   => 'ext3',
        'description' => 'USB Flash drive Sandisk',
        'number_of_partitions' => 1,
        'usb_dev_speed'   => '2.00', 	 #bcdUSB 1.0=low, 1.1=full, 2.0=high
        'usb_dev_release' => '2.00', #bcdDevice two bytes, default = 0x0316
	      'usb_dev_product' => '0x5406', #idProduct two bytes, default = 0xa4a5
	      'usb_dev_vendor' => '0x0781',  #idVendor two bytes,  default = 0x0525
	      'usb_dev_class' => 'Mass Storage', #defines bInterfaceClass, default = Mass Storage 
	      'usb_dev_protocol' => 'SCSI', #defines bDeviceSubClass or bInterfaceSubClass, default = SCSI 
	      'usb_dev_transport' => 'BBB', #defines  bDeviceProtocol or bInterfaceProtocol, default = BBB
	   },
=begin
        'flash2' =>  {
        'mount_point' => '/mnt/fd2',
        'size' => 25, #size of the device in units of 10M bytes 
        'fs'   => 'vfat',
        'description' => 'USB Flash Drive Memorex',
        'number_of_partitions' => 1,
        'usb_dev_speed'   => '2.00', 	 #bcdUSB 1.0=low, 1.1=full, 2.0=high
        'usb_dev_release' => '0x0400', #bcdDevice two bytes, default = 0x0316
	      'usb_dev_product' => '0xa4a5', #idProduct two bytes, default = 0xa4a5
	      'usb_dev_vendor' => '0x0525',  #idVendor two bytes,  default = 0x0525
	      'usb_dev_class' => 'Mass Storage', #defines bInterfaceClass, default = Mass Storage 
	      'usb_dev_protocol' => 'SCSI', #defines bDeviceSubClass or bInterfaceSubClass, default = SCSI 
	      'usb_dev_transport' => 'BBB', #defines  bDeviceProtocol or bInterfaceProtocol, default = BBB
	   },
=end
	}
		
	# @file_sizes is an array that specifies the the size of the data files used for io operation
	@file_sizes = ['5', '511', '512',  '513', '50M', '1G']
	
	{
      #'usb_device'     => @usb_devices.keys+['hda1-hda2','hda1-flash1','flash1-flash2'],     #USB device used for the test
      'usb_device'     => @usb_devices.keys+['hda1-hda2','hda1-flash1'],     #USB device used for the test
      'file_size'      => @file_sizes, # size of the for the IO operation
      'test_sequences' => ['connect+format+mkdir+rmdir+write+rename+filechk+move+filechk+properties+delete+chkdsk+delete_all+disconnect','connect+disconnect*2', 'connect+write+disconnect+connect+filechk+disconnect','connect+write+read/write+disconnect','connect+format+delete_all+mkdir+dirchk+write+filechk+read+delete_all+disconnect'], #defines the actions taken by the host on the udb slave. The syntax used is <action 1>+<action 2>+.....+<action e>[*<number of times to execute the sequence>];<action 1>+<action 2>+.....+<action e>[*<number of times to execute the sequence>];......  allowed <action x> values are connect, disconnect, delete_all, write, read, chkdsk, mkdir, delete, rmdir, dirchk, filechk, format, move, rename, properties, and defragment
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
    {}
  end
  # END_USR_CFG get_manual

  # BEG_USR_CFG get_outputs
  def get_outputs(params)
    {
      'paramsChan'     => get_params_chan(params),
      #'usbintfc'       => "#{params['usbintfc']}",
      
      'paramsControl'       => {
      },
      'ext'            => false,
      'bestFinal'      => false,
      'basic'          => false,
      'bft'            => false,
      'reg'            => false,
      'auto'           => true,
      'description'     => "#{params['test_sequences'].capitalize} operation test on #{get_dev_description(params['usb_device'])} with a file of size #{params['file_size']} bytes.",
      'testcaseID'      => "usb_msc_host_func_#{@current_id}",
      'script'          => 'LSP\A-USB\usb_host_msc.rb',
      'configID'        => '..\Config\lsp_usb_host.ini',
      'iter'            => "1",
      #'usbintfc' 				=> ['1','2'],  #are we testing a version 1.1 or 2.0 interface
      
    }
 end
  # END_USR_CFG get_outputs

  private
  
  def get_params_chan(params)
	params_chan = {
	      'usb_device'   =>     params['usb_device'],     	
        'test_sequences' =>   params['test_sequences'],
        'dev_mount_point' =>  get_dev_mount_point(params['usb_device']),
        'dev_fs'          =>  get_dev_fs(params['usb_device']),
        'dev_partitions'  =>  get_dev_partitions(params['usb_device']),  
        'dev_file_size'   =>  get_dev_file_size(params), 	
        'dev_speed' =>   		get_dev_speed(params['usb_device']), 	
        'dev_release' =>   	get_dev_release(params['usb_device']), 
	      'dev_product' =>   	get_dev_product(params['usb_device']), 
	      'dev_vendor' =>    	get_dev_vendor(params['usb_device']), 
	      'dev_class' =>     	get_dev_class(params['usb_device']),
	      'dev_protocol' =>  	get_dev_protocol(params['usb_device']),
	      'dev_transport' => 	get_dev_transport(params['usb_device']),
	      'target_sources' =>   'LSP\Common\usbutils',
	      'dev_description' =>  get_dev_description(params['usb_device']).sub(/\s&\s$/,'').sub(/\s&\s/,';')    # Included for now for connection message box
	}
	params_chan
  end
  
  def get_dev_mount_point(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['mount_point']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_fs(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['fs']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_file_size(params)
      desired_file_size = params['file_size'].sub(/G$/i,'000000000')
	  desired_file_size = desired_file_size.sub(/M$/i,'000000').to_i
  	  params['usb_device'].split('-').map {|dev| 
          backing_file_size = @usb_devices[dev]['size'].to_i*10485760
	      [backing_file_size, desired_file_size].min.to_s.sub(/000000000$/,'G').sub(/000000$/,'M')+';'
	  }.to_s.sub(/;$/,'')
  end
  
  def get_dev_partitions(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['number_of_partitions'].to_s+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_speed(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['usb_dev_speed']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_release(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['usb_dev_release']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_product(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['usb_dev_product']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_vendor(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['usb_dev_vendor']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_class(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['usb_dev_class']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_protocol(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['usb_dev_protocol']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_transport(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['usb_dev_transport']+';'}.to_s.sub(/;$/,'')
  end
  
  def get_dev_description(devices)
      devices.split('-').map {|dev|  @usb_devices[dev]['description']+' & '}.to_s
  end
  
end # Usb_host_mscTestPlan class