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
require File.dirname(__FILE__)+'/common_utils.rb'
include LspTestScript

@show_debug_messages = false

def setup
  self.as(LspTestScript).setup
end

def run
  ##initial assumptions
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "*Pretest Setup failed.*\n"

  commands = assign_commands()
  criteria = assign_criteria()
  iterations = assign_iterations()
  @platform = get_platform()
  test_folder_location = nil
  #for debugging, test_folder_location = @test_params.lld_test_archive

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
    cmd_result = run_command(Array.new.push(test_cmd),
    look_for = /#{ criteria[0] }/i)
    if cmd_result[0] == false
      set_result(test_done_result,comment + cmd_result[1])
      return
    else
      comment += cmd_result[1]
    end
    std_response = @equipment['dut1'].response.to_s

    puts "'#{ test_cmd }' run. Now to test."
    criteria_result = analyze_criteria(count, test_cmd, std_response, criteria)
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
  set_result(test_done_result, comment)
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
    elsif std_response[/#{criterion}/io]
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
  else
    @test_params.params_chan.constraints
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

def get_platform()
  if @equipment['dut1'].id.split("_").grep(/k2.?/).size > 0
    @equipment['dut1'].id.split("_").grep(/k2.?/)[0] 
  else
    "k2h"
  end
end

# Public: Copy archive from test_folder_location to linux_host.
#   untar archive in /usr/bin/ directory of EVM, flattening its file structure.
# Copy dtb files from usr/bin/ti/drv/rm/test/dts_files to /usr/bin,
# Copy dtb files from /usr/bin/device/k2h and rename to have _k2h
# Copy dtb files from /usr/bin/device/k2k and rename to have _k2k
#
# test_folder_location = "@test_params.lld_test_archive"
def build_files(test_folder_location)
  if test_folder_location
    #copy tar.gz from server to flat_n_tar, untar, flatten, tar, mv to tftpboot
    puts "'***Begin server side archive flattening***'"
    flat_n_tar = "unassembles"
    @equipment['server1'].send_cmd("mkdir #{ flat_n_tar }",
      @equipment['server1'].prompt, 10)
    @equipment['server1'].send_cmd("chmod 777 #{ flat_n_tar }",
      @equipment['server1'].prompt, 10)
    @equipment['server1'].send_cmd("cd #{ flat_n_tar }; \
      cp #{test_folder_location} test_archive.tar.gz",
      @equipment['server1'].prompt, 20)
    @equipment['server1'].send_cmd("cd #{ flat_n_tar }; \
      tar -xvzf test_archive.tar.gz --transform=\'s/.*\\///\'",
      @equipment['server1'].prompt, 10)
    @equipment['server1'].send_cmd("cd #{ flat_n_tar }; \
      tar -cvzf test_archive.tar.gz *.out *.dtb",
      @equipment['server1'].prompt, 20)
    @equipment['server1'].send_cmd("cd #{ flat_n_tar };
      cp test_archive.tar.gz #{ @equipment['server1'].tftp_path }
      /test_archive.tar.gz",
      @equipment['server1'].prompt, 10)
    @equipment['server1'].send_cmd("rm -r #{ flat_n_tar }",
      @equipment['server1'].prompt, 20)
    puts "'***end server side archive flattening***'"

    @equipment['dut1'].send_cmd("cd /usr/bin/", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("tftp -g -r test_archive.tar.gz \
      #{ @equipment['server1'].telnet_ip }", @equipment['server1'].prompt, 20)
    @equipment['dut1'].send_cmd("tar -xvzf test_archive.tar.gz",
      @equipment['dut1'].prompt, 10)
    puts "Done rebuilding archive."
  else
    puts "No archive flattening"
  end

  ##copy K2k dtb files
  @equipment['dut1'].send_cmd("cd /usr/bin/device/k2k",
    @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("ls", @equipment['dut1'].prompt, 10)
  if !@equipment['dut1'].response["_k2k.dtb"]
    @equipment['dut1'].send_cmd("for i in $(ls *.dtb); \
      do cp $i ${i%'.dtb'}'_k2k.dtb'; done", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("cp *.dtb /usr/bin",
      @equipment['dut1'].prompt, 10)
  end

  ##copy K2h dtb files
  @equipment['dut1'].send_cmd("cd /usr/bin/device/k2h",
    @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("ls", @equipment['dut1'].prompt, 10)
  if !@equipment['dut1'].response["_k2h.dtb"]
    @equipment['dut1'].send_cmd("for i in $(ls *.dtb); \
      do cp $i ${i%'.dtb'}'_k2h.dtb'; done", @equipment['dut1'].prompt, 10)
    @equipment['dut1'].send_cmd("cp *.dtb /usr/bin",
      @equipment['dut1'].prompt, 10)
  end

  ##copy dtb files
  @equipment['dut1'].send_cmd("cd /usr/bin/ti/drv/rm/test/dts_files",
    @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("ls", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cp *.dtb /usr/bin",
    @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cd", @equipment['dut1'].prompt, 10)
end

# Public: Check all files specified in commands exist.
# If file has _k2x, see that it matches other files with _k2x.
#
# commands - commands variable from TestLink
#
# Returns whether or not good files are specified, with comments
def good_files_specified?(commands)
  comment = ""
  file_list = Array.new
  ##Look through all commands for required files

  commands.each do |command|
    if command
      if command[/\(.*\)/] # takes care of commands formatted like 'method()'
        method = command[/.*\(/].to_s.sub('(', '')
        command = command.sub(method, '')
        command = command.sub('(', '').sub(')', '').sub(":"," ")
      end
      command.split(" ").uniq.each do |piece|
        folder = piece[/.*\//]
        file = folder ? piece[folder.length, piece.length] : piece
        if file =~ /\.{1}\w+/
          file_list.push(piece)
        end
      end
    end
  end

  puts "File list: '#{file_list}'"
  ##Check if all specified files exist
  file_version = ""
  seen_files = ""
  file_list.each do |tag|
    next if seen_files[tag]
    folder = tag[/.*\//]  ##parse for folder location
    if folder
      file = tag[folder.length,tag.length]
    else
      folder = ""
      file = tag
    end
#!! Version parsing may be different
    ##ensure that file versions are the same
    if tag[/[a-zA-Z]\.{1}\w+/]
      file_version += tag[/[a-zA-Z]\.{1}\w+/][0]
      if file_version.length > 1 && !tag[/.txt/] && tag[/_k2/]
        (file_version.length-1).times do |i|
          if file_version[i] != file_version[i+1]
            comment += "File version different: #{tag}. "
          end
        end
        file_version = file_version[0]
      end
    end
    file_extension = file[/\.{1}\w+/]

    ##check that the file exists, where specified, or in /usr/bin/
    if file_extension != ".txt"
      ls_cmd = "ls #{folder}*#{file_extension}"
      @equipment['dut1'].send_cmd(ls_cmd, @equipment['dut1'].prompt, 5)
      seen_files = seen_files + @equipment['dut1'].response
      if seen_files[file] == false
        puts "dealing with timeout in '/usr/bin.' "
        @equipment['dut1'].send_cmd(ls_cmd.insert(3, "/usr/bin/"), file, 10)
        if @equipment['dut1'].timeout?
          comment += "File #{file} not found. Check input \
          '#{ commands }' for correctness. "
          return [false, comment]
        else
          seen_files = seen_files + @equipment['dut1'].response
          puts "Time out resolved. found in '/usr/bin/.' "
        end
      end
    else
      puts "skipping text file #{file}."
    end
  end
  puts "Files all checked.'#{ file_list }'\n"
  [true, "'#{ comment } File_list: #{ file_list }. '"]
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
  ##Set up files (from archive) to /usr/bin/
  build_files(test_folder_location)

  ##Parse commands for files needed
  files_result = good_files_specified?(commands)
  if files_result[0] == false
    comment = "'#{files_result[1]}.' Files requested not available. "
    return [false, comment]
  else
    puts "good files specified: '#{ files_result[1] }'"
  end

  other_cmds = commands[1...commands.length]
  if other_cmds.to_s[/rmServer/] && rmServer_up? == false
    comment = "rmServer not running initially. \n"
  else
    puts comment = "rmServer running initially. "
  end

  ##Run other comamds
  if other_cmds[0]
    cmd_result = run_command(other_cmds)
    if cmd_result[0] == false
      return [false, comment + cmd_result[1]]
    else
      comment += cmd_result[1]
    end
  end

  if other_cmds.to_s[/rmServer/] and rmServer_up? == false
    comment += "Server did not start in background. "
    return [false, comment]
  elsif other_cmds.to_s[/rmServer/]
    comment += "Successfully started rmServer in background. "
    puts "**SERVER UP**\n"
  end

  [true,comment]
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
def rubify(some_string)
  if some_string[/\(.*\)/]
    method = some_string[/.*\(/].to_s.sub('(', '')
    args = some_string.to_s.sub(method, '').sub(')', '').sub('(', '')
    args_array = args.split(":")
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
# Return if cmds sent succesfully, with comments
def run_command(cmds, look_for = @equipment['dut1'].prompt)
  comment = ""
  cmds.each do |cmd|
    comment += "Running " + cmd.to_s + ". "
    if rubify(cmd)
      puts cmd + " run. command sent as ruby method"
    else
      @equipment['dut1'].send_cmd(cmd, look_for, 40)
      if @equipment['dut1'].timeout?
        puts comment += "FAILURE to meet criteria '#{ look_for }'**"
        comment += "cmd " + cmd.to_s + " not sent correctly. "
        return [false, comment]
      end
    end

    std_response = @equipment['dut1'].response.to_s
    @equipment['dut1'].log_info("\r\nstd_response(run_command): #\"#{std_response}\"#\r\n")
    if std_response[/Segmentation fault/]
      comment += "\nSeg fault error."
      return [false, comment]
    end
    comment +=  cmd.to_s + " run. \n"
  end
  return [true, comment]
end

def clean
  ##return to home directory
  @equipment['dut1'].send_cmd("cd", @equipment['dut1'].prompt, 10)

  ##close rmServer if up
  if rmServer_up?
    pid_info = @equipment['dut1'].response.to_s[/[0-9]+/].to_i  #find pid here
    @equipment['dut1'].send_cmd("kill -9 #{pid_info}",
      @equipment['dut1'].prompt, 10) if pid_info != 0
    if !@equipment['dut1'].timeout?
      puts "Successfully closed rmServer. "
    end
  end
  @equipment['dut1'].send_cmd("echo", @equipment['dut1'].prompt, 10)

  ##close rmDspClient if up
  if rmDspClient_up?
    pid_info = @equipment['dut1'].response.to_s[/[0-9]+/].to_i  #find pid here
    @equipment['dut1'].send_cmd("kill -9 #{pid_info}",
      @equipment['dut1'].prompt, 10) if pid_info != 0
    if !@equipment['dut1'].timeout?
      puts "Successfully closed rmDspClient. "
    end
  end
  @equipment['dut1'].send_cmd("echo", @equipment['dut1'].prompt, 10)

  ##soft reboot if parameter is true.
  begin
    soft_reboot = false
    if defined? @test_params.params_control.soft_reboot
      soft_reboot = @test_params.params_control.soft_reboot
    elsif defined? @test_params.params_chan.soft_reboot
      soft_reboot = @test_params.params_chan.soft_reboot
    end
    if soft_reboot
      puts "Rebooting"
      soft_reboot()
    end
  rescue Exception => e
    puts e.to_s + "\n" + e.backtrace.to_s
    raise e
  end
end