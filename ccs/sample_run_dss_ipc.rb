require File.dirname(__FILE__)+'/default_ccs'

def run
  thr = Thread.new() {
    @equipment['dut1'].run_dss "/home/a0850405local/ti/dss-scripts/myplayground2.js", 20
  }
  
  data = ''
  begin 
    data = @equipment['dut1'].read_ipc_data(20)
    puts "\n==============================\nReceive Data:#{data}"
  rescue
    data = 'error'
  end
  
  thr.join
  
  if data.match(/hello/i)
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed")
  end
end