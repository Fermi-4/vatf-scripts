require 'fileutils'

require File.dirname(__FILE__)+'/../../LSP/default_test_module'
include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def send_cmd_inputs(input, output, testName)
	@equipment['dut1'].send_cmd(input, output, 20)
	if @equipment['dut1'].timeout?
		comment = "Fail " + testName + ", "
	else
		comment = "Pass " + testName + ", "
	end
end

#? how do errors get passed up the chain?

#@	commands is a semi-colon separated array of commands (type string) to run. each command is composed of executable files
	#Example commands = "/usr/bin/qmScfgTest_k2h.out;rmServer_k2h.out global-resource-list_k2h.dtb policy_dsp_arm_k2h.dtb"
#@	constraints is a semi-colon separated array of constraints/criteria for run() to compare against
	#Example constraints = "Static Memory region configuration tests Passed"
#@	iterations is the number of times run() will run the commands
def run
	##get the files from ftp server
	#ftp "mcsdk/test/314_armv7.tar.gz"
	#get tarball. untar everything to /usr/bin/. run ___
	testFolder = @test_params.test_out_files
	@equipment['server1'].send_cmd("cp #{testFolder} #{@equipment['server1'].tftp_path}/armv7.tar.gz",@equipment['server1'].prompt, 20)
	@equipment['dut1'].send_cmd("cd /usr/bin/",@equipment['dut1'].prompt, 20)
	@equipment['dut1'].send_cmd("tftp -g -r armv7.tar.gz #{@equipment['server1'].telnet_ip}", @equipment['dut1'].prompt, 20)
	@equipment['dut1'].send_cmd("tar -xvzf armv7.tar.gz",@equipment['dut1'].prompt, 20)
	@equipment['dut1'].send_cmd("ls armv7",@equipment['dut1'].prompt, 20)
	armFolders = @equipment['dut1'].response
	puts "\n\n\nfolders #{armFolders} \n\n\n"
	
	test_done_result = FrameworkConstants::Result[:fail]
	comment = "*Test failed.*\n" #initial assumptions
	
	##Input parameters
	file_list = Array.new
	commands = @test_params.params_control.commands
	commands.each do |files|
		files.split(" ").each {|file| file_list.push(file)}
	end
	#directory and name of file to test
	test_cmd = @test_params.params_control.commands[0].to_s
	server_cmd = @test_params.params_control.commands[1].to_s
	#criteria[0] is a phrase signifying test completion. criteria[!0] signifies a passing test. 
	criteria = @test_params.params_control.constraints
	#number of times to run the test
	iterations = @test_params.params_control.iterations[0].to_i

