require File.dirname(__FILE__)+'/dev_test'
require File.dirname(__FILE__)+'/../../lib/parse_perf_data'
include ParsePerfomance

def setup
  self.as(LspTargetTestScript).setup
  # Enable interrupts on MUSB port for am180x
  @equipment['dut1'].send_cmd("insmod /lib/modules/`uname -a | cut -d' ' -f 3`/kernel/drivers/usb/gadget/g_ether.ko", /#{@equipment['dut1'].prompt}/, 30) if @equipment['dut1'].name.match(/am180x/i)
end

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
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  elsif failtest_check
    return [FrameworkConstants::Result[:fail],
            "failtest() function was called. \n",
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  else
    return [FrameworkConstants::Result[:pass],
            "Test passed. Application exited with zero. \n",
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  end
end

def run
  self.as(LspTargetTestScript).run
end

# Calls shell script (test.sh)
def run_call_script
  puts "\n LinuxTestScript::run_call_script"
  @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("chmod +x test.sh",@equipment['dut1'].prompt)
  cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
  @equipment['dut1'].send_cmd("./test.sh 2>&1 | tee stdout.log 3> result.log",@equipment['dut1'].prompt, cmd_timeout)
  @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2)
  @equipment['dut1'].timeout?
end


# Collect output from standard output and  standard error in test.log
  def run_get_script_output
    puts "\n LinuxTestScript::run_get_script_output"
    log_file_name = File.join(@linux_temp_folder, 'test.log') 
    log_file = File.new(log_file_name,'w')
    stdout_file  = File.new(File.join(@linux_temp_folder,'stdout.log'),'w')
    @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cat stdout.log",@equipment['dut1'].prompt,60)
    std_output = @equipment['dut1'].response
    stdout_file.write(std_output)
    log_file.write("\n<STD_OUTPUT>\n"+std_output+"</STD_OUTPUT>\n")
    stdout_file.close
    log_file.close
    add_log_to_html(log_file_name)
  end

