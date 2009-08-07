# -*- coding: ISO-8859-1 -*-
include LspTestScript
include Boot
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
    # check if dut is still up after wdt open long period.
    wdt_alive_period = @test_params.params_chan.wdt_alive_period[0].to_i
    sleep wdt_alive_period
    # if by this time, dut reboot, it will fail by 'is_uut_up' since no log in yet.
    if !is_uut_up? then
      set_result(FrameworkConstants::Result[:fail], "Dut is not alive.")
    else      
      set_result(FrameworkConstants::Result[:pass], "Test Pass. The dut is still up after #{wdt_alive_period} seconds.")
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
  #@equipment['dut1'].send_cmd("reboot", "login", 60)
  @equipment['apc1'].reset(@equipment['dut1'].power_port.to_s)
  sleep 50
  login_uut
end



