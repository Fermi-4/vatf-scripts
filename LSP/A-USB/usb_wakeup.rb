require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../A-Power/power_functions' 

include PowerFunctions

include LspTestScript

def setup
  @equipment['dut1'].set_api('psp')
  connect_to_extra_equipment()
  self.as(LspTestScript).setup
  # Enable interrupts on MUSB port for am180x
  @equipment['dut1'].send_cmd("insmod /lib/modules/`uname -a | cut -d' ' -f 3`/kernel/drivers/usb/gadget/g_ether.ko", /#{@equipment['dut1'].prompt}/, 30) if @equipment['dut1'].name.match(/am180x/i)
  enable_usb_wakeup
end

def enable_usb_wakeup
  power_state = @test_params.params_control.instance_variable_defined?(:@power_state) ? @test_params.params_control.power_state[0] : 'mem'
  power_wakeup_configuration("usb", power_state)
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
  wakeup_event = @test_params.params_control.wakeup_event[0]
  suspend_time = @test_params.params_control.suspend_time[0].to_i
  power_state = @test_params.params_control.instance_variable_defined?(:@power_state) ? @test_params.params_control.power_state[0] : 'mem'

  # Initialize switch state
  if wakeup_event == 'connect'
    @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
  else
    @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
  end

  # Loop for Connect/Disconnect
  @test_params.params_control.iterations[0].to_i.times do
    sleep @test_params.params_control.wait_after_disconnect[0].to_i if wakeup_event.match(/connect/)
    
    puts "GOING TO SUSPEND DUT"
    @equipment['dut1'].send_cmd("sync; echo #{power_state} > /sys/power/state", /Freezing remaining freezable tasks/, 60)
    if @equipment['dut1'].timeout?
      puts "Timeout while waiting to suspend"
      raise "DUT took more than 60 seconds to suspend - Iteration #{i}" 
    end
    sleep rand(suspend_time)+1

    session_data_pointer = @equipment['dut1'].update_response.length
    
    # Enumeration command
    #@equipment['dut1'].send_cmd("if [ -e /proc/driver/musb_hdrc.0 ] ; then echo F > /proc/driver/musb_hdrc.0  ; fi", /#{@equipment['dut1'].prompt}/, 30)
    #@equipment['dut1'].send_cmd("if [ -e /proc/driver/musb_hdrc.1 ] ; then echo F > /proc/driver/musb_hdrc.1  ; fi", /#{@equipment['dut1'].prompt}/, 30)
    
    # Generate Wakeup event
    if wakeup_event == 'connect'
      @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
    elsif wakeup_event == 'disconnect'
      @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
    elsif wakeup_event == 'mouse-click'
      3.times {puts "Please Click Mouse Button"}
      puts "\a"   # Generate beep
      sleep 3
    elsif wakeup_event == 'keyboard-press'
      3.times {puts "Please Press Keyboard"}
      puts "\a"   # Generate beep
      sleep 3
    else
      raise "Unknown USB Wakeup Source: #{wakeup_event} Iteration #{i}" 
    end

    # Give it few secs to wakeup and check it is awake
    sleep @test_params.params_control.wait_after_connect[0].to_i
    @equipment['dut1'].send_cmd("pwd", @equipment['dut1'].prompt, 0.5)
    if @equipment['dut1'].timeout?
      puts "USB Event did not wakeup the system - Iteration #{i}"
      raise "USB Event did not wakeup the system - Iteration #{i}" 
    end

    # Force enumeration in case of wakeup by disconnect
    if wakeup_event == 'disconnect'
      @usb_switch_handler.select_input(@equipment['dut1'].params['usb_port'])
      # Give it few secs to enumerate
      sleep @test_params.params_control.wait_after_connect[0].to_i
    end

    if wakeup_event == 'mouse-click' || wakeup_event == 'keyboard-press'
      @equipment['dut1'].send_cmd("lsusb", @equipment['dut1'].prompt, 3)
    end


    # Check device is enumerated
    ses_data = @equipment['dut1'].update_response
    enum_data = ses_data[session_data_pointer==0 ? 0: session_data_pointer-1, ses_data.length]
    @equipment['dut1'].log_info("Iteration #{i}: \n #{enum_data}")
    #if ( enum_data.match(/(kernel NULL pointer dereference)|(reset \w+-speed USB device number \d+)/m) )   #Temp disabling check for reset msgs
    if ( enum_data.match(/(kernel NULL pointer dereference)/m) )
      set_result(FrameworkConstants::Result[:fail], "Kernel crash or USB reset errors detected")
      return
    else
      successful_enums = successful_enums + 1 if verify_devices_detected(enum_data, wakeup_event) == 1
    end
 
    # Re-enable usb wakeup in case bable interrupts resetted the controller
    enable_usb_wakeup

    # Prepare for next loop
    if wakeup_event == 'connect'
      @usb_switch_handler.disconnect(@equipment['dut1'].params['usb_port'].keys[0])
    end
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

def verify_devices_detected(enum_data, wakeup_event)
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
  if wakeup_event.match(/connect/)
    @test_params.params_control.enum_strings.each{|current|
      if enum_data.scan(/#{current}/).length < devices_numbers[current]
        puts "#{current}  :::: #{enum_data.scan(/#{current}/).length} :: #{devices_numbers[current]}"
        return 0
      end
    }
    return 1
  else
    # Check detection based on lsusb output
    ['Mouse', 'Keyboard'].each{|device|
      return 0 if !enum_data.match(/#{device}/i)
    }
    return 1
  end
end
