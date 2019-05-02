require File.dirname(__FILE__)+'/test_protocols'
require File.dirname(__FILE__)+'/bootup_b2b'

include LspTestScript
def setup
  # boot board to board setup, pass number of board to setup
  bootup_b2b(@test_params.params_chan.numofboards[0].to_i)
end

def run
  # get dut params
  feature = @test_params.params_chan.feature[0]           # feature to load initially
  cmd = @test_params.params_chan.cmd[0]                   # command to enable feature link
  testtype = @test_params.params_chan.testtype[0]
  m_options = "-m"      # master options
  s_options = "-m -s"   # slave options
  # get config params
  tx_timestamp_timeout = @test_params.params_chan.instance_variable_defined?(:@tx_timestamp_timeout) ? @test_params.params_chan.tx_timestamp_timeout[0].to_i : 20
  priority2            = @test_params.params_chan.instance_variable_defined?(:@priority2) ? @test_params.params_chan.priority2[0].to_i : 128
  redundancy           = @test_params.params_chan.instance_variable_defined?(:@redundancy) ? @test_params.params_chan.redundancy[0].to_i : 1

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

    # initialize 3rd dut incase of Transparent Clock
    if testtype == "Transparent Clock"
      dan_X_3 = @equipment['dut3']
      dan_X_3_ip = dan_X_3.params['dut3_if']
      enable_feature(dan_X_3, feature, cmd, dan_X_3_ip, pruicss_ports)
      ping_status(dan_X_2, dan_X_3_ip)
      test_octc([dan_X_1, dan_X_2, dan_X_3], [m_options, s_options, s_options], feature,
                pruicss_ports, tx_timestamp_timeout, priority2, redundancy)
      disable_feature(dan_X_3, feature, pruicss_ports)
    else
      test_octc([dan_X_1, dan_X_2], [m_options, s_options], feature, pruicss_ports,
                tx_timestamp_timeout, priority2, redundancy)
    end

    # disable feature
    disable_feature(dan_X_1, feature, pruicss_ports)
    disable_feature(dan_X_2, feature, pruicss_ports)

    test_comment = "Verified #{testtype} in #{feature.upcase} mode."
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

# function to test transparent clock and PTP OC
def test_octc(dan_X_ns, options, feature, pruicss_ports, tx_timestamp_timeout, priority2, redundancy)
  (0..(dan_X_ns.length-1)).each do |n|
    dan_X_ns[n].send_cmd("date", dan_X_ns[n].prompt, 10)
    gen_config_file(dan_X_ns[n], feature, pruicss_ports, tx_timestamp_timeout, priority2, redundancy)
    dan_X_ns[n].send_cmd("ptp4l -f #{feature}_octc.cfg #{options[n]} &", dan_X_ns[n].prompt, 10)
    sleep(10)
  end
  verify_clock_time(dan_X_ns)
  (0..(dan_X_ns.length-1)).each do |n|
    dan_X_ns[n].send_cmd("pkill ptp4l", dan_X_ns[n].prompt, 10)
  end
end

# function to generate config file
def gen_config_file(dan_X_n, feature, pruicss_ports, tx_timestamp_timeout, priority2, redundancy, id = "0")
  br = "\"$'\\n'\"" # break line
  dan_X_n.send_cmd("echo \"[global]#{br}sanity_freq_limit 0#{br}"\
                   "step_threshold 0.00002#{br}tx_timestamp_timeout #{tx_timestamp_timeout}#{br}#{br}"\
                   "domainNumber 0#{br}priority1    128#{br}priority2    #{priority2}#{br}"\
                   "slaveOnly    0#{br}#{br}twoStepFlag                  1#{br}summary_interval             0#{br}"\
                   "doubly_attached_clock        1#{br}#{br}[#{feature}#{id}]#{br}redundancy                   #{redundancy}#{br}"\
                   "delay_mechanism              P2P#{br}network_transport            L2#{br}#{br}"\
                   "#{get_config(dan_X_n, feature, pruicss_ports[0], br, tx_timestamp_timeout, priority2, redundancy)}"\
                   "#{br}#{br}#{get_config(dan_X_n, feature, pruicss_ports[1], br, tx_timestamp_timeout, priority2, redundancy, 2)}"\
                   "\" > #{feature}_octc.cfg", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("cat #{feature}_octc.cfg", dan_X_n.prompt, 10)
end

# function to return common configs for eth ports
def get_config(dan_X_n, feature, pruicss_port, br, tx_timestamp_timeout, priority2, redundancy, slave_num = 1, id = 0)
  config = "[#{pruicss_port}]#{br}redundancy                   #{redundancy}#{br}"\
           "redundancy_master_interface  #{feature}#{id}#{br}redundancy_slave_number      #{slave_num}#{br}#{br}"\
           "logAnnounceInterval          0#{br}logSyncInterval              0#{br}"\
           "logMinPdelayReqInterval      0#{br}announceReceiptTimeout       3#{br}"\
           "syncReceiptTimeout           2#{br}#{br}delay_mechanism              P2P#{br}"\
           "network_transport            L2#{br}egressLatency                726#{br}"\
           "ingressLatency               186"
  config += "#{br}fault_reset_interval          0" if feature == 'prp'
  return config
end

# function to verify clocks are synced or not
def verify_clock_time(dan_X_ns)
  (0..(dan_X_ns.length-1)).each do |n|
    dan_X_ns[n].send_cmd("for i in `seq 60`; do sleep 1 && phc_ctl /dev/ptp1 get; done | grep phc > clock_time.log &", dan_X_ns[n].prompt, 10)
  end
  sleep(65)
  dan_X_1_clock_response = (get_clock_time_response(dan_X_ns[0]).partition('clock time is ').last).gsub(/\.\d+/, '.\\d+')[/.*:\d+\s\d+/]
  (1..(dan_X_ns.length-1)).each do |n|
    dan_X_n_clock_response = get_clock_time_response(dan_X_ns[n])
    if !( dan_X_n_clock_response =~ /#{dan_X_1_clock_response}/ )
      raise "Slave #{n} Clock failed to sync with master."
    end
  end
end

# function to get clock time
def get_clock_time_response(dan_X_n)
  dan_X_n.send_cmd("cat clock_time.log", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("cat clock_time.log | grep ':11 ' | tail -1", dan_X_n.prompt, 10)
  return dan_X_n.response
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
  clean_boards('dut3') if testtype == "Transparent Clock"
end
