require File.dirname(__FILE__)+'/../LSP/default_test_module' 
include LspTestScript

def setup
  #super
  @equipment['dut1'].set_api('psp')
end

def run
  SysBootModule::set_sysboot(@equipment['dut1'], '0000')
  @power_handler.reset(@equipment['dut1'].power_port) {
    sleep 3
  }
  @equipment['dut1'].connect({'type' => 'serial'})
  @equipment['dut1'].target.disconnect_bootloader()
  translated_boot_params = setup_host_side()
  @equipment['server1'].send_cmd("stty -F #{@equipment['dut1'].params['bootloader_port']} #{@equipment['dut1'].params['bootloader_serial_params']['baud']} -crtscts")
  # Send initial bootloader as xmodem, 2 minute timeout.
  s_boot = SysBootModule::get_sysboot_setting(@equipment['dut1'], 'uart')
  SysBootModule::set_sysboot(@equipment['dut1'], s_boot)
  @power_handler.por(@equipment['dut1'].power_port)
  @equipment['server1'].send_cmd(create_uart_load_script(translated_boot_params), /Transfer complete/, timeout=240)
  if @equipment['server1'].timeout?
	set_result(FrameworkConstants::Result[:fail], "SYSFW image transfer failed")
	return
  end
  @equipment['dut1'].target.connect_bootloader()
  @equipment['dut1'].target.wait_on_for(@equipment['dut1'].target.bootloader, /Net\s*Result:.*?test/, 120)
  sysfw_res = @equipment['dut1'].target.bootloader.response.match(/Net\s*Result:.*?,\s*(\d+)\s*failed.*?test/)

  if sysfw_res == nil
    set_result(FrameworkConstants::Result[:fail], "SYSFW failed, no results found")
  elsif sysfw_res[1] == "0"
    set_result(FrameworkConstants::Result[:pass], sysfw_res[0])
  else
    set_result(FrameworkConstants::Result[:fail], sysfw_res[0])
  end
end

def create_uart_load_script(params)
  script = File.join(SiteInfo::LINUX_TEMP_FOLDER,@test_params.staf_service_name.to_s,'sysfw_load.sh')
  File.open(script, "w") do |file|
    sleep 1
    file.puts "#!/bin/bash"
    # Run stty to set the baud rate.
    file.puts "stty -F #{@equipment['dut1'].params['bootloader_port']} #{@equipment['dut1'].params['bootloader_serial_params']['baud']} -crtscts"
    # Send initial bootloader as xmodem, 2 minute timeout.
    file.puts "/usr/bin/timeout 120 /usr/bin/sx -k --xmodem #{params['initial_bootloader']} < #{@equipment['dut1'].params['bootloader_port']} > #{@equipment['dut1'].params['bootloader_port']}"
    # If we timeout or don't return cleanly (transfer failed), return 1
    file.puts "if [ $? -ne 0 ]; then exit 1; fi"
  end
  File.chmod(0755, script)
  script
end

def clean
  super
end

