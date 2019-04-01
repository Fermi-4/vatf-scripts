# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  # dut2->RC board  
  add_equipment('dut2', @equipment['dut1'].params['rc']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['rc'], log_path)
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
  msi_int = @test_params.params_chan.instance_variable_defined?(:@msi_interrupts) ? @test_params.params_chan.msi_interrupts[0] : '16'
  num_bars = @test_params.params_chan.instance_variable_defined?(:@num_bars) ? @test_params.params_chan.num_bars[0] : '6'   
  rw_sizes = @test_params.params_chan.instance_variable_defined?(:@rw_sizes) ? @test_params.params_chan.rw_sizes[0] : '1 1024'   
  test_duration = @test_params.params_chan.instance_variable_defined?(:@test_duration) ? @test_params.params_chan.test_duration[0] : '60'   
  linux_version = @equipment['dut1'].get_linux_version
  # option: 'legacy, msi, msix'
  int_mode = @test_params.params_chan.instance_variable_defined?(:@int_mode) ? @test_params.params_chan.int_mode[0] : 'msi'
  msi_map = {"legacy"=>"0", "msi"=>"1", "msix"=>"2"}

  # Config EP
  @equipment['dut1'].send_cmd("cd /sys/kernel/config/pci_ep", @equipment['dut1'].prompt, 10)

  if Gem::Version.new(linux_version) >= Gem::Version.new("4.12")
    func_driver_name = get_func_driver_name(@equipment['dut1'].name, linux_version) 
    @equipment['dut1'].send_cmd("mkdir functions/#{func_driver_name}/func1", @equipment['dut1'].prompt, 20)
    raise "Failed to create pci-epf-test device!" if @equipment['dut1'].response.match(/can't\s+create\s+directory/i)
    @equipment['dut1'].send_cmd("ls functions/#{func_driver_name}/func1", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("cd functions/#{func_driver_name}/func1", @equipment['dut1'].prompt, 10)
  elsif Gem::Version.new(linux_version) >= Gem::Version.new("4.9")
    @equipment['dut1'].send_cmd("fun_driver_name=`ls /sys/bus/pci-epf/drivers`", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("fun_driver_name=${fun_driver_name}_k2g", @equipment['dut1'].prompt, 10) if @equipment['dut1'].name.match(/k2g/i)
    epf_dir = "dev/epf/"
    #epf_dir = "" # 4.4kernel
    @equipment['dut1'].send_cmd("mkdir -p #{epf_dir}${fun_driver_name}.0", @equipment['dut1'].prompt, 20)
    @equipment['dut1'].send_cmd("ls #{epf_dir}${fun_driver_name}.0", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("cd #{epf_dir}${fun_driver_name}.0", @equipment['dut1'].prompt, 10)
  else
    raise "There is no test support for #{linux_version} kernel"
  end

  deviceid = get_pci_deviceid(@equipment['dut1'].name)
  @equipment['dut1'].send_cmd("cat vendorid", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cat interrupt_pin", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("echo 0x104c > vendorid", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("echo #{deviceid} > deviceid", @equipment['dut1'].prompt, 10)
  if Gem::Version.new(linux_version) >= Gem::Version.new("4.19")
    msi_int = '16' if int_mode == 'legacy' #This number no use in this case; but can not be 0
    @equipment['dut1'].send_cmd("echo #{msi_int} > msi_interrupts", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo #{msi_int} > msix_interrupts", @equipment['dut1'].prompt, 10)
  else
    @equipment['dut1'].send_cmd("echo #{msi_int} > msi_interrupts", @equipment['dut1'].prompt, 10)
  end

  if Gem::Version.new(linux_version) >= Gem::Version.new("4.12")
    @equipment['dut1'].send_cmd("cd /sys/kernel/config/pci_ep", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ctrl_driver_name=`ls /sys/class/pci_epc`", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ln -s functions/#{func_driver_name}/func1 controllers/${ctrl_driver_name}", @equipment['dut1'].prompt, 10)
    raise "Failed to bind pci-epf-test device to EP controller!" if @equipment['dut1'].response.match(/invalid/i)
    @equipment['dut1'].send_cmd("echo 1 > controllers/${ctrl_driver_name}/start", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("cat controllers/${ctrl_driver_name}/start", @equipment['dut1'].prompt, 10)
    if ! @equipment['dut1'].response.match(/^1/i) 
      @power_handler.switch_on(@equipment['dut2'].power_port)
      raise "Failed to setup PCIe EP"
    end

  elsif Gem::Version.new(linux_version) >= Gem::Version.new("4.9")
    epc_dir = "dev/"
    #epc_dir = "#{epf_dir}${fun_driver_name}.0/" # 4.4 kernel
    @equipment['dut1'].send_cmd("cd /sys/kernel/config/pci_ep", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ctrl_driver_name=`ls /sys/class/pci_epc`", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo \"${ctrl_driver_name}\" > #{epc_dir}epc", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("cat #{epc_dir}epc", @equipment['dut1'].prompt, 10)
    if ! @equipment['dut1'].response.match(/pcie_ep/i) 
      @power_handler.switch_on(@equipment['dut2'].power_port)
      raise "Failed to setup PCIe EP"
    end

  else
    raise "There is no test support for #{linux_version} kernel"
  end

  puts "Bringup RC board..."

  params2 = {'platform'=>@equipment['dut2'].name}
  boot_params2 = translate_params2(params2)

  @power_handler.switch_on(@equipment['dut2'].power_port)
  sleep 1
  setup_boards('dut2', boot_params2)

  # Run pcie ep tests
  @equipment['dut2'].send_cmd("echo 1 > /sys/bus/pci/rescan", @equipment['dut2'].prompt, 10)
  sleep 1
  @equipment['dut2'].send_cmd("lspci", @equipment['dut2'].prompt, 10)
  raise "Endpoint is not showing in RC using lspci" if !@equipment['dut2'].response.match(/^01:00\.0/i)
  @equipment['dut2'].send_cmd("lspci -vv", @equipment['dut2'].prompt, 10)
  res = check_pcie_speed(@equipment['dut2'].response, @equipment['dut2'].name)
  if res != 0
    report_msg "LnkSta is not at expected speed" "dut2"
    result += res
  end
  @equipment['dut2'].send_cmd("pcitest -h", @equipment['dut2'].prompt, 10)
  raise "pcitest app is missing from filesystem" if @equipment['dut2'].response.match(/command\s+not\s+found/i)

  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 

  @equipment['dut2'].send_cmd("rmmod pci_endpoint_test", @equipment['dut2'].prompt, 60)
  if int_mode == "msi" or int_mode == "msix"
    @equipment['dut2'].send_cmd("modprobe pci_endpoint_test", @equipment['dut2'].prompt, 30)
    @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
    msi_int_before = get_msi_int(@equipment['dut2'].response)
    if msi_int_before == "FAIL"
      report_msg "Could not find MSI interrupt number!" "dut2"
      result += 1 
    end
  else
    if Gem::Version.new(linux_version) >= Gem::Version.new("4.19")
      @equipment['dut2'].send_cmd("modprobe pci_endpoint_test ", @equipment['dut2'].prompt, 30)
    else
      @equipment['dut2'].send_cmd("modprobe pci_endpoint_test no_msi=1", @equipment['dut2'].prompt, 30)
    end
  end
  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 

  @equipment['dut2'].send_cmd("ls /dev/pci-endpoint-test*", @equipment['dut2'].prompt, 10)
  raise "pci-endpoint-test driver devnode is missing!" if @equipment['dut2'].response.match(/No\s+such\s+file\s+or\s+directory/i)

  # Enable different interrupt
  if Gem::Version.new(linux_version) >= Gem::Version.new("4.19")
    mode = msi_map[int_mode]
    @equipment['dut2'].send_cmd("pcitest -i #{mode}", @equipment['dut2'].prompt, 10)
  end

  @equipment['dut2'].send_cmd("lspci -vv", @equipment['dut2'].prompt, 30)

  i = 0
  i = 1 if @equipment['dut1'].name.match(/k2g/i)
  i = 2 if @equipment['dut1'].name.match(/am654x/i)
  while i < num_bars.to_i do
    @equipment['dut2'].send_cmd("pcitest -b #{i}", @equipment['dut2'].prompt, 10)
    if !@equipment['dut2'].response.match(/bar\d+:\s+okay/i)
      report_msg "BAR #{i} test failed" "dut2"
      result += 1
    end
    i += 1
  end

  if int_mode == 'msi'
    i = 1
    while i <= msi_int.to_i do
      @equipment['dut2'].send_cmd("pcitest -m #{i}", @equipment['dut2'].prompt, 10)
      if !@equipment['dut2'].response.match(/msi\d+:\s+okay/i)
        report_msg "MSI Interrupt #{i} test failed" "dut2" 
        result += 1
      end
      i += 1
    end
  elsif int_mode == 'msix'
    i = 1
    while i <= msi_int.to_i do
      @equipment['dut2'].send_cmd("pcitest -x #{i}", @equipment['dut2'].prompt, 10)
      if !@equipment['dut2'].response.match(/msi-x\d+:\s+okay/i)
        report_msg "MSI-X Interrupt #{i} test failed" "dut2"
        result += 1
      end
      i += 1
    end
  else # for Legacy IRQ
      @equipment['dut2'].send_cmd("pcitest -l", @equipment['dut2'].prompt, 10)
      if @equipment['dut2'].response.match(/not\s+okay/i)
        report_msg "Legacy Interrupt test failed" "dut2"
        result += 1
      end
  end
  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 

  i = 0
  time = Time.now
  while ((Time.now - time) < test_duration.to_f )
    puts "In loop #{i.to_s}"
    @equipment['dut2'].log_info("====In loop #{i.to_s}====")
    rw_sizes.split(' ').each {|size|
      puts "size is: #{size}"
      @equipment['dut2'].send_cmd("pcitest -w -s #{size}", @equipment['dut2'].prompt, 120)
      if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
        report_msg "Write test w/ #{size} failed" "dut2"
        result += 1
      end
      @equipment['dut2'].send_cmd("pcitest -r -s #{size}", @equipment['dut2'].prompt, 120)
      if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
        report_msg "Read test w/ #{size} failed" "dut2"
        result += 1
      end
      @equipment['dut2'].send_cmd("pcitest -c -s #{size}", @equipment['dut2'].prompt, 120)
      if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
        report_msg "Copy test w/ #{size} test failed" "dut2"
        result += 1
      end
    }
    i += 1
  end

  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
  if int_mode == "msi" or int_mode == "msix"
    @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
    msi_int_after = get_msi_int(@equipment['dut2'].response)
    if msi_int_after == "FAIL"
      report_msg "Could not find MSI interrupt number!" "dut2"
      result += 1 
    else
      if msi_int_after.to_i <= msi_int_before.to_i
        result += 1
        report_msg "MSI interrupt was not increased" "dut2"
      end
    end
  end

  if result == 0 
    set_result(FrameworkConstants::Result[:pass], "Test Pass")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed")
  end

end

def check_pcie_speed(log, platform)
  rtn = 0
  case platform
    when /am654/
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
  if response.match(/:\s+(\d+).*(?:PCI-MSI|ITS-MSI).*pci-endpoint-test/)
    rtn = response.match(/:\s+(\d+).*(?:PCI-MSI|ITS-MSI).*pci-endpoint-test/).captures[0]
    return rtn
  else
    return "FAIL"
  end
end

def clean
  #super
  self.as(LspTestScript).clean
  clean_boards('dut2')
end





