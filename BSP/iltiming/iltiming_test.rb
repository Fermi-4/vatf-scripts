require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

def run_get_script_output
   super("Done")
end
  
def transfer_files(libs_var, libs_root)
  puts "Inside transfer_files #{libs_var} and #{libs_root}\n"
  puts "Libs_var is #{@test_params.instance_variable_get(libs_root).to_s}\n and #{@test_params.instance_variable_get(libs_var).to_s}\n"
    if @test_params.params_chan.instance_variable_defined?(libs_var) && @test_params.instance_variable_defined?(libs_root) #and false  ###### TODO TODO MUST REMOVE 'and false', Added to work around filesystem storage limit error
	puts "Libs root is #{libs_root}\n"
      src_dir = @test_params.instance_variable_get(libs_root)
	  src_dir = File.join(src_dir,get_os_version)
      puts "apps source dir set to #{src_dir}"
      @test_params.params_chan.instance_variable_get(libs_var).each {|lib|
        puts "lib filename set to #{lib}"
        put_file({'filename' => lib, 'src_dir' => src_dir, 'binary' => true})
      }
    end
  end  
  
def run_collect_performance_data
  puts "\n iltiming_test::run_collect_performance_data"
  log = get_serial_output
  perf_data = []   
  log.scan(/ min.+?(\d+\.\d)\s+(\d+\.\d).*ave.+?(\d+\.\d)\s+(\d+\.\d).*max.+?(\d+\.\d)\s+(\d+\.\d)/mx) {|d|
    perf_data << {'name' => "ISR_MIN", 'value' => "#{d[0]}", 'units' => "us"}
	perf_data << {'name' => "ISR_AVG", 'value' => "#{d[2]}", 'units' => "us"}
	perf_data << {'name' => "ISR_MAX", 'value' => "#{d[4]}", 'units' => "us"}
    perf_data << {'name' => "IST_MIN", 'value' => "#{d[1]}", 'units' => "us"}
	perf_data << {'name' => "IST_AVG", 'value' => "#{d[3]}", 'units' => "us"}
	perf_data << {'name' => "IST_MAX", 'value' => "#{d[5]}", 'units' => "us"}
  }
  perf_data
end

def run_determine_test_outcome
  puts "\n iltiming_test::run_determine_test_outcome"
  perf_data = run_collect_performance_data
  if perf_data.length > 1
    [FrameworkConstants::Result[:pass], "Performance data was collected", perf_data]
  else
    [FrameworkConstants::Result[:fail], "Performance data was not collected"]
  end
end

def clean_delete_binary_files
end

# def run_determine_test_outcome
  # puts "Test specific determine_test_outcome logic"
  # puts "\nSTD OUTPUT:\n#{get_std_output}\n"
  # puts "\nSTD ERROR:\n#{get_std_error}\n"
  # puts "\nSERIAL OUTPUT:\n#{get_serial_output}\n"
  # [FrameworkConstants::Result[:pass], "This test pass"]
# end

