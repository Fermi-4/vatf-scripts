@ECHO off
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"
echo "Testing Kernel image: #{@test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel.to_s : ''}"
echo "Command Line: #{@test_params.params_chan.cmdline[0]}"
mkdir \Release
#{@test_params.params_chan.cmdline[0]}

