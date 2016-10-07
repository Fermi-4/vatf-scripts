require File.dirname(__FILE__)+'/dev_test2'

def setup
  self.as(LspTargetTestScript).setup
end

# Determine test result outcome and save performance data
def run_determine_test_outcome(return_non_zero)
  @equipment['dut1'].send_cmd("cat result.log",/^1[\0\n\r]+/m, 2)
  failtest_check = !@equipment['dut1'].timeout?
  detailed_info = get_detailed_info()

  if return_non_zero or detailed_info.match(/of which [1-9]+\d* failed/)
    return [FrameworkConstants::Result[:fail],
            detailed_info,
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  elsif failtest_check
    return [FrameworkConstants::Result[:fail],
            "failtest() function was called. \n",
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  else
    return [FrameworkConstants::Result[:pass],
            detailed_info,
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  end
end

def get_detailed_info
  summary_data = get_test_output.match(/(Result of testsuite.+)^TEE test application done!/m)
  if summary_data
    all_lines = summary_data.captures[0]
  else
    all_lines = 'Warning: Could not parse xtest output'
  end
  return all_lines
end