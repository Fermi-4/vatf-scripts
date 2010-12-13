require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def connect_to_equipment
  super()
  if @equipment['usb_sw'].respond_to?(:serial_port) && @equipment['usb_sw'].serial_port != nil
    @equipment['usb_sw'].connect({'type'=>'serial'})
  elsif @equipment['usb_sw'].respond_to?(:serial_server_port) && @equipment['usb_sw'].serial_server_port != nil
    @equipment['usb_sw'].connect({'type'=>'serial'})
  else
    raise "You need direct or indirect (i.e. using Telnet/Serial Switch) serial port connectivity to the USB switch. Please check your bench file" 
  end
end

def run
  i=0
  successful_enums=0
  session_data_pointer=0
  expected_enum_regex=get_expected_regex(@test_params.params_control.enum_strings)
  
  # Start from disconnect state
  @equipment['usb_sw'].select_input(0)   # 0 means don't select any input port.
  
  # Loop for Connect/Disconnect
  @test_params.params_control.iterations[0].to_i.times do
    sleep @test_params.params_control.wait_after_disconnect[0].to_i
    session_data_pointer = @equipment['dut1'].update_response.length
    
    # Connect
    @equipment['usb_sw'].select_input(@equipment['dut1'].params['usb_port'])
    sleep @test_params.params_control.wait_after_connect[0].to_i
    
    # Check device is enumerated
    ses_data = @equipment['dut1'].update_response
    enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length]
    @equipment['dut1'].log_info("Iteration #{i}: \n #{enum_data}")
    successful_enums = successful_enums + 1 if expected_enum_regex.match(enum_data)
    
    # Disconnect
    @equipment['usb_sw'].select_input(0)   # 0 means don't select any input port.
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
def get_expected_regex(expected_enum_array)
  regex_array = expected_enum_array.join(".*")
  /#{regex_array}/mi
end

