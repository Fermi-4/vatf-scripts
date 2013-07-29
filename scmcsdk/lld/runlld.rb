###########################
## FOR THE NIGHTLY BUILD ##
###########################
## Date: July 29, 2013
#From the set of three inputs, run the test specified by the first command, after setting up the environment for it to run. Upon running a test, check the output for specified terms to check test completion and success.
#A build parameter @test_params.lld_test_archive, is a tar.gz archive transferred from an ftp server, specified in build
#Look below at internally_consistent? to see about constraint options that are not literal matches
#'scmcsdk: changed -/+ usage for criteria; more helper methods to clear up run() clutter'

require 'fileutils'
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/common_utils.rb'
include LspTestScript
@show_debug_messages = false

def setup
  self.as(LspTestScript).setup
end

#? how do errors get passed up the chain?

#@	commands is a semi-colon separated array of commands (type string) to run. the VERY FIRST command is the test file to run
	#Example commands = "/usr/bin/qmScfgTest_k2h.out;cd /usr/bin/;rmServer_k2h.out global-resource-list_k2h.dtb policy_dsp_arm_k2h.dtb;cd"
#@	constraints is a semi-colon separated array of constraints/criteria for run() to compare against
	#Example constraints = "Static Memory region configuration tests Passed"
#@	iterations is the number of times run() will run the commands
#@	lld_test_archive is part of the build description. it holds a flattened (or structured) folder of .dtb, .out, and .sh files
def run
	test_done_result = FrameworkConstants::Result[:fail]
	comment = "*Test failed.*\n" #initial assumptions

	#directory and name of file to test
	commands = assign_commands()
	@equipment['dut1'].send_cmd(commands.to_s, @equipment['dut1'].prompt, 5)
	@equipment['server1'].send_cmd(commands.to_s, @equipment['server1'].prompt, 5)
	test_cmd = commands[0].to_s
	#criteria[0] is a phrase signifying test completion. criteria[!0] signifies a passing test. 
	criteria = assign_criteria()
	#number of times to run the test
	iterations = assign_iterations()
	test_folder_location = nil
	#REMOVE FOR NIGHTLY# test_folder_location = @test_params.lld_test_archive #REMOVE FOR NIGHTLY#
	
	##Prepare for running tests. Bundle up file building, server starting
	prep_results= prepare_for_test(test_folder_location,commands)	
	comment += prep_results[1]
	if !prep_results[0]
		set_result(test_done_result,comment)
		return
	end
	
	##see if test passes and satisfies criteria
	if @show_debug_messages  #FOR MORE COMMENTS#
		comment += "Running Test.\n" 
	else #FOR LESS COMMENTS#
		comment = "Running Test.\n" 
	end
	iterations.times do |count|
		if rubify(test_cmd) #command sent as ruby
			puts "rubify finished iteration #{count +1}" 
		else #send_cmd, store buffer into std_response
			@equipment['dut1'].send_cmd(test_cmd, /#{criteria[0]}/i, 25)
			if @equipment['dut1'].timeout?
				puts comment += "**On iteration #{count +1}, FAILURE to meet end criteria #{criteria[0]}**"
				set_result(test_done_result,comment)
				return
			else
				puts "send_cmd finished iteration #{count +1}" 
			end
		end
		std_response = @equipment['dut1'].response.to_s
		#use regEx to pattern-match literal constraints, or parse if preceded by +/- for pass/fail
#!! currently searches for first instance of criterion. may need to change to number of times appears, etc
		#arguments count and test_cmd are only for commenting -- not used for other purposes in analyze_criteria
		criteria_result = analyze_criteria(count,test_cmd,std_response,criteria)
		if !criteria_result[0]
			set_result(test_done_result,comment + criteria_result[1])
			return
		end
		@equipment['dut1'].send_cmd("echo iteration #{count +1} done. ", @equipment['dut1'].prompt, 10)
	end
	
#! still need to check the output of the rmServer... maybe a user commmand?
	##DONE
	@equipment['dut1'].send_cmd("echo #{test_cmd}\n*TEST PASSED*", @equipment['dut1'].prompt, 10)
	comment += "\n" + test_cmd.to_s + " *TEST PASSED*"
	test_done_result = FrameworkConstants::Result[:pass]
	set_result(test_done_result,comment)
end

##loops through criteria and searches for criteria in std_response. 
#returns false if not found or when special cases fail
#format of result = [state, comment]
def analyze_criteria(count,test_cmd,std_response,criteria)
	comment = ""
	state = false
	criteria.each do |criterion|
		@equipment['dut1'].send_cmd("echo looking for criterion \"#{criterion}\"",@equipment['dut1'].prompt, 25)
		if criterion[0] == "-" #if criterion is preceded by a -, fail output contains failure_word
			failure_word = criterion[/\S.+\S/][1, criterion[/\S.+\S/].length]
			if std_response[/#{failure_word}/io]
				@equipment['dut1'].send_cmd("echo Output contains **#{failure_word}**",@equipment['dut1'].prompt, 10)
				comment += "Fail " + test_cmd.to_s + " on iteration #{count +1}. Output contains **#{failure_word}**."
				return [state, comment]
			end
		elsif criterion[0] == "+" #if criterion is preceded by a +, call internally_consistent?
			new_criterion = criterion[/\S.+\S/][1, criterion[/\S.+\S/].length]
			@equipment['dut1'].send_cmd("echo consistency testing for #{new_criterion}",@equipment['dut1'].prompt, 10)
			type_of_check = criterion[/\S.+\S/][criterion[/\S.+\S/].length]
			#type_of_check can be +,=,: 
			c_result = internally_consistent?(std_response, type_of_check, new_criterion)
			#this is the format of c_result = [consistent?, comments]
			if !c_result[0]
				comment += "Fail " + test_cmd.to_s + " for output inconsistency." 
				set_result(test_done_result,comment + c_result[1])
				return
			end
		#else, scan buffer to see if send_cmd result matches criterion
		elsif std_response[/#{criterion}/io]
			@equipment['dut1'].send_cmd("echo Output has criterion #{criterion}", @equipment['dut1'].prompt, 10)
			comment += "Iteration #{count+1}: Output has criterion \"#{criterion}\".\n"
		else
			comment += "Fail " + test_cmd.to_s + " on iteration #{count +1}. Criterion \"#{criterion}\" not met."
			return [state, comment]
		end
	end
	return [true,comment]
end

def assign_commands()
	if defined? @test_params.params_control.commands
		return @test_params.params_control.commands
	else
		return @test_params.params_chan.commands
	end	
end

def assign_criteria()
	if defined? @test_params.params_control.constraints
		return @test_params.params_control.constraints
	else
		return @test_params.params_chan.constraints
	end	
end

def assign_iterations()
	if defined? @test_params.params_control.iterations
		return @test_params.params_control.iterations[0].to_i
	else
		return @test_params.params_chan.iterations[0].to_i
	end
end

##copy archive from ftp server location "@test_params.lld_test_archive" to linux_host
##untar the archive in the /usr/bin/ directory of the EVM, flattening its file structure
def build_files (test_folder_location)
	comment = ""
#NOTE: possible to search for the file somewhere else, then run it from there. or even copy the file to the local folder
	# get tar.gz file. untar everything to /usr/bin/
	if test_folder_location
		#copy the tar from ftp server to a new folder, untar, flatten, tar, move it to tftpboot
		@equipment['dut1'].send_cmd("echo ***begin server side archive flattening***",@equipment['dut1'].prompt, 10)
		@equipment['server1'].send_cmd("cp #{test_folder_location} test_archive.tar.gz",@equipment['server1'].prompt, 20)
		@equipment['server1'].send_cmd("tar -xvzf test_archive.tar.gz --transform=\'s/.*\\///\'",@equipment['server1'].prompt, 20)
		@equipment['server1'].send_cmd("ls *.out *.sh *.dtb",@equipment['server1'].prompt, 10)
		@equipment['server1'].send_cmd("tar -cvzf test_archive.tar.gz *.out *.sh *.dtb",@equipment['server1'].prompt, 20)
		@equipment['server1'].send_cmd("tar -tvzf test_archive.tar.gz *.out *.sh *.dtb",@equipment['server1'].prompt, 20)
		@equipment['server1'].send_cmd("cp test_archive.tar.gz #{@equipment['server1'].tftp_path}/test_archive.tar.gz",@equipment['server1'].prompt, 10)
		
		@equipment['dut1'].send_cmd("echo #{test_folder_location} test_archive.tar.gz",@equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("echo tar -xvzf test_archive.tar.gz --transform=\'s/.*\\///\'",@equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("echo -cvzf test_archive.tar.gz *.out *.sh *.dtb",@equipment['server1'].prompt, 10)
		@equipment['dut1'].send_cmd("echo cp test_archive.tar.gz #{@equipment['server1'].tftp_path}/test_archive.tar.gz",@equipment['server1'].prompt, 10)
		@equipment['dut1'].send_cmd("echo ***end server side archive flattening***",@equipment['dut1'].prompt, 10)

		@equipment['dut1'].send_cmd("cd /usr/bin/",@equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("tftp -g -r test_archive.tar.gz #{@equipment['server1'].telnet_ip}", @equipment['dut1'].prompt, 20)
		@equipment['dut1'].send_cmd("tar -xvzf test_archive.tar.gz",@equipment['dut1'].prompt, 20)
		@equipment['dut1'].send_cmd("echo",@equipment['dut1'].prompt, 10)	
	else
		@equipment['dut1'].send_cmd("echo no archive flattening",@equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("cd /usr/bin/device/k2k",/#{@equipment['dut1'].prompt}/, 10)
		@equipment['dut1'].send_cmd("ls",/#{@equipment['dut1'].prompt}/, 10)
		if !@equipment['dut1'].response["_k2k.dtb"]
			@equipment['dut1'].send_cmd("for i in $(ls *.dtb); do cp $i ${i%'.dtb'}'_k2k.dtb'; done",/#{@equipment['dut1'].prompt}/, 10)
			@equipment['dut1'].send_cmd("cp *.dtb /usr/bin",/#{@equipment['dut1'].prompt}/, 10)
		end
		@equipment['dut1'].send_cmd("cd /usr/bin/device/k2h",/#{@equipment['dut1'].prompt}/, 10)
		@equipment['dut1'].send_cmd("ls",/#{@equipment['dut1'].prompt}/, 10)
		if !@equipment['dut1'].response["_k2h.dtb"]
			@equipment['dut1'].send_cmd("for i in $(ls *.dtb); do cp $i ${i%'.dtb'}'_k2h.dtb'; done",/#{@equipment['dut1'].prompt}/, 10)
			@equipment['dut1'].send_cmd("cp *.dtb /usr/bin",/#{@equipment['dut1'].prompt}/, 10)
		end
	end
	@equipment['dut1'].send_cmd("cd",/#{@equipment['dut1'].prompt}/, 10)
	return comment
end

##Make a array of files needed to run the commands in input, ensure they are version consistent, check these files to ensure they exist
# returns [good_files_specified=true|bad_file_specification=false, comments, file_list]
def good_files_specified?(commands)
	file_list = Array.new
	comment = ""
	##Look through all commands and see if they require files
	commands.each do |command|
		if command
			if command[/\(.*\)/] # to take care of commands that are formatted method()
				method = command[/.*\(/].to_s.sub('(', '')
				command = command.sub(method, '').sub('(', '').sub(')', '').sub(":"," ")
			end
			command.split(" ").uniq.each do |piece_of_command|
				folder = piece_of_command[/.*\//]
				if folder
					file = piece_of_command[folder.length,piece_of_command.length]
				else
					file = piece_of_command
				end
				if file =~ /\.{1}\w+/
					file_list.push(piece_of_command)
				else
					#comment += "Ignored #{file}. "
				end
			end
		end
	end
	@equipment['dut1'].send_cmd("echo File list." + file_list.to_s, @equipment['dut1'].prompt, 10)
	
	##Check if all specified files exist, else return <file not found>
	file_version = ""
	seen_files = ""
	file_list.each do |tag|
		next if seen_files[tag]
		##parse the folder location
		folder = tag[/.*\//]
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
			if file_version.length > 1 and !tag[/.txt/]
				(file_version.length-1).times do |i|
					if file_version[i] != file_version[i+1]
						comment += "File version different: " + tag.to_s + ". "
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
			if !seen_files[file]
				@equipment['dut1'].send_cmd("echo dealing with timeout in /usr/bin", @equipment['dut1'].prompt, 10)
				@equipment['dut1'].send_cmd(ls_cmd.insert(3, "/usr/bin/"), file, 10)
				if @equipment['dut1'].timeout?
					comment += "File " + file + " not found. Check input " + @test_params.params_control.commands.to_s + " for correctness. "
					return [false, comment, file_list]
				else
					seen_files = seen_files + @equipment['dut1'].response
					@equipment['dut1'].send_cmd("echo Time out resolved. found in /usr/bin/. ", @equipment['dut1'].prompt, 10)
				end
				
			end
		end
		
	end
	@equipment['dut1'].send_cmd("echo Files all checked.\n " + file_list.to_s, @equipment['dut1'].prompt, 10)
	return [true, comment + "File_list: " + file_list.to_s + ". ", file_list]
end

#parse output to check consistency of output
	#things such, failed: 0; passed a, passed b, passed c, total passed=3;
#@ output is the std_response from running the cmd
#@ type_of_check can be of the following type
#@		"" meaning a normal keyword/phrase match
#@		":" meaning a comparison between the output's summary and the body of the output
#@		"=" meaning a comparison between results printed in the output summary
def internally_consistent? (output, type_of_check = "", criterion = "default")
	internal_comment = ""
	puts "\n0.testing for #{criterion}\n"
	regex_output = output[/#{criterion}/i]
	if regex_output == nil 
		puts "Nothing to test in output"
		return true
	else
		puts "#{regex_output} found."
	end
	#wc_hash is a word count for unique caseless word in the output
	wc_hash = output.ind_word_counts 
	puts "\n1.testing for #{criterion}\n"
	if type_of_check == "="
		#/^ packets \s sent .+ [0-9].+ packets \s received .+[0-9].+$/ # look at the number that appears after 
		if criterion.downcase == "packets" and output[/packets/i]
			line_s = output[/#{criterion.downcase} \s+ sent .* #{type_of_check} .* \d+ \S*/ix]
			line_r = output[/#{criterion.downcase} \s+ received .* #{type_of_check} .* \d+ \S*/ix]
			#if not nil but there are different numbers at the end, return
			if line_s != nil and line_r != nil and line_s[/\d+/].to_i != line_r[/\d+/].to_i 
				internal_comment += "Number of packets does not match up. "
				return [false, internal_comment]
			end
		end
	elsif type_of_check == ":" and output[/#{criterion.downcase}/i]
	# use String.ind_word_counts to see if it has a "passed", if it does, -1 that to see if it matches
		line = output[/#{criterion.downcase} \s* #{type_of_check} .* \d+ \S*/ix]
		wc = wc_hash["#{criterion.downcase}"]
		if line == nil
			puts "does not fit word : pattern"
		#if there is a number at the end, but different from word_count
		elsif line[/\d+/] and (line[/\d+/].to_i != 0) and criterion.downcase == "failed"
			internal_comment += "Failed more than 0 times. " + line.to_s
			return [false, internal_comment]
		elsif wc != 0 and line[/\d+/] and (line[/\d+/].to_i != (wc-1)) 
			internal_comment = "\n#{criterion.upcase} are not correctly counted. " + line.to_s
			return [false, internal_comment]
		end
		#make sure that if the test outputs the String "Failed", it was because nothing Failed
		if criterion.downcase[/failed/i]
			line = output[/failed \s* : .* \d+ \S*/ix]
			if line != nil and line[/\d+/] and (line[/\d+/].to_i != 0) #if there is a number at the end.
				internal_comment += ". Failed more than 0 times. " + line.to_s
				return [false, internal_comment]
			end
		end
	end

	#std_response 
	puts "Internally consistent"
	return [true, "Passed"]
end

##Do most of the preparation for testing: archive building, file checking, and server starting
def prepare_for_test(test_folder_location,commands)
	comment = ""
	##Set up files from archive
	comment += build_files(test_folder_location) 
	file_list = Array.new
	
	##Parse commands for files needed
	files_result = good_files_specified?(commands)
	if files_result[0]
		file_list = files_result[2]
		str = "echo good files specified: \n " + files_result[1].to_s + "\n"
		@equipment['dut1'].send_cmd(str,@equipment['dut1'].prompt, 20)
	else
		comment += files_result[1] + "Files requested not consistent with those available. "
		return [false, comment]
	end	
	other_cmds = commands[1...commands.length]
	@equipment['dut1'].send_cmd("echo Checked input. Preparing for test.\n", @equipment['dut1'].prompt, 10)
	##Run the rmServer when requested
	if other_cmds[0] and file_list.length > 1 and other_cmds.to_s[/rmServer/]
		rm_result = rmServer_up?(other_cmds)
		#rm_result = [up?, comments]
		if rm_result[0]
			str = "echo "+ rm_result[1] +  "\nrmServer up and running. \n"
			@equipment['dut1'].send_cmd(str, @equipment['dut1'].prompt, 10)
		else
			comment += rm_result[1] + "RmServer did not run. "
			return [false, comment]
		end
	elsif other_cmds[0] 
		other_cmds.each do |cmd| 
			if rubify(cmd)
				#command sent as ruby
			else
				@equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt, 20)
				if @equipment['dut1'].timeout?
					comment += "cmd " + cmd.to_s + " not sent correctly. "
					return [false, comment]
				end
			end
		end
	end
	return [true,comment]
end

#See if the server is running, and starts it if not up already
# returns [running=true|not_running=false, comments]
#["cd /usr/bin/","rmServer_k2h.out /usr/bin/global-resource-list_k2h.dtb /usr/bin/policy_dsp_arm_k2h.dtb > output.out &","cd"]
def rmServer_up? (other_cmds = [], file_version = "hk")
	comment = ""
	running = false
	##test to see that the rmServer is running. Start it if its not running
	@equipment['dut1'].send_cmd("ps | grep rmServer", /rmServer_k2[#{file_version}]/i, 10)
	if @equipment['dut1'].timeout?			#run a new rmServer in the background
		comment = "rmServer#{file_version} not running initially. \n"
		@equipment['dut1'].send_cmd("clear",@equipment['dut1'].prompt, 5)
		other_cmds.each do |cmd| 
			comment += "Running " + cmd.to_s + ". "
			if rubify(cmd)
				#command sent as ruby
			else
				@equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt, 20)
				if @equipment['dut1'].timeout?
					comment += "cmd " + cmd.to_s + " not sent correctly. "
					return [false, comment]
				end
			end
			comment +=  cmd.to_s + " run. \n"
		end
		#test to see that the rmServer is now running.
		@equipment['dut1'].send_cmd("ps | grep rmServer", /rmServer_k2[#{file_version}]/i, 5)
		if @equipment['dut1'].timeout?
			comment += "Server did not start. "
			return [false, comment]
		end
		#may need to wait longer for the rmServer to be able to take input
		comment += "Successfully started rmServer in background. "
	else
		comment = "rmServer running initially. "
	end
	puts "**SERVER UP**\n"
	running = true
	return [running, comment]
end

##parse a string to see if it is a method call, then call it with its arguments
##does nothing if there are no parentheses.
##multiple arguments are separated by a colon : 
#example string "funct(x:y)" will be run, as send(funct, [x,y])
def rubify(some_string)
	if some_string[/\(.*\)/]
		method = some_string[/.*\(/].to_s.sub('(', '')
		args = some_string.to_s.sub(method, '').sub(')', '').sub('(', '').to_s
		args_array = args.split(":")
		if @show_debug_messages
			str = 'echo Method= ' + method + ', Argument(s)= ' + args_array.to_s + '.'
			@equipment['dut1'].send_cmd(str, @equipment['dut1'].prompt, 5)
		end
		begin
			self.send(method, *args_array)
			return true
		rescue => detail
			error = detail.backtrace.join("\n")
			@equipment['dut1'].send_cmd("echo #{error}", @equipment['dut1'].prompt, 5)
			raise "Error: ruby command not recognized #{method}"
		end
	else
		return false
	end
end

##to send a cmd in sudo, if necessary
def sudo_cmd(cmd, expected_match=/.*/, timeout=30)
	if cmd[/sudo/]
		send_sudo_cmd(cmd, expected_match=/.*/, timeout=30)
	else
		return false
	end
end 
##to look for passed, failed, etc. and have a noCase count of them
class String
	def ind_word_counts
		@freq = Hash.new(0)
		downcase.scan(/(\w+([-'.]\w+)*)/) {|word, space| @freq[word.downcase] +=1}
		return @freq
	end
	def phrases
		@total = 0
		downcase.scan(/(\w+([-'.\/]\w+)*)/) {|word, space| @total +=1}
		return @total
	end
end

def clean
	##return to home directory
	@equipment['dut1'].send_cmd("cd",@equipment['dut1'].prompt, 10)

	##close rmServer upon completion if it was up, after each test
	@equipment['dut1'].send_cmd("ps | grep rmServer", @equipment['dut1'].prompt, 10)
	processes = @equipment['dut1'].response.to_s
	if processes[/rmServer.{1,5}out/i] or processes[/rmServer_k2/i]
		pid_info = @equipment['dut1'].response.to_s[/[0-9]+/].to_i	#find pid here
		begin  
			@equipment['dut1'].send_cmd("kill #{pid_info}",@equipment['dut1'].prompt,10)
		end while @equipment['dut1'].timeout?
		comment += "Successfully closed rmServer. "
	end
end