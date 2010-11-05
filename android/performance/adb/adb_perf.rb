require File.dirname(__FILE__)+'/../../android_test_module' 

include AndroidTest

def run
  tx_bw =[]
  rx_bw =[]
  i =0 
  file_size = @test_params.params_control.file_size[0]
  iterations = @test_params.params_control.iterations[0].to_i
  
  send_host_cmd "dd if=/dev/urandom of=./adb_test_file bs=1M count=#{file_size}"
  iterations.times do
    data = send_adb_cmd "push ./adb_test_file /system/bin"
    tx_bw << /^(\d+)\s+KB\/s\s+/m.match(data).captures[0].to_i
    puts data
    data = send_adb_cmd "pull /system/bin/adb_test_file ./adb_test_file-rx"
    rx_bw << /^(\d+)\s+KB\/s\s+/.match(data).captures[0].to_i
    puts data
    i = i+1
  end
  
  ensure
    if i < 10
      set_result(FrameworkConstants::Result[:fail], 'ADB performance data could not be calculated, make sure the target is available')
      puts 'Test failed: ADB performance data could not be calculated, make sure the target is available'
    else
      min_bw = @test_params.params_control.min_bw[0].to_f
      if mean(tx_bw) > min_bw && mean(rx_bw) > min_bw
        set_result(FrameworkConstants::Result[:pass], "Mean-TX=#{mean(tx_bw)} Mean-RX=#{mean(rx_bw)}")
        puts "Test Passed: Mean-TX=#{mean(tx_bw)} Mean-RX=#{mean(rx_bw)}"
      else
        set_result(FrameworkConstants::Result[:fail], "Performance is less than #{min_bw} KB/s. Mean-TX=#{mean(tx_bw)} Mean-RX=#{mean(rx_bw)}")
        puts "Test Failed: Performance is less than #{min_bw} KB/s. Mean-TX=#{mean(tx_bw)} Mean-RX=#{mean(rx_bw)}"
      end
    end
end

def clean
  send_host_cmd "rm adb_test_file"
  send_host_cmd "rm adb_test_file-rx"
end

private 
def mean(a)
 a.sum.to_f / a.size
end

