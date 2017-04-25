require File.dirname(__FILE__)+'/../../../lib/utils'
require 'set'

#Function to obtain the parsed output of the sensorCapture -x command, takes
# - capture_device, string containing the dev node of the capture device that
#                   will be queried for supported formats
#Returns a hash containing the configurable parameters of the parsed output
#returned by the -x option
def get_fmt_options(capture_device, dut=@equipment['dut1'])
  result = {'pixel-format' => [], 'frame-size' => []}
  opts_string = dut.send_cmd("v4l2-ctl --list-formats -d #{capture_device}", dut.prompt, 10).gsub(/#{dut.prompt}[^\n]+/,'')
  formats = opts_string.scan(/Pixel\s*Format\s*:\s*'\w+'\s*/i)
  frame_sizes = []
  frame_sizes.each do |siz|
    
  end
  formats.each do |fmt_str|
    result['pixel-format'] << fmt_str.match(/Pixel\s*Format\s*:\s*'(\w+)'\s*/i).captures[0]
    dut.send_cmd("v4l2-ctl --list-framesizes=#{result['pixel-format'][-1]} -d #{capture_device}", dut.prompt, 10)
    result['frame-size'] += dut.response.scan(/Size:\s*Discrete\s*(\d+x\d+)\s*/i).flatten
  end
  result['frame-size'] = Set.new(result['frame-size']).to_a.sort() {|v1, v2| v2.split('x').map(&:to_i).inject(:*) <=> v1.split('x').map(&:to_i).inject(:*)} 
  result
end

#Function to obtain the parsed output of the sensorCapture usage command, takes
# - capture_device, string containing the video dev node that will be used to
#                   capture the frames
#Returns a hash containing the configurable parameters of the parsed output
#returned by the sensor capture usage command
def get_sensor_capture_options(capture_device, dut=@equipment['dut1'])
  {'--device' => capture_device,
    '--set-fmt-video' => '',
    '--stream-to' => '',
    '--stream-count' => '',
    '--stream-poll' => '',
    '--stream-mmap' => '',
  }
end

def sensor_capture(params, timeout, dut=@equipment['dut1'])
  dut.send_cmd("v4l2-ctl --device=#{params['--device']} --try-fmt-video=#{params['--set-fmt-video']}", dut.prompt, timeout)
  res_match = dut.response.match(/Width\/Height\s*:\s*(\d+)\/(\d+).*?/)
  skip_frames = 150
  skip_frames = [(200*1280*720/(res_match.captures[0].to_i*res_match.captures[1].to_i)).to_i,400].min if res_match
  cmd = "v4l2-ctl --stream-skip=#{skip_frames}"
  params.each{|key,val| cmd += ' ' + key + (val.to_s == '' ? '' : '=' + val.to_s)}
  dut.send_cmd(cmd, dut.prompt, timeout)
  return res_match.captures if res_match
  [nil, nil]
end

#Fuction to obtain the test parameter for the sensorCapture app, takes:
# - capture_opts, a hash containing the sensorCapture app "-?" options with
#                 the values allowed for that option
# - resolution, the resolution of the frames that will be captured
# - pix_fmt, the pixel format of the captured frame
# - capture_path, path of the file where the captured frames will be stored
def get_test_opts(capture_opts, resolution, pix_fmt, capture_path)
  test_params = {}
  width,  height = resolution.split(/x/i)
  capture_opts.each do |opt,vals|
    case opt
      when '--set-fmt-video'
        width, height = resolution.split(/x/)
        test_params[opt] = "pixelformat=#{pix_fmt},width=#{width},height=#{height}"
      when '--stream-to'
        test_params[opt] = capture_path
      when '--stream-count'
        test_params[opt] = 70
      when '--stream-poll'
        test_params[opt] = ''
      when '--stream-mmap'
        test_params[opt] = 6
      else
        test_params[opt] = vals
    end
  end
  test_params
end
