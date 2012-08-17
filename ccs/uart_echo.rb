require File.dirname(__FILE__)+'/default_mcusdk'

def run
  apps=get_apps_list("UART")
  res_table=create_subtests_results_table
  tests, failures= run_apps(apps, res_table)
  if failures > 0
    set_result(FrameworkConstants::Result[:fail], "#{failures} tests failed out of #{tests} tests.")
  else
    set_result(FrameworkConstants::Result[:pass], "All #{tests} tests Passed.")
  end
end

def run_apps(apps, res_table)
  tests=0
  failures=0
  apps.each {|app|
    puts "Starting test with #{app}"
    result=[]
    tests+=1
    @equipment['dut1'].log_info("\n=============================================================================\nStarting test with: #{app}\n=============================================================================")
    bps,databits,parity,stopbits,flow = File.basename(app).match(/(\d+)_(\d)_(\w)_(\d)_(\w)\./).captures
    # load binary on Target
    thr = load_program(File.join(@apps_dir,app), get_autotest_env('ccsConfig'), 60)
    puts "Waiting for load to complete"
    puts "load program thread returned #{thr.value}"
    # Check that Serial port is working
    @equipment['dut1'].target.platform_info.serial_params = {"baud" => bps.to_i,
                                                             "data_bits" => databits.to_i, 
                                                             "stop_bits" => stopbits.to_i,
                                                             "parity" => translate_parity(parity)}
    begin
      @equipment['dut1'].connect({'type' => 'serial'})
      expect_cmd_echo=get_cmd_echo(bps, databits, parity)
      @equipment['dut1'].send_cmd("hello world at #{bps}", /.*/, 5, true)   
    
      if !@equipment['dut1'].target.serial.timeout? && expect_cmd_echo
        @equipment['dut1'].log_info("RESULT for: #{app}: PASSED")
        result = [app, 'PASSED', 'Text was echoed']

      elsif !expect_cmd_echo
        a=[]
        @equipment['dut1'].response.each_byte {|b| a << b.to_i }
        e= get_expected_bytes(bps, databits, parity)
        if a == e
          @equipment['dut1'].log_info("RESULT for: #{app}: PASSED")
          result = [app, 'PASSED', 'Text was echoed']
        else
          @equipment['dut1'].log_info("RESULT for: #{app}: FAILED")
          result = [app, 'FAILED', 'No text received']
        end
        
      else
        failures+=1
        @equipment['dut1'].log_info("RESULT for: #{app}: FAILED")
        result = [app, 'FAILED', 'No text received']
        
      end
    rescue Exception => e
      @equipment['dut1'].log_info("RESULT for: #{app}: SKIP")
      result = [app, 'SKIP', e.to_s]
    end

    # Disconnect and save sub-test result
    @equipment['dut1'].disconnect('serial')
    # Save subtest result
    add_subtest_result(res_table, result)
  }
  [tests, failures]
end

def load_program(app, config, timeout=100)
  puts "Starting new thread to load #{app}"
  Thread.new() {
    @equipment['dut1'].run app, timeout, {'config' => config}
  }
end
  
def translate_parity(parity)
  return SerialPort::EVEN if parity.upcase == 'E'
  return SerialPort::ODD  if parity.upcase == 'O'
  return SerialPort::MARK if parity.upcase == 'M'
  return SerialPort::SPACE if parity.upcase == 'S'
  return SerialPort::NONE
end

def get_expected_bytes(bps, data_bits, parity)
  test="#{bps}_#{data_bits}_#{parity}"
  case test
  when /115200_8_M/i
    return [104, 89, 139, 189, 32, 215, 75, 177, 100, 144, 88, 23, 41, 138, 213, 50, 152, 76, 225]
  when /115200_8_S/i
    return [104, 101, 90, 170, 5, 209, 173, 73, 172, 100, 144, 97, 186, 40, 145, 81, 181, 50, 152, 49, 10, 255]
  when /115200_5_N/i
    return [168, 109, 237, 172, 43, 234, 189, 229, 177, 108, 161, 161, 22, 165, 86, 166, 179, 46, 137, 179, 250]
  when /115200_6_N/i
    return [104, 85, 46, 125, 144, 175, 73, 92, 42, 82, 45, 87, 164, 174, 164, 82, 33, 72, 133]
  when /9600_8_M/i
    return [104, 89, 139, 189, 32, 215, 75, 177, 100, 144, 88, 23, 41, 178, 193, 48, 133]
  when /9600_8_S/i
    return [104, 101, 90, 170, 5, 209, 173, 73, 172, 100, 144, 97, 186, 40, 145, 86, 176, 48, 133, 255]
  when /9600_5_N/i
    return [168, 109, 237, 172, 43, 234, 189, 229, 177, 108, 161, 161, 22, 165, 151, 19, 51, 46, 225]
  when /9600_6_N/i
    return [104, 85, 46, 125, 144, 175, 73, 92, 42, 82, 45, 87, 164, 47, 9, 66, 41, 255]
  else
    return [] 
  end
end
def get_cmd_echo(bps, data_bits, parity)
  return false if data_bits.to_i < 7 || parity.upcase == 'M' || parity.upcase == 'S'
  return true
end







