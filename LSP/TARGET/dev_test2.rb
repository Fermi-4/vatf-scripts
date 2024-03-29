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

def get_detailed_info
  log_file_name = File.join(@linux_temp_folder, 'test.log')
  all_lines = ''
  File.open(log_file_name, 'r').each {|line|
    all_lines += line.gsub(/<\/*(STD|ERR)_OUTPUT>/,'') if line[/(fatal|\|error\||unable)/i]
  }
  return all_lines
end
                                         
# Determine test result outcome and save performance data
def run_determine_test_outcome(return_non_zero)
  puts "\n LinuxTestScript::run_determine_test_outcome"
  @equipment['dut1'].send_cmd("cat result.log",/^1[\0\n\r]+/m, 2)
  failtest_check = !@equipment['dut1'].timeout?

  if return_non_zero
    return [FrameworkConstants::Result[:fail], 
            "Application exited with non-zero value. \n" + get_detailed_info,
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  elsif failtest_check
    return [FrameworkConstants::Result[:fail],
            "failtest() function was called. \n" + get_detailed_info,
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
  else
    if get_test_output.match(/^\|WARNING\|.+SKIPPING TEST:/)
      return [FrameworkConstants::Result[:ns],
            "Test skipped. Optional kernel config option not set as expected.\n",
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
    else
      return [FrameworkConstants::Result[:pass],
            "Test passed. Application exited with zero. \n",
            get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)]
    end
  end
end

def run
  self.as(LspTargetTestScript).run
end

# Calls shell script (test.sh)
def run_call_script
  puts "\n LinuxTestScript::run_call_script"
  get_debug_data()
  @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("chmod +x test.sh",@equipment['dut1'].prompt)
  cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
  cmd_timeout = @test_params.params_chan.timeout[0].to_i if @test_params.params_chan.instance_variable_defined?(:@timeout)
  @equipment['dut1'].send_cmd("./test.sh 2>&1 3> result.log",@equipment['dut1'].prompt, cmd_timeout)
  #write to test.log
  test_output = @equipment['dut1'].response
  if @equipment['dut1'].timeout?
    # Wait one more minute for test to finish
    @equipment['dut1'].wait_for(@equipment['dut1'].prompt, 60)
    test_output += @equipment['dut1'].response
  end
  out_file = File.new(File.join(@linux_temp_folder,'test.log'),'w')
  out_file.write(test_output)
  out_file.close

  @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2, false)
  @equipment['dut1'].timeout?
end

def get_debug_data
  if @test_params.params_chan.instance_variable_defined?(:@debug_cmds)
    @test_params.params_chan.debug_cmds.each { |cmd|
      @equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt)
    }
  end
end


# Collect output from standard output and  standard error in test.log
  def run_get_script_output
    puts "\n LinuxTestScript::run_get_script_output"
    log_file_name = File.join(@linux_temp_folder, 'test.log') 
    add_log_to_html(log_file_name)
  end


def save_firmware(e=@equipment['dut1'])
  check_firmware_links(e)
  e.send_cmd("find /lib/firmware/ -type l -exec realpath {} \\; -print 2>/dev/null", e.prompt)
  @firmware_links = Hash[*e.response.scan(/^\/lib\/firmware\/.+/)]
end

def restore_firmware(e=@equipment['dut1'])
  if @firmware_links
    @firmware_links.each {|k,v|
      e.send_cmd("ln -sf #{k.strip} #{v.strip}")
    }
  end
  check_firmware_links(e, 'RESTORE')
end

def check_firmware_links(e=@equipment['dut1'], info='SAVE')
  e.send_cmd("find /lib/firmware/ -type l ! -exec realpath {} \\;", e.prompt)
  if e.response.match(/realpath:\s*.\/lib/im)
    e.log_info("TEST_#{info}_FW_WARNING: Broken Links: #{e.response.scan(/realpath:([^\r\n]+)/im)*", "} ....")
  end
end
