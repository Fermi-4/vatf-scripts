require File.dirname(__FILE__)+'/../default_test_module'
include LspTestScript

def check_cmd(cmd, timeout=2, response=nil, dut='dut1')
  response = @equipment[dut].prompt if !response
  @equipment[dut].send_cmd(cmd, response, timeout)
  raise "Expected response not received from #{cmd}" if @equipment[dut].timeout?
  @equipment[dut].send_cmd("echo $?", /^0/m, 2)
  return_non_zero = @equipment[dut].timeout?
  raise "Error executing #{cmd}" if return_non_zero
end

def run
  begin
    # Delete tester user if it exists
    @equipment['dut1'].send_cmd("getent passwd | grep tester: && userdel tester", @equipment['dut1'].prompt)
    # Create tester user and assign appropriate groups
    check_cmd("useradd -G audio,video,render tester")
    # Set tester password
    @equipment['dut1'].send_cmd("passwd tester", "password:", 2, false)
    @equipment['dut1'].send_cmd("1234", "password:", 2, false)
    @equipment['dut1'].send_cmd("1234", "password updated successfully", 2, false)
    sleep 2
    # Set system prompt
    @equipment['dut1'].prompt = /[\w-]{5,}:.+[#$]/
    # login as tester
    3.times {
      @equipment['dut1'].send_cmd("logout", "login:", 10, false)
      break if !@equipment['dut1'].timeout?
    }
    sleep 10
    3.times {
      @equipment['dut1'].send_cmd("tester", "/Password/i", 5, false)
      @equipment['dut1'].send_cmd("1234", @equipment['dut1'].prompt, 10, false)
      break if !@equipment['dut1'].timeout?
    }
    sleep 5
    @equipment['dut1'].send_cmd("uname", @equipment['dut1'].prompt)
    # Validate use case. User can define cmd, response and timeout under Application parameters to control use case
    response = @test_params.params_control.instance_variable_defined?(:@response) ? @test_params.params_control.response[0] : @equipment['dut1'].prompt
    timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_i : 60
    check_cmd(@test_params.params_control.cmd.join(";"), timeout, response)

    # Set result
    set_result(FrameworkConstants::Result[:pass], "successfully executed use case as non-root user")

  rescue Exception => e
    puts e.message
    puts e.backtrace
    set_result(FrameworkConstants::Result[:fail], "Error trying to run use-case as non-root user.\n#{e.message}")
  end
end