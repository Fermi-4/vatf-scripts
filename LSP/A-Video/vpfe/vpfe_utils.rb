require File.dirname(__FILE__)+'/../../../lib/utils'
require 'set'

#Function to obtain the parsed output of the sensorCapture -x command
#Returns a hash containing the configurable parameters of the parsed output
#returned by the -x option
def get_fmt_options(dut=@equipment['dut1'])
  result = {}
  opts_string = dut.send_cmd('sensorCapture -x', dut.prompt, 10).gsub(/#{dut.prompt}[^\n]+/,'')
  get_sections(opts_string, /^Available.*:/i).each do |section_name, info|
    result[section_name.gsub(/(?:available|:)\s*/i,'').gsub(/[\s]/,'-')] = get_entries(info)
  end
  result
end

#Function to obtain the parsed output of the sensorCapture usage command
#Returns a hash containing the configurable parameters of the parsed output
#returned by the sensor capture usage command
def get_sensor_capture_options(dut=@equipment['dut1'])
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
#    	-d => <Device file> : /dev/video0 (default)
#	    -z => nil           : pack 16/10 bits video data into 8 bits
#	    -i => <Input>       : 0 - Composite, 1 - Svideo
#	    -l => <Loop Count>  : Number of Iterations
#	    -m => <Memory mode> : 0 - MMAP, 1 - USER POINTER
#	    -b => <Brightness>  : 0 to 255
#	    -c => <Contrast>    : 0 to 255
#	    -s => <Saturation>  : 0 to 255
#	    -h => <Hue>         : -128 to 127
#	    -g => <AGC Gain>    : 0 or 1
#	    -p => <File path    : Output file path in strings
#	    -w => WxH           : Set the frame size [800x600]
#	    -f => <Pixel Format>:
#	    -k => <left,top,WxH>: Set crop values offset and size
def sensor_capture(params, timeout, dut=@equipment['dut1'])
  cmd = 'sensorCapture'
  params.each{|key,val| cmd += ' ' + key + ' ' + val.to_s}
  dut.send_cmd(cmd, dut.prompt, timeout)
end
