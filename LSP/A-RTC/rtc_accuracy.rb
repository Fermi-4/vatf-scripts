include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  puts "rtc accuracy test run"
  commands = ensure_commands = ""
  commands = parse_cmd('cmd') if @test_params.params_chan.instance_variable_defined?(:@cmd)
  ensure_commands = parse_cmd('ensure') if @test_params.params_chan.instance_variable_defined?(:@ensure)  

  #t1 = Time.now 
  interval = @test_params.params_chan.interval[0].to_f    # in seconds
  boundary = @test_params.params_chan.boundary[0].to_f    # in seconds
  test_loop = @test_params.params_chan.test_loop[0].to_i    # in seconds

  test_loop.times {|x|
    execute_cmd(commands)
    hrs,min,sec = /(\d+):(\d+):(\d+)/.match(@equipment['dut1'].response).captures
    t1 = sec.to_i + min.to_i * 60 + hrs.to_i * 3600
    sleep interval 
    # send cmd again to get time
    execute_cmd(commands)
    hrs,min,sec = /(\d+):(\d+):(\d+)/.match(@equipment['dut1'].response).captures
    t2 = sec.to_i + min.to_i * 60 + hrs.to_i * 3600
    if (t2-t1) < 0 || ((t2-t1)-interval).abs > boundary then
      set_result(FrameworkConstants::Result[:fail], "The rtc timer is not accurate enough. The diff is #{(t2-t1).to_s} comparing to #{interval}.")
      break
    else      
      set_result(FrameworkConstants::Result[:pass], "Test Pass. The last rtc time between calls is #{(t2-t1).to_s} seconds comparing to #{interval}.")
    end      
  }    
end

def clean
  self.as(LspTestScript).clean
end




