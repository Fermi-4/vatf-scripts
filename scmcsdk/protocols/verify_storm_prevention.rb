require File.dirname(__FILE__)+'/test_protocols'
require File.dirname(__FILE__)+'/bootup_b2b'
require File.dirname(__FILE__)+'/../common_utils/common_functions'

include LspTestScript
def setup
  # boot board to board setup, pass number of board to setup
  bootup_b2b()
end

def run
  # get dut params
  feature = @test_params.params_chan.feature[0]               # feature to load initially
  cmd = @test_params.params_chan.cmd[0]                       # command to enable feature link

  # consider dut1 as DAN-X-1 and dut2 as DAN-X-2,
  # X can be P->PRP or H->HSR, Example: DAN-H-1
  dan_X_1 = @equipment['dut1']
  dan_X_2 = @equipment['dut2']

  # get ip addresses for DAN-X-1 and DAN-X-2
  dan_X_1_ip   = dan_X_1.params['dut1_if']
  dan_X_2_ip   = dan_X_2.params['dut2_if']
  storm_pcap   = dan_X_1.params['storm_pcap']
  download_loc = '/tftpboot/'

  test_comment = ""
  begin
    # get pruicss port information
    pruicss_ports = [dan_X_1.params["#{feature}_port1"], dan_X_1.params["#{feature}_port2"]]
    enable_feature(dan_X_1, feature, cmd, dan_X_1_ip, pruicss_ports)
    enable_feature(dan_X_2, feature, cmd, dan_X_2_ip, pruicss_ports)
    ping_status(dan_X_1, dan_X_2_ip)
    download_package(storm_pcap, download_loc)

    verify_storm_prevention(dan_X_1, pruicss_ports[0], "#{download_loc}#{storm_pcap.split('/')[-1]}")

    disable_feature(dan_X_1, feature, pruicss_ports)
    disable_feature(dan_X_2, feature, pruicss_ports)

    test_comment = "Verified storm prevention in #{feature.upcase} mode"
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}.")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}.")
  end
end

# function to verify storm prevention
def verify_storm_prevention(dan_X_1, pruicss_port, storm_pcap_loc)
  dan_X_1.send_cmd("echo 0 > /sys/devices/platform/pruss*_eth/net/#{pruicss_port}/nsp_credit", dan_X_1.prompt, 10)
  dan_X_1.send_cmd("cat /sys/devices/platform/pruss*_eth/net/#{pruicss_port}/nsp_credit", dan_X_1.prompt, 10)
  # play broadcast pcap file
  @equipment['server1'].send_sudo_cmd("sudo tcpreplay -i eth1 #{storm_pcap_loc}", @equipment['server1'].prompt, 60)
  dan_X_1.send_cmd("ifconfig #{pruicss_port}", dan_X_1.prompt, 10)
  dan_X_1.send_cmd("ethtool -S #{pruicss_port}", dan_X_1.prompt, 10)
  # verify that storm prev counter is set to zero or unchanged
  if !( dan_X_1.response =~ /stormPrevCounter:\s0/ )
    raise "Storm Prevention Counter updated unexpectedly at #{pruicss_port}"
  end
  # enable broadcast network storm prevention
  dan_X_1.send_cmd("echo 1 > /sys/devices/platform/pruss*_eth/net/#{pruicss_port}/nsp_credit", dan_X_1.prompt, 10)
  dan_X_1.send_cmd("cat /sys/devices/platform/pruss*_eth/net/#{pruicss_port}/nsp_credit", dan_X_1.prompt, 10)
  # play broadcast pcap file
  @equipment['server1'].send_sudo_cmd("sudo tcpreplay -i eth1 #{storm_pcap_loc}", @equipment['server1'].prompt, 60)
  dan_X_1.send_cmd("ifconfig #{pruicss_port}", dan_X_1.prompt, 10)
  dan_X_1.send_cmd("ethtool -S #{pruicss_port}", dan_X_1.prompt, 10)
  # verify that storm prev counter updated
  if !( dan_X_1.response =~ /stormPrevCounter:\s8/ )
    raise "Storm Prevention Counter update failed at #{pruicss_port}"
  end
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
