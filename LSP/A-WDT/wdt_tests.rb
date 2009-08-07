# -*- coding: ISO-8859-1 -*-
include LspTestScript
def setup
  login_uut
  self.as(LspTestScript).setup
end

def run
  puts "wdt test run"
  commands = ensure_commands = ""
  commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
  ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)  

  t1 = Time.now 
  result, cmd = execute_cmd(commands)
  if result == 0
    t2 = Time.now
    #wdt_timeout = @test_params.params_chan.wdt_timeout[0].to_i + @test_params.params_chan.wdt_timeout_ext[0].to_i
    wdt_alive_period = @test_params.params_chan.wdt_alive_period[0].to_i 
    if (t2-t1) < (wdt_alive_period) || (t2-t1) > (wdt_alive_period+12) then
      set_result(FrameworkConstants::Result[:fail], "Dut boot but not in certain timeout period.The time between trigger and reboot is #{(t2-t1).to_s} seconds.")
    else      
      set_result(FrameworkConstants::Result[:pass], "Test Pass. The time between trigger and reboot is #{(t2-t1).to_s} seconds.")
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
  sleep 50
  login_uut
end



