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
  oscope = @equipment['dut1'].params['oscope1']
  add_equipment('oscope1') do |log_path|
    Object.const_get(oscope.driver_class_name).new(oscope,log_path)
  end
end

def run
  # get dut params
  port = @test_params.params_chan.port[0]
  slave_port = @equipment['dut1'].params["#{port}"]
  master_port = @equipment['dut2'].params["#{port}"]
  slave_if = @equipment['dut1'].params['dut1_if']
  master_if = @equipment['dut2'].params['dut2_if']
  egress_lat = @test_params.params_chan.egress_lat[0].to_i
  ingress_lat = @test_params.params_chan.ingress_lat[0].to_i
  pass_crit = @test_params.params_chan.pass_crit[0]
  timeout = @test_params.params_chan.timeout[0].to_i
  enable_pps = @test_params.params_chan.enable_pps[0].to_i
  pps_enable_file = @test_params.params_chan.pps_enable_file[0]
  # Test parameters to enable PPS offset
  enable_pps_offset = @test_params.params_chan.instance_variable_defined?(:@enable_pps_offset)? @test_params.params_chan.enable_pps_offset[0].to_i: 0
  pps_offset_file = @test_params.params_chan.instance_variable_defined?(:@pps_offset_file)? @test_params.params_chan.pps_offset_file[0].to_s : ""
  # pps_offset_value needs to be converted to ns for calculations.
  pps_offset_value = @test_params.params_chan.instance_variable_defined?(:@pps_offset_value)? @test_params.params_chan.pps_offset_value[0].to_i: 0
  # Test parameters to set RX/TX configurable latency. rx_tx_delay value needs to be converted to ns for calculations.
  rx_tx_delay = @test_params.params_chan.instance_variable_defined?(:@rx_tx_delay)? @test_params.params_chan.rx_tx_delay[0].to_i: 0
  # Test parameter timeout is for number of times the oscope measurement should be made.
  timeout = @test_params.params_chan.timeout[0].to_i
  # Test parameter enable_oscope_measurements is to enable oscilloscpe measurements.
  enable_oscope_measurements = @test_params.params_chan.instance_variable_defined?(:@enable_oscope_measurements)? @test_params.params_chan.enable_oscope_measurements[0].to_i: 0
  # Test parameter jitter_spec is for jitter specification. Typical values of
  # clock delay between reference and slave clock are:
  # Ordinary Clock: 50e-9 s, Transparent Clock: 50e-9 s, Boundary Clock: 200e-9 s.
  jitter_spec = @test_params.params_chan.instance_variable_defined?(:@jitter_spec)? @test_params.params_chan.jitter_spec[0].to_f: 0

  # Bench File variable (HW dependent) ref_ch is for reference channel.
  # It is taken from the bench file since input signal connection is hardware specific.
  ref_ch = @equipment['oscope1'].instance_variable_defined?(:@params)?(@equipment['oscope1'].params['ref_ch'].to_i):0
  # Bench File variable (HW dependent) slave_ch is for slave channel.
  # It is taken from the bench file since input signal connection is hardware specific.
  slave_ch = @equipment['oscope1'].instance_variable_defined?(:@params)?(@equipment['oscope1'].params['slave_ch'].to_i):0
  # Variable osc_config_success is the result of sanity check for
  # oscilloscope connection and model number.
  osc_config_success = 0
  test_comment = ""
  begin
    if (enable_pps == 1)
      # Enable 1PPS output and perform SW checks for master (reference) and slave.
      @results_html_file.add_paragraph "============================================"
      @results_html_file.add_paragraph("1PPS Setup Information (Oscilloscope):\nPTP MASTER Board: Oscilloscope ch#{ref_ch}; master_port = #{master_port}; master_if = #{master_if}\nPTP SLAVE Board: Oscilloscope ch#{slave_ch}; slave_port=#{slave_port}; slave_if = #{slave_if}\npps_offset_value= #{pps_offset_value}ns\n rx_tx_delay = #{rx_tx_delay}ns")
      @results_html_file.add_paragraph "============================================"
      @results_html_file.add_paragraph("Result Key: P = Pass, F = Fail, X = Busy\n")
      verify_pps(@equipment['dut1'], slave_port, slave_if, pps_enable_file)
      verify_pps(@equipment['dut2'], master_port, master_if, pps_enable_file)
      if (enable_oscope_measurements == 1)
        # Sanity check oscilloscope connection and basic functionality.
        osc_config_success = @equipment['oscope1'].check_oscope_model()
        # All oscilloscope measurements require enablement of 1PPS.
        if (osc_config_success == 1)
          # Verify 1PPS time period via oscilloscope for master and slave/reference channels.
          if (enable_pps_offset == 1)
            set_pps_offset(@equipment['dut1'], slave_if, pps_offset_value, pps_offset_file)
          end
          verify_hw_1pps(slave_ch,timeout)
          verify_hw_1pps(ref_ch,timeout)
          test_comment = "1 PPS generation verified (via both sw and oscilloscope) and "
          # Verify OC via SW and HW (oscilloscope) measurements per jitter spec and
          # input channels defined in bench file
          if (jitter_spec != 0)
            verify_ptp_oc(@equipment['dut1'], @equipment['dut2'], port, slave_port, slave_if,
                        master_port, master_if, egress_lat, ingress_lat, pass_crit, timeout,
                        enable_oscope_measurements, jitter_spec, ref_ch, slave_ch, pps_offset_value,
                        rx_tx_delay)
            test_comment += "PTP Ordinary Clock on #{port} verified (via both sw and oscilloscope)."
          end
        else
         raise "Oscilloscope configuration failed."
        end
      else
        test_comment = "1 PPS generation verified. "
      end
    else
      verify_ptp_oc(@equipment['dut1'], @equipment['dut2'], port, slave_port, slave_if,
                    master_port, master_if, egress_lat, ingress_lat, pass_crit, timeout)
      test_comment += "PTP Ordinary Clock on #{port} verified."
    end
  set_result(FrameworkConstants::Result[:pass], "Test Passed. #{test_comment}")
  rescue Exception => e
    set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
  end
