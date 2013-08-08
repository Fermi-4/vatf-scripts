require File.dirname(__FILE__)+'/../TARGET/dev_test2'
require File.dirname(__FILE__)+'/usb_tree_util'

def setup
  @equipment['dut1'].set_api('psp')
  connect_to_extra_equipment()
  self.as(LspTargetTestScript).setup
end

# Goal is to run ltp test on device defined as transaction_device in
# test paramter while parallelly running disconnect and connect transitions
# on device defined as transition_device in test parameter
# Description of test parameters:
# test_duration=> total test duration
#timeout=>Timeout for LTP test
#cwait=> Waittime after connect
#dwait=> Wait time after disconnect
#transition_dev_loc=> Location of device on which transition will be performed - example, hub_hub_hub_hub_hub_hid-mouse
#transition_enum_string=> Enumeration strings to check for device for transition, example - USB\s+HID
#transaction_dev_loc=> Device location on tree for device on which LTP test is to be performed example - hub_msc
#transaction_dev_type=> Type of device - example-msc
#port_name=>name of port to identify tree - example, usbhost_ehci
#port_num=> port number, example - 0
def run
  time = Time.now
  device = @test_params.params_control.transaction_dev_loc[0]
  device_type = @test_params.params_control.transaction_dev_type[0]
  # port name would be a test case parameter for example usbhost-ehci, port number would be 0 or 1, by default port number will be 0
  port_name = @test_params.params_control.port_name[0]
  port_num = @test_params.params_control.port_num[0].to_i
  switch_port_array = []
  switch_port_array = determine_switch_port(device, port_name, port_num)
  puts "Switch port array for device #{device} is #{switch_port_array}\n"
  connect_device(switch_port_array)
  sleep @test_params.params_control.cwait[0].to_i
  test_cmd = Hash.new
  test_cmd = {'msc'=>"./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_perf_vfat -s USBHOST_S_PERF_VFAT_0001 ",
              'audio' =>"./runltp -P #{@equipment['dut1'].name} -f  ddt/usbhost_audio -s USBHOST_S_FUNC_AUDIO_LOOPBACK_ACCESSTYPE_NONINTER_01 ",
              'video' => "./runltp -P #{@equipment['dut1'].name} -f  ddt/usbhost_video -s USBHOST_M_FUNC_VIDEO_640_480 ",
              'hid-mouse' => "./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_hid_mouse -s USBHOST_L_FUNC_HID_Mouse_Detection_Test ", 
              'hid-keyboard' => "./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_hid_keyboard -s USBHOST_S_FUNC_HID_Keyboard_Detection_Test "
              }
 test_command = test_cmd[device_type]

  @eth_ip_addr = get_ip_addr()   # get_ip_addr() is defined at default_target_test.rb
  raise "Can't run the test because DUT does not seem to have an IP address configured" if !@eth_ip_addr
  @equipment['dut1'].target.platform_info.telnet_ip = @eth_ip_addr
  @equipment['dut1'].target.platform_info.telnet_port = 23
  @equipment['dut1'].connect({'type'=>'telnet'})
  @equipment['dut1'].target.telnet.send_cmd("cd /opt/ltp", @equipment['dut1'].prompt, 5)
  @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
  
  raise "Could not change directory to ltp-ddt root location" if @equipment['dut1'].timeout?
  cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
  # port name would be a test case parameter for example usbhost-ehci, port number would be 0 or 1, by default port number will be 0
  start_usb_transitions(@test_params.params_control.cwait[0].to_i, @test_params.params_control.dwait[0].to_i, port_name, port_num)
  @stop_test = false
  iteration = 0
  while ((Time.now - time) < @test_params.params_control.test_duration[0].to_f && !@stop_test )
    iteration = iteration+1
    puts "Iteration is #{iteration}\n"
    @equipment['dut1'].target.telnet.send_cmd("date", @equipment['dut1'].prompt, 5)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    #@equipment['dut1'].target.telnet.send_cmd("./runltp -P #{@equipment['dut1'].name} -f ddt/usbhost_perf_vfat -s USBHOST_L_PERF_VFAT_0001", @equipment['dut1'].prompt, cmd_timeout)
   session_data_pointer = @equipment['dut1'].target.telnet.update_response.length
    @equipment['dut1'].target.telnet.send_cmd(test_command, @equipment['dut1'].prompt, 600)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    ses_data = @equipment['dut1'].target.telnet.update_response
    enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length] 
    if ( @equipment['dut1'].target.telnet.timeout? )
      set_result(FrameworkConstants::Result[:fail], "DUT is either not responding or took more than #{cmd_timeout} seconds to complete the usb transaction test. Iteration is #{iteration}")
      return
      @stop_test = true
      break
    elsif (enum_data.match(/FAIL /i) )
      set_result(FrameworkConstants::Result[:fail], "Check LTP log for fail string and iteration is #{iteration}")
      return
    elsif (@stop_test)
      break
    end
  end
  stop_usb_transitions()
  
  set_result(FrameworkConstants::Result[:pass], "No USB errors detected") if !@stop_test
end

def start_usb_transitions(connect_wait, disconnect_wait, port_name, port_num)
  device = @test_params.params_control.transition_dev_loc[0]
  switch_port_array = []
  switch_port_array = determine_switch_port(device, port_name, port_num)

  @usb_sw_thread = Thread.new() {
    i=0
    Thread.pass
    Thread.current["stop"]=false
    # Disconnect usb device - leaf device only to prevent transaction device from being affected by any common parents between transaction device and transition device

    disconnect_leaf_device(switch_port_array)
    sleep disconnect_wait
    session_data_pointer = @equipment['dut1'].update_response.length
    iteration = 0
    while(!Thread.current["stop"])
      # Connect
      iteration = iteration+1
      connect_device(switch_port_array)
      sleep connect_wait
      ses_data = @equipment['dut1'].update_response
      enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length]
      @equipment['dut1'].log_info("Iteration #{i}: \n #{enum_data}")
      if ( enum_data.match(/(kernel NULL pointer dereference)|(reset \w+-speed USB device number \d+)/m) )
        @stop_test = true
        set_result(FrameworkConstants::Result[:fail], "Kernel crash or USB reset errors detected at iteration #{iteration}")
        return
      elsif (!enum_data.match(/new \w+-speed USB device number \d+/i))
        @stop_test = true
        set_result(FrameworkConstants::Result[:fail], "DUT is no longer detecting USB devices at iteration #{iteration}")  
        return
      elsif (!enum_data.match(/#{@test_params.params_control.transition_enum_string}/i))
        @stop_test = true
        set_result(FrameworkConstants::Result[:fail], "DUT did not detect USB device at iteration #{iteration}")  
        return
      end
      disconnect_leaf_device(switch_port_array)
      sleep disconnect_wait
      session_data_pointer = @equipment['dut1'].update_response.length
    end
  
  }
end
  
def stop_usb_transitions()
  if @usb_sw_thread
    @usb_sw_thread["stop"]=true
  end
end
