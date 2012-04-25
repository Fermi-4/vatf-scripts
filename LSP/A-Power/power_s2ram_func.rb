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
  while status = test_thr.status
    puts "test_thr status=#{status}"
    puts "suspend_thr status=#{suspend_thr.status.to_s}"
    sleep 1
  end
  result = test_thr.value           # This will block (join) until test_thr completes
  set_result(result[0], result[1]) 
  @stop_test = true
  suspend_thr.join
  query_pm_stats
  show_execution_logs
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
    cmd_timeout *= ((suspend_time + resume_time + 15) / resume_time)       #15 is approx max observed wait time to suspend
    @start_suspend_loop = true
    
    #while ((elapsed = Time.now - time) < @test_params.params_control.test_duration[0].to_f && !failure && !@stop_test )
    while ((elapsed = Time.now - time) < 10800 && !failure && !@stop_test )
      begin
        #puts "At least #{@test_params.params_control.test_duration[0].to_f - elapsed} seconds to go"
        puts "At least #{10800 - elapsed} seconds to go"
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
  if(@test_params.params_chan.instance_variable_defined?(:@wakeup_domain) && @test_params.params_chan.wakeup_domain[0].to_s=='rtc')
    @equipment['dut1'].send_cmd( "[ -e /dev/rtc0 ]; echo $?", /^0[\0\n\r]+/m, 2)
    raise "DUT does not seem to support rtc wakeup. /dev/rtc0 does not exist"  if @equipment['dut1'].timeout?
    thr = Thread.new {
    while (!@stop_test) 
      #Suspend
      puts "GOING TO SUSPEND DUT - rtcwake case"
      @equipment['dut1'].send_cmd("rtcwake -d /dev/rtc0 -m mem -s #{suspend_time}", /Freezing remaining freezable tasks/, 60)
      if @equipment['dut1'].timeout?
        puts "Timeout while waiting to suspend"
        raise "DUT took more than 60 seconds to suspend" 
      end
      sleep suspend_time  
      # Verify Resume
      puts "EXPECTING DUT TO RESUME"
      @equipment['dut1'].wait_for(/resume of devices complete/,10)
      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 5) # just in case resume string was not read, checking to see if prompt is returned indicating that device has resumed
      if @equipment['dut1'].timeout?
       puts "Timeout while waiting to resume"
       raise "DUT took more than #{suspend_time}+10 seconds to resume" 
      end
      sleep resume_time 
    end
  }

  else
  thr = Thread.new {
    while (!@stop_test) 
      #Suspend
      puts "GOING TO SUSPEND DUT"
      @equipment['dut1'].send_cmd("sync; echo mem > /sys/power/state", /Freezing remaining freezable tasks/, 60)
      if @equipment['dut1'].timeout?
        puts "Timeout while waiting to suspend"
        raise "DUT took more than 60 seconds to suspend" 
      end
      sleep suspend_time    
      # Resume from console
      puts "GOING TO RESUME DUT"
      @equipment['dut1'].send_cmd("\n\n\n", @equipment['dut1'].prompt, 1)  # Try to resume
      @equipment['dut1'].send_cmd("\n\n\n", @equipment['dut1'].prompt, 1)  # Try to resume 
      @equipment['dut1'].send_cmd("\n\n\n", @equipment['dut1'].prompt, 1)  # Try to resume 
      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 15)  # One last time
      if @equipment['dut1'].timeout?
        puts "Timeout while waiting to resume"
        raise "DUT took more than 15 seconds to resume" 
      end
      sleep resume_time 
    end
  }
  end
  return thr
end

def query_pm_stats
  puts "\n\n======= Power Domain transition stats =======\n"
  @equipment['dut1'].send_cmd("cat /debug/pm_debug/count", @equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("find /sys/devices/system/cpu/cpu0/cpuidle/ -name \"state*\" -exec cat {}/time \\;", @equipment['dut1'].prompt)
end

def show_execution_logs
  @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("cat stdout.log",@equipment['dut1'].prompt,120)
  @equipment['dut1'].send_cmd("cat stderr.log",@equipment['dut1'].prompt,60)
end
