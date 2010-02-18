@ECHO off
dir
echo "Testing EVM with IP:  #{@equipment['dut1'].telnet_ip}"
echo "Testing Kernel image: #{@test_params.kernel}"
echo "Ruby code test: #{3*3}"
cd \NAND Flash
start osbench -h
xxxxx

