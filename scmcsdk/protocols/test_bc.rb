require File.dirname(__FILE__)+'/test_protocols'
require File.dirname(__FILE__)+'/bootup_b2b'

include LspTestScript
def setup
  # boot board to board setup, pass number of board to setup
  bootup_b2b(@test_params.params_chan.numofboards[0].to_i)
end

def run
  # get dut params
  bc_ports  = @test_params.params_chan.bc_ports
  ocs_port = @test_params.params_chan.ocs_port
  ocm_port = @test_params.params_chan.ocm_port
  gmc_port  = @test_params.params_chan.gmc_port[0]

  ptp_pass_crit = get_rec_crit(@test_params.params_chan.ptp_pass_crit[0])
  ptp_fail_crit = @test_params.params_chan.ptp_fail_crit[0]
  phc_pass_crit = get_rec_crit(@test_params.params_chan.phc_pass_crit[0])
  phc_fail_crit = @test_params.params_chan.phc_fail_crit[0]

  # consider duts as dan_X_n_bc, dan_X_n_ocs, dan_X_n_ocm
  dan_X_n_bc  = @equipment["dut2"]
  dan_X_n_ocs = @equipment["#{@test_params.params_chan.ocs[0]}"]
  dan_X_n_ocm = @equipment["#{@test_params.params_chan.ocm[0]}"]

  # get ip addresses
  bc_ips  = [dan_X_n_bc.params["#{bc_ports[0]}"], dan_X_n_bc.params["#{bc_ports[1]}"], dan_X_n_bc.params["#{bc_ports[2]}"]]
  ocs_ips = [dan_X_n_ocs.params["#{ocs_port[0]}"]]
  ocm_ips = [dan_X_n_ocm.params["#{ocm_port[0]}"]]

  test_comment = ""
  begin
    # set prp emac mode
    set_prp_emac(dan_X_n_bc)
    set_prp_emac(dan_X_n_ocs)
    set_prp_emac(dan_X_n_ocm)

    # enable ethernet ports
    enable_ports(dan_X_n_bc, bc_ports, bc_ips)
    enable_ports(dan_X_n_ocs, ocs_port, ocs_ips)
    enable_ports(dan_X_n_ocm, ocm_port, ocm_ips)
    sleep(50) # allow ethernet port to up
    ping_status(dan_X_n_bc, ocs_ips[0])
    ping_status(dan_X_n_bc, ocm_ips[0])

    # generate configuration files
    gen_config_files(dan_X_n_bc, dan_X_n_ocs, dan_X_n_ocm, bc_ports, ocs_port, ocm_port)

    phc2sys_cmd = "phc2sys -a -X -g #{gmc_port} -S 0.000002 -L 0 -m"

    # verify boundary clock between GMAC and PRU
    verify_bc(dan_X_n_bc, dan_X_n_ocs, dan_X_n_ocm, phc2sys_cmd, ptp_pass_crit, ptp_fail_crit, phc_pass_crit, phc_fail_crit, gmc_port, ocm_port[0])

    test_comment = "Verified BC between GMAC and PRU."
    set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  ensure
    disable = '0'
    set_prp_emac(dan_X_n_bc, disable)
    set_prp_emac(dan_X_n_ocs, disable)
    set_prp_emac(dan_X_n_ocm, disable)
  end
end

# function to run ptp4l and phc2sys to sync internal clocks on
# GMC DUT and sync clocks with OC Slave and Master DUT
def verify_bc(bc, ocs, ocm, phc2sys_cmd, ptp_pass_crit, ptp_fail_crit, phc_pass_crit, phc_fail_crit, gmc_port, ocm_port)
  bc_cmd  = "ptp4l -f bc.cfg -m"
  ocs_cmd = "ptp4l -2 -P -f oc.cfg -m -s"
  ocm_cmd = "ptp4l -2 -P -f oc.cfg -m"

  bc.send_cmd("ptp4l -f bc.cfg -m 2>&1 | tee ptp4l_bc.txt &", bc.prompt, 10)
  sleep(30)
  bc.send_cmd("#{phc2sys_cmd} 2>&1 | tee phc2sys_bc.txt &", bc.prompt, 10)
  sleep(30)
  ocs.send_cmd("ptp4l -2 -P -f oc.cfg -m -s 2>&1 | tee ptp4l_ocs.txt &", ocs.prompt, 10)
  sleep(30)
  ocm.send_cmd("ptp4l -2 -P -f oc.cfg -m 2>&1 | tee ptp4l_ocm.txt &", ocm.prompt, 10)
  sleep(60)

  (@equipment['dut1'].params['gmac_list'].include? ocm_port) ? verify_clock_time([bc, ocs, ocm], ['0', '1', '0']) : verify_clock_time([bc, ocs, ocm], ['0', '0', '1'])

  stop_process(bc, ["phc2sys", "ptp4l"])
  stop_process(ocs, ["ptp4l"])
  stop_process(ocm, ["ptp4l"])

  bc.send_cmd("cat ptp4l_bc.txt", bc.prompt, 10)
  ocs.send_cmd("cat ptp4l_ocs.txt", ocs.prompt, 10)
  ocm.send_cmd("cat ptp4l_ocm.txt", ocm.prompt, 10)
  bc.send_cmd("cat ptp4l_bc.txt | tail -20", bc.prompt, 10)
  ocs.send_cmd("cat ptp4l_ocs.txt | tail -20", ocs.prompt, 10)
  verify_log("GMC", bc.response, ptp_pass_crit, ptp_fail_crit)
  verify_log("OCS", ocs.response, ptp_pass_crit, ptp_fail_crit)
  bc.send_cmd("cat phc2sys_bc.txt", bc.prompt, 10)
  verify_log("GMC", bc.response, "selecting eth\\d for synchronization")
  verify_log("GMC", bc.response, "selecting eth\\d for synchronization")
  verify_log("GMC", bc.response, "selecting #{gmc_port} as the default clock")
  bc.send_cmd("cat phc2sys_bc.txt | grep ']: eth' | tail -20", bc.prompt, 10)
  verify_log("GMC", bc.response, phc_pass_crit, phc_fail_crit)
