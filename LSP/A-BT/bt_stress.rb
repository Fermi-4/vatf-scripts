require File.dirname(__FILE__)+'/../TARGET/dev_test2'
# Bench file entry example
#bt = EquipmentInfo.new("bt_device")
#bt.driver_class_name = "EquipmentDriver"
#bt.params={'bt_id'=>"aparnab-desktop-0"}

def setup
  super
end

def run
  run_bt_init_scan_exit_stress
#  run_save_results(true)
end

def run_bt_init_scan_exit_stress
  script_location = @test_params.params_chan.bt_script_location[0]
  @equipment['dut1'].send_cmd("ls #{script_location}")
  raise 'Dut does not have required path or BT scripts in path specified. Please check path specified in test case parameter. ' if !@equipment['dut1'].response.index("BT_Init.sh") || !@equipment['dut1'].response.index("BT_Inquiry.sh") || !@equipment['dut1'].response.index("BT_Exit.sh")
  init_success_string = "Device setup complete"
  exit_success_string = "BT Disable"
  remote_device = @equipment['bt_device1'].params['bt_id']
  init_fail_count = 0
  scan_fail_count = 0
  exit_fail_count = 0
  loop_count = 0
  total_count = @test_params.params_control.iterations[0].to_i
  pass_rate  = @test_params.params_control.pass_rate[0].to_i

  @equipment['dut1'].send_cmd("cd #{script_location}", @equipment['dut1'].prompt, 10)
  # to make sure BT is not running before start of iterations
  @equipment['dut1'].send_cmd("./BT_Exit.sh", @equipment['dut1'].prompt, 15)
  while (loop_count<total_count)
    @equipment['dut1'].send_cmd("./BT_Init.sh", @equipment['dut1'].prompt, 15)
    if @equipment['dut1'].response.index(init_success_string) != nil
      @equipment['dut1'].send_cmd("./BT_Inquiry.sh", @equipment['dut1'].prompt, 60)
      # scan for device list
      puts "REMOTE DEVICE is #{remote_device}\n"
      if @equipment['dut1'].response.index(remote_device) == nil
        scan_fail_count = scan_fail_count + 1
      end
      @equipment['dut1'].send_cmd("./BT_Exit.sh", @equipment['dut1'].prompt, 15)
      if @equipment['dut1'].response.index(exit_success_string) == nil
        exit_fail_count = exit_fail_count + 1
      end                       
    else 
      init_fail_count=init_fail_count+1
    end
    loop_count = loop_count+1
  end
  init_success_rate = (total_count-init_fail_count).to_f/total_count.to_f * 100
  scan_success_rate = (total_count-scan_fail_count).to_f/total_count.to_f * 100
  exit_success_rate = (total_count-exit_fail_count).to_f/total_count.to_f * 100
  puts "RATES are #{init_success_rate}, #{scan_success_rate}, and #{exit_success_rate}\n"
  if (init_success_rate.to_i < pass_rate || scan_success_rate.to_i < pass_rate || exit_success_rate.to_i < pass_rate)
    set_result(FrameworkConstants::Result[:fail], "Init success rate=#{init_success_rate} Scan success rate=#{scan_success_rate} Exit success rate=#{exit_success_rate}")
  else
    set_result(FrameworkConstants::Result[:pass], "Init,Scan, and Exit are 100% successful")
  end
end

def run_determine_test_outcome(return_non_zero)
  perf_data = get_performance_data(File.join(@linux_temp_folder,'test.log'), get_perf_metrics)
  test_type = @test_params.params_control.type[0]
  if test_type.match(/tcp/i)
    perf_data.each{|d|
      sum = 0.0
      d['value'].each {|v| sum += v}
      d['value'] = sum
    }  
  end
  
  if perf_data == nil || perf_data.size == 0
    return [FrameworkConstants::Result[:fail], 
            "Performance data could not be captured \n",
            perf_data]
  else
    return [FrameworkConstants::Result[:pass],
            "Test passed \n",
            perf_data]
  end
end
