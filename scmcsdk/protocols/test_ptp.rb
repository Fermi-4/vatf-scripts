# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../LSP/A-PCI/test_pcie'
require File.dirname(__FILE__)+'/test_protocols'

include LspTestScript
def setup
  # dut2 board setup
  add_equipment('dut2', @equipment['dut1'].params['dut2']) do |e_class, log_path|
    e_class.new(@equipment['dut1'].params['dut2'], log_path)
  end
  @equipment['dut2'].set_api('psp')
  @power_handler.load_power_ports(@equipment['dut2'].power_port)
  # boot 1st EVM
  setup_boards('dut1')
  # boot 2nd EVM
  # check if both dut's not same
  if @equipment['dut1'].name != @equipment['dut2'].name
    params2 = {'platform'=>@equipment['dut2'].name}
    boot_params2 = translate_params2(params2)
    setup_boards('dut2', boot_params2)
  else
    setup_boards('dut2')
  end
end

def run
  # get dut params
  port = @test_params.params_chan.port[0]
  slave_port = @equipment['dut1'].params["#{port}"]
  master_port = @equipment['dut2'].params["#{port}"]
  slave_if = @equipment['dut1'].params['dut1_if']
  master_if = @equipment['dut2'].params['dut2_if']
  egress_lat = @test_params.params_chan.egress_lat[0]
  ingress_lat = @test_params.params_chan.ingress_lat[0]
  pass_crit = @test_params.params_chan.pass_crit[0]
  timeout = @test_params.params_chan.timeout[0].to_i

  test_comment = ""
  begin
    verify_ptp_oc(@equipment['dut1'], @equipment['dut2'], port, slave_port, slave_if,
      master_port, master_if, egress_lat, ingress_lat, pass_crit, timeout)
    test_comment = "PTP Ordinary Clock on #{port} verified."
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to verify PTP OC
def verify_ptp_oc(dut_slave, dut_master, port, slave_port, slave_if, master_port,
                  master_if, egress_lat, ingress_lat, pass_crit, timeout)
  dut_slave.send_cmd("ifconfig #{slave_port} up", dut_slave.prompt, 10)
  dut_master.send_cmd("ifconfig #{master_port} up", dut_master.prompt, 10)
  dut_slave.send_cmd("ifconfig #{slave_port} #{slave_if}", dut_slave.prompt, 10)
  dut_master.send_cmd("ifconfig #{master_port} #{master_if}", dut_master.prompt, 10)
  sleep(10)
  ping_status(dut_slave, master_if)
  ping_status(dut_master, slave_if)
  gen_config_file(dut_master, master_port, egress_lat, ingress_lat)
  gen_config_file(dut_slave, slave_port, egress_lat, ingress_lat)
  # check for PRU_ICSS and if then setup
  if port == "PRU-ICSS"
    setup_pru_icss(dut_master)
    setup_pru_icss(dut_slave)
  end
  # run ptp master and slave
  dut_master.send_cmd("ptp4l -2 -P -f oc_eth.cfg -m", "assuming the grand master role", 20)
  dut_slave.send_cmd("ptp4l -2 -P -f oc_eth.cfg -s -m & (PID=$! ; sleep #{timeout}; kill $PID)",\
                      dut_slave.prompt, (timeout+5))
  dut_master.send_cmd("\cC echo 'Closing Application.'", dut_master.prompt, 20)
  if !(dut_slave.response =~ Regexp.new("(#{pass_crit})")) or dut_slave.timeout?
    raise "Failed to match criteria: #{pass_crit}."
  end
end

# function to setup pru-icss
def setup_pru_icss(dut)
  dut.send_cmd("ifconfig eth2 down", dut.prompt, 10)
  dut.send_cmd("ifconfig eth3 down", dut.prompt, 10)
  dut.send_cmd("ethtool -K eth2 hsr-rx-offload off", dut.prompt, 10)
  dut.send_cmd("ethtool -K eth3 hsr-rx-offload off", dut.prompt, 10)
  dut.send_cmd("ethtool -K eth2 prp-rx-offload on", dut.prompt, 10)
  dut.send_cmd("ethtool -K eth3 prp-rx-offload on", dut.prompt, 10)
  dut.send_cmd("ifconfig eth2 up", dut.prompt, 10)
  dut.send_cmd("ifconfig eth3 up", dut.prompt, 10)
end

# function to generate config file
def gen_config_file(dut, port, egress_lat, ingress_lat)
  dut.send_cmd("echo \"[global]\"$'\\n'\"tx_timestamp_timeout 10\"$'\\n'\""\
               "logMinPdelayReqInterval -3\"$'\\n'\"logSyncInterval -3\"$'\\n'"\
               "\"twoStepFlag 1\"$'\\n'\"summary_interval 0\"$'\\n'\"[#{port}]"\
               "\"$'\\n'\"egressLatency #{egress_lat}\"$'\\n'\"ingressLatency "\
               "#{ingress_lat}\" > oc_eth.cfg", dut.prompt, 10)
  dut.send_cmd("cat oc_eth.cfg", dut.prompt, 10)
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
