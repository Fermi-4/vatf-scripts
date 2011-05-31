@ECHO off
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"
echo "Testing Kernel image: #{@test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel.to_s : 'No kernel specified'}"
echo "Command Line: #{@test_params.params_chan.cmdline[0]}"
mkdir \Release
echo "Command Line: #{translate_module_name(@test_params.params_chan.cmdline[0],@test_params.platform,'MSFlash')}"
#{translate_module_name(@test_params.params_chan.cmdline[0],@test_params.platform,'MSFlash')}


