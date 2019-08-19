require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript

class Point
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def ==(other)
    self.class === other and
      other.x == @x and
      other.y == @y
  end

  alias eql? ==

  def hash
    @x.hash ^ @y.hash # XOR
  end
end

def setup
  self.as(LspTestScript).setup
  multitouch = @equipment['dut1'].params['multitouch']
  conn_type = multitouch.params && multitouch.params.has_key?('conn_type') ? multitouch.params['conn_type'] : 'serial'
  add_equipment('multitouch') do |log_path|
    Object.const_get(multitouch.driver_class_name).new(multitouch,log_path)
  end
  # Connect to multitouch
  @equipment['multitouch'].connect({'type'=>conn_type})
  @equipment['multitouch'].configure_device(@equipment['dut1'].name)
end

def run
  tsc_event = get_tsc_event()
  
  # If there is no touch hardware then kill the test
  if (tsc_event.length == 0) 
    set_result(FrameworkConstants::Result[:fail], "Touchscreen test FAILED, no touch HW found")
    return 
  end
  
   # Determine DUT screen size from evtest
   @equipment['dut1'].send_cmd("evtest #{tsc_event}", @equipment['dut1'].prompt, 1)
   evtest_response = @equipment['dut1'].response
   screen_x, screen_y = get_screen_size(evtest_response)
   @equipment['multitouch'].set_screen(screen_x, screen_y)
  
  # Generate point to touch for test case 
  x, y = @equipment['multitouch'].generate_point()
  point1 = Point.new(x, y)

  # Build multitouch point by adding offset to original point
  x, y = @equipment['multitouch'].build_multitouch_point(point1)
  point2 = Point.new(x, y)
  
  # Get number of test iterations
  iterations = @test_params.params_chan.num_iter[0].to_i
 
  # Declare hash for recording touch data
  tsc_filtered_data = Hash.new()
  tsc_filtered_data[point1] = Hash.new()
  tsc_filtered_data[point2] = Hash.new()
  
  # Loop through points to touch per test iteration
  for i in 1..iterations
    # Touch point
    Thread.new() {
      @equipment['multitouch'].touch(point1)
    }
    
    @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 5)
    
    # Get recorded touch data
    tsc_results = get_tsc_data(@equipment['dut1'].response, point1, point2)
    
    tsc_filtered_data[point1]['x_value'] = tsc_results['x_value_1']
    tsc_filtered_data[point1]['y_value'] = tsc_results['y_value_1']
    
    tsc_filtered_data[point2]['x_value'] = tsc_results['x_value_2']
    tsc_filtered_data[point2]['y_value'] = tsc_results['y_value_2']
    
    # Verify test results
    verify_touch_data(tsc_filtered_data)
  end
end

# Function gets the touchscreen hw event
# Return Parameter: touch event hw
def get_tsc_event()
  @equipment['dut1'].send_cmd('ls /dev/input/touchscreen0', @equipment['dut1'].prompt)

  if (@equipment['dut1'].response.match(/No such file or directory/))
    return ''
  else 
    return '/dev/input/touchscreen0'
  end 
end

# Function pulls screen size from information printed by the evetest command
# Input: String of output from evtest
# Return: x and y integers representing max value of screen size
def get_screen_size(str)
  x = str.to_s.scan(/\(ABS_X\).\s*Value\s*[0-9]+.\s*Min\s*[0-9]+.\s*Max\s*([0-9]+)/)[0][0].to_i
  y = str.to_s.scan(/\(ABS_Y\).\s*Value\s*[0-9]+.\s*Min\s*[0-9]+.\s*Max\s*([0-9]+)/)[0][0].to_i
  return x, y
end

# Function filters the touch data report by the platform(evtest).
# Input parameters: str: is string data collected from platform.
# Return Parameter: filterd data
def get_tsc_data(str, p1, p2)
  tsc_data = Hash.new()
  x_values = str.to_s.scan(/\(ABS_MT_POSITION_X\).+value\s([0-9]+)/)
  y_values = str.to_s.scan(/\(ABS_MT_POSITION_Y\).+value\s([0-9]+)/)
  
  x_values = x_values.map{|x|
    x[0].to_i
  }
  
  y_values = y_values.map{|x|
    x[0].to_i
  }

  tsc_data['x_value_1'], tsc_data['x_value_2'] = group_values(x_values, p1.x, p2.x) 
  
  tsc_data['y_value_1'] = get_average(y_values)
  tsc_data['y_value_2'] = get_average(y_values)
  
  return tsc_data
end

# Function attempts to group the multitouch points together and calculate the average value for both touch points.
# Input parameters: array_values: are array of x or y values for each touch.
# Return Parameter: grouped average values
def group_values(array_values, point1, point2)
  x1 = Array.new
  x2 = Array.new
  
  array_values.each do |x|
    if ((x - point1).abs < 20)
      x1.push(x)
    elsif ((x - point2).abs < 20)
      x2.push(x)
    else
      puts "no group assigned for #{x}"
    end
  end

  return get_average(x1), get_average(x2)
end

# Function gets the average of the values in the array.
# Input parameters: array_values: are array of x or y values for each touch.
# Return Parameter: average values
def get_average(array_values)
  return 0 if array_values.length == 0
  total = 0
  array_values.each do |x|
    total += x
  end
  return total / array_values.length
end

# Function gets the map of recorded touch events as input and determines if the touch data is accurate
def verify_touch_data(data)
  raise "Need to at least test 2 coordinates to verify proper touchscreen operation." if data.keys.size < 2
  
  # Check if each point's recorded x & y results are within 150px of the original point
  data.each { |k, v|
    puts "checking values for (#{k.x}, #{k.y})"
    puts "x difference #{k.x - v['x_value']}"
    puts "y difference #{k.y - v['y_value']}"
    
    if ((k.x - v['x_value']).abs > 150)
      set_result(FrameworkConstants::Result[:fail], "Touchscreen test FAILED for point (#{k.x}, #{k.y}). Expected x value within 150 px of #{k.x}, got #{v['x_value']}.")
      return
    end
    
    if ((k.y - v['y_value']).abs > 150)
      set_result(FrameworkConstants::Result[:fail], "Touchscreen test FAILED for point (#{k.x}, #{k.y}). Expected y value within 150 px of #{k.y}, got #{v['y_value']}.")
      return
    end
  }
  
  set_result(FrameworkConstants::Result[:pass], "Touchscreen test PASSED.")
end