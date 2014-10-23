require File.dirname(__FILE__)+'/../TARGET/dev_test2'
require File.dirname(__FILE__)+'/power_functions' 

include PowerFunctions

def setup
  self.as(LspTargetTestScript).setup
  @DEBUGFS_PATH='/sys/kernel/debug/'
end

def run
  @mutex = Mutex.new
  time = Time.now
  get_ip
  configure_dut
  run_generate_script
  run_transfer_script
  @stop_test = false
  @global_stop = false
  @start_suspend_loop = false
  @queue = Queue.new
  query_pm_stats
  test_thr = start_target_tests
  test_thr.priority = 1  # Increase its priority compared to suspend/resume thread
  while !@start_suspend_loop
    sleep 1
  end
  sleep 5                           # Give tests thread a 5 secs head start
  suspend_thr = suspend_resume_loop
  while ((elapsed = Time.now - time) < @test_params.params_control.test_duration[0].to_f) && (status = test_thr.status) && !@global_stop
    puts "Elapsed Time: #{elapsed} seconds"
    puts "test_thr status=#{status}, suspend_thr status=#{suspend_thr.status.to_s}"
    sleep 1
  end
  puts "\n===> Test time achieved. Going to stop test"
  @global_stop = true
  @stop_test = true
  puts "\n===> waiting on suspend_thr"
  suspend_thr.join
  puts "\n===> waiting on test_thr"
  result = test_thr.value           # This will block (join) until test_thr completes
  puts "\n===> all threads finished"
  set_result(result[0], result[1]) 
  query_pm_stats
  show_execution_logs
end

def get_ip
  @eth_ip_addr = get_ip_addr()   # get_ip_addr() is defined at default_target_test.rb
  raise "Can't run the test because DUT does not seem to have an IP address configured" if !@eth_ip_addr
end

