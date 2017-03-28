# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  # boot up dut1 --- EP board
  self.as(LspTestScript).setup
  # dut2->RC board  
  add_equipment('dut2', @equipment['dut1'].params['rc']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['rc'], log_path)
  end
  @equipment['dut2'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut2'].power_port)
end

def run
  #self.as(LspTestScript).run
  result = 0
  result_msg = ''
  msi_int = @test_params.params_chan.instance_variable_defined?(:@msi_interrupts) ? @test_params.params_chan.msi_interrupts[0] : '0'
  num_bars = @test_params.params_chan.instance_variable_defined?(:@num_bars) ? @test_params.params_chan.num_bars[0] : '6'   
  rw_sizes = @test_params.params_chan.instance_variable_defined?(:@rw_sizes) ? @test_params.params_chan.rw_sizes[0] : '1 1024'   
  test_duration = @test_params.params_chan.instance_variable_defined?(:@test_duration) ? @test_params.params_chan.test_duration[0] : '60'   
  # before configuring EP, power down RC
  @equipment['dut2'].shutdown({'power_handler' => @power_handler})

  # Config EP
  @equipment['dut1'].send_cmd("cd /sys/kernel/config/pci_ep", @equipment['dut1'].prompt, 20)

  @equipment['dut1'].send_cmd("fun_driver_name=`ls /sys/bus/pci-epf/drivers`", @equipment['dut1'].prompt, 20)
  epf_dir = "dev/epf/"
  #epf_dir = "" # 4.4kernel
  @equipment['dut1'].send_cmd("mkdir -p #{epf_dir}${fun_driver_name}.0", @equipment['dut1'].prompt, 20)
  #@equipment['dut1'].send_cmd("cd dev/epf/${fun_driver_name}.0", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("ls #{epf_dir}${fun_driver_name}.0", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("cat #{epf_dir}${fun_driver_name}.0/vendorid", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("cat #{epf_dir}${fun_driver_name}.0/interrupt_pin", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("echo 0x104c > #{epf_dir}${fun_driver_name}.0/vendorid", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("echo 0xb500 > #{epf_dir}${fun_driver_name}.0/deviceid", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("echo #{msi_int} > #{epf_dir}${fun_driver_name}.0/msi_interrupts", @equipment['dut1'].prompt, 20)
  #@equipment['dut1'].send_cmd("cd /sys/kernel/config/pci_ep", @equipment['dut1'].prompt, 20)
  epc_dir = "dev/"
  #epc_dir = "#{epf_dir}${fun_driver_name}.0/" # 4.4 kernel
  @equipment['dut1'].send_cmd("ctrl_driver_name=`ls /sys/class/pci_epc`", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("echo \"${ctrl_driver_name}\" > #{epc_dir}epc", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("cat #{epc_dir}epc", @equipment['dut1'].prompt, 20)
  if ! @equipment['dut1'].response.match(/pcie_ep/i) 
    @power_handler.switch_on(@equipment['dut2'].power_port)
    raise "Failed to setup PCIe EP"
  end

  puts "Bringup RC board..."

  params2 = {'platform'=>@equipment['dut2'].name}
  boot_params2 = translate_params2(params2)

  setup_boards('dut2', boot_params2)

  # Run pcie ep tests
  @equipment['dut2'].send_cmd("lspci", @equipment['dut2'].prompt, 10)
  raise "Endpoint is not showing in RC using lspci" if !@equipment['dut2'].response.match(/^01:00\.0/i)
  @equipment['dut2'].send_cmd("lspci -vv", @equipment['dut2'].prompt, 10)
  @equipment['dut2'].send_cmd("pcitest -h", @equipment['dut2'].prompt, 10)
  raise "pcitest app is missing from filesystem" if @equipment['dut2'].response.match(/command\s+not\s+found/i)
  @equipment['dut2'].send_cmd("ls /dev/pci-endpoint-test*", @equipment['dut2'].prompt, 10)
  raise "pci-endpoint-test driver devnode is missing!" if @equipment['dut2'].response.match(/No\s+such\s+file\s+or\s+directory/i)

  i = 0
  while i < num_bars.to_i do
    @equipment['dut2'].send_cmd("pcitest -b #{i}", @equipment['dut2'].prompt, 10)
    if !@equipment['dut2'].response.match(/bar\d+:\s+okay/i)
      result_msg += result_msg + "BAR #{i} test failed" 
      result += 1
    end
    i += 1
  end

  if msi_int.to_i >= 1
    i = 1
    while i <= msi_int.to_i do
      @equipment['dut2'].send_cmd("pcitest -m #{i}", @equipment['dut2'].prompt, 10)
      if !@equipment['dut2'].response.match(/msi\d+:\s+okay/i)
        result_msg += result_msg + "MSI Interrupt #{i} test failed" 
        result += 1
      end
      i += 1
    end
  else #msi_int=0 for Legacy IRQ
      @equipment['dut2'].send_cmd("pcitest -l", @equipment['dut2'].prompt, 10)
      if @equipment['dut2'].response.match(/not\s+okay/i)
        result_msg += result_msg + "Legacy Interrupt test failed"
        result += 1
      end
  end

  i = 0
  time = Time.now
  while ((Time.now - time) < test_duration.to_f )
    puts "In loop #{i.to_s}"
    @equipment['dut2'].log_info("====In loop #{i.to_s}====")
    rw_sizes.split(' ').each {|size|
      puts "size is: #{size}"
      @equipment['dut2'].send_cmd("pcitest -w -s #{size}", @equipment['dut2'].prompt, 120)
      if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
        result_msg += result_msg + "Write test w/ #{size} failed" 
        result += 1
      end
      @equipment['dut2'].send_cmd("pcitest -r -s #{size}", @equipment['dut2'].prompt, 120)
      if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
        result_msg += result_msg + "Read test w/ #{size} failed" 
        result += 1
      end
      @equipment['dut2'].send_cmd("pcitest -c -s #{size}", @equipment['dut2'].prompt, 120)
      if @equipment['dut2'].response.match(/not\s+okay/i) || ! @equipment['dut2'].response.match(/okay/i)
        result_msg += result_msg + "Copy test w/ #{size} test failed" 
        result += 1
      end
    }
    i += 1
  end

  if result == 0 
    set_result(FrameworkConstants::Result[:pass], "Test Pass")
  else
    set_result(FrameworkConstants::Result[:fail], result_msg)
  end

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





