require File.dirname(__FILE__)+'/test_protocols'
require File.dirname(__FILE__)+'/bootup_b2b'

include LspTestScript
def setup
  # boot board to board setup, pass number of board to setup
  bootup_b2b()
end

def run
  # get dut params
  feature = @test_params.params_chan.feature[0]               # feature to load initially
  forget_time = @test_params.params_chan.forget_time[0].to_i  # node table forget time in seconds

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
    dan_X_1_pruicss_ports = [dan_X_1.params["#{feature}_port1"], dan_X_1.params["#{feature}_port2"]]
    cmd = get_cmd(feature, dan_X_1_pruicss_ports)
    enable_feature(dan_X_1, feature, cmd, dan_X_1_ip, dan_X_1_pruicss_ports)
    dan_X_2_pruicss_ports = [dan_X_2.params["#{feature}_port1"], dan_X_2.params["#{feature}_port2"]]
    cmd = get_cmd(feature, dan_X_2_pruicss_ports)
    enable_feature(dan_X_2, feature, cmd, dan_X_2_ip, dan_X_2_pruicss_ports)

    verify_nt_forget_time(dan_X_1, dan_X_2, feature, dan_X_1_pruicss_ports[0], dan_X_2_ip, forget_time)

    disable_feature(dan_X_1, feature, dan_X_1_pruicss_ports)
    disable_feature(dan_X_2, feature, dan_X_2_pruicss_ports)

    test_comment = "Verified node table forget time in #{feature.upcase} mode"
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to verify node table forget time
def verify_nt_forget_time(dan_X_1, dan_X_2, feature, pruicss_port, dan_X_2_ip, forget_time)
  dan_X_1.send_cmd("cat /sys/kernel/debug/prueth-#{feature}-*/node_table", dan_X_1.prompt, 10)
  dan_X_2.send_cmd("cat /sys/kernel/debug/prueth-#{feature}-*/node_table", dan_X_2.prompt, 10)
  dan_X_1.send_cmd("cat /sys/class/net/#{pruicss_port}/address", dan_X_1.prompt, 10)
  # get dan X 1 mac address
  dan_X_1_mac_addr = dan_X_1.response[/\w+:\w+:\w+:\w+:\w+:\w+/]
  ping_status(dan_X_1, dan_X_2_ip)
  dan_X_1.send_cmd("cat /sys/kernel/debug/prueth-#{feature}-*/node_table", dan_X_1.prompt, 10)
  dan_X_2.send_cmd("cat /sys/kernel/debug/prueth-#{feature}-*/node_table", dan_X_2.prompt, 10)
  if !( dan_X_2.response =~ /#{dan_X_1_mac_addr}/ )
    raise "Node table entry not found."
  end
  sleep(forget_time) #sleep to give time to forget node table entry
  if ( dan_X_2.response =~ /#{dan_X_1_mac_addr}/ )
    raise "Failed to forget node table entry in #{forget_time} seconds."
  end
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
