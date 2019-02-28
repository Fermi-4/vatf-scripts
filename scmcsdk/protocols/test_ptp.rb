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
  # Value needs to be converted to ns for calculations.
  pps_offset_value = @test_params.params_chan.instance_variable_defined?(:@pps_offset_value)? @test_params.params_chan.pps_offset_value[0].to_i: 0
  # Test parameters to set RX/TX configurable latency. Value needs to be converted to ns for calculations.
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
      verify_pps(@equipment['dut1'], slave_port, slave_if, pps_enable_file)
      verify_pps(@equipment['dut2'], master_port, master_if, pps_enable_file)
      if (enable_oscope_measurements == 1)
        # Sanity check oscilloscope connection and basic functionality.
        osc_config_success = @equipment['oscope1'].check_oscope_model()
        # All oscilloscope measurements require enablement of 1PPS.
        if (osc_config_success == 1)
          # Verify 1PPS time period via oscilloscope for master and slave/reference channels.
          if (enable_pps_offset == 1)
            set_pps_offset(@equipment['dut2'], pps_offset_value, pps_offset_file)
          end
          verify_hw_1pps(slave_ch,timeout)
          verify_hw_1pps(ref_ch,timeout)
          test_comment = "1 PPS generation verified (via both sw and oscilloscope) and "
          # Verify OC via SW and HW (oscilloscope) measurements per jitter spec and
          # input channels defined in bench file
          verify_ptp_oc(@equipment['dut1'], @equipment['dut2'], port, slave_port, slave_if,
                        master_port, master_if, egress_lat, ingress_lat, pass_crit, timeout,
                        enable_oscope_measurements, jitter_spec, ref_ch, slave_ch, pps_offset_value,
                        rx_tx_delay)
          test_comment += "PTP Ordinary Clock on #{port} verified (via both sw and oscilloscope)."
        else
         raise "Oscilloscope configuration failed."
        end
      else
        test_comment = "1 PPS generation and "
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
  # Oscope Resolution is 5ns
  oscope_resolution = 5e-9
  # Reset oscilloscope and take oscilloscope measurements
  @equipment['oscope1'].reset_oscope()
  @results_html_file.add_paragraph "============================================"
  @results_html_file.add_paragraph("Measuring jitter between reference = ch#{cha} and slave = ch#{chb} for #{timeout} seconds.",nil,nil,nil)
  @results_html_file.add_paragraph "============================================"
  jitter_measurement, oscope_screenshot_file = @equipment['oscope1'].measure_jitter(cha, chb, timeout)
  oscope_screenshot_info = upload_file("#{oscope_screenshot_file}")
  @results_html_file.add_paragraph("JITTER PLOT:",nil,nil,nil)
  @results_html_file.add_paragraph("jitter_measurement.png",nil,nil,oscope_screenshot_info[1]) if oscope_screenshot_info
  @results_html_file.add_paragraph("JITTER MEASUREMENTS:",nil,nil,nil)

  # Verify that jitter measurements match specification.
  jitter_measurement.each_with_index do |element, time|

    # Find minimum jitter value given configurable delay values (pps_offset and RX/TX latency)
    current_jitter = element[0].abs
    if ((current_jitter <= min_jitter) && (current_jitter > oscope_resolution))
      min_jitter = current_jitter
    end
    if ((current_jitter > max_jitter) && (current_jitter > oscope_resolution))
      max_jitter = current_jitter
    end

    # Compare with Jitter Spec
    if (element[0].abs <= (jitter_spec+jitter_delay))
      @results_html_file.add_paragraph("Jitter #{element[0]}s at #{element[1]}s meets spec #{jitter_spec}s.",nil,nil,nil)
    # 9.9e+37 is the oscilloscope specific busy value
    elsif (element[0] == 9.9e+37)
      @results_html_file.add_paragraph("Jitter #{element[0]}s at #{element[1]}s ignored (oscilloscope busy).",nil,nil,nil)
    else
      @results_html_file.add_paragraph("Jitter #{element[0]}s at #{element[1]}s exceeds spec #{jitter_spec}s. Test failed",nil,nil,nil)
      raise "Failed to match criteria: Jitter #{element}s exceeds spec #{jitter_spec}s."
    end
  end

  avg_jitter = 0.5 * (max_jitter + min_jitter)
  # Compare to clock delay (RX/TX and PPS offset)
  # Multiplied by factor of 0.7 error margin
  if (avg_jitter >= jitter_delay)
    @results_html_file.add_paragraph("Delay condition satisfied. Average Jitter=#{avg_jitter} > jitter_delay #{jitter_delay}.",nil,nil,nil)
  else
    @results_html_file.add_paragraph("Delay condition not satisfied. Average Jitter=#{avg_jitter} < jitter_delay #{jitter_delay}.",nil,nil,nil)
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

  # Reset oscilloscope and take oscilloscope measurements
  @equipment['oscope1'].reset_oscope()
  @results_html_file.add_paragraph "============================================"

  @results_html_file.add_paragraph("Measuring 1PPS for channel=ch#{ch} for #{timeout} seconds.",nil,nil,nil)
  @results_html_file.add_paragraph "============================================"

  period_measurement, oscope_screenshot_file = @equipment['oscope1'].measure_time_period(ch, timeout)
  oscope_screenshot_info = upload_file("#{oscope_screenshot_file}")
  @results_html_file.add_paragraph("1PPS TIME PERIOD PLOT FOR CH#{ch}:",nil,nil,nil)
  @results_html_file.add_paragraph("period_measurement_ch#{ch}.png",nil,nil,oscope_screenshot_info[1]) if oscope_screenshot_info
  @results_html_file.add_paragraph("1PPS TIME PERIOD MEASUREMENTS FOR CH#{ch}:",nil,nil,nil)
  # Verify that jitter measurements match specification.
  period_measurement.each_with_index do |element, time|
    if (((element[0]) >= (period_spec - error_margin)) and ((element[0]) <= (period_spec + error_margin)))
      @results_html_file.add_paragraph("Period #{element[0]}s at #{element[1]}s meets spec #{period_spec}s.",nil,nil,nil)
    elsif (element[0] == 9.9e+37)
      @results_html_file.add_paragraph("Period #{element[0]}s at #{element[1]}s ignored (oscilloscope busy).",nil,nil,nil)
    else
      @results_html_file.add_paragraph("Period #{element[0]}s at #{element[1]}s exceeds spec #{period_spec}s. Test failed",nil,nil,nil)
      raise "Failed to match criteria: Period #{element}s exceeds spec #{period_spec}s."
    end
  end
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
  #VK Debug: RX TX Latency Issue needs to be fixed.
  gen_config_file(dut_master, master_port, egress_lat, ingress_lat)
  # Configurable round trip (2x) RX/TX delay via config file i.e. rx_tx_delay
  gen_config_file(dut_slave, slave_port, egress_lat, ingress_lat+(2*rx_tx_delay))
  # run ptp master and slave
  dut_master.send_cmd("ptp4l -2 -P -f oc_eth.cfg -m", "assuming the grand master role", 20)
  if (enable_oscope_measurements==1)
    jitter_delay = pps_offset_value.to_i + rx_tx_delay.to_i
    @results_html_file.add_paragraph "============================================"
    @results_html_file.add_paragraph("Jitter Setup Information (Oscilloscope): \n master_if = #{master_if} ; master_channel = #{ref_ch} \n slave_if = #{slave_if}; slave_channel = #{slave_ch} \n pps_offset_value= #{pps_offset_value} \n rx_tx_delay = #{rx_tx_delay} \n total jitter_delay = #{jitter_delay}.",nil,nil,nil)
    @results_html_file.add_paragraph "============================================"
    # If oscilloscope measurements are enabled, launch 2 threads, first for triggering PTP algorithm
    # and second for oscilloscope measurements.
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
  # File assert does not exist for GMAC port: eth1, eth0.
  # Only eth1 excluded here since eth0 is used for NFS boot
  # and will not be used for PTP connections.
  if (dut_port != "eth1")
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
  elsif (dut_port == "eth1")
    @results_html_file.add_paragraph("Skipping 1PPS SW Check for GMAC port on #{dut_if}.",nil,nil,nil)
  end
end

# Function to set pps offset
def set_pps_offset(dut, pps_offset_value, pps_offset_file)
  dut.send_cmd("echo #{pps_offset_value} > #{pps_offset_file}", dut.prompt, 10)
  @results_html_file.add_paragraph("Command sent to set PPS offset = #{pps_offset_value} to file #{pps_offset_file} for #{dut}.",nil,nil,nil)
end

def clean
  self.as(LspTestScript).clean
  clean_boards('dut2')
end
