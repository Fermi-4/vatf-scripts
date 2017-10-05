# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../demos/dlp_sdk/common_functions'

include LspTestScript
def setup
  #super
  self.as(LspTestScript).setup
end

def run
  setup_iot_gw(@test_params.params_chan.iot_gw_git[0])
  @equipment['dut1'].send_cmd("rm -r tidep0084*", @equipment['dut1'].prompt, 20)
  transfer_to_dut("iot_gw/tidep0084.tar.gz", @equipment['server1'].telnet_ip)
  result = build_iot_gw(@test_params.params_chan.constraints[0], @test_params.params_chan.constraints[1])
  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test Passed. IOT Gateway successfully connected to AWS")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed. IOT Gateway did not connect to AWS")
  end
end

def clean
  #super
  self.as(LspTestScript).clean
end

def build_iot_gw(pass_crit,fail_crit)
  @equipment['dut1'].send_cmd("tar xzvf tidep0084.tar.gz", @equipment['dut1'].prompt, 300)
  @equipment['dut1'].send_cmd("mv tidep0084/hosts /etc/hosts", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cd tidep0084/prebuilt/", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("chmod +x bin/bbb_collector", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("bash run_demo.sh > log.txt", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("sleep 15", @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("cat log.txt", @equipment['dut1'].prompt, 10)
  dut_log = @equipment['dut1'].response
  @equipment['dut1'].send_cmd("kill $(ps aux | grep '[n]ode' | awk '{print $2}')", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("kill $(ps aux | grep '[c]ollector' | awk '{print $2}')", @equipment['dut1'].prompt, 10)
  if @equipment['dut1'].timeout? or !(dut_log =~ /(#{pass_crit})/) or (dut_log =~ /(#{fail_crit})/)
    return 1
  else
    return 0
  end
end

def setup_iot_gw(iot_gw_git)
  @equipment['server1'].send_sudo_cmd("rm -r /tftpboot/iot_gw/tidep0084*", @equipment['server1'].prompt, 10)
  @equipment['server1'].send_cmd("git clone #{iot_gw_git} /tftpboot/iot_gw/tidep0084", \
                                  @equipment['server1'].prompt, 60)
  @equipment['server1'].send_cmd("cp /tftpboot/iot_gw/awsConfig.json /tftpboot/iot_gw/tidep0084/prebuilt/iot-gateway/cloudAdapter/", @equipment['server1'].prompt, 60)
  @equipment['server1'].send_cmd("cp /tftpboot/iot_gw/certs/* /tftpboot/iot_gw/tidep0084/prebuilt/iot-gateway/cloudAdapter/certs/", @equipment['server1'].prompt, 60)
  @equipment['server1'].send_cmd("cp /tftpboot/iot_gw/hosts /tftpboot/iot_gw/tidep0084/", @equipment['server1'].prompt, 60)
  @equipment['server1'].send_cmd("cd /tftpboot/iot_gw; tar -cvzf tidep0084.tar.gz tidep0084", \
                                  @equipment['server1'].prompt, 60)
end