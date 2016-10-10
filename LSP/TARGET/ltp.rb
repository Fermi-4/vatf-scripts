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
    if get_test_output.match(/^\|WARNING\|.+SKIPPING TEST:/)
      skipped_tests = get_test_output.match(/(^\|WARNING\|.+SKIPPING TEST:.*)/).captures[0]
      return [FrameworkConstants::Result[:pass],
            skipped_tests+"\n"+get_detailed_info(),
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
    else
      return [FrameworkConstants::Result[:pass],
            get_detailed_info(),
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
    end
  end
end

def get_detailed_info
  summary_data = get_test_output.match(/(^\s+Done executing testcases\..+^Total Failures:\s*\d+)/m).captures[0]
  all_lines = ''
  all_lines << summary_data.match(/Total Tests.+/).to_s + ", "
  all_lines << summary_data.match(/Total Failures.+/).to_s + ". \n"
  summary_data.scan(/^([\w\d_\-]+)\s+FAIL\s+\d+/) {|t| all_lines << "#{t[0]}, "}
  return all_lines
end

def run_call_script
  @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("chmod +x test.sh",@equipment['dut1'].prompt)
  cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
  @equipment['dut1'].send_cmd("./test.sh 2>&1 3> result.log",/Done executing testcases.+#{@equipment['dut1'].prompt}/m, cmd_timeout)
  test_output = @equipment['dut1'].response
  if @equipment['dut1'].timeout?
    # Wait one more minute for test to finish
    @equipment['dut1'].wait_for(@equipment['dut1'].prompt, 60)
    test_output += @equipment['dut1'].response
  end
  #write to test.log
  out_file = File.new(File.join(@linux_temp_folder,'test.log'),'w')
  out_file.write(test_output)
  out_file.close

  @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
  @equipment['dut1'].timeout?
end

def run
  self.as(LspTargetTestScript).run
end
