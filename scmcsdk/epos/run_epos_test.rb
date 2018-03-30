#####################################################################
##runlld.rb for TestLink Automation
##
##**DESCRIPTION**
##runlld is used by the TestLink framework to automate running tests
##  Requires three variables to be defined in the test case:
##    commands, constraints, and iterations
##  Note: each variable is an array of String
##
##**PROCESS**
##runlld will run the commands specified in commands, in the following order.
##When commands = [a,b,c,d,e], execution will b, c, d, e, then a.
##After running all commands, runlld checks the output for specified terms to
##  check test completion and success. Key words from are scanned, and tests
##  fail or pass depending on parameter constraints.
##Repeat iteration times
##
##**MISCELLANEOUS**
##Build parameter @test_params.lld_test_archive, is a tar.gz archive
##  transferred from an ftp server, specified in the build description.
##  It holds .dtb, .out, and .sh files.
##Test param @test_params.params_control.soft_reboot is optional, but will
##  reboot the DUT if defined and set to true
##Look below at internally_consistent? to see about constraint options that are
##  not literal matches (+/-/:/=)

require 'fileutils'
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../armtest/common_utils.rb'
require File.dirname(__FILE__)+'/../../lib/parse_perf_data'
include LspTestScript
include ParsePerfomance

@show_debug_messages = false

def setup
  self.as(LspTestScript).setup
end

def get_perf_metrics
  if @test_params.params_control.instance_variable_defined?(:@perf_metrics_file)
    require File.dirname(__FILE__)+"/../../#{@test_params.params_control.perf_metrics_file[0].sub(/\.rb$/,'')}"
    get_metrics
  else
    return nil
  end
end

