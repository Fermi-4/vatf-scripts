@ECHO off
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"
echo "Testing Kernel image: #{@test_params.kernel}"
echo "Command Line: #{@test_params.params_chan.cmdline[0]}"






