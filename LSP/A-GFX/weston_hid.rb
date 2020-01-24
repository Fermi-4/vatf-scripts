# -*- coding: ISO-8859-1 -*-
=begin
Test to validate support for keyboard and mouse in weston. The test
triggers keyboard or mouse events using a MSP430F5529LP launchpad,
the events should be reported by the weston-eventdemo application.
Requirements:
  - pseudohid capability
  - MSP430F5529LP running the pseudoHID app. Launchpad gpio setup is:
      * Port P1.5 in J1 for mouse events
      * Port P1.4 in J1 for keyboard events
  - Relay board or Beaglebone black (BBB) to trigger the keyboard or
    mouse sequence in the MSP430
Bench entries:
  - Add "mouse-gpio" and "kb-gpio" entries to dut params field in
    the bench file. These should point to the relay board (NO) ports or
    BBB gpios ports where P1.5 and P1.4 of the MSP430 launchpad are
    connected.
    dut.params { .
                 .
                 'mouse-gpio' => { <BBB or relay board bench object> =>
                                   <BBB port (P8_7, P8_8, etc) or
                                   relay port (1 to 8)>},
                 'kb-gpio' => { <BBB or relay board bench object> =>
                                   <BBB port (P8_7, P8_8, etc) or
                                   relay port (1 to 8)> },
                 .
                 .
                 .
                 }
=end
require File.dirname(__FILE__)+'/../default_target_test'  

include LspTargetTestScript

def setup
  super
  @equipment['dut1'].send_cmd('/etc/init.d/matrix-gui-2.0 stop',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep || /etc/init.d/weston start && sleep 3',@equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd('ps -ef | grep -i weston | grep -v grep || echo "weston failed"',@equipment['dut1'].prompt,10)
  if @equipment['dut1'].response.scan(/weston\s*failed/im).length > 1
    @equipment['dut1'].send_cmd('cat /var/log/weston.log', @equipment['dut1'].prompt, 10)
    raise "Weston did not start, test requires weston"
  end
end

def run
  mod = ''
  if @equipment['dut1'].name.match(/j7.*|am6.*/im)
    mod="-M tidss"
  end
  @equipment['dut1'].send_cmd("modetest #{mod} -c", @equipment['dut1'].prompt, 20)
  resolutions = @equipment['dut1'].response.scan(/\s+\d+x\d+\s/)
  widths = []
  heights = [] 
  resolutions.collect do |r| rarr = r.strip().split('x')
            widths << rarr[0].to_i
            heights << rarr[1].to_i
  end
  @equipment['dut1'].send_cmd("weston-eventdemo --width=#{widths.max()*2} --height=#{heights.max()*2} -b")
  sleep 5
  hid_type = @test_params.params_chan.hid[0]
  events_data = trigger_event(hid_type)
  result, processed_data = case hid_type
    when 'mouse'
      check_mouse_events_data(events_data)
    when 'keyboard'
      check_kb_events_data(events_data)
  end
  if result
    set_result(FrameworkConstants::Result[:pass], "Weston #{hid_type} test passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Weston #{hid_type} test failed:\n#{processed_data}")
  end
end

def clean()
  @equipment['dut1'].send_cmd("\x03") #Send Ctrl-c to get out of weston-eventdemo
  super
end

def trigger_event(etype)
  e_info, gpio = case etype
    when 'mouse'
      @equipment['dut1'].params['mouse-gpio'].to_a[0]
    when 'keyboard'
      @equipment['dut1'].params['kb-gpio'].to_a[0]
  end

  add_equipment('hid-gpio', e_info) do |e_class, log_path|
    e_class.new(e_info, log_path)
  end

  r_thr = Thread.new() { @equipment['dut1'].read_for(15) }
  if @equipment['hid-gpio'].respond_to?(:gpio_write)
    @equipment['hid-gpio'].connect({'type'=>'serial'})
    @equipment['hid-gpio'].configure_device()
    @equipment['hid-gpio'].gpio_write(gpio, 1)
    @equipment['hid-gpio'].gpio_write(gpio, 0)
  else
    @equipment['hid-gpio'].reset(gpio)
  end
  r_thr.join()
  @equipment['dut1'].response
end

def check_mouse_events_data(data)
  captured_data = data.scan(/x:\s*([\d\.]+),\s*y:\s*([\d\.]+)/im).map() {|xy| xy.map(&:to_f)}
  mid_idx = captured_data.length / 2

  #Get the test sammples
  xys = captured_data[mid_idx - 20..mid_idx + 20]

  #Get 3 points to calculate the circles center
  x1,y1 = xys[0]
  x2,y2 = captured_data[mid_idx]
  x3,y3 = xys[1]
  
  #Squared of the modules
  r1 = x1**2 + y1**2
  r2 = x2**2 + y2**2
  r3 = x3**2 + y3**2
  
  #Getting the center coordinates
  xc = ((y3-y1)*(r2-r1) - (y2-y1)*(r3-r1))/(2*((x2-x1)*(y3-y1) - (x3-x1)*(y2-y1)))
  yc = (r3 - r1 - (2*xc*(x3-x1))) / (2*(y3-y1))
  
  puts "Center = #{[xc, yc]}"
  #Validate that points in mid_ix-20 to mid_idx+20 are in a circular trajectory
  current = [xys[0][0]-xc, xys[0][1]-yc]
  radius = (current.reduce(0) { |sum, c| sum += c**2 })**0.5
  puts "Points = #{current}, #{radius}"
  xys[1..-1].each do |xy|
    txy = [xy[0]-xc, xy[1]-yc]
    txy_radius = (txy.reduce(0) { |sum, c| sum += c**2 })**0.5
    puts "#{txy}, #{txy_radius}"
    return [false, "rotation: #{current}->#{txy}, radius: #{radius} (expected), #{txy_radius} (current)"] if !check_rotation(current, txy) || txy_radius - radius < -15 || txy_radius - radius > 15
    current = txy
  end

  return [true, "passed"]
end

def check_rotation(p1,p2)
  # Counter Clockwise rotation
  #if p1[0] > 0 && p1[1] > 0 # +,+ quadrant
  #  return false if p2[1] < 0 
  #elsif p1[0] < 0 && p1[1] > 0 # -,+ quadrant
  #  return false if p2[0] > 0
  #elsif p1[0] < 0 && p1[1] < 0 # -,- quadrant
  #  return false if p2[1] > 0
  #elsif p1[0] > 0 && p1[1] < 0 # +,- quadrant
  #  return false if p2[0] < 0
  #end
  
  #Clockwise rotation
  if p1[0] > 0 && p1[1] > 0 # +,+ quadrant
    return false if p2[0] < 0 
  elsif p1[0] < 0 && p1[1] > 0 # -,+ quadrant
    return false if p2[1] < 0
  elsif p1[0] < 0 && p1[1] < 0 # -,- quadrant
    return false if p2[0] > 0
  elsif p1[0] > 0 && p1[1] < 0 # +,- quadrant
    return false if p2[1] > 0
  end
  true
end

def check_kb_events_data(data)
  captured_str = data.scan(/unicode:\s*(\d+),\s*state:\s*pressed,\s*modifiers:\s*0x/im).flatten().map(&:to_i)
  captured_str = captured_str.select{ |x| x < 256}.map(&:chr).join('')
  [captured_str.include?('Keyboard demo: The quick brown fox jumped over the lazy dog'), captured_str]
end
