require File.dirname(__FILE__)+'/../default_test_module' 

include LspTestScript

def setup
  @equipment['dut1'].connect({'type'=>'serial'})
  # Bench entry is documented in the sample bench.rb 
  add_equipment('relay') do |log_path|
    DevantechRelayController.new(@equipment['dut1'].params['relay'].keys[0],log_path)
  end
  self.as(LspTestScript).setup
  # Hack to Install input-utils binaries until there is a yocto package
  install_input_utils
end

def run
  test_status = 0
  tsc_filtered_data = Hash.new()
  tsc_filtered_data['x_value'] = Array.new()
  tsc_filtered_data['y_value'] = Array.new() 
  flag = 0 
  # making sure valid ports are defined on the bench.
  # Bench dut.params = {'relay' => {pwr => [6,3, 5,4]}}
  # In the sample bench entry above, four relay portes are used
  # control selonoids. The power to the selonoid could be turned on one at 
  # a time. 
  @equipment['dut1'].params['relay'].values[0].each do |power_port|
      if power_port ==nil
        raise "You need Ethernet Relay connectivity to run this test"
      end
  end 
  @equipment['dut1'].send_cmd("lsinput", @equipment['dut1'].prompt, 3)
  str = @equipment['dut1'].response
  tsc_event = get_event(str)
  if tsc_event == "" 
    puts "No event detected for ti-tsc\n"
  end  
  for i in 0..@test_params.params_chan.num_iter[0].to_i
      @equipment['dut1'].params['relay'].values[0].each do |power_port|
        @equipment['dut1'].send_cmd("input-events #{tsc_event.match(/([0-9]+)/).captures[0]}", @equipment['dut1'].prompt, 3)
        do_touch_screen(power_port)
        @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 3)
        tsc_data = @equipment['dut1'].response
        tsc_filtered_data['x_value'] << get_tsc_data(tsc_data)['x_value'].to_s
        tsc_filtered_data['y_value'] << get_tsc_data(tsc_data)['y_value'].to_s
      end
   puts "TSC DATA ##########################################"
   puts "x value #{tsc_filtered_data['x_value']}"
   puts "y value #{tsc_filtered_data['y_value']}"
   puts "END DATA ###########################################"
  end  
  #Verify Result 
  counter = 0
  result = ""
  for outer_index in 0..1
    inner_counter = 0
    for innet_index in 0..(@equipment['dut1'].params['relay'].values[0].length - 1)
      delta_x = tsc_filtered_data['x_value'][counter + innet_index] - tsc_filtered_data['x_value'][innet_index]
      delta_y = tsc_filtered_data['y_value'][counter + innet_index] - tsc_filtered_data['y_value'][innet_index]
      if delta_x.to_i > 5 or delta_y.to_i > 5
        puts "TEst failed: x reference value #{tsc_filtered_data['x_value'][innet_index]}, x read #{tsc_filtered_data['x_value'][counter + innet_index]}"
        puts "TEst failed: y reference value #{tsc_filtered_data['y_value'][innet_index]}, y read #{tsc_filtered_data['y_value'][counter + innet_index]}"
        result = "x reference value #{tsc_filtered_data['x_value'][innet_index]}, x read #{tsc_filtered_data['x_value'][counter + innet_index]} + " "+\
                  y reference value #{tsc_filtered_data['y_value'][innet_index]}, y read #{tsc_filtered_data['y_value'][counter + innet_index]}"
        inner_counter += inner_counter
      else 
        test_status =  1
      end     
    end  
      counter += inner_counter
  end  
  if test_status > 0
    set_result(FrameworkConstants::Result[:pass], "Touch Screen Test Pass",result)
  else
    set_result(FrameworkConstants::Result[:fail], "Touch Screen Test Pass",result)   
  end 
 
end 

#Function does the touch using solenoids.
# Input parameters: power_port: is the relay port to which the solenoid is connected. 
# Return Parameter: none  

def do_touch_screen(power_port)
  @equipment['relay'].switch_on(power_port)
  puts "turn ON USB Swtich !!!!!!!!!"
  puts "sleep half second !!!" 
  sleep 0.5
  @equipment['relay'].switch_off(power_port)
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

def get_event(str)
    str.split(/\/dev\/input/).each do |str|
      if str.include?('ti-tsc')
        tsc_event = str.to_s.match(/(event[0-9]+)/).captures[0] 
        return tsc_event
      end 
    end 
    return ""
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