end

def verify_jitter(cha=1, chb=2, jitter_spec=50e-9, jitter_delay=0, timeout=5)
  # Variable jitter_measurement holds the returned jitter measurement and timestamp values.
  jitter_measurement = Array.new {Array.new}
  # Set minimum jitter initial value to max allowed jitter i.e. jitter_spec+jitter_delay
  min_jitter = jitter_spec+jitter_delay
  # Set max jitter to the min value of jitter
  max_jitter = 0
  avg_jitter = 0
  current_jitter = 0
  # Convert to nanoseconds
  jitter_delay = jitter_delay*1e-9
  # Oscope Resolution is 5ns, Worst case resolution for CPTS clock is 10ns
  clock_resolution = 10e-9
  test_comment = ""
  # Here an error margin is needed. Reasons:
  # 1. CPTS Clock resolution is 10ns and IEP clock resolution is 5ns. This
  # causes an inherent inacurracy when no delay is applied. This needs to be accounted.
  # 2. For PPS offset delay, the delay should match more closely.
  # 3. For configurable RX/TX latency checking, the number setup in config file
  # is compensated in the algorithm but may not result in abslute programmed
  # delay. Further, the customer is advised to use the recommended values from
  # ti.com for the config file. Still, value of testing is twofold:
  #  a. As the algortihm changes over time, the published number may need to be
  # updated. This would get flagged in the nightly regression.
  #  b. We are testing that the value is configurable i.e. can be changed via
  # config file.
  # For the above reasons, an assumption is made that the average delay should
  # be +-20% i.e. at least 0.8x of the programmed delay.
  # Skipping check for the the upper bound, i.e. 1.2x. This upper bound is
  # already being checked by the jitter spec check e.g. +-50ns for OC.
  delay_error_margin = 0.8

  # Reset oscilloscope and take oscilloscope measurements
  @equipment['oscope1'].reset_oscope()
  @results_html_file.add_paragraph "============================================"
  @results_html_file.add_paragraph("Measuring jitter between reference = ch#{cha} and slave = ch#{chb} for #{timeout} seconds.")
  jitter_measurement, oscope_screenshot_file = @equipment['oscope1'].measure_jitter(cha, chb, timeout)
  oscope_screenshot_info = upload_file("#{oscope_screenshot_file}")
  @results_html_file.add_paragraph("JITTER MEASUREMENTS:")
  @results_html_file.add_paragraph("jitter_measurement.png",nil,nil,oscope_screenshot_info[1]) if oscope_screenshot_info

  # Verify that jitter measurements match specification.
  jitter_measurement.each_with_index do |element, time|

    # Find minimum jitter value given configurable delay values (pps_offset and RX/TX latency)
    current_jitter = element[0].abs
    # Ignore busy values
    if (current_jitter != 9.9e+37)
      # calculate minimum jitter
      if ((current_jitter <= min_jitter) && (current_jitter > clock_resolution))
        min_jitter = current_jitter
      end
      # calculate maximum jitter
      if ((current_jitter > max_jitter) && (current_jitter > clock_resolution))
        max_jitter = current_jitter
      end
    end

    # Compare each jitter value with Jitter Spec
    if (element[0].abs <= (jitter_spec+jitter_delay))
      @equipment['server1'].send_cmd("#Jitter #{element[0]}s at #{element[1]}s meets spec #{jitter_spec}s + jitter_delay=#{jitter_delay}.")
      test_comment += "P "
    # 9.9e+37 is the oscilloscope specific busy value
    elsif (element[0] == 9.9e+37)
      @equipment['server1'].send_cmd("#Jitter #{element[0]}s at #{element[1]}s ignored (oscilloscope busy).")
      test_comment += "X "
    else
      @equipment['server1'].send_cmd("#Jitter #{element[0]}s at #{element[1]}s exceeds spec #{jitter_spec}s + jitter_delay= #{jitter_delay}. Test failed.")
      test_comment += "F "
      @results_html_file.add_paragraph("Results: [#{test_comment}]")
      raise "Failed to match criteria: Jitter #{element[0]}s exceeds spec #{jitter_spec}s + jitter_delay= #{jitter_delay}."
    end
  end
  @results_html_file.add_paragraph("Jitter Results: [#{test_comment}]")

  # Assuming jitter is symmetric and centered around 0ns or programmed RX/TX Latency delay or PPS Offset delay.
  avg_jitter = 0.5 * (max_jitter + min_jitter)
  # Compare average jitter to RX/TX and PPS offset
  # Multiply clock delay by factor of 0.8 (error margin as well as compensation for negative jitter)
  # Check: Average delay should be +-20% i.e. at least 0.8x of the programmed delay.
  if (avg_jitter >= (jitter_delay*delay_error_margin))
    @results_html_file.add_paragraph("Delay condition satisfied. Min Jitter = #{min_jitter}; Max Jitter = #{max_jitter}; \nAverage Jitter=#{avg_jitter} > #{(jitter_delay*delay_error_margin)} Jitter Delay with 80% Error Margin.")
  else
    @results_html_file.add_paragraph("Delay condition not satisfied. Min Jitter = #{min_jitter}; Max Jitter = #{max_jitter}; \nAverage Jitter=#{avg_jitter} < #{(jitter_delay*delay_error_margin)} Jitter Delay with 80% Error Margin.")
    raise "Failed to match criteria: Programmed delay (e.g. RX/TX or PPS Offset) not met."
  end
