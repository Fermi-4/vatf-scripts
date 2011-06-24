# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_default_test_module'
include C6xTestScript

  
def setup
  super
end

def run
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  dut = @equipment['dut1']
  linux_server = @equipment['server1']
  dut.send_cmd("uname -a",dut.prompt,10)
  endian = dut.response.match(/-le/)? "el" : "eb"
  platform = dut.response.match(/ti(c\d+\w)/).captures[0]
  dut.send_cmd("cat /proc/cpuinfo",dut.prompt,10)
  num_cores = dut.response.match(/SoC\scores:\s+(\d)/).captures[0].to_i
  puts "Platform:#{platform} Endian: #{endian} Number of cores: #{num_cores}"
  dut.send_cmd("cd #{SYSLINK_DST_DIR}/syslink_evm#{platform}.#{endian}",dut.prompt,10)
  @testcase = @test_params.params_chan.instance_variable_get("@syslink_testname")[0].to_s
  test_to_run = "#{@testcase}_app_test_#{num_cores}_core.sh"
  linux_core_response_regex=''
    case @testcase
    when "notify"
      times = num_cores*2
      linux_core_response_regex=/(?:.*?(?:Received\s+10000\s+events\s+for\s+event\s+ID\s+\d+\s+from\s+processor\s+\d+)){#{times}}/im
    when "gatemp"
     linux_core_response_regex=/Completed\s+9000\s+iterations\s+successfully/
    when "heapbufmp"  
      times = (num_cores-1)*2
      linux_core_response_regex = /(?:(?:.*?Allocating\s+from\s+\w+\s+Heap)(?:.*?HeapBufMP_\w+\.\s+\w+\s+\[0x[0-9a-e].*?\]){4}){#{times}}/im  
    when "heapmemmp"
      times = (num_cores-1)*2
      linux_core_response_regex = /(?:(?:.*?Allocating\s+from\s+\w+\s+Heap)(?:.*?HeapMemMP_\w+\.\s+\w+\s+\[0x[0-9a-e].*?\]){4}){#{times}}/im  
    when "messageq"
      times= (num_cores-1)
      linux_core_response_regex = /(.*?Sending\s+a\s+message\s+\#1000\s+to\s+\d){#{times}}/im
    when "listmp"
      linux_core_response_regex =/ListMP sample application run is complete/
    when "sharedregion"
      linux_core_response_regex = /(.*?Successfully\s+\w+\s+0x1000\s+bytes\s+\w+\s+heap\s+associated\s+with\s+sharedregion\s+\d+){4}/im
    end
  puts linux_core_response_regex
  sleep 5
  dut.send_cmd("./#{test_to_run}",linux_core_response_regex,300)

  if(!dut.timeout?)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end

  set_result(test_done_result,comment)
end

def clean

end



