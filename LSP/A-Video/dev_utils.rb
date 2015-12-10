
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
