require File.dirname(__FILE__)+'/../default_test'

include WinceTestScript

# Collect output from standard output, standard error and serial port in test.log
def run_get_script_output
  puts "\n cetk_test::run_get_script_output"
  super("</TESTGROUP>")
end

def run_collect_performance_data
  puts "\n cetk_test::run_collect_performance_data"
  # log = get_serial_output
  # out_file = File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER, "perf.log"),'w')   
  # log.scan(/\|\s+(\d+\.\d+)\s+\|\s+IP\s+=\s+(\w+)\s+\|\s+CS\s+=\s+(\w+).+?Max\s+Time\s+=\s+(\d+\.\d+)\s+(\w+).+?Min\s+Time\s+=\s+(\d+\.\d+)\s+(\w+).+?Avg\s+Time\s+=\s+(\d+\.\d+)\s+(\w+)/m) {|d|
    # out_file.puts "#{d[0]}_ip#{d[1]}_cs#{d[2]}_MAX #{d[3]} #{d[4]}"
    # out_file.puts "#{d[0]}_ip#{d[1]}_cs#{d[2]}_MIN #{d[5]} #{d[6]}"
    # out_file.puts "#{d[0]}_ip#{d[1]}_cs#{d[2]}_AVG #{d[7]} #{d[8]}"
  # }
  # out_file.close
end

def run_determine_test_outcome
  puts "\n cetk_test::run_determine_test_outcome"
  # perf_data = Array.new
  # File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER, "perf.log"),'r').each {|line| 
    # n, v, u = line.strip.split(' ')
    # perf_data << {'name' => n, 'value' => v, 'units' => u}
  # }
  # if perf_data.length > 1
    # [FrameworkConstants::Result[:pass], "Performace data was collected", perf_data]
  # else
    # [FrameworkConstants::Result[:fail], "Performance data was not collected"]
  # end
  result, comment = [FrameworkConstants::Result[:fail], "This test is fail or skip or abort."]
  File.new(File.join(SiteInfo::WINCE_TEMP_FOLDER, "test_#{@test_id}\.log"),'r').each {|line| 
    # n, v, u = line.strip.split(' ')
    # perf_data << {'name' => n, 'value' => v, 'units' => u}
    if line =~ /\*\*\*\s*passed:\s+1/i then
      puts "-----------test passed---------"
      result, comment = [FrameworkConstants::Result[:pass], "This test pass."]
    end
  }
  return result, comment

end

