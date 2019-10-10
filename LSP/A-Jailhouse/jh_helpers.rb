def start_linux_demo()
    @equipment['dut1'].send_cmd("modprobe jailhouse",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cd /opt/ltp",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("./runltp -P #{@equipment['dut1'].name} -f ddt/jailhouse -s \"JAILHOUSE_S_FUNC_LINUX_INMATE \"",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cd",@equipment['dut1'].prompt)
    # Wait for the login prompt
    jh_send_cmd("", @equipment['dut1'].login_prompt)
end

def jh_send_cmd(cmd, expected_match=/.*/, timeout=10, check_cmd_echo=true, append_linefeed=true, conn=@equipment['dut1'].target.secondary_serial)
    puts("Connection: " + cmd)
    conn.send_cmd(cmd, expected_match, timeout, check_cmd_echo, append_linefeed)
    [conn.timeout?, conn.response]
end
