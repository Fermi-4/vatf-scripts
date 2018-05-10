# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../demos/dlp_sdk/common_functions'

include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  timeout = @test_params.params_chan.instance_variable_defined?(:@timeout) ? @test_params.params_chan.timeout[0].to_i : 2500
  setup_wpantund(@test_params.params_chan.wpantund_git[0])
  @equipment['dut1'].send_cmd("rm -r wpantund*", @equipment['dut1'].prompt, 20)
  transfer_to_dut("wpantund.tar.gz", @equipment['server1'].telnet_ip)
  result = build_wpantund(@test_params.params_chan.constraints[0], @test_params.params_chan.constraints[1], \
                          timeout)
  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test Passed. WPANTUND build successfully on target")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed. WPANTUND build failed on target")
  end
end

def clean
  #super
  self.as(LspTestScript).clean
end

def build_wpantund(pass_crit,fail_crit,timeout)
  @equipment['dut1'].send_cmd("tar xzvf wpantund.tar.gz", @equipment['dut1'].prompt, 300)
  @equipment['dut1'].send_cmd("cd wpantund", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("date -s '#{Time.now.getutc.strftime("%Y-%m-%d %H:%M:%S")}'", \
                               @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("find . -exec touch {} \\;", @equipment['dut1'].prompt, 30)
  @equipment['dut1'].send_cmd("echo \"Running ./configure\" && ./configure && echo \"Running make\" \
                               && make && echo \"Running make install\" && make install",@equipment['dut1'].prompt, \
                               timeout)
  dut_log = @equipment['dut1'].response
  if @equipment['dut1'].timeout? or !(dut_log =~ /(#{pass_crit})/) or (dut_log =~ /(#{fail_crit})/)
    return 1
  else
    return 0
  end
end

def setup_wpantund(wpantund_git)
  @equipment['server1'].send_sudo_cmd("rm -r /tftpboot/wpantund*", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("git clone #{wpantund_git} /tftpboot/wpantund", \
                                  @equipment['server1'].prompt, 60)
  @equipment['server1'].send_cmd("cd /tftpboot/wpantund; git checkout full/latest-release", \
                                  @equipment['server1'].prompt, 30)
  @equipment['server1'].send_cmd("cd /tftpboot; tar -cvzf wpantund.tar.gz wpantund", \
                                  @equipment['server1'].prompt, 60)
  @equipment['server1'].send_sudo_cmd("chmod 777 /tftpboot/wpantund.tar.gz", \
                                       @equipment['server1'].prompt, 20)
  @equipment['server1'].send_sudo_cmd("chown nobody /tftpboot/wpantund.tar.gz", \
                                       @equipment['server1'].prompt, 20)
end
