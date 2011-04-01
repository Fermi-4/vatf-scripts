require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

def run_transfer_script()
    puts "\n qbench_test::run_transfer_script"
    put_file({'filename'=>'test.bat'})
    # transfer tux etc files to target
	if @test_params.instance_variable_defined?(:@var_build_test_libs_root)
      src_dir = @test_params.var_build_test_libs_root
	  os_version = get_os_version
	  src_dir = File.join(@test_params.var_build_test_libs_root,os_version)
	  src_dir = File.join(src_dir,'QBench-pro')
	  puts "Src_dir is #{src_dir}\n"
      get_qbench_filenames(src_dir).split(':').each {|lib_file|
        put_file({'filename' => lib_file, 'src_dir' => src_dir, 'binary' => true})
      }
    end
  end
  
  def get_qbench_filenames(qbench_files_dir)
    qbench_files = {'6.0_R3' => 'tux.exe:kato.dll:qbench_reg.lic:qbench_tux.dll:tooltalk.dll:qbench_dll.dll:qbench_res.dll:qb.exe','7.0' => 'tux.exe:kato.dll:qbench_reg.lic:qbench_tux.dll:tooltalk.dll:qbench_dll.dll:qbench_res.dll:qb.exe'}
	os_version = get_os_version
	puts "From get_qbench_files #{qbench_files[os_version.to_s]}\n"
    return qbench_files[os_version.to_s]
  end
  
# Collect output from standard output, standard error and serial port in test.log
def run_get_script_output
  puts "\n cetk_test::run_get_script_output"
  super("</TESTGROUP>")
end

def run_collect_performance_data
  puts "\n qbench_test::run_collect_performance_data"
  perfdata =[]
  success = 0
    File.new(File.join(@wince_temp_folder, "test_#{@test_id}\.log"),'r').each {|line|
	 if (line.include?("Success"))
	   success = 1
	 end
	 if (@test_params.params_chan.benchmark_units[0].to_s == "Q" && success == 1)
	   if(line.match(/\d+\.\d+\sQ/))
	     benchmark_value = line.delete(@test_params.params_chan.benchmark_units[0]).chomp.strip
	     benchmark_value = /\d+\.\d+/.match(benchmark_value).to_s
		 benchmark_value = Float(benchmark_value)
	     puts "Benchmark value is #{benchmark_value}\n"
		 perfdata<<{'name'=>@test_params.params_chan.benchmark_name[0],'value'=>benchmark_value,'units'=>@test_params.params_chan.benchmark_units[0]}
	   end
	 else
	    if (line.include?(@test_params.params_chan.benchmark_units[0].to_s) && success == 1)
	      benchmark_value = line.delete(@test_params.params_chan.benchmark_units[0]).chomp.strip
	      benchmark_value = /\d+\.\d+/.match(benchmark_value).to_s
	      benchmark_value = Float(benchmark_value)
		  perfdata<<{'name'=>@test_params.params_chan.benchmark_name[0],'value'=>benchmark_value,'units'=>@test_params.params_chan.benchmark_units[0]}
		  
	    end
	 end
	}
	return perfdata
end

def run_determine_test_outcome
  puts "\n qbench_test::run_determine_test_outcome"
  result, comment = [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
  File.new(File.join(@wince_temp_folder, "test_#{@test_id}\.log"),'r').each {|line| 
    if line =~ /\*\*\*\s*passed:\s+1/i then
      puts "-----------test passed---------"
	  if (@test_params.params_chan.benchmark_units[0]!="none")
       result = [FrameworkConstants::Result[:pass], "This test pass.", run_collect_performance_data]
	  else
	   result = [FrameworkConstants::Result[:pass], "This test pass."]
	  end
	  puts "result is #{result}\n"
	elsif line =~ /\*\*\*\s*failed:\s+1/i then
	  puts "-----------test failed---------"
	  result = [FrameworkConstants::Result[:fail], "This test failed."]
	end
  }
  return result
end

