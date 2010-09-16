@ECHO off
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"
echo "Testing Kernel image: #{@test_params.kernel}"
echo "Command Line: #{@test_params.params_chan.cmdline[0]}"
echo "Command Line: #{@test_params.params_chan.cmdline[1]}"
echo "Command Line: #{@test_params.params_chan.resolution[0]}"
echo "Command Line: #{@test_params.params_chan.media_location[0]}"
do opm ?
#{test_command}


