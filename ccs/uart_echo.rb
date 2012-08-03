require File.dirname(__FILE__)+'/default_ccs'

def run
  thr = Thread.new() {
    @equipment['dut1'].run "/mnt/gtautoftp/tmp/carlos/mcu-sdk/TMDXDOCKH52C1_uartecho.out",
                           100,
                           {'config' => "/home/a0850405/ti/CCSTargetConfigurations/MyConcerto.ccxml"}
  }
  sleep 30
  #@equipment['server1'].send_cmd("/home/a0850405local/code/mcu-sdk/fromTod/sendOneTcpMessage #{@equipment['dut1'].telnet_ip}", @equipment['server1'].prompt)

  @equipment['dut1'].connect({'type' => 'serial'})
  @equipment['dut1'].send_cmd("hello world", /.*/, 5)   # By default drivers checks echo of text sent
                                                        # so no need to wait for additional text
  
  if !@equipment['dut1'].target.serial.timeout?
    set_result(FrameworkConstants::Result[:pass], "Test Passed. Text was echoed")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Failed. No text received")
  end
end