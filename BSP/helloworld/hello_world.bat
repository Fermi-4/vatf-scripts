@ECHO off
dir
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"
echo "Testing Kernel image: #{@test_params.kernel}"
echo "Math expression evaluation: #{3*3}"
cd #{@test_params.params_chan.test_dir[0]}
start osbench -h



