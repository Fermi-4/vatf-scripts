###########################
## FOR THE NIGHTLY BUILD ##
###########################
## Date: July 25, 1013
#flipped shell files to ruby script, and now requires user to input the number of iterations to do, one per core.

#./load_all.sh rmK2HArmv7LinuxDspClientTestProject.out
def mpm_load_all(out_file, num_of_cores = 8)
	for count in 0..(num_of_cores-1)
		@equipment['dut1'].send_cmd("echo Loading and Running " + out_file.to_s + "...", @equipment['dut1'].prompt, 10)
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
		@equipment['dut1'].send_cmd("echo Resetting core " + file.to_s + "...", @equipment['dut1'].prompt, 10)
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
		@equipment['dut1'].send_cmd("echo Core #{count} Trace...", @equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("cat /debug/remoteproc/remoteproc#{count}/trace0", @equipment['dut1'].prompt, 10)
		@equipment['dut1'].send_cmd("echo -----------------------------------------", @equipment['dut1'].prompt, 10)
	end
end