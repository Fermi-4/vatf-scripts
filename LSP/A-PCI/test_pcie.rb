# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  # dut2->RC board  
  add_equipment('dut2', @equipment['dut1'].params['dut2']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['dut2'], log_path)
  end
  @equipment['dut2'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut2'].power_port)

  # before configuring EP, power down RC
  @equipment['dut2'].shutdown({'power_handler' => @power_handler})

  # boot up dut1 --- EP board
  setup_boards('dut1')
end

def run
  #self.as(LspTestScript).run
  result = 0
  result_msg = ''

  params = {}
  params['num_pfs'] = @test_params.params_chan.instance_variable_defined?(:@num_pfs) ? @test_params.params_chan.num_pfs[0] : '1'   
  params['num_vfs'] = @test_params.params_chan.instance_variable_defined?(:@num_vfs) ? @test_params.params_chan.num_vfs[0] : '0'   
  params['msi_int'] = @test_params.params_chan.instance_variable_defined?(:@msi_interrupts) ? @test_params.params_chan.msi_interrupts[0] : '16'
  params['msix_int'] = @test_params.params_chan.instance_variable_defined?(:@msix_interrupts) ? @test_params.params_chan.msix_interrupts[0] : '16'
  params['num_bars'] = @test_params.params_chan.instance_variable_defined?(:@num_bars) ? @test_params.params_chan.num_bars[0] : '6'   
  params['rw_sizes'] = @test_params.params_chan.instance_variable_defined?(:@rw_sizes) ? @test_params.params_chan.rw_sizes[0] : '1 1024'   
  params['linux_version'] = @equipment['dut1'].get_linux_version
  # option: 'legacy, msi, msix'
  params['int_mode'] = @test_params.params_chan.instance_variable_defined?(:@int_mode) ? @test_params.params_chan.int_mode[0] : 'msi'
  msi_map = {"legacy"=>"0", "msi"=>"1", "msix"=>"2"}

  prepare_ep(params)
  bringup_rc('dut2', '2', params)

  # Run pcie ep tests
  @equipment['dut2'].send_cmd("lspci", @equipment['dut2'].prompt, 10)
  @equipment['dut2'].send_cmd("echo 1 > /sys/bus/pci/rescan", @equipment['dut2'].prompt, 10)
  sleep 1
  @equipment['dut2'].send_cmd("for f in /sys/bus/pci/devices/*/sriov_numvfs; do echo #{params['num_vfs']} > $f; done", @equipment['dut2'].prompt, 10)
  @equipment['dut2'].send_cmd("lspci", @equipment['dut2'].prompt, 10)
  raise "Endpoint is not showing in RC using lspci" if !@equipment['dut2'].response.match(/01:00\.0/i)

  @equipment['dut2'].send_cmd("lspci -vv", @equipment['dut2'].prompt, 10)
  res = check_pcie_speed(@equipment['dut2'].response, @equipment['dut2'].name)
  if res != 0
    report_msg "Test Fail Reason: LnkSta is not at expected speed", "dut2"
    result += res
  end

  @equipment['dut2'].send_cmd("pcitest -h", @equipment['dut2'].prompt, 10)
  raise "pcitest app is missing from filesystem" if @equipment['dut2'].response.match(/command\s+not\s+found/i)

  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 

  if Gem::Version.new(params['linux_version']) >= Gem::Version.new("4.19")
    #@equipment['dut2'].send_cmd("modprobe pci_endpoint_test ", @equipment['dut2'].prompt, 30)
    puts "do not modprobe"
  else
    @equipment['dut2'].send_cmd("rmmod pci_endpoint_test", @equipment['dut2'].prompt, 60)
    @equipment['dut2'].send_cmd("modprobe pci_endpoint_test no_msi=1", @equipment['dut2'].prompt, 30)
  end

  @equipment['dut2'].send_cmd("ls /dev/pci-endpoint-test*", @equipment['dut2'].prompt, 10)
  raise "pci-endpoint-test driver devnode is missing!" if @equipment['dut2'].response.match(/No\s+such\s+file\s+or\s+directory/i)

  # run pcitest for each of pci-endpoint-test
  test_dev_array = @equipment['dut2'].response.scan(/\/dev\/pci-endpoint-test\.\d+/im)
  report_msg "There are #{test_dev_array.length} pci-endpoint-test being created", "dut2"

  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
  @equipment['dut2'].send_cmd("lspci -vv", @equipment['dut2'].prompt, 30)

  test_dev_array.each do |test_dev|
    #next if test_dev.include? "pci-endpoint-test.0"
    report_msg "=== Testing #{test_dev} ===", "dut2"
    # Enable different interrupt
    if Gem::Version.new(params['linux_version']) >= Gem::Version.new("4.19")
      mode = msi_map[params['int_mode']]
      @equipment['dut2'].send_cmd("pcitest -i #{mode} -D #{test_dev}", @equipment['dut2'].prompt, 10)
    end
    if params['int_mode'] == "msi" or params['int_mode'] == "msix"
      @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
      msi_int_before = get_msi_int(@equipment['dut2'].response)
      if msi_int_before == "FAIL"
        report_msg "Test Fail Reason: Could not find intial MSI interrupt number!", "dut2"
        result += 1 
      end
    end

    i = 0
    i = 1 if @equipment['dut1'].name.match(/k2g/i)
    i = 2 if @equipment['dut1'].name.match(/am654x/i)
    while i < params['num_bars'].to_i do
      @equipment['dut2'].send_cmd("pcitest -b #{i} -D #{test_dev}", @equipment['dut2'].prompt, 10)
      if !@equipment['dut2'].response.match(/bar\d+:\s+okay/i)
        report_msg "Test Fail Reason: BAR #{i} test failed", "dut2"
        result += 1
      end
      i += 1
    end

    if params['int_mode'] == 'msi'
      i = 1
      while i <= params['msi_int'].to_i do
        @equipment['dut2'].send_cmd("pcitest -m #{i} -D #{test_dev}", @equipment['dut2'].prompt, 10)
        if !@equipment['dut2'].response.match(/msi\d+:\s+okay/i)
          report_msg "Test Fail Reason: MSI Interrupt #{i} test failed", "dut2" 
          result += 1
        end
        i += 1
      end
    elsif params['int_mode'] == 'msix'
      i = 1
      while i <= msix_int.to_i do
        @equipment['dut2'].send_cmd("pcitest -x #{i} -D #{test_dev}", @equipment['dut2'].prompt, 10)
        if !@equipment['dut2'].response.match(/msi-x\d+:\s+okay/i)
          report_msg "Test Fail Reason: MSI-X Interrupt #{i} test failed", "dut2"
          result += 1
        end
        i += 1
      end
    else # for Legacy IRQ
        @equipment['dut2'].send_cmd("pcitest -l -D #{test_dev}", @equipment['dut2'].prompt, 10)
        if @equipment['dut2'].response.match(/not\s+okay/i)
          report_msg "Test Fail Reason: Legacy Interrupt test failed", "dut2"
          result += 1
        end
    end
    @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
    @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 

    i = 0
    time = Time.now
    test_duration = @test_params.params_chan.instance_variable_defined?(:@test_duration) ? @test_params.params_chan.test_duration[0] : '10'   
    while ((Time.now - time) < test_duration.to_f )
      puts "In loop #{i.to_s}"
      @equipment['dut2'].log_info("====In loop #{i.to_s}====")
      params['rw_sizes'].split(' ').each {|size|
        puts "size is: #{size}"
        @equipment['dut2'].send_cmd("pcitest -w -s #{size} -D #{test_dev}", @equipment['dut2'].prompt, 120)
        if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
          report_msg "Test Fail Reason: Write test w/ #{size} failed", "dut2"
          result += 1
        end
        @equipment['dut2'].send_cmd("pcitest -r -s #{size} -D #{test_dev}", @equipment['dut2'].prompt, 120)
        if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
          report_msg "Test Fail Reason: Read test w/ #{size} failed", "dut2"
          result += 1
        end
        @equipment['dut2'].send_cmd("pcitest -c -s #{size} -D #{test_dev}", @equipment['dut2'].prompt, 120)
        if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
          report_msg "Test Fail Reason: Copy test w/ #{size} test failed", "dut2"
          result += 1
        end
      }
      i += 1
    end

    @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
    @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
    if params['int_mode'] == "msi" or params['int_mode'] == "msix"
      @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
      msi_int_after = get_msi_int(@equipment['dut2'].response)
      if msi_int_after == "FAIL"
        report_msg "Test Fail Reason: Could not find end MSI interrupt number!", "dut2"
        result += 1 
      else
        if msi_int_after.to_i <= msi_int_before.to_i
          result += 1
          report_msg "Test Fail Reason: MSI interrupt was not increased", "dut2"
        end
      end
    end

    # Clear interrupt
    if Gem::Version.new(params['linux_version']) >= Gem::Version.new("4.19")
      mode = msi_map[params['int_mode']]
      @equipment['dut2'].send_cmd("pcitest -e #{mode} -D #{test_dev}", @equipment['dut2'].prompt, 10)
    end

  end # test_dev_array 

  if result == 0 
    set_result(FrameworkConstants::Result[:pass], "Test Pass")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed")
  end

end

def bringup_rc(dut='dut2', img_idx='', params={})
  puts "Bringup RC board #{dut} ..."

  if ! (@equipment["#{dut}"].name =~ /dra7/)
    @power_handler.switch_on(@equipment["#{dut}"].power_port)
    sleep 1
  end
  setup_boards("#{dut}", {'dut_idx' => img_idx})

end

def prepare_ep(params={})
  num_pfs = params['num_pfs']
  num_vfs = params['num_vfs']
  linux_version = params['linux_version']

  # Config EP
  config_fs = "/sys/kernel/config"
  func_driver_name = get_func_driver_name(@equipment['dut1'].name, linux_version)
  func_dir = "#{config_fs}/pci_ep/functions/#{func_driver_name}"
  driver_names = []
  if @equipment['dut1'].params.has_key?("pcie_ctrl_driver_name")
    if @equipment['dut1'].params['pcie_ctrl_driver_name'].kind_of?(Array)
      driver_names = @equipment['dut1'].params['pcie_ctrl_driver_name'] 
    else
      driver_names[0] = @equipment['dut1'].params['pcie_ctrl_driver_name']
    end
  else
    raise "please sepecify 'pcie_ctrl_driver_name' as dut params in bench"
  end
 
  # pcie_ctrl_driver_name can be found using "ls /sys/class/pci_epc"
  for d in driver_names
    @equipment['dut1'].send_cmd("ctrl_driver_name=#{d} ", @equipment['dut1'].prompt, 10)

    for i in 1..num_pfs.to_i do
      fname = "#{d}_pf#{i}"
      setup_ep("#{fname}", func_dir, params) 
      for v in 1..num_vfs.to_i do
        setup_ep("#{d}_vf#{i}_#{v}", func_dir, params) if i <= 4 #Only the 1st 4 PF support VF
        @equipment['dut1'].send_cmd("ln -s #{func_dir}/#{d}_vf#{i}_#{v} #{func_dir}/#{fname}", @equipment['dut1'].prompt, 10) if i <= 4
      end
      @equipment['dut1'].send_cmd("ln -s #{func_dir}/#{fname} #{config_fs}/pci_ep/controllers/${ctrl_driver_name}", @equipment['dut1'].prompt, 10)
      raise "Failed to bind pci-epf-test device to EP controller!" if @equipment['dut1'].response.match(/invalid/i)
    end

  end
  @equipment['dut1'].send_cmd("ls -l #{func_dir}", @equipment['dut1'].prompt, 10) 

  # Start pcie ep
  for d in driver_names
    @equipment['dut1'].send_cmd("ctrl_driver_name=#{d} ", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo 1 > #{config_fs}/pci_ep/controllers/${ctrl_driver_name}/start", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("cat #{config_fs}/pci_ep/controllers/${ctrl_driver_name}/start", @equipment['dut1'].prompt, 2)
    if ! @equipment['dut1'].response.match(/^1/i) 
      raise "Failed to start EP controller #{d}"
    end
  end

end

def setup_ep(func='pf1', func_dir, params)
  func_dir = "#{func_dir}/#{func}"

  @equipment['dut1'].send_cmd("mkdir #{func_dir}", @equipment['dut1'].prompt, 20)
  raise "Failed to create pci-epf-test device!" if @equipment['dut1'].response.match(/can't\s+create\s+directory/i)
  @equipment['dut1'].send_cmd("ls #{func_dir}", @equipment['dut1'].prompt, 10)

  deviceid = get_pci_deviceid(@equipment['dut1'].name)
  @equipment['dut1'].send_cmd("cat #{func_dir}/vendorid", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cat #{func_dir}/interrupt_pin", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("echo 0x104c > #{func_dir}/vendorid", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("echo #{deviceid} > #{func_dir}/deviceid", @equipment['dut1'].prompt, 10)

  msi_int = params['msi_int']
  msix_int = params['msix_int']
  # option: 'legacy, msi, msix'
  int_mode = params['int_mode']
  if Gem::Version.new(params['linux_version']) >= Gem::Version.new("4.19")
    msi_int = '16' if int_mode == 'legacy' #This number no use in this case; but can not be 0
    msix_int = '16' if int_mode == 'legacy' #This number no use in this case; but can not be 0
    @equipment['dut1'].send_cmd("echo #{msi_int} > #{func_dir}/msi_interrupts", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo #{msix_int} > #{func_dir}/msix_interrupts", @equipment['dut1'].prompt, 10)
  else
    @equipment['dut1'].send_cmd("echo #{msi_int} > #{func_dir}/msi_interrupts", @equipment['dut1'].prompt, 10)
  end

end

def check_pcie_speed(log, platform)
  rtn = 0
  case platform
    when /am654|j7/
      expected_speed = "8GT/s"
    else
      expected_speed = "5GT/s"
  end
  rtn = 1 if ! log.match(/LnkSta:\s+Speed\s+#{expected_speed}/i)
  return rtn
end

def get_func_driver_name(platform, linux_version)
  if Gem::Version.new(linux_version) >= Gem::Version.new("4.19")
    rtn = 'pci_epf_test'
  else
    case platform
      when /k2g/
        rtn = 'pci_epf_test_k2g'
      when /am654x/
        rtn = 'pci_epf_test_am6'
      else
        rtn = 'pci_epf_test'
    end
  end
end

def get_msi_int(response)
  #"333:          0          0   ITS-MSI 134742016 Edge      pci-endpoint-test.0"
  if response.match(/:\s+(\d+).*(?:PCI-MSI|ITS-MSI).*pci-endpoint-test/)
    rtn = response.match(/:\s+(\d+).*(?:PCI-MSI|ITS-MSI).*pci-endpoint-test/).captures[0]
    return rtn
  else
    return "FAIL"
  end
end

def clean
  #super
  @power_handler.switch_on(@equipment['dut2'].power_port)
  self.as(LspTestScript).clean
  clean_boards('dut2')
end





