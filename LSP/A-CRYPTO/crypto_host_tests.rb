# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
  self.as(LspTestScript).setup
end

def run
  # Preserve current governor
  prev_gov = create_save_cpufreq_governors
  #Change to performance governor
  enable_cpufreq_governor
  # Run the test
  crypto_test
  # Restore previous governor
  restore_cpufreq_governors(prev_gov)
end

def crypto_test
	runltp_fail = false
	dut_timeout = @test_params.params_control.instance_variable_defined?(:@dut_timeout) ? @test_params.params_control.dut_timeout[0].to_i : 600
        if (@test_params.params_control.type[0].match('openssl_hw'))
          @equipment['dut1'].send_cmd("ls /dev|grep crypto",@equipment['dut1'].prompt, 10)
          crypto_device = @equipment['dut1'].response.lines.to_a[1..-1].join.strip
          puts "CRYPTO_DEVICE is #{crypto_device}\n"
          if (crypto_device.match(/crypto/) == nil)
            puts "CRYPTO device is not present and hence not hardware accelerated\n"
            set_result(FrameworkConstants::Result[:fail], "Test Failed since hardware crypto device was not found. Verify that cryptodev module is built and inserted before re-running this test.")
            return
          end
        elsif (@test_params.params_control.type[0].match('openssl_sw'))
          @equipment['dut1'].send_cmd("ls /dev|grep crypto",@equipment['dut1'].prompt, 10)
          @equipment['dut1'].send_cmd("modprobe -r cryptodev",@equipment['dut1'].prompt,10)
          @equipment['dut1'].send_cmd("lsmod|grep cryptodev",@equipment['dut1'].prompt,10)
          lsmod_response = @equipment['dut1'].response.lines.to_a[1..-1].join.strip
          if (lsmod_response.match(/cryptodev/) != nil)
            puts "CRYPTODEV module could not be removed and hence not software mode\n"
            set_result(FrameworkConstants::Result[:fail], "Test Failed since cryptodev module could not be removed to test software-only mode. Verify why the cryptodev module could not be removed by the modprobe -r command.")
            return
          end
        end
	runtest_cmd = @test_params.params_control.script.join(";")
	cmd = eval(('"'+runtest_cmd.gsub("\\","\\\\\\\\").gsub('"','\\"')+'"')+"\n")
	@equipment['dut1'].send_cmd(cmd, @equipment['dut1'].prompt, dut_timeout)
        response = @equipment['dut1'].response
        if @equipment['dut1'].timeout?
           puts "Test Fail"
           set_result(FrameworkConstants::Result[:fail], "Test Failed.")
        else
           if (@test_params.params_control.type[0].match('openssl'))
             perf_data = run_openssl_performance(response)
           else
             perf_data = run_crypto_performance(response)
           end
           if (perf_data.length == 0)
             set_result(FrameworkConstants::Result[:fail], "No performance data was collected. Check logs.")
           else
             set_result(FrameworkConstants::Result[:pass], "Test Passed.", perf_data)
           end
        end
end
 
def run_crypto_performance(log)
    perf_data = []
    variable_name=''
    log.each_line { |line|
         # start of log
         m1 = /testing speed of /.match(line)
         if (m1 != nil)
           variable_name = line.split('testing speed of ')[1].gsub(' ','_').strip
           variable_name = variable_name.gsub('encryption','enc')
           variable_name = variable_name.gsub('decryption','dec')
           next
         end
         # aes and des regexp
         # $1 is id, $2 is bitkey, $3 is byteblocks, $4 is operations, $5 is time and $6 is bytes
         m2 = /test\s(\d*)\s\((\d*)\sbit\skey,\s(\d*)\sbyte\sblocks\):\s*(\d*)\soperations\s*in\s*(\d*)\sseconds\s\((\d*)\s*bytes\)/.match(line)
         puts "M2 is #{m2}\n"
         if (m2 != nil) 
             testid=$1
             time=$5
             bytes=$6
             rate=bytes.to_f/time.to_f
             perf_data << {'name' => "#{variable_name}_id_#{testid}", 'value' => rate, 'units' => "Bytes/s"}
             next
          end
         # md5, sha regexp
         # $1 is id, $2 is byteblocks, $3 is bytesperupdate, $4 is numofupdates, $5 is opers/sec and $6 is bytes/sec
         m3 = /test\s*(\d*)\s*\(\s*(\d*)\s*byte\sblocks,\s*(\d*)\s*bytes\s*per\s*update,\s*(\d*)\s*updates\s*\):\s*(\d*)\s*opers\/sec,\s*(\d*)\s*bytes\/sec/.match(line)
        if (m3 != nil)
          testid = $1
          rate = $6
          perf_data << {'name' => "#{variable_name}_id_#{testid}", 'value' => rate, 'units' => "Bytes/s"}
          next
        end
}
    return perf_data
end

# Parsing of openssl performance test log
def run_openssl_performance(log)
    perf_data = []
    variable_name=''
    algo_name = ''
    log.each_line { |line|
         # start of log
         m = /Running\s*(\S*)\s*test/.match(line)
         if (m != nil)
           algo_name = $1
           next
         end
         m = /Doing.*for.*(\d+)s.*\s+(\d+).*size\s+blocks\s*:\s*(\d+).*/.match(line)
         if (m != nil) 
             time=$1
             block_size=$2
             throughput=$3.to_f/time.to_f
             perf_data << {'name' => "#{algo_name}_throughput_#{block_size}_bytes", 'value' => throughput, 'units' => "KBytes/s"}
             next
          end
          m = /User.*time.*:\s*(\S+)/.match(line)
          if (m != nil)
           #user_time = $1
           perf_data << {'name' => "#{algo_name}_user_time", 'value' => $1, 'units' => "s"}
           next
          end
          m = /System.*time.*:\s*(\S+)/.match(line)
          if (m != nil)
           perf_data << {'name' => "#{algo_name}_system_time", 'value' => $1, 'units' => "s"}
           next
          end
          m = /Percent\s*of\s*CPU.*:\s*(\d+)%/.match(line)
          if (m != nil)
           perf_data << {'name' => "#{algo_name}_cpu_util", 'value' => $1, 'units' => "%"}
           next
          end
}
    return perf_data
end