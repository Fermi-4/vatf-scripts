require File.dirname(__FILE__)+'/test_protocols'
require File.dirname(__FILE__)+'/bootup_b2b'

include LspTestScript
def setup
  # boot board to board setup
  bootup_b2b()
end

def run
  # get dut params
  feature = @test_params.params_chan.feature[0]           # feature to load initially
  cmd = @test_params.params_chan.cmd[0]                   # command to enable feature link

  # get bandwidth, time, rx_usecs and adaptive_rx
  vlan = @test_params.params_chan.instance_variable_defined?(:@vlan) ? @test_params.params_chan.vlan[0] : "no"
  id = @test_params.params_chan.instance_variable_defined?(:@id) ? @test_params.params_chan.id[0] : "0"

  # consider dut1 as DAN-X-1 and dut2 as DAN-X-2,
  # X can be P->PRP or H->HSR, Example: DAN-H-1
  dan_X_1 = @equipment['dut1']
  dan_X_2 = @equipment['dut2']

  # get ip addresses for DAN-X-1 and DAN-X-2
  dan_X_1_ip = dan_X_1.params['dut1_if']
  dan_X_2_ip = dan_X_2.params['dut2_if']

  test_comment = ""
  begin
    # get pruicss port information
    pruicss_ports = [dan_X_1.params["#{feature}_port1"], dan_X_1.params["#{feature}_port2"]]
    enable_feature(dan_X_1, feature, cmd, dan_X_1_ip, pruicss_ports)
    enable_feature(dan_X_2, feature, cmd, dan_X_2_ip, pruicss_ports)
    ping_status(dan_X_1, dan_X_2_ip)

    display_stats(dan_X_1, dan_X_2, feature, pruicss_ports[0], vlan, id)
    verify_sv_frames(dan_X_2, pruicss_ports[0], vlan)

    # disable feature
    disable_feature(dan_X_1, feature, pruicss_ports)
    disable_feature(dan_X_2, feature, pruicss_ports)

    test_comment = "#{feature.upcase}: Verified SV frames are transmitted and received using VLAN=#{vlan}"
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{feature.upcase}: #{e}.")
  end
end

# function to verify whether SV frames are vlan tagged with VID,
# PCP and DEI on rx side using tcpdump utility or not
def verify_sv_frames(dan_X_n, pruicss_port, vlan)
  dan_X_n.send_cmd("tcpdump -vv -i #{pruicss_port} -xx > tcpdump.log 2>&1 & sleep 10 ; killall tcpdump", dan_X_n.prompt, 30)
  dan_X_n.send_cmd("cat tcpdump.log", dan_X_n.prompt, 10)
  if (!(dan_X_n.response =~ /ethertype\s802.1Q[\n\s\S]*a00a/) and vlan == "yes") or \
     ((dan_X_n.response =~ /ethertype\s802.1Q[\n\s\S]*a00a/) and vlan == "no")
    raise "Failed to verify SV frame vlan tag, VID, PCP and DEI on rx side"
  end
end

# function to display-verify node table and lre stats
def display_stats(dan_X_1, dan_X_2, feature, pruicss_port, vlan, id)
  dan_X_2.send_cmd("cat /sys/class/net/#{pruicss_port}/address", dan_X_2.prompt, 10)
  dan_X_1.send_cmd("cat /proc/#{feature}#{id}/node-table", dan_X_1.prompt, 10)
  dan_X_2_mac_addr = dan_X_2.response[/\w+:\w+:\w+:\w+:\w+:\w+/]
  if !( dan_X_1.response =~ /#{dan_X_2_mac_addr}/ )
    raise "Node table entry not found"
  end
  dan_X_2.send_cmd("cat /proc/#{feature}#{id}/lre-stats", dan_X_2.prompt, 10)
  dan_X_1.send_cmd("cat /proc/#{feature}#{id}/lre-stats", dan_X_1.prompt, 10)
  dan_X_1.send_cmd("cat /sys/kernel/debug/#{feature}#{id}/lre_info", dan_X_1.prompt, 10)
  dan_X_2.send_cmd("cat /sys/kernel/debug/#{feature}#{id}/lre_info", dan_X_2.prompt, 10)
  # verify VID, PCP and DEI if vlan is set
  if vlan == "yes"
    constraint = "VID\\s:\\s10[\\s\\S\\n]*PCP\\s:\\s5[\\s\\S\\n]*DEI\\s:\\s0"
    if !(dan_X_1.response =~ /#{constraint}/) or !(dan_X_2.response =~ /#{constraint}/)
      raise "Failed to verify SV frame VID, PCP and DEI on tx side"
    end
  end
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
