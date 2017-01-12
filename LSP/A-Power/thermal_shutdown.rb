require File.dirname(__FILE__)+'/../default_test_module'

include LspTestScript

# Returns true if command returns non-zero value, e.g. there was an error
def check_cmd(cmd, expect, timeout=10)
	@equipment['dut1'].send_cmd(cmd, expect, timeout)
	@last_cmd_response = @equipment['dut1'].response
	@equipment['dut1'].send_cmd("echo $?",/^0[\0\n\r]+/m, 2, false)
    @equipment['dut1'].timeout?
end

def run
	if check_cmd "zcat /proc/config.gz |grep THERMAL_EMULATION=y", @equipment['dut1'].prompt
		return set_result FrameworkConstants::Result[:ns], "THERMAL_EMULATION kernel config option not set.\n"
	end

	if check_cmd "zcat /proc/config.gz |grep CPU_THERMAL=y", @equipment['dut1'].prompt
		return set_result FrameworkConstants::Result[:ns], "CPU_THERMAL kernel config option not set.\n"
	end

	if check_cmd "ls /sys/class/thermal/thermal_zone0/emul_temp", @equipment['dut1'].prompt
		return set_result FrameworkConstants::Result[:fail], "emul_temp node not found.\n"
	end

	if check_cmd "grep -rl 'critical' /sys/class/thermal/*/ 2>/dev/null |head -n 1", @equipment['dut1'].prompt
		return set_result FrameworkConstants::Result[:fail], "no critical trip point found.\n"
	end

	temp_node = @last_cmd_response.match(/^(\/sys\/class\/thermal[^\n]+)/).captures[0]
	temp_node.gsub!(/_type/,'_temp')
	if check_cmd "cat #{temp_node}", @equipment['dut1'].prompt
		return set_result FrameworkConstants::Result[:fail], "could not read critical temp for #{temp_node}.\n"
	end

	temp_value = @last_cmd_response.match(/^(\d+)/).captures[0]
	temp_value = temp_value.to_i + 5000
	temp_node = "#{File.dirname(temp_node)}/emul_temp"
	@equipment['dut1'].send_cmd("echo #{temp_value} > #{temp_node}", /critical temperature reached.*shutting down/, 10)
    if @equipment['dut1'].timeout?
		return set_result FrameworkConstants::Result[:fail], "critical temp #{temp_value} for #{temp_node} did not trigger shutdown.\n"
    end

	if ! @equipment['dut1'].response.match(/reboot: Power down/)
		@equipment['dut1'].wait_for(/reboot: Power down/, 120)
	    if @equipment['dut1'].timeout?
			return set_result FrameworkConstants::Result[:fail], "critical temp #{temp_value} for #{temp_node} did not power down the board.\n"
	    end
	end

    set_result FrameworkConstants::Result[:pass], "critical temp #{temp_value} for #{temp_node} powered down the board.\n"

end
