require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript

def setup
  self.as(LspTestScript).setup
  connect_to_extra_equipment()
end

def connect_to_extra_equipment
  usb_switch = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usb_otg_port'].keys[0]]
  if usb_switch.respond_to?(:serial_port) && usb_switch.serial_port != nil
    usb_switch.connect({'type'=>'serial'})
  elsif usb_switch.respond_to?(:serial_server_port) && usb_switch.serial_server_port != nil
    usb_switch.connect({'type'=>'serial'})
  else
    raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the USB switch. Please check your bench file"
  end
end

def run
  i=0
  successful_enums=0
  session_data_pointer=0
  # Start from disconnect state
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_otg_port'].keys[0])
  # Make sure module is installed
  @equipment['dut1'].send_cmd("zcat /proc/config.gz | grep USB | grep FILE", @equipment['dut1'].prompt, 3)
  case @equipment['dut1'].response
  when /CONFIG_USB_FILE_STORAGE\s+is\s+not\s+set/
    raise "Can't run test because kernel does NOT support CONFIG_USB_FILE_STORAGE"
  when /CONFIG_USB_FILE_STORAGE=m/
     @equipment['dut1'].send_cmd("modprobe g_mass_storage file=#{@test_params.params_control.fbs_node[0]} stall=0", @equipment['dut1'].prompt, 5)
     @equipment['dut1'].send_cmd("lsmod", /g_mass_storage\s+\d+/, 3)
     raise "Failed to modprobe g_mass_storage" if @equipment['dut1'].timeout?
  else
    # Do Nothing. Driver is already included in the kernel
  end
    
  # Loop for Connect/Disconnect
  @test_params.params_control.iterations[0].to_i.times do
    sleep @test_params.params_control.wait_after_disconnect[0].to_i
    num_usb_dev_before=`lsusb | wc -l`
    session_data_pointer = @equipment['dut1'].update_response.length

    # Connect
    @usb_switch_handler.select_input(@equipment['dut1'].params['usb_otg_port'])
    sleep @test_params.params_control.wait_after_connect[0].to_i
    num_usb_dev_after=`lsusb | wc -l`
    usb_dev_after=`lsusb`

    # Check device is enumerated
    ses_data = @equipment['dut1'].update_response
    enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length]
    @equipment['dut1'].log_info("Iteration #{i}: \n #{enum_data}")
    successful_enums = successful_enums + 1 if (verify_dut_detection_msg(enum_data) == 1 && verify_host_detection_msg(num_usb_dev_before, num_usb_dev_after, usb_dev_after) == 1)

    # Disconnect
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_otg_port'].keys[0])
    i = i+1
  end

  success_rate = (successful_enums.to_f / @test_params.params_control.iterations[0].to_f)*100.0

  if (success_rate >= @test_params.params_control.pass_rate[0].to_f)
    set_result(FrameworkConstants::Result[:pass], "Success Enumeration rate=#{success_rate}")
  else
    set_result(FrameworkConstants::Result[:fail], "Success Enumeration rate=#{success_rate}")
  end
end

private

def verify_dut_detection_msg(data)
  return 1 if data.match(/Linux\s*File-Backed\s*Storage/i)
  @equipment['dut1'].log_info("'Linux File-Backed Storage' message was NOT detected")
  return 0
end

def verify_host_detection_msg(num_before, num_after, data)
  return 1 if num_after.to_i > num_before.to_i && data.match(/Linux-USB\s*File\s*Storage\s*Gadget/i) 
  @equipment['server1'].log_info("'Linux-USB File Storage Gadget' message was NOT detected")
  return 0
end

