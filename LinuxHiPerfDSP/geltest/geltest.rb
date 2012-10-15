# Connects Test Equipment to DUT(s) and Boot DUT(s)
require File.dirname(__FILE__)+'/../boot/c6x_gel_test_module'
include C6xGELTestScript
  
def setup
  super
end

def run

  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  wait_for_string = Regexp.new(@test_params.params_chan.instance_variable_get("@wait_for_string")[0])
  boot_times = @test_params.params_chan.instance_variable_get("@boot_times")[0].to_i
  power_port = @equipment['dut1'].power_port
  timeout = @test_params.params_chan.instance_variable_get("@timeout")[0].to_i
  @test_case_id = @test_params.caseID
  iteration = Time.now
  @iteration_id = iteration.strftime("%m_%d_%Y_%H_%M_%S")
  FileUtils.mkdir_p "#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}" if !Dir.exists?("#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}")
  logs_dir = "#{SiteInfo::LTP_TEMP_FOLDER}/TC#{@test_case_id}/Iter#{@iteration_id}"
  
  success_times = 0
  fail_times = 0
  boot_failures = 0
  boot_arr = [] 
  # @read_fail_caches_on = 0
  # @read_fail_caches_off1 = 0
  # @read_fail_caches_off2 = 0

  # @read_refresh_fail_caches_on = 0
  # @read_refresh_fail_caches_off1 = 0
  # @read_refresh_fail_caches_off2 = 0

  # @write_fail_caches_on = 0
  # @write_fail_caches_off1 = 0
  # @write_fail_caches_off2 = 0
  # v1.3
  @read_fail_caches_off_std = 0
  @read_fail_caches_off_inv = 0
  @read_fail_caches_on_std = 0
  @read_fail_caches_on_inv = 0
 
  response = nil
  local_logs = "#{File.dirname(__FILE__)}/logs"
   
  boot_times.times { |i|
  puts "Switching power for # #{i}th iteration"
  disconnect('dut1')
  @power_handler.switch_off(power_port)
  sleep(10)
  @power_handler.switch_on(power_port)
  sleep(45)
  connect_to_equipment('dut1')
  puts "cd #{File.dirname(__FILE__)} ; #{@dss_dir}/dss.sh #{File.dirname(__FILE__)+'/gel_test.js'} #{@dss_param_evm_id} "
  Thread.new {
  @equipment['server1'].send_cmd("cd #{File.dirname(__FILE__)} ; #{@dss_dir}/dss.sh #{File.dirname(__FILE__)+'/gel_test.js'} #{@dss_param_evm_id} ",/.*/,10)
  }

  @equipment['dut1'].wait_for(wait_for_string, timeout)
  sleep 10

  @equipment['server1'].send_cmd("kill `ps -ef | grep DebugServer | grep -v grep | awk '{print $2}'`",/.*/,10)
   @equipment['server1'].send_cmd("ps -ef | grep DebugServer" ,/.*/,10)
  if (@equipment['dut1'].timeout?)
    response =  nil
  else
    response = @equipment['dut1'].response
  end

  if (response != nil)
    if parse_response(response)
      success_times = success_times+1
      boot_arr << 'B'
    else
      fail_times = fail_times+1
      boot_arr << 'X'
    end
  else
    fail_times = fail_times+1
    boot_failures = boot_failures+1
    boot_arr << 'X'
  end
  @equipment['server1'].send_cmd("ruby #{File.dirname(__FILE__)}/extract_logs.rb #{File.dirname(__FILE__)}/logs/#{@targetFlag}_*-trace.txt",@equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("cp #{local_logs}/* #{logs_dir}")
  @equipment['server1'].send_sudo_cmd("rm #{File.dirname(__FILE__)}/logs/*") 
  }
  if success_times == boot_times
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass. DDR test completed successfully #{boot_times} out of #{boot_times} times "
  else
    test_done_result = FrameworkConstants::Result[:fail]
    comment = "Test fail. DDR test failed #{fail_times} out of #{boot_times} times. Boot log - #{boot_arr.to_s} "    
  end
  if (boot_failures > 0) 
    comment += "Board failed to boot #{boot_failures} out of #{boot_times} times  Boot log - #{boot_arr.to_s}"
  end
  @equipment['server1'].send_sudo_cmd("rm #{@ccs_gel_dir}/#{@ccstargetFlag}-geltest.gel", @equipment['server1'].prompt, 10)

  # puts "ruby extract_logs.rb #{File.dirname(__FILE__)}/logs/#{@targetFlag}_*-trace.txt"
  # @equipment['server1'].send_cmd("ruby #{File.dirname(__FILE__)}/extract_logs.rb #{File.dirname(__FILE__)}/logs/#{@targetFlag}_*-trace.txt",@equipment['server1'].prompt, 10)
  # @equipment['server1'].send_sudo_cmd("cp -r #{local_logs} #{logs_dir}")
  @equipment['server1'].send_sudo_cmd("rm -rf #{File.dirname(__FILE__)}/logs") 
  @equipment['server1'].send_sudo_cmd("rm -rf #{File.dirname(__FILE__)}/binaries") 
  sep = "\\"
  comment += "\n Logs at #{logs_dir.gsub("/mnt/gtsnowball/","\\\\\\gtsnowball\\System_Test\\").gsub(/\\|\//,sep)}"
  set_result(test_done_result,comment)
  
end

def connect_to_equipment(equipment)
  this_equipment = @equipment["#{equipment}"]
  if ((this_equipment.respond_to?(:serial_port) && this_equipment.serial_port != nil ) || (this_equipment.respond_to?(:serial_server_port) && this_equipment.serial_server_port != nil)) && !this_equipment.target.serial
    this_equipment.connect({'type'=>'serial'})     
  elsif !this_equipment.target.serial
    raise "You need Serial port connectivity to #{equipment}. Please check your bench file" 
  end

end
def disconnect(equipment)
  this_equipment = @equipment["#{equipment}"]
  if this_equipment.target.telnet || this_equipment.target.serial
    this_equipment.disconnect
  end
end

def parse_response(response)
  # read_fail_caches_on = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[0].to_i
  # @read_fail_caches_on = @read_fail_caches_on + read_fail_caches_on
  # read_fail_caches_off1 = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[1].to_i
  # @read_fail_caches_off1 = @read_fail_caches_off1 + read_fail_caches_off1
  # read_fail_caches_off2 = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[2].to_i 
  # @read_fail_caches_off2 = @read_fail_caches_off2 + read_fail_caches_off2    

  # read_refresh_fail_caches_on = response.match(/Total\sRead\sRefresh\sFailures:\s+(\d+)/).captures[0].to_i
  # @read_refresh_fail_caches_on = @read_refresh_fail_caches_on + read_refresh_fail_caches_on
  # read_refresh_fail_caches_off1 = response.match(/Total\sRead\sRefresh\sFailures:\s+(\d+)/).captures[1].to_i
  # @read_refresh_fail_caches_off1 = @read_refresh_fail_caches_off1 + read_refresh_fail_caches_off1
  # read_refresh_fail_caches_off2 = response.match(/Total\sRead\sRefresh\sFailures:\s+(\d+)/).captures[2].to_i  
  # @read_refresh_fail_caches_off2 = @read_refresh_fail_caches_off2 + read_refresh_fail_caches_off2

  # write_fail_caches_on = response.match(/Total\sWrite\sFailures:\s+(\d+)/).captures[0].to_i
  # @write_fail_caches_on = @write_fail_caches_on + write_fail_caches_on
  # write_fail_caches_off1 = response.match(/Total\sWrite\sFailures:\s+(\d+)/).captures[1].to_i
  # @write_fail_caches_off1 = @read_fail_caches_off1 + write_fail_caches_off1
  # write_fail_caches_off2 = response.match(/Total\sWrite\sFailures:\s+(\d+)/).captures[2].to_i
  # @write_fail_caches_off2 = @write_fail_caches_off2 + write_fail_caches_off2   
  # if (read_fail_caches_on != 0 || read_fail_caches_off1 != 0 || read_fail_caches_off2 != 0 || read_refresh_fail_caches_on != 0 || read_refresh_fail_caches_off1 != 0 || read_refresh_fail_caches_off2 != 0 || write_fail_caches_on != 0 || write_fail_caches_off1 != 0 || write_fail_caches_off2 != 0)
    
    # DDR test v1.3
    
    read_fail_caches_off_std = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[0].to_i
    @read_fail_caches_off_std = @read_fail_caches_off_std + read_fail_caches_off_std
    read_fail_caches_off_inv = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[1].to_i
    @read_fail_caches_off_inv = @read_fail_caches_off_inv + read_fail_caches_off_inv
    read_fail_caches_on_std = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[2].to_i 
    @read_fail_caches_on_std = @read_fail_caches_on_std + read_fail_caches_on_std  
    read_fail_caches_on_inv = response.match(/Total\sRead\sFailures:\s+(\d+)/).captures[3].to_i
    @read_fail_caches_on_inv = @read_fail_caches_on_inv + read_fail_caches_on_inv
    
    if (read_fail_caches_off_std != 0 || read_fail_caches_off_inv != 0 || read_fail_caches_on_std != 0 || read_fail_caches_on_inv != 0)
    return false
  else
    return true 
  end        
end

    
def clean

end
