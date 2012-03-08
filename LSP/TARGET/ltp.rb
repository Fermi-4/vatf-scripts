require File.dirname(__FILE__)+'/dev_test2'

def setup
  self.as(LspTargetTestScript).setup
end

# Determine test result outcome and save performance data
def run_determine_test_outcome(return_non_zero)
  @equipment['dut1'].send_cmd("cat result.log",/^1[\0\n\r]+/m, 2)
  failtest_check = !@equipment['dut1'].timeout?

  if return_non_zero
    return [FrameworkConstants::Result[:fail], 
            get_detailed_info(),
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  elsif failtest_check
    return [FrameworkConstants::Result[:fail],
            "failtest() function was called. \n",
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  else
    return [FrameworkConstants::Result[:pass],
            get_detailed_info(),
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  end
end

def get_detailed_info
  summary_data = get_std_output.match(/(^\s+Done executing testcases\..+^Total Failures:\s*\d+)/m).captures[0]
  all_lines = ''
  all_lines << summary_data.match(/Total Tests.+/).to_s + ", "
  all_lines << summary_data.match(/Total Failures.+/).to_s + ". \n"
  summary_data.scan(/^([\w\d_\-]+)\s+FAIL\s+\d+/) {|t| all_lines << "#{t[0]}, "}
  return all_lines
end

def run
  self.as(LspTargetTestScript).run
end