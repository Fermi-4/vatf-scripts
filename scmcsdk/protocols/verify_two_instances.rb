require File.dirname(__FILE__)+'/test_protocols'
require File.dirname(__FILE__)+'/bootup_b2b'

include LspTestScript
def setup
  # boot board to board setup, pass number of board to setup
  bootup_b2b(3)
end

def run
  # get dut params
  feature_pru1 = @test_params.params_chan.feature_pru1[0]           # feature to load initially
  cmd_pru1     = @test_params.params_chan.cmd_pru1[0]               # command to enable feature link
  feature_pru2 = @test_params.params_chan.feature_pru2[0]           # feature to load initially
  cmd_pru2     = @test_params.params_chan.cmd_pru2[0]               # command to enable feature link

  # consider dut1 as DAN-X-1 and dut2 as DAN-X-2,
  # X can be P->PRP or H->HSR, Example: DAN-H-1
  dan_X_1 = @equipment['dut1']
  dan_X_2 = @equipment['dut2']
  dan_X_3 = @equipment['dut3']

  # get ip addresses for DAN-X-n
  dan_X_1_ip  = dan_X_1.params['dut1_if']
  dan_X_2_ip  = dan_X_2.params['dut2_if2']
  dan_X_3_ips = [dan_X_3.params['dut3_if'], dan_X_3.params['dut3_if2']]

  test_comment = ""
  begin
    # get pruicss port information
    pruicss1_ports = dan_X_1.params["pru_icss1"]
    pruicss2_ports = dan_X_1.params["pru_icss2"]

    # enable feature
    enable_feature(dan_X_1, feature_pru1, cmd_pru1, dan_X_1_ip, pruicss1_ports)
    enable_feature(dan_X_2, feature_pru2, cmd_pru2, dan_X_2_ip, pruicss2_ports, false, 1)
    enable_feature(dan_X_3, feature_pru1, cmd_pru1, dan_X_3_ips[0], pruicss1_ports)
    enable_feature(dan_X_3, feature_pru2, cmd_pru2, dan_X_3_ips[1], pruicss2_ports, false, 1)
    # verify ping
    ping_status(dan_X_3, dan_X_1_ip)
    ping_status(dan_X_3, dan_X_2_ip)
    # test iperf between all 3 duts
    test_iperf(dan_X_3, dan_X_1, dan_X_3_ips[0], "10000")
    test_iperf(dan_X_3, dan_X_2, dan_X_3_ips[1], "20000")
    # verify node entry using snmpwalk
    verify_snmpwalk(dan_X_1, dan_X_3_ips[0], "#{feature_pru1}0", "#{feature_pru2}1")
    verify_snmpwalk(dan_X_2, dan_X_3_ips[1], "#{feature_pru1}0", "#{feature_pru2}1")

    # delete links
    delete_link(dan_X_1, "#{feature_pru1}0")
    delete_link(dan_X_2, "#{feature_pru2}1")
    delete_link(dan_X_3, "#{feature_pru1}0")
    delete_link(dan_X_3, "#{feature_pru2}1")

    test_comment = "Verified two instances as PRU_ICSS1-#{feature_pru1} & PRU_ICSS2-#{feature_pru2}."
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}.")
  end
end

# function to run iperf to verify jitter/lost
def test_iperf(iperf_server, iperf_client, iperf_server_ip, port)
  iperf_server.send_cmd("iperf -s -u -p#{port} > iperf_response.log 2>&1 &", iperf_server.prompt, 60)
  iperf_client.send_cmd("iperf -c #{iperf_server_ip} -u -b40M -l1472 -p#{port}", iperf_client.prompt, 60)
  iperf_server.send_cmd("killall iperf", iperf_server.prompt, 10)
  iperf_server.send_cmd("cat iperf_response.log", iperf_server.prompt, 10)
  iperf_client_response = iperf_client.response
  # verify jitter/lost packet count approx to zero
  if !( iperf_client_response =~ /sec\s*\d*.\d*\s*MBytes\s*\d*.\d*\s*Mbits\/sec\s*\d*.\d*\s*ms\s*0\/\d*\s*\(0%\)/ )
    raise "IPERF: packet loss/jitter observed: "\
          "#{iperf_client_response[/sec\s*\d*.\d*\s*MBytes\s*\d*.\d*\s*Mbits\/sec\s*\d*.\d*\s*ms\s*0\/\d*\s*\(0%\)/]}."
  end
end

# function to verify node entry using snmpwalk utility
def verify_snmpwalk(dan_X_n, dan_X_3_ip, feature_pru1, feature_pru2)
  dan_X_n.send_cmd("snmpwalk -v 2c -c public #{dan_X_3_ip} IEC-62439-3-MIB::iec62439", dan_X_n.prompt, 30)
  if !( dan_X_n.response =~ /lreNodeName.\d\s=\sSTRING:\s#{feature_pru1}/ )
    raise "SNMPWALK: Missing node entry for #{feature_pru1}"
  end
  if !( dan_X_n.response =~ /lreNodeName.\d\s=\sSTRING:\s#{feature_pru2}/ )
    raise "SNMPWALK: Missing node entry for #{feature_pru2}"
  end
end

# function to delete links
def delete_link(dan_X_n, feature)
  dan_X_n.send_cmd("ip link delete #{feature}", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("ifconfig", dan_X_n.prompt, 10)
  if (dan_X_n.response =~ Regexp.new("(#{feature}\s+Link\sencap:Ethernet\s+HWaddr)"))
    raise "Failed to delete link #{feature}"
  end
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
  clean_boards('dut3')
end
