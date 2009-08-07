
class Usb_slave_mscTestPlan < TestPlan

  def initialize
	super
	@base_bootargs = Hash.new
	@import_only = true
  end
  
  # BEG_USR_CFG setup
  def setup()
 #   @order = 2
    @group_by = ['dsp','host_os']
    @sort_by  = ['dsp','host_os', 'backing_file_type', 'usb_dev_luns']
  end
  # END_USR_CFG setup
  
  # BEG_USR_CFG get_keys
  def get_keys()
    keys = [
      {
        'platform'  => ['dm'],							#Enter the platform used here (string) i.e. 'dm6446'
        'target'    => ['2xx'],
        'os'        => ['linux'],					#Operating system used in the target
        'custom'    => ['usbslave'],				#This defines the usb mode to be slave, do not change
        #'dsp'       => ['static', 'dynamic'],       # 'dsp' key is used to select if kernel uimage statically or dynamically loads the modules. Valid values are static | dynamic
        'dsp'       => ['dynamic'],
        'micro'     => ['dma'],           	# 'micro' key is used to select the operation mode. Valud values are pio | dma | polled
        #'microType' => ['server', 'rtt','lld']    	# 'microType' key is used to select kernel's preemtion mode. Valid values are lld | rtt | server
        'microType' => ['lld']
      },
    ]
  end
  # END_USR_CFG get_keys
  
  # BEG_USR_CFG get_params
  def get_params()
    #@usb_devices is a hash of hashes containing usb device information. Each usb device info hash is accessed by a usb_dev value and contains the following key-value pairs:
    #               	'mount_point' => the target file system node where the device's file system will be mounted (string)
    #		'size' => size of the device in units of 10M bytes
    @usb_devices = 	{'hda1' =>  {
									'mount_point' => '/mnt/hd1', #target file system node where the device will be mounted if it has not been mounted
									'size' => 1000, #size of the device in units of 10M bytes 
								},
					 'hda2' =>  {
									'mount_point' => '/mnt/hd2',
									'size' => 1000, #size of the device in units of 10M bytes 
								},
					 'mmcblk0' => 	{
									'mount_point' => '/mnt/hd1',
									'size' => 180, #size of the device in units of 10M bytes 
								},
					 'nand' =>  {
									'mount_point' => '',
									'size' => 180, #size of the device in units of 10M bytes 
								},
					 'tape' =>  {
									'mount_point' => '',
									'size' => 180, #size of the device in units of 10M bytes 
								},
					 'fd' => 	{
									'mount_point' => '',
									'size' => 0.0512, #size of the device in units of 10M bytes 
								},
					}
					
	# @base_bootargs is a hash that contains the base bootargs associated with each platform type. If a specific bootargs value is required for a type of platform
	# then add another line to this section of syntax @base_bootargs[<platform_type>] = <bootargs_value>, <platform_type> must match a value contained in the array
	# indexed by the 'platform' key defined in the get_keys function, otherwise the default value is used.
	#@base_bootargs.default = 'console\=ttyS0\,115200n8 noinitrd rw ip\=dhcp root\=/dev/nfs nfsroot\=${nfs_root_path}\,nolock mem\=120M'
	@base_bootargs.default = 'mem=116M console=ttyS0,115200n8 root=/dev/nfs rw nfsroot=10.218.103.13:/usr/workdir/filesys ip=dhcp'
    
	# @file_sizes is an array that specifies the the size of the data files used for io operation
	@file_sizes = ['512', '50M', '1G']
	{
    #'usb_device'   => ['hda1', 'hda2', 'mmcblk0', 'nand', 'tape', 'fd'],     #target device used for the test
    'usb_device'   => ['mmcblk0'],
	  'file_size'   => @file_sizes, # size of the for the IO operation
    #'host_os'  => ['win_xp', 'linux', 'win_2k', 'mac'], #Operating system used by the usb host
    'host_os'  => ['win_xp'],
	  #'host_controller' => ['ehci','ohci','uhci'], #host controller interface implementation use ehci for USB 2.0
		#'host_controller' => ['usb0','usb1'], #host controller interface implementation use ehci for USB 2.0
    'host_controller' => ['ehci'], #host controller interface implementation use ehci for USB 2.0
	  'base_backing_file_name' => ['usb_slave'],  #base string used for the name of the backing file used in the test the backing files names used in the test will be <base_backing_file_name>_<usb_device>_lun<0 to usb_dev_luns -1>
	  'host_mount_point' => [''], #host file system node where the device will be mounted, used for linux systems only
	  'backing_file_type' => ['file','device'], #determines if the file storage will be a file on the device or a partition on the device. selecting 'device' makes the test rearrange the device's partitions which causes loss of data
	  'max_backing_file_size' => [180], #maximum size of the backing_file in units of 10M bytes 
	  'test_sequences' => ['connect+disconnect*2','connect+format+disconnect','connect+format+write+read+disconnect;connect+filechk+disconnect'], #defines the actions taken by the host on the udb slave. The syntax used is <action 1>+<action 2>+.....+<action e>[*<number of times to execute the sequence>];<action 1>+<action 2>+.....+<action e>[*<number of times to execute the sequence>];......  allowed <action x> values are connect, disconnect, delete_all, write, read, chkdsk, mkdir, delete, rmdir, dirchk, filechk, format, move, rename, properties, and defragment
	  'usb_dev_stall' => ['default','true','false'], # Boolean to permit the driver to halt bulk endpoints. default = determined according to the type of device (ussually true)
	  'usb_dev_buflen' => ['default','16384'], # buffer size used (will be rounded to a multiple of PAGE_CACHE_SIZE), default = 16384
	  'usb_dev_release' => ['default','0x0400'], #bcdDevice two bytes, default = 0x0316
	  'usb_dev_product' => ['default','0xa4a5'], #idProduct two bytes, default = 0xa4a5
	  'usb_dev_vendor' => ['default','0x0525'],  #idVendor two bytes,  default = 0x0525
	  #'usb_dev_protocol' => ['default','SCSI','RBC','ATAPI','QIC','UFI','8070'], #defines bDeviceSubClass or bInterfaceSubClass, default = SCSI 
	  'usb_dev_protocol' => ['default','SCSI'], #defines bDeviceSubClass or bInterfaceSubClass, default = SCSI 
	  #'usb_dev_transport' => ['default','BBB','CB','CBI'], #defines  bDeviceProtocol or bInterfaceProtocol, default = BBB
	  'usb_dev_transport' => ['default','BBB'], #defines  bDeviceProtocol or bInterfaceProtocol, default = BBB
	  'usb_dev_removable' => ['default','true', 'false'], # boolean for removable media, default = false
	  'usb_dev_luns' => ['default','2'],  # number of backing files, number of luns to support, number in [1, 8], default = 1
	  'usb_dev_read_only' => ['default','true','false'], #booleans for read only access of the luns ( currently only single value that applies to all luns is supported ), default = false	   
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
      
      'paramsControl'       => {
      },
      'ext'            	=> false,
      'bestFinal'      	=> false,
      'basic'          	=> false,
      'bft'            	=> false,
      'reg'            	=> false,
      'auto'           	=> true,
      'description'     => "#{params['test_sequences'].capitalize} operation test with a file of size #{get_file_size(params)} bytes" +
                          " on #{params['usb_device']}.",
      'testcaseID'      => "usb_msc_slave_func_#{@current_id}",
      'script'          => 'LSP\A-USB\usb_slave_msc.rb',
      
      'configID'        => '..\Config\lsp_usb_slave_msc.ini',
      'iter'            => "1",
    }
 end
  # END_USR_CFG get_outputs

  private
  
  def get_params_chan(params)
	params_chan = {
	    'usb_device'   => params['usb_device'],     #target device used for IO operation
		  'dev_mount_point' => get_mount_point(params),
		  'file_size'   => get_file_size(params), # size of the file used for the IO operation
	    'host_os'  => params['host_os'], #Operating system used by the usb host
		  'host_controller' => params['host_controller'],
		  'base_backing_file_name' => params['base_backing_file_name'],
		  'backing_file_size' => get_backing_file_size(params),
		  'host_mount_point' => params['host_mount_point'],
		  'test_sequences' => params['test_sequences'],
		  'usb_dev_stall' => params['usb_dev_stall'],
		  'usb_dev_buflen' => params['usb_dev_buflen'],
		  'usb_dev_release' => params['usb_dev_release'],
		  'usb_dev_product' => params['usb_dev_product'],
		  'usb_dev_vendor' => params['usb_dev_vendor'],
		  'usb_dev_protocol' => params['usb_dev_protocol'],
		  'usb_dev_transport' => params['usb_dev_transport'],
		  'usb_dev_removable' => params['usb_dev_removable'],
		  'usb_dev_luns' => params['usb_dev_luns'],
		  'usb_dev_read_only' => params['usb_dev_read_only'],
		  'backing_file_type' => params['backing_file_type'],
    }
	
	if params['dsp'].downcase.strip == 'static' 
		param_string = ''
		ro_string = ' g_file_storage.ro\=1'
		
		if params['backing_file_type'].strip.downcase != 'device'
			1.upto(params['usb_dev_luns'].to_i-1) do |idx| 
				ro_string +='\,1'
			end
		end
		
		ro_string.gsub!('1','0') if params['usb_dev_read_only'].strip.downcase != 'true' 
		param_string += ro_string if params['usb_dev_read_only'].strip.downcase != 'default'
		
		#if params['usb_dev_removable'].strip.downcase == 'true'
			param_string += ' g_file_storage.removable\=1'
		#elsif params['usb_dev_removable'].strip.downcase == 'false'
			#param_string += ' g_file_storage.removable=0'
		#end
		
		param_string += ' g_file_storage.vendor\='+params['usb_dev_vendor'].strip.downcase if params['usb_dev_vendor'].strip.downcase != 'default'
		
		if params['backing_file_type'].strip.downcase == 'device'
			param_string += ' g_file_storage.luns\=1' if params['usb_dev_luns'].strip.downcase != 'default'
		else
			param_string += ' g_file_storage.luns\='+params['usb_dev_luns'].to_s if params['usb_dev_luns'].strip.downcase != 'default'
		end
		
		param_string += ' g_file_storage.transport\='+params['usb_dev_transport'].strip.downcase if params['usb_dev_transport'].strip.downcase != 'default'
		param_string += ' g_file_storage.protocol\='+params['usb_dev_protocol'].strip.downcase if params['usb_dev_protocol'].strip.downcase != 'default'
		param_string += ' g_file_storage.product\='+params['usb_dev_product'].strip.downcase if params['usb_dev_product'].strip.downcase != 'default'
		param_string += ' g_file_storage.release\='+params['usb_dev_release'].strip.downcase if params['usb_dev_release'].strip.downcase != 'default'
		param_string += ' g_file_storage.buflen\='+params['usb_dev_buflen'].strip.downcase if params['usb_dev_buflen'].strip.downcase != 'default'
		
		if params['usb_dev_stall'].strip.downcase == 'true'
			param_string += ' g_file_storage.stall\=1'
		elsif params['usb_dev_stall'].strip.downcase == 'false'
			param_string += ' g_file_storage.stall\=0'
		end
		params_chan['bootargs'] = @base_bootargs[params['platform']] + param_string
	end
	params_chan
  end
  
  def get_mount_point(params)
	@usb_devices[params['usb_device']]['mount_point']
  end
  
  def get_backing_file_size(params)
	max_file_size = params['max_backing_file_size'].to_i 
	device_size = @usb_devices[params['usb_device']]['size'].to_f
	num_luns = params['usb_dev_luns'].to_i
	if num_luns*max_file_size > device_size
		(device_size/num_luns).floor
	else
		max_file_size
	end
  end
  
  def get_file_size(params)
	backing_file_size = get_backing_file_size(params)*10485760
	desired_file_size = params['file_size'].sub(/G$/i,'000000000')
	desired_file_size = desired_file_size.sub(/M$/i,'000000').to_i
	if backing_file_size < desired_file_size
		size_array = Array.new
		(@file_sizes - [params['file_size']]).each do |current_size|
			a_file_size = current_size.sub(/G$/i,'000000000')
			a_file_size = current_size.sub(/M$/i,'000000').to_i
			size_array << a_file_size if a_file_size < desired_file_size
		end
		size_array.max.to_s.sub(/000000000$/,'G').sub(/000000$/,'M')
	else
		params['file_size']
	end
  end
  
end #END_CLASS
