@ECHO off
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"

echo "Command Line: #{@test_params.params_chan.cmdline[0]}"
echo "Command Line: #{@test_params.params_chan.cmdline[1]}"
echo "Command Line: #{@test_params.params_chan.test_dir[0]}"
do opm ?
#{test_command}


