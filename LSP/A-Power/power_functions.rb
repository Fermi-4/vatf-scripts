module PowerFunctions

  # Set operating point on cpu specified. opp units in KHz as expected by cpufreq
  def set_cpu_opp(opp, cpu=0, e='dut1')
    @equipment[e].send_cmd("cat /sys/devices/system/cpu/cpu#{cpu}/cpufreq/scaling_available_frequencies", @equipment[e].prompt)
    supported_frequencies = @equipment[e].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    raise "This dut does not support #{opp} KHz, supported values are #{supported_frequencies.to_s}" if !supported_frequencies.include?(opp)
    @equipment[e].send_cmd("echo #{opp} > /sys/devices/system/cpu/cpu#{cpu}/cpufreq/scaling_setspeed", @equipment[e].prompt)
    @equipment[e].send_cmd("cat /sys/devices/system/cpu/cpu#{cpu}/cpufreq/scaling_cur_freq", @equipment[e].prompt)
    new_opp = @equipment[e].response.split(/\s+/).select {|v| v =~ /^\d+$/ }
    raise "Could not set #{opp} KHz for cpu #{cpu}" if !new_opp.include?(opp)
  end

  def set_coproc_opp(opp, coproc='coproc0', e='dut1')
    @equipment[e].send_cmd("(x=`ls /sys/devices/#{coproc}*/devfreq/#{coproc}*/userspace/set_freq`" \
      " && echo #{opp.to_i*1000} > $x && echo 'OK') || echo 'FAILED'", @equipment[e].prompt)
    raise "Could not set #{opp} KHz for #{coproc}" if @equipment[e].response.match(/FAILED/)
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
    if wakeup_domain == 'gpio' or  wakeup_domain == 'rtc'
      raise "Please define dut.params['gpio_wakeup_port'] in your bench file" if wakeup_domain == 'gpio' and !@equipment[e].params.has_key?('gpio_wakeup_port')
      @power_handler.load_power_ports(@equipment[e].params['gpio_wakeup_port']) if wakeup_domain == 'gpio'
      is_dut_awake=false
      Thread.new {             
        @equipment[e].wait_for(/PM:\s+resume\s+of\s+devices\s+complete\s+after\s+[0-9\.]+\s+[umsec]+|#{@equipment[e].prompt}/i, max_resume_time)
        is_dut_awake = !@equipment[e].timeout?
      }
      sleep 1 
      @power_handler.reset(@equipment[e].params['gpio_wakeup_port']) if wakeup_domain == 'gpio'
      begin 
        Timeout::timeout(max_resume_time) {
          while !is_dut_awake
            sleep 1
          end
        }
      rescue Timeout::Error => e
        raise "DUT took more than #{max_resume_time} seconds to resume"
      end
      response = @equipment[e].response
    
    else
      response = ''
      max_resume_time.times do |i|
        @equipment[e].send_cmd("", /PM:\s+resume\s+of\s+devices\s+complete\s+after\s+[0-9\.]+\s+[umsec]+|#{@equipment[e].prompt}/i, 1, false)
        response += @equipment[e].response
        break if !@equipment[e].timeout?
        raise "DUT took more than #{max_resume_time} seconds to resume" if i == (max_resume_time-1)
      end
    end
    response
  end

  def power_wakeup_configuration(wakeup_domain, power_state, e='dut1')
    # set uart to gpio in standby_gpio_pad_conf so that uart can wakeup from standby
  if power_state == 'standby' && wakeup_domain == 'uart'
    @equipment[e].send_cmd("cd /debug/omap_mux/board", @equipment[e].prompt, 10)
    @equipment[e].send_cmd("#{CmdTranslator.get_linux_cmd({'cmd'=>'set_uart_to_gpio_standby', 'platform'=>@test_params.platform, 'version'=>@equipment[e].get_linux_version})}" , @equipment[e].prompt, 10)
    @equipment[e].send_cmd("#{CmdTranslator.get_linux_cmd({'cmd'=>'get_uart_to_gpio_standby', 'platform'=>@test_params.platform, 'version'=>@equipment[e].get_linux_version})}", @equipment[e].prompt, 10)
  end

  if wakeup_domain == 'uart'
    # Enable UART wakeup if required
    cmd = CmdTranslator.get_linux_cmd({'cmd'=>'enable_uart_wakeup', 'platform'=>@test_params.platform, 'version'=>@equipment[e].get_linux_version})
    @equipment[e].send_cmd(cmd , @equipment[e].prompt) if cmd.to_s != ''
  end

  if wakeup_domain == 'gpio'
    # Enable GPIO wakeup if required
    cmd = CmdTranslator.get_linux_cmd({'cmd'=>'enable_gpio_wakeup', 'platform'=>@test_params.platform, 'version'=>@equipment[e].get_linux_version})
    @equipment[e].send_cmd(cmd , @equipment[e].prompt) if cmd.to_s != ''
  end

  if wakeup_domain != 'usb'
    # Disable usb wakeup to reduce standby power
    cmd = CmdTranslator.get_linux_cmd({'cmd'=>'disable_usb_wakeup', 'platform'=>@test_params.platform, 'version'=>@equipment[e].get_linux_version})
    @equipment[e].send_cmd(cmd , @equipment[e].prompt) if cmd.to_s != ''
  end

  if wakeup_domain != 'tsc'
    # Disable tsc wakeup tp reduce standby power
    cmd = CmdTranslator.get_linux_cmd({'cmd'=>'disable_tsc_wakeup', 'platform'=>@test_params.platform, 'version'=>@equipment[e].get_linux_version})
    @equipment[e].send_cmd(cmd , @equipment[e].prompt) if cmd.to_s != ''
  end
  end

end