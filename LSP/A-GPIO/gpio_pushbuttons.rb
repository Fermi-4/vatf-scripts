# Script to check gpio push buttons as input event 

require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript


def setup
  super
end

def run

  result_msg = ""
  result = 0 

  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i gpio", @equipment['dut1'].prompt, 10, false) 
  @equipment['dut1'].send_cmd("cat /sys/kernel/debug/gpio", @equipment['dut1'].prompt, 10, false) 

  begin
    @equipment['dut1'].send_cmd("evtest", /Select.*event\s+number\s+.*:/i, 10) 

    # find out event number for this button
    event = get_keypad_event_number(@equipment['dut1'].response)
    puts "event is #{event}"
    @equipment['dut1'].send_cmd("#{event}", /\(interrupt\s+to\s+exit\)/i, 10) 
    #puts @equipment['dut1'].response

    keys = get_pushbuttons(@equipment['dut1'].name)
    puts "keys: #{keys.to_s}"
    keys.each {|key|
      key = key.downcase
      raise "Please define dut.params[\'#{key}\'] in your bench file" if !@equipment['dut1'].params.has_key?("#{key}")
      @power_handler.load_power_ports(@equipment['dut1'].params["#{key}"]) 
      @power_handler.reset(@equipment['dut1'].params["#{key}"]) 
      # check if event raise when key is pressing down
      @equipment['dut1'].wait_for(/Event:\s+time.*#{key}/i, 30)
      if @equipment['dut1'].timeout?
        result_msg = "Did not find event for #{key}; "
        result = result + 1
      end
    } 

  ensure
    @equipment['dut1'].send_cmd("\cC", @equipment['dut1'].prompt, 10, false) 
    raise "Ctrl+C failed" if @equipment['dut1'].timeout?
  end

  # check interrupt after keys are pressed
  @equipment['dut1'].send_cmd("cat /proc/interrupts | grep -i gpio", @equipment['dut1'].prompt, 10, false) 
  if result == 0
    set_result(FrameworkConstants::Result[:pass], "This test passed.")
  else 
    set_result(FrameworkConstants::Result[:fail], "This test failed." + result_msg)
  end

end

def get_keypad_event_number(dut_response)
  event_num = dut_response.match(/\/dev\/input\/event(\d+):\s+(?:matrix_keypad|gpio-keys)/i)[1]
  raise "Could not find event number for keypad" if event_num == nil
  return event_num
end

def get_pushbuttons(platform)
  platform = platform.downcase
  case platform
    when 'am335x-evm'
      buttons = ['key_back', 'key_right', 'key_down', 'key_enter', 'key_left', 'key_menu']
    when 'am43xx-gpevm'
      buttons = ['key_down', 'key_right', 'key_numeric_2', 'key_left', 'key_up', 'key_numeric_1']
    when 'omapl138-lcdk'
      buttons = ['btn_0', 'btn_1']
    else
      raise "Push buttons are not defined for platform #{platform}"
  end
  return buttons
end