end

def verify_hw_1pps(ch, timeout=5)
  # Variable period_measurement holds the returned period measurement and timestamp values.
  period_measurement = Array.new {Array.new}
  # Variable period_spec is the time period specification, hard coded to 1s here since
  # it is implicit in 1PPS testing.
  period_spec = 1.0
  # Variable error_margin is to account for minor setup (oscope/wires/EVM) variations.
  # Multiplying with period_spec to make it relative.
  error_margin = 1e-2 * period_spec
  test_comment = ""

  # Reset oscilloscope and take oscilloscope measurements
  @equipment['oscope1'].reset_oscope()
  @results_html_file.add_paragraph "============================================"

  @results_html_file.add_paragraph("Measuring 1PPS for channel=ch#{ch} for #{timeout} seconds.")
  period_measurement, oscope_screenshot_file = @equipment['oscope1'].measure_time_period(ch, timeout)
  oscope_screenshot_info = upload_file("#{oscope_screenshot_file}")
  @results_html_file.add_paragraph("1PPS TIME PERIOD MEASUREMENTS FOR CH#{ch}:")
  @results_html_file.add_paragraph("period_measurement_ch#{ch}.png",nil,nil,oscope_screenshot_info[1]) if oscope_screenshot_info
  # Verify that jitter measurements match specification.
  period_measurement.each_with_index do |element, time|
    if (((element[0]) >= (period_spec - error_margin)) and ((element[0]) <= (period_spec + error_margin)))
      @equipment['server1'].send_cmd("#Period #{element[0]}s at #{element[1]}s meets spec #{period_spec}s.")
      test_comment += "P "
    elsif (element[0] == 9.9e+37)
      @equipment['server1'].send_cmd("#Period #{element[0]}s at #{element[1]}s ignored (oscilloscope busy).")
      test_comment += "X "
    else
      @equipment['server1'].send_cmd("#Period #{element[0]}s at #{element[1]}s does not meet spec #{period_spec}s. Test failed")
      test_comment += "F "
      @results_html_file.add_paragraph("Current Results: [#{test_comment}]")
      raise "Failed to match criteria: Period #{element[0]}s exceeds spec #{period_spec}s."
    end
  end
  @results_html_file.add_paragraph("Results: [#{test_comment}]")
