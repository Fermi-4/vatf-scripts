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

end