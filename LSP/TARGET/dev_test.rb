require File.dirname(__FILE__)+'/../default_target_test'

include LspTargetTestScript

def setup
  self.as(LspTargetTestScript).setup
end

# Generate Linux shell script to be executed at DUT.
# This function used the script specified in the test params, replace any ruby code and/or
# test parameter references and creates test.sh  
def run_generate_script
  puts "\n LinuxTestScript::run_generate_script"
  FileUtils.mkdir_p @linux_temp_folder
  ftp_file_version = @test_params.params_control.script[0]
  isScriptACommand = !ftp_file_version.match(/ftp:\/\//i)
  if (!isScriptACommand)  # Need to retrieve script using ftp bee
    # Resolve Dispatcher name
    my_staf_handle = STAFHandle.new("my_staf") 
    staf_req = my_staf_handle.submit("local","VAR","GET SHARED VAR STAF/TMC/Machine") 
    if(staf_req.rc == 0)
      tmc_machine = staf_req.result
    else
      tmc_machine = nil
      raise "Could not resolve VAR STAF/TMC/Machine. Make sure that STAF is running and the TEE is reqistered with TMC Dispatcher"
    end
    
    begin
      # Request FTP BEE to RESMGR
      staf_req = my_staf_handle.submit(tmc_machine,"RESMGR","REQUEST TYPE ftp TIMEOUT 1w") 
      if(staf_req.rc != 0)
       raise "Could not find a FTP BEE available. This test scripts requires a FTP Bee to run"
      end
      staf_result_map = STAF::STAFResult.unmarshall_response(staf_req.result)
      bee_machine = staf_result_map['name'] 
      bee_id      = staf_result_map['id']
      ftp_file_version.gsub!(/ftp:\/\//i,'')
      # Request GET BUILDID  to FTP BEE
      staf_req = my_staf_handle.submit(bee_machine,"ftp@"+bee_id,"GET BUILDID ASSET script VERSION #{ftp_file_version}") 
      if(staf_req.rc != 0)
        raise "The #{bee_machine} FTP BEE could not get the ID for asset with version: #{ftp_file_version}"
      end
      
      # Request BUILD  to FTP BEE
      staf_req = my_staf_handle.submit(bee_machine,"ftp@"+bee_id,"BUILD ASSET script VERSION #{ftp_file_version}") 
      if(staf_req.rc != 0)
        raise "The #{bee_machine} FTP BEE could not retrieve the asset at #{ftp_file_version}"
      end
      staf_result_map = STAF::STAFResult.unmarshall_response(staf_req.result)
      bee_file_path = staf_result_map['path']
      bee_file_id   = staf_result_map['id']
      
      # Resolve STAF Datadir
      staf_req = my_staf_handle.submit("local","VAR","GET SYSTEM VAR STAF/DataDir") 
      if(staf_req.rc != 0)
        raise "Could not resolve VAR STAF/DataDir. Make sure that STAF is running at the TEE machine"
      end
      staf_data_dir = staf_req.result
  	
      # Copy file from BEE to local TEE directory
      dst_dir = "#{staf_data_dir}/user/sw_assets/ftp/script/#{bee_file_id}"
      dst_file = "#{dst_dir}/#{File.basename(bee_file_path.gsub(/\\/,'/'))}"
      if (!File.exists?(dst_file))
        FileUtils.mkdir_p dst_dir
  	  staf_req = my_staf_handle.submit(bee_machine,"fs","COPY FILE #{bee_file_path} TOFILE #{dst_file}") 
        if(staf_req.rc != 0)
          raise "Could not copy file from FTP Bee to TEE machine"
        end
      end
    rescue Exception => e
      puts e.to_s+"\n"+e.backtrace.to_s
    ensure
      staf_req = my_staf_handle.submit(tmc_machine,"RESMGR","RELEASE TYPE ftp NAME #{bee_machine} ID #{bee_id}") 
    end
  end
  
  in_file = File.new(dst_file, 'r') if !isScriptACommand
  if isScriptACommand
    raw_test_lines = @test_params.params_control.script  # Return array of commands
  else
    raw_test_lines = in_file.readlines  
  end
  
  out_file = File.new(File.join(@linux_temp_folder, 'test.sh'),'w')
  if raw_test_lines[0].match(/^#!\//)
    out_file.print("#{raw_test_lines.shift}\n") #Print sha-bang first 
  end
  out_file.print("failtest() {\n")
  out_file.print("  echo 1 >&3\n")
  out_file.print("}\n")
  param_names = @test_params.params_control.instance_variables
  param_names.each {|name|
    next if name.to_s.sub(/@/,'') == 'script'
    val=@test_params.params_control.instance_variable_get(name)[0]
    out_file.print("#{name.to_s.sub(/@/,'')}=#{/\s+/.match(val) ? "'"+val+"'" : val }\n")
  }
  out_file.print("\n# Start of user's script logic\n")
  raw_test_lines.each do |current_line|
    if current_line.match(/#\{.+\}/) # Apply Ruby var substitution
      out_file.print(eval('"'+current_line.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"')+"\n")
    else
      out_file.print(current_line.gsub('$','\$').gsub(/(?=`)/,'\\')+"\n")
    end
  end
  in_file.close   if !isScriptACommand
  out_file.close
end

# Calls shell script (test.sh)
def run_call_script
  puts "\n LinuxTestScript::run_call_script"
  @equipment['dut1'].send_cmd("cd #{@linux_dst_dir}",@equipment['dut1'].prompt)
  @equipment['dut1'].send_cmd("chmod +x test.sh",@equipment['dut1'].prompt)
  cmd_timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 600
  @equipment['dut1'].send_cmd("./test.sh 2> stderr.log > stdout.log 3> result.log",@equipment['dut1'].prompt, cmd_timeout)
  @equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 5, false)
  @equipment['dut1'].timeout?
end

# Determine test result outcome by checking if failtest() function was called or 
# the script returned and error code
def run_determine_test_outcome(return_non_zero)
  puts "\n LinuxTestScript::run_determine_test_outcome"
  @equipment['dut1'].send_cmd("cat result.log",/^1[\0\n\r]+/m, 2)
  failtest_check = !@equipment['dut1'].timeout?
  
  if return_non_zero
    return [FrameworkConstants::Result[:fail], "Application exited with non-zero value. \n"+get_detailed_info]
  elsif failtest_check
    return [FrameworkConstants::Result[:fail], "failtest() function was called. \n"+get_detailed_info]
  else
    return [FrameworkConstants::Result[:pass], "Application exited with zero. \n"+get_detailed_info]
  end
end

def get_detailed_info
  log_file_name = File.join(@linux_temp_folder, 'test.log') 
  all_lines = ''
  File.open(log_file_name, 'r').each {|line|
    all_lines += line.gsub(/<\/*(STD|ERR)_OUTPUT>/,'')
  }
  return all_lines
end

def run
  self.as(LspTargetTestScript).run
end