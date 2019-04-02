=begin
Script to test capture functionality. It can be run in two modes:
  - auto: The script performs a capture and compares against
          previously saved references to determine pass/fail. Requires
          auto param defined in test definition, and an entry in the
          bench file params field of syntax:
            'sensor_info' => {'id' => <sensor box unique id>,
                              ['light' => {<light src power object> => <port id>}]
                             }
          where:
            * 'id' references a global unique identifier for the sensor,
                 that is used to retrieved the appropiate reference
                 files for the setup
            * 'light': is an optional entry that reference the object in
                 the bench that is used to turn on the light source that
                 iluminates the target of the capture
            
          for example, additional bench definition required for this 
          test could be:
            pwr = EquipmentInfo.new("power_controller", "192.168.0.10")
            pwr.telnet_ip = '192.168.0.10'
            pwr.driver_class_name = 'DevantechRelayController'
            
            dut = EquipmentInfo.new("dra7xx-evm", "linux_videosensor")
              .
              .
              .
            dut.params = {'sensor_info' => 
                            {'id' => 'ov10633_box4',
                             'light' => {pwr => 1}
                            }
                         }
  - semi-auto: The scripts performs a capture and pops-up a window so
          the user can play the captured frames and click on pass or
          fail. 
=end
require File.dirname(__FILE__)+'/../../default_target_test'
require File.dirname(__FILE__)+'/../../../lib/utils'
require File.dirname(__FILE__)+'/../play_utils'
require File.dirname(__FILE__)+'/../dev_utils'
require File.dirname(__FILE__)+'/../f2f_utils'
require File.dirname(__FILE__)+'/../../A-Display/drm/capture_utils'
require File.dirname(__FILE__)+'/v4l2ctl_utils'

require 'matrix'
require 'fileutils'

include LspTargetTestScript
include CaptureUtils

def run
  @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt)
  test_result = true
  ip_type = @test_params.params_chan.capture_ip_type[0]
  cap_devs = get_type_devices(ip_type)
  raise "No capture device of type #{ip_type} found" if !cap_devs
  capture_mem_needed = 1600*1200*48
  perf_data = []
  cap_devs.each do |dev|
    sensor = get_sensor_name(dev)
    capture_device = '/dev/' + dev
    if @equipment['dut1'].name == 'omapl138-lcdk'
      next if @equipment['dut1'].send_cmd("v4l2-ctl -d #{capture_device} -I", @equipment['dut1'].prompt, 10).match(/S-Video/im)
    end
    fmt_opts = get_fmt_options(capture_device)
    dev_interrupt_info = ''
    if @test_params.params_chan.instance_variable_defined?(:@video_standard)
      dev_interrupt_info = @test_params.params_chan.video_standard[0].upcase()+'_'
      raise "Unable to set the video standard on the input" if !set_video_standard(@test_params.params_chan.video_standard[0], capture_device)
    end
    test_res = fmt_opts['frame-size'].minmax{|a,b| a.split('x').map(&:to_i).reduce(1,:*) <=> b.split('x').map(&:to_i).reduce(1,:*)}
    test_fmt = fmt_opts['pixel-format'].minmax{|a,b| get_format_length(a) <=> get_format_length(b)}
    test_res.each do |resolution|
      @results_html_file.add_paragraph("")
      res_table = @results_html_file.add_table([["Capture Device",{:bgcolor => "4863A0"}],
                                              ["Frame size",{:bgcolor => "4863A0"}], 
                                              ["Pixel format", {:bgcolor => "4863A0"}],
                                              ["Result", {:bgcolor => "4863A0"}],
                                              ["Comment", {:bgcolor => "4863A0"}]])
      test_fmt.each do |pix_fmt|
        width,  height = resolution.split(/x/i)
        f_length = get_format_length(pix_fmt)
        trial_result = FrameworkConstants::Result[:nry]
        play_width = ''
        play_height = ''
        cap_width, cap_height = nil
        fps = []
        use_memory(capture_mem_needed) do
          cap_width, cap_height, fps = sensor_capture({'--device' => capture_device, 
                                                       '--set-fmt-video' => "pixelformat=#{pix_fmt},width=#{width},height=#{height}"},
                                                       [width.to_f * height.to_f / 1000, 30].max)
        end
        play_width = cap_width && cap_height ? cap_width : width
        play_height = cap_width && cap_height ? cap_height : height
        perf_data << {'name' => "#{sensor}_#{play_width}x#{play_height}_#{pix_fmt}", 'units' => 'fps', 'value' => fps}
        test_result &= !fps.empty?
        @results_html_file.add_rows_to_table(res_table,[[capture_device,
                                                         "#{play_width}x#{play_height}", 
                                                         pix_fmt,
                                                         !fps.empty? ? ["Passed",{:bgcolor => "green"}] :
                                                         ["Failed",{:bgcolor => "red"}],
                                                         '']]
                                                         )
      end
    end
  end
  if test_result
    set_result(FrameworkConstants::Result[:pass], "Capture Test Passed", perf_data)
  else
    set_result(FrameworkConstants::Result[:fail], "Capture Test failed", perf_data)
  end
