include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  puts "timer test run"
  commands = ensure_commands = ""
  commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
  ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)  

  #t1 = Time.now 
  interval = @test_params.params_chan.interval[0].to_f    # in seconds
  boundary = @test_params.params_chan.boundary[0].to_f    # in seconds
  result, cmd = execute_cmd(commands)
  if result == 0
    t1 = /Gettimeofday\(\)\s+=\s+([\d\.]+)/.match(@equipment['dut1'].response).captures[0].to_f
    sleep interval 
    # send cmd again to get time
    execute_cmd(commands)
    t2 = /Gettimeofday\(\)\s+=\s+([\d\.]+)/.match(@equipment['dut1'].response).captures[0].to_f
    
    if (t2-t1) < 0 || ((t2-t1)-interval).abs > boundary then
      set_result(FrameworkConstants::Result[:fail], "The timer is not accurate enough. The diff is #{(t2-t1).to_s} comparing to #{interval}.")
    else      
      set_result(FrameworkConstants::Result[:pass], "Test Pass. The time between gettimeofday calls is #{(t2-t1).to_s} seconds comparing to #{interval}.")
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




