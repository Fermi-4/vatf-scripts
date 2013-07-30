###########################
## FOR THE NIGHTLY BUILD ##
###########################
## Date: July 30, 1013
#flipped shell files to ruby script, and now requires user to input the number of iterations to do, one per core.

def exampleA(argA, argB)
	@equipment['dut1'].send_cmd("echo 'running exampleA(#{argA}, #{argB})'", @equipment['dut1'].prompt, 10)
	@equipment['dut1'].send_cmd("echo exampleA: I have found #{argA} and #{argB}", @equipment['dut1'].prompt, 10)
end

def exampleB(argA, argB)
	@equipment['dut1'].send_cmd("echo 'running exampleB(#{argA}, #{argB})'", @equipment['dut1'].prompt, 10)
	argB.to_i.times do |count|
		@equipment['dut1'].send_cmd("echo iteration #{count}", @equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("echo exampleB: I have found #{argA} and #{argB}", @equipment['dut1'].prompt, 10)
	end
end

def exampleC
	#tested to see that this format will not cause errors when echo-ing
	@equipment['dut1'].send_cmd("echo 'running exampleC() 3'", @equipment['dut1'].prompt, 10)
end

#./load_all.sh rmK2HArmv7LinuxDspClientTestProject.out
def mpm_load_all(out_file, num_of_cores = 8)
	for count in 0..(num_of_cores-1)
		@equipment['dut1'].send_cmd("echo 'Loading and Running #{out_file}...'", @equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("./mpmcl load dsp#{count} #{out_file}", @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			return false
		end
		@equipment['dut1'].send_cmd("./mpmcl run dsp#{count}", @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			return false
		end
		@equipment['dut1'].send_cmd("echo Done", @equipment['dut1'].prompt, 10)
	end
end 

def mpm_stop_all(file, num_of_cores = 8)
	for count in 0..(num_of_cores-1)
		@equipment['dut1'].send_cmd("echo 'Resetting core #{file}...'", @equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("mpmcl reset dsp#{count}", @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			return false
		end
		@equipment['dut1'].send_cmd("mpmcl status dsp#{count}", @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			return false
		end		
		@equipment['dut1'].send_cmd("echo Done", @equipment['dut1'].prompt, 10)
	end
end

def dump_all(num_of_cores = 8)
	for count in 0..(num_of_cores-1)
		@equipment['dut1'].send_cmd("echo 'Core #{count} Trace...'", @equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("cat /debug/remoteproc/remoteproc#{count}/trace0", @equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("echo '-----------------------------------------'", @equipment['dut1'].prompt, 10)
	end
end