module PowerFunctions

  # Set operating point on cpu specified. opp units in KHz as expected by cpufreq
  def set_opp_freq(opp, cpu=0, e='dut1')
    @equipment[e].send_cmd("cat /sys/devices/system/cpu/cpu#{cpu}/cpufreq/scaling_available_frequencies", @equipment[e].prompt)
    supported_frequencies = @equipment[e].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    raise "This dut does not support #{opp} KHz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(opp)
    @equipment[e].send_cmd("echo #{opp} > /sys/devices/system/cpu/cpu#{cpu}/cpufreq/scaling_setspeed", @equipment[e].prompt)
    @equipment[e].send_cmd("cat /sys/devices/system/cpu/cpu#{cpu}/cpufreq/scaling_cur_freq", @equipment[e].prompt)
    new_opp = @equipment[e].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    raise "Could not set #{opp} KHz" if !new_opp.include?(opp)
  end

  def suspend(wakeup_domain, power_state, suspend_time, e='dut1')
    @equipment[e].send_cmd("sync", @equipment[e].prompt, 120)
    if wakeup_domain == 'uart' or wakeup_domain == 'gpio'
      @equipment[e].send_cmd("echo #{power_state} > /sys/power/state", /Freezing remaining freezable tasks/i, suspend_time, false)
    elsif wakeup_domain == 'rtc'
      @equipment[e].send_cmd("rtcwake -d /dev/rtc0 -m #{power_state} -s #{suspend_time}", /Freezing remaining freezable tasks/i, suspend_time, false)
    else
      raise "#{wakeup_domain} wakeup domain is not supported"
    end
    raise "DUT took more than #{suspend_time} seconds to suspend" if @equipment[e].timeout?
    sleep 2 # extra time to make sure board is sleep 
  end

  def resume(wakeup_domain, max_resume_time, e='dut1')
    if wakeup_domain == 'gpio'
      raise "Please define dut.params['gpio_wakeup_port'] in your bench file" if !@equipment[e].params.has_key?('gpio_wakeup_port')
      @power_handler.load_power_ports(@equipment[e].params['gpio_wakeup_port'])
      is_dut_awake=false
      Thread.new {
        @equipment[e].wait_for(/resume of devices complete/, max_resume_time)
        is_dut_awake = !@equipment[e].timeout?
      }
      sleep 1 
      @power_handler.reset(@equipment[e].params['gpio_wakeup_port'])
      begin 
        Timeout::timeout(max_resume_time) {
          while !is_dut_awake
            sleep 1
          end
        }
      rescue Timeout::Error => e
        raise "DUT took more than #{max_resume_time} seconds to resume"
      end
    else
      max_resume_time.times do |i|
        @equipment[e].send_cmd("", @equipment[e].prompt, 1, false)
        break if !@equipment[e].timeout?
        raise "DUT took more than #{max_resume_time} seconds to resume" if i == (max_resume_time-1)
      end
    end
  end

end