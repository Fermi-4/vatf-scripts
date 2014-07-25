# This script is intended to be generic enough to test any timestamping application
# Inputs to the script are the logfile with timestamps, resolution of offset error the user wants to report,
# timestamping interval and regular expression to find timestamps in the logfile
# The script will report offset errors (difference between observed and expected timestamps) if they are larger
# than resolution value. This will catch clock roll over, if logfile has sufficient timestamp values.
# The script will also report if clock drift is observed.
#
# Assumes timestamping test binary is in /usr/bin directory on DUT. Assumes timestamping app is in /usr/bin of Linux PC 
# for rx case 

require File.dirname(__FILE__)+'/../TARGET/dev_test2'

def setup
  super
  @dir = @test_params.params_control.test_type[0].to_s
  @offset_res = @test_params.params_control.instance_variable_defined?(:@offset_resolution) ? @test_params.params_control.offset_resolution[0].to_f : 0.001
  @timestamping_interval = @test_params.params_control.instance_variable_defined?(:@interval) ? @test_params.params_control.interval[0].to_f : 5
  @timestamp_regex = @test_params.params_control.instance_variable_defined?(:@timestamp_regex) ? @test_params.params_control.timestamp_regex[0].to_s : 'HW\sraw\s(\d+\.\d+)'
  @incorrect_offset_detected = 0
  @timeout = @test_params.params_control.instance_variable_defined?(:@timeout) ? @test_params.params_control.timeout[0].to_f : 300
  @iface = @test_params.params_control.instance_variable_defined?(:@iface) ? @test_params.params_control.iface[0].to_s : 'eth0'
  @drift = 0
  if (@dir == "rx")
    server_iface = get_local_iface_name(@equipment['server1'],get_ip_addr('dut1',@iface))
    kill_process(@equipment['server1'],'timestamping')
    @equipment['server1'].send_sudo_cmd_nonblock("timestamping #{server_iface} SOF_TIMESTAMPING_TX_SOFTWARE SOF_TIMESTAMPING_SOFTWARE",/.*/,@timeout)  
    if (process_running?(@equipment['server1'],'timestamping'))
      #do nothing
    else
      raise "Could not start timestamping on Linux PC. Please check if timestamping is installed"
    end
  end
  end

# Determine test result outcome and save performance data
def run_determine_test_outcome(return_non_zero)
  test_result_comment = check_timestamps(File.join(@linux_temp_folder,'test.log'),@timestamp_regex)
  test_outcome = FrameworkConstants::Result[:fail]
  
  if @incorrect_offset_detected > 5
  # Fail test only if 5 or more incorrect offset readings
  elsif @drift > 0
  # failtest
  else
    test_outcome = FrameworkConstants::Result[:pass]
  end
  return [test_outcome,
            test_result_comment
            ]
end

def check_timestamps(logs, regex)
    data = logs
    diff_arr = []
    ref_arr = []
    obs_arr = []
    start_index = 0
    if File.file? logs
      data = File.new(logs,'r').read
    end
    
    # Read observed timestamps
    expect_regex = Regexp.new(@timestamp_regex.gsub(/^\'/,'').gsub(/\'$/,''))
    puts expect_regex
    data.scan(expect_regex) { |vals|
      obs_arr << vals[0].to_f
    }

    # ignore first five entries
    5.times do 
      obs_arr.delete_at(0)
    end
    puts "obs_arr: #{obs_arr}"
    #Create array of reference (expected) timestamps
    ref_arr << obs_arr[0]
    for i in (1..(obs_arr.length - 1)) do
      ref_arr[i] =  ref_arr[i-1] + @timestamping_interval
    end
    puts "ref_arr: #{ref_arr}"
    
    #Now check offsets between expected value and measured value
    for i in (1..(obs_arr.length - 1)) do
      diff_arr << (ref_arr[i] - obs_arr[i]).abs
      if diff_arr[-1] > @offset_res
        puts "Offset difference greater that #{@offset_res} seconds detected"
        @incorrect_offset_detected =  @incorrect_offset_detected + 1
      end
    end
    puts "unsorted #{diff_arr}"

    for i in (-1).downto(-(diff_arr.length-1))
    puts "comparing #{diff_arr[i]} and #{diff_arr[i-1]}"
      if diff_arr[i] > diff_arr[i-1]        
        puts "drift detected at index #{i-1}"
        start_index = i-1
      else
        break
      end
    end 
    # report drift only if observed in last 5 readings or more
    if start_index != nil && start_index < -5
      @drift = 1
      puts "drift observed from #{diff_arr.length+start_index} reading. Total readings #{diff_arr.length}"
    end
    puts "********************"
    puts "Total readings #{diff_arr.length}"
    puts "Timestamp interval #{@timestamping_interval}"
    puts "Offset resolution used is #{@offset_res}"
    puts "@incorrect_offset_detected in #{@incorrect_offset_detected} readings."
    puts "@drift #{@drift}."
    puts "********************"
    test_result_comment = " \n
    ********************
     Total readings #{diff_arr.length} \n
     Timestamp interval #{@timestamping_interval} \n
     Offset resolution used is #{@offset_res} \n
     @incorrect_offset_detected in #{@incorrect_offset_detected} readings.
     @drift #{@drift}. \n
     drift observed from #{diff_arr.length+start_index} reading. Total readings #{diff_arr.length} \n
     ******************** \n
    "
end

def clean
  super
  if (@dir == "rx")
    kill_process(@equipment['server1'],'timestamping')
  end
end

