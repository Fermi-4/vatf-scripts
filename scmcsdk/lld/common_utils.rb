#####################################################################
##common_utils for TestLink Automation
##
##Common utilities, used by runlld.rb
#####################################################################

# For DSP + ARM Linux Test Project
#./dump_trace.sh
def dump_trace(num_of_cores = 8)
  for count in 0..(num_of_cores-1)
    puts "'Core #{count} Trace...'"
    @equipment['dut1'].send_cmd(
      "cat /debug/remoteproc/remoteproc#{count}/trace0",
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
def mpm_load_all(out_file, num_of_cores = 8)
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
def mpm_stop_all(file, num_of_cores = 8)
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

# Reboots the DUT and logs back in
def soft_reboot
  if @equipment['dut1'].instance_variable_defined?(:@power_port)
    dut_power_port = @equipment['dut1'].power_port
    @equipment['dut1'].power_port = nil
    @equipment['dut1'].power_cycle({'power_handler'=>1})
    @equipment['dut1'].connect({'type'=>'serial'})
    @equipment['dut1'].power_port = dut_power_port
    @equipment['dut1'].wait_for(/login:/, 60)

    @equipment['dut1'].send_cmd(@equipment['dut1'].login,
      @equipment['dut1'].prompt, 10) #login to the unit
    if @equipment['dut1'].timeout?
      raise "reboot failed"
    end
    puts "\n"
    puts "'-----------------------------------------'"
    puts "'echo Reboot completed'"
    puts "'-----------------------------------------'"
    sleep(5)
  end
end

# Public: See if the rmServer is running
#
# Returns true if running, or false if  not
def rmServer_up?(file_version = "hk")
  @equipment['dut1'].send_cmd("ps | grep rmServer",
    /rmServer_k2[#{ file_version }]/i, 10)
  @equipment['dut1'].timeout? ? false : true
end

# Public: See if the rmDspClient is running
#
# Returns true if running, or false if not
def rmDspClient_up?
  @equipment['dut1'].send_cmd("ps | grep rmDspClient", /rmDspClient/i, 10)
  @equipment['dut1'].timeout? ? false : true
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