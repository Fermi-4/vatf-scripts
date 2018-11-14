require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../common_utils/common_functions'
require File.dirname(__FILE__)+'/ipc_core_data'

include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
  release_ver   = @test_params.var_build_tag[/^\d\d\.\d\d\.\d\d/]
  release_tag   = @test_params.var_build_tag[/\d\d$/]
  core_id       = @test_params.params_chan.instance_variable_defined?(:@core_id) ? @test_params.params_chan.core_id[0] : "dsp1"
  reload_file   = @test_params.params_chan.instance_variable_defined?(:@reload_file) ? @test_params.params_chan.reload_file[0] : "40800000.dsp"
  platform_name = @equipment['dut1'].params['platform_name']
  evm           = @equipment['dut1'].params['evm']
  #temparary directory to install sdk's and build ipc
  temp_dir      = '/tftpboot/ipc_temp/'
  #ccs_path      = @equipment['dut1'].params['ccs_install_path']

  begin
    #get rtos/linux build urls
    rtos_build  = get_build(release_ver, release_tag, platform_name, evm, 'rtos')
    linux_build = get_build(release_ver, release_tag, platform_name, evm)
    #clean previous installtion and binaries
    cleanup(temp_dir)

    #download rtos/linux sdks
    download_package(rtos_build, temp_dir, 270)
    download_package(linux_build, temp_dir, 270)

    #install rtos/linux sdks
    install_sdk(rtos_build.split('/')[-1], temp_dir)
    install_sdk(linux_build.split('/')[-1], temp_dir, 900)

    #build ipc
    build_ipc(temp_dir+'ti/')
    transfer_to_dut('ipc_temp/ti/ipc_bins.tar', @equipment['server1'].telnet_ip, @equipment['dut1'], 240)

    #run ipc binaries on target
    run_ipc(core_id, reload_file)
    set_result(FrameworkConstants::Result[:pass], "Test Passed.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
  cleanup(temp_dir)
end

def clean
  self.as(LspTestScript).clean
end

#function to run ipc on target
def run_ipc(core_id, reload_file)
  @equipment['dut1'].send_cmd('tar -xvf ipc_bins.tar', @equipment['dut1'].prompt, 60)
  @equipment['dut1'].send_cmd('ls -ltr', @equipment['dut1'].prompt, 10)
  locate_bins()
  #check mpmcl supported, if yes run using mpm load run
  if (@equipment['dut1'].name).include? 'k2'
    mpm_load_run()
  else
    extension = 'xe66'
    extension = 'xem4' if core_id.include? "ipu"
    @equipment['dut1'].send_cmd("ls -l /lib/firmware/", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ln -sf ~/server_#{core_id}.#{extension} /lib/firmware/dra7-#{core_id}-fw.#{extension}",\
                                @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ls -l /lib/firmware/", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("cd /sys/bus/platform/drivers/omap-rproc/; ls -l", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo #{reload_file} > unbind; sleep 5", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("echo #{reload_file} > bind; sleep 5", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("~/app_host #{core_id.upcase}", @equipment['dut1'].prompt, 30)
    if !(@equipment['dut1'].response =~ Regexp.new("(App_exec:\smessage\sreceived)")) or @equipment['dut1'].timeout?
      raise "Failed to match criteria for #{core_id}: 'App_exec: message received'."
    end
  end
end

#function to locate ipc binaries and copy to home directory
def locate_bins()
  @equipment['dut1'].send_cmd("find ./ex02_messageq/ -name '*.xe66' -exec cp {} ~/ \\;", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("find ./ex02_messageq/ -name '*.xem4' -exec cp {} ~/ \\;", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("find ./ex02_messageq/ -name 'app_host' -exec cp {} ~/ \\;", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("ls -ltr", @equipment['dut1'].prompt, 10)
end

#function to run ipc using mpmcl
def mpm_load_run()
  coreid = 0
  for core in get_supported_cores(@equipment['dut1'].name) do
    @equipment['dut1'].send_cmd("ls -l /lib/firmware/keystone-#{core}-fw", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ln -sf ~/server_core#{coreid}.xe66 /lib/firmware/keystone-#{core}-fw", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("ls -l /lib/firmware/keystone-#{core}-fw", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("mpmcl status #{core}", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("mpmcl reset #{core}", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("mpmcl status #{core}", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("mpmcl load #{core} server_core#{coreid}.xe66", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("mpmcl run #{core}", @equipment['dut1'].prompt, 10)
    if !(@equipment['dut1'].response =~ Regexp.new("(run succeeded)")) or @equipment['dut1'].timeout?
      raise "Failed to match criteria for #{core}: 'run succeeded'."
    end
    coreid += 1
  end
end

#function to build ipc linux
def build_ipc(sdk_install_path)
  @equipment['server1'].send_cmd("export TI_RTOS_PATH=#{sdk_install_path};"\
                                 "export PATH_BACKUP=$PATH;"\
                                 "export PATH=#{sdk_install_path}linux-devkit/sysroots/x86_64-arago-linux/usr/bin/:$PATH;"\
                                 "cd #{sdk_install_path};"\
                                 "make ti-ipc-linux;"\
                                 "make ti-ipc-linux-examples;"\
                                 "export PATH=$PATH_BACKUP;"\
                                 "ls #{sdk_install_path}ipc_*/examples/*_linux_elf/ex02_messageq/host/bin/debug;"\
                                 "cd #{sdk_install_path}ipc_*/examples/*_linux_elf/;"\
                                 "tar -cvf #{sdk_install_path}ipc_bins.tar ./ex02_messageq/; ls -ltr",\
                                 @equipment['server1'].prompt, 900)
end

#function for cleanup
def cleanup(dir_to_clean)
  @equipment['server1'].send_sudo_cmd("rm -r #{dir_to_clean}", @equipment['server1'].prompt, 300)
  @equipment['dut1'].send_cmd("rm -r ~/ex02_messageq", @equipment['dut1'].prompt, 60)
  @equipment['dut1'].send_cmd("rm -r ~/ipc_bins.tar", @equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("rm -r ~/server_* ~/app_host", @equipment['dut1'].prompt, 10)
end
