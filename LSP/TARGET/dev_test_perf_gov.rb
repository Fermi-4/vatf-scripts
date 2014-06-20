require File.dirname(__FILE__)+'/dev_test2'

def run
  # Preserve current governor
  prev_gov = create_save_cpufreq_governors
  #Change to performance governor
  enable_cpufreq_governor

  # Run the test
  self.as(LspTargetTestScript).run

  # Restore previous governor
  restore_cpufreq_governors(prev_gov)
end

