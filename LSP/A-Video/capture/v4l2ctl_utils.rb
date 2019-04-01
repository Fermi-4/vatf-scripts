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
  formats = opts_string.scan(/Pixel\s*Format\s*:\s*'\w+'\s*|\[\d+\]:\s*'[A-Z\d]+/im)
  frame_sizes = []
  formats.each do |fmt_str|
    result['pixel-format'] << fmt_str.match(/Pixel\s*Format\s*:\s*'(\w+)'\s*|\[\d+\]:\s*'([A-Z\d]+)/im).captures.select{|f| f}[0]
    dut.send_cmd("v4l2-ctl --list-framesizes=#{result['pixel-format'][-1]} -d #{capture_device}", dut.prompt, 10)
    result['frame-size'] += dut.response.scan(/Size:\s*Discrete\s*(\d+x\d+)\s*/i).flatten
  end
  #VIDIOC_ENUM_FRAMESIZES fails assume it is not a sensor but a video input
  if result['frame-size'].empty?
    opts_string = dut.send_cmd("v4l2-ctl --get-fmt-video -d #{capture_device}", dut.prompt, 10)
    result['frame-size'] = [opts_string.match(/Width\/Height\s*:\s*(\d+)\/(\d+)/im).captures*'x']
    result['pixel-format'] = [opts_string.match(/Pixel\s*Format\s*:\s*'(\w+)'/im).captures[0]]
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

#Function to obtain the video standards supported by an input, takes
# - capture_device, string containing the video dev node that will be
#                   queried
#Returns a hash containing <standard name> => <standard value> pairs,
#where <standard name> is a string containing the name of the standard
#PAL, NTSC, etc; and <standard value> is the IOCTL value that may be used
#to set the video input to the standard 
def get_video_standards(capture_device, dut=@equipment['dut1'])
  std_str = dut.send_cmd("v4l2-ctl -d #{capture_device} --list-standards", dut.prompt, 10)
  result = {}
  std_str.scan(/ID\s*:\s*([^\r\n]+)\s*Name\s*:\s*([^\r\n]+)/im) {|v,k| result[k.strip()] = v.strip()}
  result
end

#Function to obtain the set a video input to the given standard, takes
# - standard, string containing the name of the standard. I.e PAL, NTSC,
#              etc.
# - capture_device, string containing the video dev node that will be
#                   queried
#Returns true if succesful, false otherwise
def set_video_standard(standard, capture_device, dut=@equipment['dut1'])
  std_list = get_video_standards(capture_device, dut)
  std_resp = dut.send_cmd("v4l2-ctl -d #{capture_device} --set-standard=#{std_list[standard.upcase()]}", dut.prompt, 10)
  std_resp.match(/Standard\s*set\s*to\s*.0*#{std_list[standard.upcase()].sub(/0x0/,'')}/im) != nil
end

def sensor_capture(params, timeout, dut=@equipment['dut1'])
  dut.send_cmd("v4l2-ctl --device=#{params['--device']} --try-fmt-video=#{params['--set-fmt-video']}", dut.prompt, timeout)
  res_match = dut.response.match(/Width\/Height\s*:\s*(\d+)\/(\d+).*?/)
  skip_frames = 300
  cmd = "v4l2-ctl --stream-skip=100"
  params.merge({'--stream-count' => 1, '--stream-to' => '/dev/null'}).each{|key,val| cmd += ' ' + key + (val.to_s == '' ? '' : '=' + val.to_s)}
  dut.send_cmd(cmd, dut.prompt, timeout)
  fps = dut.response.scan(/[\d\.]+(?=\s*fps)/im).map(&:to_f)
  if !fps.empty?
    skip_frames=(mean(fps)*10).to_i
  end
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
