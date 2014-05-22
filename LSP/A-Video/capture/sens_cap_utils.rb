require File.dirname(__FILE__)+'/../../../lib/utils'
require 'set'

#Function to obtain the parsed output of the sensorCapture -x command, takes
# - capture_device, string containing the dev node of the capture device that
#                   will be queried for supported formats
#Returns a hash containing the configurable parameters of the parsed output
#returned by the -x option
def get_fmt_options(capture_device, dut=@equipment['dut1'])
  result = {}
  opts_string = dut.send_cmd("sensorCapture -x -d #{capture_device}", dut.prompt, 10).gsub(/#{dut.prompt}[^\n]+/,'')
  get_sections(opts_string, /^Available.*:/i).each do |section_name, info|
    result[section_name.gsub(/(?:available|:)\s*/i,'').gsub(/[\s]/,'-')] = get_entries(info)
  end
  result
end

#Function to obtain the parsed output of the sensorCapture usage command, takes
# - capture_device, string containing the video dev node that will be used to
#                   capture the frames
#Returns a hash containing the configurable parameters of the parsed output
#returned by the sensor capture usage command
def get_sensor_capture_options(capture_device, dut=@equipment['dut1'])
  result = {}
  opts_string = dut.send_cmd('sensorCapture -h', dut.prompt,10).gsub(/#{dut.prompt}[^\n]+/,'')
  get_sections(opts_string, /^\s*\[\-\w.*?\]\s*:/i).each do |section_name, info|
    option_match = section_name.match(/\[(-\w)\s*([^\]]*)/)
    opt = option_match[1]
    #"-b", "-c", "-s", "-h", "-g" are disabled until a board with support for controls is found
    #in order to parse the control fields appropriately
    next if ["-x", "-b", "-c", "-s", "-h", "-g"].include?(opt)
    
    result[opt] = case(info.strip())
                    when ''
                      option_match[2]
                    when /\d+\s*to\s*\d+/i
                      info.strip().split(/[^-\d]+/)
                    when /\d+\s*or\s*\d+/i
                      Set.new(info.strip().split(/[^-\d]+/))
                    when /\d+\s*-\s*\w+/
                      info_res = {}
                      info.scan(/(\d+)\s*-\s*(\w+)/).each do |o|
                        info_res[o[1].downcase()] = o[0]
                      end
                      info_res
                    else
                      info.strip.split(/[\r\n]+/)[0]
                    end
  end
  result['-d'] = capture_device
  result
end

#Function to obtain the a list of options based on the Available ...
#sections of the string returned by sensorCapture -x
#Returns a list containing the entries found in the section
def get_entries(info)
  Set.new(info.scan(/(?<=: )[^\r\n]+/)).to_a  
end


#Function to perform a sensor capture operataion on the dut, takes:
#  params, a Hash whose entries are:
#      -d => <Device file> : /dev/video0 (default)
#      -z => nil           : pack 16/10 bits video data into 8 bits
#      -i => <Input>       : 0 - Composite, 1 - Svideo
#      -l => <Loop Count>  : Number of Iterations
#      -m => <Memory mode> : 0 - MMAP, 1 - USER POINTER
#      -b => <Brightness>  : 0 to 255
#      -c => <Contrast>    : 0 to 255
#      -s => <Saturation>  : 0 to 255
#      -h => <Hue>         : -128 to 127
#      -g => <AGC Gain>    : 0 or 1
#      -p => <File path    : Output file path in strings
#      -w => WxH           : Set the frame size [800x600]
#      -f => <Pixel Format>:
#      -k => <left,top,WxH>: Set crop values offset and size
def sensor_capture(params, timeout, dut=@equipment['dut1'])
  cmd = 'sensorCapture'
  params.each{|key,val| cmd += ' ' + key + ' ' + val.to_s}
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
    if opt == '-w'
      test_params[opt] = resolution.strip()
    elsif opt == '-f'
      test_params[opt] = pix_fmt.strip()
    elsif opt == '-d'
      test_params[opt] = vals
      test_params[opt] = @test_params.params_chan.device[0] if @test_params.params_chan.instance_variable_defined?(:@device)
    elsif opt == '-l'
      test_params[opt] = @test_params.params_chan.iterations[0] if @test_params.params_chan.instance_variable_defined?(:@iterations)
      test_params[opt] = 1 if ["SBGGR8", "SGBRG8", "SGRBG8", "SRGGB8"].include?(pix_fmt)
    elsif opt == '-p'
      test_params[opt] = capture_path
    elsif opt == '-z'
      test_params[opt] = nil if @test_params.params_chan.instance_variable_defined?(:@compact)
#   elsif opt == '-k'    #Commented out, place holder for crop feature. Uncomment and change
#     left = 16*res_idx  #(if needed) once crop is implemented in sensorCapture app
#     top = 16*pix_idx
#     width = width.to_i - left
#     height = height.to_i - top
#     test_params[opt] = "#{left},#{top},#{width}x#{height}" if pix_idx % 2 == 1
    elsif vals.kind_of?(Set)
      test_params[opt] = vals.to_a[(pix_idx + rand(0..1)) % vals.length]
    elsif vals.kind_of?(Array)
      test_params[opt] = rand(vals[0].to_i..vals[1].to_i)
    elsif vals.kind_of?(Hash)
      if opt == "-m" && @test_params.params_chan.instance_variable_defined?(:@mem_mode)
        test_params[opt] = vals[@test_params.params_chan.mem_mode[0].downcase()]
      elsif opt == "-i" && @test_params.params_chan.instance_variable_defined?(:@input_type)
        test_params[opt] = vals[@test_params.params_chan.input_type[0].downcase()]
      else
        hash_vals = vals.values
        test_params[opt] = hash_vals[(pix_idx + rand(0..1)) % hash_vals.length]
      end
    end
  end
  test_params
end
