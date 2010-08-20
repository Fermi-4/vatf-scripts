@ECHO off
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"
echo "Testing Kernel image: #{@test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel.to_s : 'No kernel specified'}"
#{@test_params.params_chan.cmd[0]} #{@test_params.params_chan.fps[0].to_s == '0' ? '' : '-fps'} -vsync=#{@test_params.params_chan.vsync[0].to_s} -qat=#{@test_params.params_chan.time[0].to_s}





