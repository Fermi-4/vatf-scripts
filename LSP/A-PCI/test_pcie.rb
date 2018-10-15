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
  msi_int = @test_params.params_chan.instance_variable_defined?(:@msi_interrupts) ? @test_params.params_chan.msi_interrupts[0] : '0'
  num_bars = @test_params.params_chan.instance_variable_defined?(:@num_bars) ? @test_params.params_chan.num_bars[0] : '6'   
  rw_sizes = @test_params.params_chan.instance_variable_defined?(:@rw_sizes) ? @test_params.params_chan.rw_sizes[0] : '1 1024'   
  test_duration = @test_params.params_chan.instance_variable_defined?(:@test_duration) ? @test_params.params_chan.test_duration[0] : '60'   
  linux_version = @equipment['dut1'].get_linux_version

  # Config EP
  @equipment['dut1'].send_cmd("cd /sys/kernel/config/pci_ep", @equipment['dut1'].prompt, 10)

  if Gem::Version.new(linux_version) >= Gem::Version.new("4.12")
    func_driver_name = get_func_driver_name(@equipment['dut1'].name) 
    @equipment['dut1'].send_cmd("mkdir functions/#{func_driver_name}/func1", @equipment['dut1'].prompt, 20)
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
  @equipment['dut1'].send_cmd("echo #{msi_int} > msi_interrupts", @equipment['dut1'].prompt, 10)

  if Gem::Version.new(linux_version) >= Gem::Version.new("4.12")
    @equipment['dut1'].send_cmd("cd /sys/kernel/config/pci_ep", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ctrl_driver_name=`ls /sys/class/pci_epc`", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ln -s functions/#{func_driver_name}/func1 controllers/${ctrl_driver_name}", @equipment['dut1'].prompt, 10)
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

  setup_boards('dut2', boot_params2)

  # Run pcie ep tests
  @equipment['dut2'].send_cmd("lspci", @equipment['dut2'].prompt, 10)
  raise "Endpoint is not showing in RC using lspci" if !@equipment['dut2'].response.match(/^01:00\.0/i)
  @equipment['dut2'].send_cmd("lspci -vv", @equipment['dut2'].prompt, 10)
  res = check_pcie_speed(@equipment['dut2'].response, @equipment['dut2'].name)
  result += res
  @equipment['dut2'].send_cmd("pcitest -h", @equipment['dut2'].prompt, 10)
  raise "pcitest app is missing from filesystem" if @equipment['dut2'].response.match(/command\s+not\s+found/i)

  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 

  @equipment['dut2'].send_cmd("rmmod pci_endpoint_test", @equipment['dut2'].prompt, 60)
  if msi_int.to_i >= 1
    @equipment['dut2'].send_cmd("modprobe pci_endpoint_test", @equipment['dut2'].prompt, 30)
    @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
    msi_int_before = get_msi_int(@equipment['dut2'].response)
  else
    @equipment['dut2'].send_cmd("modprobe pci_endpoint_test no_msi=1", @equipment['dut2'].prompt, 30)
  end
  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 

  @equipment['dut2'].send_cmd("lspci -vv", @equipment['dut2'].prompt, 30)
  @equipment['dut2'].send_cmd("ls /dev/pci-endpoint-test*", @equipment['dut2'].prompt, 10)
  raise "pci-endpoint-test driver devnode is missing!" if @equipment['dut2'].response.match(/No\s+such\s+file\s+or\s+directory/i)

  i = 0
  i = 1 if @equipment['dut1'].name.match(/k2g/i)
  i = 2 if @equipment['dut1'].name.match(/am654x/i)
  while i < num_bars.to_i do
    @equipment['dut2'].send_cmd("pcitest -b #{i}", @equipment['dut2'].prompt, 10)
    if !@equipment['dut2'].response.match(/bar\d+:\s+okay/i)
      report_msg "BAR #{i} test failed" 
      result += 1
    end
    i += 1
  end

  if msi_int.to_i >= 1
    i = 1
    while i <= msi_int.to_i do
      @equipment['dut2'].send_cmd("pcitest -m #{i}", @equipment['dut2'].prompt, 10)
      if !@equipment['dut2'].response.match(/msi\d+:\s+okay/i)
        report_msg "MSI Interrupt #{i} test failed" 
        result += 1
      end
      i += 1
    end
  else #msi_int=0 for Legacy IRQ
      @equipment['dut2'].send_cmd("pcitest -l", @equipment['dut2'].prompt, 10)
      if @equipment['dut2'].response.match(/not\s+okay/i)
        report_msg "Legacy Interrupt test failed"
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
        report_msg "Write test w/ #{size} failed" 
        result += 1
      end
      @equipment['dut2'].send_cmd("pcitest -r -s #{size}", @equipment['dut2'].prompt, 120)
      if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
        report_msg "Read test w/ #{size} failed" 
        result += 1
      end
      @equipment['dut2'].send_cmd("pcitest -c -s #{size}", @equipment['dut2'].prompt, 120)
      if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
        report_msg "Copy test w/ #{size} test failed" 
        result += 1
      end
    }
    i += 1
  end

  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut1'].prompt, 5) 
  @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
  if msi_int.to_i >= 1
    @equipment['dut2'].send_cmd("cat /proc/interrupts | grep -i pci", @equipment['dut2'].prompt, 5) 
    msi_int_after = get_msi_int(@equipment['dut2'].response)
    if msi_int_after.to_i <= msi_int_before.to_i
      result += 1
      report_msg "MSI interrupt was not increased"
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
  rtn = 1 if ! log.match(/LnkSta:\s+Speed\s+#{expected_speed},/i)
  return rtn
end

def get_func_driver_name(platform)
  case platform
    when /k2g/
      rtn = 'pci_epf_test_k2g'
    when /am654x/
      rtn = 'pci_epf_test_am6'
    else
      rtn = 'pci_epf_test'
  end
end

def get_msi_int(response)
  rtn = response.match(/:\s+(\d+).*(?:PCI-MSI|ITS-MSI).*pci-endpoint-test/).captures[0]
  return rtn
end

def translate_params2(params)
    new_params = params.clone
    new_params['kernel']     = new_params['kernel2'] ? new_params['kernel2'] :
                             @test_params.instance_variable_defined?(:@kernel2) ? @test_params.kernel2 :
                             ''
    new_params['kernel_dev'] = new_params['kernel2_dev'] ? new_params['kernel2_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@kernel2_dev) ? @test_params.params_chan.kernel2_dev[0] :
                             @test_params.instance_variable_defined?(:@var_kernel2_dev) ? @test_params.var_kernel2_dev :
                             new_params['kernel'] != '' ? 'eth' : 'mmc'

    new_params['kernel_src_dev'] = new_params['kernel2_src_dev'] ? new_params['kernel2_src_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@kernel2_src_dev) ? @test_params.params_chan.kernel2_src_dev[0] :
                             @test_params.instance_variable_defined?(:@var_kernel2_src_dev) ? @test_params.var_kernel2_src_dev :
                             new_params['kernel'] != '' ? 'eth' : 'mmc'

    new_params['kernel_image_name'] = new_params['kernel2_image_name'] ? new_params['kernel2_image_name'] :
                             @test_params.instance_variable_defined?(:@var_kernel2_image_name) ? @test_params.var_kernel2_image_name :
                             new_params['kernel'] != '' ? File.basename(new_params['kernel']) : 'uImage'
    new_params['kernel_modules'] = new_params['kernel2_modules'] ? new_params['kernel2_modules'] :
                             @test_params.instance_variable_defined?(:@kernel2_modules) ? @test_params.kernel2_modules :
                             ''
    new_params['dtb']        = new_params['dtb2'] ? new_params['dtb2'] :
                             @test_params.instance_variable_defined?(:@dtb2) ? @test_params.dtb2 :
                             @test_params.instance_variable_defined?(:@dtb2_file) ? @test_params.dtb2_file :
                             ''
    new_params['dtb_dev']    = new_params['dtb2_dev'] ? new_params['dtb2_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@dtb2_dev) ? @test_params.params_chan.dtb2_dev[0] :
                             @test_params.instance_variable_defined?(:@var_dtb2_dev) ? @test_params.var_dtb2_dev :
                             new_params['dtb'] != '' ? 'eth' : 'none'

    new_params['dtb_src_dev']    = new_params['dtb2_src_dev'] ? new_params['dtb2_src_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@dtb2_src_dev) ? @test_params.params_chan.dtb2_src_dev[0] :
                             @test_params.instance_variable_defined?(:@var_dtb2_src_dev) ? @test_params.var_dtb2_src_dev :
                             new_params['dtb'] != '' ? 'eth' : 'none'

    new_params['dtb_image_name'] = new_params['dtb2_image_name'] ? new_params['dtb2_image_name'] :
                             @test_params.instance_variable_defined?(:@var_dtb2_image_name) ? @test_params.var_dtb2_image_name :
                             File.basename(new_params['dtb'])

    @test_params.instance_variables.each{|k|
        if k.to_s.match(/dtbo2_\d+/)
            key_name = k.to_s.gsub(/[@:]/,'').gsub(/dtbo2_/,'dtbo_')
            new_params[key_name] = @test_params.instance_variable_get(k)
            new_params[key_name+'_dev'] = 'eth'
            new_params[key_name+'_src_dev'] = 'eth'
        end
    }

    new_params['fs']         = new_params['fs2'] ? new_params['fs2'] :
                             @test_params.instance_variable_defined?(:@fs2) ? @test_params.fs2 :
                             @test_params.instance_variable_defined?(:@nfs2) ? @test_params.nfs2 :
                             @test_params.instance_variable_defined?(:@ramfs2) ? @test_params.ramfs2 :
                             ''
    new_params['fs_dev']     = new_params['fs2_dev'] ? new_params['fs2_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@fs2_dev) ? @test_params.params_chan.fs2_dev[0] :
                             @test_params.instance_variable_defined?(:@var_fs2_dev) ? @test_params.var_fs2_dev : 'mmc'
    new_params['fs_src_dev']     = new_params['fs2_src_dev'] ? new_params['fs2_src_dev'] :
                             @test_params.params_chan.instance_variable_defined?(:@fs2_src_dev) ? @test_params.params_chan.fs2_src_dev[0] :
                             @test_params.instance_variable_defined?(:@var_fs2_src_dev) ? @test_params.var_fs2_src_dev :
                             new_params['fs'] != '' ? 'eth' : 'mmc'
    new_params['fs_type']    = new_params['fs2_type'] ? new_params['fs2_type'] :
                             @test_params.params_chan.instance_variable_defined?(:@fs2_type) ? @test_params.params_chan.fs2_type[0] :
                             @test_params.instance_variable_defined?(:@var_fs2_type) ? @test_params.var_fs2_type :
                             @test_params.instance_variable_defined?(:@nfs2) || @test_params.instance_variable_defined?(:@var_nfs2) ? 'nfs' :
                             @test_params.instance_variable_defined?(:@ramfs2) ? 'ramfs' :
                             'mmcfs'
    new_params['fs_image_name'] = new_params['fs2_image_name'] ? new_params['fs2_image_name'] :
                             @test_params.instance_variable_defined?(:@var_fs2_image_name) ? @test_params.var_fs2_image_name :
                             new_params['fs_type'] != 'nfs' ? File.basename(new_params['fs']) : ''
     
    new_params 
end

def clean
  #super
  self.as(LspTestScript).clean
  clean_boards('dut2')
end





