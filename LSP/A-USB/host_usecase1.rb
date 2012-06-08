require File.dirname(__FILE__)+'/../TARGET/dev_test2'

def setup
  connect_to_extra_equipment()
  self.as(LspTargetTestScript).setup
end

def connect_to_extra_equipment
  usb_switch = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usb_port'].keys[0]]
  if usb_switch.respond_to?(:serial_port) && usb_switch.serial_port != nil
    usb_switch.connect({'type'=>'serial'})
  elsif usb_switch.respond_to?(:serial_server_port) && usb_switch.serial_server_port != nil
    usb_switch.connect({'type'=>'serial'})
  else
    raise "You need direct or indirect (using Telnet/Serial Switch) serial port connectivity to the USB switch, Please check your bench file"
  end
end


def run
  time = Time.now
  @eth_ip_addr = get_ip_addr()   # get_ip_addr() is defined at default_target_test.rb
  raise "Can't run the test because DUT does not seem to have an IP address configured" if !@eth_ip_addr
  @equipment['dut1'].target.platform_info.telnet_ip = @eth_ip_addr
  @equipment['dut1'].target.platform_info.telnet_port = 23
  @equipment['dut1'].connect({'type'=>'telnet'})
  @equipment['dut1'].target.telnet.send_cmd("cd /opt/ltp", @equipment['dut1'].prompt, 5)
  @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
  
  raise "Could not change directory to ltp-ddt root location" if @equipment['dut1'].timeout?
  cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
  
  start_usb_transitions(@test_params.params_control.cwait[0].to_i, @test_params.params_control.dwait[0].to_i)
  @stop_test = false
  while ((Time.now - time) < @test_params.params_control.test_duration[0].to_f && !@stop_test )
    @equipment['dut1'].target.telnet.send_cmd("date", @equipment['dut1'].prompt, 5)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    @equipment['dut1'].target.telnet.send_cmd("./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_perf_vfat -s USBHOST_L_PERF_VFAT_0001", @equipment['dut1'].prompt, cmd_timeout)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    if ( @equipment['dut1'].target.telnet.timeout? )
      set_result(FrameworkConstants::Result[:fail], "DUT is either not responding or took more that #{cmd_timeout} seconds to complete the usb write/read test")
      @stop_test = true
      break
    elsif (@stop_test)
      break
    end
  end
  stop_usb_transitions()
  
  set_result(FrameworkConstants::Result[:pass], "No USB errors detected") if !@stop_test
end

def start_usb_transitions(connect_wait, disconnect_wait)
  @usb_sw_thread = Thread.new() {
    i=0
    Thread.pass
    Thread.current["stop"]=false
    # Disconnect usb devices
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
    sleep disconnect_wait
    session_data_pointer = @equipment['dut1'].update_response.length
   
    while(!Thread.current["stop"])
      # Connect
      @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
      sleep connect_wait
      ses_data = @equipment['dut1'].update_response
      enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length]
      @equipment['dut1'].log_info("Iteration #{i}: \n #{enum_data}")
      if ( enum_data.match(/(kernel NULL pointer dereference)|(reset high-speed USB device number \d+ using musb-hdrc)/m) )
        @stop_test = true
        set_result(FrameworkConstants::Result[:fail], "Kernel crash or USB reset errors detected")
        return
      elsif (!enum_data.match(/New USB device found/))
        @stop_test = true
        set_result(FrameworkConstants::Result[:fail], "DUT is no longer detecting USB devices")  
        return
      end
      # Disconnect
      @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
      sleep disconnect_wait
      session_data_pointer = @equipment['dut1'].update_response.length
      i += 1
    end
  
  }
end
  
def stop_usb_transitions()
  if @usb_sw_thread
    @usb_sw_thread["stop"]=true
  end
end