#  Downloads epos test applications package in destination directory
def download_package(package,dest_dir)
  @equipment['server1'].send_sudo_cmd("wget -N -P #{dest_dir} #{package}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chmod 777 #{dest_dir}#{package.split('/')[-1]}", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_sudo_cmd("chown nobody #{dest_dir}#{package.split('/')[-1]}", @equipment['server1'].prompt, 10)
end

# Transfers files from host to dut
def transfer_to_dut(file_name,server_ip)
  @equipment['dut1'].send_cmd("tftp -g -r #{file_name} #{server_ip}", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("ls -l", @equipment['dut1'].prompt,10)
end

#Function to setup epos test environment
def setup_epos_environment()
  @equipment['dut1'].send_cmd("tar -xvf am438x-epos-apps.tar",\
                                @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("cd am438x-epos-apps", @equipment['dut1'].prompt,10)
  @equipment['dut1'].send_cmd("chmod 777 -R * .", @equipment['dut1'].prompt,10)
end

def run
  perfdata = []
  ##initial assumptions
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "*Pretest Setup failed.*\n"

  download_package("#{@test_params.params_chan.epos_testapp[0]}",'/tftpboot/epos_testapps/')
  transfer_to_dut("epos_testapps/am438x-epos-apps.tar",@equipment['server1'].telnet_ip)
  setup_epos_environment()

  commands = assign_commands()
  criteria = assign_criteria()
  @timeout = assign_timeout()
  @soft_reboot = @test_params.params_control.instance_variable_defined?(:@soft_reboot) ? \
                        (@test_params.params_control.soft_reboot[0].to_s) : @test_params.params_chan.instance_variable_defined?(:@soft_reboot) ? \
						(@test_params.params_chan.soft_reboot[0].to_s) : "false"
  iterations = assign_iterations()
  test_folder_location = nil

  ##Prepare for running tests. Bundle up file building, server starting
  prep_results = prepare_for_test(test_folder_location, commands)
  if prep_results[0] == false
    if @show_debug_messages
      comment += prep_results[1]
    end
    set_result(test_done_result,comment)
    return
  end

  if @show_debug_messages
    @equipment['dut1'].send_cmd("echo 'Commands to run: \
      #{ commands.to_s }'", @equipment['dut1'].prompt, 5)
    @equipment['server1'].send_cmd("echo 'Commands to run: \
      #{ commands.to_s }'", @equipment['server1'].prompt, 5)
    comment += "Running Test.\n" #FOR MORE COMMENTS#
  else
    comment = "Running Test.\n" #FOR LESS COMMENTS#
  end

  ##run test_cmd iteration times
  test_cmd = commands[0]
  iterations.times do |count|
    ## check to see if we are told to run setup for every iteration
    if (count > 0 && setup_required == true)
        prep_results = prepare_for_test(test_folder_location, commands)
        if prep_results[0] == false
            if @show_debug_messages
	        comment += prep_results[1]
	    end
	    set_result(test_done_result,comment)
	    return
	end
    end
    cmd_result = run_command(Array.new.push(test_cmd),{
      :look_for => (criteria != nil) ? Regexp.new(criteria[0], Regexp::IGNORECASE) : nil, :timeout => @timeout})
    if cmd_result[0] == false
      set_result(test_done_result,comment + cmd_result[1])
      return
    else
      comment += cmd_result[1]
    end
    std_response = @equipment['dut1'].update_response
    puts "'#{ test_cmd }' run. Now to test."
    if criteria != nil
      criteria_result = analyze_criteria(count, test_cmd, std_response, criteria)
      if @test_params.params_control.instance_variable_defined?(:@perf_metrics_file)
        test_log = (@equipment['dut1'].update_response).gsub("\u0000", '')
        perfdata = analyze_perf_data(test_log)
      end
    else
      if @equipment['dut1'].timeout?
        criteria_result = [false, "DUT timeout executing #{test_cmd}"]
      else
        criteria_result = [true]
      end
    end
    if criteria_result[0] == false
      set_result(test_done_result, comment + criteria_result[1])
      return
    end
    puts "Iteration #{ count + 1 } done. "
  end

  ##DONE
  puts "**************************\n'#{ test_cmd }'"
  puts "*TEST PASSED*\n**************************"
  comment += "\n '#{ test_cmd }'\n*TEST PASSED*"
  test_done_result = FrameworkConstants::Result[:pass]
  if perfdata != nil
  set_result(test_done_result, comment, perfdata)
  else
  set_result(test_done_result, comment)
  end
end

# Return array of performance data that comply w/ set_result method defined by atf_session_runner
# logs can be either a log file path or the actual string with the execution data.
# perf_metrics is an array, Each array element is a hash
def analyze_perf_data(test_log)
  perf_data = get_performance_data(test_log, get_perf_metrics)
  perf_data
end

# Public: Loop through criteria and searches for criteria in std_response.
# Use regEx to pattern-match literal constraints,
# Parse if preceded by +/- for pass/fail
#
# (Note: Arguments count and test_cmd are only for commenting purposes)
# (Note: Currently searches for first instance of criterion.
#   May need to change to number of times appears.)
#
# Returns false if criteria not found or when special cases fail, with comments
def analyze_criteria(count, test_cmd, std_response, criteria)
  comment = ""
  criteria.each do |criterion|
    puts "looking for criterion \"#{ criterion }\""
    if std_response[/Segmentation fault/]
      set_result(test_done_result,comment + "\nSegmentation fault error. ")
      return
    #if criterion is preceded by a -, fail output contains failure_word
    elsif criterion[0] == "-"
      failure_word = criterion[/\S.+\S/][1, criterion[/\S.+\S/].length]
      #if std_response[/#{failure_word}/io]
      if std_response[/#{failure_word}/i]
        puts "**Output contains '#{failure_word}'**"
        comment += "** Error: output contains '#{failure_word}' **\n"
        return [false, comment]
      end
    #if criterion is preceded by a +, call internally_consistent?
    elsif criterion[0] == "+"
      new_crit = criterion[/\S.+\S/][1, criterion[/\S.+\S/].length]
      puts "consistency testing for #{new_crit}"
      type_of_check = criterion[/\S.+\S/][criterion[/\S.+\S/].length]
      #type_of_check can be =,:
      c_result = internally_consistent?(std_response, type_of_check, new_crit)
      #this is the format of c_result = [consistent?, comments]
      if !c_result[0]
        comment += "Fail '#{test_cmd}' for output inconsistency. "
        set_result(test_done_result,comment + c_result[1])
        return [false, comment]
      end
    #else, scan buffer to see if send_cmd result matches criterion
    elsif std_response[/#{criterion}/im]
      puts "Output has criterion #{criterion}"
      comment += "Iteration #{count+1}: \
        Output has criterion \"#{criterion}\".\n"
    else
      comment += "Fail '#{test_cmd}' on iteration #{count +1}. \
        Criterion \"#{criterion}\" not met."
      return [false, comment]
    end
  end
  [true, comment]
end

# commands - commands variable from TestLink
# commands[0] is the last command run. commands[!0] are run first.
def assign_commands
  if defined? @test_params.params_control.commands
    @test_params.params_control.commands
  else
    @test_params.params_chan.commands
  end
end

# constraints - constraints variable from TestLink
# constraints[0] is a phrase signifying test completion.
# constraints[!0] are for regEx matching
def assign_criteria
  if defined? @test_params.params_control.constraints
    @test_params.params_control.constraints
  elsif defined? @test_params.params_chan.constraints
    @test_params.params_chan.constraints
  else
    nil
  end
end

# iterations - iterations variable from TestLink
def assign_iterations
  if defined? @test_params.params_control.iterations
    @test_params.params_control.iterations[0].to_i
  else
    @test_params.params_chan.iterations[0].to_i
  end
end

def assign_timeout
  if defined? @test_params.params_control.timeout
    @test_params.params_control.timeout[0].to_i
  elsif defined? @test_params.params_chan.timeout
    @test_params.params_chan.timeout[0].to_i
  else
    timeout = 120
  end
end

# Public: Parse output to check consistency with criterion
# (Note: this method may be null if formatting of output becomes inconsistent)
#
# output        - the std_response from running the cmd
# type_of_check - can be of the following type
#   "" means a normal keyword/phrase match
#   ":" means a comparison between output's summary and body of the output
#   "=" means a comparison between results printed in the output summary
#
# Examples
#   If output contains the following line,
#     failed: 0; passed a, passed b, passed c, total passed=3;
#   then criterion could be "failed", with type_of_check = ":"
#   then criterion could be "passed", with type_of_check = "="
#
# Returns whether output is consistent with criterion
def internally_consistent?(output, type_of_check = "", criterion = "default")
  internal_comment = ""
  crite = criterion.downcase
  puts "\n0.testing for #{ criterion }\n"
  regex_output = output[/#{ criterion }/i]
  if regex_output == nil
    puts "Nothing to test in output"
    return true
  else
    puts "#{regex_output} found."
  end
  #wc_hash is a word count for unique caseless word in the output
  wc_hash = output.ind_word_counts
  puts "\n1.testing for #{ criterion }\n"
  if type_of_check == "="
    #regEx: /^ packets \s sent .+ [0-9].+ packets \s received .+[0-9].+$/
    # look at the number that appears after
    if crite == "packets" && output[/packets/i]
      line_s = output[/#{ crite } \s+ sent.* #{type_of_check}.* \d+ \S*/ix]
      line_r = output[/#{ crite } \s+ received.* #{type_of_check}.* \d+ \S*/ix]
      #if not nil but there are different numbers at the end, return
      if line_s != nil && line_r != nil
        if line_s[/\d+/].to_i != line_r[/\d+/].to_i
          internal_comment += "Number of packets does not match up. "
          return [false, internal_comment]
        end
      end
    end
  elsif type_of_check == ":" && output[/#{ crite }/i]
  #use String.ind_word_counts to see if it has a "passed",
  # if it does, -1 that to see if it matches
    line = output[/#{ crite } \s* #{ type_of_check } .* \d+ \S*/ix]
    wc = wc_hash["#{ crite }"]
    if line == nil
      puts "does not fit word : pattern"
    #If there is a number at the end, but different from word_count
    elsif line[/\d+/] && (line[/\d+/].to_i != 0) && crite == "failed"
      internal_comment += "Failed more than 0 times. " + line.to_s
      return [false, internal_comment]
    elsif wc != 0 && line[/\d+/] && (line[/\d+/].to_i != (wc-1))
      internal_comment = "\n#{ criterion.upcase } are not \
        correctly counted. " + line.to_s
      return [false, internal_comment]
    end
    #Confirm that if the test output the String "Failed", nothing really Failed
    if crite[/failed/i]
      line = output[/failed \s* : .* \d+ \S*/ix]
      #if there is a number at the end, it should be 0
      if line != nil && line[/\d+/] && (line[/\d+/].to_i != 0)
        internal_comment += ". Failed more than 0 times. " + line.to_s
        return [false, internal_comment]
      end
    end
  end

  #std_response
  puts "Internally consistent"
  [true, "Passed"]
end

# Public: Do most of the preparation for testing:
# archive building, file checking, and server starting
#
# Return true is ready to run commands[0], with comments
def prepare_for_test(test_folder_location, commands)
  comment = ""
  if @soft_reboot == "true"
    puts "Rebooting DUT"
    soft_reboot()
  end

  other_cmds = commands[1...commands.length]

  ##Run other comamds
  if other_cmds[0]
    cmd_result = run_command(other_cmds,:look_for => @equipment['dut1'].prompt,:timeout => @timeout)
    if cmd_result[0] == false
      return [false, comment + cmd_result[1]]
    else
      comment += cmd_result[1]
    end
  end
end

# Public: If some_string is a ruby method, call as a ruby method
#   rather than a shell command.
#
# some_string - A String from the commands array
#
# In Tesk Link, multiple arguments are separated by a colon :
#
#   Example
#
#     string "funct(x:y)" will be run as send(funct, [x,y])
#
# Return false if there are no parentheses.
def rubify(some_string,look_for,timeout)
  if some_string[/\(.*\)/]
    method = some_string[/.*?\(/].to_s.sub('(', '')
    some_string.gsub(/\(.*\)/) do |substr|
      args = substr[1..-2]
      if args[/\(.*\)/]
        args_array = args.split
      else
        args_array = args.split(",")
     end
     if args_array.any? { |word| word.match(/\(.*\)/) } || !args_array.any? { |word| word.match(/\{\:.*\}/) }
       # insert hash of look_for and timeout
       #args_array << {:look_for=>look_for, :timeout=>timeout}
     else
       # If arguments passed are not a method requiring rubify() and already contain a hash of optional args, merge look_for and timeout
       if args_array.any? { |word| word.match(/\{\:.*\}/) }
         args_array.each { |word|
           if word.is_a?(Hash)
             word = eval(word.to_s)
             #word.merge({:look_for=>look_for, :timeout=>timeout})
           end
         }
       end
     end
      if @show_debug_messages
        puts 'Method= ' + method + ', Argument(s)= ' + args_array.to_s + '.'
      end
      begin
        self.send(method, *args_array)
        true
      rescue => detail
        error = detail.backtrace.join("\n")
        puts "**********************\nERROR: #{error}\n**********************"
        raise "Error: ruby command not recognized: #{method}"
      end
    end
  else
    false
  end
end

# Public: Run commands through ruby, or on the DUT
# Similar to .send_cmd, but arg[0] is an Array of String
#
# cmds      - An array of commands to run
# look_for  - Criteria to look for in cmds output
#
# Return if cmds sent successfully, with comments
def run_command(cmds,opts={:look_for => @equipment['dut1'].prompt, :timeout => 30})
  comment = ""
  #look_for = opts[:look_for].to_s
  look_for = nil
  timeout = opts[:timeout].to_i
  cmds.each do |cmd|
    comment += "Running " + cmd.to_s + ". "
    sleep 5
    if rubify(cmd,look_for,timeout)
      puts cmd + " run. command sent as ruby method"
    else
      @equipment['dut1'].send_cmd(cmd, look_for, timeout)
    end

    std_response = @equipment['dut1'].response.to_s
    if std_response[/Segmentation fault/]
      comment += "\nSeg fault error."
      return [false, comment]
    end
    comment +=  cmd.to_s + " run. \n"
  end
  return [true, comment]
end

def eval_and_send(cmd,args_array)
  cmd_to_send = eval('"'+cmd+'"')
  run_command(Array.new.push(cmd_to_send),args_array)
end

# Function to clone user specified git repository on server and copy to dut
def clone_user_git_repo(git_repo)
  if git_repo != ''
    git_branch = @test_params.params_chan.instance_variable_defined?(:@git_branch) ? @test_params.params_chan.git_branch[0] : ''
    git_dir = git_repo.match(/\/([\w]+).git/)[1]
    tmp_path = @test_params.staf_service_name.to_s.strip.gsub('@','_')
    @equipment['server1'].send_sudo_cmd("rm -r /tftpboot/#{tmp_path}/#{git_dir} /tftpboot/#{tmp_path}/#{git_dir}.tar.gz", \
                                         @equipment['server1'].prompt, 10)
    @equipment['server1'].send_cmd("git clone #{git_repo} /tftpboot/#{tmp_path}/#{git_dir} ", \
                                    @equipment['server1'].prompt, 60)
    if git_branch != ''
      @equipment['server1'].send_cmd("cd /tftpboot/#{tmp_path}/#{git_dir}; git checkout #{git_branch}", \
                                      @equipment['server1'].prompt, 30)
    end
      @equipment['server1'].send_cmd("cd /tftpboot/#{tmp_path}; tar -cvzf #{git_dir}.tar.gz #{git_dir}", \
                                      @equipment['server1'].prompt, 60)
    @equipment['dut1'].send_cmd("tftp -g -r #{tmp_path}/#{git_dir}.tar.gz #{@equipment['server1'].telnet_ip}", @equipment['dut1'].prompt, 60)
  end
end

def clean

end
