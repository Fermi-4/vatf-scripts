require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  puts "timer test run"
  commands = ensure_commands = ""
  commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
  ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)  

  expected_resolution = @test_params.params_chan.expected_resolution[0].to_f    # in seconds
  time_to_finish = @test_params.params_chan.time_to_finish[0].to_f    # in seconds
  t1 = Time.now
  result, cmd = execute_cmd(commands)
  if result == 0
    t2 = Time.now    
    if (t2-t1) < 0 || (t2-t1) > time_to_finish then
      set_result(FrameworkConstants::Result[:fail], "The test is not get over in #{(t2-t1).to_s} seconds.")
    else 
      # check the resolution
      res = /resolution\s+is:\s+(\d+)/.match(@equipment['dut1'].response).captures[0].to_f        
      if res != expected_resolution then
        set_result(FrameworkConstants::Result[:fail], "the resolution is reported as: #{res.to_s}.")
      else
        set_result(FrameworkConstants::Result[:pass], "Test Pass. The time between gettimeofday calls is #{(t2-t1).to_s} seconds.")
      end
    end      
      
  elsif result == 1
      set_result(FrameworkConstants::Result[:fail], "Timeout executing cmd: #{cmd.cmd_to_send}")
  elsif result == 2
      set_result(FrameworkConstants::Result[:fail], "Fail message received executing cmd: #{cmd.cmd_to_send}")
  else
      set_result(FrameworkConstants::Result[:nry])
  end
  ensure 
      result, cmd = execute_cmd(ensure_commands)
end

def clean
  self.as(LspTestScript).clean
end




