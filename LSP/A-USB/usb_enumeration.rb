require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript

def setup
  @equipment['dut1'].set_api('psp')
  connect_to_extra_equipment()
  self.as(LspTestScript).setup
  # Enable interrupts on MUSB port for am180x
  @equipment['dut1'].send_cmd("insmod /lib/modules/`uname -a | cut -d' ' -f 3`/kernel/drivers/usb/gadget/g_ether.ko", /#{@equipment['dut1'].prompt}/, 30) if @equipment['dut1'].name.match(/am180x/i)
end

def connect_to_extra_equipment
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
  @test_params.params_control.iterations[0].to_i.times do
    sleep @test_params.params_control.wait_after_disconnect[0].to_i
    session_data_pointer = @equipment['dut1'].update_response.length
    
    # Enumeration command
    @equipment['dut1'].send_cmd("if [ -e /proc/driver/musb_hdrc.0 ] ; then echo F > /proc/driver/musb_hdrc.0  ; fi", /#{@equipment['dut1'].prompt}/, 30)
    @equipment['dut1'].send_cmd("if [ -e /proc/driver/musb_hdrc.1 ] ; then echo F > /proc/driver/musb_hdrc.1  ; fi", /#{@equipment['dut1'].prompt}/, 30)
    
    # Connect
    @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
    sleep @test_params.params_control.wait_after_connect[0].to_i

    # Check device is enumerated
    ses_data = @equipment['dut1'].update_response
    enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length]
    @equipment['dut1'].log_info("Iteration #{i}: \n #{enum_data}")
    if ( enum_data.match(/(kernel NULL pointer dereference)|(reset \w+-speed USB device number \d+)/m) )
      set_result(FrameworkConstants::Result[:fail], "Kernel crash or USB reset errors detected")
      return
    else
      successful_enums = successful_enums + 1 if verify_devices_detected(enum_data) == 1
    end

    # Disconnect
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
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

def verify_devices_detected(enum_data)
  devices_numbers=Hash.new
  @test_params.params_control.enum_strings.each{|current|
    count = 0
    @test_params.params_control.enum_strings.each{|elem|
    if current.eql?(elem)
      count = count + 1
    end
    }
    devices_numbers[current] = count
  }
  #filtered_data = enum_data.gsub(/{#@test_params.params_control.redundant[0]}/,"")
  @test_params.params_control.enum_strings.each{|current|
    if enum_data.scan(/#{current}/).length < devices_numbers[current]
      puts "#{current}  :::: #{enum_data.scan(/#{current}/).length} :: #{devices_numbers[current]}"
      return 0
    end
  }
  return 1
end
