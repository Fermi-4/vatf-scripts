require File.dirname(__FILE__)+'/default_ccs'

def run
  thr = Thread.new() {
    @equipment['dut1'].run "/home/a0850405local/code/mcu-sdk/fromTod/ndk_evm6748_elf_helloWorld.out",
                           100,
                           {'config' => "/home/a0850405local/ti/CCSTargetConfigurations/c6748wgel.ccxml"}
  }
  sleep 30
  @equipment['server1'].send_cmd("/home/a0850405local/code/mcu-sdk/fromTod/sendOneTcpMessage #{@equipment['dut1'].telnet_ip}",
                                 @equipment['server1'].prompt)
  thr.join
  
  if @equipment['dut1'].target.ccs.response.match(/Test Passed/)
    set_result(FrameworkConstants::Result[:pass], "Test Passed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed")
  end
end