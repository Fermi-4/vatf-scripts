# Utilities file, to be used with runlld.rb

def exampleA(argA, argB)
	@equipment['dut1'].send_cmd("echo 'running exampleA(#{argA}, #{argB})'", @equipment['dut1'].prompt, 10)
	puts "exampleA: I have found #{argA} and #{argB}"
end

def exampleB(argA, argB)
	@equipment['dut1'].send_cmd("echo 'running exampleB(#{argA}, #{argB})'", @equipment['dut1'].prompt, 10)
	argB.to_i.times do |count|
		puts "iteration #{count}"
		puts " exampleB: I have found #{argA} and #{argB}"
	end
end

def exampleC
	#tested to see that this format will not cause errors when echo-ing
	@equipment['dut1'].send_cmd("echo 'running exampleC()'", @equipment['dut1'].prompt, 10)
	puts "'running exampleC() 3'"
end

#./load_all.sh rmK2HArmv7LinuxDspClientTestProject.out
def mpm_load_all(out_file, num_of_cores = 8)
	for count in 0..(num_of_cores-1)
		puts " 'Loading and Running #{out_file}...'"
		@equipment['dut1'].send_cmd("./mpmcl load dsp#{count} #{out_file}", @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			return false
		end
		@equipment['dut1'].send_cmd("./mpmcl run dsp#{count}", @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			return false
		end
		puts "Done"
	end
end 

def mpm_stop_all(file, num_of_cores = 8)
	for count in 0..(num_of_cores-1)
		puts "'Resetting core #{file}...'"
		@equipment['dut1'].send_cmd("mpmcl reset dsp#{count}", @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			return false
		end
		@equipment['dut1'].send_cmd("mpmcl status dsp#{count}", @equipment['dut1'].prompt, 10)
		if @equipment['dut1'].timeout?
			return false
		end		
		puts "Done"
	end
end

def dump_trace(num_of_cores = 8)
	for count in 0..(num_of_cores-1)
		puts "'Core #{count} Trace...'"
		@equipment['dut1'].send_cmd("cat /debug/remoteproc/remoteproc#{count}/trace0", @equipment['dut1'].prompt, 10)
		puts "'-----------------------------------------'"
	end
end

def soft_reboot
	if @equipment['dut1'].instance_variable_defined?(:@power_port)
		dut_power_port = @equipment['dut1'].power_port
		@equipment['dut1'].power_port = nil 
		@equipment['dut1'].power_cycle({'power_handler'=>1})
		@equipment['dut1'].connect({'type'=>'serial'})
		@equipment['dut1'].power_port = dut_power_port
		@equipment['dut1'].wait_for(/login:/, 60)
		
		@equipment['dut1'].send_cmd(@equipment['dut1'].login, @equipment['dut1'].prompt, 10) # login to the unit
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