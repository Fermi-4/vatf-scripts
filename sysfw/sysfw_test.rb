require File.dirname(__FILE__)+'/../LSP/default_test_module' 
include LspTestScript

def setup
  #super
  @equipment['dut1'].set_api('psp')
end

def run
  expected_resets = @test_params.params_chan.instance_variable_defined?(:@expected_resets) ? @test_params.params_chan.expected_resets[0].to_i :
                    @test_params.instance_variable_defined?(:@var_expected_resets) ? @test_params.var_expected_resets.to_i : 0
  console_timeout = @test_params.params_chan.instance_variable_defined?(:@timeout) ? @test_params.params_chan.timeout[0].to_i :
                    @test_params.instance_variable_defined?(:@var_timeout) ? @test_params.var_timeout.to_i : 120
  SysBootModule::set_sysboot(@equipment['dut1'], '0000')
  @power_handler.reset(@equipment['dut1'].power_port) {
    sleep 3
  }
  @equipment['dut1'].connect({'type' => 'serial'})
  @equipment['dut1'].target.disconnect_bootloader()
  translated_boot_params = setup_host_side()
  @equipment['server1'].send_cmd("stty -F #{@equipment['dut1'].params['bootloader_port']} #{@equipment['dut1'].params['bootloader_serial_params']['baud']} -crtscts")
  s_boot = SysBootModule::get_sysboot_setting(@equipment['dut1'], 'uart')
  SysBootModule::set_sysboot(@equipment['dut1'], s_boot)
  @power_handler.por(@equipment['dut1'].power_port)
  expected_resets.times do 
	load_and_connect(translated_boot_params)
	@equipment['dut1'].target.wait_on_for(@equipment['dut1'].target.bootloader, /CCCC/, console_timeout)
	@equipment['dut1'].target.disconnect_bootloader()
  end
  load_and_connect(translated_boot_params)
  @equipment['dut1'].target.wait_on_for(@equipment['dut1'].target.bootloader, /Net\s*Result:.*?test/, console_timeout)
  sysfw_res = @equipment['dut1'].target.bootloader.response.match(/Net\s*Result:.*?,\s*(\d+)\s*failed.*?test/)

  if sysfw_res == nil
    set_result(FrameworkConstants::Result[:fail], "SYSFW failed, no results found")
  elsif sysfw_res[1] == "0"
    set_result(FrameworkConstants::Result[:pass], sysfw_res[0])
  else
    set_result(FrameworkConstants::Result[:fail], sysfw_res[0])
  end
end

def load_and_connect(params)
  r,w = IO.pipe
  sx_thread = Thread.new {
	Thread.pass
	# Send initial bootloader as xmodem, 2 minute timeout.
	Open3.pipeline("/usr/bin/timeout 120 /usr/bin/sx -k --xmodem #{params['initial_bootloader']}", :in => @equipment['dut1'].params['bootloader_port'], :out => @equipment['dut1'].params['bootloader_port'], :err=>w)
  }
  status = ''
  Timeout::timeout(130) {
	  status = r.read(8)
	  while !status.match(/Bytes\s*Sent:\s*\d+\s/) do
		#puts status #Uncomment to debug
		status += r.read(8)
	  end
  }
  @equipment['dut1'].target.connect_bootloader()
  rescue Timeout::Error => e
    puts "TIMEOUT loading image #{params['initial_bootloader']}"
    @equipment['server1'].log_info("TIMEOUT loading image #{params['initial_bootloader']}")
    raise "TIMEOUT loading image #{params['initial_bootloader']}\n#{e}"
  ensure
    @equipment['server1'].log_info(status)
    w.close()
    r.close()
end

def clean
  super
end

