require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def connect_to_equipment
  super()
  usb_switch = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usb_port'].keys[0]]
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
  @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
  
  # Loop for Connect/Disconnect
  @test_params.params_chan.iterations[0].to_i.times do
    sleep 2
    sleep @test_params.params_chan.wait_after_disconnect[0].to_i
    session_data_pointer = @equipment['dut1'].update_response.length
    
    # Connect
    @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
    sleep @test_params.params_chan.wait_after_connect[0].to_i
    
    # Check device is enumerated
    ses_data = @equipment['dut1'].update_response
    enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length]
    @equipment['dut1'].log_info("Iteration #{i}: \n #{enum_data}")
    successful_enums = successful_enums + 1 if verify_devices_detected(enum_data) == 1 
    
    # Disconnect
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
    i = i+1
  end
  
  success_rate = (successful_enums.to_f / @test_params.params_chan.iterations[0].to_f)*100.0
  
  if (success_rate >= @test_params.params_chan.pass_rate[0].to_f)
    set_result(FrameworkConstants::Result[:pass], "Success Enumeration rate=#{success_rate}")
  else
    set_result(FrameworkConstants::Result[:fail], "Success Enumeration rate=#{success_rate}")
  end
  
end

private 

def verify_devices_detected(enum_data) 
 devices_numbers=Hash.new 
 @test_params.params_chan.enum_strings.each{|current|
   count = 0 
   @test_params.params_chan.enum_strings.each{|elem|
   if current.eql?(elem)
    count = count + 1 
   end   
   }
   devices_numbers[current] = count    
 }
 filtered_data = enum_data.gsub(/{#@test_params.params_chan.redundant[0]}/,"")
 @test_params.params_chan.enum_strings.each{|current|
 if enum_data.scan(/#{current}/).length != devices_numbers[current]
  puts "#{current}  :::: #{enum_data.scan(/#{current}/).length} :: #{devices_numbers[current]}"
  return 0
 end 
 }
  return 1 
end 


