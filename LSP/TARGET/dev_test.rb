require File.dirname(__FILE__)+'/../default_target_test'

include LspTargetTestScript

# Generate Linux shell script to be executed at DUT.
# This function used the shell_script software asset, replace any ruby code and/or
# test parameter references and creates test.sh  
def run_generate_script
  puts "\n LinuxTestScript::run_generate_script"
  FileUtils.mkdir_p SiteInfo::LINUX_TEMP_FOLDER
  in_file = File.new(File.join(@test_params.shell_script), 'r')
  raw_test_lines = in_file.readlines
  out_file = File.new(File.join(SiteInfo::LINUX_TEMP_FOLDER, 'test.sh'),'w')
  #out_file.puts("#!/bin/bash \n")
  out_file.puts("failtest() {")
  out_file.puts("  echo 1 >&3")
  out_file.puts("}")
  param_names = @test_params.params_chan.instance_variables
  param_names.each {|name|
    val=@test_params.params_chan.instance_variable_get(name)[0]
    out_file.puts("#{name.sub(/@/,'')}=#{/\s+/.match(val) ? "'"+val+"'" : val }")
  }
  out_file.puts("# Start of user's script logic")
  raw_test_lines.each do |current_line|
    out_file.puts(eval('"'+current_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"'))
  end
  
  
  in_file.close
  out_file.close
end

# Calls shell script (test.sh)
def run_call_script
  puts "\n LinuxTestScript::run_call_script"
  @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("chmod +x test.sh",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("./test.sh 2> stderr.log > stdout.log 3> result.log",@equipment['dut1'].prompt)
end

# Determine test result outcome by checking if failtest() function was called or 
# the script returned and error code
def run_determine_test_outcome
  puts "\n LinuxTestScript::run_determine_test_outcome"
  @equipment['dut1'].send_cmd("echo $?",/^0$/m, 2)
  returncode_check = @equipment['dut1'].timeout?
  @equipment['dut1'].send_cmd("cat result.log",/^1$/m, 2)
  failtest_check = !@equipment['dut1'].timeout?
  
  if returncode_check
    return [FrameworkConstants::Result[:fail], "The shell script returned non-zero value. \n"+get_detailed_info]
  elsif failtest_check
    return [FrameworkConstants::Result[:fail], "The shell script called failtest(). \n"+get_detailed_info]
  else
    return [FrameworkConstants::Result[:pass], "Shell script returned 0 and did not call failtest(). \n"+get_detailed_info]
  end
end

def get_detailed_info
  log_file_name = File.join(SiteInfo::LINUX_TEMP_FOLDER, 'test.log') 
  all_lines = ''
  File.open(log_file_name, 'r').each {|line|
    all_lines += line.gsub(/<\/*(STD|ERR)_OUTPUT>/,'')
  }
  return all_lines
end