end

# function to verify PTP OC
def verify_ptp_oc(dut_slave, dut_master, port, slave_port, slave_if, master_port,
                  master_if, egress_lat, ingress_lat, pass_crit, timeout,
                  enable_oscope_measurements=0, jitter_spec=0, ref_ch=1, slave_ch=2,
                  pps_offset_value=0, rx_tx_delay=0)
  jitter_delay = 0
  dut_slave.send_cmd("ifconfig #{slave_port} up", dut_slave.prompt, 10)
  dut_master.send_cmd("ifconfig #{master_port} up", dut_master.prompt, 10)
  dut_slave.send_cmd("ifconfig #{slave_port} #{slave_if}", dut_slave.prompt, 10)
  dut_master.send_cmd("ifconfig #{master_port} #{master_if}", dut_master.prompt, 10)
  sleep(10)
  ping_status(dut_slave, master_if)
  ping_status(dut_master, slave_if)

  gen_config_file(dut_master, master_port, egress_lat, ingress_lat)
  # Configurable round trip (2x) RX/TX delay via config file i.e. rx_tx_delay
  gen_config_file(dut_slave, slave_port, egress_lat, ingress_lat+(2*rx_tx_delay))
  # run ptp master and slave
  dut_master.send_cmd("ptp4l -2 -P -f oc_eth.cfg -m", "assuming the grand master role", 20)
  if (enable_oscope_measurements==1)
    jitter_delay = pps_offset_value.to_i + rx_tx_delay.to_i
    # If oscilloscope measurements are enabled, launch 2 threads, first for triggering PTP algorithm
    # and second for oscilloscope measurements.
    Thread.abort_on_exception = true
    threads = []
    threads << Thread.new { dut_slave.send_cmd("ptp4l -2 -P -f oc_eth.cfg -s -m & (PID=$! ;sleep #{timeout+20}; kill $PID)", dut_slave.prompt, timeout+30)}
    threads << Thread.new { @equipment['oscope1'].reset_oscope();verify_jitter(ref_ch,slave_ch,jitter_spec,jitter_delay,timeout)}
    threads[0].join
  else
    dut_slave.send_cmd("ptp4l -2 -P -f oc_eth.cfg -s -m & (PID=$! ;\
    sleep #{timeout}; kill $PID)", dut_slave.prompt, (timeout+5))
  end
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
  # File "assert" does not exist for GMAC port: eth1, eth0.
  # Typically eth0 is used for NFS boot and will not be used for PTP connections.
  if ((dut_port != "eth1") && (dut_port != "eth0"))
    dut.send_cmd("cat /sys/class/pps/pps1/assert > pps_timestamp.txt", dut.prompt, 10)
    for i in 0..30
      dut.send_cmd("cat /sys/class/pps/pps1/assert >> pps_timestamp.txt", dut.prompt, 10)
      sleep(0.9)
    end
    dut.send_cmd("cat pps_timestamp.txt; cat pps_timestamp.txt | tr '\\n' ' '", dut.prompt, 10)

    if (!(dut.response =~ Regexp.new("(\\d{9}1.\\d{9}.\\d+\\s\\d{9}2.\\d{9}.\\d+\\s\\d{9}3.\\d{9}.\\d+)")) \
        or dut.timeout?)
      raise "Failed to verify 1 PPS."
    end
  elsif ((dut_port == "eth1")||(dut_port == "eth0"))
    @results_html_file.add_paragraph("Skipping 1PPS SW Check for GMAC port on #{dut_if}.")
  end
end

# Function to set pps offset
def set_pps_offset(dut, dut_if, pps_offset_value, pps_offset_file)
  dut.send_cmd("echo #{pps_offset_value} > #{pps_offset_file}", dut.prompt, 10)
  @results_html_file.add_paragraph("PPS Offset delay Command sent. Set Slave PPS offset = #{pps_offset_value} to file #{pps_offset_file} for #{dut_if}.")
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
