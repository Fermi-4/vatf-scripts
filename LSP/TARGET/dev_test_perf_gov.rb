require File.dirname(__FILE__)+'/dev_test2'

def run
  # Preserve current governor
  prev_gov = create_save_cpufreq_governors
  
  if is_cpufreq_supported(@equipment['dut1'].name)
    #Change to performance governor
    enable_cpufreq_governor
  end

  # Run the test
  self.as(LspTargetTestScript).run

  if is_cpufreq_supported(@equipment['dut1'].name)
    # Restore previous governor
    restore_cpufreq_governors(prev_gov)
  end
end

