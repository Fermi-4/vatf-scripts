require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def run
  tx_bw =[]
  rx_bw =[]
  i =0 
  file_size = @test_params.params_control.file_size[0].to_i
  file_size = (file_size/2).to_i if @equipment['dut1'].name == 'am57xx-evm'
  iterations = @test_params.params_control.iterations[0].to_i
  
  host_path = File.join(@linux_temp_folder, 'adb_test_file')
  rx_host_path = File.join(@linux_temp_folder, 'adb_test_file-rx')
  dut_path = File.join(@linux_dst_dir, 'adb_test_file')
  send_host_cmd "dd if=/dev/urandom of=#{host_path} bs=1M count=#{file_size}"
  iterations.times do
    data = send_adb_cmd "push #{host_path} #{dut_path}"
    tx, unit = /([\d\.]+)\s+(.)B\/s\s+/m.match(data).captures
    case unit
      when /g/i
        tx = tx.to_f*1024
      when /k/i
        tx = tx.to_f/1024.0
    end
    tx_bw << tx
    data = send_adb_cmd "pull #{dut_path} #{rx_host_path}"
    rx, unit = /([\d\.]+)\s+(.)B\/s\s+/.match(data).captures
    case unit
      when /g/i
        rx = rx.to_f*1024
      when /k/i
        rx = rx.to_f/1024
    end
    rx_bw << rx
    puts data
    i = i+1
  end
  
  ensure
    if i < iterations
      set_result(FrameworkConstants::Result[:fail], 'ADB performance data could not be calculated, make sure the target is available')
      puts 'Test failed: ADB performance data could not be calculated, make sure the target is available'
    else
      perfdata = [{'name'=> "TX_Throughput", 'value' => tx_bw.map{|a| a.to_f}, 'units' => "MB/s"},
                  {'name'=> "RX_Throughput", 'value' => rx_bw.map{|a| a.to_f}, 'units' => "MB/s"}]
      set_result(FrameworkConstants::Result[:pass], 'Passed, performance data collected.', perfdata)
    end
end

