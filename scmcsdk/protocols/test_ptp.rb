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
  enable_pps = @test_params.params_chan.enable_pps[0].to_i
  pps_enable_file = @test_params.params_chan.pps_enable_file[0]

  test_comment = ""
  begin
    if enable_pps == 1
      verify_pps(@equipment['dut1'], slave_port, slave_if, pps_enable_file)
      verify_pps(@equipment['dut2'], master_port, master_if, pps_enable_file)
      test_comment = "1 PPS generation and "
    end
    verify_ptp_oc(@equipment['dut1'], @equipment['dut2'], port, slave_port, slave_if,
      master_port, master_if, egress_lat, ingress_lat, pass_crit, timeout)
    test_comment += "PTP Ordinary Clock on #{port} verified."
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
  # run ptp master and slave
  dut_master.send_cmd("ptp4l -2 -P -f oc_eth.cfg -m", "assuming the grand master role", 20)
  dut_slave.send_cmd("ptp4l -2 -P -f oc_eth.cfg -s -m & (PID=$! ; sleep #{timeout}; kill $PID)",\
                      dut_slave.prompt, (timeout+5))
  dut_master.send_cmd("\cC echo 'Closing Application.'", dut_master.prompt, 20)
  if !(dut_slave.response =~ Regexp.new("(#{pass_crit})")) or dut_slave.timeout?
    raise "Failed to match criteria: #{pass_crit}."
  end
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

# function to verify 1 pulse per second
def verify_pps(dut, dut_port, dut_if, pps_enable_file)
  dut.send_cmd("echo 1 > /sys/kernel/debug/prueth-#{dut_port}/prp_emac_mode", dut.prompt, 10)
  dut.send_cmd("ifconfig #{dut_port} #{dut_if}", dut.prompt, 10)
  dut.send_cmd("echo 1 > #{pps_enable_file}", dut.prompt, 10)
  # redirect pps timestamp to file at 1 sec of interval
  dut.send_cmd("cat /sys/class/pps/pps1/assert > pps_timestamp.txt", dut.prompt, 10)
  for i in 0..30
    dut.send_cmd("cat /sys/class/pps/pps1/assert >> pps_timestamp.txt", dut.prompt, 10)
    sleep(0.9)
  end
  dut.send_cmd("cat pps_timestamp.txt; cat pps_timestamp.txt | tr '\\n' ' '", dut.prompt, 10)
  if !(dut.response =~ Regexp.new("(\\d{9}1.\\d{9}.\\d+\\s\\d{9}2.\\d{9}.\\d+\\s\\d{9}3.\\d{9}.\\d+)"))\
       or dut.timeout?
    raise "Failed to verify 1 PPS."
  end
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
