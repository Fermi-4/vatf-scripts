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
  singletouch = @equipment['dut1'].params['singletouch']
  conn_type = singletouch.params && singletouch.params.has_key?('conn_type') ? singletouch.params['conn_type'] : 'serial'
  add_equipment('singletouch') do |log_path|
    Object.const_get(singletouch.driver_class_name).new(singletouch,log_path)
  end
  # Connect to singletouch
  @equipment['singletouch'].connect({'type'=>conn_type})
  @equipment['singletouch'].configure_device(@equipment['dut1'].name)
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
  @equipment['singletouch'].set_screen(screen_x, screen_y)
  
  # Generate points to touch for test case 
  points = @equipment['singletouch'].generate_points()
  
  # Get number of test iterations
  iterations = @test_params.params_chan.num_iter[0].to_i
  
  # Parse generated points into objects
  tsc_filtered_data = parse_touch_points(points)
  
  # Loop through points to touch per test iteration
  for i in 1..iterations
    for point in tsc_filtered_data.keys
      # Touch point
      Thread.new() {
        @equipment['singletouch'].touch(point)
      }
      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 5)
      
      # Get recorded touch data
      tsc_data = @equipment['dut1'].response

      tsc_filtered_data[point]['x_value'] = get_tsc_data(tsc_data)['x_value']
      tsc_filtered_data[point]['y_value'] = get_tsc_data(tsc_data)['y_value']
    end
    
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

# function parses points out of test-params into hash
def parse_touch_points(points)
  data = Hash.new()
  
  i = 0
  while (i < points.size)
    p = Point.new(points[i].to_i, points[i+1].to_i)
    data[p] = Hash.new()
    i += 2
  end

  return data
end

#Function filters the touch data report by the platform(evtest).
# Input parameters: str: is string data collected from platform.
# Return Parameter: filtered data
def get_tsc_data(str)
  tsc_data = Hash.new()
  x_values = str.to_s.scan(/ABS_X\),\s*value\s*([0-9]+)/)
  tsc_data['x_value'] = get_average(x_values)
  y_values = str.to_s.scan(/ABS_Y\),\s*value\s*([0-9]+)/)
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
    
    # Tapbot touches come in at an angle making the pixel accuracy slightly off at farther reaches, 
    # keeping buffer of 150px to keep test from failing when it should pass
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