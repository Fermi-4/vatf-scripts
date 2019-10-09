require File.dirname(__FILE__)+'/../../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../dlp_sdk/common_functions'

include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  # download and copy Ethercat binaries to evm
  download_package("#{@test_params.params_chan.jailhouse_inmate2[0]}",'/tftpboot/jailhouse_inmates/')
  transfer_to_dut("jailhouse_inmates/ethercat_slave_demo.bin",@equipment['server1'].telnet_ip)

  master_crit = @test_params.params_chan.master_crit[0]    # master criteria
  slave_crit = @test_params.params_chan.slave_crit[0]      # slave criteria

  begin
    enable_jailhouse_etherCAT_Slave()
    verify_etherCAT_Master_Slave(slave_crit, master_crit)
    set_result(FrameworkConstants::Result[:pass], "Test Passed. Verified EtherCAT Master Slave communication.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

def clean
  self.as(LspTestScript).clean
end

# function to enable jailhouse EtherCAT slave
def enable_jailhouse_etherCAT_Slave()
  @equipment['dut1'].send_cmd("modprobe jailhouse", @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("cp ethercat_slave_demo.bin /usr/share/jailhouse/inmates/",\
                             @equipment['dut1'].prompt, 20)
  @equipment['dut1'].send_cmd("jailhouse enable /usr/share/jailhouse/cells/*-evm.cell",\
                              @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("jailhouse cell create /usr/share/jailhouse/cells/*-ethercat.cell",\
                              @equipment['dut1'].prompt, 10)
  @equipment['dut1'].send_cmd("jailhouse cell load 1 /usr/share/jailhouse/inmates/ethercat_slave_demo.bin -a 0x90000000",\
                              @equipment['dut1'].prompt, 10)
end

# function to verify EtherCAT Master Slave communication
def verify_etherCAT_Master_Slave(slave_crit, master_crit)
  @equipment['dut1'].send_cmd("jailhouse cell start 1 &", "Board_setDigOutput - 0x6a", 120)
  dut_log = @equipment['dut1'].response
  if @equipment['dut1'].timeout? or !( dut_log =~ /#{slave_crit}/ )
    raise "Failed start etherCAT slave."
  end
  sleep(10)
  @equipment['server1'].send_sudo_cmd("simple_test eth1", @equipment['server1'].prompt, 120)
  sleep(10)
  server_log = @equipment['server1'].response
  if @equipment['server1'].timeout? or !( server_log =~ /#{master_crit}/ )
    raise "Failed to match etherCAT master constraint: #{master_crit}"
  end
end
