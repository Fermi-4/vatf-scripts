require File.dirname(__FILE__)+'/../../../lib/utils'
require 'set'

#Function to obtain the parsed output of the sensorCapture -x command, takes
# - capture_device, string containing the dev node of the capture device that
#                   will be queried for supported formats
#Returns a hash containing the configurable parameters of the parsed output
#returned by the -x option
def get_fmt_options(capture_device, dut=@equipment['dut1'])
  result = {'pixel-format' => [], 'frame-size' => []}
  opts_string = dut.send_cmd("yavta --enum-formats #{capture_device}", dut.prompt, 10).gsub(/#{dut.prompt}[^\n]+/,'')
  formats = opts_string.scan(/Format\s*\d+:\s*\w+\s*\(\w+\)/i)
  frame_sizes = opts_string.scan(/Frame\s*size:\s*\d+x\d+\s*\(.*?\)/i)
  formats.each do |fmt_str|
    result['pixel-format'] << fmt_str.match(/Format\s*\d+:\s*(\w+)\s*\(\w+\)/i).captures[0]
  end
  frame_sizes.each do |siz|
    result['frame-size'] << siz.match(/Frame\s*size:\s*(\d+x\d+)\s*\(.*?\)/i).captures[0]
  end
  result['frame-size'] = Set.new(result['frame-size']).to_a
  result
end

#Function to obtain the parsed output of the sensorCapture usage command, takes
# - capture_device, string containing the video dev node that will be used to
#                   capture the frames
#Returns a hash containing the configurable parameters of the parsed output
#returned by the sensor capture usage command
def get_sensor_capture_options(capture_device, dut=@equipment['dut1'])
  result = {}
  opts_string = dut.send_cmd('yavta', dut.prompt,10).gsub(/#{dut.prompt}[^\n]+/,'')
  opts_string.scan(/(?:-\w, ){0,1}--[^\s]+/).each do |opt|
    result[opt.split(', ')[0]] = ''
  end
  result[''] = capture_device
  result
end


#Function to perform a sensor capture operataion on the dut, takes:
#  params, a Hash whose entries are:
#    -B, --buffer-type    Buffer type ("capture", "output",
#                                    "capture-mplane" or "output-mplane")
#    -c, --capture[=nframes]    Capture frames
#    -C, --check-overrun    Verify dequeued frames for buffer overrun
#    -d, --delay      Delay (in ms) before requeuing buffers
#    -f, --format format    Set the video format
#    -F, --file[=name]    Read/write frames from/to disk
#                         For video capture devices, the first '#' character in
#                         the file name is expanded to the frame sequence number.                    
#                         The default file name is 'frame-#.bin'.
#    -h, --help      Show this help screen
#    -i, --input input    Select the video input
#    -I, --fill-frames    Fill frames with check pattern before queuing them
#    -l, --list-controls    List available controls
#    -n, --nbufs n      Set the number of video buffers
#    -p, --pause      Pause before starting the video stream
#    -q, --quality n      MJPEG quality (0-100)
#    -r, --get-control ctrl    Get control 'ctrl'
#    -R, --realtime=[priority]  Enable realtime RR scheduling
#    -s, --size WxH      Set the frame size
#    -t, --time-per-frame num/denom  Set the time per frame (eg. 1/25 = 25 fps)
#    -u, --userptr      Use the user pointers streaming method
#    -w, --set-control 'ctrl value'  Set control 'ctrl' to 'value'
#        --enum-formats    Enumerate formats
#        --enum-inputs    Enumerate inputs
#        --fd                        Use a numeric file descriptor insted of a device
#        --no-query      Don't query capabilities on open
#        --offset      User pointer buffer offset from page start
#        --requeue-last    Requeue the last buffers before streamoff
#        --timestamp-source    Set timestamp source on output buffers [eof, soe]
#        --skip n      Skip the first n frames
#        --sleep-forever    Sleep forever after configuring the device
#        --stride value    Line stride in bytes
def sensor_capture(params, timeout, dut=@equipment['dut1'])
  cmd = 'yavta'
  params.each{|key,val| cmd += ' ' + key + val.to_s}
  dut.send_cmd(cmd, dut.prompt, timeout)
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
      when '-s'
        test_params[opt] = resolution
      when '-f'
        test_params[opt] = pix_fmt
      when '-F'
        test_params[opt] = capture_path
      when '-c'
        test_params[opt] = 70
        test_params[opt] = 1 if ["SBGGR8", "SGBRG8", "SGRBG8", "SRGGB8"].include?(pix_fmt)
      when ''
        test_params[opt] = vals
      else
         puts "Option #{opt} not used at the moment"
    end
  end
  test_params
end
