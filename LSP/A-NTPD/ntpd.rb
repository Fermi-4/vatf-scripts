# Compares date obtained from NTP server on DUT and host PC and ensures the two values are within acceptable limits
require 'date'
require File.dirname(__FILE__)+'/../TARGET/dev_test2'

def setup
  super
end

def run
  # if no offset is defined in test case, 10 seconds is used as a default value
  offset = @test_params.params_chan.instance_variable_defined?(:@offset) ? @test_params.params_chan.offset[0] : 10
  # if no ntp_server is defined, use default that works
  ntp_server = @test_params.params_chan.instance_variable_defined?(:@ntp_server) ? @test_params.params_chan.ntp_server[0] : 'letime.itg.ti.com'

  @equipment['dut1'].send_cmd("echo server #{ntp_server} > /etc/testntpd.conf", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("ntpd -sf /etc/testntpd.conf", @equipment['dut1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("ntpdate #{ntp_server}", @equipment['server1'].prompt, 10)
  @equipment['dut1'].send_cmd("date -u", @equipment['dut1'].prompt)
  @equipment['server1'].send_cmd("date -u", @equipment['server1'].prompt)
  # read date response into DateTime format for comparison
  dut_time=DateTime.parse(@equipment['dut1'].response)
  server_time=DateTime.parse(@equipment['server1'].response)
  # get absolute time difference in seconds
  time_diff=(((server_time-dut_time)*24*3600).to_i).abs
  @equipment['server1'].log_info("DUT_TIME is #{dut_time} and SERVER_TIME is #{server_time} ")
  if (time_diff <= offset)
     set_result(FrameworkConstants::Result[:pass], "Test Passed. Observed offset is #{time_diff} and allowed offset is #{offset}\n")
  else
     set_result(FrameworkConstants::Result[:fail], "Test Failed. Observed offset is #{time_diff} and allowed offset is #{offset}\n")
  end
end

def clean
  super
  @equipment['dut1'].send_cmd("rm /etc/testntpd.conf", @equipment['dut1'].prompt)
end
