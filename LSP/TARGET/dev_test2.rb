require File.dirname(__FILE__)+'/dev_test'
require File.dirname(__FILE__)+'/../../lib/parse_perf_data'
include ParsePerfomance

# Default implementation to return empty array
def get_perf_metrics
  if @test_params.params_control.instance_variable_defined?(:@perf_metrics_file)
    require File.dirname(__FILE__)+"/../../#{@test_params.params_control.perf_metrics_file[0].sub(/\.rb$/,'')}" #Dummy comment to show code propely in eclipse"
    get_metrics 
  else
    return nil
  end
end
                                         
# Determine test result outcome and save performance data
def run_determine_test_outcome(return_non_zero)
  puts "\n LinuxTestScript::run_determine_test_outcome"
  @equipment['dut1'].send_cmd("cat result.log",/^1[\0\n\r]+/m, 2)
  failtest_check = !@equipment['dut1'].timeout?
  if return_non_zero
    return [FrameworkConstants::Result[:fail], 
            "Application exited with non-zero value. \n",
            get_performance_data(File.join(SiteInfo::LINUX_TEMP_FOLDER,'test.log'), get_perf_metrics)]
  elsif failtest_check
    return [FrameworkConstants::Result[:fail],
            "failtest() function was called. \n",
            get_performance_data(File.join(SiteInfo::LINUX_TEMP_FOLDER,'test.log'), get_perf_metrics)]
  else
    return [FrameworkConstants::Result[:pass],
            "Test passed. Application exited with zero. \n",
            get_performance_data(File.join(SiteInfo::LINUX_TEMP_FOLDER,'test.log'), get_perf_metrics)]
  end
end

