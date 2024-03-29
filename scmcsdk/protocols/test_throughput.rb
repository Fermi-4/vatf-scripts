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

  # get bandwidth, time, rx_usecs and adaptive_rx
  bandwidth = @test_params.params_chan.instance_variable_defined?(:@bandwidth) ? @test_params.params_chan.bandwidth : [""]
  time = @test_params.params_chan.instance_variable_defined?(:@time) ? @test_params.params_chan.time : [""]
  rx_usecs = @test_params.params_chan.instance_variable_defined?(:@rx_usecs) ? @test_params.params_chan.rx_usecs[0] : '0'
  adaptive_rx = @test_params.params_chan.instance_variable_defined?(:@adaptive_rx) ? @test_params.params_chan.adaptive_rx[0] : 'off'

  # consider dut1 as DAN-X-1 and dut2 as DAN-X-2,
  # X can be P->PRP or H->HSR, Example: DAN-H-1
  dan_X_1 = @equipment['dut1']
  dan_X_2 = @equipment['dut2']

  # set defaults
  cmd_timeout = 10

  # get ip addresses for DAN-X-1 and DAN-X-2
  dan_X_1_ip = dan_X_1.params['dut1_if']
  dan_X_2_ip = dan_X_2.params['dut2_if']

  test_comment = ""
  begin
    if feature == 'emac'
       # get pru port list
       danx1_port_list  = dan_X_1.params['pru_emac_list']
       danx2_port_list = dan_X_2.params['pru_emac_list']
       for port_index in 0..(danx1_port_list.length - 1)
         setup_port([danx1_port_list, danx2_port_list], [dan_X_1, dan_X_2], [dan_X_1_ip, dan_X_2_ip], port_index)
         test_throughput(dan_X_1, dan_X_2, [[danx1_port_list[port_index]], [danx2_port_list[port_index]]], dan_X_2_ip, bandwidth, time, rx_usecs, adaptive_rx, cmd_timeout, feature)
         port_index += 1
       end
    else
    # get pruicss port information
      pruicss_ports = [dan_X_1.params["#{feature}_port1"], dan_X_1.params["#{feature}_port2"]]
      cmd = get_cmd(feature, pruicss_ports) # get command to enable feature link
      enable_feature(dan_X_1, feature, cmd, dan_X_1_ip, pruicss_ports)
      enable_feature(dan_X_2, feature, cmd, dan_X_2_ip, pruicss_ports)
      ping_status(dan_X_1, dan_X_2_ip)

      test_throughput(dan_X_1, dan_X_2, pruicss_ports, dan_X_2_ip, bandwidth, time, rx_usecs, adaptive_rx, cmd_timeout, feature)

    # disable feature
      disable_feature(dan_X_1, feature, pruicss_ports)
      disable_feature(dan_X_2, feature, pruicss_ports)

      test_comment = "Feature #{feature} verified over interface: #{pruicss_ports}."
    end
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}\n\
 Verified throughput for Bandwidth: #{bandwidth} with respect to Time: #{time}.")
 rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to enable PRU ports
def setup_port(danxn_port_list, dan_X_n, dan_X_n_ips, port_index)
  dut_index = 0
  for dut in dan_X_n
    for port in danxn_port_list[dut_index]
      dut.send_cmd("ifconfig #{port} down", dut.prompt, 10)
    end
    dut.send_cmd("ifconfig #{danxn_port_list[dut_index][port_index]} #{dan_X_n_ips[dut_index]}", dut.prompt, 10)
    dut_index += 1
  end
end