def configure_dut
  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'
  wakeup_domain = @test_params.params_chan.instance_variable_defined?(:@wakeup_domain) ? @test_params.params_chan.wakeup_domain[0] : 'uart'

  @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 3)
  @equipment['dut1'].send_cmd(" cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies", @equipment['dut1'].prompt, 3)
  supported_frequencies = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }

  # Check debugfs is available
  raise "debugfs is not available at #{@DEBUGFS_PATH}" if !dut_dir_exist? @DEBUGFS_PATH
  
  # Enable cpu idle  
  @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.sleep_while_idle[0]} > #{@DEBUGFS_PATH}pm_debug/sleep_while_idle", @equipment['dut1'].prompt)
  
  # Enable off mode (RTC-only wakeup)
  @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.enable_off_mode[0]} > #{@DEBUGFS_PATH}pm_debug/enable_off_mode", @equipment['dut1'].prompt) 
  
  
  if @test_params.params_chan.cpufreq[0] != '0' 
    # put device in avaiable OPP states
    raise "This dut does not support #{@test_params.params_chan.dvfs_freq[0]} Hz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(@test_params.params_chan.dvfs_freq[0])
    @equipment['dut1'].send_cmd("echo #{@test_params.params_chan.dvfs_freq[0]} > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed", @equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", @equipment['dut1'].prompt, 3)
    new_opp = @equipment['dut1'].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    raise "Could not set #{@test_params.params_chan.dvfs_freq[0]} OPP" if !new_opp.include?(@test_params.params_chan.dvfs_freq[0])
  end

  power_wakeup_configuration(wakeup_domain, power_state)

end

def start_target_tests
  thr = Thread.new {
    time = Time.now
    failure = false
    suspend_time = @test_params.params_chan.suspend_time[0].to_i
    resume_time = @test_params.params_chan.resume_time[0].to_i + 1 # Give extra second for ethernet bringup
    result = [FrameworkConstants::Result[:pass], "Test completed without errors"]
    @equipment['dut1'].target.platform_info.telnet_ip = @eth_ip_addr
    @equipment['dut1'].target.platform_info.telnet_port = 23
    @equipment['dut1'].connect({'type'=>'telnet'})
    @equipment['dut1'].target.telnet.send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    @equipment['dut1'].target.telnet.send_cmd("chmod +x test.sh",@equipment['dut1'].prompt)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    @equipment['dut1'].target.telnet.send_cmd("export IPERFHOST=#{@equipment['server1'].telnet_ip}", @equipment['dut1'].prompt) if @equipment['server1'].respond_to?(:telnet_ip)
    @equipment['dut1'].log_info("Telnet Data: \n #{@equipment['dut1'].target.telnet.response}")
    cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
    cmd_timeout *= ((suspend_time + resume_time + 60)*1.0 / resume_time).ceil  #60 is approx max observed wait time in suspend/resume transitions
    @queue.push(1)  # Just to get this Thread going for the first time w/out waiting for suspend thread
    @start_suspend_loop = true
    
    while ( !failure && !@stop_test && !@global_stop )
      begin
        # Don't try to start test while DUT is sleeping
        @queue.pop # Wait for indication from suspend_resume thread
        @equipment['dut1'].log_info("STARTING TEST with cmd: ./test.sh 2> stderr.log > stdout.log 3> result.log")
        @equipment['dut1'].target.telnet.send_cmd("./test.sh 2> stderr.log > stdout.log 3> result.log",@equipment['dut1'].prompt, cmd_timeout)
      rescue Timeout::Error => e
        @equipment['dut1'].log_info("Telnet TIMEOUT ERROR. Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
        result = [FrameworkConstants::Result[:fail], "DUT is either not responding or took more that #{cmd_timeout} seconds to run the test"]
        failure = true
      end
      @equipment['dut1'].log_info("Telnet Session Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
      begin
        @equipment['dut1'].log_info("Telnet Session get return value")
        @mutex.synchronize do
          @equipment['dut1'].target.telnet.send_cmd("echo $?",/^0[\0\n\r]+/m, suspend_time + 30) if !failure  
        end
        @equipment['dut1'].log_info("Telnet Session Return Value:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Return value END")
      rescue Timeout::Error => e
        @equipment['dut1'].log_info("Telnet Session TIMEOUT ERROR. Data START:\n #{@equipment['dut1'].target.telnet.response}\nTelnet Data END")
        result = [FrameworkConstants::Result[:fail], "Test returned non-zero value"]
        failure = true
      end
    end
    
    result
  }
  return thr
end

def suspend_resume_loop
  suspend_time = @test_params.params_chan.suspend_time[0].to_i + rand(10)
  resume_time = @test_params.params_chan.resume_time[0].to_i + 1 # Give extra second for ethernet bringup
  power_state = @test_params.params_chan.instance_variable_defined?(:@power_state) ? @test_params.params_chan.power_state[0] : 'mem'

  if(@test_params.params_chan.instance_variable_defined?(:@wakeup_domain) && @test_params.params_chan.wakeup_domain[0].to_s=='rtc')
    @equipment['dut1'].send_cmd( "[ -e /dev/rtc0 ]; echo $?", /^0[\0\n\r]+/m, 2)
    raise "DUT does not seem to support rtc wakeup. /dev/rtc0 does not exist"  if @equipment['dut1'].timeout?
    thr = Thread.new {
    while (!@stop_test) 
      puts "GOING TO SUSPEND DUT - rtcwake case"
      @mutex.synchronize do
        @equipment['dut1'].send_cmd("sync", @equipment['dut1'].prompt, 120)
        @equipment['dut1'].send_cmd("rtcwake -d /dev/rtc0 -m #{power_state} -s #{suspend_time}", /resume\s+of\s+devices\s+complete/i, suspend_time+60, false)
      end
      if @equipment['dut1'].timeout?
        puts "Timeout while waiting for RTC suspend/resume completion"
        @queue.push(1)  # Inform test thread that dut is awake
        @global_stop = true
        report_and_exit "DUT took more than #{suspend_time+60} seconds to suspend/resume" 
      end
      @queue.push(1)  # Inform test thread that dut is awake
      sleep resume_time 
    end
    @queue.push(1)  # Extra one to avoid lock in atypical case where test thread run faster than suspend thread
  }

  else
  thr = Thread.new {
    while (!@stop_test) 
      puts "GOING TO SUSPEND DUT"
      @mutex.synchronize do
        @equipment['dut1'].send_cmd("sync; echo #{power_state} > /sys/power/state", /Freezing remaining freezable tasks/, 120, false)
      end
      if @equipment['dut1'].timeout?
        puts "Timeout while waiting to suspend"
        report_and_exit "DUT took more than 120 seconds to suspend" 
      end
      sleep suspend_time    
      # Resume from console
      puts "GOING TO RESUME DUT"
      @equipment['dut1'].send_cmd("\n\n\n", @equipment['dut1'].prompt, 1)  # Try to resume
      @equipment['dut1'].send_cmd("\n\n\n", @equipment['dut1'].prompt, 1)  # Try to resume 
      @equipment['dut1'].send_cmd("\n\n\n", @equipment['dut1'].prompt, 1)  # Try to resume 
      @equipment['dut1'].send_cmd("", @equipment['dut1'].prompt, 60)  # One last time
      if @equipment['dut1'].timeout?
        puts "Timeout while waiting to resume"
        @queue.push(1)  # Inform test thread that dut is awake
        @global_stop = true
        report_and_exit "DUT took more than 60 seconds to resume" 
      end
      @queue.push(1)  # Inform test thread that dut is awake
      sleep resume_time 
    end
    @queue.push(1)  # Extra one to avoid lock in atypical case where test thread run faster than suspend thread
  }
  end
  return thr
end

def query_pm_stats
  puts "\n\n======= Power Domain transition stats =======\n"
  @equipment['dut1'].send_cmd("cat #{@DEBUGFS_PATH}pm_debug/count", @equipment['dut1'].prompt) 
  @equipment['dut1'].send_cmd("cat /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state", @equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("find /sys/devices/system/cpu/cpu0/cpuidle/ -name \"state*\" -exec cat {}/time \\;", @equipment['dut1'].prompt)
end

def show_execution_logs
  @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("cat stdout.log",@equipment['dut1'].prompt,120)
  @equipment['dut1'].send_cmd("cat stderr.log",@equipment['dut1'].prompt,60)
end
