require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript

def setup
  self.as(LspTestScript).setup
  singletouch = @equipment['dut1'].params['singletouch']
  conn_type = singletouch.params && singletouch.params.has_key?('conn_type') ? singletouch.params['conn_type'] : 'serial'
  add_equipment('singletouch') do |log_path|
    Object.const_get(singletouch.driver_class_name).new(singletouch,log_path)
  end
  # Connect to singletouch
  @equipment['singletouch'].connect({'type'=>conn_type})
  @equipment['singletouch'].configure_device(@equipment['dut1'].name)
  # Hack to Install input-utils binaries until there is a yocto package
  install_input_utils
end

def run
  test_status = 0
  tsc_filtered_data = Hash.new()
  flag = 0

  @equipment['dut1'].send_cmd("lsinput", @equipment['dut1'].prompt, 3)
  str = @equipment['dut1'].response
  tsc_event = get_event(str, @equipment['dut1'].name)
  if tsc_event == ""
    puts "No touch event HW detected\n"
  end
  @equipment['dut1'].send_cmd("input-events #{tsc_event.match(/([0-9]+)/).captures[0]}", @equipment['dut1'].prompt, 1)
  for i in 0..@test_params.params_chan.num_iter[0].to_i
    for point in @test_params.params_chan.coordinates
      tsc_filtered_data[point] = Hash.new()
      Thread.new() {
        @equipment['singletouch'].touch(point)
      }
      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 5)
      tsc_data = @equipment['dut1'].response
      tsc_filtered_data[point]['x_value'] = get_tsc_data(tsc_data)['x_value']
      tsc_filtered_data[point]['y_value'] = get_tsc_data(tsc_data)['y_value']
    end
    tsc_filtered_data.each {|k,v|
      puts "processing point #{k}"
      puts "x value:#{v['x_value']}"
      puts "y value:#{v['y_value']}"
    }
    verify_touch_data(tsc_filtered_data)
  end
end

def verify_touch_data(data)
  raise "You need to at least test 2 coordinates to verify proper touchscreen operation. Please modify your test" if data.keys.size < 2
  data.keys.combination(2) {|c|
    puts "verifying #{c[0]} and #{c[1]}"
    if c[0].match(/top/) and c[1].match(/(center|bottom)/) and data[c[0]]['y_value'] > data[c[1]]['y_value']
      set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Failed. #{c[0]} y coordinates are > than #{c[1]} ")
      return
    end
    if c[0].match(/center/) and c[1].match(/bottom/) and data[c[0]]['y_value'] > data[c[1]]['y_value']
      set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Failed. #{c[0]} y coordinates are > than #{c[1]} ")
      return
    end
    if c[0].match(/center/) and c[1].match(/top/) and data[c[0]]['y_value'] < data[c[1]]['y_value']
      set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Failed. #{c[0]} y coordinates are < than #{c[1]} ")
      return
    end
    if c[0].match(/bottom/) and c[1].match(/(top|center)/) and data[c[0]]['y_value'] < data[c[1]]['y_value']
      set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Failed. #{c[0]} y coordinates are < than #{c[1]} ")
      return
    end
    if c[0].match(/left/) and c[1].match(/(center|right)/) and data[c[0]]['x_value'] > data[c[1]]['x_value']
      set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Failed. #{c[0]} x coordinates are > than #{c[1]} ")
      return
    end
    if c[0].match(/center/) and c[1].match(/right/) and data[c[0]]['x_value'] > data[c[1]]['x_value']
      set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Failed. #{c[0]} x coordinates are > than #{c[1]} ")
      return
    end
    if c[0].match(/center/) and c[1].match(/left/) and data[c[0]]['x_value'] < data[c[1]]['x_value']
      set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Failed. #{c[0]} x coordinates are < than #{c[1]} ")
      return
    end
    if c[0].match(/right/) and c[1].match(/(left|center)/) and data[c[0]]['x_value'] < data[c[1]]['x_value']
      set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Failed. #{c[0]} x coordinates are < than #{c[1]} ")
      return
    end
  }
  set_result(FrameworkConstants::Result[:pass], "Touch Screen Test Passed. All touch coordinates matched expected relative changes")
end


#Function filters the touch data report by the platform(input-utils).
# Input parameters: str: is string data collected from platform.
# Return Parameter: filterd data

def get_tsc_data(str)
    tsc_data = Hash.new()
    x_values = str.to_s.scan(/EV_ABS\s+ABS_X\s+([0-9]+)/)
    tsc_data['x_value'] = get_average(x_values)
    y_values = str.to_s.scan(/EV_ABS\s+ABS_Y\s+([0-9]+)/)
    tsc_data['y_value'] = get_average(y_values)
    return tsc_data
end

#Function calculates the avarage of the x and y values reported by each touch.
# Input parameters: array_values: are array of x or y values for each touch.
# Return Parameter: average

def get_average(array_values)
    return 0 if array_values.length == 0
    total = 0
    array_values.each do |x|
      total += x[0].to_i
    end
    return  total / array_values.length
end

#Function gets the touch event number.
# Input parameters: str: string data returned by lsinput command of input-utils
# Return Parameter: touch event number

def get_event(str, dut_name)
    touch_signature = case dut_name
    when /am335x-evm/
      'ti-tsc'
    when /am437x-sk/
      'EP0980M09'
    else
      Raise "This test is not supported on #{dut_name}. Please define touch hw signature in the test code"
    end
    str.split(/\/dev\/input/).each do |str|
      if str.include?(touch_signature)
        tsc_event = str.to_s.match(/(event[0-9]+)/).captures[0]
        return tsc_event
      end
    end
    Raise "Could not find touch hw signature for #{dut_name}"
end

def install_input_utils
  @equipment['dut1'].send_cmd("which lsinput input-events && echo FOUND", /^FOUND/, 2)
  if @equipment['dut1'].timeout?
    @equipment['dut1'].send_cmd("wget http://10.218.103.34/anonymous/releases/bins/input-events", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("wget http://10.218.103.34/anonymous/releases/bins/lsinput", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("ls lsinput input-events && echo GOOD", /GOOD/, 2)
    raise "Input utils could not be installed" if @equipment['dut1'].timeout?
    @equipment['dut1'].send_cmd("chmod +x lsinput; mv lsinput /usr/bin/", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("chmod +x input-events; mv input-events /usr/bin/", @equipment['dut1'].prompt)
  end
end