# function to test throughput
def test_throughput(dan_X_1, dan_X_2, pruicss_ports, dan_X_2_ip, bandwidth, time, rx_usecs, adaptive_rx, cmd_timeout, feature)
  feature == 'emac' ? danx1_pruicss_ports = pruicss_ports[0] : danx1_pruicss_ports = pruicss_ports
  feature == 'emac' ? danx2_pruicss_ports = pruicss_ports[1] : danx2_pruicss_ports = pruicss_ports
  #danx1_pruicss_ports = pruicss_ports[0] if feature == 'emac'
  #danx2_pruicss_ports = pruicss_ports[1] if feature == 'emac'
  set_interrupts(dan_X_1, danx1_pruicss_ports, cmd_timeout, feature)
  set_interrupts(dan_X_2, danx2_pruicss_ports, cmd_timeout, feature)
  dan_X_2.send_cmd("echo '******** RX-USECS = 0, ADAPTIVE-RX = off ********' > iperf_response.log 2>&1",\
                    dan_X_2.prompt, cmd_timeout)
  dan_X_2.send_cmd("iperf3 -s -i5 >> iperf_response.log 2>&1 &", dan_X_2.prompt, cmd_timeout)
  test_iperf(dan_X_1, dan_X_2, dan_X_2_ip, bandwidth, time, cmd_timeout)
  set_interrupts(dan_X_1, danx1_pruicss_ports, cmd_timeout, feature, rx_usecs)
  set_interrupts(dan_X_2, danx2_pruicss_ports, cmd_timeout, feature, rx_usecs)
  dan_X_2.send_cmd("echo '******** RX-USECS = #{rx_usecs}, ADAPTIVE-RX = off ********' >> iperf_response.log 2>&1",\
                    dan_X_2.prompt, cmd_timeout)
  test_iperf(dan_X_1, dan_X_2, dan_X_2_ip, bandwidth, time, cmd_timeout)
  set_interrupts(dan_X_2, danx2_pruicss_ports, cmd_timeout, feature, rx_usecs, adaptive_rx)
  dan_X_2.send_cmd("echo '******** RX-USECS = #{rx_usecs}, ADAPTIVE-RX = #{adaptive_rx}  ********' >> iperf_response.log 2>&1",\
                    dan_X_2.prompt, cmd_timeout)
  test_iperf(dan_X_1, dan_X_2, dan_X_2_ip, bandwidth, time, cmd_timeout)
  dan_X_2.send_cmd("killall iperf3", dan_X_2.prompt, cmd_timeout)
  dan_X_2.send_cmd("cat iperf_response.log", dan_X_2.prompt, cmd_timeout)
end

# function to set rx-usecs and adaptive-rx interrupts
def set_interrupts(dan_X_n, pruicss_ports, cmd_timeout, feature, rx_usecs = 0, adaptive_rx = 'off')
    dan_X_n.send_cmd("ethtool -C #{pruicss_ports[0]} rx-usecs #{rx_usecs} adaptive-rx #{adaptive_rx}", dan_X_n.prompt, cmd_timeout)
    dan_X_n.send_cmd("ethtool -c #{pruicss_ports[0]}", dan_X_n.prompt, cmd_timeout)
        if !( dan_X_n.response =~ /Adaptive\sRX.\s#{adaptive_rx}[\n\s\S]*rx-usecs.\s#{rx_usecs}/ )
          raise "Failed to set rx-usecs/adaptive-rx to #{rx_usecs}/#{adaptive_rx} for #{pruicss_ports[0]}."
	end
        if feature != 'emac'
	  dan_X_n.send_cmd("ethtool -c #{pruicss_ports[1]}", dan_X_n.prompt, cmd_timeout)
          if !( dan_X_n.response =~ /Adaptive\sRX.\s#{adaptive_rx}[\n\s\S]*rx-usecs.\s#{rx_usecs}/ )
            raise "Failed to set rx-usecs/adaptive-rx to #{rx_usecs}/#{adaptive_rx} for #{pruicss_ports[1]}."
          end
        end
end

# function to run iperf3 for specified range of bandwidth wrt time
def test_iperf(dan_X_1, dan_X_2, dan_X_n_ip, bandwidth, time, cmd_timeout)
  for index in 0..(bandwidth.length - 1)
    dan_X_2.send_cmd("cat /proc/interrupts >> iperf_response.log 2>&1", dan_X_2.prompt, cmd_timeout) if index == bandwidth.length - 1
    dan_X_1.send_cmd("iperf3 -c #{dan_X_n_ip} -u -b#{bandwidth[index]}M -l96 -t#{time[index]}", dan_X_1.prompt,\
                      (time[index].to_i + 5))
  end
  dan_X_2.send_cmd("cat /proc/interrupts >> iperf_response.log 2>&1", dan_X_2.prompt, cmd_timeout)
  dan_X_1_response = dan_X_1.response
  # verify jitter/lost packet count approx to zero
  if !( dan_X_1_response =~ /\s0.\d+\sms\s+\d+\/\d+\s+.0\.*\d*%.\s+receiver/ )
    raise "Failed to achieve expected throughput <br> #{dan_X_1_response[/(-\s-\s-\s-\s-[\n\s\S]*)iperf\sDone/]}."
  end
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
