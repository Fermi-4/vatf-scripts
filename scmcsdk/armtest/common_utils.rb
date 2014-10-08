#####################################################################
##common_utils for TestLink Automation
##
##Common utilities, used by runlld.rb
#####################################################################

# For DSP + ARM Linux Test Project
#./dump_trace.sh
def dump_trace(num_of_cores = @dsp_cores, look_for,timeout)
  for count in 0..(num_of_cores-1)
    puts "'Core #{count} Trace...'"
    @equipment['dut1'].send_cmd(
      "cat /sys/kernel/debug/remoteproc/remoteproc#{count}/trace0",
      @equipment['dut1'].prompt, 10)
    puts "'-----------------------------------------'"
  end
end

def exampleA(argA, argB)
  @equipment['dut1'].send_cmd("echo 'running exampleA(#{argA}, #{argB})'",
    @equipment['dut1'].prompt, 10)
  puts "exampleA: I have found #{argA} and #{argB}"
end

def exampleB(argA, argB)
  @equipment['dut1'].send_cmd("echo 'running exampleB(#{argA}, #{argB})'",
    @equipment['dut1'].prompt, 10)
  argB.to_i.times do |count|
    puts "iteration #{count}"
    puts " exampleB: I have found #{argA} and #{argB}"
  end
end

def exampleC
  #tested to see that this format will not cause errors when echo-ing
  @equipment['dut1'].send_cmd("echo 'running exampleC()'",
    @equipment['dut1'].prompt, 10)
  puts "'running exampleC() 3'"
end

# For DSP + ARM Linux Test Project
#./stop_all.sh rmK2HArmv7LinuxDspClientTestProject.out
def mpm_load_all(out_file,num_of_cores = @dsp_cores,look_for,timeout)
  for count in 0..(num_of_cores-1)
    puts " 'Loading and Running #{out_file}...'"
    @equipment['dut1'].send_cmd("./mpmcl load dsp#{count} #{out_file}",
      @equipment['dut1'].prompt, 10)
    if @equipment['dut1'].timeout?
      return false
    end
    @equipment['dut1'].send_cmd("./mpmcl run dsp#{count}",
      @equipment['dut1'].prompt, 10)
    if @equipment['dut1'].timeout?
      return false
    end
    puts "Done"
  end
end

# For DSP + ARM Linux Test Project
# ./stop_all.sh rmK2KArmv7LinuxDspClientTestProject.out
def mpm_stop_all(file,num_of_cores = @dsp_cores,look_for,timeout)
  for count in 0..(num_of_cores-1)
    puts "'Resetting core #{file}...'"
    @equipment['dut1'].send_cmd("mpmcl reset dsp#{count}",
      @equipment['dut1'].prompt, 10)
    if @equipment['dut1'].timeout?
      return false
    end
    @equipment['dut1'].send_cmd("mpmcl status dsp#{count}",
      @equipment['dut1'].prompt, 10)
    if @equipment['dut1'].timeout?
      return false
    end
    puts "Done"
  end
end

# Reboots the DUT and logs back in. Reboot is done by either soft reboot or cycling power,
# depending on user specified parameter. The default without specifying any parameters
# is to soft reboot dut1.
def reboot(equip=@equipment['dut1'], cycle_power=false)
  params = Hash.new
  params['var_use_default_env'] = 2
  params['dut'] = equip
  saved_power_port = equip.power_port
  saved_sys_loader = equip.system_loader
  equip.system_loader = nil
  equip.power_port = nil if !cycle_power
  equip.boot(params)
  equip.power_port = saved_power_port
  equip.system_loader = saved_sys_loader 
end

# Reboots the DUT and logs back in
def soft_reboot(equip=@equipment['dut1'])
  reboot(equip)
end

# Public: See if the rmServer is running
#
# Returns true if running, or false if  not
def rmServer_up?(file_version = "_2sohk")
  process_running?(@equipment['dut1'],"rmServer")
end

# Public: See if the rmDspClient is running
#
# Returns true if running, or false if not
def rmDspClient_up?
  process_running?(@equipment['dut1'],"rmDspClient")
end

class String
  # Public: Word counts individual words in a String, disregarding case
  #
  # Return a Hash with key = word, and value = count.
  def ind_word_counts
    @freq = Hash.new(0)
    downcase.scan(/(\w+([-'.]\w+)*)/) {|word, _| @freq[word.downcase] += 1}
    @freq
  end

  # Public: Sums up number of words in a String.
  #
  # Return the total word count.
  def phrases
    @total = 0
    downcase.scan(/(\w+([-'.\/]\w+)*)/) {|word, _| @total += 1}
    @total
  end
end

# Public: Send a cmd as sudo
def sudo_cmd(cmd, expected_match = /.*/, timeout = 30)
  if cmd[/sudo/]
    send_sudo_cmd(cmd, expected_match = /.*/, timeout = 30)
  else
    false
  end
end

# Public: Get the TFTP file and path from test params
def get_relative_tftp_file_and_path(file)
  relative_tftp_file_and_path = ""
  tmp_relative_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
  error_msg = "Error: \"#{file.gsub('$',"")}=\" not specified in build information."
  case file
    when "$kernel"
      if !@test_params.instance_variable_defined?(:@kernel)
        @equipment['dut1'].log_info(error_msg)
        raise error_msg
      else
        relative_tftp_file_and_path = File.join(tmp_relative_path, File.basename(@test_params.kernel))
      end
    when "$nand_test_file"
      if !@test_params.instance_variable_defined?(:@nand_test_file)
        @equipment['dut1'].log_info(error_msg)
        raise error_msg
      else
        tftp_file_name = File.basename(@test_params.nand_test_file)
        server_tftp_path = File.join(@equipment['server1'].tftp_path, tmp_relative_path)
        server_tftp_file_and_path = File.join(server_tftp_path, tftp_file_name)
        @equipment['server1'].log_info("\r\n src: #{@test_params.nand_test_file}, dst: #{server_tftp_path}\r\n")
        copy_asset(@equipment['server1'], @test_params.nand_test_file, server_tftp_path)
        relative_tftp_file_and_path = File.join(tmp_relative_path, tftp_file_name)
        #relative_tftp_file_and_path = "make_it_fail"
      end
    else
      relative_tftp_file_and_path = file
  end
  return relative_tftp_file_and_path
end

# Public: TFTP file to EVM
def tftp_file_from_host(file, host_ip, timeout_secs,look_for,dut_timeout=nil)
  tftp_file_and_path = get_relative_tftp_file_and_path(file)
  tftp_server_ip = (host_ip == "$host_ip" ? @equipment['server1'].telnet_ip : host_ip)
  #@equipment['dut1'].send_cmd("tftp -g -r #{tftp_file_and_path} #{tftp_server_ip} ; echo command_done", "command_done", 2)
  @equipment['dut1'].send_cmd("tftp -g -r #{tftp_file_and_path} #{tftp_server_ip} ; echo command_done", @equipment['dut1'].prompt, 2)
  response_string = @equipment['dut1'].response.to_s
  if !response_string.include?("error") && !response_string.include?("can't")
    @equipment['dut1'].send_cmd("\r\n", "command_done", timeout_secs.to_i)
  end
end