end

def sensor_capture(params, timeout, dut=@equipment['dut1'])
  dut.send_cmd("v4l2-ctl --device=#{params['--device']} --try-fmt-video=#{params['--set-fmt-video']}", dut.prompt, timeout)
  res_match = dut.response.match(/Width\/Height\s*:\s*(\d+)\/(\d+).*?/)
  cmd = "v4l2-ctl --stream-skip=300 --stream-poll --stream-mmap=6 --stream-count=1 --stream-to=/dev/null"
  params.each{|key,val| cmd += ' ' + key + (val.to_s == '' ? '' : '=' + val.to_s)}
  dut.send_cmd(cmd, dut.prompt, timeout)
  fps = dut.response.scan(/[\d\.]+(?=\s*fps)/im).map(&:to_f)
  return res_match.captures << fps if res_match
  [nil, nil, fps]
end

def get_sensor_name(device, dut=@equipment['dut1'])
  dev_dir = "/sys/class/video4linux/#{device}/device/of_node"
  dut.send_cmd("ls #{dev_dir}",dut.prompt)
  if dut.response.match(/port@\d+/)
    ports = dut.response.scan(/port[^\s]*/)
    ports.each do |p|
      dut.send_cmd("cat #{dev_dir}/#{p}/status", dut.prompt)
      if dut.response.match(/^okay/im)
        dut.send_cmd("ls #{dev_dir}/#{p}/",dut.prompt)
        ep = dut.response.scan(/endpoint[^\s]*/)[0]
        return find_sensor_name("#{dev_dir}/#{p}/#{ep}/remote-endpoint", dut)
      end
    end
  elsif dut.response.match(/ports/)
    dev_dir = dev_dir + '/ports'
    dut.send_cmd("ls #{dev_dir}",dut.prompt)
    ports = dut.response.scan(/port@[^\s]*/)
    ports.each do |p|
      dut.send_cmd("ls #{dev_dir}/#{p}", dut.prompt)
      dut.response.scan(/endpoint[^\s]*/).each do |ep|
        return find_sensor_name("#{dev_dir}/#{p}/#{ep}/remote-endpoint", dut)
      end
    end
  else
    dut.send_cmd("cat #{dev_dir}/status", dut.prompt)
    if dut.response.match(/^okay/im)
      return find_sensor_name("#{dev_dir}/port/endpoint/remote-endpoint", dut)
    end
  end
  nil
end

def find_sensor_name(ep_path, dut)
  devices = "/sys/devices/platform"
  fw_dir = "/sys/firmware/devicetree/base"
  dut.send_cmd("hexdump #{ep_path}", dut.prompt)
  handle = dut.response.match(/0000000[^\r\n]+/im)[0].strip()
  dut.send_cmd("find #{fw_dir} -name 'phandle' -print -exec hexdump {} \\; | grep -B1 '#{handle}'", dut.prompt)
  sensor_path = dut.response.match(/^#{fw_dir}[^\r\n]+/m)[0].gsub(fw_dir,'').gsub(/\/port\/endpoint.*\/phandle/,'')
  dut.send_cmd("grep -sr '#{sensor_path}' #{devices} | grep -v of_node", dut.prompt, 30)
  sensor_data = dut.response.match(/^\/sys\/.*OF_FULLNAME/m)[0]
  dut.send_cmd("cat #{File.dirname(sensor_data)}/name | xargs echo \"sensor: \"",dut.prompt)
  return dut.response.match(/^sensor: ([^\r\n]+)/m).captures[0].strip()
end