end

# function to get multiline criteria
def get_rec_crit(criteria, occurences = 3)
  rec_criteria = "#{criteria}"
  for index in 0..occurences
    rec_criteria += ".*\\n.*" + criteria
  end
  return rec_criteria
end

# function to verify logs based on provided pass/fail criteria
def verify_log(board, log, pass_crit, fail_crit = "")
  raise "#{board}: Failed to match criteria- #{pass_crit}" if !( log =~ /#{pass_crit}/ )
  raise "#{board}: Log contails negative criteria- #{fail_crit}" if ( log =~ /#{fail_crit}/ and fail_crit != "" )
end

# function to kill process
def stop_process(dan_X_n, processes)
  for process in processes
    dan_X_n.send_cmd("pkill #{process}", dan_X_n.prompt, 10)
    sleep(5)
  end
end

# function to enable ethernet port
def enable_ports(dan_X_n, ports, ips)
  for index in 0..(ports.length)
    dan_X_n.send_cmd("ifconfig #{ports[index]} #{ips[index]}", dan_X_n.prompt, 10)
  end
  dan_X_n.send_cmd("ifconfig", dan_X_n.prompt, 10)
end

# function to enable PRP emac mode
def set_prp_emac(dan_X_n, enable='1')
  dan_X_n.send_cmd("echo #{enable} > /sys/devices/platform/pruss2_eth/net/eth2/prp_emac_mode", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("echo #{enable} > /sys/devices/platform/pruss2_eth/net/eth3/prp_emac_mode", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("echo #{enable} > /sys/devices/platform/pruss1_eth/net/eth4/prp_emac_mode", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("echo #{enable} > /sys/devices/platform/pruss1_eth/net/eth5/prp_emac_mode", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("cat /sys/devices/platform/pruss*_eth/net/eth*/prp_emac_mode", dan_X_n.prompt, 10)
  if !( dan_X_n.response =~ /#{enable}/ )
      raise "PRP emac mode: Failed to set #{enable}."
  end
end

# function to generate config files
def gen_config_files(bc, ocs, ocm, bc_ports, ocs_port, ocm_port)
  br = "\"$'\\n'\"" # break line
  common_config = get_common_config(br)
  gen_bc_config(bc, common_config, br, bc_ports)
  gen_oc_config(ocs, common_config, br, ocs_port[0], false)
  gen_oc_config(ocm, common_config, br, ocm_port[0])
end

# function to return common config
def get_common_config(br)
  return "[global]#{br}sanity_freq_limit 0#{br}step_threshold 0.000002#{br}"\
         "tx_timestamp_timeout 10#{br}logMinPdelayReqInterval -3#{br}"\
         "logSyncInterval -3#{br}twoStepFlag 1#{br}summary_interval 0"
end

# function to generate bc config file
def gen_bc_config(dan_X_n, common_config, br, bc_ports)
  dan_X_n.send_cmd("echo \"#{common_config}#{br}#{get_config_per_port(br, bc_ports[0])}"\
                   "#{br}#{get_config_per_port(br, bc_ports[1])}#{br}#{get_config_per_port(br, bc_ports[2])}"\
                   "\" > bc.cfg", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("cat bc.cfg", dan_X_n.prompt, 10)
end

# function to generate oc config file
def gen_oc_config(dan_X_n, common_config, br, port, master = true, egresslat = "726", ingresslat = "186")
  common_config += "#{br}priority2 122" if master
  if @equipment['dut1'].params['gmac_list'].include? port
    egresslat  = "146"
    ingresslat = "346"
  end
  dan_X_n.send_cmd("echo \"#{common_config}#{br}[#{port}]#{br}egressLatency #{egresslat}#{br}"\
                   "ingressLatency #{ingresslat}#{br}\" > oc.cfg", dan_X_n.prompt, 10)
  dan_X_n.send_cmd("cat oc.cfg", dan_X_n.prompt, 10)
end

# function to get config per port
def get_config_per_port(br, port, egresslat = "726", ingresslat = "186")
  if @equipment['dut1'].params['gmac_list'].include? port
    egresslat  = "146"
    ingresslat = "346"
  end
  return "[#{port}]#{br}boundary_clock_jbod 1#{br}egressLatency #{egresslat}#{br}"\
         "ingressLatency #{ingresslat}#{br}delay_mechanism P2P#{br}network_transport L2"
end

# function to verify clocks are synced or not
def verify_clock_time(dan_X_ns, ptpns)
  (0..(dan_X_ns.length-1)).each do |n|
    dan_X_ns[n].send_cmd("for i in `seq 60`; do sleep 1 && phc_ctl /dev/ptp#{ptpns[n]} get; done | grep phc > clock_time.log &", dan_X_ns[n].prompt, 10)
  end
  sleep(65)
  dan_X_1_clock_response = (get_clock_time_response(dan_X_ns[0]).partition('clock time is ').last).gsub(/\.\d+/, '.\\d+')[/.*:\d+\s\d+/]
  (1..(dan_X_ns.length-1)).each do |n|
    dan_X_n_clock_response = get_clock_time_response(dan_X_ns[n])
    if !( dan_X_n_clock_response =~ /#{dan_X_1_clock_response}/ )
      raise "Clocks failed to sync with master."
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
  clean_boards('dut3')
end
