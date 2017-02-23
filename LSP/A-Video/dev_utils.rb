
#Function to fetch the test file in the dut and host
def get_type_devices(ip_type)
  @equipment['dut1'].send_cmd("ls /sys/class/video4linux/")
  video_devs = @equipment['dut1'].response.scan(/video\d+\s+/im)
  result = []
  video_devs.each do |dev|
    @equipment['dut1'].send_cmd("cat /sys/class/video4linux/#{dev.strip()}/name")
    result << dev.strip if @equipment['dut1'].response.downcase.include?(ip_type.downcase)
  end
  return result.empty? ? nil : result
end

#Function to obtain the bytes per pixel of a data format, takes
#  format, string with the format name
#Returns the length in bytes per pixel of the format
def get_format_length(format)
  return case(format)
           when 'SBGGR8'
             1
           when 'NV12', 'NV21', 'YU12', 'YV12'
             1.5 
           when 'UYVY', 'VYUY', 'YUYV', 'YVYU', 'NV16', 'NV61', 'RGB565X'
             2
           when 'BGR24', 'RGB24'
             3
           when 'RGB32', 'BGR32'
             4
           end
end
