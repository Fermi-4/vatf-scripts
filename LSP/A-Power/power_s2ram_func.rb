require File.dirname(__FILE__)+'/../TARGET/dev_test2'

def setup
  self.as(LspTargetTestScript).setup
end

def run
  get_ip
  configure_dut
  run_generate_script
  run_transfer_script
  @stop_test = false
  @start_suspend_loop = false
  query_pm_stats
  test_thr = start_target_tests
  while !@start_suspend_loop
    sleep 1
  end
  sleep 5                           # Give tests thread a 5 secs head start
  suspend_thr = suspend_resume_loop
  result = test_thr.value           # This will block (join) until test_thr completes
  set_result(result[0], result[1]) 
  @stop_test = true
  suspend_thr.join
  query_pm_stats
end

def get_ip
  @eth_ip_addr = get_ip_addr()   # get_ip_addr() is defined at default_target_test.rb
  raise "Can't run the test because DUT does not seem to have an IP address configured" if !@eth_ip_addr
end

def configure_dut
  @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 3)
  @equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies", @equipment['dut1'].prompt, 3)
  supported_frequencies = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    
  if @test_params.params_chan.sleep_while_idle[0] != '0' ||  @test_params.params_chan.enable_off_mode[0] != '0'
    @equipment['dut1'].send_cmd("mkdir /debug", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("mount -t debugfs debugfs /debug", @equipment['dut1'].prompt)
    #@equipment['dut1'].send_cmd("echo #{@test_params.params_chan.sleep_while_idle[0]} > /debug/pm_debug/sleep_while_idle", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > /debug/pm_debug/enable_off_mode", @equipment['dut1'].prompt) 
  end
 
  if @test_params.params_chan.cpufreq[0] != '0' 
    # put device in avaiable OPP states
    raise "This dut does not support #{@test_params.params_chan.dvfs_freq[0]} Hz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(@test_params.params_chan.dvfs_freq[0])
    @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.dvfs_freq[0]} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 3)
    new_opp = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    raise "Could not set #{@test_params.params_chan.dvfs_freq[0]} OPP" if !new_opp.include?(@test_params.params_chan.dvfs_freq[0])
  end
end


def start_target_tests
  thr = Thread.new {
    time = Time.now
    failure = false
    suspend_time = @test_params.params_chan.suspend_time[0].to_i
    resume_time = @test_params.params_chan.resume_time[0].to_i
    result = [FrameworkConstants::Result[:pass], "Test completed without errors"]
    @equipment['dut1'].target.platform_info.telnet_ip = @eth_ip_addr
    @equipment['dut1'].target.platform_info.telnet_port = 23
    @equipment['dut1'].connect({'type'=>'telnet'})
    @equipment['dut1'].target.telnet.send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    @equipment['dut1'].target.telnet.send_cmd("chmod +x test.sh",@equipment['dut1'].prompt)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
    cmd_timeout *= ((suspend_time + resume_time + 5) / resume_time)       #5 is max wait time to suspend
    @start_suspend_loop = true
    
    while ((Time.now - time) < @test_params.params_control.test_duration[0].to_f && !failure && !@stop_test )
      begin
        
        @equipment['dut1'].target.telnet.send_cmd("./test.sh 2> stderr.log > stdout.log 3> result.log",@equipment['dut1'].prompt, cmd_timeout)
      rescue Timeout::Error => e
        @equipment['dut1'].log_info("Telnet TIMEOUT ERROR. Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
        result = [FrameworkConstants::Result[:fail], "DUT is either not responding or took more that #{cmd_timeout} seconds to run the test"]
        failure = true
      end
      @equipment['dut1'].log_info("Telnet Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
      begin
        @equipment['dut1'].target.telnet.send_cmd("echo $?",/^0[\0\n\r]+/m, suspend_time + 10) if !failure  
      rescue Timeout::Error => e
        @equipment['dut1'].log_info("Telnet TIMEOUT ERROR. Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
        result = [FrameworkConstants::Result[:fail], "Test returned non-zero value"]
        failure = true
      end
    end
    
    result
  }
  return thr
end

def suspend_resume_loop
  suspend_time = @test_params.params_chan.suspend_time[0].to_i
  resume_time = @test_params.params_chan.resume_time[0].to_i
  thr = Thread.new {
    while (!@stop_test) 
      #Suspend
      @equipment['dut1'].send_cmd("sync; echo mem > /sys/power/state", /Freezing remaining freezable tasks/, 5)
      raise "DUT took more than 5 seconds to suspend" if @equipment['dut1'].timeout?
      sleep suspend_time    
      # Resume from console
      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 5)  # Try to resume 2
      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 5)  # times, just in case
      raise "DUT took more than 5 seconds to resume" if @equipment['dut1'].timeout?
      sleep resume_time 
    end
  }
  return thr
end

def query_pm_stats
  puts "\n\n======= Power Domain transition stats =======\n"
  @equipment['dut1'].send_cmd("cat /debug/pm_debug/count", @equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("find /sys/devices/system/cpu/cpu0/cpuidle/ -name \"state*\" -exec cat {}/time \\;", @equipment['dut1'].prompt)
  
end
