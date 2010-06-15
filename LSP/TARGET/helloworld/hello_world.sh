ls
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"
echo "Testing Kernel image: #{@test_params.instance_variable_defined?(:@kernel) ? @test_params.kernel.to_s : 'No kernel specified'}"
echo "Math expression evaluation: #{3*3}"
echo "Sample DUT config  parameter: #{@test_params.params_chan.sample_param[0]}"