#NOTE: possible to search for the file somewhere else, then run it from there. or even copy the file to the local folder
	##get additional files from ftp server
	inputfile= @test_params.lld_dtb
	@equipment['server1'].send_cmd("cp #{inputfile} #{@equipment['server1'].tftp_path}/lld_dtb.tar.gz",@equipment['server1'].prompt, 20)
	@equipment['dut1'].send_cmd("tftp -g -r lld_dtb.tar.gz #{@equipment['server1'].telnet_ip}", @equipment['dut1'].prompt, 20)
	@equipment['dut1'].send_cmd("tar -xvzf lld_dtb.tar.gz",@equipment['dut1'].prompt, 20)
	@equipment['dut1'].send_cmd("ls",@equipment['dut1'].prompt, 20)

	##proceed if all specified files exist, else return <file not found>
	file_version = ""
	file_list.each do |tag|
		##parse the folder location
		folder = tag[/.*\//]
		if folder
			file = tag[folder.length,tag.length]
		else 
			folder = ""
			file = tag
		end
		file_extension = tag[/\.{1}\w+/]
		##ensure that file versions are the same
		file_version += tag[/[a-zA-Z]\.{1}\w+/][0]
		if file_version.length > 1
			(file_version.length-1).times do |i|
				if file_version[i] != file_version[i+1]
					comment = "file versions are different: #{commands}. " 
				end
			end
			file_version = file_version[0]
		end
		##check that the file exists, where specified
		ls_cmd = "ls #{folder}*#{file_extension}"
		@equipment['dut1'].send_cmd(ls_cmd, /#{file}/i, 10)
		puts "Command Sent"
		if @equipment['dut1'].timeout?
			@equipment['dut1'].send_cmd(ls_cmd.insert(3, "/usr/bin/"), /#{file}/i, 10)
			if @equipment['dut1'].timeout?
				comment += "File #{file} not found. Check input #{@test_params.params_control.commands} for correctness"
				set_result(test_done_result,comment)
				return
			else
				puts "time out resolved. found in /usr/bin/"
			end
		end
	end

	##run the rmServer when requested
	if server_cmd and file_list.length > 1
#!! change to make output a testlink var
		rm_result = rmServer_up?(server_cmd, output = "rmServerOutput.txt")	
		#rm_result = [up?, comments, rmServer_PID]
		if rm_result[0]
			comment += rm_result[1] + "rmServer_k2#{file_version} up and running. "
			puts "rmServer up and running. "
			pid_info = rm_result[2]
		else
			comment += "rmServer did not run. "
			set_result(test_done_result,comment)
			return
		end
		#to kill the rmServer after this test
		#@equipment['dut1'].send_cmd("kill #{pid_info}",@equipment['dut1'].prompt,10)
	end

	##see if test passes and satisfies criteria
	comment = "\nRunning Test.\n"
	iterations.times do |count|
		#send_cmd, store buffer into std_response
		@equipment['dut1'].send_cmd(test_cmd, /#{criteria[0]}/i, 20)
		std_response = @equipment['dut1'].response.to_s
		if @equipment['dut1'].timeout?
			puts comment += "**On iteration #{count +1}, FAILURE to meet end criteria**"
		else
			puts "send_cmd finished iteration #{count +1}" 
		end

		#use regEx to pattern-match literal constraints
#!! currently searches for first instance of criterion. may need to change
		criteria.each do |criterion|
			puts "looking for criterion \"#{criterion}\""
			#if criterion is preceded by a -, call internally_consistent?
			if criterion[/-.*/i]
				print "consistency testing for "
				puts new_criterion = criterion[/\S.+\S/][1, criterion[/\S.+\S/].length]
				type_of_check = criterion[/\S.+\S/][criterion[/\S.+\S/].length]
				#type_of_check can be +,=,: 
				c_result = internally_consistent?(std_response, type_of_check, new_criterion)
				#c_result = [consistent?, comments]
				if !c_result[0]
					comment += "Fail #{test_cmd} for output inconsistency." 
					set_result(test_done_result,comment + c_result[1])
					return
				end
			#else, scan buffer to see if send_cmd result matches criterion
			elsif std_response[/#{criterion}/io]
				puts "Output has criterion #{criterion}"
				comment += "Iteration #{count+1}: Output has criterion \"#{criterion}\".\n"
			else
				comment += "Fail #{test_cmd} on iteration #{count +1}. Criterion \"#{criterion}\" not met."
				set_result(test_done_result,comment)
				return
			end
		end
		puts "Done with iteration #{count +1}. "
	end
	
	# EL edits
	#test = @test_params.params_control.test_tag[0].to_s
	#comment += "Ran test #{test}"
	# end EL edits

	##close rmServer upon completion if it was up, after each test
	if server_cmd and rm_result and file_list.length > 1
		#find pid here?
		#@equipment['dut1'].send_cmd("ps | grep rmserver",@equipment['dut1'].prompt,10) 
		begin  
			@equipment['dut1'].send_cmd("kill #{pid_info}",@equipment['dut1'].prompt,10)
		end while @equipment['dut1'].timeout?
		comment += "Successfully closed rmServer. "
	end
	
	##DONE
	puts "\nDone with #{test_cmd}"
	puts comment += "\n#{test_cmd} *TEST PASSED*"
	test_done_result = FrameworkConstants::Result[:pass]
	set_result(test_done_result,comment)
end

#looks to see if the server is running, and starts it if it is not up already
# returns [running=true|not_running=false, comments, rmServer pid]
#runCmd = "rmServer_k2#{file_version}.out /usr/bin/global-resource-list_k2#{file_version}.dtb /usr/bin/policy_dsp_arm_k2#{file_version}.dtb > #{output} &"
def rmServer_up? (server_cmd = "", output = "rmServerOutput.txt", file_version = "hk")
	running = false
	##test to see that the rmServer is running. Start it if its not running
	@equipment['dut1'].send_cmd("ps | grep rmServer", /rmServer_k2[#{file_version}]/i, 5)
	if @equipment['dut1'].timeout?			#run a new rmServer in the background
		comment = "rmServer not running initially."
		if server_cmd.phrases < 3
			return [false, "server_cmd has too few arguments - has #{server_cmd.phrases}; needs 3",nil]
		end
		runCmd = "#{server_cmd} > #{output} &"
		@equipment['dut1'].send_cmd(runCmd, @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			comment += "server did not start "
			return [false, comment ,nil]
		end
		#test to see that the rmServer is now running.
		@equipment['dut1'].send_cmd("ps | grep rmServer", /rmServer_k2[#{file_version}]/i, 10)
		if @equipment['dut1'].timeout?
			comment += "Prompt not received. "
			return [false, comment ,nil]
		end
		#may need to wait longer for the rmServer to be able to take input
		
		comment += "Successfully started rmServer in background. "
	else
		comment = "rmServer running initially. "
	end
	running = true
	pid_info = @equipment['dut1'].response.to_s[/[0-9]+/].to_i
	puts "\nPID info #{pid_info}\n"
	return [running, comment, pid_info]
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
			puts ""#does not fit word :# pattern
		#if there is a number at the end, but different from word_count
		elsif line[/\d+/] and (line[/\d+/].to_i != 0) and criterion.downcase == "failed"
			internal_comment += "Failed more than 0 times. #{line}"
			return [false, internal_comment]
		elsif wc != 0 and line[/\d+/] and (line[/\d+/].to_i != (wc-1)) 
			internal_comment = "\n#{criterion.upcase} are not correctly counted. #{line}"
			return [false, internal_comment]
		end
		#make sure that if the test outputs the String "Failed", it was because nothing Failed
	end

	#std_response 
	puts "Internally consistent"
	return [true, "Passed"]
end

#to look for passed, failed, etc. and have a noCase count of them
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

#/^ packets \s sent .+ [0-9].+ packets \s received .+[0-9].+$/
# look at the number that appears after 

def clean
end
